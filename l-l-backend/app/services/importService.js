import xlsx from "xlsx";
import fs from "fs";
import csvParser from "csv-parser";
import leadModel from "../models/leadModel.js";
import importJobModel from "../models/importJobModel.js";
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

// Clean and normalize phone numbers (e.g. +91 98765 43210 -> 9876543210)
function normalizePhone(phone) {
    if (!phone) return "";
    let clean = String(phone).replace(/[^0-9]/g, '');
    if (clean.length > 10) {
        // Strip country code if present (like 91 at front)
        if (clean.startsWith('91') && clean.length === 12) {
            clean = clean.slice(2);
        }
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
    const email = String(getRowValue(row, 'emailAddress') || '').trim();
    const city = String(getRowValue(row, 'city') || '').trim();
    const state = String(getRowValue(row, 'state') || '').trim();

    const errors = [];


    const phone = normalizePhone(rawPhone);
    if (!phone || phone.length < 10) {
        errors.push(`Invalid or missing phone number: "${rawPhone}"`);
    }

    if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
        errors.push(`Invalid email address: "${email}"`);
    }

    return {
        rowNumber: rowNum,
        isValid: errors.length === 0,
        errors,
        mappedData: {
            fullName,
            mobileNumber: phone || rawPhone,
            emailAddress: email || null,
            personalDetails: {
                city: city || null,
                state: state || null
            }
        }
    };
}

