import departmentService from "../services/departmentService.js";

const departmentController = {
    getAvailablePages: async (req, res) => {
        try {
            const response = departmentService.getAvailablePages();
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },

    createDepartment: async (req, res) => {
        try {
            const response = await departmentService.createDepartment(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },

    getDepartments: async (req, res) => {
        try {
            const response = await departmentService.getDepartments(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },

    getDepartmentById: async (req, res) => {
        try {
            const response = await departmentService.getDepartmentById(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },

    updateDepartment: async (req, res) => {
        try {
            const response = await departmentService.updateDepartment(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },

    deleteDepartment: async (req, res) => {
        try {
            const response = await departmentService.deleteDepartment(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    }
};

export default departmentController;
