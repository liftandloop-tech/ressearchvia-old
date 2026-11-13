import mongoose from "mongoose";
import leadModel from "../models/leadModel.js";
import staffModel from "../models/staffModel.js";
import leadPoolModel from "../models/leadPoolModel.js";
import leadCampaignModel from "../models/leadCampaignModel.js";
import leadVendorModel from "../models/leadVendorModel.js";
import leadTimelineModel from "../models/leadTimelineModel.js";
import segmentsModel from "../models/segmentsModel.js";
import xlsx from "xlsx";
import fs from "fs";
import csvParser from "csv-parser";
import importService from "../services/importService.js";
import importJobModel from "../models/importJobModel.js";
import { ensureDefaultFreshPool } from "./leadPoolController.js";
import { getSupervisedStaffIds, getAccessibleLeadPoolFilter } from "../utils/staffHierarchy.js";
import { resolveAdminStaff } from "../services/staffService.js";

const leadController = {
    createLead: async (req, res) => {
        try {
            const companyId = req.user?.companyId || req.user?.company || "default_company";
            const callerId = req.user?._id || req.user?.userId || req.user?.id;
            const isSuper = req.user?.userType === 'admin' || req.user?.userType === 'super_admin' || req.user?.role === 'Admin';

            let { leadPoolId } = req.body;
            let targetPool = null;

            if (leadPoolId) {
                const poolFilter = await getAccessibleLeadPoolFilter(callerId, companyId);
                poolFilter._id = leadPoolId;
                targetPool = await leadPoolModel.findOne(poolFilter);
            }

            if (!targetPool) {
                targetPool = await ensureDefaultFreshPool(companyId);
            }

            let assignedRM = null;
            if (isSuper) {
                assignedRM = req.body.assignedRM || null;
            } else if (callerId) {
                const hierarchy = await getSupervisedStaffIds(callerId);
                const allowedStaffIds = (hierarchy.staffIds || [callerId]).map(id => id.toString());
                if (req.body.assignedRM && allowedStaffIds.includes(req.body.assignedRM.toString())) {
                    assignedRM = req.body.assignedRM;
                } else {
                    assignedRM = callerId;
                }
            }

            const cleanPhone = importService.normalizePhone(req.body.mobileNumber) || req.body.mobileNumber;

            const lead = await leadModel.create({
                ...req.body,
                mobileNumber: cleanPhone,
                companyId,
                leadSource: req.body.leadSource || 'MANUAL_ENTRY',
                leadPoolId: targetPool._id,
                assignedRM
            });

            // Record timeline entry
            await leadTimelineModel.create({
                leadId: lead._id,
                companyId,
                eventType: 'LEAD_CREATED',
                title: 'Lead Created Manually',
                description: `Lead created by ${req.user?.fullName || req.user?.name || 'Staff'}`,
                metadata: { stage: lead.stage, assignedRM: lead.assignedRM },
                performedBy: { staffId: callerId, name: req.user?.fullName || req.user?.name || 'Staff' }
            });

            res.status(200).send({ status: 200, message: "Lead created and added to lead pool successfully", data: { lead } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    updateLead: async (req, res) => {
        try {
            const { id } = req.params;
            const callerId = req.user?._id || req.user?.userId || req.user?.id;
            const isSuper = req.user?.userType === 'admin' || req.user?.userType === 'super_admin' || req.user?.role === 'Admin';

            let filter = { _id: id };
            const updates = { ...req.body };

            if (!isSuper && callerId) {
                const hierarchy = await getSupervisedStaffIds(callerId);
                if (!hierarchy.isSystemAdmin) {
                    const staffMember = hierarchy.staffMember;
                    const hasUpdateAll = staffMember?.roleId?.permissionGroups?.some(g =>
                        g.permissions?.some(p => p.actions?.includes('leads.update_all'))
                    );
                    if (!hasUpdateAll) {
                        filter.assignedRM = { $in: hierarchy.staffIds };
                    }

                    if (!hierarchy.isSupervisor && (!hierarchy.staffIds || hierarchy.staffIds.length <= 1)) {
                        delete updates.assignedRM;
                        delete updates.leadPoolId;
                    } else if (updates.assignedRM) {
                        const targetStaffId = updates.assignedRM.toString();
                        if (!hierarchy.staffIds.some(sid => sid.toString() === targetStaffId)) {
                            return res.status(403).send({ status: 403, message: "Cannot reassign lead to staff outside your supervised team", data: {} });
                        }
                    }
                }
            }

            if (updates.assignedRM) {
                const targetStaff = await staffModel.findById(updates.assignedRM);
                if (targetStaff && targetStaff.status && targetStaff.status.toLowerCase() !== 'active') {
                    return res.status(400).send({ status: 400, message: "Cannot assign lead to an inactive staff member", data: {} });
                }
            }

            const existingLead = await leadModel.findOne(filter);
            if (!existingLead) {
                return res.status(404).send({ status: 404, message: "Lead not found or access denied", data: {} });
            }

            // Track timeline changes
            if (updates.stage && updates.stage !== existingLead.stage) {
                await leadTimelineModel.create({
                    leadId: existingLead._id,
                    companyId: existingLead.companyId,
                    eventType: 'STATUS_UPDATED',
                    title: `Status Changed to ${updates.stage}`,
                    description: `Pipeline stage moved from "${existingLead.stage}" to "${updates.stage}"`,
                    metadata: { oldStage: existingLead.stage, newStage: updates.stage },
                    performedBy: { staffId: callerId, name: req.user?.fullName || req.user?.name || 'Staff' }
                });
            }

            if (updates.assignedRM && String(updates.assignedRM) !== String(existingLead.assignedRM)) {
                const targetStaff = await staffModel.findById(updates.assignedRM).select('fullName');
                await leadTimelineModel.create({
                    leadId: existingLead._id,
                    companyId: existingLead.companyId,
                    eventType: 'LEAD_ASSIGNED',
                    title: `Assigned to ${targetStaff ? targetStaff.fullName : 'New RM'}`,
                    description: `Lead assigned to RM ${targetStaff ? targetStaff.fullName : updates.assignedRM}`,
                    metadata: { oldRM: existingLead.assignedRM, newRM: updates.assignedRM },
                    performedBy: { staffId: callerId, name: req.user?.fullName || req.user?.name || 'Staff' }
                });
            }

            const lead = await leadModel.findOneAndUpdate(filter, updates, { new: true });
            res.status(200).send({ status: 200, message: "Lead updated successfully", data: { lead } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    listLeads: async (req, res) => {
        try {
            const {
                page = 1,
                limit = 10,
                search = "",
                stage = "",
                assignedRM = "",
                leadPoolId = "",
                campaignId = "",
                leadVendorId = "",
                segmentId = "",
                name = "",
                mobile = "",
                location = "",
                sortBy = "",
                sortOrder = ""
            } = req.query;
            const query = {};

            const callerId = req.user?._id || req.user?.userId || req.user?.id;
            const isSuper = req.user?.userType === 'admin' || req.user?.userType === 'super_admin' || req.user?.role === 'Admin';
            let allowedStaffIds = null;

            if (!isSuper && callerId) {
                const hierarchy = await getSupervisedStaffIds(callerId);
                if (!hierarchy.isSystemAdmin) {
                    const staffMember = hierarchy.staffMember;
                    if (hierarchy.staffIds && hierarchy.staffIds.length > 0) {
                        allowedStaffIds = hierarchy.staffIds.map(id => id.toString());
                    } else {
                        const myId = staffMember?._id || callerId;
                        allowedStaffIds = [myId.toString()];
                    }

                    query.assignedRM = { 
                        $in: allowedStaffIds.map(id => mongoose.isValidObjectId(id) ? new mongoose.Types.ObjectId(id) : id) 
                    };
                }
            }

            if (search) {
                query.$or = [
                    { fullName: { $regex: search, $options: "i" } },
                    { mobileNumber: { $regex: search, $options: "i" } },
                    { emailAddress: { $regex: search, $options: "i" } },
                    { remarks: { $regex: search, $options: "i" } }
                ];
            }
            if (name && name.trim() !== '') {
                query.fullName = { $regex: name.trim(), $options: "i" };
            }
            if (mobile && mobile.trim() !== '') {
                query.mobileNumber = { $regex: mobile.trim(), $options: "i" };
            }
            if (location && location.trim() !== '') {
                query.$or = [
                    { "personalDetails.city": { $regex: location.trim(), $options: "i" } },
                    { "personalDetails.state": { $regex: location.trim(), $options: "i" } },
                    { city: { $regex: location.trim(), $options: "i" } },
                    { state: { $regex: location.trim(), $options: "i" } }
                ];
            }
            if (stage) query.stage = stage;
            if (campaignId && mongoose.isValidObjectId(campaignId)) {
                query.campaignId = new mongoose.Types.ObjectId(campaignId);
            }
            if (leadVendorId && mongoose.isValidObjectId(leadVendorId)) {
                query.leadVendorId = new mongoose.Types.ObjectId(leadVendorId);
            }
            if (segmentId && mongoose.isValidObjectId(segmentId)) {
                query.segmentIds = new mongoose.Types.ObjectId(segmentId);
            }
            if (assignedRM) {
                if (allowedStaffIds !== null) {
                    if (allowedStaffIds.includes(assignedRM.toString()) && mongoose.isValidObjectId(assignedRM)) {
                        query.assignedRM = new mongoose.Types.ObjectId(assignedRM.toString());
                    } else {
                        query.assignedRM = new mongoose.Types.ObjectId();
                    }
                } else {
                    if (assignedRM === 'unassigned' || assignedRM === 'null') {
                        query.assignedRM = null;
                    } else if (assignedRM === 'admin') {
                        const adminStaff = await resolveAdminStaff();
                        query.assignedRM = adminStaff ? adminStaff._id : null;
                    } else if (mongoose.isValidObjectId(assignedRM)) {
                        query.assignedRM = new mongoose.Types.ObjectId(assignedRM.toString());
                    }
                }
            }
            if (req.query.leadSource && req.query.leadSource.trim() !== '') {
                query.leadSource = req.query.leadSource.trim();
            }
            if (req.query.isAppUser !== undefined && req.query.isAppUser !== '') {
                query.isAppUser = req.query.isAppUser === 'true' || req.query.isAppUser === true;
            }
            if (leadPoolId && mongoose.isValidObjectId(leadPoolId)) {
                query.leadPoolId = new mongoose.Types.ObjectId(leadPoolId);
            }

            let sortOptions = { createdAt: -1 };
            if (sortBy && sortBy.trim() !== '') {
                const direction = (sortOrder === 'asc' || sortOrder === '1') ? 1 : -1;
                sortOptions = { [sortBy.trim()]: direction };
            }

            const total = await leadModel.countDocuments(query);
            const leads = await leadModel.find(query)
                .populate('assignedRM', 'fullName emailAddress mobileNumber')
                .populate('leadPoolId', 'name description pullSize maxPerStaff isActive')
                .populate('campaignId', 'name description isActive')
                .populate('leadVendorId', 'name code contactPerson')
                .populate('segmentIds', 'segmentName segmentStatus')
                .populate('previousRM.staffId', 'fullName emailAddress mobileNumber')
                .skip((page - 1) * limit)
                .limit(parseInt(limit))
                .sort(sortOptions);

            res.status(200).send({ status: 200, message: "Leads fetched successfully", data: { total, leads, page, limit } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    addFollowUp: async (req, res) => {
        try {
            const { id } = req.params;
            const { notes, followUpDate, followUpType, status, nextFollowUpDate } = req.body;
            if (!notes || !followUpDate) {
                return res.status(400).send({ status: 400, message: "Notes and followUpDate are required", data: {} });
            }

            const callerId = req.user?._id || req.user?.userId || req.user?.id;
            const isSuper = req.user?.userType === 'admin' || req.user?.userType === 'super_admin' || req.user?.role === 'Admin';

            let filter = { _id: id };
            if (!isSuper && callerId) {
                const hierarchy = await getSupervisedStaffIds(callerId);
                if (!hierarchy.isSystemAdmin) {
                    const staffMember = hierarchy.staffMember;
                    const hasFollowUpAll = staffMember?.roleId?.permissionGroups?.some(g =>
                        g.permissions?.some(p => p.actions?.includes('leads.follow_up_all'))
                    );
                    if (!hasFollowUpAll) {
                        filter.assignedRM = { $in: hierarchy.staffIds };
                    }
                }
            }

            const lead = await leadModel.findOne(filter);
            if (!lead) {
                return res.status(404).send({ status: 404, message: "Lead not found or access denied", data: {} });
            }

            lead.followUps.push({
                notes,
                followUpDate,
                followUpType: followUpType || 'Call',
                status: status || 'Pending',
                nextFollowUpDate: nextFollowUpDate || null
            });
            if (lead.stage === 'New') {
                lead.stage = 'Contacted';
            }
            await lead.save();

            // Record timeline entry
            await leadTimelineModel.create({
                leadId: lead._id,
                companyId: lead.companyId,
                eventType: 'FOLLOW_UP_ADDED',
                title: `Follow-up Added: ${followUpType || 'Call'}`,
                description: `${notes} (Scheduled for: ${new Date(followUpDate).toLocaleString()})`,
                metadata: { followUpType, status, followUpDate, nextFollowUpDate },
                performedBy: { staffId: callerId, name: req.user?.fullName || req.user?.name || 'Staff' }
            });

            res.status(200).send({ status: 200, message: "Follow-up added successfully", data: { lead } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    updateFollowUpStatus: async (req, res) => {
        try {
            const { id, followUpId } = req.params;
            const { status, notes, nextFollowUpDate, rescheduleDate } = req.body;

            const callerId = req.user?._id || req.user?.userId || req.user?.id;
            const lead = await leadModel.findById(id);
            if (!lead) {
                return res.status(404).send({ status: 404, message: "Lead not found", data: {} });
            }

            const followUp = lead.followUps.id(followUpId);
            if (!followUp) {
                return res.status(404).send({ status: 404, message: "Follow-up record not found", data: {} });
            }

            const oldStatus = followUp.status;
            if (status) followUp.status = status;
            if (notes) followUp.notes = `${followUp.notes} | Update: ${notes}`;
            if (rescheduleDate) {
                followUp.followUpDate = new Date(rescheduleDate);
                followUp.status = 'Rescheduled';
            }
            if (nextFollowUpDate) {
                followUp.nextFollowUpDate = new Date(nextFollowUpDate);
            }

            await lead.save();

            // Record timeline entry
            await leadTimelineModel.create({
                leadId: lead._id,
                companyId: lead.companyId,
                eventType: 'FOLLOW_UP_UPDATED',
                title: `Follow-up ${status || 'Updated'}`,
                description: `Follow-up marked as ${followUp.status}. ${notes ? `Note: ${notes}` : ''}`,
                metadata: { oldStatus, newStatus: followUp.status, followUpId },
                performedBy: { staffId: callerId, name: req.user?.fullName || req.user?.name || 'Staff' }
            });

            res.status(200).send({ status: 200, message: "Follow-up updated successfully", data: { lead, followUp } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    getPendingFollowups: async (req, res) => {
        try {
            const { page = 1, limit = 20, isOverdue } = req.query;
            const callerId = req.user?._id || req.user?.userId || req.user?.id;
            const isSuper = req.user?.userType === 'admin' || req.user?.userType === 'super_admin' || req.user?.role === 'Admin';

            const matchFilter = {};

            if (!isSuper && callerId) {
                const hierarchy = await getSupervisedStaffIds(callerId);
                if (!hierarchy.isSystemAdmin) {
                    const allowedStaffIds = (hierarchy.staffIds || [callerId]).map(id =>
                        mongoose.isValidObjectId(id) ? new mongoose.Types.ObjectId(id) : id
                    );
                    matchFilter.assignedRM = { $in: allowedStaffIds };
                }
            }

            const now = new Date();

            // MongoDB aggregation to unwind followUps and filter pending
            const pipeline = [
                { $match: matchFilter },
                { $unwind: "$followUps" },
                {
                    $match: {
                        "followUps.status": { $in: ['Pending', 'Rescheduled'] }
                    }
                }
            ];

            if (isOverdue === 'true') {
                pipeline.push({
                    $match: {
                        "followUps.followUpDate": { $lt: now }
                    }
                });
            }

            pipeline.push(
                {
                    $lookup: {
                        from: "staffs",
                        localField: "assignedRM",
                        foreignField: "_id",
                        as: "assignedRMDetails"
                    }
                },
                {
                    $lookup: {
                        from: "leadcampaigns",
                        localField: "campaignId",
                        foreignField: "_id",
                        as: "campaignDetails"
                    }
                },
                {
                    $project: {
                        leadId: "$_id",
                        fullName: 1,
                        mobileNumber: 1,
                        emailAddress: 1,
                        stage: 1,
                        assignedRM: 1,
                        assignedRMName: { $arrayElemAt: ["$assignedRMDetails.fullName", 0] },
                        campaignName: { $arrayElemAt: ["$campaignDetails.name", 0] },
                        followUpId: "$followUps._id",
                        notes: "$followUps.notes",
                        followUpDate: "$followUps.followUpDate",
                        followUpType: "$followUps.followUpType",
                        status: "$followUps.status",
                        nextFollowUpDate: "$followUps.nextFollowUpDate",
                        createdAt: "$followUps.createdAt",
                        isOverdue: { $lt: ["$followUps.followUpDate", now] }
                    }
                },
                { $sort: { followUpDate: 1 } }
            );

            const allResults = await leadModel.aggregate(pipeline);
            const total = allResults.length;
            const skip = (parseInt(page) - 1) * parseInt(limit);
            const followUps = allResults.slice(skip, skip + parseInt(limit));

            res.status(200).send({
                status: 200,
                message: "Pending follow-ups retrieved successfully",
                data: { total, followUps, page: parseInt(page), limit: parseInt(limit) }
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    assignLeadSegments: async (req, res) => {
        try {
            const { id } = req.params;
            const { segmentIds } = req.body;
            const callerId = req.user?._id || req.user?.userId || req.user?.id;

            if (!Array.isArray(segmentIds)) {
                return res.status(400).send({ status: 400, message: "segmentIds must be an array", data: {} });
            }

            const lead = await leadModel.findById(id);
            if (!lead) {
                return res.status(404).send({ status: 404, message: "Lead not found", data: {} });
            }

            lead.segmentIds = segmentIds;
            await lead.save();

            // Populate segment names for timeline
            const populatedSegments = await segmentsModel.find({ _id: { $in: segmentIds } }).select('segmentName');
            const segmentNames = populatedSegments.map(s => s.segmentName).join(', ');

            await leadTimelineModel.create({
                leadId: lead._id,
                companyId: lead.companyId,
                eventType: 'SEGMENT_ASSIGNED',
                title: 'Segments Assigned',
                description: `Assigned segments: ${segmentNames || 'None'}`,
                metadata: { segmentIds },
                performedBy: { staffId: callerId, name: req.user?.fullName || req.user?.name || 'Staff' }
            });

            res.status(200).send({ status: 200, message: "Segments assigned successfully", data: { lead } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    updateFreeTrial: async (req, res) => {
        try {
            const { id } = req.params;
            const { startDate, endDate } = req.body;
            const callerId = req.user?._id || req.user?.userId || req.user?.id;

            const lead = await leadModel.findById(id);
            if (!lead) {
                return res.status(404).send({ status: 404, message: "Lead not found", data: {} });
            }

            lead.freeTrial = {
                startDate: startDate ? new Date(startDate) : null,
                endDate: endDate ? new Date(endDate) : null
            };
            await lead.save();

            await leadTimelineModel.create({
                leadId: lead._id,
                companyId: lead.companyId,
                eventType: 'FREE_TRIAL_UPDATED',
                title: 'Free Trial Updated',
                description: startDate && endDate 
                    ? `Free trial set from ${new Date(startDate).toLocaleDateString()} to ${new Date(endDate).toLocaleDateString()}`
                    : 'Free trial dates cleared',
                metadata: { freeTrial: lead.freeTrial },
                performedBy: { staffId: callerId, name: req.user?.fullName || req.user?.name || 'Staff' }
            });

            res.status(200).send({ status: 200, message: "Free trial updated successfully", data: { lead } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    getLeadTimeline: async (req, res) => {
        try {
            const { id } = req.params;
            const timeline = await leadTimelineModel.find({ leadId: id }).sort({ createdAt: -1 });

            // If no explicit timeline events exist yet for an older lead, construct a baseline from lead details
            if (timeline.length === 0) {
                const lead = await leadModel.findById(id).populate('assignedRM', 'fullName');
                if (lead) {
                    const fallbackEvents = [];
                    fallbackEvents.push({
                        leadId: lead._id,
                        eventType: 'LEAD_CREATED',
                        title: 'Lead Created',
                        description: `Lead originally created on ${new Date(lead.createdAt).toLocaleString()}`,
                        createdAt: lead.createdAt,
                        performedBy: { name: 'System' }
                    });
                    if (lead.assignedRM) {
                        fallbackEvents.push({
                            leadId: lead._id,
                            eventType: 'LEAD_ASSIGNED',
                            title: `Assigned to ${lead.assignedRM.fullName || 'RM'}`,
                            description: 'Initial lead assignment',
                            createdAt: lead.pulledAt || lead.createdAt,
                            performedBy: { name: 'System' }
                        });
                    }
                    for (const f of lead.followUps) {
                        fallbackEvents.push({
                            leadId: lead._id,
                            eventType: 'FOLLOW_UP_ADDED',
                            title: `Follow-up: ${f.followUpType}`,
                            description: f.notes,
                            createdAt: f.createdAt || f.followUpDate,
                            performedBy: { name: 'Staff' }
                        });
                    }
                    return res.status(200).send({
                        status: 200,
                        message: "Timeline retrieved successfully",
                        data: fallbackEvents.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
                    });
                }
            }

            res.status(200).send({ status: 200, message: "Timeline retrieved successfully", data: timeline });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    // --- CAMPAIGN MANAGEMENT ---
    listCampaigns: async (req, res) => {
        try {
            const companyId = req.user?.companyId || req.user?.company || "default_company";
            const campaigns = await leadCampaignModel.find({ companyId, isActive: { $ne: false } }).sort({ createdAt: -1 });
            res.status(200).send({ status: 200, message: "Campaigns retrieved successfully", data: campaigns });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    createCampaign: async (req, res) => {
        try {
            const companyId = req.user?.companyId || req.user?.company || "default_company";
            const callerId = req.user?._id || req.user?.userId || req.user?.id;
            const { name, description, startDate, endDate, budget } = req.body;

            if (!name) {
                return res.status(400).send({ status: 400, message: "Campaign name is required", data: {} });
            }

            const campaign = await leadCampaignModel.create({
                name,
                description,
                startDate: startDate ? new Date(startDate) : null,
                endDate: endDate ? new Date(endDate) : null,
                budget: budget || 0,
                companyId,
                createdBy: callerId
            });

            res.status(200).send({ status: 200, message: "Campaign created successfully", data: campaign });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    updateCampaign: async (req, res) => {
        try {
            const { id } = req.params;
            const campaign = await leadCampaignModel.findByIdAndUpdate(id, req.body, { new: true });
            if (!campaign) {
                return res.status(404).send({ status: 404, message: "Campaign not found", data: {} });
            }
            res.status(200).send({ status: 200, message: "Campaign updated successfully", data: campaign });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    deleteCampaign: async (req, res) => {
        try {
            const { id } = req.params;
            await leadCampaignModel.findByIdAndUpdate(id, { isActive: false });
            res.status(200).send({ status: 200, message: "Campaign deactivated successfully" });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    // --- VENDOR MANAGEMENT ---
    listVendors: async (req, res) => {
        try {
            const companyId = req.user?.companyId || req.user?.company || "default_company";
            const vendors = await leadVendorModel.find({ companyId, isActive: { $ne: false } }).sort({ createdAt: -1 });
            res.status(200).send({ status: 200, message: "Vendors retrieved successfully", data: vendors });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    createVendor: async (req, res) => {
        try {
            const companyId = req.user?.companyId || req.user?.company || "default_company";
            const callerId = req.user?._id || req.user?.userId || req.user?.id;
            const { name, code, contactPerson, mobile, email, costPerLead } = req.body;

            if (!name) {
                return res.status(400).send({ status: 400, message: "Vendor name is required", data: {} });
            }

            const vendor = await leadVendorModel.create({
                name,
                code,
                contactPerson,
                mobile,
                email,
                costPerLead: costPerLead || 0,
                companyId,
                createdBy: callerId
            });

            res.status(200).send({ status: 200, message: "Vendor created successfully", data: vendor });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    updateVendor: async (req, res) => {
        try {
            const { id } = req.params;
            const vendor = await leadVendorModel.findByIdAndUpdate(id, req.body, { new: true });
            if (!vendor) {
                return res.status(404).send({ status: 404, message: "Vendor not found", data: {} });
            }
            res.status(200).send({ status: 200, message: "Vendor updated successfully", data: vendor });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    deleteVendor: async (req, res) => {
        try {
            const { id } = req.params;
            await leadVendorModel.findByIdAndUpdate(id, { isActive: false });
            res.status(200).send({ status: 200, message: "Vendor deactivated successfully" });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    // --- SEGMENT LISTING FOR LEADS ---
    listLeadSegments: async (req, res) => {
        try {
            const segments = await segmentsModel.find({ segmentStatus: { $ne: 'inactive' } }).select('segmentName segmentDiscription segmentStatus');
            res.status(200).send({ status: 200, message: "Segments retrieved successfully", data: segments });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    // --- BULK PASTE ---
    bulkPaste: async (req, res) => {
        try {
            const {
                rawText,
                numbers: inputNumbers,
                leadPoolId: inputPoolId,
                campaignId,
                leadVendorId,
                assignedRM,
                stage = 'New',
                duplicateStrategy = 'skip',
                duplicatePolicy,
                defaultName = ''
            } = req.body;

            const callerId = req.user?._id || req.user?.userId || req.user?.id;
            const companyId = req.user?.companyId || req.user?.company || "default_company";
            const effectiveDuplicatePolicy = duplicatePolicy || duplicateStrategy || 'skip';

            // Parse raw lines
            let rawLines = [];
            if (Array.isArray(inputNumbers) && inputNumbers.length > 0) {
                rawLines = inputNumbers;
            } else if (typeof rawText === 'string' && rawText.trim().length > 0) {
                rawLines = rawText.split(/[\r\n\u2028\u2029]+/);
            }

            if (rawLines.length === 0) {
                return res.status(400).send({
                    status: 400,
                    message: "No lead entries provided. Paste mobile numbers or comma/tab separated records.",
                    data: {}
                });
            }

            let leadPoolId = inputPoolId;
            if (!leadPoolId) {
                const freshPool = await ensureDefaultFreshPool(companyId);
                leadPoolId = freshPool._id;
            }

            let validRM = null;
            if (assignedRM && assignedRM !== 'unassigned') {
                const staffDoc = await staffModel.findOne({
                    _id: assignedRM,
                    companyId: companyId,
                    status: { $regex: /^active$/i }
                });
                if (staffDoc) validRM = staffDoc._id;
            }

            const validLeads = [];
            const seenInBatch = new Set();
            let invalidCount = 0;
            let batchDuplicateCount = 0;

            for (const line of rawLines) {
                const trimmed = String(line || '').trim();
                if (!trimmed) continue;

                // Support tab or comma separation: "Name, Phone, Email" or "Name\tPhone" or just "9876543210"
                let name = defaultName;
                let rawPhone = trimmed;
                let email = null;

                if (trimmed.includes('\t')) {
                    const parts = trimmed.split('\t').map(p => p.trim());
                    if (parts.length >= 2) {
                        name = parts[0] || defaultName;
                        rawPhone = parts[1];
                        email = parts[2] || null;
                    }
                } else if (trimmed.includes(',')) {
                    const parts = trimmed.split(',').map(p => p.trim());
                    if (parts.length >= 2) {
                        name = parts[0] || defaultName;
                        rawPhone = parts[1];
                        email = parts[2] || null;
                    }
                }

                const normalized10 = importService.normalizePhone(rawPhone);
                if (!normalized10 || normalized10.length !== 10 || !/^[6-9]\d{9}$/.test(normalized10)) {
                    invalidCount++;
                    continue;
                }

                if (seenInBatch.has(normalized10)) {
                    batchDuplicateCount++;
                    continue;
                }
                seenInBatch.add(normalized10);

                validLeads.push({
                    fullName: name ? String(name).trim() : '',
                    mobileNumber: normalized10,
                    emailAddress: email,
                    stage: stage || 'New',
                    assignedRM: validRM,
                    leadPoolId: leadPoolId,
                    campaignId: campaignId || null,
                    leadVendorId: leadVendorId || null,
                    companyId: companyId,
                    leadSource: 'IMPORTED_POOL',
                    isRead: false
                });
            }

            if (validLeads.length === 0) {
                return res.status(400).send({
                    status: 400,
                    message: `No valid 10-digit mobile numbers found (Processed ${rawLines.length} lines, ${invalidCount} invalid).`,
                    data: { totalReceived: rawLines.length, invalidCount }
                });
            }

            // Check duplicates against database
            const mobileNumbers = validLeads.map(l => l.mobileNumber);
            const existingLeads = await leadModel.find({
                companyId,
                mobileNumber: { $in: mobileNumbers }
            });

            const existingMap = new Map();
            for (const lead of existingLeads) {
                existingMap.set(lead.mobileNumber, lead);
            }

            let insertedCount = 0;
            let updatedCount = 0;
            let skippedCount = 0;
            let dbDuplicateCount = 0;
            const leadsToInsert = [];

            for (const leadData of validLeads) {
                const existing = existingMap.get(leadData.mobileNumber);
                if (existing) {
                    dbDuplicateCount++;
                    if (effectiveDuplicatePolicy === 'overwrite' || effectiveDuplicatePolicy === 'update') {
                        const changes = [];
                        if (leadData.fullName && existing.fullName !== leadData.fullName) {
                            changes.push(`Name: ${existing.fullName || 'empty'} -> ${leadData.fullName}`);
                            existing.fullName = leadData.fullName;
                        }
                        if (leadData.emailAddress && existing.emailAddress !== leadData.emailAddress) {
                            changes.push(`Email: ${existing.emailAddress || 'empty'} -> ${leadData.emailAddress}`);
                            existing.emailAddress = leadData.emailAddress;
                        }
                        if (validRM) existing.assignedRM = validRM;
                        if (leadPoolId) existing.leadPoolId = leadPoolId;
                        if (campaignId) existing.campaignId = campaignId;
                        if (leadVendorId) existing.leadVendorId = leadVendorId;
                        if (stage && !['Won', 'Lost', 'Invalid'].includes(existing.stage)) {
                            existing.stage = stage;
                        }
                        await existing.save();

                        // Record timeline entry for overwrite
                        await leadTimelineModel.create({
                            leadId: existing._id,
                            companyId,
                            eventType: 'LEAD_OVERWRITTEN',
                            title: 'Lead Overwritten via Bulk Paste',
                            description: `Lead updated (Overwrite mode). ${changes.join(', ')}`,
                            metadata: { campaignId, leadVendorId, assignedRM: validRM },
                            performedBy: { staffId: callerId, name: req.user?.fullName || req.user?.name || 'Staff' }
                        });
                        updatedCount++;
                    } else {
                        skippedCount++;
                    }
                } else {
                    leadsToInsert.push(leadData);
                }
            }

            if (leadsToInsert.length > 0) {
                const inserted = await leadModel.insertMany(leadsToInsert);
                insertedCount = inserted.length;

                // Timeline entries for new leads
                const timelines = inserted.map(l => ({
                    leadId: l._id,
                    companyId,
                    eventType: 'LEAD_CREATED',
                    title: 'Lead Created via Bulk Paste',
                    description: `Pasted lead added to ${l.leadPoolId ? 'pool' : 'CRM'}`,
                    metadata: { campaignId, leadVendorId, assignedRM: validRM },
                    performedBy: { staffId: callerId, name: req.user?.fullName || req.user?.name || 'Staff' }
                }));
                await leadTimelineModel.insertMany(timelines);
            }

            return res.status(200).send({
                status: 200,
                message: `Successfully processed ${validLeads.length} unique numbers: ${insertedCount} created, ${updatedCount} overwritten, ${skippedCount} skipped, ${invalidCount} invalid.`,
                data: {
                    totalReceived: rawLines.length,
                    validUnique: validLeads.length,
                    insertedCount,
                    createdCount: insertedCount,
                    updatedCount,
                    skippedCount,
                    duplicateCount: dbDuplicateCount + batchDuplicateCount,
                    dbDuplicateCount,
                    batchDuplicateCount,
                    invalidCount
                }
            });
        } catch (error) {
            console.error("Error in bulkPaste leads:", error);
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    bulkUpload: async (req, res) => {
        try {
            if (!req.file) {
                return res.status(400).send({ status: 400, message: "Please upload an Excel or CSV file", data: {} });
            }

            const filePath = req.file.path;
            const ext = req.file.originalname.split('.').pop().toLowerCase();

            const { sheetNames, previewRows, columnPreview } = await importService.parseUploadedFile(filePath, ext);

            if (columnPreview.length === 0) {
                if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
                return res.status(400).send({ status: 400, message: "File contains no columns or data headers", data: {} });
            }

            const job = await importJobModel.create({
                userId: req.user._id,
                companyId: req.user.companyId || req.user.company || "default_company",
                fileName: req.file.originalname,
                filePath: filePath,
                status: 'mapping_required',
                sheetNames,
                columnPreview,
                previewRows
            });

            const suggestedMapping = importService.calculateSuggestions(columnPreview);

            res.status(200).send({
                status: 200,
                message: "File uploaded and parsed successfully",
                data: {
                    importId: job._id,
                    status: job.status,
                    sheetNames,
                    columnPreview,
                    previewRows,
                    suggestedMapping
                }
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    getTemplate: (req, res) => {
        try {
            res.setHeader('Content-Type', 'text/csv');
            res.setHeader('Content-Disposition', 'attachment; filename=leads_template.csv');
            const csvContent = "fullName,mobileNumber,alternateMobile,emailAddress,city,state,remarks\nAmit Sharma,9876543210,9876543299,amit.sharma@example.com,Mumbai,Maharashtra,Interested in Nifty trading\nPriya Patel,8765432109,,priya.patel@example.com,Ahmedabad,Gujarat,Call after 4 PM\nJohn Doe,7654321098,,john.doe@example.com,Bangalore,Karnataka,Looking for equity calls\n";
            res.status(200).send(csvContent);
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    markAsRead: async (req, res) => {
        try {
            const { id } = req.params;
            const callerId = req.user?._id || req.user?.userId || req.user?.id;
            const isSuper = req.user?.userType === 'admin' || req.user?.userType === 'super_admin' || req.user?.role === 'Admin';

            let filter = { _id: id };
            if (!isSuper && callerId) {
                const hierarchy = await getSupervisedStaffIds(callerId);
                if (!hierarchy.isSystemAdmin) {
                    filter.assignedRM = { $in: hierarchy.staffIds };
                }
            }

            const lead = await leadModel.findOneAndUpdate(filter, { isRead: true }, { new: true });
            if (!lead) {
                return res.status(404).send({ status: 404, message: "Lead not found or access denied" });
            }
            res.status(200).send({ status: 200, message: "Lead marked as read", data: { lead } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message });
        }
    },

    bulkAssign: async (req, res) => {
        try {
            const { leadIds, assignedRM } = req.body;
            if (!leadIds || !Array.isArray(leadIds) || leadIds.length === 0) {
                return res.status(400).send({ status: 400, message: "leadIds must be a non-empty array" });
            }

            const staffId = assignedRM && assignedRM !== 'unassigned' ? assignedRM : null;
            const callerId = req.user?._id || req.user?.userId || req.user?.id;
            const isSuper = req.user?.userType === 'admin' || req.user?.userType === 'super_admin' || req.user?.role === 'Admin';
            let leadFilter = { _id: { $in: leadIds } };

            if (!isSuper && callerId) {
                const hierarchy = await getSupervisedStaffIds(callerId);
                if (!hierarchy.isSystemAdmin) {
                    if (!hierarchy.isSupervisor && (!hierarchy.staffIds || hierarchy.staffIds.length <= 1)) {
                        return res.status(403).send({ status: 403, message: "Only team leaders and administrators can assign leads" });
                    }
                    leadFilter.assignedRM = { $in: hierarchy.staffIds };
                    if (staffId && !hierarchy.staffIds.some(sid => sid.toString() === staffId.toString())) {
                        return res.status(403).send({ status: 403, message: "Cannot assign leads to staff outside your supervised team" });
                    }
                }
            }

            const targetStaff = staffId ? await staffModel.findById(staffId).select('fullName') : null;
            const reassignmentNote = targetStaff
                ? `🔄 Reassigned to RM: ${targetStaff.fullName}`
                : '🔄 Lead set to unassigned';

            await leadModel.updateMany(
                leadFilter,
                {
                    $set: { assignedRM: staffId, isRead: false },
                    $push: {
                        followUps: {
                            notes: reassignmentNote,
                            followUpDate: new Date(),
                            followUpType: 'Manager Follow-up',
                            status: 'Completed',
                            createdAt: new Date()
                        }
                    }
                }
            );

            // Record timeline entries for bulk assigned leads
            const timelineDocs = leadIds.map(leadId => ({
                leadId,
                eventType: 'LEAD_ASSIGNED',
                title: targetStaff ? `Assigned to ${targetStaff.fullName}` : 'Lead Unassigned',
                description: reassignmentNote,
                metadata: { assignedRM: staffId },
                performedBy: { staffId: callerId, name: req.user?.fullName || req.user?.name || 'Staff' }
            }));
            await leadTimelineModel.insertMany(timelineDocs);

            res.status(200).send({ status: 200, message: "Leads assigned successfully" });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message });
        }
    },

    bulkAssignByNumbers: async (req, res) => {
        try {
            const { rawNumbers, numbers, assignedRM } = req.body;
            let numberList = [];

            if (Array.isArray(numbers) && numbers.length > 0) {
                numberList = numbers;
            } else if (typeof rawNumbers === 'string' && rawNumbers.trim().length > 0) {
                numberList = rawNumbers.split(/[\r\n,;\t]+/);
            }

            const normalizedMap = new Set();
            for (const item of numberList) {
                if (!item) continue;
                const digits = item.toString().replace(/\D/g, '');
                if (digits.length >= 10) {
                    const tenDigit = digits.slice(-10);
                    normalizedMap.add(tenDigit);
                }
            }

            const uniqueNumbers = Array.from(normalizedMap);
            if (uniqueNumbers.length === 0) {
                return res.status(400).send({
                    status: 400,
                    message: "No valid 10-digit mobile numbers found in input"
                });
            }

            const staffId = assignedRM && assignedRM !== 'unassigned' ? assignedRM : null;
            const callerId = req.user?._id || req.user?.userId || req.user?.id;
            const isSuper = req.user?.userType === 'admin' || req.user?.userType === 'super_admin' || req.user?.role === 'Admin';

            let targetStaff = null;
            if (staffId) {
                targetStaff = await staffModel.findById(staffId).select('fullName staffId status');
                if (!targetStaff) {
                    return res.status(404).send({ status: 404, message: "Target staff member not found" });
                }
            }

            const queryVariations = [];
            for (const n of uniqueNumbers) {
                queryVariations.push(n);
                queryVariations.push(`+91${n}`);
                queryVariations.push(`91${n}`);
                queryVariations.push(`0${n}`);
            }

            const leadFilter = {
                $or: [
                    { mobileNumber: { $in: queryVariations } },
                    { mobileNumber: { $regex: new RegExp(`(${uniqueNumbers.join('|')})$`) } }
                ]
            };

            if (!isSuper && callerId) {
                const hierarchy = await getSupervisedStaffIds(callerId);
                if (!hierarchy.isSystemAdmin) {
                    if (!hierarchy.isSupervisor && (!hierarchy.staffIds || hierarchy.staffIds.length <= 1)) {
                        return res.status(403).send({ status: 403, message: "Only team leaders and administrators can assign leads" });
                    }
                    if (staffId && !hierarchy.staffIds.some(sid => sid.toString() === staffId.toString())) {
                        return res.status(403).send({ status: 403, message: "Cannot assign leads to staff outside your supervised team" });
                    }
                }
            }

            const updateResult = await leadModel.updateMany(
                leadFilter,
                { $set: { assignedRM: staffId } }
            );

            return res.status(200).send({
                status: 200,
                message: `Successfully assigned ${updateResult.modifiedCount} leads to ${targetStaff ? targetStaff.fullName : 'unassigned'}`,
                data: {
                    matchedCount: updateResult.matchedCount,
                    modifiedCount: updateResult.modifiedCount,
                    totalNumbersProvided: uniqueNumbers.length,
                    staffName: targetStaff ? targetStaff.fullName : 'Unassigned'
                }
            });
        } catch (error) {
            return res.status(500).send({ status: 500, message: error.message });
        }
    }
};

export default leadController;
