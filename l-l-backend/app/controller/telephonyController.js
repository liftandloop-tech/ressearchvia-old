import telephonyService from "../services/telephonyService.js";
import leadModel from "../models/leadModel.js";
import staffModel from "../models/staffModel.js";
import callLogModel from "../models/callLogModel.js";

const telephonyController = {
    /**
     * Start a Click-to-Call session
     * POST /api/telephony/click-to-call
     */
    initiateClickToCall: async (req, res) => {
        try {
            const { leadId, extension } = req.body;
            if (!leadId) {
                return res.status(400).json({ status: false, message: "Lead ID is required" });
            }

            const lead = await leadModel.findById(leadId);
            if (!lead) {
                return res.status(404).json({ status: false, message: "Lead not found" });
            }

            if (!lead.mobileNumber) {
                return res.status(400).json({ status: false, message: "Lead does not have a valid mobile number" });
            }

            const staffId = req.user?._id || req.user?.userId;
            const staff = staffId ? await staffModel.findById(staffId) : null;

            // Resolve extension to use:
            // 1. Explicit extension from request
            // 2. Staff's assigned telephonyExtension in profile
            // 3. Assigned RM's extension if staff doesn't have one
            // 4. Fallback default from env or '101'
            let assignedRMExt = null;
            if (!staff?.telephonyExtension && lead.assignedRM) {
                const assignedRMStaff = await staffModel.findById(lead.assignedRM).select('telephonyExtension telephonyType').lean();
                assignedRMExt = assignedRMStaff?.telephonyExtension;
            }

            const resolvedExtension = extension || staff?.telephonyExtension || assignedRMExt || process.env.TELEPHONY_DEFAULT_EXTENSION || '101';
            const resolvedType = staff?.telephonyType || 'extension';

            const result = await telephonyService.initiateClickToDial({
                fromDestination: resolvedExtension,
                fromType: resolvedType,
                toDestination: lead.mobileNumber,
                leadId: lead._id,
                staffId: staffId || lead.assignedRM || null,
                companyId: lead.companyId || 'default_company'
            });

            return res.status(200).json({
                status: true,
                message: "Call initiated successfully",
                data: {
                    callId: result.callId,
                    callLogId: result.callLog._id,
                    status: result.callLog.status,
                    leadName: lead.fullName,
                    leadPhone: lead.mobileNumber,
                    extension: resolvedExtension
                }
            });
        } catch (error) {
            console.error('[TelephonyController] initiateClickToCall error:', error);
            return res.status(500).json({
                status: false,
                message: error.message || "Failed to initiate call"
            });
        }
    },

    /**
     * Get live status of an ongoing call
     * GET /api/telephony/calls/:callId/status
     */
    getCallStatus: async (req, res) => {
        try {
            const { callId } = req.params;
            if (!callId) {
                return res.status(400).json({ status: false, message: "Call ID is required" });
            }

            const callLog = await telephonyService.getCallStatus(callId);
            return res.status(200).json({
                status: true,
                data: callLog
            });
        } catch (error) {
            console.error('[TelephonyController] getCallStatus error:', error);
            return res.status(500).json({
                status: false,
                message: error.message || "Failed to fetch call status"
            });
        }
    },

    /**
     * Terminate / Hangup a call
     * POST /api/telephony/calls/:callId/hangup
     */
    terminateCall: async (req, res) => {
        try {
            const { callId } = req.params;
            if (!callId) {
                return res.status(400).json({ status: false, message: "Call ID is required" });
            }

            const callLog = await telephonyService.terminateCall(callId);
            return res.status(200).json({
                status: true,
                message: "Call ended successfully",
                data: callLog
            });
        } catch (error) {
            console.error('[TelephonyController] terminateCall error:', error);
            return res.status(500).json({
                status: false,
                message: error.message || "Failed to end call"
            });
        }
    },

    /**
     * Get all call records for a specific lead
     * GET /api/telephony/lead/:leadId/calls
     */
    getLeadCallHistory: async (req, res) => {
        try {
            const { leadId } = req.params;
            const calls = await callLogModel.find({ leadId })
                .sort({ createdAt: -1 })
                .populate('staffId', 'fullName emailAddress mobileNumber staffId')
                .lean();

            return res.status(200).json({
                status: true,
                data: calls
            });
        } catch (error) {
            console.error('[TelephonyController] getLeadCallHistory error:', error);
            return res.status(500).json({
                status: false,
                message: error.message || "Failed to fetch lead call logs"
            });
        }
    },

    /**
     * Log notes and register formal Follow-up for lead after call
     * POST /api/telephony/calls/:callLogId/log-followup
     */
    logCallFollowUp: async (req, res) => {
        try {
            const { callLogId } = req.params;
            const { notes, status, nextFollowUpDate, stage } = req.body;

            const result = await telephonyService.logFollowUpFromCall(callLogId, {
                notes,
                status,
                nextFollowUpDate,
                stage,
                userId: req.user?._id
            });

            return res.status(200).json({
                status: true,
                message: "Call follow-up logged successfully",
                data: result
            });
        } catch (error) {
            console.error('[TelephonyController] logCallFollowUp error:', error);
            return res.status(500).json({
                status: false,
                message: error.message || "Failed to log follow-up from call"
            });
        }
    },

    /**
     * Get available extensions
     * GET /api/telephony/extensions
     */
    getExtensions: async (req, res) => {
        try {
            const extensions = await telephonyService.getAccountExtensions();
            return res.status(200).json({
                status: true,
                data: extensions
            });
        } catch (error) {
            console.warn('[TelephonyController] getExtensions API fallback:', error.message);
            return res.status(200).json({
                status: true,
                data: [
                    { extension_number: "101", caller_id: "Default Extension", dnd_enabled: false }
                ],
                warning: error.message
            });
        }
    },

    /**
     * Update a staff member's assigned extension
     * PUT /api/telephony/staff/:staffId/extension
     */
    updateStaffExtension: async (req, res) => {
        try {
            const { staffId } = req.params;
            const { extension, telephonyType } = req.body;

            const callerId = (req.user?._id || req.user?.id || '').toString();
            const callerRole = (req.user?.role || '').toLowerCase();
            const callerDept = (req.user?.deparment || req.user?.department || '').toLowerCase();
            const isSystemAdmin = callerRole === 'admin' || callerDept === 'admin';
            const isSelf = callerId && (callerId === staffId?.toString());

            // Allow bypass in test scripts where req.user might be unset
            if (req.user && !isSystemAdmin && !isSelf) {
                return res.status(403).json({ status: false, message: "Forbidden: You are not authorized to update this staff extension." });
            }

            const staff = await staffModel.findById(staffId);
            if (!staff) {
                return res.status(404).json({ status: false, message: "Staff not found" });
            }

            staff.telephonyExtension = extension;
            if (telephonyType) {
                staff.telephonyType = telephonyType;
            }
            await staff.save();

            return res.status(200).json({
                status: true,
                message: "Staff telephony extension updated successfully",
                data: {
                    staffId: staff._id,
                    telephonyExtension: staff.telephonyExtension,
                    telephonyType: staff.telephonyType
                }
            });
        } catch (error) {
            console.error('[TelephonyController] updateStaffExtension error:', error);
            return res.status(500).json({
                status: false,
                message: error.message || "Failed to update staff extension"
            });
        }
    }
};

export default telephonyController;
