import departmentModel from "../models/departmentModel.js";
import { AVAILABLE_DEPARTMENT_PAGES } from "../config/departmentPages.js";
import permissionGroupModel from "../models/permissionGroupModel.js";
import roleModel from "../models/roleModel.js";
import staffModel from "../models/staffModel.js";

const DEFAULT_DEPARTMENTS = [
    {
        name: 'Administration & Management',
        code: 'ADMIN',
        description: 'Complete cross-departmental access to all system features, security settings, and operations.',
        isGlobal: true,
        assignedPages: AVAILABLE_DEPARTMENT_PAGES.map(p => p.key)
    },
    {
        name: 'Research & Advisory',
        code: 'RESEARCH',
        description: 'Market research, equity reports, market publications, and advisory plan entitlements.',
        isGlobal: false,
        assignedPages: ['Reports', 'Subscriptions']
    },
    {
        name: 'Sales & Relationship Management',
        code: 'SALES',
        description: 'Lead generation, sales caller pools, client follow-ups, and engagement broadcasts.',
        isGlobal: false,
        assignedPages: ['Leads', 'Users', 'Notifications']
    },
    {
        name: 'Operations & Compliance',
        code: 'OPERATIONS',
        description: 'KYC identity approvals, user account compliance, payment verification, and onboarding.',
        isGlobal: false,
        assignedPages: ['Users', 'KYC', 'Payments']
    }
];

