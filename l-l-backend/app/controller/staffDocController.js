import staffModel from "../models/staffModel.js";

const staffDocController = {
    uploadDocument: async (req, res) => {
        try {
            const { id } = req.params;
            const { type } = req.query; // 'pan', 'aadhaar', 'nism', 'education'
            if (!req.file) {
                return res.status(400).send({ status: 400, message: "No file uploaded", data: {} });
            }
            const staff = await staffModel.findById(id);
            if (!staff) {
                return res.status(404).send({ status: 404, message: "Staff not found", data: {} });
            }
            const fieldMap = {
                pan: 'panUrl',
                aadhaar: 'aadhaarUrl',
                nism: 'nismUrl',
                education: 'highestEducationUrl'
            };
            const field = fieldMap[type];
            if (!field) {
                return res.status(400).send({ status: 400, message: "Invalid document type", data: {} });
            }
            staff[field] = req.file.filename;
            
            // Update onboarding status based on available documents
            if (staff.panUrl && staff.aadhaarUrl && staff.nismUrl && staff.highestEducationUrl) {
                staff.onboardingStatus = staff.kycVideoUrl ? 'VERIFIED' : 'DOCUMENTS_UPLOADED';
            }
            await staff.save();
            res.status(200).send({ status: 200, message: `${type} uploaded successfully`, data: { staff } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },
    uploadVideo: async (req, res) => {
        try {
            const { id } = req.params;
            if (!req.file) {
                return res.status(400).send({ status: 400, message: "No video file uploaded", data: {} });
            }
            const staff = await staffModel.findById(id);
            if (!staff) {
                return res.status(404).send({ status: 404, message: "Staff not found", data: {} });
            }
            staff.kycVideoUrl = req.file.filename;
            if (staff.panUrl && staff.aadhaarUrl && staff.nismUrl && staff.highestEducationUrl) {
                staff.onboardingStatus = 'VERIFIED';
            }
            await staff.save();
            res.status(200).send({ status: 200, message: "KYC Video uploaded successfully", data: { staff } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    }
};

export default staffDocController;
