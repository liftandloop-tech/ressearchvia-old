import importJobModel from "../models/importJobModel.js";
import importTemplateModel from "../models/importTemplateModel.js";
import leadPoolModel from "../models/leadPoolModel.js";
import importService from "../services/importService.js";

const importController = {
    getImportFields: (req, res) => {
        try {
            res.status(200).send({
                status: 200,
                message: "Fields retrieved successfully",
                data: importService.LEAD_IMPORT_FIELDS
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    getPreview: async (req, res) => {
        try {
            const { importId } = req.params;
            const { mapping } = req.body;

            const companyId = req.user.companyId || req.user.company || "default_company";

            const job = await importJobModel.findById(importId);
            if (!job) {
                return res.status(404).send({ status: 404, message: "Import job not found", data: {} });
            }

            // Verify company access
            if (job.companyId !== companyId) {
                return res.status(403).send({ status: 403, message: "Unauthorized access to import job", data: {} });
            }

            if (!mapping) {
                return res.status(400).send({ status: 400, message: "Mapping is required", data: {} });
            }

            const previewData = await importService.runPreviewValidation(importId, mapping);
            res.status(200).send({
                status: 200,
                message: "Preview validation generated successfully",
                data: previewData
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    startImport: async (req, res) => {
        try {
            const { importId } = req.params;
            const { mapping, selectedSheet, importOptions } = req.body;

            const companyId = req.user.companyId || req.user.company || "default_company";

            const job = await importJobModel.findById(importId);
            if (!job) {
                return res.status(404).send({ status: 404, message: "Import job not found", data: {} });
            }

            // Verify company access
            if (job.companyId !== companyId) {
                return res.status(403).send({ status: 403, message: "Unauthorized access to import job", data: {} });
            }

            let leadPoolId = null;
            if (importOptions && importOptions.leadPoolId) {
                leadPoolId = importOptions.leadPoolId;
                // Verify the leadPoolId belongs to the same companyId
                const pool = await leadPoolModel.findOne({ _id: leadPoolId, companyId });
                if (!pool) {
                    return res.status(400).send({ status: 400, message: "The selected Lead Pool is invalid or belongs to another company", data: {} });
                }
            }

            // Save configuration
            job.mapping = mapping;
            if (selectedSheet) job.selectedSheet = selectedSheet;
            if (importOptions) {
                job.importOptions = {
                    duplicateHandling: importOptions.duplicateHandling || 'skip',
                    assignedRM: importOptions.assignedRM || null,
                    stage: importOptions.stage || 'New',
                    leadPoolId: leadPoolId
                };
            }
            job.status = 'processing';
            await job.save();

            // Run in background asynchronously
            setTimeout(() => {
                importService.runImportJob(job._id).catch(err => {
                    console.error("Failed executing background import job:", err);
                });
            }, 50);

            res.status(200).send({
                status: 200,
                message: "Import processing started in background",
                data: { importId: job._id, status: job.status }
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    getImportStatus: async (req, res) => {
        try {
            const { importId } = req.params;
            const companyId = req.user.companyId || req.user.company || "default_company";

            const job = await importJobModel.findById(importId);
            if (!job) {
                return res.status(404).send({ status: 404, message: "Import job not found", data: {} });
            }

            if (job.companyId !== companyId) {
                return res.status(403).send({ status: 403, message: "Unauthorized access to import job", data: {} });
            }

            res.status(200).send({
                status: 200,
                message: "Import status retrieved successfully",
                data: {
                    importId: job._id,
                    status: job.status,
                    totalRows: job.totalRows,
                    processedRows: job.processedRows,
                    successfulRows: job.successfulRows,
                    failedRows: job.failedRows,
                    duplicateRows: job.duplicateRows,
                    completedAt: job.completedAt
                }
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    getImportErrors: async (req, res) => {
        try {
            const { importId } = req.params;
            const companyId = req.user.companyId || req.user.company || "default_company";

            const job = await importJobModel.findById(importId);
            if (!job) {
                return res.status(404).send({ status: 404, message: "Import job not found", data: {} });
            }

            if (job.companyId !== companyId) {
                return res.status(403).send({ status: 403, message: "Unauthorized access to import job", data: {} });
            }

            res.status(200).send({
                status: 200,
                message: "Import errors retrieved successfully",
                data: job.errors
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    getTemplates: async (req, res) => {
        try {
            const companyId = req.user.companyId || req.user.company || "default_company";
            const templates = await importTemplateModel.find({ companyId }).sort({ createdAt: -1 });
            res.status(200).send({
                status: 200,
                message: "Templates retrieved successfully",
                data: templates
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    saveTemplate: async (req, res) => {
        try {
            const { name, mappings } = req.body;
            if (!name || !mappings) {
                return res.status(400).send({ status: 400, message: "Name and mappings are required", data: {} });
            }

            const companyId = req.user.companyId || req.user.company || "default_company";

            const template = await importTemplateModel.findOneAndUpdate(
                { companyId, name },
                { mappings },
                { new: true, upsert: true }
            );

            res.status(200).send({
                status: 200,
                message: "Template saved successfully",
                data: template
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    }
};

export default importController;
