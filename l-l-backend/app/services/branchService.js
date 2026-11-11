import branchModel from "../models/branchModel.js";
import staffModel from "../models/staffModel.js";
import applicantModel from "../models/applicantModel.js";

const DEFAULT_BRANCHES = [
    {
        name: 'Indore',
        code: 'IND',
        city: 'Indore',
        state: 'Madhya Pradesh',
        isActive: true
    },
    {
        name: 'Jabalpur',
        code: 'JBP',
        city: 'Jabalpur',
        state: 'Madhya Pradesh',
        isActive: true
    },
    {
        name: 'Bhopal',
        code: 'BPL',
        city: 'Bhopal',
        state: 'Madhya Pradesh',
        isActive: true
    },
    {
        name: 'Jaipur',
        code: 'JPR',
        city: 'Jaipur',
        state: 'Rajasthan',
        isActive: true
    }
];

const branchService = {
    seedDefaultBranches: async () => {
        try {
            const count = await branchModel.countDocuments();
            if (count === 0) {
                for (const b of DEFAULT_BRANCHES) {
                    await branchModel.create(b);
                }
                console.log("Default branches seeded: Indore, Jabalpur, Bhopal, Jaipur");
            }
        } catch (error) {
            console.error("Error seeding default branches:", error);
        }
    },

    getBranches: async (req) => {
        try {
            const companyId = req.user?.companyId || "default_company";
            const { isActive, search } = req.query;

            const query = {
                $or: [
                    { companyId },
                    { companyId: "default_company" },
                    { companyId: { $exists: false } }
                ]
            };

            if (isActive !== undefined) {
                query.isActive = isActive === 'true' || isActive === true;
            }

            if (search && search.trim()) {
                const s = search.trim();
                query.$and = [
                    {
                        $or: [
                            { name: { $regex: s, $options: 'i' } },
                            { code: { $regex: s, $options: 'i' } },
                            { city: { $regex: s, $options: 'i' } }
                        ]
                    }
                ];
            }

            const branches = await branchModel.find(query).sort({ name: 1 }).lean();

            // Enrich each branch with active staff count and applicant count
            const enriched = await Promise.all(branches.map(async (b) => {
                const activeStaffCount = await staffModel.countDocuments({
                    branchId: b._id,
                    isDeleted: false,
                    status: 'Active'
                });
                const totalStaffCount = await staffModel.countDocuments({
                    branchId: b._id,
                    isDeleted: false
                });
                const applicantCount = await applicantModel.countDocuments({
                    branchId: b._id,
                    isDeleted: false
                });

                return {
                    ...b,
                    activeStaffCount,
                    totalStaffCount,
                    staffCount: activeStaffCount,
                    applicantCount
                };
            }));

            return {
                status: 200,
                message: "Branches retrieved successfully",
                data: enriched
            };
        } catch (error) {
            return { status: 400, message: error.message, data: [] };
        }
    },

    getBranchById: async (req) => {
        try {
            const { id } = req.params;
            const branch = await branchModel.findById(id).lean();
            if (!branch) {
                return { status: 404, message: "Branch not found", data: {} };
            }

            const activeStaffCount = await staffModel.countDocuments({
                branchId: branch._id,
                isDeleted: false,
                status: 'Active'
            });
            const totalStaffCount = await staffModel.countDocuments({
                branchId: branch._id,
                isDeleted: false
            });

            return {
                status: 200,
                message: "Branch retrieved successfully",
                data: {
                    ...branch,
                    activeStaffCount,
                    totalStaffCount,
                    staffCount: activeStaffCount
                }
            };
        } catch (error) {
            return { status: 400, message: error.message, data: {} };
        }
    },

    createBranch: async (req) => {
        try {
            const { name, code, city, state, address, pincode, isActive } = req.body;
            const companyId = req.user?.companyId || "default_company";
            const createdBy = req.user?._id || req.user?.id || null;

            if (!name || !name.trim()) {
                return { status: 400, message: "Branch name is required", data: {} };
            }

            const trimmedName = name.trim();
            const existing = await branchModel.findOne({
                name: { $regex: new RegExp(`^${trimmedName}$`, 'i') }
            });

            if (existing) {
                return { status: 400, message: `Branch "${trimmedName}" already exists`, data: {} };
            }

            const branchCode = (code && code.trim())
                ? code.trim().toUpperCase()
                : trimmedName.substring(0, 3).toUpperCase();

            const branch = await branchModel.create({
                name: trimmedName,
                code: branchCode,
                city: city?.trim() || trimmedName,
                state: state?.trim() || "Madhya Pradesh",
                address: address?.trim() || null,
                pincode: pincode?.trim() || null,
                isActive: isActive !== false,
                companyId,
                createdBy
            });

            return {
                status: 201,
                message: "Branch created successfully",
                data: branch
            };
        } catch (error) {
            return { status: 400, message: error.message, data: {} };
        }
    },

    updateBranch: async (req) => {
        try {
            const { id } = req.params;
            const { name, code, city, state, address, pincode, isActive } = req.body;

            const branch = await branchModel.findById(id);
            if (!branch) {
                return { status: 404, message: "Branch not found", data: {} };
            }

            let nameChanged = false;
            if (name && name.trim() && name.trim() !== branch.name) {
                const trimmedName = name.trim();
                const duplicate = await branchModel.findOne({
                    _id: { $ne: id },
                    name: { $regex: new RegExp(`^${trimmedName}$`, 'i') }
                });
                if (duplicate) {
                    return { status: 400, message: `Another branch with name "${trimmedName}" already exists`, data: {} };
                }
                branch.name = trimmedName;
                nameChanged = true;
            }

            if (code !== undefined) {
                branch.code = code ? code.trim().toUpperCase() : null;
            }
            if (city !== undefined) branch.city = city?.trim() || null;
            if (state !== undefined) branch.state = state?.trim() || null;
            if (address !== undefined) branch.address = address?.trim() || null;
            if (pincode !== undefined) branch.pincode = pincode?.trim() || null;
            if (isActive !== undefined) branch.isActive = Boolean(isActive);

            await branch.save();

            // If name changed, synchronize branchName in staff and applicant collections
            if (nameChanged) {
                await staffModel.updateMany(
                    { branchId: id },
                    { $set: { branchName: branch.name } }
                );
                await applicantModel.updateMany(
                    { branchId: id },
                    { $set: { branchName: branch.name } }
                );
            }

            return {
                status: 200,
                message: "Branch updated successfully",
                data: branch
            };
        } catch (error) {
            return { status: 400, message: error.message, data: {} };
        }
    },

    deleteBranch: async (req) => {
        try {
            const { id } = req.params;
            const branch = await branchModel.findById(id);
            if (!branch) {
                return { status: 404, message: "Branch not found", data: {} };
            }

            // Check if active staff are assigned
            const activeStaffCount = await staffModel.countDocuments({
                branchId: id,
                isDeleted: false,
                status: 'Active'
            });

            if (activeStaffCount > 0) {
                return {
                    status: 400,
                    message: `Cannot delete branch "${branch.name}". It currently has ${activeStaffCount} active staff member${activeStaffCount === 1 ? '' : 's'} assigned. Please reassign staff first.`,
                    data: {}
                };
            }

            // Deactivate or delete
            await branchModel.findByIdAndDelete(id);

            // Clean up unassigned references in non-active staff / applicants
            await staffModel.updateMany(
                { branchId: id },
                { $set: { branchId: null, branchName: null } }
            );
            await applicantModel.updateMany(
                { branchId: id },
                { $set: { branchId: null, branchName: null } }
            );

            return {
                status: 200,
                message: `Branch "${branch.name}" deleted successfully`,
                data: {}
            };
        } catch (error) {
            return { status: 400, message: error.message, data: {} };
        }
    }
};

export default branchService;

