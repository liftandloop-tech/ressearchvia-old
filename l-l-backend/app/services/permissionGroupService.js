import permissionGroupModel from "../models/permissionGroupModel.js";
import { PERMISSION_REGISTRY } from "../config/permissionRegistry.js";
import departmentService from "./departmentService.js";
import departmentModel from "../models/departmentModel.js";

const permissionGroupService = {
    seedAdminGroup: async () => {
        try {
            // First seed default departments
            await departmentService.seedDefaultDepartments();

            const adminDept = await departmentModel.findOne({ code: 'ADMIN' });
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
                    departmentId: adminDept ? adminDept._id : null,
                    permissions: fullPermissions
                });
                console.log('Default "admin" permission group seeded successfully.');
            } else {
                // Ensure default admin group always possesses all permissions and admin department
                adminGroup.permissions = fullPermissions;
                if (adminDept && !adminGroup.departmentId) {
                    adminGroup.departmentId = adminDept._id;
                }
                await adminGroup.save();
            }
        } catch (error) {
            console.error('Error seeding admin permission group:', error);
        }
    },

    createPermissionGroup: async ({ body }) => {
        try {
            const { name, description, departmentId, permissions } = body;
            if (!name) {
                return { status: 400, message: "Name is required", data: {} };
            }
            const existing = await permissionGroupModel.findOne({ name });
            if (existing) {
                return { status: 400, message: "Permission Group with this name already exists", data: {} };
            }

            let validDeptId = null;
            if (departmentId) {
                const dept = await departmentModel.findById(departmentId);
                if (dept) {
                    validDeptId = dept._id;
                }
            }

            const group = await permissionGroupModel.create({
                name,
                description,
                departmentId: validDeptId,
                permissions
            });
            const populated = await permissionGroupModel.findById(group._id).populate('departmentId');
            return { status: 200, message: "Permission group created successfully", data: populated };
        } catch (error) {
            return { status: 400, message: error.message, data: {} };
        }
    },

    getPermissionGroups: async (req = {}) => {
        try {
            const query = {};
            if (req.query?.departmentId) {
                query.departmentId = req.query.departmentId;
            }
            const groups = await permissionGroupModel.find(query).populate('departmentId');
            return { status: 200, message: "Permission groups retrieved successfully", data: groups };
        } catch (error) {
            return { status: 400, message: error.message, data: {} };
        }
    },

    getPermissionGroupById: async ({ params }) => {
        try {
            const { id } = params;
            const group = await permissionGroupModel.findById(id).populate('departmentId');
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
            const { name, description, departmentId, permissions } = body;
            const group = await permissionGroupModel.findById(id);
            if (!group) {
                return { status: 404, message: "Permission group not found", data: {} };
            }

            if (group.name === 'admin' && name && name !== 'admin') {
                return { status: 400, message: "Cannot rename the default admin group", data: {} };
            }

            if (name) group.name = name;
            if (description !== undefined) group.description = description;
            if (departmentId !== undefined) {
                if (departmentId) {
                    const dept = await departmentModel.findById(departmentId);
                    group.departmentId = dept ? dept._id : null;
                } else {
                    group.departmentId = null;
                }
            }
            if (permissions) group.permissions = permissions;

            await group.save();
            const populated = await permissionGroupModel.findById(group._id).populate('departmentId');
            return { status: 200, message: "Permission group updated successfully", data: populated };
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
