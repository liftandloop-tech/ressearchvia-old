import leadModel from "../models/leadModel.js";
import xlsx from "xlsx";
import fs from "fs";
import csvParser from "csv-parser";

const leadController = {
    createLead: async (req, res) => {
        try {
            const lead = await leadModel.create(req.body);
            res.status(200).send({ status: 200, message: "Lead created successfully", data: { lead } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    updateLead: async (req, res) => {
        try {
            const { id } = req.params;
            const lead = await leadModel.findByIdAndUpdate(id, req.body, { new: true });
            if (!lead) {
                return res.status(404).send({ status: 404, message: "Lead not found", data: {} });
            }
            res.status(200).send({ status: 200, message: "Lead updated successfully", data: { lead } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    listLeads: async (req, res) => {
        try {
            const { page = 1, limit = 10, search = "", stage = "", assignedRM = "" } = req.query;
            const query = {};

            if (search) {
                query.$or = [
                    { fullName: { $regex: search, $options: "i" } },
                    { mobileNumber: { $regex: search, $options: "i" } },
                    { emailAddress: { $regex: search, $options: "i" } }
                ];
            }
            if (stage) query.stage = stage;
            if (assignedRM) query.assignedRM = assignedRM;

            const total = await leadModel.countDocuments(query);
            const leads = await leadModel.find(query)
                .populate('assignedRM', 'fullName emailAddress mobileNumber')
                .skip((page - 1) * limit)
                .limit(parseInt(limit))
                .sort({ createdAt: -1 });

            res.status(200).send({ status: 200, message: "Leads fetched successfully", data: { total, leads, page, limit } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    addFollowUp: async (req, res) => {
        try {
            const { id } = req.params;
            const { notes, followUpDate } = req.body;
            if (!notes || !followUpDate) {
                return res.status(400).send({ status: 400, message: "Notes and followUpDate are required", data: {} });
            }

            const lead = await leadModel.findById(id);
            if (!lead) {
                return res.status(404).send({ status: 404, message: "Lead not found", data: {} });
            }

            lead.followUps.push({ notes, followUpDate });
            // Move stage to Contacted if it was New
            if (lead.stage === 'New') {
                lead.stage = 'Contacted';
            }
            await lead.save();

            res.status(200).send({ status: 200, message: "Follow-up added successfully", data: { lead } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    bulkUpload: async (req, res) => {
        try {
            if (!req.file) {
                return res.status(400).send({ status: 400, message: "Please upload an Excel or CSV file", data: {} });
            }

            const filePath = req.file.path;
            const ext = req.file.originalname.split('.').pop().toLowerCase();
            let leadsToInsert = [];

            if (ext === 'csv') {
                const results = [];
                await new Promise((resolve, reject) => {
                    fs.createReadStream(filePath)
                        .pipe(csvParser())
                        .on('data', (data) => results.push(data))
                        .on('end', resolve)
                        .on('error', reject);
                });

                leadsToInsert = results.map(row => ({
                    fullName: row.fullName || row.name || row.FullName || row.Name,
                    mobileNumber: row.mobileNumber || row.phone || row.Mobile || row.Phone,
                    emailAddress: row.emailAddress || row.email || row.Email || null,
                    personalDetails: {
                        city: row.city || null,
                        state: row.state || null
                    }
                }));
            } else {
                // Excel parse
                const workbook = xlsx.readFile(filePath);
                const sheetName = workbook.SheetNames[0];
                const sheet = workbook.Sheets[sheetName];
                const data = xlsx.utils.sheet_to_json(sheet);

                leadsToInsert = data.map(row => ({
                    fullName: row.fullName || row.name || row.FullName || row.Name,
                    mobileNumber: String(row.mobileNumber || row.phone || row.Mobile || row.Phone || ''),
                    emailAddress: row.emailAddress || row.email || row.Email || null,
                    personalDetails: {
                        city: row.city || null,
                        state: row.state || null
                    }
                }));
            }

            // Cleanup temp file
            fs.unlinkSync(filePath);

            // Filter out empty names or phones
            const validLeads = leadsToInsert.filter(l => l.fullName && l.mobileNumber);
            if (validLeads.length === 0) {
                return res.status(400).send({ status: 400, message: "No valid lead records found in file", data: {} });
            }

            const createdLeads = await leadModel.insertMany(validLeads);
            res.status(200).send({
                status: 200,
                message: `Successfully uploaded ${createdLeads.length} leads`,
                data: { count: createdLeads.length }
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    getTemplate: (req, res) => {
        try {
            res.setHeader('Content-Type', 'text/csv');
            res.setHeader('Content-Disposition', 'attachment; filename=leads_template.csv');
            const csvContent = "fullName,mobileNumber,emailAddress,city,state\nAmit Sharma,9876543210,amit.sharma@example.com,Mumbai,Maharashtra\nPriya Patel,8765432109,priya.patel@example.com,Ahmedabad,Gujarat\nJohn Doe,7654321098,john.doe@example.com,Bangalore,Karnataka\n";
            res.status(200).send(csvContent);
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    }
};

export default leadController;