const importService = {
    LEAD_IMPORT_FIELDS: [
        { key: "fullName", label: "Full Name", type: "text", required: false },
        { key: "mobileNumber", label: "Mobile Number", type: "phone", required: true },
        { key: "emailAddress", label: "Email Address", type: "email", required: false },
        { key: "city", label: "City", type: "text", required: false, path: "personalDetails.city" },
        { key: "state", label: "State", type: "text", required: false, path: "personalDetails.state" }
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
                        sampleValues: sampleValues.map(String)
                    };
                });
            }
        } else {
            // Excel parsing
            const workbook = xlsx.readFile(filePath);
            sheetNames = workbook.SheetNames;
            const defaultSheet = workbook.Sheets[sheetNames[0]];
            const rawData = xlsx.utils.sheet_to_json(defaultSheet, { header: 1 });

            if (rawData.length > 0) {
                const headers = rawData[0].map(h => String(h || '').trim());
                previewRows = xlsx.utils.sheet_to_json(defaultSheet).slice(0, 10);

                columnPreview = headers.map((header, index) => {
                    const colIdx = index + 1;
                    const sampleValues = [];
                    for (let r = 1; r < Math.min(rawData.length, 6); r++) {
                        if (rawData[r] && rawData[r][index] !== undefined) {
                            sampleValues.push(String(rawData[r][index]));
                        }
                    }
                    return {
                        index: colIdx,
                        letter: getColumnLetter(colIdx),
                        header: header || `Column ${colIdx}`,
                        sampleValues: sampleValues
                    };
                });
            }
        }

        return { sheetNames, previewRows, columnPreview };
    },

    calculateSuggestions: (columns) => {
        const fieldAliases = {
            fullName: [/name/i, /full.*name/i, /customer.*name/i, /fname/i],
            mobileNumber: [/phone/i, /mobile/i, /contact/i, /whatsapp/i, /tel/i, /number/i],
            emailAddress: [/email/i, /mail/i, /e-mail/i],
            city: [/city/i, /town/i, /location/i],
            state: [/state/i, /region/i, /province/i]
        };

        const suggested = {};

        for (const field of importService.LEAD_IMPORT_FIELDS) {
            let bestCol = null;
            let maxConfidence = 0;

            for (const col of columns) {
                const header = col.header.toLowerCase();
                const aliases = fieldAliases[field.key] || [];

                for (let i = 0; i < aliases.length; i++) {
                    if (aliases[i].test(header)) {
                        // Earlier match rules in the array have higher confidence
                        const confidence = Math.max(0, 100 - (i * 15));
                        if (confidence > maxConfidence) {
                            maxConfidence = confidence;
                            bestCol = col.index;
                        }
                    }
                }
            }

            if (bestCol) {
                suggested[field.key] = {
                    columnIndex: bestCol,
                    confidence: maxConfidence
                };
            }
        }

        return suggested;
    },

    // Executed on the frontend mapped data preview pass
    runPreviewValidation: async (jobId, mapping) => {
        const job = await importJobModel.findById(jobId);
        if (!job) throw new Error("Import job not found");

        const ext = job.fileName.split('.').pop().toLowerCase();
        const filePath = job.filePath;
        let rows = [];

        if (ext === 'csv') {
            await new Promise((resolve, reject) => {
                fs.createReadStream(filePath)
                    .pipe(csvParser())
                    .on('data', (data) => {
                        if (rows.length < 10) rows.push(data);
                    })
                    .on('end', resolve)
                    .on('error', reject);
            });
        } else {
            const workbook = xlsx.readFile(filePath);
            const sheetName = job.selectedSheet || workbook.SheetNames[0];
            const sheet = workbook.Sheets[sheetName];
            rows = xlsx.utils.sheet_to_json(sheet).slice(0, 10);
        }

        return rows.map((row, index) => {
            return transformAndValidateRow(row, mapping, index + 2);
        });
    },

    runImportJob: async (jobId) => {
        const job = await importJobModel.findById(jobId);
        if (!job) return;

        job.status = 'processing';
        await job.save();

        try {
            const ext = job.fileName.split('.').pop().toLowerCase();
            const filePath = job.filePath;
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
                const sheetName = job.selectedSheet || workbook.SheetNames[0];
                const sheet = workbook.Sheets[sheetName];
                rows = xlsx.utils.sheet_to_json(sheet);
            }

            job.totalRows = rows.length;
            await job.save();

            const batchSize = 100;
            const duplicateStrategy = job.importOptions.duplicateHandling || 'skip';
            const assignedRM = job.importOptions.assignedRM || null;
            const leadStage = job.importOptions.stage || 'New';
            const companyId = job.companyId || "default_company";

            // Resolve pool: use explicitly selected pool or default to Fresh Leads
            let leadPoolId = job.importOptions.leadPoolId || null;
            if (!leadPoolId) {
                const freshPool = await ensureDefaultFreshPool(companyId);
                leadPoolId = freshPool._id;
            }

            let successfulCount = 0;
            let failedCount = 0;
            let duplicateCount = 0;
            const errorLogs = [];
            const seenPhones = new Set();

            for (let i = 0; i < rows.length; i += batchSize) {
                const batch = rows.slice(i, i + batchSize);
                const leadsToInsert = [];

                for (let r = 0; r < batch.length; r++) {
                    const row = batch[r];
                    const rowNum = i + r + 2; // +1 header row +1 1-based index

                    const result = transformAndValidateRow(row, job.mapping, rowNum);
                    if (!result.isValid) {
                        errorLogs.push({ rowNumber: rowNum, errorText: result.errors.join(", "), rawData: row });
                        failedCount++;
                        continue;
                    }

                    const phone = result.mappedData.mobileNumber;
                    const email = result.mappedData.emailAddress;
                    const fullName = result.mappedData.fullName;
                    const city = result.mappedData.personalDetails.city;
                    const state = result.mappedData.personalDetails.state;

                    // Duplicate Lead Resolution
                    const existingLead = await leadModel.findOne({ mobileNumber: phone, companyId });
                    if (existingLead || seenPhones.has(phone)) {
                        duplicateCount++;
                        if (duplicateStrategy === 'skip') {
                            continue;
                        } else if (duplicateStrategy === 'update') {
                            if (existingLead) {
                                existingLead.fullName = fullName;
                                if (email) existingLead.emailAddress = email;
                                if (city) existingLead.personalDetails.city = city;
                                if (state) existingLead.personalDetails.state = state;
                                if (assignedRM) existingLead.assignedRM = assignedRM;
                                if (leadPoolId) existingLead.leadPoolId = leadPoolId;
                                await existingLead.save();
                            } else {
                                // Update inside current insert batch
                                const match = leadsToInsert.find(l => l.mobileNumber === phone);
                                if (match) {
                                    match.fullName = fullName;
                                    if (email) match.emailAddress = email;
                                    if (city) match.personalDetails.city = city;
                                    if (state) match.personalDetails.state = state;
                                    if (leadPoolId) match.leadPoolId = leadPoolId;
                                }
                            }
                            successfulCount++;
                            continue;
                        }
                    }
                    seenPhones.add(phone);

                    // Prepare for insert
                    leadsToInsert.push({
                        fullName,
                        mobileNumber: phone,
                        emailAddress: email || null,
                        stage: leadStage,
                        assignedRM: assignedRM,
                        leadPoolId: leadPoolId,
                        companyId: companyId,
                        personalDetails: {
                            city: city || null,
                            state: state || null
                        }
                    });
                }

                if (leadsToInsert.length > 0) {
                    await leadModel.insertMany(leadsToInsert);
                    successfulCount += leadsToInsert.length;
                }

                // Update job metrics periodically
                job.processedRows = i + batch.length;
                job.successfulRows = successfulCount;
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
