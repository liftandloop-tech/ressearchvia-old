import branchService from "../services/branchService.js";

const branchController = {
    getBranches: async (req, res) => {
        try {
            const response = await branchService.getBranches(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: [] });
        }
    },

    getBranchById: async (req, res) => {
        try {
            const response = await branchService.getBranchById(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },

    createBranch: async (req, res) => {
        try {
            const response = await branchService.createBranch(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },

    updateBranch: async (req, res) => {
        try {
            const response = await branchService.updateBranch(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },

    deleteBranch: async (req, res) => {
        try {
            const response = await branchService.deleteBranch(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    }
};

export default branchController;