const departmentService = {
    seedDefaultDepartments: async () => {
        try {
            for (const deptDef of DEFAULT_DEPARTMENTS) {
                const existing = await departmentModel.findOne({
                    $or: [
                        { name: { $regex: new RegExp(`^${deptDef.name}$`, 'i') } },
                        { code: deptDef.code }
                    ]
                });
                if (!existing) {
                    await departmentModel.create(deptDef);
                    console.log(`Default department seeded: "${deptDef.name}" (${deptDef.code})`);
                }
            }

            // Link admin permission group to Admin department if not already set
            const adminDept = await departmentModel.findOne({ code: 'ADMIN' });
            if (adminDept) {
                await permissionGroupModel.updateMany(
                    { name: 'admin', departmentId: null },
                    { $set: { departmentId: adminDept._id } }
                );
                await roleModel.updateMany(
                    { name: 'Admin', departmentId: null },
                    { $set: { departmentId: adminDept._id } }
                );
            }
        } catch (error) {
            console.error('Error seeding default departments:', error);
        }
    },

    getAvailablePages: () => {
        return {
            status: 200,
            message: "Available pages retrieved successfully",
            data: AVAILABLE_DEPARTMENT_PAGES
        };
    },

    createDepartment: async ({ body }) => {
        try {
            const { name, code, description, assignedPages = [], isGlobal = false } = body;
            if (!name || !name.trim()) {
                return { status: 400, message: "Department name is required", data: {} };
            }

            const trimmedName = name.trim();
            const existing = await departmentModel.findOne({
                name: { $regex: new RegExp(`^${trimmedName}$`, 'i') }
            });

            if (existing) {
                return { status: 400, message: `Department "${trimmedName}" already exists`, data: {} };
            }

            // Validate that assigned pages exist in AVAILABLE_DEPARTMENT_PAGES
            const validKeys = new Set(AVAILABLE_DEPARTMENT_PAGES.map(p => p.key));
            const filteredPages = assignedPages.filter(p => validKeys.has(p));

            const dept = await departmentModel.create({
                name: trimmedName,
                code: code ? code.trim().toUpperCase() : trimmedName.substring(0, 4).toUpperCase(),
                description: description || null,
                assignedPages: isGlobal ? AVAILABLE_DEPARTMENT_PAGES.map(p => p.key) : filteredPages,
                isGlobal: Boolean(isGlobal),
                isActive: true
            });

            return { status: 200, message: "Department created successfully", data: dept };
        } catch (error) {
            return { status: 400, message: error.message, data: {} };
        }
    },

    getDepartments: async ({ query = {} } = {}) => {
        try {
            const filter = {};
            if (query.activeOnly === 'true') {
                filter.isActive = true;
            }

            const departments = await departmentModel.find(filter).sort({ isGlobal: -1, createdAt: 1 });
            return { status: 200, message: "Departments retrieved successfully", data: departments };
        } catch (error) {
            return { status: 400, message: error.message, data: {} };
        }
    },

    getDepartmentById: async ({ params }) => {
        try {
            const { id } = params;
            const department = await departmentModel.findById(id);
            if (!department) {
                return { status: 404, message: "Department not found", data: {} };
            }
            return { status: 200, message: "Department retrieved successfully", data: department };
        } catch (error) {
            return { status: 400, message: error.message, data: {} };
        }
    },

    updateDepartment: async ({ params, body }) => {
        try {
            const { id } = params;
            const { name, code, description, assignedPages, isGlobal, isActive } = body;

            const department = await departmentModel.findById(id);
            if (!department) {
                return { status: 404, message: "Department not found", data: {} };
            }

            // Prevent modifying the name/code of the built-in ADMIN department
            if (department.code === 'ADMIN' && code && code !== 'ADMIN') {
                return { status: 400, message: "Cannot alter the system ADMIN department code", data: {} };
            }

            if (name && name.trim()) {
                const existing = await departmentModel.findOne({
                    _id: { $ne: id },
                    name: { $regex: new RegExp(`^${name.trim()}$`, 'i') }
                });
                if (existing) {
                    return { status: 400, message: `Another department named "${name.trim()}" already exists`, data: {} };
                }
                department.name = name.trim();
            }

            if (code !== undefined) department.code = code ? code.trim().toUpperCase() : department.code;
            if (description !== undefined) department.description = description;

            if (assignedPages !== undefined) {
                const validKeys = new Set(AVAILABLE_DEPARTMENT_PAGES.map(p => p.key));
                department.assignedPages = department.isGlobal
                    ? AVAILABLE_DEPARTMENT_PAGES.map(p => p.key)
                    : assignedPages.filter(p => validKeys.has(p));
            }

            if (isGlobal !== undefined && department.code !== 'ADMIN') {
                department.isGlobal = Boolean(isGlobal);
            }

            if (isActive !== undefined && department.code !== 'ADMIN') {
                department.isActive = Boolean(isActive);
            }

            await department.save();
            return { status: 200, message: "Department updated successfully", data: department };
        } catch (error) {
            return { status: 400, message: error.message, data: {} };
        }
    },

    deleteDepartment: async ({ params }) => {
        try {
            const { id } = params;
            const department = await departmentModel.findById(id);
            if (!department) {
                return { status: 404, message: "Department not found", data: {} };
            }

            if (department.code === 'ADMIN' || department.isGlobal) {
                return { status: 400, message: "Cannot delete the default Administrator department", data: {} };
            }

            // Check if any active staff, role, or permission group is linked to this department
            const [linkedStaff, linkedRoles, linkedGroups] = await Promise.all([
                staffModel.countDocuments({ departmentId: id }),
                roleModel.countDocuments({ departmentId: id }),
                permissionGroupModel.countDocuments({ departmentId: id })
            ]);

            if (linkedStaff > 0 || linkedRoles > 0 || linkedGroups > 0) {
                return {
                    status: 400,
                    message: `Cannot delete department: It is currently linked to ${linkedStaff} staff member(s), ${linkedRoles} role(s), and ${linkedGroups} permission group(s). Please reassign them first.`,
                    data: { linkedStaff, linkedRoles, linkedGroups }
                };
            }

            await departmentModel.findByIdAndDelete(id);
            return { status: 200, message: "Department deleted successfully", data: {} };
        } catch (error) {
            return { status: 400, message: error.message, data: {} };
        }
    }
};

export default departmentService;
