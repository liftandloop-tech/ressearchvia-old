import roleService from "../services/roleService.js";

const roleController = {
    createRole: async (req, res) => {
        try {
            const response = await roleService.createRole(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    getRoles: async (req, res) => {
        try {
            const response = await roleService.getRoles(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    getRoleById: async (req, res) => {
        try {
            const response = await roleService.getRoleById(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    updateRole: async (req, res) => {
        try {
            const response = await roleService.updateRole(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    deleteRole: async (req, res) => {
        try {
            const response = await roleService.deleteRole(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    }
};

export default roleController;
