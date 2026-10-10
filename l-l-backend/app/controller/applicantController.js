import applicantModel from "../models/applicantModel.js";
import staffModel from "../models/staffModel.js";
import emailService from "../services/emailService.js";
import axios from "axios";
import staffService, { resolveRoleAndDepartment } from "../services/staffService.js";
import roleModel from "../models/roleModel.js";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import mongoose from "mongoose";

const generateOtp = () => Math.floor(1000 + Math.random() * 9000);

const findApplicantByIdOrCustomId = async (id) => {
    if (!id) return null;
    const strId = String(id).trim();
    if (mongoose.Types.ObjectId.isValid(strId)) {
        const doc = await applicantModel.findById(strId);
        if (doc) return doc;
    }
    return await applicantModel.findOne({ applicantId: strId });
};

const generateNextApplicantId = async () => {
    const currentYear = new Date().getFullYear();
    const yearPrefix = `APP-${currentYear}-`;
    const lastApplicant = await applicantModel
        .findOne({ applicantId: new RegExp(`^${yearPrefix}`) })
        .sort({ applicantId: -1 })
        .lean();

    let nextSeqNum = 1;
    if (lastApplicant && lastApplicant.applicantId) {
        const parts = lastApplicant.applicantId.split('-');
        const lastNum = parseInt(parts[parts.length - 1], 10);
        if (!isNaN(lastNum)) {
            nextSeqNum = lastNum + 1;
        }
    }

    let appSeq = `${yearPrefix}${String(nextSeqNum).padStart(4, '0')}`;
    while (await applicantModel.exists({ applicantId: appSeq })) {
        nextSeqNum++;
        appSeq = `${yearPrefix}${String(nextSeqNum).padStart(4, '0')}`;
    }
    return appSeq;
};

/**
 * Normalizes a mobile number to 91XXXXXXXXXX (12 digits, prefixed with 91).
 */
const normalizeIndianMobile = (phone) => {
    if (!phone) return { valid: false, normalized12: '', numeric12: 0, last10: '' };
    const digits = phone.toString().replace(/\D/g, '');

    let last10 = '';
    let normalized12 = '';

    if (digits.length === 10) {
        last10 = digits;
        normalized12 = `91${digits}`;
    } else if (digits.length === 12 && digits.startsWith('91')) {
        last10 = digits.slice(-10);
        normalized12 = digits;
    } else if (digits.length === 11 && digits.startsWith('0')) {
        last10 = digits.slice(1);
        normalized12 = `91${last10}`;
    } else if (digits.length > 12 && digits.startsWith('91')) {
        last10 = digits.slice(-10);
        normalized12 = `91${last10}`;
    } else {
        return { valid: false, normalized12: '', numeric12: 0, last10: '' };
    }

    const numeric12 = parseInt(normalized12, 10);
    const valid = normalized12.length === 12 && normalized12.startsWith('91') && last10.length === 10 && !isNaN(numeric12);
    return { valid, normalized12, numeric12, last10 };
};

const sendMobileOtp = async (phone, otp) => {
    try {
        const username = process.env.SMS_SHORT_SERVICE_USER || 'ResearchVia';
        const apikey = process.env.SMS_SHORT_SERVICE_API_KEY || 'DA15E-A0C79';
        const sender = process.env.SMS_SHORT_SERVICE_SENDER || 'REGISR';
        const templateID = process.env.SMS_SHORT_SERVICE_TEMPLATEID || '1607100000000327862';
        const url = process.env.SMS_SHORT_SERVICE_URL || 'http://sms.shortmsgservice.com/sms-panel/api/http/index.php?';

        const { valid, normalized12 } = normalizeIndianMobile(phone);
        if (!valid || normalized12.length !== 12 || !normalized12.startsWith('91')) {
            console.error(`[SMS Gateway] Invalid phone number provided for OTP: ${phone}`);
            return false;
        }

        const defaultTemplate = "Your OTP for ResearchVia App is {OTP}\n\n\n\nPlease do not share OTP with anyone.\n\nhttps://researchvia.in\n\n";
        const messageText = defaultTemplate.replaceAll('{OTP}', otp);
        const message = encodeURIComponent(messageText);
        const smsUrl = `${url}username=${username}&apikey=${apikey}&apirequest=Text&sender=${sender}&mobile=${normalized12}&message=${message}sms&route=TRANS&TemplateID=${templateID}&format=JSON`;

        console.log(`[SMS Gateway] Sending mobile OTP to ${normalized12}`);
        const response = await axios.get(smsUrl, { timeout: 10000 });
        return response.status === 200;
    } catch (e) {
        console.error('Error sending mobile SMS:', e.message);
        return false;
    }
};

