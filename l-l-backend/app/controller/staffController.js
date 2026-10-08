import staffService from "../services/staffService.js";
import { getSupervisedStaffIds } from "../utils/staffHierarchy.js";

const staffController = {
    staffCreate: async (req, res) => {
        try {
            const response = await staffService.staffCreate(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    staffLogin: async (req, res) => {
        try {
            const response = await staffService.staffLogin(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    staffMpinLogin: async (req, res) => {
        try {
            const response = await staffService.staffMpinLogin(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    staffOtpVerify: async (req, res) => {
        try {
            const response = await staffService.staffOtpVerify(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    staffReset: async (req, res) => {
        try {
            const response = await staffService.staffReset(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    staffList: async (req, res) => {
        try {
            const response = await staffService.staffList({ user: req.user, query: req.query });
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    cancleStaff: async (req, res) => {
        try {
            const response = await staffService.cancleStaff(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    StaffAssignment: async (req, res) => {
        try {
            const response = await staffService.StaffAssignment({
                body: req.body,
                user: req.user,
                req
            });
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },

    getStaffAssignedUsers: async (req, res) => {
        try {
            console.log('>>> [BACKEND getStaffAssignedUsers CALLED] query:', req.query);
            // Get staff ID from the authenticated user (from JWT token)
            const staffId = req.user._id;
            const response = await staffService.getStaffAssignedUsers({ staffId, user: req.user, query: req.query });
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },

    getUserAssignedRM: async (req, res) => {
        try {
            const userId = req.user?._id || req.user?.userId || req.user?.id;
            const response = await staffService.getUserAssignedRM({ userId });
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },

    staffImpersonate: async (req, res) => {
        try {
            const response = await staffService.staffImpersonate({
                body: req.body,
                user: req.user
            });
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },

    getPublicStaffVerification: async (req, res) => {
        try {
            const { staffId } = req.params;
            const response = await staffService.getPublicStaffVerification(staffId);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: null });
        }
    },

    getStaffProfileMe: async (req, res) => {
        try {
            const response = await staffService.getStaffProfileMe({ user: req.user });
            res.status(response.status).send(response);
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: null });
        }
    },

    updateStaffProfileMe: async (req, res) => {
        try {
            const response = await staffService.updateStaffProfileMe({ user: req.user, body: req.body });
            res.status(response.status).send(response);
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: null });
        }
    },

    changeStaffMpinMe: async (req, res) => {
        try {
            const response = await staffService.changeStaffMpinMe({ user: req.user, body: req.body });
            res.status(response.status).send(response);
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: null });
        }
    },

    logoutStaff: async (req, res) => {
        try {
            const response = await staffService.logoutStaff({
                headers: req.headers,
                user: req.user,
                token: req.token
            });
            res.status(response.status).send(response);
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: null });
        }
    },

    signAgreement: async (req, res) => {
        try {
            const response = await staffService.signAgreement({
                user: req.user,
                body: req.body,
                req: req
            });
            res.status(response.status).send(response);
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: null });
        }
    },

    initiateDigioAgreement: async (req, res) => {
        try {
            const staffId = req.user?._id || req.user?.userId || req.body?.staffId;
            const origin = req.body?.redirectUrl || req.headers.origin || req.headers.referer;
            let customRedirectUrl = null;
            if (origin) {
              try {
                if (typeof origin === 'string' && origin.startsWith('http')) {
                  const parsed = new URL(origin);
                  customRedirectUrl = `${parsed.origin}/job-terms-agreement?signed=true`;
                }
              } catch (_) {
                if (typeof origin === 'string' && origin.startsWith('http')) {
                  customRedirectUrl = origin.includes('/job-terms-agreement') ? origin : `${origin.replace(/\/+$/, '')}/job-terms-agreement?signed=true`;
                }
              }
            }
            const response = await staffService.initiateStaffDigioAgreement(staffId, customRedirectUrl);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: null });
        }
    },

    getAgreementStatus: async (req, res) => {
        try {
            const staffId = req.query?.staffId || req.user?._id || req.user?.userId;
            const origin = req.headers.origin || req.headers.referer;
            let customRedirectUrl = null;
            if (origin && typeof origin === 'string' && origin.startsWith('http')) {
              try {
                const parsed = new URL(origin);
                customRedirectUrl = `${parsed.origin}/job-terms-agreement?signed=true`;
              } catch (_) {}
            }
            const response = await staffService.getStaffAgreementStatus(staffId, customRedirectUrl);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: null });
        }
    },

    verifyStaffAgreement: async (req, res) => {
        try {
            const { staffId } = req.params;
            const response = await staffService.verifyStaffAgreement(staffId, req.user);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: null });
        }
    },

    rejectStaffAgreement: async (req, res) => {
        try {
            const { staffId } = req.params;
            const { reason } = req.body;
            const response = await staffService.rejectStaffAgreement(staffId, req.user, reason);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: null });
        }
    },

    downloadStaffAgreementDocument: async (req, res) => {
        try {
            const targetStaffId = (req.params.staffId || req.query.staffId || req.user?._id || '').toString();
            const callerId = (req.user?._id || req.user?.id || '').toString();
            const callerRole = (req.user?.role || '').toLowerCase();
            const callerDept = (req.user?.deparment || req.user?.department || '').toLowerCase();
            const isSystemAdmin = callerRole === 'admin' || callerDept === 'admin';
            const isSelf = callerId && (callerId === targetStaffId);

            if (!isSystemAdmin && !isSelf) {
                const hierarchy = await getSupervisedStaffIds(callerId);
                const isSupervisor = hierarchy.isSystemAdmin || (hierarchy.supervisedStaffIds || []).some(id => id.toString() === targetStaffId);
                if (!isSupervisor) {
                    return res.status(403).send({ status: 403, message: "Forbidden: You are not authorized to view this agreement." });
                }
            }

            const response = await staffService.downloadStaffAgreementDocument(targetStaffId);
            if (response.status === 200) {
                const buffer = Buffer.from(response.data);
                res.setHeader('Content-Type', response.contentType || 'application/pdf');
                res.setHeader('Content-Disposition', `inline; filename=${response.filename || 'agreement.pdf'}`);
                res.setHeader('Content-Length', buffer.length);
                return res.end(buffer);
            } else {
                return res.status(response.status).send({ status: response.status, message: response.message });
            }
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message });
        }
    }
};
export default staffController;