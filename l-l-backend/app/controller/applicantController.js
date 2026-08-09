import staffModel from "../models/staffModel.js";
import emailService from "../services/emailService.js";
import axios from "axios";

const generateOtp = () => Math.floor(1000 + Math.random() * 9000);

const sendMobileOtp = async (phone, otp) => {
    try {
        const username = process.env.SMS_SHORT_SERVICE_USER;
        const apikey = process.env.SMS_SHORT_SERVICE_API_KEY;
        const sender = process.env.SMS_SHORT_SERVICE_SENDER;
        const templateID = process.env.SMS_SHORT_SERVICE_TEMPLATEID;
        const url = process.env.SMS_SHORT_SERVICE_URL;

        if (!url || !username || !apikey) {
            console.log(`[SMS MOCK] To: ${phone}, OTP: ${otp}`);
            return true;
        }

        const defaultTemplate = "Your OTP for ResearchVia App is {OTP}\n\n\n\nPlease do not share OTP with anyone.\n\nhttps://researchvia.in\n\n";
        const messageText = defaultTemplate.replaceAll('{OTP}', otp);
        const message = encodeURIComponent(messageText);
        const smsUrl = `${url}username=${username}&apikey=${apikey}&apirequest=Text&sender=${sender}&mobile=${phone}&message=${message}sms&route=TRANS&TemplateID=${templateID}&format=JSON`;
        
        const response = await axios.get(smsUrl);
        return response.status === 200;
    } catch (e) {
        console.error('Error sending mobile SMS:', e.message);
        return false;
    }
};

const sendEmailOtp = async (email, otp) => {
    try {
        const result = await emailService.sendEmail({
            to: email,
            subject: "ResearchVia Applicant Verification OTP",
            htmlContent: `
                <h2>Verification Code</h2>
                <p>Hello,</p>
                <p>Thank you for applying at ResearchVia. Your email verification OTP is:</p>
                <h1 style="color:#4CAF50; letter-spacing: 2px;">${otp}</h1>
                <p>Please enter this code on the application page. This code is valid for 10 minutes.</p>
                <p>Regards,<br/>ResearchVia HR Team</p>
            `
        });
        return result.success;
    } catch (e) {
        console.error('Error sending email OTP:', e.message);
        return false;
    }
};

