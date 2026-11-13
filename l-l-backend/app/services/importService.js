import xlsx from "xlsx";
import fs from "fs";
import csvParser from "csv-parser";
import leadModel from "../models/leadModel.js";
import importJobModel from "../models/importJobModel.js";
import leadTimelineModel from "../models/leadTimelineModel.js";
import { ensureDefaultFreshPool } from "../controller/leadPoolController.js";

// Helper to generate A, B, C... AA column letters
function getColumnLetter(colIndex) {
    let temp = colIndex;
    let letter = "";
    while (temp > 0) {
        let modulo = (temp - 1) % 26;
        letter = String.fromCharCode(65 + modulo) + letter;
        temp = Math.floor((temp - modulo) / 26);
    }
    return letter;
}

// Clean and normalize phone numbers strictly to 10 digits (e.g. +91 98765 43210, 09876543210, 0919876543210 -> 9876543210)
function normalizePhone(phone) {
    if (!phone) return "";
    let clean = String(phone).replace(/\D/g, '');
    if (clean.length === 10) return clean;
    if (clean.length === 11 && clean.startsWith('0')) return clean.slice(1);
    if (clean.length === 12 && clean.startsWith('91')) return clean.slice(2);
    if (clean.length === 13 && clean.startsWith('091')) return clean.slice(3);
    if (clean.length > 10) {
        const last10 = clean.slice(-10);
        if (/^[6-9]\d{9}$/.test(last10)) return last10;
    }
    return clean;
}

// Unified mapping, extraction, and validation pipeline
function transformAndValidateRow(row, mapping, rowNum) {
    const getRowValue = (row, crmFieldKey) => {
        let mappingVal;
        if (mapping && typeof mapping.get === 'function') {
            mappingVal = mapping.get(crmFieldKey);
        } else if (mapping) {
            mappingVal = mapping[crmFieldKey];
        }
        if (!mappingVal) return null;

        if (typeof mappingVal === 'number' || !isNaN(mappingVal)) {
            const idx = parseInt(mappingVal) - 1;
            const keys = Object.keys(row);
            if (idx >= 0 && idx < keys.length) {
                return row[keys[idx]];
            }
        }

        return row[mappingVal] || null;
    };

    const fullName = String(getRowValue(row, 'fullName') || '').trim();
    const rawPhone = String(getRowValue(row, 'mobileNumber') || '').trim();
    const rawAltPhone = String(getRowValue(row, 'alternateMobile') || '').trim();
    const email = String(getRowValue(row, 'emailAddress') || '').trim();
    const city = String(getRowValue(row, 'city') || '').trim();
    const state = String(getRowValue(row, 'state') || '').trim();
    const remarks = String(getRowValue(row, 'remarks') || '').trim();

    const errors = [];
    let isMissingMobile = false;

    if (!rawPhone) {
        isMissingMobile = true;
        errors.push("Missing phone number");
    }

    const phone = normalizePhone(rawPhone);
    if (rawPhone && (!phone || phone.length < 10)) {
        errors.push(`Invalid phone number: "${rawPhone}"`);
    }

    const altPhone = rawAltPhone ? normalizePhone(rawAltPhone) : "";

    if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
        errors.push(`Invalid email address: "${email}"`);
    }

    return {
        rowNumber: rowNum,
        isValid: errors.length === 0,
        isMissingMobile,
        errors,
        mappedData: {
            fullName,
            mobileNumber: phone || rawPhone,
            alternateMobile: altPhone,
            emailAddress: email || null,
            remarks: remarks || "",
            personalDetails: {
                city: city || null,
                state: state || null
            }
        }
    };
}

