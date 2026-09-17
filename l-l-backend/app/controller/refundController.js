import refundService from "../services/refundService.js";

const refundController = {
    /**
     * Preview refund calculation based on tenure/usage
     */
    previewRefund: async (req, res) => {
        try {
            const response = await refundService.previewRefundCalculation({ body: req.body });
            return res.status(response.status).send(response);
        } catch (error) {
            console.error("[refundController.previewRefund] Error:", error);
            return res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    /**
     * Process a refund for a user (Admin Only)
     */
    processRefund: async (req, res) => {
        try {
            const adminUser = req.adminUser || req.user;
            const response = await refundService.processRefund({
                body: req.body,
                adminUser
            });
            return res.status(response.status).send(response);
        } catch (error) {
            console.error("[refundController.processRefund] Error:", error);
            return res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    /**
     * Fetch user refund history
     */
    getUserRefunds: async (req, res) => {
        try {
            const response = await refundService.getUserRefundHistory({ params: req.params });
            return res.status(response.status).send(response);
        } catch (error) {
            console.error("[refundController.getUserRefunds] Error:", error);
            return res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    }
};

export default refundController;
