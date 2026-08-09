import segmentsService from "../services/segmentsServices.js";


const segmentsController = {
    createSegments: async (req, res) => {
        try {
            const response = await segmentsService.createSegments(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    updateSegments: async (req, res) => {
        try {
            const response = await segmentsService.updateSegments(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    segmentsDelete: async (req, res) => {
        try {
            const response = await segmentsService.segmentsDelete(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    segmentsDropDownList: async (req, res) => {
        try {
            const response = await segmentsService.segmentsDropDownList(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    userSegmentsPlansList: async (req, res) => {
        try {
            const response = await segmentsService.userSegmentsPlansList(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    segmentsPurchase: async (req, res) => {
        try {
            const response = await segmentsService.segmentsPurchase(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    segmentsPaymentVerify: async (req, res) => {
        try {
            const response = await segmentsService.segmentsPaymentVerify(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    getUserActiveSegment: async (req, res) => {
        try {
            const response = await segmentsService.getUserActiveSegment(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    expireSegments: async (req, res) => {
        try {
            const response = await segmentsService.expireSegments(req);
        } catch (error) {
            console.log({ "Error expiring segments:": error })
        }
    },
    segmentInvoice: async (req, res) => {
        try {
            const response = await segmentsService.segmentInvoice(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    segmentPaymentHistroy: async (req, res) => {
        try {
            const response = await segmentsService.segmentPaymentHistroy(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    segmentsPlanCreate: async (req, res) => {
        try {
            const response = await segmentsService.segmentsPlanCreate(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    segmentsPlanUpdate: async (req, res) => {
        try {
            const response = await segmentsService.segmentsPlanUpdate(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    segmentsPlanDelete: async (req, res) => {
        try {
            const response = await segmentsService.segmentsPlanDelete(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    segmentsPlanList: async (req, res) => {
        try {
            const response = await segmentsService.segmentsPlanList(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    userSegmentPlanList: async (req, res) => {
        try {
            const response = await segmentsService.userSegmentPlanList(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    subscriptionsPlanList: async (req, res) => {
        try {
            const response = await segmentsService.subscriptionsPlanList(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    subscriptionsSegmentList: async (req, res) => {
        try {
            const response = await segmentsService.subscriptionsSegmentList(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    getHniRequests: async (req, res) => {
        try {
            const response = await segmentsService.getHniRequests({ query: req.query });
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    adminGrantHniPlan: async (req, res) => {
        try {
            const response = await segmentsService.adminGrantHniPlan({ body: req.body, user: req.user });
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    fixPrices: async (req, res) => {
        try {
            const response = await segmentsService.fixPrices(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message });
        }
    },
    adminGrantSegment: async (req, res) => {
        try {
            const response = await segmentsService.adminGrantSegment({ body: req.body, user: req.user });
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    getPendingBankTransfers: async (req, res) => {
        try {
            const response = await segmentsService.getPendingBankTransfers({ query: req.query });
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    rejectBankTransfer: async (req, res) => {
        try {
            const response = await segmentsService.rejectBankTransfer({ body: req.body });
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    revertApproval: async (req, res) => {
        try {
            const response = await segmentsService.revertApproval({ body: req.body, user: req.user });
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    revertRejection: async (req, res) => {
        try {
            const response = await segmentsService.revertRejection({ body: req.body, user: req.user });
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    }
}
export default segmentsController