const applicantController = {
    registerApplicant: async (req, res) => {
        try {
            const { fullName, mobileNumber, emailAddress, dob, gender, currentAddress, permanentAddress, emergencyContact, experienceYears, previousCompany, lastCtc } = req.body;

            if (!fullName || !mobileNumber || !emailAddress) {
                return res.status(400).send({ status: 400, message: "Full Name, Mobile, and Email are required", data: {} });
            }

            let applicant = await staffModel.findOne({
                $or: [
                    { mobileNumber: Number(mobileNumber) },
                    { emailAddress: emailAddress.trim() }
                ]
            });

            const mobileOtp = generateOtp();
            const emailOtp = generateOtp();
            const expiry = new Date(Date.now() + 10 * 60000); // 10 mins

            if (applicant) {
                if (applicant.stage === 'Employee') {
                    return res.status(400).send({ status: 400, message: "A staff member is already registered with these details", data: {} });
                }
                // Update existing applicant details & reset verification
                applicant.fullName = fullName;
                applicant.mobileNumber = Number(mobileNumber);
                applicant.emailAddress = emailAddress.trim();
                applicant.dob = dob ? new Date(dob) : null;
                applicant.gender = gender;
                applicant.currentAddress = currentAddress;
                applicant.permanentAddress = permanentAddress;
                applicant.emergencyContact = emergencyContact;
                applicant.experienceYears = experienceYears;
                applicant.previousCompany = previousCompany;
                applicant.lastCtc = lastCtc;
                applicant.mobileOtp = mobileOtp;
                applicant.mobileOtpExpires = expiry;
                applicant.emailOtp = emailOtp;
                applicant.emailOtpExpires = expiry;
                applicant.isMobileVerified = false;
                applicant.isEmailVerified = false;
                applicant.onboardingStatus = 'PENDING';
                await applicant.save();
            } else {
                // Generate a unique staff ID
                const count = await staffModel.countDocuments();
                const randomSuffix = Math.floor(1000 + Math.random() * 9000);
                const staffId = `STF${String(count + 1).padStart(3, '0')}${randomSuffix}`;

                applicant = await staffModel.create({
                    staffId,
                    fullName,
                    mobileNumber: Number(mobileNumber),
                    emailAddress: emailAddress.trim(),
                    dob: dob ? new Date(dob) : null,
                    gender,
                    currentAddress,
                    permanentAddress,
                    emergencyContact,
                    experienceYears,
                    previousCompany,
                    lastCtc,
                    stage: 'Applicant',
                    mobileOtp,
                    mobileOtpExpires: expiry,
                    emailOtp,
                    emailOtpExpires: expiry
                });
            }

            // Send out OTPs
            await sendMobileOtp(mobileNumber, mobileOtp);
            await sendEmailOtp(emailAddress.trim(), emailOtp);

            res.status(200).send({
                status: 200,
                message: "Verification OTPs sent to your mobile and email",
                data: { applicantId: applicant._id }
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    verifyOtp: async (req, res) => {
        try {
            const { applicantId, mobileOtp, emailOtp } = req.body;
            if (!applicantId || !mobileOtp || !emailOtp) {
                return res.status(400).send({ status: 400, message: "Applicant ID, mobileOtp, and emailOtp are required", data: {} });
            }

            const applicant = await staffModel.findById(applicantId);
            if (!applicant || applicant.stage !== 'Applicant') {
                return res.status(404).send({ status: 404, message: "Applicant profile not found", data: {} });
            }

            const now = new Date();
            if (applicant.mobileOtp !== Number(mobileOtp) || applicant.mobileOtpExpires < now) {
                return res.status(400).send({ status: 400, message: "Invalid or expired Mobile OTP", data: {} });
            }

            if (applicant.emailOtp !== Number(emailOtp) || applicant.emailOtpExpires < now) {
                return res.status(400).send({ status: 400, message: "Invalid or expired Email OTP", data: {} });
            }

            applicant.isMobileVerified = true;
            applicant.isEmailVerified = true;
            applicant.mobileOtp = null;
            applicant.emailOtp = null;
            await applicant.save();

            res.status(200).send({ status: 200, message: "Mobile and Email verified successfully", data: { applicant } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    uploadApplicantDoc: async (req, res) => {
        try {
            const { id } = req.params;
            const { type } = req.query; // 'pan', 'aadhaar', 'nism', 'education', 'photo', 'resume'
            if (!req.file) {
                return res.status(400).send({ status: 400, message: "No file uploaded", data: {} });
            }

            const applicant = await staffModel.findById(id);
            if (!applicant || applicant.stage !== 'Applicant') {
                return res.status(404).send({ status: 404, message: "Applicant not found", data: {} });
            }

            if (!applicant.isMobileVerified || !applicant.isEmailVerified) {
                return res.status(403).send({ status: 403, message: "Verification required before document upload", data: {} });
            }

            const fieldMap = {
                pan: 'panUrl',
                aadhaar: 'aadhaarUrl',
                nism: 'nismUrl',
                education: 'highestEducationUrl',
                photo: 'photoUrl',
                resume: 'resumeUrl'
            };
            const field = fieldMap[type];
            if (!field) {
                return res.status(400).send({ status: 400, message: "Invalid document type", data: {} });
            }

            applicant[field] = req.file.path;

            // Check onboarding completeness
            if (applicant.panUrl && applicant.aadhaarUrl && applicant.nismUrl && applicant.highestEducationUrl && applicant.photoUrl && applicant.resumeUrl) {
                applicant.onboardingStatus = applicant.kycVideoUrl ? 'VERIFIED' : 'DOCUMENTS_UPLOADED';
            }
            await applicant.save();

            res.status(200).send({ status: 200, message: `${type} uploaded successfully`, data: { applicant } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    uploadApplicantVideo: async (req, res) => {
        try {
            const { id } = req.params;
            if (!req.file) {
                return res.status(400).send({ status: 400, message: "No video file uploaded", data: {} });
            }

            const applicant = await staffModel.findById(id);
            if (!applicant || applicant.stage !== 'Applicant') {
                return res.status(404).send({ status: 404, message: "Applicant not found", data: {} });
            }

            if (!applicant.isMobileVerified || !applicant.isEmailVerified) {
                return res.status(403).send({ status: 403, message: "Verification required before document upload", data: {} });
            }

            applicant.kycVideoUrl = req.file.path;

            if (applicant.panUrl && applicant.aadhaarUrl && applicant.nismUrl && applicant.highestEducationUrl && applicant.photoUrl && applicant.resumeUrl) {
                applicant.onboardingStatus = 'VERIFIED';
            }
            await applicant.save();

            res.status(200).send({ status: 200, message: "KYC Video uploaded successfully", data: { applicant } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    listApplicants: async (req, res) => {
        try {
            const applicants = await staffModel.find({ stage: 'Applicant' }).sort({ createdAt: -1 });
            res.status(200).send({ status: 200, message: "Applicants retrieved successfully", data: { applicants } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    approveApplicant: async (req, res) => {
        try {
            const { id } = req.params;
            const { deparment, mpin, joiningDate, isViewOnly, assignedDirector } = req.body;

            if (!deparment || !mpin) {
                return res.status(400).send({ status: 400, message: "Department and MPIN are required to approve staff", data: {} });
            }

            const applicant = await staffModel.findById(id);
            if (!applicant || applicant.stage !== 'Applicant') {
                return res.status(404).send({ status: 404, message: "Applicant not found", data: {} });
            }

            // Promote to Employee
            applicant.stage = 'Employee';
            applicant.deparment = deparment;
            applicant.mpin = mpin.toString();
            applicant.joiningDate = joiningDate ? new Date(joiningDate) : new Date();
            applicant.status = 'Active';
            applicant.isViewOnly = isViewOnly === true || isViewOnly === 'true';
            if (assignedDirector) {
                applicant.assignedDirector = assignedDirector;
            }

            await applicant.save();
            res.status(200).send({ status: 200, message: "Applicant approved and promoted to Employee", data: { staff: applicant } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    getApplicantDetails: async (req, res) => {
        try {
            const { id } = req.params;
            const applicant = await staffModel.findById(id);
            if (!applicant || applicant.stage !== 'Applicant') {
                return res.status(404).send({ status: 404, message: "Applicant not found", data: {} });
            }

            const data = applicant.toObject();
            delete data.emailOtp;
            delete data.emailOtpExpires;
            delete data.mobileOtp;
            delete data.mobileOtpExpires;
            delete data.mpin;

            res.status(200).send({ status: 200, message: "Applicant retrieved successfully", data: { applicant: data } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    initiateContinueApplication: async (req, res) => {
        try {
            const { identifier } = req.body;
            if (!identifier) {
                return res.status(400).send({ status: 400, message: "Email or Mobile Number is required", data: {} });
            }

            const cleanId = identifier.trim().replace(/[^0-9a-zA-Z@.]/g, '');
            const isEmail = cleanId.includes('@');
            let query = { stage: 'Applicant' };

            if (isEmail) {
                query.emailAddress = { $regex: new RegExp(`^${cleanId}$`, 'i') };
            } else {
                const numericId = parseInt(cleanId);
                const last10 = parseInt(cleanId.slice(-10));
                query.$or = [
                    { mobileNumber: numericId },
                    { mobileNumber: last10 },
                    { mobileNumber: parseInt("91" + last10) }
                ];
            }

            const applicant = await staffModel.findOne(query);
            if (!applicant) {
                return res.status(400).send({ status: 400, message: "No such applicant found", data: {} });
            }

            const otp = generateOtp().toString();
            const expires = Date.now() + 10 * 60 * 1000;

            if (isEmail) {
                applicant.emailOtp = otp;
                applicant.emailOtpExpires = expires;
                await applicant.save();
                await sendEmailOtp(applicant.emailAddress, otp);
            } else {
                applicant.mobileOtp = otp;
                applicant.mobileOtpExpires = expires;
                await applicant.save();
                await sendMobileOtp(applicant.mobileNumber.toString(), otp);
                console.log(`[SMS OTP] Sent to ${applicant.mobileNumber}: ${otp}`);
            }

            res.status(200).send({
                status: 200,
                message: "Verification code sent successfully",
                data: { otpType: isEmail ? 'email' : 'mobile' }
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    verifyContinueApplication: async (req, res) => {
        try {
            const { identifier, otp, otpType } = req.body;
            if (!identifier || !otp || !otpType) {
                return res.status(400).send({ status: 400, message: "All fields are required", data: {} });
            }

            const cleanId = identifier.trim().replace(/[^0-9a-zA-Z@.]/g, '');
            const isEmail = cleanId.includes('@');
            let query = { stage: 'Applicant' };

            if (isEmail) {
                query.emailAddress = { $regex: new RegExp(`^${cleanId}$`, 'i') };
            } else {
                const numericId = parseInt(cleanId);
                const last10 = parseInt(cleanId.slice(-10));
                query.$or = [
                    { mobileNumber: numericId },
                    { mobileNumber: last10 },
                    { mobileNumber: parseInt("91" + last10) }
                ];
            }

            const applicant = await staffModel.findOne(query);
            if (!applicant) {
                return res.status(400).send({ status: 400, message: "Applicant not found", data: {} });
            }

            if (otpType === 'email') {
                if (applicant.emailOtp !== parseInt(otp) || applicant.emailOtpExpires < Date.now()) {
                    return res.status(400).send({ status: 400, message: "Invalid or expired email OTP", data: {} });
                }
                applicant.isEmailVerified = true;
                applicant.emailOtp = undefined;
            } else {
                if (applicant.mobileOtp !== parseInt(otp) || applicant.mobileOtpExpires < Date.now()) {
                    return res.status(400).send({ status: 400, message: "Invalid or expired mobile OTP", data: {} });
                }
                applicant.isMobileVerified = true;
                applicant.mobileOtp = undefined;
            }

            await applicant.save();

            res.status(200).send({
                status: 200,
                message: "Verification successful",
                data: { applicantId: applicant._id }
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    }
};

export default applicantController;
