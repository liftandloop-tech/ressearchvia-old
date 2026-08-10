import leadPoolModel from "../models/leadPoolModel.js";

const ensureDefaultFreshPool = async (companyId) => {
    let pool = await leadPoolModel.findOne({ companyId, name: "Fresh Leads" });
    if (!pool) {
        pool = await leadPoolModel.create({
            companyId,
            name: "Fresh Leads",
            description: "Default lead pool for incoming fresh leads"
        });
    }
    return pool;
};

const leadPoolController = {
    listLeadPools: async (req, res) => {
        try {
            const companyId = req.user.companyId || req.user.company || "default_company";
            await ensureDefaultFreshPool(companyId);
            const pools = await leadPoolModel.find({ companyId }).sort({ createdAt: -1 });
            res.status(200).send({
                status: 200,
                message: "Lead pools retrieved successfully",
                data: pools
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    createLeadPool: async (req, res) => {
        try {
            const { name, description } = req.body;
            if (!name || String(name).trim().length === 0) {
                return res.status(400).send({ status: 400, message: "Name is required and cannot be empty", data: {} });
            }

            if (String(name).trim() === "Fresh Leads") {
                return res.status(400).send({ status: 400, message: "Fresh Leads is a system reserved pool name", data: {} });
            }

            const companyId = req.user.companyId || req.user.company || "default_company";

            // Prevent duplicate pool names within the same company
            const exists = await leadPoolModel.findOne({ companyId, name: name.trim() });
            if (exists) {
                return res.status(400).send({ status: 400, message: "Lead pool with this name already exists", data: {} });
            }

            const pool = await leadPoolModel.create({
                companyId,
                name: name.trim(),
                description
            });

            res.status(200).send({
                status: 200,
                message: "Lead pool created successfully",
                data: pool
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    }
};

export { ensureDefaultFreshPool };
export default leadPoolController;