const sendEmailOtp = async (email, otp) => {
    try {
        const cleanEmail = email ? email.trim() : '';
        if (!cleanEmail) return false;

        console.log(`[Email Gateway] Sending applicant OTP to ${cleanEmail}`);
        const result = await emailService.sendEmail({
            to: cleanEmail,
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
    createAccount: async (req, res) => {
        try {
            const { emailAddress, password } = req.body;
            if (!emailAddress || !password) {
                return res.status(400).send({ status: 400, message: "Email and password are required", data: {} });
            }

            const cleanEmail = emailAddress.trim().toLowerCase();
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!emailRegex.test(cleanEmail)) {
                return res.status(400).send({ status: 400, message: "Please enter a valid email address", data: {} });
            }

            if (password.length < 6) {
                return res.status(400).send({ status: 400, message: "Password must be at least 6 characters long", data: {} });
            }

            // Check if already an employee in staffModel
            const existingStaff = await staffModel.findOne({ emailAddress: cleanEmail });
            if (existingStaff) {
                return res.status(400).send({ status: 400, message: "A staff member is already registered with this email. Please log in on the Staff Login tab.", data: {} });
            }

            // Check if existing applicant
            let applicant = await applicantModel.findOne({ emailAddress: cleanEmail }).select('+password');
            const hashedPassword = await bcrypt.hash(password, 10);
            const emailOtp = generateOtp();
            const expiry = new Date(Date.now() + 10 * 60000);

            if (applicant) {
                if (!applicant.isDraft && applicant.stage !== 'DRAFT') {
                    return res.status(400).send({
                        status: 400,
                        message: "An application has already been submitted with this email. Please use Continue Application.",
                        data: { alreadySubmitted: true }
                    });
                }
                applicant.password = hashedPassword;
                applicant.emailOtp = emailOtp;
                applicant.emailOtpExpires = expiry;
                applicant.isEmailVerified = false;
                await applicant.save();
            } else {
                const applicantId = await generateNextApplicantId();
                applicant = await applicantModel.create({
                    applicantId,
                    emailAddress: cleanEmail,
                    password: hashedPassword,
                    fullName: "",
                    isDraft: true,
                    currentStep: 1,
                    emailOtp,
                    emailOtpExpires: expiry,
                    isEmailVerified: false,
                    stage: 'APPLIED',
                    stageHistory: [{
                        stage: 'APPLIED',
                        note: 'Applicant account created',
                        changedAt: new Date()
                    }]
                });
            }

            await sendEmailOtp(cleanEmail, emailOtp);

            return res.status(200).send({
                status: 200,
                message: "Verification code sent to your email address",
                data: {
                    applicantId: applicant._id,
                    emailAddress: cleanEmail
                }
            });
        } catch (error) {
            console.error("[createAccount Error]:", error);
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    verifyAccountEmail: async (req, res) => {
        try {
            const { applicantId, emailOtp } = req.body;
            if (!applicantId || !emailOtp) {
                return res.status(400).send({ status: 400, message: "Applicant ID and email OTP are required", data: {} });
            }

            const applicant = await findApplicantByIdOrCustomId(applicantId);
            if (!applicant) {
                return res.status(404).send({ status: 404, message: "Applicant profile not found", data: {} });
            }

            const now = Date.now();
            const emailExpired = !applicant.emailOtpExpires || new Date(applicant.emailOtpExpires).getTime() < now;
            if (String(applicant.emailOtp).trim() !== String(emailOtp).trim() || emailExpired) {
                return res.status(400).send({ status: 400, message: "Invalid or expired Email OTP", data: {} });
            }

            applicant.isEmailVerified = true;
            applicant.emailOtp = null;
            applicant.emailOtpExpires = null;
            await applicant.save();

            const token = jwt.sign(
                { _id: applicant._id.toString(), email: applicant.emailAddress, type: 'applicant' },
                process.env.JWT_TOKEN || 'researchvia-jwt-secret',
                { expiresIn: '24h' }
            );

            const data = applicant.toObject();
            delete data.password;
            delete data.emailOtp;
            delete data.mobileOtp;

            return res.status(200).send({
                status: 200,
                message: "Email verified successfully",
                data: { applicant: data, token, currentStep: applicant.currentStep || 1 }
            });
        } catch (error) {
            console.error("[verifyAccountEmail Error]:", error);
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    resendEmailOtp: async (req, res) => {
        try {
            const { applicantId, emailAddress } = req.body;
            let query = {};
            if (applicantId) query._id = applicantId;
            else if (emailAddress) query.emailAddress = emailAddress.trim().toLowerCase();
            else return res.status(400).send({ status: 400, message: "Applicant ID or email is required", data: {} });

            const applicant = await applicantModel.findOne(query);
            if (!applicant) {
                return res.status(404).send({ status: 404, message: "Applicant not found", data: {} });
            }

            const emailOtp = generateOtp();
            applicant.emailOtp = emailOtp;
            applicant.emailOtpExpires = new Date(Date.now() + 10 * 60000);
            await applicant.save();

            await sendEmailOtp(applicant.emailAddress, emailOtp);

            return res.status(200).send({
                status: 200,
                message: "New verification code sent to your email",
                data: { applicantId: applicant._id, emailAddress: applicant.emailAddress }
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    continueLogin: async (req, res) => {
        try {
            const { emailAddress, password } = req.body;
            if (!emailAddress || !password) {
                return res.status(400).send({ status: 400, message: "Email address and password are required", data: {} });
            }

            const cleanEmail = emailAddress.trim().toLowerCase();

            // First check if staff
            const existingStaff = await staffModel.findOne({ emailAddress: cleanEmail });
            if (existingStaff && existingStaff.status && existingStaff.status.toLowerCase() === 'active') {
                return res.status(400).send({
                    status: 400,
                    message: "You are already an active staff member! Please log in on the Staff Login tab.",
                    data: { isStaff: true }
                });
            }

            const applicant = await applicantModel.findOne({ emailAddress: cleanEmail }).select('+password');
            if (!applicant) {
                return res.status(400).send({ status: 400, message: "No application found with this email. Please create an account first.", data: {} });
            }

            if (!applicant.password) {
                return res.status(400).send({ status: 400, message: "Password not set for this application. Please reset or contact HR.", data: {} });
            }

            const isMatch = await bcrypt.compare(password, applicant.password);
            if (!isMatch) {
                return res.status(400).send({ status: 400, message: "Invalid email or password", data: {} });
            }

            const token = jwt.sign(
                { _id: applicant._id.toString(), email: applicant.emailAddress, type: 'applicant' },
                process.env.JWT_TOKEN || 'researchvia-jwt-secret',
                { expiresIn: '24h' }
            );

            const data = applicant.toObject();
            delete data.password;
            delete data.emailOtp;
            delete data.mobileOtp;

            return res.status(200).send({
                status: 200,
                message: "Login successful",
                data: {
                    applicant: data,
                    token,
                    currentStep: applicant.currentStep || 1
                }
            });
        } catch (error) {
            console.error("[continueLogin Error]:", error);
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    sendMobileOtp: async (req, res) => {
        try {
            const { applicantId, mobileNumber } = req.body;
            if (!applicantId || !mobileNumber) {
                return res.status(400).send({ status: 400, message: "Applicant ID and mobile number are required", data: {} });
            }

            const phoneInfo = normalizeIndianMobile(mobileNumber);
            if (!phoneInfo.valid) {
                return res.status(400).send({
                    status: 400,
                    message: "Please enter a valid 10-digit Indian mobile number",
                    data: {}
                });
            }

            const applicant = await applicantModel.findById(applicantId);
            if (!applicant) {
                return res.status(404).send({ status: 404, message: "Applicant not found", data: {} });
            }

            // Check if mobile number belongs to an active staff member
            const existingStaff = await staffModel.findOne({
                mobileNumber: phoneInfo.numeric12,
                _id: { $ne: applicant.convertedStaffId }
            });
            if (existingStaff) {
                return res.status(400).send({ status: 400, message: "This mobile number is already registered to a staff member", data: {} });
            }

            const mobileOtp = generateOtp();
            applicant.mobileOtp = mobileOtp;
            applicant.mobileOtpExpires = new Date(Date.now() + 10 * 60000);
            await applicant.save();

            await sendMobileOtp(phoneInfo.normalized12, mobileOtp);

            return res.status(200).send({
                status: 200,
                message: `OTP sent to ${phoneInfo.normalized12}`,
                data: { mobileNumber: phoneInfo.normalized12 }
            });
        } catch (error) {
            console.error("[sendMobileOtp Error]:", error);
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    verifyMobileOtp: async (req, res) => {
        try {
            const { applicantId, mobileNumber, otp } = req.body;
            if (!applicantId || !mobileNumber || !otp) {
                return res.status(400).send({ status: 400, message: "Applicant ID, mobile number, and OTP are required", data: {} });
            }

            const phoneInfo = normalizeIndianMobile(mobileNumber);
            if (!phoneInfo.valid) {
                return res.status(400).send({ status: 400, message: "Invalid mobile number format", data: {} });
            }

            const applicant = await findApplicantByIdOrCustomId(applicantId);
            if (!applicant) {
                return res.status(404).send({ status: 404, message: "Applicant not found", data: {} });
            }

            const now = Date.now();
            const mobileExpired = !applicant.mobileOtpExpires || new Date(applicant.mobileOtpExpires).getTime() < now;
            if (String(applicant.mobileOtp).trim() !== String(otp).trim() || mobileExpired) {
                return res.status(400).send({ status: 400, message: "Invalid or expired Mobile OTP", data: {} });
            }

            applicant.mobileNumber = phoneInfo.numeric12;
            applicant.isMobileVerified = true;
            applicant.mobileOtp = null;
            applicant.mobileOtpExpires = null;
            if (applicant.walkInForm) {
                applicant.walkInForm.mobileNumber = phoneInfo.normalized12;
                applicant.markModified('walkInForm');
            }
            await applicant.save();

            return res.status(200).send({
                status: 200,
                message: "Mobile number verified successfully",
                data: { isMobileVerified: true, mobileNumber: phoneInfo.numeric12 }
            });
        } catch (error) {
            console.error("[verifyMobileOtp Error]:", error);
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    saveStep: async (req, res) => {
        try {
            const { id } = req.params;
            const { step, stepData } = req.body;

            const applicant = await findApplicantByIdOrCustomId(id);
            if (!applicant) {
                return res.status(404).send({ status: 404, message: "Applicant not found", data: {} });
            }

            if (!stepData) {
                return res.status(400).send({ status: 400, message: "Step data is required", data: {} });
            }

            // Step 1: Personal Info
            if (stepData.title !== undefined) applicant.title = stepData.title;
            if (stepData.firstName !== undefined) applicant.firstName = stepData.firstName;
            if (stepData.middleName !== undefined) applicant.middleName = stepData.middleName;
            if (stepData.lastName !== undefined) applicant.lastName = stepData.lastName;
            if (stepData.fatherName !== undefined) applicant.fatherName = stepData.fatherName;
            if (stepData.fullName !== undefined) applicant.fullName = stepData.fullName;
            else if (applicant.firstName || applicant.lastName) {
                applicant.fullName = [applicant.firstName, applicant.middleName, applicant.lastName].filter(Boolean).join(' ').trim();
            }

            if (stepData.dob !== undefined) applicant.dob = stepData.dob ? new Date(stepData.dob) : applicant.dob;
            if (stepData.gender !== undefined) applicant.gender = stepData.gender;
            if (stepData.maritalStatus !== undefined) applicant.maritalStatus = stepData.maritalStatus;
            if (stepData.currentLocation !== undefined) applicant.currentLocation = stepData.currentLocation;
            if (stepData.skypeOrLinkedIn !== undefined) applicant.skypeOrLinkedIn = stepData.skypeOrLinkedIn;
            if (stepData.alternateEmail !== undefined) applicant.alternateEmail = stepData.alternateEmail;

            // Identity & Documents
            if (stepData.panNumber !== undefined) applicant.panNumber = stepData.panNumber;
            if (stepData.confirmPanNumber !== undefined) applicant.confirmPanNumber = stepData.confirmPanNumber;
            if (stepData.passportNumber !== undefined) applicant.passportNumber = stepData.passportNumber;
            if (stepData.proofOfAddressType !== undefined) applicant.proofOfAddressType = stepData.proofOfAddressType;
            if (stepData.proofOfAddressUrl !== undefined) applicant.proofOfAddressUrl = stepData.proofOfAddressUrl;
            if (stepData.panUrl !== undefined) applicant.panUrl = stepData.panUrl;
            if (stepData.photoUrl !== undefined) applicant.photoUrl = stepData.photoUrl;

            // Target Role
            if (stepData.appliedRoleId !== undefined) {
                applicant.targetRoleId = stepData.appliedRoleId;
                const r = await roleModel.findById(stepData.appliedRoleId);
                if (r) {
                    applicant.targetRole = r.name;
                    if (r.departmentId) applicant.targetDepartment = r.departmentId.name || null;
                }
            } else if (stepData.targetRole !== undefined) {
                applicant.targetRole = stepData.targetRole;
            }

            // Step 2: Contact details (PROTECT mobileNumber if already verified!)
            if (!applicant.isMobileVerified && stepData.mobileNumber) {
                const p = normalizeIndianMobile(stepData.mobileNumber);
                if (p.valid) applicant.mobileNumber = p.numeric12;
            }
            if (stepData.currentAddress !== undefined) applicant.currentAddress = stepData.currentAddress;
            if (stepData.permanentAddress !== undefined) applicant.permanentAddress = stepData.permanentAddress;
            if (stepData.telephoneResidence !== undefined) applicant.telephoneResidence = stepData.telephoneResidence;

            // Step 3: Education
            if (stepData.highestQualification !== undefined) applicant.highestQualification = stepData.highestQualification;
            if (stepData.majorSubject !== undefined) applicant.majorSubject = stepData.majorSubject;
            if (stepData.instituteUniversity !== undefined) applicant.instituteUniversity = stepData.instituteUniversity;
            if (stepData.yearOfPassing !== undefined) applicant.yearOfPassing = Number(stepData.yearOfPassing);
            if (stepData.percentageGrade !== undefined) applicant.percentageGrade = stepData.percentageGrade;
            if (stepData.academicGap !== undefined) applicant.academicGap = Boolean(stepData.academicGap);
            if (stepData.academicGapDetails !== undefined) applicant.academicGapDetails = stepData.academicGapDetails;
            if (stepData.backlogsCount !== undefined) applicant.backlogsCount = stepData.backlogsCount;
            if (stepData.highestEducationUrl !== undefined) applicant.highestEducationUrl = stepData.highestEducationUrl;

            // Step 4: Professional Qualifications
            if (stepData.professionalQualifications !== undefined) applicant.professionalQualifications = stepData.professionalQualifications;
            if (stepData.nismUrl !== undefined) applicant.nismUrl = stepData.nismUrl;

            // Step 5: Occupational & Emergency Contact
            if (stepData.hasWorkExperience !== undefined) applicant.hasWorkExperience = Boolean(stepData.hasWorkExperience);
            if (stepData.experienceYears !== undefined) applicant.experienceYears = Number(stepData.experienceYears);
            if (stepData.previousCompany !== undefined) applicant.previousCompany = stepData.previousCompany;
            if (stepData.currentDesignation !== undefined) applicant.currentDesignation = stepData.currentDesignation;
            if (stepData.reportingManagerName !== undefined) applicant.reportingManagerName = stepData.reportingManagerName;
            if (stepData.reportingManagerDesignation !== undefined) applicant.reportingManagerDesignation = stepData.reportingManagerDesignation;
            if (stepData.reporteesCount !== undefined) applicant.reporteesCount = Number(stepData.reporteesCount);
            if (stepData.fixedSalary !== undefined) applicant.fixedSalary = stepData.fixedSalary;
            if (stepData.bonusIncentive !== undefined) applicant.bonusIncentive = stepData.bonusIncentive;
            if (stepData.lastCtc !== undefined) applicant.lastCtc = stepData.lastCtc;
            if (stepData.expectedSalary !== undefined) applicant.expectedSalary = stepData.expectedSalary;
            if (stepData.noticePeriod !== undefined) applicant.noticePeriod = stepData.noticePeriod;
            if (stepData.resumeUrl !== undefined) applicant.resumeUrl = stepData.resumeUrl;
            if (stepData.careerGapDetails !== undefined) applicant.careerGapDetails = stepData.careerGapDetails;
            if (stepData.previousEmploymentHistory !== undefined) applicant.previousEmploymentHistory = stepData.previousEmploymentHistory;
            if (stepData.emergencyContact !== undefined) applicant.emergencyContact = stepData.emergencyContact;
            if (stepData.walkInForm !== undefined) {
                applicant.walkInForm = { ...(applicant.walkInForm || {}), ...stepData.walkInForm };
                applicant.markModified('walkInForm');
            }

            // Update current step
            const nextStepNum = Number(step) || applicant.currentStep;
            applicant.currentStep = Math.max(applicant.currentStep || 1, nextStepNum);
            await applicant.save();

            const data = applicant.toObject();
            delete data.password;
            delete data.emailOtp;
            delete data.mobileOtp;

            return res.status(200).send({
                status: 200,
                message: "Step saved successfully",
                data: { applicant: data, currentStep: applicant.currentStep }
            });
        } catch (error) {
            console.error("[saveStep Error]:", error);
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    finalizeApplication: async (req, res) => {
        try {
            const { id } = req.params;
            const applicant = await findApplicantByIdOrCustomId(id);
            if (!applicant) {
                return res.status(404).send({ status: 404, message: "Applicant not found", data: {} });
            }

            if (!applicant.isEmailVerified) {
                return res.status(400).send({ status: 400, message: "Email verification is required before submission", data: {} });
            }

            if (!applicant.isMobileVerified) {
                return res.status(400).send({ status: 400, message: "Mobile number verification is required before submission", data: {} });
            }

            applicant.isDraft = false;
            applicant.stage = 'APPLIED';
            applicant.currentStep = 6;
            applicant.isVerified = true;
            applicant.verifiedAt = new Date();
            applicant.stageHistory.push({
                stage: 'APPLIED',
                note: 'Multi-step application submitted and confirmed by applicant',
                changedAt: new Date()
            });

            await applicant.save();

            const data = applicant.toObject();
            delete data.password;
            delete data.emailOtp;
            delete data.mobileOtp;

            return res.status(200).send({
                status: 200,
                message: "Application submitted successfully! Our HR team will review your profile.",
                data: { applicant: data }
            });
        } catch (error) {
            console.error("[finalizeApplication Error]:", error);
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    registerApplicant: async (req, res) => {
        try {
            const { fullName, mobileNumber, emailAddress, dob, gender, currentAddress, permanentAddress, emergencyContact, experienceYears, previousCompany, lastCtc, appliedRoleId } = req.body;

            if (!fullName || !mobileNumber || !emailAddress) {
                return res.status(400).send({ status: 400, message: "Full Name, Mobile, and Email are required", data: {} });
            }

            const phoneInfo = normalizeIndianMobile(mobileNumber);
            if (!phoneInfo.valid) {
                return res.status(400).send({
                    status: 400,
                    message: "Please enter a valid 10-digit mobile number or 12-digit number with 91 prefix",
                    data: {}
                });
            }

            const normalizedPhone = phoneInfo.numeric12;
            const last10 = phoneInfo.last10;
            const cleanEmail = emailAddress ? emailAddress.trim().toLowerCase() : '';

            if (req.body.walkInForm) {
                req.body.walkInForm.mobileNumber = phoneInfo.normalized12;
            }

            if (emergencyContact && emergencyContact.phone) {
                const emgInfo = normalizeIndianMobile(emergencyContact.phone);
                if (emgInfo.valid) {
                    emergencyContact.phone = emgInfo.normalized12;
                }
            }

            let roleDoc = null;
            if (appliedRoleId) {
                roleDoc = await roleModel.findById(appliedRoleId);
            } else if (req.body.walkInForm?.appliedPosition) {
                roleDoc = await roleModel.findOne({ name: { $regex: new RegExp(`^${req.body.walkInForm.appliedPosition.trim()}$`, 'i') } });
            }

            // Check if already an employee in staffModel
            const existingStaff = await staffModel.findOne({
                $or: [
                    { mobileNumber: normalizedPhone },
                    { emailAddress: cleanEmail }
                ]
            });
            if (existingStaff) {
                return res.status(400).send({ status: 400, message: "A staff member is already registered with these details", data: {} });
            }

            // Search in dedicated applicantModel
            let applicant = await applicantModel.findOne({
                $or: [
                    { mobileNumber: normalizedPhone },
                    { emailAddress: cleanEmail }
                ]
            });

            const mobileOtp = generateOtp();
            const emailOtp = generateOtp();
            const expiry = new Date(Date.now() + 10 * 60000);

            if (applicant) {
                applicant.fullName = fullName;
                applicant.mobileNumber = normalizedPhone;
                applicant.emailAddress = cleanEmail;
                applicant.dob = dob ? new Date(dob) : applicant.dob;
                applicant.gender = gender || applicant.gender;
                applicant.currentAddress = currentAddress || applicant.currentAddress;
                applicant.permanentAddress = permanentAddress || applicant.permanentAddress;
                applicant.emergencyContact = emergencyContact || applicant.emergencyContact;
                if (roleDoc) {
                    applicant.targetRoleId = roleDoc._id;
                    applicant.targetRole = roleDoc.name;
                    if (roleDoc.departmentId) applicant.targetDepartment = roleDoc.departmentId.name || null;
                }
                if (req.body.walkInForm) {
                    applicant.walkInForm = req.body.walkInForm;
                    applicant.markModified('walkInForm');
                }
                applicant.mobileOtp = mobileOtp;
                applicant.mobileOtpExpires = expiry;
                applicant.emailOtp = emailOtp;
                applicant.emailOtpExpires = expiry;
                applicant.isMobileVerified = false;
                applicant.isEmailVerified = false;
                applicant.isVerified = false;
                applicant.stage = 'APPLIED';
                applicant.stageHistory.push({
                    stage: 'APPLIED',
                    note: 'Updated walk-in application form details',
                    changedAt: new Date()
                });
                await applicant.save();
            } else {
                // Generate next unique sequential applicant ID (APP-YYYY-XXXX)
                const currentYear = new Date().getFullYear();
                const yearPrefix = `APP-${currentYear}-`;
                const lastApplicant = await applicantModel
                    .findOne({ applicantId: new RegExp(`^${yearPrefix}`) })
                    .sort({ applicantId: -1 })
                    .lean();

                let nextSeqNum = 1;
                if (lastApplicant && lastApplicant.applicantId) {
                    const parts = lastApplicant.applicantId.split('-');
                    const lastNum = parseInt(parts[parts.length - 1], 10);
                    if (!isNaN(lastNum)) {
                        nextSeqNum = lastNum + 1;
                    }
                }

                let appSeq = `${yearPrefix}${String(nextSeqNum).padStart(4, '0')}`;
                while (await applicantModel.exists({ applicantId: appSeq })) {
                    nextSeqNum++;
                    appSeq = `${yearPrefix}${String(nextSeqNum).padStart(4, '0')}`;
                }

                applicant = await applicantModel.create({
                    applicantId: appSeq,
                    fullName,
                    mobileNumber: normalizedPhone,
                    emailAddress: cleanEmail,
                    dob: dob ? new Date(dob) : null,
                    gender,
                    currentAddress,
                    permanentAddress,
                    emergencyContact,
                    targetRoleId: roleDoc ? roleDoc._id : null,
                    targetRole: roleDoc ? roleDoc.name : (req.body.walkInForm?.appliedPosition || 'Complience Executive'),
                    targetDepartment: roleDoc?.departmentId ? (roleDoc.departmentId.name || null) : null,
                    walkInForm: req.body.walkInForm || {},
                    stage: 'APPLIED',
                    stageHistory: [{
                        stage: 'APPLIED',
                        note: 'Walk-in application registered',
                        changedAt: new Date()
                    }],
                    mobileOtp,
                    mobileOtpExpires: expiry,
                    emailOtp,
                    emailOtpExpires: expiry
                });
            }

            // Dispatch verification OTPs
            await sendMobileOtp(phoneInfo.normalized12, mobileOtp);
            await sendEmailOtp(cleanEmail, emailOtp);

            res.status(200).send({
                status: 200,
                message: "Verification OTPs sent to your mobile and email",
                data: { applicantId: applicant._id }
            });
        } catch (error) {
            console.error("[registerApplicant Error]:", error);
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    verifyOtp: async (req, res) => {
        try {
            const { applicantId, mobileOtp, emailOtp } = req.body;
            if (!applicantId || !mobileOtp || !emailOtp) {
                return res.status(400).send({ status: 400, message: "Applicant ID, mobileOtp, and emailOtp are required", data: {} });
            }

            const applicant = await applicantModel.findById(applicantId);
            if (!applicant) {
                return res.status(404).send({ status: 404, message: "Applicant profile not found", data: {} });
            }

            const now = Date.now();
            const mobileExpired = !applicant.mobileOtpExpires || new Date(applicant.mobileOtpExpires).getTime() < now;
            if (String(applicant.mobileOtp).trim() !== String(mobileOtp).trim() || mobileExpired) {
                return res.status(400).send({ status: 400, message: "Invalid or expired Mobile OTP", data: {} });
            }

            const emailExpired = !applicant.emailOtpExpires || new Date(applicant.emailOtpExpires).getTime() < now;
            if (String(applicant.emailOtp).trim() !== String(emailOtp).trim() || emailExpired) {
                return res.status(400).send({ status: 400, message: "Invalid or expired Email OTP", data: {} });
            }

            applicant.isMobileVerified = true;
            applicant.isEmailVerified = true;
            applicant.isVerified = true;
            applicant.verifiedAt = new Date();
            applicant.mobileOtp = null;
            applicant.emailOtp = null;
            await applicant.save();

            res.status(200).send({ status: 200, message: "Mobile and Email verified successfully", data: { applicant } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    updateContactAndResendOtp: async (req, res) => {
        try {
            const { applicantId, mobileNumber, emailAddress } = req.body;
            if (!applicantId) {
                return res.status(400).send({ status: 400, message: "Applicant ID is required", data: {} });
            }
            if (!mobileNumber || !emailAddress) {
                return res.status(400).send({ status: 400, message: "Mobile number and email address are required", data: {} });
            }

            const phoneInfo = normalizeIndianMobile(mobileNumber);
            if (!phoneInfo.valid) {
                return res.status(400).send({
                    status: 400,
                    message: "Please enter a valid 10-digit mobile number or 12-digit number with 91 prefix",
                    data: {}
                });
            }

            const applicant = await applicantModel.findById(applicantId);
            if (!applicant) {
                return res.status(404).send({ status: 404, message: "Applicant not found", data: {} });
            }

            const cleanEmail = emailAddress.trim().toLowerCase();
            const normalizedPhone = phoneInfo.numeric12;

            // Check if phone/email belongs to another existing staff
            const existingStaff = await staffModel.findOne({
                _id: { $ne: applicant.convertedStaffId },
                $or: [
                    { mobileNumber: normalizedPhone },
                    { emailAddress: cleanEmail }
                ]
            });
            if (existingStaff) {
                return res.status(400).send({ status: 400, message: "A staff member is already registered with these details", data: {} });
            }

            const mobileOtp = generateOtp();
            const emailOtp = generateOtp();
            const expiry = new Date(Date.now() + 10 * 60000);

            applicant.mobileNumber = normalizedPhone;
            applicant.emailAddress = cleanEmail;
            if (applicant.walkInForm) {
                applicant.walkInForm.mobileNumber = phoneInfo.normalized12;
                applicant.walkInForm.emailAddress = cleanEmail;
                applicant.markModified('walkInForm');
            }
            applicant.mobileOtp = mobileOtp;
            applicant.mobileOtpExpires = expiry;
            applicant.emailOtp = emailOtp;
            applicant.emailOtpExpires = expiry;
            applicant.isMobileVerified = false;
            applicant.isEmailVerified = false;
            applicant.isVerified = false;
            await applicant.save();

            // Dispatch verification OTPs
            await sendMobileOtp(phoneInfo.normalized12, mobileOtp);
            await sendEmailOtp(cleanEmail, emailOtp);

            return res.status(200).send({
                status: 200,
                message: "New verification codes sent to your updated mobile and email",
                data: {
                    applicantId: applicant._id,
                    mobileNumber: applicant.mobileNumber,
                    emailAddress: applicant.emailAddress
                }
            });
        } catch (error) {
            console.error("[updateContactAndResendOtp Error]:", error);
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

            const applicant = await findApplicantByIdOrCustomId(id);
            if (!applicant) {
                return res.status(404).send({ status: 404, message: "Applicant not found", data: {} });
            }

            const fieldMap = {
                pan: 'panUrl',
                pancard: 'panUrl',
                aadhaar: 'aadhaarUrl',
                poa: 'aadhaarUrl',
                nism: 'nismUrl',
                certificate: 'nismUrl',
                education: 'highestEducationUrl',
                highestEducation: 'highestEducationUrl',
                degree: 'highestEducationUrl',
                photo: 'photoUrl',
                resume: 'resumeUrl'
            };
            const field = fieldMap[type];
            if (!field) {
                return res.status(400).send({ status: 400, message: "Invalid document type: " + type, data: {} });
            }

            applicant[field] = req.file.path;
            if (!applicant.documents) applicant.documents = {};
            applicant.documents[type] = req.file.path;
            applicant.markModified('documents');
            if (applicant.photoUrl && applicant.resumeUrl && applicant.panUrl && applicant.aadhaarUrl) {
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

            const applicant = await findApplicantByIdOrCustomId(id);
            if (!applicant) {
                return res.status(404).send({ status: 404, message: "Applicant not found", data: {} });
            }

            applicant.kycVideoUrl = req.file.path;
            applicant.onboardingStatus = 'VERIFIED';
            await applicant.save();

            res.status(200).send({ status: 200, message: "KYC Video uploaded successfully", data: { applicant } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    listApplicants: async (req, res) => {
        try {
            const { stage, search } = req.query;
            const filter = {};

            if (stage && stage !== 'ALL') {
                if (stage === 'PROMOTED') {
                    filter.$or = [{ stage: 'PROMOTED' }, { stage: 'OFFER_ACCEPTED' }, { convertedStaffId: { $ne: null } }];
                } else if (stage === 'OFFER_ACCEPTED') {
                    filter.$or = [{ stage: 'OFFER_ACCEPTED' }, { stage: 'PROMOTED' }];
                } else {
                    filter.stage = stage;
                }
            }

            if (search && search.trim().length > 0) {
                const s = search.trim();
                const numericSearch = s.replace(/\D/g, '');
                filter.$or = [
                    { fullName: { $regex: s, $options: 'i' } },
                    { emailAddress: { $regex: s, $options: 'i' } },
                    { applicantId: { $regex: s, $options: 'i' } },
                    { targetRole: { $regex: s, $options: 'i' } }
                ];
                if (numericSearch.length >= 4) {
                    const num = parseInt(numericSearch, 10);
                    if (!isNaN(num)) {
                        filter.$or.push({ mobileNumber: num });
                    }
                    if (numericSearch.length === 10) {
                        const num12 = parseInt(`91${numericSearch}`, 10);
                        if (!isNaN(num12)) {
                            filter.$or.push({ mobileNumber: num12 });
                        }
                    }
                }
            }

            const applicants = await applicantModel.find(filter).sort({ createdAt: -1 }).lean();
            res.status(200).send({
                status: 200,
                message: "Applicants retrieved successfully",
                data: {
                    applicants,
                    totalCount: applicants.length
                }
            });
        } catch (error) {
            console.error("[listApplicants Error]:", error);
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    updateApplicantStage: async (req, res) => {
        try {
            const { id } = req.params;
            const { stage, note } = req.body;

            const validStages = [
                "APPLIED",
                "SCREENING",
                "SHORTLISTED",
                "INTERVIEW",
                "SELECTED",
                "OFFER_SENT",
                "OFFER_ACCEPTED",
                "ONBOARDING",
                "PROMOTED",
                "REJECTED",
                "WITHDRAWN"
            ];

            if (!stage || !validStages.includes(stage.toUpperCase())) {
                return res.status(400).send({
                    status: 400,
                    message: `Invalid stage. Valid stages are: ${validStages.join(', ')}`,
                    data: {}
                });
            }

            const targetStage = stage.toUpperCase();
            const applicant = await findApplicantByIdOrCustomId(id);
            if (!applicant) {
                return res.status(404).send({ status: 404, message: "Applicant not found", data: {} });
            }

            const prevStage = applicant.stage;
            applicant.stage = targetStage;
            if (targetStage === 'REJECTED' && note) {
                applicant.rejectionReason = note;
            }

            applicant.stageHistory.push({
                stage: targetStage,
                note: note || `Stage updated from ${prevStage} to ${targetStage}`,
                changedBy: req.user?._id || null,
                changedAt: new Date()
            });

            await applicant.save();

            res.status(200).send({
                status: 200,
                message: `Applicant stage updated to ${targetStage} successfully`,
                data: { applicant }
            });
        } catch (error) {
            console.error("[updateApplicantStage Error]:", error);
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    rejectApplicant: async (req, res) => {
        try {
            const { id } = req.params;
            const { rejectionReason, reason, note } = req.body;
            const effectiveReason = rejectionReason || reason || note || 'Application rejected by reviewer';

            const applicant = await findApplicantByIdOrCustomId(id);
            if (!applicant) {
                return res.status(404).send({ status: 404, message: "Applicant not found", data: {} });
            }

            applicant.stage = 'REJECTED';
            applicant.rejectionReason = effectiveReason;
            applicant.stageHistory.push({
                stage: 'REJECTED',
                note: effectiveReason,
                changedBy: req.user?._id || null,
                changedAt: new Date()
            });

            await applicant.save();

            res.status(200).send({
                status: 200,
                message: "Applicant rejected successfully",
                data: { applicant }
            });
        } catch (error) {
            console.error("[rejectApplicant Error]:", error);
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    approveApplicant: async (req, res) => {
        try {
            const { id } = req.params;
            const {
                roleId,
                role,
                deparment,
                mpin,
                joiningDate,
                isViewOnly,
                assignedDirector,
                assignedDirectorName,
                supervisorId,
                supervisorName,
                reportingTo,
                note
            } = req.body;

            const applicant = await applicantModel.findById(id).select('+password');
            if (!applicant) {
                return res.status(404).send({ status: 404, message: "Applicant record not found", data: {} });
            }

            const effectiveSupervisorId = assignedDirector || supervisorId || reportingTo || null;
            const effectiveSupervisorName = assignedDirectorName || supervisorName || null;

            // Resolve role and department gracefully (defaults to applicant info or unassigned)
            const targetRoleId = roleId || applicant.targetRoleId || null;
            const targetRoleName = role || applicant.targetRole || null;
            const targetDeptName = deparment || applicant.targetDepartment || null;

            let resolved = { roleId: null, roleName: null, departmentId: null, departmentName: null };
            if (targetRoleId || targetRoleName || targetDeptName) {
                try {
                    resolved = await resolveRoleAndDepartment({
                        roleId: targetRoleId,
                        roleName: targetRoleName,
                        fallbackDept: targetDeptName
                    });
                } catch (e) {
                    console.warn("[approveApplicant] Role resolution warning:", e.message);
                }
            }

            // Check if already an employee in staffModel
            let staff = await staffModel.findOne({
                $or: [
                    { applicantId: applicant._id },
                    { emailAddress: applicant.emailAddress.toLowerCase() },
                    { mobileNumber: applicant.mobileNumber }
                ]
            });

            const isDirectAdmin = effectiveSupervisorId === 'admin' || effectiveSupervisorName === 'Admin';
            let finalSupervisorId = null;
            let finalSupervisorName = null;

            if (isDirectAdmin) {
                finalSupervisorName = 'Admin';
            } else if (effectiveSupervisorId && effectiveSupervisorId !== 'unassigned') {
                finalSupervisorId = effectiveSupervisorId;
                if (effectiveSupervisorName && effectiveSupervisorName.trim().length > 0) {
                    finalSupervisorName = effectiveSupervisorName.trim();
                } else {
                    const supervisor = await staffModel.findById(effectiveSupervisorId).select('fullName status');
                    finalSupervisorName = supervisor ? supervisor.fullName : null;
                }
            }

            const effectiveMpin = mpin ? mpin.toString().trim() : '0000';

            if (!staff) {
                // Generate a unique staff ID
                const count = await staffModel.countDocuments();
                const staffId = `STF${String(count + 1).padStart(3, '0')}${Math.floor(1000 + Math.random() * 9000)}`;

                staff = await staffModel.create({
                    applicantId: applicant._id,
                    staffId,
                    fullName: applicant.fullName,
                    emailAddress: applicant.emailAddress.toLowerCase(),
                    password: applicant.password || null,
                    mobileNumber: applicant.mobileNumber,
                    countryCode: applicant.countryCode || "+91",
                    dob: applicant.dob,
                    gender: applicant.gender,
                    currentAddress: applicant.currentAddress,
                    permanentAddress: applicant.permanentAddress,
                    emergencyContact: applicant.emergencyContact,
                    photoUrl: applicant.photoUrl,
                    resumeUrl: applicant.resumeUrl,
                    aadhaarUrl: applicant.aadhaarUrl,
                    panUrl: applicant.panUrl,
                    joiningDate: joiningDate ? new Date(joiningDate) : new Date(),
                    status: 'Active',
                    roleId: resolved.roleId,
                    role: resolved.roleName,
                    departmentId: resolved.departmentId,
                    deparment: resolved.departmentName,
                    mpin: effectiveMpin,
                    assignedDirector: finalSupervisorId,
                    assignedDirectorName: finalSupervisorName,
                    isViewOnly: isViewOnly === true || isViewOnly === 'true',
                    walkInForm: applicant.walkInForm || {},
                    agreementStatus: 'PENDING_SIGNATURE'
                });
            } else {
                // Update existing staff record
                staff.applicantId = applicant._id;
                staff.fullName = applicant.fullName;
                if (applicant.password) {
                    staff.password = applicant.password;
                }
                if (resolved.roleId) staff.roleId = resolved.roleId;
                if (resolved.roleName) staff.role = resolved.roleName;
                if (resolved.departmentId) staff.departmentId = resolved.departmentId;
                if (resolved.departmentName) staff.deparment = resolved.departmentName;
                if (mpin) staff.mpin = effectiveMpin;
                staff.joiningDate = joiningDate ? new Date(joiningDate) : (staff.joiningDate || new Date());
                staff.status = 'Active';
                if (finalSupervisorId || isDirectAdmin) {
                    staff.assignedDirector = finalSupervisorId;
                    staff.assignedDirectorName = finalSupervisorName;
                }
                if (isViewOnly !== undefined) {
                    staff.isViewOnly = isViewOnly === true || isViewOnly === 'true';
                }
                if (!staff.agreementStatus || staff.agreementStatus === 'NOT_INITIATED') {
                    staff.agreementStatus = 'PENDING_SIGNATURE';
                }
                await staff.save();
            }

            // Update applicant stage and link
            applicant.stage = 'PROMOTED';
            applicant.convertedStaffId = staff._id;
            applicant.hiredAt = new Date();
            applicant.stageHistory.push({
                stage: 'PROMOTED',
                note: note || `Applicant promoted to Staff (Staff ID: ${staff.staffId})`,
                changedBy: req.user?._id || null,
                changedAt: new Date()
            });
            await applicant.save();

            // Automatically initialize personalized Digio Aadhaar agreement & dispatch branded email
            try {
                await staffService.initiateStaffDigioAgreement(staff._id);
            } catch (digioErr) {
                console.warn("[Applicant Approval] Auto Digio agreement error:", digioErr.message);
            }

            const updatedStaff = await staffModel.findById(staff._id)
                .populate('departmentId')
                .populate({
                    path: 'roleId',
                    populate: [
                        { path: 'permissionGroups' },
                        { path: 'departmentId' }
                    ]
                });

            res.status(200).send({
                status: 200,
                message: "Applicant promoted to Staff successfully",
                data: { staff: updatedStaff || staff, applicant }
            });
        } catch (error) {
            console.error("[approveApplicant Error]:", error);
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    getApplicantDetails: async (req, res) => {
        try {
            const { id } = req.params;
            const applicant = await findApplicantByIdOrCustomId(id);
            if (!applicant) {
                return res.status(404).send({ status: 404, message: "Applicant not found", data: {} });
            }

            const data = applicant.toObject();
            delete data.emailOtp;
            delete data.emailOtpExpires;
            delete data.mobileOtp;
            delete data.mobileOtpExpires;
            if (!data.onboardingStatus) {
                data.onboardingStatus = data.kycVideoUrl ? 'VERIFIED' : (data.isVerified ? 'VERIFIED' : 'PENDING');
            }

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

            const cleanInput = identifier.trim();
            const isEmail = cleanInput.includes('@');
            let query = {};
            let targetMobile = '';

            if (isEmail) {
                const cleanEmail = cleanInput.toLowerCase();
                query.emailAddress = { $regex: new RegExp(`^${cleanEmail.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&')}$`, 'i') };
            } else {
                const phoneInfo = normalizeIndianMobile(cleanInput);
                if (!phoneInfo.valid) {
                    return res.status(400).send({
                        status: 400,
                        message: "Please enter a valid 10-digit mobile number or 12-digit number with 91 prefix",
                        data: {}
                    });
                }
                targetMobile = phoneInfo.normalized12;
                query.mobileNumber = phoneInfo.numeric12;
            }

            const applicant = await applicantModel.findOne(query);
            if (!applicant) {
                return res.status(400).send({ status: 400, message: "No such applicant found with this " + (isEmail ? "email" : "mobile number"), data: {} });
            }

            const otp = generateOtp().toString();
            const expires = new Date(Date.now() + 10 * 60 * 1000);

            if (isEmail) {
                applicant.emailOtp = otp;
                applicant.emailOtpExpires = expires;
                await applicant.save();
                await sendEmailOtp(applicant.emailAddress, otp);
            } else {
                applicant.mobileOtp = otp;
                applicant.mobileOtpExpires = expires;
                await applicant.save();
                const sendTo = targetMobile || applicant.mobileNumber.toString();
                await sendMobileOtp(sendTo, otp);
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

            const cleanInput = identifier.trim();
            const isEmail = cleanInput.includes('@');
            let query = {};

            if (isEmail) {
                const cleanEmail = cleanInput.toLowerCase();
                query.emailAddress = { $regex: new RegExp(`^${cleanEmail.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&')}$`, 'i') };
            } else {
                const phoneInfo = normalizeIndianMobile(cleanInput);
                const with91Num = phoneInfo.valid ? phoneInfo.numeric12 : parseInt(`91${cleanInput.slice(-10)}`, 10);
                query.mobileNumber = with91Num;
            }

            const applicant = await applicantModel.findOne(query);
            if (!applicant) {
                return res.status(400).send({ status: 400, message: "Applicant not found", data: {} });
            }

            const submittedOtp = String(otp).trim();
            const now = Date.now();
            if (otpType === 'email') {
                const isExpired = !applicant.emailOtpExpires || new Date(applicant.emailOtpExpires).getTime() < now;
                if (String(applicant.emailOtp).trim() !== submittedOtp || isExpired) {
                    return res.status(400).send({ status: 400, message: "Invalid or expired email OTP", data: {} });
                }
                applicant.isEmailVerified = true;
                applicant.emailOtp = null;
            } else {
                const isExpired = !applicant.mobileOtpExpires || new Date(applicant.mobileOtpExpires).getTime() < now;
                if (String(applicant.mobileOtp).trim() !== submittedOtp || isExpired) {
                    return res.status(400).send({ status: 400, message: "Invalid or expired mobile OTP", data: {} });
                }
                applicant.isMobileVerified = true;
                applicant.mobileOtp = null;
            }

            applicant.isVerified = true;
            applicant.verifiedAt = new Date();
            await applicant.save();

            res.status(200).send({
                status: 200,
                message: "Verification successful",
                data: { applicantId: applicant._id }
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    saveEvaluationRemarks: async (req, res) => {
        try {
            const { id } = req.params;
            const { recruiterRemarks, interviewerRemarks } = req.body;

            const applicant = await findApplicantByIdOrCustomId(id);
            if (!applicant) {
                return res.status(404).send({ status: 404, message: "Applicant not found", data: {} });
            }

            if (!applicant.walkInForm) {
                applicant.walkInForm = {};
            }

            if (recruiterRemarks !== undefined) {
                applicant.walkInForm.recruiterRemarks = recruiterRemarks;
            }
            if (interviewerRemarks !== undefined) {
                applicant.walkInForm.interviewerRemarks = interviewerRemarks;
            }

            applicant.markModified('walkInForm');
            await applicant.save();

            res.status(200).send({
                status: 200,
                message: "Evaluation remarks saved successfully",
                data: { walkInForm: applicant.walkInForm }
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    }
};

export default applicantController;
