import applicantModel from "../models/applicantModel.js";
import staffModel from "../models/staffModel.js";
import emailService from "../services/emailService.js";
import offerLetterService from "../services/offerLetterService.js";
import { sendOtpSms } from "../services/smsService.js";
import axios from "axios";
import staffService, { resolveRoleAndDepartment } from "../services/staffService.js";
import roleModel from "../models/roleModel.js";
import { getSupervisedStaffIds } from "../utils/staffHierarchy.js";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import mongoose from "mongoose";

const generateOtp = () => Math.floor(1000 + Math.random() * 9000);

const findApplicantByIdOrCustomId = async (id, selectPassword = false) => {
    if (!id) return null;
    const strId = String(id).trim();
    if (!strId || strId === 'null' || strId === 'undefined') return null;
    const applySelect = (q) => selectPassword ? q.select('+password') : q;
    if (mongoose.Types.ObjectId.isValid(strId)) {
        const doc = await applySelect(applicantModel.findById(strId));
        if (doc) return doc;
    }
    const byAppId = await applySelect(applicantModel.findOne({ applicantId: strId }));
    if (byAppId) return byAppId;
    if (strId.includes('@')) {
        return await applySelect(applicantModel.findOne({ emailAddress: strId.toLowerCase() }));
    }
    return null;
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
        const { valid, last10 } = normalizeIndianMobile(phone);
        const targetPhone = valid ? last10 : phone;
        console.log(`[SMS Gateway] Sending applicant mobile OTP to ${targetPhone} via Airtel IQ SMS...`);
        const result = await sendOtpSms(targetPhone, otp, 'ResearchVia');
        return result && (result.success || result.status === 200);
    } catch (e) {
        console.error('[SMS Gateway] Error sending mobile SMS:', e.message);
        return false;
    }
};

