import staffService from "../services/staffService.js";

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
            const response = await staffService.staffList({ user: req.user });
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
            // Get user ID from the authenticated user (from JWT token)
            const userId = req.user._id;
            const response = await staffService.getUserAssignedRM({ userId });
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },

}
export default staffController;