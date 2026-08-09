import userKycModel from "../models/userKycModel.js";
import userDocUploadModel from "../models/userDocUploadModel.js";
import userModel from "../models/userModel.js"
import KycService from "./kycService.js";
import axios from "axios";
import { fileURLToPath } from "url";
import path from "path";
import fs from 'fs'
import FormData from "form-data";
import { PDFDocument, StandardFonts, rgb } from 'pdf-lib'



const userkycService = {
    pancardUpload: async ({ params, body, file }) => {
        try {
            console.log('[PAN Upload] Request received:', { userId: params.id, panNumber: body.panNumber, hasFile: !!file });
            let { id } = params
            let { panNumber } = body
            const cleanPan = panNumber?.toString().trim().toUpperCase();

            // 1. Check Uniqueness
            if (cleanPan) {
                const existingUser = await userModel.findOne({ panNumber: cleanPan, _id: { $ne: id } });
                if (existingUser) {
                    return { status: 400, message: "This PAN card is already registered with another account.", data: {} };
                }
            }

            // 2. Update Legacy Doc Model (Keep for safety)
            let userDoc = await userDocUploadModel.findOne({ userId: id });
            if (!userDoc) {
                userDoc = new userDocUploadModel({
                    userId: id,
                    pancard: {
                        panNumber: cleanPan,
                        fileOriginalName: file.originalname,
                        fileName: file.filename,
                        filePath: file.path
                    }
                });
                await userDoc.save();
            } else {
                userDoc.pancard = {
                    panNumber: cleanPan,
                    fileOriginalName: file.originalname,
                    fileName: file.filename,
                    filePath: file.path
                };
                await userDoc.save();
            }

            // 3. Sync to User Model & State Machine
            const user = await userModel.findById(id);
            if (user) {
                user.kycDocs.panImage = file.filename;
                if (cleanPan) user.panNumber = cleanPan;

                // --- GATE 1 RESET: Re-submission always resets gate to PENDING ---
                // BUG FIX 1 & 3: Gate is reset BEFORE syncOverallStatus so the sync
                // sees the fresh PENDING state, not the old REJECTED/VERIFIED state.
                // Any re-upload (regardless of current status) resets to PENDING.
                if (!user.kycGates) user.kycGates = {};
                if (!user.kycGates.documents) user.kycGates.documents = {};
                user.kycGates.documents.status = 'PENDING';
                user.kycGates.documents.rejectionReason = null;
                user.kycGates.documents.submittedAt = new Date();
                user.markModified('kycGates');
                console.log('[PAN Upload] Document gate reset to PENDING.');

                await user.save();

                // Sync overall status AFTER gate is updated so computed status is accurate
                await KycService.syncOverallStatus(id, { type: 'SYSTEM', id: 'PAN_UPLOAD' });
            }

            return { status: 200, message: "Pancard uploaded", data: { files: userDoc } };
        } catch (error) {
            console.error('[PAN Upload] Error:', error.message);
            return { status: 400, message: error.message, data: {} }
        }

    },
    aadhaarUpload: async ({ params, body, files }) => {
        try {
            console.log('[Aadhaar Upload] Request received:', { userId: params.id, aadhaarNumber: body.aadhaarNumber, filesCount: files?.length });
            let { id } = params
            let { aadhaarNumber } = body

            // 1. Legacy Update
            let userDoc = await userDocUploadModel.findOne({ userId: id })
            if (userDoc) {
                userDoc.aadhaar.aadhaarNumber = aadhaarNumber
                userDoc.aadhaar.front.fileOriginalName = files[0].originalname
                userDoc.aadhaar.front.fileName = files[0].filename
                userDoc.aadhaar.front.filePath = files[0].path

                userDoc.aadhaar.back.fileOriginalName = files[1].originalname
                userDoc.aadhaar.back.fileName = files[1].filename
                userDoc.aadhaar.back.filePath = files[1].path
                await userDoc.save()
            } else {
                userDoc = new userDocUploadModel({
                    userId: id,
                    aadhaar: {
                        aadhaarNumber: aadhaarNumber,
                        front: {
                            fileOriginalName: files[0].originalname,
                            fileName: files[0].filename,
                            filePath: files[0].path
                        },
                        back: {
                            fileOriginalName: files[1].originalname,
                            fileName: files[1].filename,
                            filePath: files[1].path
                        }
                    }
                });
                await userDoc.save();
            }

            // 2. Sync to User Model
            const user = await userModel.findById(id);
            if (user) {
                user.kycDocs.aadhaarFront = files[0].filename;
                user.kycDocs.aadhaarBack = files[1].filename;

                // --- GATE 1 RESET: Re-submission always resets gate to PENDING ---
                // BUG FIX 1 & 3: Gate is reset BEFORE syncOverallStatus so the sync
                // sees the fresh PENDING state, not the old REJECTED/VERIFIED state.
                // Any re-upload (regardless of current status) resets to PENDING.
                if (!user.kycGates) user.kycGates = {};
                if (!user.kycGates.documents) user.kycGates.documents = {};
                user.kycGates.documents.status = 'PENDING';
                user.kycGates.documents.rejectionReason = null;
                user.kycGates.documents.submittedAt = new Date();
                user.markModified('kycGates');
                console.log('[Aadhaar Upload] Document gate reset to PENDING.');

                await user.save();

                // Sync overall status AFTER gate is updated so computed status is accurate
                await KycService.syncOverallStatus(id, { type: 'SYSTEM', id: 'AADHAAR_UPLOAD' });
            }

            return { status: 200, message: "Aadhaar uploaded", data: { files: userDoc } };

        } catch (error) {
            console.error('[Aadhaar Upload] Error:', error.message);
            return { status: 400, message: error.message, data: {} }
        }
    },
    usersDocKyc: async ({ params, body }) => {
        try {
            let { id } = params
            let {
                email,
                name,
                firstName,
                middleName,
                lastName,
                fatherName,
                dob,
                housePvNo,
                street,
                area,
                landmark,
                city,
                pincode,
                state,
                pan // Added pan to destructuring
            } = body

            // GST State Code Map
            const gstStateMap = {
                "01": "Jammu & Kashmir", "02": "Himachal Pradesh", "03": "Punjab", "04": "Chandigarh", "05": "Uttarakhand",
                "06": "Haryana", "07": "Delhi", "08": "Rajasthan", "09": "Uttar Pradesh", "10": "Bihar",
                "11": "Sikkim", "12": "Arunachal Pradesh", "13": "Nagaland", "14": "Manipur", "15": "Mizoram",
                "16": "Tripura", "17": "Meghalaya", "18": "Assam", "19": "West Bengal", "20": "Jharkhand",
                "21": "Odisha", "22": "Chhattisgarh", "23": "Madhya Pradesh", "24": "Gujarat", "25": "Daman & Diu",
                "26": "Dadra & Nagar Haveli and Daman & Diu", "27": "Maharashtra", "28": "Andhra Pradesh", "29": "Karnataka", "30": "Goa",
                "31": "Lakshadweep", "32": "Kerala", "33": "Tamil Nadu", "34": "Puducherry", "35": "Andaman & Nicobar Islands",
                "36": "Telangana", "37": "Andhra Pradesh (New)", "97": "Other Territory", "96": "Other Country"
            };

            // Check if KYC is already verified
            const existingKyc = await userKycModel.findOne({ userId: id });
            if (existingKyc && existingKyc.kycStatus === 'verified') {
                return { status: 200, message: "KYC already verified", data: { digio: existingKyc, kycStatus: 'verified' } };
            }

            let digioResponses = [];
            const __filename = fileURLToPath(import.meta.url);
            const __dirname = path.dirname(__filename);
            let filePath = path.join(__dirname, "../serviceAgreement/service_agreement_final.pdf");
            const existingPdfBytes = fs.readFileSync(filePath);
            const pdfDoc = await PDFDocument.load(existingPdfBytes);
            const pages = {
                page4: pdfDoc.getPage(5),
                page5: pdfDoc.getPage(14),
                page6: pdfDoc.getPage(15),
                page7: pdfDoc.getPage(16),
                page8: pdfDoc.getPage(17),
                page9: pdfDoc.getPage(18),
                page10: pdfDoc.getPage(19),
                page11: pdfDoc.getPage(20),
                page12: pdfDoc.getPage(21),
            };
            const page13 = pdfDoc.getPage(22);
            const valueX = 227;
            const fontSize = 12;
            const userDetails = await userModel.findOne({ _id: id })
            const userName = userDetails.fullName.replace(/\s+/g, "_");
            const u = userDetails?.userObject || {};

            // --- FALLBACK LOGIC START ---

            // Helper to check if value is valid
            const isValid = (val) => val && val !== 'null' && val !== 'undefined' && val.trim() !== '';

            // Construct Full Fallback Object
            // We use the existing 'u' (userObject) as base, but enforce overwrites if missing
            // to ensure we have a "valid" object structure for KRA compliance checks.

            // 1. Name Construction
            let fallbackName = u.APP_NAME;
            if (!isValid(fallbackName)) {
                let fullNameParts = [];
                if (firstName) fullNameParts.push(firstName);
                if (middleName) fullNameParts.push(middleName);
                if (lastName) fullNameParts.push(lastName);
                fallbackName = fullNameParts.join(' ');

                // Final fallback to user's registered name if form name is somehow empty
                if (!fallbackName || fallbackName.trim() === '') {
                    fallbackName = userDetails.fullName;
                }
            }

            // 2. Father Name
            let fallbackFatherName = u.APP_F_NAME;
            if (!isValid(fallbackFatherName) && fatherName) {
                fallbackFatherName = fatherName;
            }

            // 3. DOB
            let fallbackDob = u.APP_DOB_DT;
            if (!isValid(fallbackDob) && dob) {
                fallbackDob = dob;
            }

            // 4. Address Construction
            let fallbackCorAdd1 = u.APP_COR_ADD1;
            if (!isValid(fallbackCorAdd1)) fallbackCorAdd1 = [housePvNo, street].filter(Boolean).join(' ');

            let fallbackCorAdd2 = u.APP_COR_ADD2;
            if (!isValid(fallbackCorAdd2) && area) fallbackCorAdd2 = area;

            let fallbackCorAdd3 = u.APP_COR_ADD3;
            if (!isValid(fallbackCorAdd3) && landmark) fallbackCorAdd3 = landmark;

            let fallbackCorCity = u.APP_COR_CITY;
            if (!isValid(fallbackCorCity) && city) fallbackCorCity = city;

            let fallbackCorPincode = u.APP_COR_PINCD;
            if (!isValid(fallbackCorPincode) && pincode) fallbackCorPincode = pincode;

            // 5. State Handling
            let fallbackCorState = u.APP_COR_STATE;
            if (isValid(fallbackCorState)) {
                if (gstStateMap[fallbackCorState]) fallbackCorState = gstStateMap[fallbackCorState];
            } else if (state) {
                fallbackCorState = state;
            }

            // 6. Contact Info
            let fallbackMobile = u.APP_MOB_NO;
            if (!isValid(fallbackMobile)) fallbackMobile = userDetails.phone;

            let fallbackEmail = u.APP_EMAIL;
            if (!isValid(fallbackEmail)) fallbackEmail = userDetails.email;

            // 7. PAN (CRITICAL: Must exist)
            let fallbackPan = u.APP_PAN_NO;
            if (!isValid(fallbackPan) && pan) fallbackPan = pan; // Prefer body.pan if missing in Object
            if (!isValid(fallbackPan) && u.pan) fallbackPan = u.pan; // Check both slots
            // If still missing? We should have it from User Model (not necessarily in userObject yet)
            // But usually, APP_PAN_NO is set during signup KRA check step.

            // RECOVERY: If PAN is still missing, try to fetch from Document Upload Record
            if (!isValid(fallbackPan)) {
                try {
                    const userDocRec = await userDocUploadModel.findOne({ userId: id });
                    if (userDocRec && userDocRec.pancard && userDocRec.pancard.panNumber) {
                        fallbackPan = userDocRec.pancard.panNumber;
                    }
                } catch (e) {
                    console.error("PAN Recovery Failed:", e);
                }
            }

            // If it's still missing here, we are in trouble. But let's assume it's in userObject usually.

            // 8. Update 'u' (userObject) with consolidated values
            u.APP_NAME = fallbackName;
            u.APP_F_NAME = fallbackFatherName;
            u.APP_DOB_DT = fallbackDob;
            u.APP_COR_ADD1 = fallbackCorAdd1;
            u.APP_COR_ADD2 = fallbackCorAdd2;
            u.APP_COR_ADD3 = fallbackCorAdd3;
            u.APP_COR_CITY = fallbackCorCity;
            u.APP_COR_PINCD = fallbackCorPincode;
            u.APP_COR_STATE = fallbackCorState;
            u.APP_MOB_NO = fallbackMobile;
            u.APP_EMAIL = fallbackEmail;
            u.APP_PAN_NO = fallbackPan; // Ensure we keep what we found
            u.APP_PER_ADD1 = fallbackCorAdd1;
            u.APP_PER_ADD2 = fallbackCorAdd2;
            u.APP_PER_ADD3 = fallbackCorAdd3;
            u.APP_PER_CITY = fallbackCorCity;
            u.APP_PER_PINCD = fallbackCorPincode;
            u.APP_PER_STATE = fallbackCorState;
            // 9. Permanent Address Mirroring (If User didn't provide separate)
            if (!isValid(u.APP_PER_ADD1)) u.APP_PER_ADD1 = fallbackCorAdd1;
            if (!isValid(u.APP_PER_ADD2)) u.APP_PER_ADD2 = fallbackCorAdd2;
            if (!isValid(u.APP_PER_ADD3)) u.APP_PER_ADD3 = fallbackCorAdd3;
            if (!isValid(u.APP_PER_CITY)) u.APP_PER_CITY = fallbackCorCity;
            if (!isValid(u.APP_PER_PINCD)) u.APP_PER_PINCD = fallbackCorPincode;
            if (!isValid(u.APP_PER_STATE)) u.APP_PER_STATE = fallbackCorState;

            // --- FALLBACK LOGIC END ---

            // CRITICAL FIX: Persist the Fallback Data to User Model
            // This ensures logic like determineNextStep sees the updated data and doesn't ask for it again.
            u.REGISTERED_ADDRESS = [
                u.APP_COR_ADD1,
                u.APP_COR_ADD3,
                u.APP_COR_CITY,
                u.APP_COR_PINCD,
                u.APP_COR_STATE
            ].filter(Boolean).join(', ');

            if (userDetails) {
                userDetails.userObject = u;
                userDetails.markModified('userObject');
                await userDetails.save();
            }

            // VALIDATION: If still missing essential data, request fallback
            if (!isValid(u.APP_NAME) || !isValid(u.APP_COR_ADD1)) {
                return {
                    status: 422,
                    message: "KRA Details missing. Please provide manual details.",
                    data: { requireFallback: true }
                };
            }

            const drawFields = (page, rows, data, customX = valueX) => {
                Object.entries(rows).forEach(([key, y]) => {
                    let options = {
                        x: customX,
                        y,
                        size: fontSize,
                    }
                    if (key === 'REGISTERED_ADDRESS') {
                        options.maxWidth = 530 - customX
                        options.lineHeight = 12
                        options.size = 10
                    }
                    page.drawText(String(data[key] ?? "-"), options);
                });
            };
            const rowsPage4 = {
                APP_NAME: 718,
                APP_TYPE: 703,
                REGISTERED_ADDRESS: 653,
                APP_EMAIL: 618,
                APP_MOB_NO: 605,
                APP_PAN_NO: 588,
            };
            const rowsPage5 = {
                APP_POS_CODE: 565,
                APP_TYPE: 515,
                APP_NO: 465,
                APP_DATE: 415,
                APP_PAN_NO: 365,
                APP_PAN_COPY: 315,
                APP_EXMT: 265,
                APP_EXMT_CAT: 215,
                APP_EXMT_ID_PROOF: 165,
                APP_IPV_FLAG: 115,
            };
            const rowsPage6 = {
                APP_IPV_DATE: 640,
                APP_GEN: 590,
                APP_NAME: 540,
                APP_F_NAME: 490,
                APP_REGNO: 440,
                APP_DOB_DT: 390,
                APP_COMMENCE_DT: 340,
                APP_NATIONALITY: 290,
                APP_OTH_NATIONALITY: 240,
                APP_COMP_STATUS: 190,
                APP_OTH_COMP_STATUS: 120,
                APP_RES_STATUS: 70,
            }
            const rowsPage7 = {
                APP_RES_STATUS_PROOF: 690,
                APP_UID_NO: 630,
                APP_COR_ADD1: 580,
                APP_COR_ADD2: 530,
                APP_COR_ADD3: 480,
                APP_COR_CITY: 430,
                APP_COR_PINCD: 380,
                APP_COR_STATE: 330,
                APP_COR_CTRY: 280,
                APP_OFF_NO: 230,
                APP_RES_NO: 180,
                APP_MOB_NO: 120,
            }
            const rowsPage8 = {
                APP_FAX_NO: 690,
                APP_EMAIL: 630,
                APP_COR_ADD_PROOF: 580,
                APP_COR_ADD_REF: 530,
                APP_COR_ADD_DT: 480,
                APP_PER_ADD1: 430,
                APP_PER_ADD2: 380,
                APP_PER_ADD3: 330,
                APP_PER_CITY: 280,
                APP_PER_PINCD: 230,
                APP_PER_STATE: 180,
                APP_PER_CTRY: 130,
            }
            const rowsPage9 = {
                APP_PER_ADD_PROOF: 690,
                APP_PER_ADD_REF: 640,
                APP_PER_ADD_DT: 590,
                APP_INCOME: 540,
                APP_OCC: 490,
                APP_OTH_OCC: 440,
                APP_POL_CONN: 390,
                APP_DOC_PROOF: 330,
                APP_INTERNAL_REF: 290,
                APP_BRANCH_CODE: 240,
                APP_MAR_STATUS: 190,
                APP_NETWRTH: 130,
            }
            const rowsPage10 = {
                APP_NETWORTH_DT: 690,
                APP_INCORP_PLC: 630,
                APP_OTHERINFO: 590,
                APP_ACC_OPENDT: 530,
                APP_ACC_ACTIVEDT: 490,
                APP_ACC_UPDTDT: 430,
                APP_FILLER1: 390,
                APP_FILLER2: 330,
                APP_FILLER3: 290,
                APP_STATUS: 230,
                APP_STATUSDT: 190,
                APP_ERROR_DESC: 130,
            }
            const rowsPage11 = {
                APP_DUMP_TYPE: 690,
                APP_DNLDDT: 630,
                APP_REMARKS: 590,
                APP_KYC_MODE: 530,
                APP_UID_TOKEN: 490,
                APP_VER_NO: 430,
                APP_KRA_INFO: 390,
                APP_IOP_FLG: 330,
                APP_FATCA_APPLICABLE_FLAG: 290,
                APP_FATCA_BIRTH_PLACE: 230,
                APP_FATCA_BIRTH_COUNTRY: 160,
            }

            const rowsPage12 = {
                APP_FATCA_COUNTRY_RES: 690,
                APP_FATCA_COUNTRY_CITYZENSHIP: 620,
                APP_FATCA_DATE_DECLARATION: 550,
            }
            drawFields(pages.page4, rowsPage4, u, 310);
            drawFields(pages.page5, rowsPage5, u);
            drawFields(pages.page6, rowsPage6, u);
            drawFields(pages.page7, rowsPage7, u);
            drawFields(pages.page8, rowsPage8, u);
            drawFields(pages.page9, rowsPage9, u);
            drawFields(pages.page10, rowsPage10, u);
            drawFields(pages.page11, rowsPage11, u);
            drawFields(pages.page12, rowsPage12, u);
            let userDoc = await userDocUploadModel.findOne({ userId: id })
            if (userDoc) {
                let aadhaarFront = userDoc.aadhaar.front.fileName
                let aadhaarBack = userDoc.aadhaar.back.fileName
                let pancard = userDoc.pancard.fileName
                
                const aadhaarFrontPath = path.join(__dirname, `../uploads/kycimg/${aadhaarFront}`);
                const aadhaarBackPath = path.join(__dirname, `../uploads/kycimg/${aadhaarBack}`);
                const pancardPath = path.join(__dirname, `../uploads/kycimg/${pancard}`);

                if (fs.existsSync(aadhaarFrontPath) && fs.existsSync(aadhaarBackPath) && fs.existsSync(pancardPath)) {
                    const aadhaarFrontBytes = fs.readFileSync(aadhaarFrontPath);
                    const aadhaarBackBytes = fs.readFileSync(aadhaarBackPath);
                    const panCardBytes = fs.readFileSync(pancardPath);
                    
                    const aadhaarFrontImage = aadhaarFrontBytes[0] === 0x89 ? await pdfDoc.embedPng(aadhaarFrontBytes) : await pdfDoc.embedJpg(aadhaarFrontBytes);
                    const aadhaarBackImage = aadhaarBackBytes[0] === 0x89 ? await pdfDoc.embedPng(aadhaarBackBytes) : await pdfDoc.embedJpg(aadhaarBackBytes);
                    const panCardImage = panCardBytes[0] === 0x89 ? await pdfDoc.embedPng(panCardBytes) : await pdfDoc.embedJpg(panCardBytes);
                    
                    page13.drawImage(aadhaarFrontImage, {
                        x: 50,
                        y: 650,
                        width: 200,
                        height: 120,
                    });

                    page13.drawImage(aadhaarBackImage, {
                        x: 330,
                        y: 650,
                        width: 200,
                        height: 120,
                    });
                    page13.drawImage(panCardImage, {
                        x: 50,
                        y: 250,
                        width: 250,
                        height: 140,
                    });
                }
            }
            const updatedPdf = await pdfDoc.save();
            const outputFilePath = path.join(__dirname, `../serviceAgreement/service_agreement_final_${userName}.pdf`);
            fs.writeFileSync(outputFilePath, updatedPdf);
            
            const apiBaseUrl = process.env.DIGIO_API_BASE_URL;
            const CLIENT_ID = process.env.DIGIO_CLIENT_ID
            const CLIENT_SECRET = process.env.DIGIO_CLIENT_SECRET_ID;
            
            const signerEmail = email || userDetails.email || u.APP_EMAIL;
            const signerName = name || userDetails.fullName || u.APP_NAME;

            if (!signerEmail) {
                return { status: 400, message: "Email identifier is required for Digio request", data: {} };
            }

            const authHeader = Buffer.from(`${CLIENT_ID}:${CLIENT_SECRET}`).toString("base64");
            const requestData = {
                signers: [
                    {
                        identifier: signerEmail,
                        name: signerName,
                        sign_type: "Aadhaar",
                        reason: "Service Agreement"
                    }
                ],
                expire_in_days: 15,
                display_on_page: "ALL",
                notify_signers: true,
                send_sign_link: true,
                file_name: `SP_Service_Agreement_${userName}.pdf`,
                will_self_sign: true,
                generate_access_token: true,
                sign_coordinates: {
                    [signerEmail]: {
                        "1": [{
                            llx: 376.55,
                            lly: 67.89,
                            urx: 535.89,
                            ury: 129.36
                        }]
                    }
                }
            };
            const formData = new FormData();
            formData.append("file", fs.createReadStream(outputFilePath), { filename: `service_agreement_final_${userName}.pdf` });
            formData.append("request", JSON.stringify(requestData));
            
            const response = await axios.post(apiBaseUrl, formData, {
                headers: {
                    Authorization: `Basic ${authHeader}`,
                    Accept: "application/json",
                    ...formData.getHeaders(),
                },
                maxContentLength: Infinity,
                maxBodyLength: Infinity,
            });
            
            console.log("Digio Response Status:", response.status);
            
            if (response.status >= 200 && response.status < 300) {
                // FALLBACK: Use findOneAndUpdate to replace existing document if it exists (refreshes expired/corrupted state)
                const userKyc = await userKycModel.findOneAndUpdate(
                    { userId: id },
                    { 
                        digioObject: response.data,
                        kycStatus: "pending",
                        updatedAt: new Date()
                    },
                    { upsert: true, new: true }
                );

                // --- SYNC WORKFLOW: Reset E-Sign gate on every new Digio request ---
                const user = await userModel.findById(id);
                if (user) {
                    if (!user.kycGates) user.kycGates = {};
                    if (!user.kycGates.esign) user.kycGates.esign = {};

                    user.kycGates.esign.status = 'PENDING';
                    user.kycGates.esign.rejectionReason = null;
                    user.kycGates.esign.submittedAt = new Date();
                    user.markModified('kycGates');
                    console.log('[Digio Init] E-Sign gate unconditionally reset to PENDING.');

                    await user.save();
                }

                // Sync overall status AFTER gate is updated so computed status is accurate
                await KycService.syncOverallStatus(id, { type: 'SYSTEM', id: 'DIGIO_INIT' });

                const responseData = response.data;
                let extractedToken = null;
                if (responseData.access_token) {
                    if (typeof responseData.access_token === 'string') {
                        extractedToken = responseData.access_token;
                    } else if (responseData.access_token.id) {
                        extractedToken = responseData.access_token.id;
                    }
                }
                if (!extractedToken && responseData.token) {
                    extractedToken = responseData.token;
                }

                const tokenData = {
                    id: responseData.id || responseData.document_id,
                    tokenId: extractedToken,
                    access_token: responseData.access_token
                };

                return { status: 200, message: "kyc initialized", data: { digio: userKyc, sdkResponse: responseData, tokens: tokenData } };
            } else {
                return { status: 400, message: "Digio initialization failed", data: { digio: response.data } };
            }
        } catch (error) {
            console.error("Digio Error:", error.response?.data || error.message);
            return { 
                status: error.response?.status || 400, 
                message: error.message, 
                data: { digio: error.response?.data || error.message } 
            };
        }
    },
    kycChangeStatus: async ({ query }) => {
        try {
            // Updated to use KYC Service for Audit Trail
            let { userId, status, reason } = query
            status = status?.trim().toUpperCase(); // Ensure UpperCase for our new Enum

            // BUG FIX 2: Validate required fields BEFORE calling transitionStatus
            // to return a clean 400 response instead of an unhandled thrown error.
            if (!userId) {
                return { status: 400, message: 'userId is required.', data: {} };
            }
            if (!status) {
                return { status: 400, message: 'status is required.', data: {} };
            }
            if (status === 'REJECTED' && (!reason || reason.trim() === '')) {
                return { status: 400, message: 'A rejection reason is required when rejecting KYC.', data: {} };
            }

            const actor = { type: 'ADMIN', id: 'ADMIN_ACTION' }; // Should ideally get admin ID from req context if passed

            await KycService.transitionStatus(userId, status, actor, reason);

            // Also update legacy userKycModel if needed for backward compat?
            // Existing code updated userKycModel.kycStatus. 
            // We should sync them.
            let userKyc = await userKycModel.findOne({ userId: userId });
            if (userKyc) {
                userKyc.kycStatus = status.toLowerCase(); // Legacy holds lowercase often
                await userKyc.save();
            }

            return { status: 200, message: "kyc status changed", data: { status: status } };
        } catch (error) {
            return { status: 400, message: error.message, data: {} }
        }
    },
    kycDocList: async ({ query }) => {
        try {
            let { userId } = query
            let userDoc = await userDocUploadModel.findOne({ userId: userId })
            const __filename = fileURLToPath(import.meta.url);
            const __dirname = path.dirname(__filename);
            if (!userDoc) {
                return {
                    status: 200,
                    message: "uploaded Document not found",
                    data: { aadhaarFrontFile: null, aadhaarBackFile: null, panCardFile: null }
                };
            }
            let aadhaarFront = userDoc.aadhaar.front.filePath
            let aadhaarBack = userDoc.aadhaar.back.filePath
            let pancard = userDoc.pancard.filePath
            return { status: 200, message: "uploaded Document", data: { aadhaarFrontFile: aadhaarFront, aadhaarBackFile: aadhaarBack, panCardFile: pancard } };
        } catch (error) {
            return { status: 400, message: error.message, data: {} }
        }
    },
    uploadKycVideo: async ({ params, file }) => {
        try {
            let { id } = params
            const user = await userModel.findOne({ _id: id })
            if (!user) {
                return { status: 404, message: "User not found", data: {} };
            }

            // Sync to new fields
            user.kycDocs.video = file.filename;
            user.kycVideo = file.filename; // legacy

            if (user.registrationStatus !== 'ACTIVE') {
                user.registrationStatus = "COMPLETE";
            }

            // --- GATE 3 RESET: Re-submission always resets gate to PENDING ---
            // BUG FIX 1 & 3: Gate is reset unconditionally (handles REJECTED, NOT_STARTED,
            // PENDING and even VERIFIED re-uploads). Gate is reset BEFORE syncOverallStatus
            // so the sync sees the fresh PENDING state, not the stale old state.
            if (!user.kycGates) user.kycGates = {};
            if (!user.kycGates.video) user.kycGates.video = {};
            user.kycGates.video.status = 'PENDING';
            user.kycGates.video.rejectionReason = null;
            user.kycGates.video.submittedAt = new Date();
            user.markModified('kycGates');
            console.log('[Video Upload] Video gate reset to PENDING.');

            await user.save();

            // Sync overall KYC status AFTER gate is updated so computed status is accurate
            await KycService.syncOverallStatus(id, { type: 'SYSTEM', id: 'VIDEO_UPLOAD' });

            return { status: 200, message: "KYC Video uploaded", data: { kycVideo: file.filename, registrationStatus: user.registrationStatus } };
        } catch (error) {
            return { status: 400, message: error.message, data: {} }
        }
    },
    updateAdminKycDocument: async ({ params, query, body, file }) => {
        try {
            let { id } = params;
            let { docType } = query;

            if (!file) {
                return { status: 400, message: "No file uploaded", data: {} };
            }

            const user = await userModel.findById(id);
            if (!user) {
                return { status: 404, message: "User not found", data: {} };
            }

            // Ensure kycDocs object exists
            if (!user.kycDocs) {
                user.kycDocs = {
                    panImage: null,
                    aadhaarFront: null,
                    aadhaarBack: null,
                    video: null
                };
            }

            let userDoc = await userDocUploadModel.findOne({ userId: id });
            if (!userDoc) {
                userDoc = new userDocUploadModel({ userId: id });
            }

            if (docType === 'pan') {
                const panNumber = body.panNumber;
                const cleanPan = panNumber?.toString().trim().toUpperCase();

                if (cleanPan) {
                    const existingUser = await userModel.findOne({ panNumber: cleanPan, _id: { $ne: id } });
                    if (existingUser) {
                        return { status: 400, message: "This PAN card is already registered with another account.", data: {} };
                    }
                    user.panNumber = cleanPan;
                }

                user.kycDocs.panImage = file.filename;
                if (!userDoc.pancard) userDoc.pancard = {};
                userDoc.pancard.fileName = file.filename;
                userDoc.pancard.filePath = file.path;
                userDoc.pancard.fileOriginalName = file.originalname;
                if (cleanPan) userDoc.pancard.panNumber = cleanPan;
            } else if (docType === 'aadhaarFront') {
                user.kycDocs.aadhaarFront = file.filename;
                if (!userDoc.aadhaar) userDoc.aadhaar = {};
                if (!userDoc.aadhaar.front) userDoc.aadhaar.front = {};
                userDoc.aadhaar.front.fileName = file.filename;
                userDoc.aadhaar.front.filePath = file.path;
                userDoc.aadhaar.front.fileOriginalName = file.originalname;
            } else if (docType === 'aadhaarBack') {
                user.kycDocs.aadhaarBack = file.filename;
                if (!userDoc.aadhaar) userDoc.aadhaar = {};
                if (!userDoc.aadhaar.back) userDoc.aadhaar.back = {};
                userDoc.aadhaar.back.fileName = file.filename;
                userDoc.aadhaar.back.filePath = file.path;
                userDoc.aadhaar.back.fileOriginalName = file.originalname;
            } else if (docType === 'video') {
                user.kycDocs.video = file.filename;
                user.kycVideo = file.filename;
            } else {
                return { status: 400, message: "Invalid docType", data: {} };
            }

            // Reset the relevant gate to PENDING so the admin can re-review the updated doc
            if (!user.kycGates) user.kycGates = {};
            const gateKey = (docType === 'pan' || docType === 'aadhaarFront' || docType === 'aadhaarBack') ? 'documents' : 'video';
            if (!user.kycGates[gateKey]) user.kycGates[gateKey] = {};
            user.kycGates[gateKey].status = 'PENDING';
            user.kycGates[gateKey].rejectionReason = null;
            user.kycGates[gateKey].submittedAt = new Date();
            user.markModified('kycGates');

            // Record history
            if (!user.kycHistory) user.kycHistory = [];
            user.kycHistory.push({
                fromStatus: user.kycStatus,
                toStatus: user.kycStatus,
                changedBy: 'ADMIN',
                reason: `Admin updated ${docType} document`,
                timestamp: new Date()
            });

            // Mark modified for nested objects
            user.markModified('kycDocs');
            user.markModified('kycHistory');

            await user.save();
            await userDoc.save();

            // Re-sync overall KYC status since a gate may have changed
            await KycService.syncOverallStatus(user._id, { type: 'ADMIN', id: `DOC_UPDATE_${docType}` });

            return { status: 200, message: `${docType} updated successfully`, data: { filename: file.filename } };

        } catch (error) {
            console.error('[Admin Doc Update] Error:', error.message);
            return { status: 400, message: error.message, data: {} };
        }
    },

    // DIGIO Download Proxy
    downloadDigioDocument: async (documentId) => {
        try {
            const url = `https://api.digio.in/v2/client/document/download?document_id=${documentId}`;

            const CLIENT_ID = process.env.DIGIO_CLIENT_ID;
            const CLIENT_SECRET = process.env.DIGIO_CLIENT_SECRET_ID;
            const authHeader = Buffer.from(`${CLIENT_ID}:${CLIENT_SECRET}`).toString("base64");

            console.log(`[Proxy] Downloading Digio Document: ${documentId} using Basic Auth`);

            const response = await axios.get(url, {
                headers: {
                    'accept': '*/*',
                    'Authorization': `Basic ${authHeader}`
                },
                responseType: 'arraybuffer'
            });

            return { status: 200, data: response.data };
        } catch (error) {
            console.error('[Digio Proxy Error]:', error.response?.data?.toString() || error.message);
            return {
                status: error.response?.status || 400,
                message: error.message,
                data: error.response?.data || error.message
            };
        }
    },

    // =============================================================================
    // updateGateStatus — Admin endpoint to approve/reject individual KYC gates.
    // Accepts: gate ('documents' | 'esign' | 'video'), status, optional reason.
    // Auto-computes the overall kycStatus after every gate change.
    // =============================================================================
    updateGateStatus: async ({ params, body }) => {
        try {
            const { id } = params;
            const { gate, status, reason } = body;

            // 1. Validate inputs
            const validGates = ['documents', 'esign', 'video'];
            const validStatuses = ['NOT_STARTED', 'PENDING', 'VERIFIED', 'REJECTED'];

            if (!validGates.includes(gate)) {
                return { status: 400, message: `Invalid gate. Must be one of: ${validGates.join(', ')}`, data: {} };
            }
            if (!validStatuses.includes(status)) {
                return { status: 400, message: `Invalid status. Must be one of: ${validStatuses.join(', ')}`, data: {} };
            }
            if (status === 'REJECTED' && (!reason || reason.trim() === '')) {
                return { status: 400, message: 'A rejection reason is required when rejecting a gate.', data: {} };
            }

            // 2. Find user
            const user = await userModel.findById(id);
            if (!user) {
                return { status: 404, message: 'User not found', data: {} };
            }

            // 3. Keep old status for audit trail
            const oldOverallStatus = user.kycStatus;

            // 4. Safely initialize kycGates (backward compat for existing users)
            if (!user.kycGates) user.kycGates = {};
            if (!user.kycGates[gate]) user.kycGates[gate] = {};

            // 5. Apply the gate status update
            user.kycGates[gate].status = status;
            user.kycGates[gate].rejectionReason = status === 'REJECTED' ? reason.trim() : null;
            user.kycGates[gate].reviewedAt = new Date();

            // --- SYNC: Reflect 'esign' gate update in the specialized UserKycModel ---
            if (gate === 'esign') {
                await userKycModel.findOneAndUpdate(
                    { userId: id },
                    { kycStatus: status.toLowerCase() },
                    { upsert: false }
                );
                console.log(`[Gate Update] Synced E-Sign gate status '${status}' to UserKycModel.`);
            }

            user.markModified('kycGates');
            await user.save();

            // 6. Auto-compute the overall kycStatus from all 3 gate statuses using KycService (which handles disclaimer & history correctly)
            const syncedUser = await KycService.syncOverallStatus(user._id, { type: 'ADMIN', id: `GATE_UPDATE_${gate}` });

            console.log(`[Gate Update] User ${id} — gate '${gate}' → ${status}. Overall kycStatus: ${syncedUser.kycStatus}`);

            return {
                status: 200,
                message: `Gate '${gate}' updated to ${status}`,
                data: {
                    gateStatuses: syncedUser.kycGates,
                    overallKycStatus: syncedUser.kycStatus
                }
            };

        } catch (error) {
            console.error('[updateGateStatus] Error:', error.message);
            return { status: 400, message: error.message, data: {} };
        }
    },

}

export default userkycService
