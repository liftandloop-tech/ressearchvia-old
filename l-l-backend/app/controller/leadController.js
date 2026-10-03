import mongoose from "mongoose";
import leadModel from "../models/leadModel.js";
import staffModel from "../models/staffModel.js";
import leadPoolModel from "../models/leadPoolModel.js";
import xlsx from "xlsx";
import fs from "fs";
import csvParser from "csv-parser";
import importService from "../services/importService.js";
import importJobModel from "../models/importJobModel.js";
import { ensureDefaultFreshPool } from "./leadPoolController.js";
import { getSupervisedStaffIds, getAccessibleLeadPoolFilter } from "../utils/staffHierarchy.js";

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

            // Leads must be added to a pool as unassigned (assignedRM: null).
            // Staff subsequently pull from the pool based on lead distribution quotas.
            // Only administrators can directly pre-assign leads at creation time.
            const assignedRM = isSuper && req.body.assignedRM ? req.body.assignedRM : null;

            const lead = await leadModel.create({
                ...req.body,
                companyId,
                leadPoolId: targetPool._id,
                assignedRM
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

                    // Protect lead assignment and pool placement:
                    // Base sales executives (no subordinates) cannot reassign leads or change lead pools
                    if (!hierarchy.isSupervisor && (!hierarchy.staffIds || hierarchy.staffIds.length <= 1)) {
                        delete updates.assignedRM;
                        delete updates.leadPoolId;
                    } else if (updates.assignedRM) {
                        // Team leaders / managers can only reassign to staff within their supervised team
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

            const lead = await leadModel.findOneAndUpdate(filter, updates, { new: true });
            if (!lead) {
                return res.status(404).send({ status: 404, message: "Lead not found or access denied", data: {} });
            }
            res.status(200).send({ status: 200, message: "Lead updated successfully", data: { lead } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    listLeads: async (req, res) => {
        try {
            const { page = 1, limit = 10, search = "", stage = "", assignedRM = "", leadPoolId = "" } = req.query;
            const query = {};

            // Data-Scope Enforcement: Non-admins without leads.view_all are restricted to their team or themselves
            const callerId = req.user?._id || req.user?.userId || req.user?.id;
            const isSuper = req.user?.userType === 'admin' || req.user?.userType === 'super_admin' || req.user?.role === 'Admin';
            if (!isSuper && callerId) {
                const hierarchy = await getSupervisedStaffIds(callerId);
                if (!hierarchy.isSystemAdmin) {
                    const staffMember = hierarchy.staffMember;
                    const hasViewAll = staffMember?.roleId?.permissionGroups?.some(g =>
                        g.permissions?.some(p => p.actions?.includes('leads.view_all'))
                    );

                    // Unless explicitly granted leads.view_all, restrict query to assignedRM
                    if (!hasViewAll) {
                        if (hierarchy.staffIds && hierarchy.staffIds.length > 1) {
                            // Team Leader / Manager: sees all leads assigned to their team
                            query.assignedRM = { $in: hierarchy.staffIds };
                        } else {
                            // Individual Sales Executive: ONLY sees leads assigned to THEMSELVES
                            const myId = staffMember?._id || (mongoose.isValidObjectId(callerId) ? new mongoose.Types.ObjectId(callerId.toString()) : callerId);
                            query.assignedRM = myId;
                        }
                    }
                }
            }

            if (search) {
                query.$or = [
                    { fullName: { $regex: search, $options: "i" } },
                    { mobileNumber: { $regex: search, $options: "i" } },
                    { emailAddress: { $regex: search, $options: "i" } }
                ];
            }
            if (stage) query.stage = stage;
            if (assignedRM) {
                if (query.assignedRM && query.assignedRM.$in) {
                    const allowed = query.assignedRM.$in.map(id => id.toString());
                    if (allowed.includes(assignedRM.toString())) {
                        query.assignedRM = assignedRM;
                    }
                } else if (!query.assignedRM) {
                    query.assignedRM = assignedRM;
                }
            }
            if (leadPoolId) query.leadPoolId = leadPoolId;

            const total = await leadModel.countDocuments(query);
            const leads = await leadModel.find(query)
                .populate('assignedRM', 'fullName emailAddress mobileNumber')
                .populate('leadPoolId', 'name description pullSize maxPerStaff isActive')
                .skip((page - 1) * limit)
                .limit(parseInt(limit))
                .sort({ createdAt: -1 });

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
            // Move stage to Contacted if it was New
            if (lead.stage === 'New') {
                lead.stage = 'Contacted';
            }
            await lead.save();

            res.status(200).send({ status: 200, message: "Follow-up added successfully", data: { lead } });
        } catch (error) {
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

            // Parse file headers, preview values and sheets
            const { sheetNames, previewRows, columnPreview } = await importService.parseUploadedFile(filePath, ext);

            if (columnPreview.length === 0) {
                // Cleanup temp file
                if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
                return res.status(400).send({ status: 400, message: "File contains no columns or data headers", data: {} });
            }

            // Create background job record
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

            // Calculate matching recommendations
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

    bulkPaste: async (req, res) => {
        try {
            const {
                rawText,
                numbers: inputNumbers,
                leadPoolId: inputPoolId,
                assignedRM,
                stage = 'New',
                duplicateStrategy = 'skip',
                defaultName = ''
            } = req.body;

            const companyId = req.user?.companyId || req.user?.company || "default_company";

            // Extract items from rawText (splitting on line breaks, Enter key, commas, semicolons) or array
            let rawItems = [];
            if (Array.isArray(inputNumbers) && inputNumbers.length > 0) {
                rawItems = inputNumbers;
            } else if (typeof rawText === 'string' && rawText.trim().length > 0) {
                rawItems = rawText.split(/[\r\n\u2028\u2029,;]+/);
            }

            if (rawItems.length === 0) {
                return res.status(400).send({
                    status: 400,
                    message: "No phone numbers provided. Paste numbers separated by new lines or commas.",
                    data: {}
                });
            }

            // Resolve target pool
            let leadPoolId = inputPoolId;
            if (!leadPoolId) {
                const freshPool = await ensureDefaultFreshPool(companyId);
                leadPoolId = freshPool._id;
            }

            // Validate assignedRM if provided (ensure active staff)
            let validRM = null;
            if (assignedRM) {
                const staffDoc = await staffModel.findOne({
                    _id: assignedRM,
                    companyId: companyId,
                    status: { $regex: /^active$/i }
                });
                if (staffDoc) {
                    validRM = staffDoc._id;
                }
            }

            const validLeads = [];
            const seenInBatch = new Set();
            let invalidCount = 0;
            let batchDuplicateCount = 0;

            for (const item of rawItems) {
                const trimmed = String(item || '').trim();
                if (!trimmed) continue;

                const normalized10 = importService.normalizePhone(trimmed);
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
                    fullName: defaultName ? String(defaultName).trim() : '',
                    mobileNumber: normalized10,
                    emailAddress: null,
                    stage: stage || 'New',
                    assignedRM: validRM,
                    leadPoolId: leadPoolId,
                    companyId: companyId,
                    isRead: false
                });
            }

            if (validLeads.length === 0) {
                return res.status(400).send({
                    status: 400,
                    message: `No valid 10-digit mobile numbers found (Processed ${rawItems.length} entries, ${invalidCount} invalid).`,
                    data: { totalReceived: rawItems.length, invalidCount }
                });
            }

            // Check duplicates against existing DB leads
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
            let dbDuplicateCount = 0;
            const leadsToInsert = [];

            for (const leadData of validLeads) {
                const existing = existingMap.get(leadData.mobileNumber);
                if (existing) {
                    dbDuplicateCount++;
                    if (duplicateStrategy === 'update') {
                        if (validRM) existing.assignedRM = validRM;
                        if (leadPoolId) existing.leadPoolId = leadPoolId;
                        if (stage) existing.stage = stage;
                        await existing.save();
                        updatedCount++;
                    }
                } else {
                    leadsToInsert.push(leadData);
                }
            }

            if (leadsToInsert.length > 0) {
                await leadModel.insertMany(leadsToInsert);
                insertedCount = leadsToInsert.length;
            }

            return res.status(200).send({
                status: 200,
                message: `Successfully processed ${validLeads.length} unique numbers: ${insertedCount} inserted, ${dbDuplicateCount} existing duplicates (${duplicateStrategy === 'update' ? `${updatedCount} updated` : 'skipped'}), ${invalidCount} invalid.`,
                data: {
                    totalReceived: rawItems.length,
                    validUnique: validLeads.length,
                    insertedCount,
                    updatedCount,
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

    getTemplate: (req, res) => {
        try {
            res.setHeader('Content-Type', 'text/csv');
            res.setHeader('Content-Disposition', 'attachment; filename=leads_template.csv');
            const csvContent = "fullName,mobileNumber,emailAddress,city,state\nAmit Sharma,9876543210,amit.sharma@example.com,Mumbai,Maharashtra\nPriya Patel,8765432109,priya.patel@example.com,Ahmedabad,Gujarat\nJohn Doe,7654321098,john.doe@example.com,Bangalore,Karnataka\n";
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
                    // Base sales executives (no subordinates) CANNOT assign leads
                    if (!hierarchy.isSupervisor && (!hierarchy.staffIds || hierarchy.staffIds.length <= 1)) {
                        return res.status(403).send({ status: 403, message: "Only team leaders and administrators can assign leads" });
                    }

                    // A supervisor can reassign leads among their supervised team
                    // Note: Unassigned pool leads (assignedRM: null) must be pulled via the pull system, not cherry-picked
                    leadFilter.assignedRM = { $in: hierarchy.staffIds };

                    if (staffId && !hierarchy.staffIds.some(sid => sid.toString() === staffId.toString())) {
                        return res.status(403).send({ status: 403, message: "Cannot assign leads to staff outside your supervised team" });
                    }
                }
            }

            await leadModel.updateMany(
                leadFilter,
                { $set: { assignedRM: staffId } }
            );

            res.status(200).send({ status: 200, message: "Leads assigned successfully" });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message });
        }
    }
};

export default leadController;
