import reportService from "../services/reportService.js"
const reportsController = {
    createReport: async (req, res) => {
        try {
            const response = await reportService.createReport(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    updateReport: async (req, res) => {
        try {
            const response = await reportService.updateReport(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    reportDownload: async (req, res) => {
        try {
            await reportService.reportDownload(req, res);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    userReportList: async (req, res) => {
        try {
            const response = await reportService.userReportList(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },

    deleteReport: async (req, res) => {
        try {
            const response = await reportService.deleteReport(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },

    publishReportStatus: async (req, res) => {
        try {
            const response = await reportService.publishReportStatus({
                query: req.query,
                body: req.body,
                user: req.user,
                req
            });
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },

    reportList: async (req, res) => {
        try {
            const response = await reportService.reportList(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },

    createAutomatedTradingCall: async (req, res) => {
        try {
            const response = await reportService.createOrUpdateAutomatedTradingCall({
                body: req.body,
                headers: req.headers
            });
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    }

}
export default reportsController