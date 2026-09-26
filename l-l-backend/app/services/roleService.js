import roleModel from "../models/roleModel.js";
import permissionGroupModel from "../models/permissionGroupModel.js";
import permissionGroupService from "./permissionGroupService.js";
import departmentModel from "../models/departmentModel.js";

const roleService = {
    seedAdminRole: async () => {
        try {
            // First make sure the admin group is seeded
            await permissionGroupService.seedAdminGroup();

            const adminDept = await departmentModel.findOne({ code: 'ADMIN' });
            const adminGroup = await permissionGroupModel.findOne({ name: 'admin' });
            if (!adminGroup) {
                console.error('Cannot seed Admin role: admin permission group not found');
                return;
            }

            const adminRole = await roleModel.findOne({ name: 'Admin' });
            if (!adminRole) {
                await roleModel.create({
                    name: 'Admin',
                    description: 'Default Administrator Role',
                    departmentId: adminDept ? adminDept._id : null,
                    permissionGroups: [adminGroup._id]
                });
                console.log('Default "Admin" role seeded successfully.');
            } else {
                let updated = false;
                if (!adminRole.permissionGroups.includes(adminGroup._id)) {
                    adminRole.permissionGroups.push(adminGroup._id);
                    updated = true;
                }
                if (adminDept && !adminRole.departmentId) {
                    adminRole.departmentId = adminDept._id;
                    updated = true;
                }
                if (updated) {
                    await adminRole.save();
                }
            }
        } catch (error) {
            console.error('Error seeding admin role:', error);
        }
    },

    createRole: async ({ body }) => {
        try {
            const { name, code, level = 1, description, departmentId, permissionGroups, isActive = true } = body;
            if (!name) {
                return { status: 400, message: "Name is required", data: {} };
            }
            const existing = await roleModel.findOne({ name });
            if (existing) {
                return { status: 400, message: "Role with this name already exists", data: {} };
            }

            let validDeptId = null;
            if (departmentId) {
                const dept = await departmentModel.findById(departmentId);
                if (dept) validDeptId = dept._id;
            }

            const role = await roleModel.create({
                name,
                code: code ? code.trim().toUpperCase() : null,
                level: Number(level) || 1,
                description,
                departmentId: validDeptId,
                permissionGroups,
                isActive: Boolean(isActive)
            });
            const populated = await roleModel.findById(role._id).populate("departmentId").populate("permissionGroups");
            return { status: 200, message: "Role created successfully", data: populated };
        } catch (error) {
            return { status: 400, message: error.message, data: {} };
        }
    },

    getRoles: async (req = {}) => {
        try {
            const query = {};
            if (req.query?.departmentId) {
                query.departmentId = req.query.departmentId;
            }
            const roles = await roleModel.find(query).sort({ level: 1, createdAt: 1 }).populate("departmentId").populate("permissionGroups");
            return { status: 200, message: "Roles retrieved successfully", data: roles };
        } catch (error) {
            return { status: 400, message: error.message, data: {} };
        }
    },

    getRoleById: async ({ params }) => {
        try {
            const { id } = params;
            const role = await roleModel.findById(id).populate("departmentId").populate("permissionGroups");
            if (!role) {
                return { status: 404, message: "Role not found", data: {} };
            }
            return { status: 200, message: "Role retrieved successfully", data: role };
        } catch (error) {
            return { status: 400, message: error.message, data: {} };
        }
    },

    updateRole: async ({ params, body }) => {
        try {
            const { id } = params;
            const { name, code, level, description, departmentId, permissionGroups, isActive } = body;
            const role = await roleModel.findById(id);
            if (!role) {
                return { status: 404, message: "Role not found", data: {} };
            }

            if (role.name === 'Admin' && name && name !== 'Admin') {
                return { status: 400, message: "Cannot rename the default Admin role", data: {} };
            }

            if (name) role.name = name;
            if (code !== undefined) role.code = code ? code.trim().toUpperCase() : null;
            if (level !== undefined) role.level = Number(level) || 1;
            if (description !== undefined) role.description = description;
            if (departmentId !== undefined) {
                if (departmentId) {
                    const dept = await departmentModel.findById(departmentId);
                    role.departmentId = dept ? dept._id : null;
                } else {
                    role.departmentId = null;
                }
            }
            if (permissionGroups) role.permissionGroups = permissionGroups;
            if (isActive !== undefined) role.isActive = Boolean(isActive);

            await role.save();
            const populated = await roleModel.findById(role._id).populate("departmentId").populate("permissionGroups");
            return { status: 200, message: "Role updated successfully", data: populated };
        } catch (error) {
            return { status: 400, message: error.message, data: {} };
        }
    },

    deleteRole: async ({ params }) => {
        try {
            const { id } = params;
            const role = await roleModel.findById(id);
            if (!role) {
                return { status: 404, message: "Role not found", data: {} };
            }
            if (role.name === 'Admin') {
                return { status: 400, message: "Cannot delete the default Admin role", data: {} };
            }
            await roleModel.findByIdAndDelete(id);
            return { status: 200, message: "Role deleted successfully", data: {} };
        } catch (error) {
            return { status: 400, message: error.message, data: {} };
        }
    }
};

export default roleService;
