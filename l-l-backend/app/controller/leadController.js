import leadModel from "../models/leadModel.js";
import staffModel from "../models/staffModel.js";
import xlsx from "xlsx";
import fs from "fs";
import csvParser from "csv-parser";
import importService from "../services/importService.js";
import importJobModel from "../models/importJobModel.js";
import { ensureDefaultFreshPool } from "./leadPoolController.js";
import { getSupervisedStaffIds } from "../utils/staffHierarchy.js";

const leadController = {
    createLead: async (req, res) => {
        try {
            const companyId = req.user.companyId || req.user.company || "default_company";
            let { leadPoolId } = req.body;
            if (!leadPoolId) {
                const defaultPool = await ensureDefaultFreshPool(companyId);
                leadPoolId = defaultPool._id;
            }
            const lead = await leadModel.create({
                ...req.body,
                companyId,
                leadPoolId
            });
            res.status(200).send({ status: 200, message: "Lead created successfully", data: { lead } });
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
                }
            }

            const lead = await leadModel.findOneAndUpdate(filter, req.body, { new: true });
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

            // Data-Scope Enforcement: If user has leads.view_assigned but not leads.view_all, restrict query to assignedRM
            const callerId = req.user?._id || req.user?.userId || req.user?.id;
            const isSuper = req.user?.userType === 'admin' || req.user?.userType === 'super_admin' || req.user?.role === 'Admin';
            if (!isSuper && callerId) {
                const hierarchy = await getSupervisedStaffIds(callerId);
                if (!hierarchy.isSystemAdmin) {
                    const staffMember = hierarchy.staffMember;
                    if (staffMember && staffMember.roleId && staffMember.roleId.permissionGroups) {
                        const hasViewAll = staffMember.roleId.permissionGroups.some(g =>
                            g.permissions?.some(p => p.actions?.includes('leads.view_all'))
                        );
                        const hasViewAssigned = staffMember.roleId.permissionGroups.some(g =>
                            g.permissions?.some(p => p.actions?.includes('leads.view_assigned') || p.actions?.includes('read'))
                        );

                        if (hasViewAssigned && !hasViewAll) {
                            if (hierarchy.staffIds && hierarchy.staffIds.length > 1) {
                                query.assignedRM = { $in: hierarchy.staffIds };
                            } else {
                                query.assignedRM = staffMember._id;
                            }
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
                    leadFilter.$or = [
                        { assignedRM: { $in: hierarchy.staffIds } },
                        { assignedRM: null }
                    ];

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