const sendEmailOtp = async (email, otp) => {
    try {
        const cleanEmail = email ? email.trim() : '';
        if (!cleanEmail) return false;

        console.log(`🔑 [Applicant OTP] Generated code for ${cleanEmail}: ${otp}`);
        const result = await emailService.sendOtpEmail({
            to: cleanEmail,
            otp: otp,
            recipientName: 'Applicant',
            purpose: 'Career Application Verification'
        });
        return result && (result.success || result.accepted?.length > 0);
    } catch (e) {
        console.error('[Email Gateway] Error sending email OTP:', e.message);
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
            const cleanPassword = String(password).trim();
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
                applicant.password = cleanPassword;
                applicant.plainPassword = cleanPassword;
                applicant.emailOtp = emailOtp;
                applicant.emailOtpExpires = expiry;
                applicant.isEmailVerified = false;
                await applicant.save();
            } else {
                const applicantId = await generateNextApplicantId();
                applicant = await applicantModel.create({
                    applicantId,
                    emailAddress: cleanEmail,
                    password: cleanPassword,
                    plainPassword: cleanPassword,
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

            if (!applicant.password && !applicant.plainPassword) {
                return res.status(400).send({ status: 400, message: "Password not set for this application. Please reset or contact HR.", data: {} });
            }

            const candidatePass = password.toString();
            const isMatch = (applicant.password === candidatePass) ||
                            (applicant.plainPassword === candidatePass) ||
                            (applicant.password && await bcrypt.compare(candidatePass, applicant.password).catch(() => false));
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

    forgotPasswordOtp: async (req, res) => {
        try {
            const { emailAddress } = req.body;
            if (!emailAddress || !emailAddress.trim()) {
                return res.status(400).send({ status: 400, message: "Email address is required", data: {} });
            }

            const cleanEmail = emailAddress.trim().toLowerCase();

            // Check applicantModel first
            let applicant = await applicantModel.findOne({ emailAddress: cleanEmail });

            // If not found in applicants, check if they exist in staffModel (e.g. walk-in applicant recorded in staff)
            if (!applicant) {
                const staffRecord = await staffModel.findOne({ emailAddress: cleanEmail });
                if (staffRecord) {
                    const applicantId = await generateNextApplicantId();
                    applicant = await applicantModel.create({
                        applicantId,
                        fullName: staffRecord.fullName || staffRecord.name || '',
                        emailAddress: cleanEmail,
                        mobileNumber: staffRecord.mobileNumber || null,
                        isDraft: false,
                        currentStep: 1,
                        stage: 'APPLIED',
                        walkInForm: staffRecord.walkInForm || null,
                        stageHistory: [{
                            stage: 'APPLIED',
                            note: 'Migrated from staff record for application resume',
                            changedAt: new Date()
                        }]
                    });
                }
            }

            if (!applicant) {
                return res.status(404).send({
                    status: 404,
                    message: "No application found with this email. Please click 'Create Application Account' to start.",
                    data: {}
                });
            }

            const otp = generateOtp();
            applicant.emailOtp = otp;
            applicant.emailOtpExpires = new Date(Date.now() + 10 * 60000);
            await applicant.save();

            await sendEmailOtp(cleanEmail, otp);

            return res.status(200).send({
                status: 200,
                message: "Verification code sent to your registered email address.",
                data: {
                    emailAddress: cleanEmail,
                    hasExistingPassword: !!applicant.password
                }
            });
        } catch (error) {
            console.error("[forgotPasswordOtp Error]:", error);
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    resetPassword: async (req, res) => {
        try {
            const { emailAddress, otp, newPassword } = req.body;
            if (!emailAddress || !otp || !newPassword) {
                return res.status(400).send({
                    status: 400,
                    message: "Email address, OTP, and new password are required",
                    data: {}
                });
            }

            if (newPassword.length < 6) {
                return res.status(400).send({
                    status: 400,
                    message: "Password must be at least 6 characters long",
                    data: {}
                });
            }

            const cleanEmail = emailAddress.trim().toLowerCase();
            const applicant = await applicantModel.findOne({ emailAddress: cleanEmail }).select('+password +emailOtp +emailOtpExpires');
            if (!applicant) {
                return res.status(404).send({ status: 404, message: "Applicant profile not found", data: {} });
            }

            const submittedOtp = String(otp).trim();
            const now = Date.now();
            const isExpired = !applicant.emailOtpExpires || new Date(applicant.emailOtpExpires).getTime() < now;

            if (String(applicant.emailOtp).trim() !== submittedOtp || isExpired) {
                return res.status(400).send({ status: 400, message: "Invalid or expired OTP", data: {} });
            }

            const cleanPassword = String(newPassword).trim();
            applicant.password = cleanPassword;
            applicant.plainPassword = cleanPassword;
            applicant.emailOtp = null;
            applicant.emailOtpExpires = null;
            applicant.isEmailVerified = true;
            await applicant.save();

            // Also sync password to staff record if one exists with the same email
            await staffModel.updateOne(
                { emailAddress: cleanEmail },
                { $set: { password: cleanPassword, plainPassword: cleanPassword, updatedAt: new Date() } }
            );

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
                message: "Password set successfully. Continuing to your application...",
                data: {
                    applicant: data,
                    token,
                    currentStep: applicant.currentStep || 1
                }
            });
        } catch (error) {
            console.error("[resetPassword Error]:", error);
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
            if (stepData.aadhaarNumber !== undefined) applicant.aadhaarNumber = stepData.aadhaarNumber;
            if (stepData.passportNumber !== undefined) applicant.passportNumber = stepData.passportNumber;
            if (stepData.proofOfAddressType !== undefined) applicant.proofOfAddressType = stepData.proofOfAddressType;
            if (stepData.proofOfAddressUrl !== undefined) {
                applicant.proofOfAddressUrl = stepData.proofOfAddressUrl;
                applicant.aadhaarUrl = stepData.proofOfAddressUrl;
            }
            if (stepData.aadhaarUrl !== undefined) {
                applicant.aadhaarUrl = stepData.aadhaarUrl;
                if (!applicant.proofOfAddressUrl) applicant.proofOfAddressUrl = stepData.aadhaarUrl;
            }
            if (stepData.aadhaarFrontUrl !== undefined) {
                applicant.aadhaarUrl = stepData.aadhaarFrontUrl;
                applicant.proofOfAddressUrl = stepData.aadhaarFrontUrl;
            }
            if (stepData.aadhaarBackUrl !== undefined) {
                applicant.aadhaarBackUrl = stepData.aadhaarBackUrl;
            }
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

            // Contact details (save mobileNumber directly)
            if (stepData.mobileNumber) {
                const p = normalizeIndianMobile(stepData.mobileNumber);
                if (p.valid) {
                    applicant.mobileNumber = p.numeric12;
                } else {
                    const clean = String(stepData.mobileNumber).replace(/\D/g, '');
                    if (clean) applicant.mobileNumber = Number(clean);
                }
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
            if (stepData.isFresher !== undefined) {
                applicant.isFresher = Boolean(stepData.isFresher);
                applicant.hasWorkExperience = !Boolean(stepData.isFresher);
            } else if (stepData.hasWorkExperience !== undefined) {
                applicant.hasWorkExperience = Boolean(stepData.hasWorkExperience);
                applicant.isFresher = !Boolean(stepData.hasWorkExperience);
            }
            if (stepData.kycVideoUrl !== undefined) applicant.kycVideoUrl = stepData.kycVideoUrl;
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
            if (stepData.relievingLetterUrl !== undefined) applicant.relievingLetterUrl = stepData.relievingLetterUrl;
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

            applicant.isDraft = false;
            applicant.stage = 'APPLIED';
            applicant.currentStep = 3;
            applicant.onboardingStatus = applicant.kycVideoUrl ? 'VERIFIED' : ((applicant.photoUrl && applicant.resumeUrl) ? 'DOCUMENTS_UPLOADED' : 'SUBMITTED');
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
            const id = req.params?.id || req.query?.applicantId || req.query?.id || req.body?.applicantId || req.body?.id;
            const type = req.query?.type || req.body?.type; // 'pan', 'aadhaar', 'nism', 'education', 'photo', 'resume'
            if (!req.file) {
                return res.status(400).send({ status: 400, message: "No file uploaded", data: {} });
            }

            let applicant = null;
            if (id && id !== 'null' && id !== 'undefined') {
                applicant = await findApplicantByIdOrCustomId(id);
            }
            if (!applicant && req.body?.emailAddress) {
                applicant = await applicantModel.findOne({ emailAddress: String(req.body.emailAddress).trim().toLowerCase() });
            }
            if (!applicant) {
                applicant = await applicantModel.findOne({ isDraft: true }).sort({ createdAt: -1 });
            }
            if (!applicant) {
                const applicantId = await generateNextApplicantId();
                applicant = await applicantModel.create({
                    applicantId,
                    emailAddress: `applicant_${Date.now()}@temp.com`,
                    fullName: '',
                    isDraft: true,
                    currentStep: 1,
                    stage: 'APPLIED',
                });
            }

            const fieldMap = {
                pan: 'panUrl',
                pancard: 'panUrl',
                aadhaar: 'aadhaarUrl',
                aadhaarFront: 'aadhaarUrl',
                aadhaar_front: 'aadhaarUrl',
                aadhaarBack: 'aadhaarBackUrl',
                aadhaar_back: 'aadhaarBackUrl',
                poa: 'aadhaarUrl',
                nism: 'nismUrl',
                certificate: 'nismUrl',
                education: 'highestEducationUrl',
                highestEducation: 'highestEducationUrl',
                degree: 'highestEducationUrl',
                photo: 'photoUrl',
                resume: 'resumeUrl',
                relieving: 'relievingLetterUrl',
                relievingLetter: 'relievingLetterUrl',
                relieving_letter: 'relievingLetterUrl'
            };
            const field = fieldMap[type];
            if (!field) {
                return res.status(400).send({ status: 400, message: "Invalid document type: " + type, data: {} });
            }

            applicant[field] = req.file.path;
            if (field === 'aadhaarUrl') {
                applicant.proofOfAddressUrl = req.file.path;
            }
            if (!applicant.documents) applicant.documents = {};
            applicant.documents[type] = req.file.path;
            applicant.markModified('documents');
            if (applicant.photoUrl && applicant.resumeUrl && (applicant.aadhaarUrl || applicant.proofOfAddressUrl) && applicant.aadhaarBackUrl) {
                applicant.onboardingStatus = applicant.kycVideoUrl ? 'VERIFIED' : 'DOCUMENTS_UPLOADED';
            }
            await applicant.save();

            res.status(200).send({ status: 200, message: `${type} uploaded successfully`, data: { applicant } });
        } catch (error) {
            console.error("[uploadApplicantDoc Error]:", error);
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    uploadApplicantVideo: async (req, res) => {
        try {
            const id = req.params?.id || req.query?.applicantId || req.query?.id || req.body?.applicantId || req.body?.id;
            const email = req.body?.emailAddress || req.query?.email || req.body?.email;
            if (!req.file) {
                return res.status(400).send({ status: 400, message: "No video file uploaded", data: {} });
            }

            let applicant = null;
            if (id && id !== 'null' && id !== 'undefined') {
                applicant = await findApplicantByIdOrCustomId(id);
            }
            if (!applicant && email) {
                applicant = await applicantModel.findOne({ emailAddress: String(email).trim().toLowerCase() });
            }
            if (!applicant) {
                // Find latest draft applicant or create a draft applicant so the video upload is NEVER rejected
                applicant = await applicantModel.findOne({ isDraft: true }).sort({ createdAt: -1 });
            }
            if (!applicant) {
                const applicantId = await generateNextApplicantId();
                const cleanEmail = email ? String(email).trim().toLowerCase() : `applicant_${Date.now()}@temp.com`;
                applicant = await applicantModel.create({
                    applicantId,
                    emailAddress: cleanEmail,
                    fullName: '',
                    isDraft: true,
                    currentStep: 3,
                    stage: 'APPLIED',
                });
            }

            applicant.kycVideoUrl = req.file.path;
            if (!applicant.documents) applicant.documents = {};
            applicant.documents['video'] = req.file.path;
            applicant.documents['kycVideo'] = req.file.path;
            applicant.markModified('documents');
            applicant.onboardingStatus = 'VERIFIED';
            await applicant.save();

            res.status(200).send({ status: 200, message: "KYC Video uploaded successfully", data: { applicant } });
        } catch (error) {
            console.error("[uploadApplicantVideo Error]:", error);
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    listApplicants: async (req, res) => {
        try {
            const { stage, search } = req.query;
            const stageFilter = {};

            if (stage && stage !== 'ALL') {
                if (stage === 'PROMOTED') {
                    stageFilter.$or = [{ stage: 'PROMOTED' }, { stage: 'OFFER_ACCEPTED' }, { convertedStaffId: { $ne: null } }];
                } else if (stage === 'OFFER_ACCEPTED') {
                    stageFilter.$or = [{ stage: 'OFFER_ACCEPTED' }, { stage: 'PROMOTED' }];
                } else {
                    stageFilter.stage = stage;
                }
            }

            const searchFilter = {};
            if (search && search.trim().length > 0) {
                const s = search.trim();
                const numericSearch = s.replace(/\D/g, '');
                searchFilter.$or = [
                    { fullName: { $regex: s, $options: 'i' } },
                    { emailAddress: { $regex: s, $options: 'i' } },
                    { applicantId: { $regex: s, $options: 'i' } },
                    { targetRole: { $regex: s, $options: 'i' } }
                ];
                if (numericSearch.length >= 4) {
                    const num = parseInt(numericSearch, 10);
                    if (!isNaN(num)) {
                        searchFilter.$or.push({ mobileNumber: num });
                    }
                    if (numericSearch.length === 10) {
                        const num12 = parseInt(`91${numericSearch}`, 10);
                        if (!isNaN(num12)) {
                            searchFilter.$or.push({ mobileNumber: num12 });
                        }
                    }
                }
            }

            // Staff Scoping: If caller is staff (and not super admin), only show applicants assigned to them
            const callerId = req.user?._id || req.user?.userId || req.user?.id;
            let staffScopeFilter = null;

            if (callerId) {
                const hierarchy = await getSupervisedStaffIds(callerId);
                // System admin sees all applicants; regular staff/supervisors only see applicants assigned to them
                if (!hierarchy.isSystemAdmin) {
                    const allowedStaffIds = hierarchy.staffIds || [callerId];
                    const objIds = allowedStaffIds
                        .filter(id => id && mongoose.isValidObjectId(id))
                        .map(id => new mongoose.Types.ObjectId(id.toString()));
                    const strIds = allowedStaffIds.filter(Boolean).map(id => id.toString());
                    const allTargetStaffIds = [...new Set([...objIds, ...strIds])];

                    staffScopeFilter = {
                        $or: [
                            { assignedStaffId: { $in: allTargetStaffIds } },
                            { assignedRecruiterId: { $in: allTargetStaffIds } }
                        ]
                    };
                }
            }

            const andConditions = [];
            if (Object.keys(stageFilter).length > 0) andConditions.push(stageFilter);
            if (Object.keys(searchFilter).length > 0) andConditions.push(searchFilter);
            if (staffScopeFilter) andConditions.push(staffScopeFilter);

            let filter = {};
            if (andConditions.length === 1) {
                filter = andConditions[0];
            } else if (andConditions.length > 1) {
                filter = { $and: andConditions };
            }

            const applicants = await applicantModel.find(filter).sort({ createdAt: -1 }).lean();

            // Populate accurate applied role & department for applicants
            for (let a of applicants) {
                if (!a.targetRole && (a.convertedStaffId || a.stage === 'PROMOTED')) {
                    const s = await staffModel.findOne({
                        $or: [
                            ...(a.convertedStaffId ? [{ _id: a.convertedStaffId }] : []),
                            { applicantId: a._id },
                            ...(a.emailAddress ? [{ emailAddress: a.emailAddress }] : [])
                        ]
                    }).select('role deparment departmentId').populate('roleId departmentId').lean();

                    if (s) {
                        a.targetRole = s.role || s.roleId?.name || a.targetRole;
                        a.targetDepartment = s.deparment || s.departmentId?.name || a.targetDepartment;
                    }
                }

                const resolvedRole = a.targetRole ||
                    a.walkInForm?.appliedPosition ||
                    a.walkInForm?.positionApplied ||
                    a.walkInForm?.position ||
                    a.appliedPosition ||
                    a.appliedRole ||
                    a.role ||
                    null;

                const resolvedDept = a.targetDepartment ||
                    a.deparment ||
                    a.walkInForm?.department ||
                    null;

                a.role = resolvedRole;
                a.targetRole = resolvedRole;
                a.deparment = resolvedDept;
                a.targetDepartment = resolvedDept;
            }

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

            if (targetStage === 'PROMOTED') {
                return applicantController.approveApplicant(req, res);
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

    assignApplicant: async (req, res) => {
        try {
            const { id } = req.params;
            const { staffId, staffName } = req.body;
            const applicant = await findApplicantByIdOrCustomId(id);
            if (!applicant) {
                return res.status(404).send({ status: 404, message: "Applicant not found", data: {} });
            }

            let resolvedStaffName = staffName || null;
            if (staffId && !resolvedStaffName) {
                const s = await staffModel.findById(staffId).select('name fullName');
                if (s) resolvedStaffName = s.fullName || s.name;
            }

            applicant.assignedRecruiterId = staffId || null;
            applicant.assignedStaffId = staffId || null;
            applicant.assignedStaffName = resolvedStaffName;
            await applicant.save();

            // CRITICAL SYNC: If this applicant has already been converted or promoted to staff,
            // automatically sync their assigned supervisor (assignedDirector) on the staff page too!
            try {
                const staffLookup = [];
                if (applicant.convertedStaffId && mongoose.Types.ObjectId.isValid(applicant.convertedStaffId)) {
                    staffLookup.push({ _id: applicant.convertedStaffId });
                }
                if (applicant._id) {
                    staffLookup.push({ applicantId: applicant._id });
                }
                if (applicant.emailAddress && applicant.emailAddress.trim().length > 0) {
                    staffLookup.push({ emailAddress: applicant.emailAddress.toLowerCase().trim() });
                }
                if (applicant.mobileNumber) {
                    const cleanM = parseInt(String(applicant.mobileNumber).replace(/\D/g, '').slice(-10), 10);
                    if (cleanM) staffLookup.push({ mobileNumber: cleanM });
                }

                if (staffLookup.length > 0) {
                    const supervisorObjId = (staffId && mongoose.Types.ObjectId.isValid(staffId))
                        ? new mongoose.Types.ObjectId(staffId)
                        : null;
                    await staffModel.updateMany(
                        { $or: staffLookup },
                        {
                            $set: {
                                assignedDirector: supervisorObjId,
                                assignedDirectorName: resolvedStaffName || null
                            }
                        }
                    );
                }
            } catch (syncErr) {
                console.warn('[assignApplicant] Staff supervisor sync warning:', syncErr.message);
            }

            return res.status(200).send({
                status: 200,
                message: "Applicant assigned successfully and synced to staff record",
                data: { applicant }
            });
        } catch (error) {
            console.error("[assignApplicant Error]:", error);
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    deleteApplicant: async (req, res) => {
        try {
            const { id } = req.params;

            // Check permission: Admin or recruitment.delete / staff.delete_applicant / staff.delete
            const callerId = req.user?._id || req.user?.userId || req.user?.id;
            const callerRole = (req.user?.role || req.user?.userType || '').toLowerCase();
            const isAdmin = callerRole === 'admin' || callerRole === 'super_admin';

            if (!isAdmin && callerId) {
                const staffMember = await staffModel.findById(callerId)
                    .populate({
                        path: 'roleId',
                        populate: { path: 'permissionGroups' }
                    }).lean();

                if (staffMember) {
                    let hasDeletePerm = false;
                    const groups = staffMember.roleId?.permissionGroups || [];
                    for (const group of groups) {
                        for (const perm of (group.permissions || [])) {
                            const actions = (perm.actions || []).map(a => a.toLowerCase());
                            if (actions.includes('*') || actions.includes('all') ||
                                actions.includes('recruitment.delete') ||
                                actions.includes('staff.delete_applicant') ||
                                actions.includes('staff.delete')) {
                                hasDeletePerm = true;
                                break;
                            }
                        }
                        if (hasDeletePerm) break;
                    }

                    if (!hasDeletePerm) {
                        return res.status(403).send({
                            status: 403,
                            message: "Access denied. You do not have permission to delete job applicants.",
                            data: {}
                        });
                    }
                }
            }

            const applicant = await findApplicantByIdOrCustomId(id);
            if (!applicant) {
                return res.status(404).send({ status: 404, message: "Applicant not found", data: {} });
            }

            await applicantModel.findByIdAndDelete(applicant._id);

            return res.status(200).send({
                status: 200,
                message: "Applicant deleted successfully"
            });
        } catch (error) {
            console.error("[deleteApplicant Error]:", error);
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

            const applicant = await findApplicantByIdOrCustomId(id, true);
            if (!applicant) {
                return res.status(404).send({ status: 404, message: "Applicant record not found", data: {} });
            }

            const cleanMobile = applicant.mobileNumber
                ? parseInt(String(applicant.mobileNumber).replace(/\D/g, '').slice(-10), 10)
                : (applicant.phone ? parseInt(String(applicant.phone).replace(/\D/g, '').slice(-10), 10) : null);

            if (!cleanMobile) {
                return res.status(400).send({
                    status: 400,
                    message: "Cannot promote applicant: Valid 10-digit Mobile Number is required to create a staff account. Please update the applicant record.",
                    data: {}
                });
            }

            const effectiveFullName = (applicant.fullName && applicant.fullName.trim().length > 0)
                ? applicant.fullName.trim()
                : (applicant.firstName ? `${applicant.firstName} ${applicant.lastName || ''}`.trim() : (applicant.emailAddress ? applicant.emailAddress.split('@')[0] : 'Staff Member'));

            // Priority for supervisor / reporting authority:
            // 1. Explicitly passed in req.body (assignedDirector || supervisorId || reportingTo)
            // 2. Previously assigned on the job applicant page (applicant.assignedStaffId || applicant.assignedRecruiterId)
            // 3. The staff member currently performing the promotion (req.user), if they are not system admin
            let candidateSupervisorId = assignedDirector || supervisorId || reportingTo || null;
            let candidateSupervisorName = assignedDirectorName || supervisorName || null;

            if (!candidateSupervisorId || candidateSupervisorId === 'unassigned') {
                if (applicant.assignedStaffId || applicant.assignedRecruiterId) {
                    candidateSupervisorId = (applicant.assignedStaffId || applicant.assignedRecruiterId).toString();
                    candidateSupervisorName = applicant.assignedStaffName || null;
                } else if (req.user?._id && req.user?.role !== 'Admin' && req.user?.role !== 'admin' && req.user?.userType !== 'admin') {
                    candidateSupervisorId = req.user._id.toString();
                    candidateSupervisorName = req.user.fullName || req.user.name || null;
                }
            }

            if (candidateSupervisorId && !candidateSupervisorName && mongoose.Types.ObjectId.isValid(candidateSupervisorId)) {
                try {
                    const supervisor = await staffModel.findById(candidateSupervisorId).select('fullName name');
                    if (supervisor) {
                        candidateSupervisorName = supervisor.fullName || supervisor.name;
                    }
                } catch (_) {}
            }

            const isDirectAdmin = candidateSupervisorId === 'admin' || candidateSupervisorName === 'Admin';
            let finalSupervisorId = null;
            let finalSupervisorName = null;

            if (isDirectAdmin) {
                finalSupervisorName = 'Admin';
            } else if (candidateSupervisorId && candidateSupervisorId !== 'unassigned') {
                if (mongoose.Types.ObjectId.isValid(candidateSupervisorId)) {
                    finalSupervisorId = new mongoose.Types.ObjectId(candidateSupervisorId);
                    finalSupervisorName = candidateSupervisorName;
                } else if (candidateSupervisorName && candidateSupervisorName.trim().length > 0) {
                    finalSupervisorName = candidateSupervisorName.trim();
                }
            }

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

            // Check if already an employee in staffModel (safely without querying null values)
            const lookupConditions = [{ applicantId: applicant._id }];
            if (applicant.convertedStaffId && mongoose.Types.ObjectId.isValid(applicant.convertedStaffId)) {
                lookupConditions.push({ _id: applicant.convertedStaffId });
            }
            if (applicant.emailAddress && String(applicant.emailAddress).trim().length > 0) {
                lookupConditions.push({ emailAddress: applicant.emailAddress.toLowerCase().trim() });
            }
            if (cleanMobile) {
                lookupConditions.push({ mobileNumber: cleanMobile });
            }
            let staff = await staffModel.findOne({ $or: lookupConditions });

            const effectiveMpin = mpin ? mpin.toString().trim() : '0000';

            if (!staff) {
                // Generate a unique staff ID
                const count = await staffModel.countDocuments();
                const staffId = `STF${String(count + 1).padStart(3, '0')}${Math.floor(1000 + Math.random() * 9000)}`;

                staff = await staffModel.create({
                    applicantId: applicant._id,
                    staffId,
                    fullName: effectiveFullName,
                    emailAddress: applicant.emailAddress ? applicant.emailAddress.toLowerCase().trim() : '',
                    password: applicant.plainPassword || applicant.password || null,
                    plainPassword: applicant.plainPassword || applicant.password || null,
                    mobileNumber: cleanMobile,
                    countryCode: applicant.countryCode || "+91",
                    dob: applicant.dob,
                    gender: applicant.gender,
                    currentAddress: applicant.currentAddress || applicant.localAddress,
                    permanentAddress: applicant.permanentAddress,
                    emergencyContact: applicant.emergencyContact,
                    photoUrl: applicant.photoUrl,
                    resumeUrl: applicant.resumeUrl,
                    aadhaarUrl: applicant.aadhaarUrl || applicant.proofOfAddressUrl,
                    aadhaarBackUrl: applicant.aadhaarBackUrl,
                    aadhaarNumber: applicant.aadhaarNumber,
                    panUrl: applicant.panUrl,
                    panNumber: applicant.panNumber,
                    nismUrl: applicant.nismUrl || applicant.certDocumentUrl,
                    highestEducationUrl: applicant.highestEducationUrl,
                    kycVideoUrl: applicant.kycVideoUrl,
                    experienceYears: applicant.experienceYears || 0,
                    previousCompany: applicant.previousCompany,
                    lastCtc: applicant.lastCtc,
                    joiningDate: joiningDate ? new Date(joiningDate) : new Date(),
                    status: 'Active',
                    stage: 'Employee',
                    roleId: resolved.roleId,
                    role: resolved.roleName,
                    departmentId: resolved.departmentId,
                    deparment: resolved.departmentName,
                    mpin: effectiveMpin,
                    assignedDirector: finalSupervisorId,
                    assignedDirectorName: finalSupervisorName,
                    isViewOnly: isViewOnly === true || isViewOnly === 'true',
                    isEmailVerified: applicant.isEmailVerified || false,
                    isMobileVerified: applicant.isMobileVerified || false,
                    onboardingStatus: applicant.onboardingStatus || (applicant.kycVideoUrl ? 'VERIFIED' : (applicant.photoUrl && applicant.resumeUrl && applicant.aadhaarUrl ? 'DOCUMENTS_UPLOADED' : 'PENDING')),
                    walkInForm: applicant.walkInForm || {},
                    agreementStatus: 'PENDING_SIGNATURE'
                });
            } else {
                // Update existing staff record
                staff.applicantId = applicant._id;
                staff.fullName = effectiveFullName;
                if (cleanMobile) staff.mobileNumber = cleanMobile;
                if (applicant.aadhaarUrl || applicant.proofOfAddressUrl) staff.aadhaarUrl = applicant.aadhaarUrl || applicant.proofOfAddressUrl;
                if (applicant.aadhaarBackUrl) staff.aadhaarBackUrl = applicant.aadhaarBackUrl;
                if (applicant.aadhaarNumber) staff.aadhaarNumber = applicant.aadhaarNumber;
                if (applicant.panUrl) staff.panUrl = applicant.panUrl;
                if (applicant.panNumber) staff.panNumber = applicant.panNumber;
                if (applicant.photoUrl) staff.photoUrl = applicant.photoUrl;
                if (applicant.resumeUrl) staff.resumeUrl = applicant.resumeUrl;
                if (applicant.nismUrl || applicant.certDocumentUrl) staff.nismUrl = applicant.nismUrl || applicant.certDocumentUrl;
                if (applicant.highestEducationUrl) staff.highestEducationUrl = applicant.highestEducationUrl;
                if (applicant.kycVideoUrl) staff.kycVideoUrl = applicant.kycVideoUrl;
                if (applicant.currentAddress) staff.currentAddress = applicant.currentAddress;
                if (applicant.permanentAddress) staff.permanentAddress = applicant.permanentAddress;
                if (applicant.emergencyContact) staff.emergencyContact = applicant.emergencyContact;
                if (applicant.emailAddress) staff.emailAddress = applicant.emailAddress.toLowerCase().trim();
                if (applicant.plainPassword || applicant.password) {
                    staff.password = applicant.plainPassword || applicant.password;
                    staff.plainPassword = applicant.plainPassword || applicant.password;
                }
                if (resolved.roleId) staff.roleId = resolved.roleId;
                if (resolved.roleName) staff.role = resolved.roleName;
                if (resolved.departmentId) staff.departmentId = resolved.departmentId;
                if (resolved.departmentName) staff.deparment = resolved.departmentName;
                if (mpin) staff.mpin = effectiveMpin;
                staff.joiningDate = joiningDate ? new Date(joiningDate) : (staff.joiningDate || new Date());
                staff.status = 'Active';
                staff.stage = 'Employee';
                if (applicant.isEmailVerified !== undefined) staff.isEmailVerified = applicant.isEmailVerified;
                if (applicant.isMobileVerified !== undefined) staff.isMobileVerified = applicant.isMobileVerified;
                if (applicant.onboardingStatus) staff.onboardingStatus = applicant.onboardingStatus;
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
            applicant.targetRole = resolved.roleName || staff.role;
            applicant.targetDepartment = resolved.departmentName || staff.deparment;
            applicant.targetRoleId = resolved.roleId || staff.roleId;
            applicant.hiredAt = new Date();
            const changedByUserId = (req.user?._id && mongoose.Types.ObjectId.isValid(req.user._id)) ? req.user._id : null;
            applicant.stageHistory.push({
                stage: 'PROMOTED',
                note: note || `Applicant promoted to Staff (Staff ID: ${staff.staffId})`,
                changedBy: changedByUserId,
                changedAt: new Date()
            });
            if (finalSupervisorId && !applicant.assignedStaffId) {
                applicant.assignedStaffId = finalSupervisorId;
                applicant.assignedStaffName = finalSupervisorName;
            }
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

            // Staff Scoping: If caller is staff (and not super admin), verify assignment
            const callerId = req.user?._id || req.user?.userId || req.user?.id;
            if (callerId) {
                const callerStaff = await staffModel.findById(callerId).lean();
                if (callerStaff) {
                    const hierarchy = await getSupervisedStaffIds(callerId);
                    if (!hierarchy.isSystemAdmin) {
                        const allowedStaffIds = (hierarchy.staffIds || [callerId]).map(i => i.toString());
                        const assignedStaff = applicant.assignedStaffId ? applicant.assignedStaffId.toString() : null;
                        const assignedRecruiter = applicant.assignedRecruiterId ? applicant.assignedRecruiterId.toString() : null;
                        const hasAccess = (assignedStaff && allowedStaffIds.includes(assignedStaff)) ||
                                          (assignedRecruiter && allowedStaffIds.includes(assignedRecruiter));
                        if (!hasAccess) {
                            return res.status(403).send({
                                status: 403,
                                message: "Access denied. This applicant is not assigned to you.",
                                data: {}
                            });
                        }
                    }
                }
            }

            const data = applicant.toObject();
            delete data.emailOtp;
            delete data.emailOtpExpires;
            delete data.mobileOtp;
            delete data.mobileOtpExpires;
            if (!data.plainPassword && data.password && !data.password.startsWith('$2a$') && !data.password.startsWith('$2b$')) {
                data.plainPassword = data.password;
            }
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
    },

    previewOfferLetter: async (req, res) => {
        try {
            const { id } = req.params;
            const applicant = await findApplicantByIdOrCustomId(id);
            if (!applicant) {
                return res.status(404).send({ status: 404, message: "Applicant not found", data: {} });
            }

            const options = {
                designation: req.query.designation || req.body?.designation,
                joiningDate: req.query.joiningDate || req.body?.joiningDate,
                issueDate: req.query.issueDate || req.body?.issueDate
            };

            const result = await offerLetterService.generateOfferLetterPdf(applicant, options);

            if (req.query.format === 'json') {
                return res.status(200).send({
                    status: 200,
                    success: true,
                    data: {
                        fileName: result.fileName,
                        candidateName: result.candidateName,
                        email: result.email,
                        designation: result.designation,
                        joiningDate: result.joiningDate,
                        issueDate: result.issueDate,
                        pdfBase64: result.pdfBytes.toString('base64')
                    }
                });
            }

            res.setHeader('Content-Type', 'application/pdf');
            res.setHeader('Content-Disposition', `inline; filename="${result.fileName}"`);
            res.setHeader('Content-Length', result.pdfBytes.length);
            return res.status(200).send(result.pdfBytes);
        } catch (error) {
            console.error("[previewOfferLetter Error]:", error);
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    sendOfferLetter: async (req, res) => {
        try {
            const { id } = req.params;
            const applicant = await findApplicantByIdOrCustomId(id);
            if (!applicant) {
                return res.status(404).send({ status: 404, message: "Applicant not found", data: {} });
            }

            if (!applicant.emailAddress) {
                return res.status(400).send({ status: 400, message: "Applicant does not have a registered email address to receive the offer letter", data: {} });
            }

            const { designation, joiningDate, issueDate, customNote } = req.body;
            const options = { designation, joiningDate, issueDate };

            // 1. Generate filled PDF
            const result = await offerLetterService.generateOfferLetterPdf(applicant, options);

            // 2. Save PDF to uploads folder
            const saveResult = await offerLetterService.saveOfferLetterPdf(applicant._id, result.pdfBytes, result.fileName);

            // 3. Send email to candidate
            const emailResult = await offerLetterService.sendOfferLetterEmail({
                applicant,
                pdfBuffer: result.pdfBytes,
                designation: result.designation,
                joiningDate: result.joiningDate,
                fileName: result.fileName
            });

            // 4. Update applicant stage and history
            const previousStage = applicant.stage;
            applicant.stage = 'OFFER_SENT';
            applicant.offerLetterUrl = saveResult.relativeUrl;
            applicant.offerLetterSentAt = new Date();
            applicant.offerLetterSentBy = req.user?._id || req.staff?._id || null;
            applicant.offerLetterDesignation = result.designation;
            applicant.offerLetterJoiningDate = result.joiningDate;

            if (!applicant.stageHistory) {
                applicant.stageHistory = [];
            }
            applicant.stageHistory.push({
                stage: 'OFFER_SENT',
                note: customNote || `Offer letter issued for position "${result.designation}" (Joining: ${result.joiningDate}). Email ${emailResult.success ? 'dispatched successfully' : 'dispatch failed: ' + (emailResult.error || '')}`,
                changedBy: req.user?._id || null,
                changedAt: new Date()
            });

            await applicant.save();

            res.status(200).send({
                status: 200,
                success: true,
                message: `Offer letter successfully generated and sent to ${applicant.emailAddress}!`,
                data: {
                    offerLetterUrl: saveResult.relativeUrl,
                    fileName: result.fileName,
                    emailSent: emailResult.success,
                    emailError: emailResult.error || null,
                    applicant: {
                        _id: applicant._id,
                        applicantId: applicant.applicantId,
                        fullName: applicant.fullName,
                        emailAddress: applicant.emailAddress,
                        stage: applicant.stage,
                        offerLetterUrl: applicant.offerLetterUrl,
                        offerLetterSentAt: applicant.offerLetterSentAt,
                        offerLetterDesignation: applicant.offerLetterDesignation,
                        offerLetterJoiningDate: applicant.offerLetterJoiningDate
                    }
                }
            });
        } catch (error) {
            console.error("[sendOfferLetter Error]:", error);
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    downloadOfferLetter: async (req, res) => {
        try {
            const { id } = req.params;
            const applicant = await findApplicantByIdOrCustomId(id);
            if (!applicant) {
                return res.status(404).send({ status: 404, message: "Applicant not found", data: {} });
            }

            let pdfBytes = null;
            let fileName = `Offer_Letter_${(applicant.fullName || 'Candidate').replace(/[^a-zA-Z0-9]/g, '_')}.pdf`;

            if (applicant.offerLetterUrl) {
                const localPath = path.join(__dirname, '..', applicant.offerLetterUrl);
                if (fs.existsSync(localPath)) {
                    pdfBytes = fs.readFileSync(localPath);
                }
            }

            if (!pdfBytes) {
                const options = {
                    designation: applicant.offerLetterDesignation || applicant.targetRole,
                    joiningDate: applicant.offerLetterJoiningDate
                };
                const generated = await offerLetterService.generateOfferLetterPdf(applicant, options);
                pdfBytes = generated.pdfBytes;
                fileName = generated.fileName;
            }

            res.setHeader('Content-Type', 'application/pdf');
            res.setHeader('Content-Disposition', `attachment; filename="${fileName}"`);
            res.setHeader('Content-Length', pdfBytes.length);
            return res.status(200).send(pdfBytes);
        } catch (error) {
            console.error("[downloadOfferLetter Error]:", error);
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    }
};

export default applicantController;
