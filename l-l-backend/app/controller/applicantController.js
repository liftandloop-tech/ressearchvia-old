import applicantModel from "../models/applicantModel.js";
import staffModel from "../models/staffModel.js";
import emailService from "../services/emailService.js";
import axios from "axios";
import staffService, { resolveRoleAndDepartment } from "../services/staffService.js";
import roleModel from "../models/roleModel.js";

const generateOtp = () => Math.floor(1000 + Math.random() * 9000);

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
                const count = await applicantModel.countDocuments();
                const appSeq = `APP-${new Date().getFullYear()}-${String(count + 1).padStart(4, '0')}`;

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

            const applicant = await applicantModel.findById(id);
            if (!applicant) {
                return res.status(404).send({ status: 404, message: "Applicant not found", data: {} });
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

            const applicant = await applicantModel.findById(id);
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
                filter.stage = stage;
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
                reportingTo
            } = req.body;

            const effectiveSupervisorId = assignedDirector || supervisorId || reportingTo;
            const effectiveSupervisorName = assignedDirectorName || supervisorName;

            if ((!roleId && !role && !deparment) || !mpin) {
                return res.status(400).send({ status: 400, message: "Role and MPIN are required to approve staff", data: {} });
            }

            if (!effectiveSupervisorId && !effectiveSupervisorName) {
                return res.status(400).send({ status: 400, message: "Reporting authority (Supervisor or Direct Admin) is required to approve staff", data: {} });
            }

            const applicant = await applicantModel.findById(id);
            if (!applicant) {
                return res.status(404).send({ status: 404, message: "Applicant record not found", data: {} });
            }

            // Resolve role and department
            const resolved = await resolveRoleAndDepartment({
                roleId,
                roleName: role,
                fallbackDept: deparment
            });

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
                    if (supervisor && supervisor.status && supervisor.status.toLowerCase() !== 'active') {
                        return res.status(400).send({ status: 400, message: "Cannot assign an inactive supervisor to new staff", data: {} });
                    }
                    finalSupervisorName = supervisor ? supervisor.fullName : null;
                }
            }

            if (!staff) {
                // Generate a unique staff ID
                const count = await staffModel.countDocuments();
                const staffId = `STF${String(count + 1).padStart(3, '0')}${Math.floor(1000 + Math.random() * 9000)}`;

                staff = await staffModel.create({
                    applicantId: applicant._id,
                    staffId,
                    fullName: applicant.fullName,
                    emailAddress: applicant.emailAddress.toLowerCase(),
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
                    mpin: mpin.toString().trim(),
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
                staff.roleId = resolved.roleId;
                staff.role = resolved.roleName;
                staff.departmentId = resolved.departmentId;
                staff.deparment = resolved.departmentName;
                staff.mpin = mpin.toString().trim();
                staff.joiningDate = joiningDate ? new Date(joiningDate) : new Date();
                staff.status = 'Active';
                staff.assignedDirector = finalSupervisorId;
                staff.assignedDirectorName = finalSupervisorName;
                staff.isViewOnly = isViewOnly === true || isViewOnly === 'true';
                if (!staff.agreementStatus || staff.agreementStatus === 'NOT_INITIATED') {
                    staff.agreementStatus = 'PENDING_SIGNATURE';
                }
                await staff.save();
            }

            // Update applicant stage and link
            applicant.stage = 'OFFER_ACCEPTED';
            applicant.convertedStaffId = staff._id;
            applicant.hiredAt = new Date();
            applicant.stageHistory.push({
                stage: 'OFFER_ACCEPTED',
                note: `Applicant hired as ${resolved.roleName} (Staff ID: ${staff.staffId})`,
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
                message: "Applicant approved and hired as Staff successfully",
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
            const applicant = await applicantModel.findById(id);
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

            const applicant = await applicantModel.findById(id);
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
