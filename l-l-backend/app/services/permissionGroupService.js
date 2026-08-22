import permissionGroupModel from "../models/permissionGroupModel.js";
import { PERMISSION_REGISTRY } from "../config/permissionRegistry.js";

const permissionGroupService = {
    seedAdminGroup: async () => {
        try {
            const adminGroup = await permissionGroupModel.findOne({ name: 'admin' });

            // Build full permissions list grouped by feature using canonical keys
            const featureMap = {};
            Object.keys(PERMISSION_REGISTRY).forEach(key => {
                const item = PERMISSION_REGISTRY[key];
                if (!featureMap[item.feature]) {
                    featureMap[item.feature] = [];
                }
                featureMap[item.feature].push(key);
            });

            const fullPermissions = Object.entries(featureMap).map(([feature, actions]) => ({
                feature,
                actions
            }));

            if (!adminGroup) {
                await permissionGroupModel.create({
                    name: 'admin',
                    description: 'Default Admin Group with all canonical permissions',
                    permissions: fullPermissions
                });
                console.log('Default "admin" permission group seeded successfully.');
            } else {
                // Ensure default admin group always possesses all permissions
                adminGroup.permissions = fullPermissions;
                await adminGroup.save();
            }
        } catch (error) {
            console.error('Error seeding admin permission group:', error);
        }
    },

    createPermissionGroup: async ({ body }) => {
        try {
            const { name, description, permissions } = body;
            if (!name) {
                return { status: 400, message: "Name is required", data: {} };
            }
            const existing = await permissionGroupModel.findOne({ name });
            if (existing) {
                return { status: 400, message: "Permission Group with this name already exists", data: {} };
            }
            const group = await permissionGroupModel.create({ name, description, permissions });
            return { status: 200, message: "Permission group created successfully", data: group };
        } catch (error) {
            return { status: 400, message: error.message, data: {} };
        }
    },

    getPermissionGroups: async () => {
        try {
            const groups = await permissionGroupModel.find({});
            return { status: 200, message: "Permission groups retrieved successfully", data: groups };
        } catch (error) {
            return { status: 400, message: error.message, data: {} };
        }
    },

    getPermissionGroupById: async ({ params }) => {
        try {
            const { id } = params;
            const group = await permissionGroupModel.findById(id);
            if (!group) {
                return { status: 404, message: "Permission group not found", data: {} };
            }
            return { status: 200, message: "Permission group retrieved successfully", data: group };
        } catch (error) {
            return { status: 400, message: error.message, data: {} };
        }
    },

    updatePermissionGroup: async ({ params, body }) => {
        try {
            const { id } = params;
            const { name, description, permissions } = body;
            const group = await permissionGroupModel.findById(id);
            if (!group) {
                return { status: 404, message: "Permission group not found", data: {} };
            }

            if (group.name === 'admin' && name && name !== 'admin') {
                return { status: 400, message: "Cannot rename the default admin group", data: {} };
            }

            if (name) group.name = name;
            if (description !== undefined) group.description = description;
            if (permissions) group.permissions = permissions;

            await group.save();
            return { status: 200, message: "Permission group updated successfully", data: group };
        } catch (error) {
            return { status: 400, message: error.message, data: {} };
        }
    },

    deletePermissionGroup: async ({ params }) => {
        try {
            const { id } = params;
            const group = await permissionGroupModel.findById(id);
            if (!group) {
                return { status: 404, message: "Permission group not found", data: {} };
            }
            if (group.name === 'admin') {
                return { status: 400, message: "Cannot delete the default admin group", data: {} };
            }
            await permissionGroupModel.findByIdAndDelete(id);
            return { status: 200, message: "Permission group deleted successfully", data: {} };
        } catch (error) {
            return { status: 400, message: error.message, data: {} };
        }
    }
};

export default permissionGroupService;
