import permissionGroupService from "../services/permissionGroupService.js";

const permissionGroupController = {
    createPermissionGroup: async (req, res) => {
        try {
            const response = await permissionGroupService.createPermissionGroup(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    getPermissionGroups: async (req, res) => {
        try {
            const response = await permissionGroupService.getPermissionGroups(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    getPermissionGroupById: async (req, res) => {
        try {
            const response = await permissionGroupService.getPermissionGroupById(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    updatePermissionGroup: async (req, res) => {
        try {
            const response = await permissionGroupService.updatePermissionGroup(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    },
    deletePermissionGroup: async (req, res) => {
        try {
            const response = await permissionGroupService.deletePermissionGroup(req);
            res.status(response.status).send(response);
        } catch (error) {
            res.status(400).send({ status: 400, message: error.message, data: {} });
        }
    }
};

export default permissionGroupController;
