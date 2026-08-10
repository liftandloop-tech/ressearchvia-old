import roleModel from "../models/roleModel.js";
import permissionGroupModel from "../models/permissionGroupModel.js";
import permissionGroupService from "./permissionGroupService.js";

const roleService = {
    seedAdminRole: async () => {
        try {
            // First make sure the admin group is seeded
            await permissionGroupService.seedAdminGroup();

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
                    permissionGroups: [adminGroup._id]
                });
                console.log('Default "Admin" role seeded successfully.');
            } else {
                // Ensure it is associated with the admin group
                if (!adminRole.permissionGroups.includes(adminGroup._id)) {
                    adminRole.permissionGroups.push(adminGroup._id);
                    await adminRole.save();
                }
            }
        } catch (error) {
            console.error('Error seeding admin role:', error);
        }
    },

    createRole: async ({ body }) => {
        try {
            const { name, description, permissionGroups } = body;
            if (!name) {
                return { status: 400, message: "Name is required", data: {} };
            }
            const existing = await roleModel.findOne({ name });
            if (existing) {
                return { status: 400, message: "Role with this name already exists", data: {} };
            }
            const role = await roleModel.create({ name, description, permissionGroups });
            return { status: 200, message: "Role created successfully", data: role };
        } catch (error) {
            return { status: 400, message: error.message, data: {} };
        }
    },

    getRoles: async () => {
        try {
            const roles = await roleModel.find({}).populate("permissionGroups");
            return { status: 200, message: "Roles retrieved successfully", data: roles };
        } catch (error) {
            return { status: 400, message: error.message, data: {} };
        }
    },

    getRoleById: async ({ params }) => {
        try {
            const { id } = params;
            const role = await roleModel.findById(id).populate("permissionGroups");
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
            const { name, description, permissionGroups } = body;
            const role = await roleModel.findById(id);
            if (!role) {
                return { status: 404, message: "Role not found", data: {} };
            }

            if (role.name === 'Admin' && name && name !== 'Admin') {
                return { status: 400, message: "Cannot rename the default Admin role", data: {} };
            }

            if (name) role.name = name;
            if (description !== undefined) role.description = description;
            if (permissionGroups) role.permissionGroups = permissionGroups;

            await role.save();
            return { status: 200, message: "Role updated successfully", data: role };
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