const importService = {
    normalizePhone,
    LEAD_IMPORT_FIELDS: [
        { key: "fullName", label: "Full Name", type: "text", required: false },
        { key: "mobileNumber", label: "Mobile Number", type: "phone", required: true },
        { key: "alternateMobile", label: "Alternate Mobile", type: "phone", required: false },
        { key: "emailAddress", label: "Email Address", type: "email", required: false },
        { key: "city", label: "City", type: "text", required: false, path: "personalDetails.city" },
        { key: "state", label: "State", type: "text", required: false, path: "personalDetails.state" },
        { key: "remarks", label: "Remarks / Notes", type: "text", required: false }
    ],

    parseUploadedFile: async (filePath, ext) => {
        let sheetNames = [];
        let previewRows = [];
        let columnPreview = [];

        if (ext === 'csv') {
            sheetNames = ['Default CSV Sheet'];
            const rows = [];
            await new Promise((resolve, reject) => {
                fs.createReadStream(filePath)
                    .pipe(csvParser())
                    .on('data', (data) => {
                        if (rows.length < 50) rows.push(data);
                    })
                    .on('end', resolve)
                    .on('error', reject);
            });

            if (rows.length > 0) {
                previewRows = rows.slice(0, 10);
                const headers = Object.keys(rows[0]);
                columnPreview = headers.map((header, index) => {
                    const colIdx = index + 1;
                    const sampleValues = rows.slice(0, 5).map(r => r[header]).filter(v => v !== undefined && v !== null);
                    return {
                        index: colIdx,
                        letter: getColumnLetter(colIdx),
                        header: header,
                        sampleValues: sampleValues.map(v => String(v))
                    };
                });
            }
        } else {
            // Excel File handling
            const workbook = xlsx.readFile(filePath);
            sheetNames = workbook.SheetNames;
            const firstSheet = workbook.Sheets[sheetNames[0]];
            const jsonData = xlsx.utils.sheet_to_json(firstSheet, { header: 1 });

            if (jsonData.length > 0) {
                const rawHeaders = jsonData[0] || [];
                const headers = rawHeaders.map((h, i) => (h ? String(h).trim() : `Column ${getColumnLetter(i + 1)}`));
                const dataRows = jsonData.slice(1, 11);

                previewRows = dataRows.map(row => {
                    const obj = {};
                    headers.forEach((h, i) => {
                        obj[h] = row[i] !== undefined ? row[i] : null;
                    });
                    return obj;
                });

                columnPreview = headers.map((header, index) => {
                    const colIdx = index + 1;
                    const sampleValues = dataRows.map(r => r[index]).filter(v => v !== undefined && v !== null);
                    return {
                        index: colIdx,
                        letter: getColumnLetter(colIdx),
                        header: header,
                        sampleValues: sampleValues.map(v => String(v))
                    };
                });
            }
        }

        return { sheetNames, previewRows, columnPreview };
    },

    calculateSuggestions: (columnPreview) => {
        const mapping = {};
        columnPreview.forEach(col => {
            const h = col.header.toLowerCase();
            if (h.includes("full name") || h.includes("client name") || h.includes("customer name") || (h.includes("name") && !h.includes("company"))) {
                mapping["fullName"] = col.header;
            } else if (h.includes("alt") || h.includes("alternate") || h.includes("whatsapp") || h.includes("secondary")) {
                mapping["alternateMobile"] = col.header;
            } else if (h.includes("phone") || h.includes("mobile") || h.includes("contact") || h.includes("cell")) {
                mapping["mobileNumber"] = col.header;
            } else if (h.includes("email") || h.includes("mail")) {
                mapping["emailAddress"] = col.header;
            } else if (h.includes("city") || h.includes("town") || h.includes("district")) {
                mapping["city"] = col.header;
            } else if (h.includes("state") || h.includes("province") || h.includes("region")) {
                mapping["state"] = col.header;
            } else if (h.includes("remark") || h.includes("note") || h.includes("comment") || h.includes("description")) {
                mapping["remarks"] = col.header;
            }
        });
        return mapping;
    },

    runPreviewValidation: async (importId, mapping) => {
        const job = await importJobModel.findById(importId);
        if (!job) throw new Error("Import job not found");

        const filePath = job.filePath;
        const ext = filePath.split('.').pop().toLowerCase();
        let rows = [];

        if (ext === 'csv') {
            await new Promise((resolve, reject) => {
                fs.createReadStream(filePath)
                    .pipe(csvParser())
                    .on('data', (data) => rows.push(data))
                    .on('end', resolve)
                    .on('error', reject);
            });
        } else {
            const workbook = xlsx.readFile(filePath);
            const sheet = workbook.Sheets[job.selectedSheet || workbook.SheetNames[0]];
            rows = xlsx.utils.sheet_to_json(sheet);
        }

        const totalRows = rows.length;
        let validRows = 0;
        let invalidRows = 0;
        let missingMobileRows = 0;
        let duplicateInFileRows = 0;
        const seenInFile = new Set();
        const validPhones = [];
        const validatedRows = [];

        for (let i = 0; i < rows.length; i++) {
            const row = rows[i];
            const validated = transformAndValidateRow(row, mapping, i + 2);

            if (validated.isMissingMobile) {
                missingMobileRows++;
            }

            if (!validated.isValid) {
                invalidRows++;
            } else {
                validRows++;
                const p = validated.mappedData.mobileNumber;
                if (seenInFile.has(p)) {
                    duplicateInFileRows++;
                } else {
                    seenInFile.add(p);
                }
                validPhones.push(p);
            }

            if (i < 10) {
                validatedRows.push(validated);
            }
        }

        // Check duplicates against database
        const existingLeads = await leadModel.find({
            companyId: job.companyId,
            mobileNumber: { $in: validPhones }
        }).select('mobileNumber').lean();

        const dbDuplicateCount = existingLeads.length;
        const totalDuplicateRows = dbDuplicateCount + duplicateInFileRows;

        return {
            totalRows,
            validRows,
            invalidRows,
            missingMobileRows,
            duplicateInFileRows,
            dbDuplicateCount,
            duplicateRows: totalDuplicateRows,
            sampleRows: validatedRows
        };
    },

    runImportJob: async (importId) => {
        const job = await importJobModel.findById(importId);
        if (!job) return;

        try {
            const filePath = job.filePath;
            const ext = filePath.split('.').pop().toLowerCase();
            let rows = [];

            if (ext === 'csv') {
                await new Promise((resolve, reject) => {
                    fs.createReadStream(filePath)
                        .pipe(csvParser())
                        .on('data', (data) => rows.push(data))
                        .on('end', resolve)
                        .on('error', reject);
                });
            } else {
                const workbook = xlsx.readFile(filePath);
                const sheet = workbook.Sheets[job.selectedSheet || workbook.SheetNames[0]];
                rows = xlsx.utils.sheet_to_json(sheet);
            }

            job.totalRows = rows.length;
            await job.save();

            const companyId = job.companyId;
            let leadPoolId = job.importOptions?.leadPoolId;
            if (!leadPoolId) {
                const defaultFreshPool = await ensureDefaultFreshPool(companyId);
                leadPoolId = defaultFreshPool._id;
            }

            const assignedRM = job.importOptions?.assignedRM || null;
            const campaignId = job.importOptions?.campaignId || null;
            const leadVendorId = job.importOptions?.leadVendorId || null;
            const leadStage = job.importOptions?.stage || 'New';
            const duplicateStrategy = job.importOptions?.duplicatePolicy || job.importOptions?.duplicateHandling || 'skip';

            const batchSize = 100;
            let createdCount = 0;
            let updatedCount = 0;
            let skippedCount = 0;
            let failedCount = 0;
            let duplicateCount = 0;
            const errorLogs = [];
            const seenPhones = new Set();

            for (let i = 0; i < rows.length; i += batchSize) {
                const batch = rows.slice(i, i + batchSize);
                const leadsToInsert = [];
                const timelineToInsert = [];

                for (let r = 0; r < batch.length; r++) {
                    const row = batch[r];
                    const rowNum = i + r + 2;

                    const result = transformAndValidateRow(row, job.mapping, rowNum);
                    if (!result.isValid) {
                        errorLogs.push({ rowNumber: rowNum, errorText: result.errors.join(", "), rawData: row });
                        failedCount++;
                        continue;
                    }

                    const phone = result.mappedData.mobileNumber;
                    const altPhone = result.mappedData.alternateMobile;
                    const email = result.mappedData.emailAddress;
                    const fullName = result.mappedData.fullName;
                    const city = result.mappedData.personalDetails.city;
                    const state = result.mappedData.personalDetails.state;
                    const remarks = result.mappedData.remarks;

                    // Check existing duplicate in DB or current batch
                    const existingLead = await leadModel.findOne({ mobileNumber: phone, companyId });
                    const isDupInBatch = seenPhones.has(phone);

                    if (existingLead || isDupInBatch) {
                        duplicateCount++;
                        if (duplicateStrategy === 'skip') {
                            skippedCount++;
                            continue;
                        } else if (duplicateStrategy === 'overwrite' || duplicateStrategy === 'update') {
                            if (existingLead) {
                                const changes = [];
                                if (fullName && existingLead.fullName !== fullName) {
                                    changes.push(`Name: ${existingLead.fullName || 'empty'} -> ${fullName}`);
                                    existingLead.fullName = fullName;
                                }
                                if (altPhone) existingLead.alternateMobile = altPhone;
                                if (email && existingLead.emailAddress !== email) {
                                    changes.push(`Email: ${existingLead.emailAddress || 'empty'} -> ${email}`);
                                    existingLead.emailAddress = email;
                                }
                                if (city) existingLead.personalDetails.city = city;
                                if (state) existingLead.personalDetails.state = state;
                                if (remarks) existingLead.remarks = remarks;
                                if (campaignId) existingLead.campaignId = campaignId;
                                if (leadVendorId) existingLead.leadVendorId = leadVendorId;
                                if (leadPoolId) existingLead.leadPoolId = leadPoolId;
                                if (assignedRM) existingLead.assignedRM = assignedRM;
                                if (leadStage && !['Won', 'Lost', 'Invalid'].includes(existingLead.stage)) {
                                    existingLead.stage = leadStage;
                                }
                                existingLead.importBatchId = job._id;
                                await existingLead.save();

                                // Audit timeline entry for overwrite
                                await leadTimelineModel.create({
                                    leadId: existingLead._id,
                                    companyId,
                                    eventType: 'LEAD_OVERWRITTEN',
                                    title: 'Lead Overwritten via Import',
                                    description: `Lead updated from file "${job.fileName}" (Overwrite mode). ${changes.join(', ')}`,
                                    metadata: { importBatchId: job._id, fileName: job.fileName },
                                    performedBy: { staffId: job.userId, name: 'Import System' }
                                });
                            }
                            updatedCount++;
                            continue;
                        }
                    }
                    seenPhones.add(phone);

                    // New lead document
                    const newLeadDoc = {
                        fullName,
                        mobileNumber: phone,
                        alternateMobile: altPhone,
                        emailAddress: email || null,
                        stage: leadStage,
                        assignedRM: assignedRM,
                        campaignId: campaignId,
                        leadVendorId: leadVendorId,
                        leadPoolId: leadPoolId,
                        companyId: companyId,
                        remarks: remarks || "",
                        importBatchId: job._id,
                        leadSource: 'IMPORTED_POOL',
                        personalDetails: {
                            city: city || null,
                            state: state || null
                        }
                    };
                    leadsToInsert.push(newLeadDoc);
                }

                if (leadsToInsert.length > 0) {
                    const inserted = await leadModel.insertMany(leadsToInsert);
                    createdCount += inserted.length;

                    // Create timeline entries for created leads
                    const timelines = inserted.map(l => ({
                        leadId: l._id,
                        companyId,
                        eventType: 'LEAD_CREATED',
                        title: 'Lead Created via File Import',
                        description: `Lead ingested from "${job.fileName}" into pool`,
                        metadata: { importBatchId: job._id, fileName: job.fileName },
                        performedBy: { staffId: job.userId, name: 'Import Wizard' }
                    }));
                    await leadTimelineModel.insertMany(timelines);
                }

                // Update job metrics periodically
                job.processedRows = i + batch.length;
                job.successfulRows = createdCount + updatedCount;
                job.createdRows = createdCount;
                job.updatedRows = updatedCount;
                job.skippedRows = skippedCount;
                job.failedRows = failedCount;
                job.duplicateRows = duplicateCount;
                await job.save();
            }

            // Wrap up job details
            job.status = errorLogs.length > 0 ? 'completed_with_errors' : 'completed';
            job.errors = errorLogs;
            job.completedAt = new Date();
            await job.save();

            // Safe cleanup of temp files
            if (fs.existsSync(filePath)) {
                fs.unlinkSync(filePath);
            }
        } catch (error) {
            console.error("Error executing lead import job:", error);
            job.status = 'failed';
            job.errors.push({ rowNumber: 0, errorText: error.message, rawData: {} });
            await job.save();
        }
    }
};

export default importService;
