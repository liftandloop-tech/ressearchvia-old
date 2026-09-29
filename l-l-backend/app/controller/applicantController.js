import staffModel from "../models/staffModel.js";
import emailService from "../services/emailService.js";
import axios from "axios";
import { resolveRoleAndDepartment } from "../services/staffService.js";
import roleModel from "../models/roleModel.js";

const generateOtp = () => Math.floor(1000 + Math.random() * 9000);

/**
 * Normalizes a phone number to 91XXXXXXXXXX (12 digits, prefixed with 91).
 * Validates that the input is either 10 digits or 12 digits containing 91.
 * Returns { valid: boolean, normalized12: string, numeric12: number, last10: string }
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
    } else if (digits.length > 10 && digits.slice(-12).startsWith('91')) {
        last10 = digits.slice(-10);
        normalized12 = digits.slice(-12);
    } else if (digits.length > 10) {
        last10 = digits.slice(-10);
        normalized12 = `91${last10}`;
    } else {
        return { valid: false, normalized12: '', numeric12: 0, last10: '' };
    }

    const numeric12 = parseInt(normalized12);
    const valid = normalized12.length === 12 && normalized12.startsWith('91') && !isNaN(numeric12);
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
        if (!valid) {
            console.error(`[SMS Gateway] Invalid phone number provided for OTP (must be 10 or 12 digits containing 91): ${phone}`);
            return false;
        }

        const defaultTemplate = "Your OTP for ResearchVia App is {OTP}\n\n\n\nPlease do not share OTP with anyone.\n\nhttps://researchvia.in\n\n";
        const messageText = defaultTemplate.replaceAll('{OTP}', otp);
        const message = encodeURIComponent(messageText);
        const smsUrl = `${url}username=${username}&apikey=${apikey}&apirequest=Text&sender=${sender}&mobile=${normalized12}&message=${message}sms&route=TRANS&TemplateID=${templateID}&format=JSON`;

        console.log(`[SMS Gateway] Sending mobile OTP to ${normalized12}`);
        const response = await axios.get(smsUrl, { timeout: 10000 });
        console.log(`[SMS Gateway] Response for ${normalized12}:`, response.data);
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
        console.log(`[Email Gateway] Response for ${cleanEmail}:`, result);
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

            const normalizedPhone = phoneInfo.numeric12; // 91XXXXXXXXXX as Number
            const last10 = phoneInfo.last10;
            const cleanEmail = emailAddress ? emailAddress.trim().toLowerCase() : '';

            let roleDoc = null;
            if (appliedRoleId) {
                roleDoc = await roleModel.findById(appliedRoleId);
            } else if (req.body.walkInForm?.appliedPosition) {
                roleDoc = await roleModel.findOne({ name: { $regex: new RegExp(`^${req.body.walkInForm.appliedPosition.trim()}$`, 'i') } });
            }

            let applicant = await staffModel.findOne({
                $or: [
                    { mobileNumber: normalizedPhone },
                    { mobileNumber: phoneInfo.normalized12 },
                    { mobileNumber: parseInt(last10) },
                    { mobileNumber: last10 },
                    { mobileNumber: `+91${last10}` },
                    { emailAddress: { $regex: new RegExp(`^${cleanEmail.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&')}$`, 'i') } }
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
                applicant.mobileNumber = normalizedPhone;
                applicant.emailAddress = cleanEmail;
                applicant.dob = dob ? new Date(dob) : null;
                applicant.gender = gender;
                applicant.currentAddress = currentAddress;
                applicant.permanentAddress = permanentAddress;
                applicant.emergencyContact = emergencyContact;
                applicant.experienceYears = experienceYears;
                applicant.previousCompany = previousCompany;
                applicant.lastCtc = lastCtc;
                if (roleDoc) {
                    applicant.roleId = roleDoc._id;
                    applicant.role = roleDoc.name;
                    if (roleDoc.departmentId) applicant.departmentId = roleDoc.departmentId;
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
                applicant.stage = 'Applicant';
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
                    mobileNumber: normalizedPhone,
                    emailAddress: cleanEmail,
                    dob: dob ? new Date(dob) : null,
                    gender,
                    currentAddress,
                    permanentAddress,
                    emergencyContact,
                    experienceYears,
                    previousCompany,
                    lastCtc,
                    roleId: roleDoc ? roleDoc._id : null,
                    role: roleDoc ? roleDoc.name : (req.body.walkInForm?.appliedPosition || null),
                    departmentId: roleDoc?.departmentId ? roleDoc.departmentId : null,
                    walkInForm: req.body.walkInForm || {},
                    stage: 'Applicant',
                    mobileOtp,
                    mobileOtpExpires: expiry,
                    emailOtp,
                    emailOtpExpires: expiry
                });
            }

            // Send out OTPs
            await sendMobileOtp(phoneInfo.normalized12, mobileOtp);
            await sendEmailOtp(cleanEmail, emailOtp);

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

            const applicant = await staffModel.findById(id);
            if (!applicant || applicant.stage !== 'Applicant') {
                return res.status(404).send({ status: 404, message: "Applicant not found or already promoted", data: {} });
            }

            // Ensure unique staffId exists
            if (!applicant.staffId) {
                const count = await staffModel.countDocuments();
                const randomSuffix = Math.floor(1000 + Math.random() * 9000);
                applicant.staffId = `STF${String(count + 1).padStart(3, '0')}${randomSuffix}`;
            }

            const resolved = await resolveRoleAndDepartment({
                roleId,
                roleName: role,
                fallbackDept: deparment
            });

            // Promote to Employee
            applicant.stage = 'Employee';
            if (resolved.roleId) {
                applicant.roleId = resolved.roleId;
                applicant.role = resolved.roleName;
            }
            if (resolved.departmentId) {
                applicant.departmentId = resolved.departmentId;
                applicant.deparment = resolved.departmentName;
            } else if (deparment) {
                applicant.deparment = deparment;
            }
            applicant.mpin = mpin.toString().trim();
            applicant.joiningDate = joiningDate ? new Date(joiningDate) : new Date();
            applicant.status = 'Active';
            applicant.isViewOnly = isViewOnly === true || isViewOnly === 'true';

            // Resolve and assign Reporting Authority dynamically
            const isDirectAdmin = effectiveSupervisorId === 'admin' || effectiveSupervisorName === 'Admin';
            if (isDirectAdmin) {
                applicant.assignedDirector = null;
                applicant.assignedDirectorName = 'Admin';
            } else if (effectiveSupervisorId && effectiveSupervisorId !== 'unassigned') {
                applicant.assignedDirector = effectiveSupervisorId;
                if (effectiveSupervisorName && effectiveSupervisorName.trim().length > 0) {
                    applicant.assignedDirectorName = effectiveSupervisorName.trim();
                } else {
                    const supervisor = await staffModel.findById(effectiveSupervisorId).select('fullName');
                    applicant.assignedDirectorName = supervisor ? supervisor.fullName : null;
                }
            } else {
                applicant.assignedDirector = null;
                applicant.assignedDirectorName = null;
            }

            await applicant.save();

            const updatedStaff = await staffModel.findById(applicant._id)
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
                message: "Applicant approved and promoted to Employee",
                data: { staff: updatedStaff || applicant }
            });
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

            const cleanInput = identifier.trim();
            const isEmail = cleanInput.includes('@');
            let query = { stage: { $ne: 'Employee' } };

            if (isEmail) {
                const cleanEmail = cleanInput.toLowerCase();
                query.emailAddress = { $regex: new RegExp(`^${cleanEmail.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&')}$`, 'i') };
            } else {
                const cleanDigits = cleanInput.replace(/\D/g, '');
                const last10 = cleanDigits.slice(-10);
                const last10Num = parseInt(last10);
                const with91Num = parseInt("91" + last10);
                query.$or = [
                    { mobileNumber: last10Num },
                    { mobileNumber: with91Num },
                    { mobileNumber: last10 },
                    { mobileNumber: "91" + last10 },
                    { mobileNumber: "+91" + last10 }
                ];
            }

            const applicant = await staffModel.findOne(query);
            if (!applicant) {
                return res.status(400).send({ status: 400, message: "No such applicant found with this " + (isEmail ? "email" : "mobile number"), data: {} });
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

            const cleanInput = identifier.trim();
            const isEmail = cleanInput.includes('@');
            let query = { stage: { $ne: 'Employee' } };

            if (isEmail) {
                const cleanEmail = cleanInput.toLowerCase();
                query.emailAddress = { $regex: new RegExp(`^${cleanEmail.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&')}$`, 'i') };
            } else {
                const cleanDigits = cleanInput.replace(/\D/g, '');
                const last10 = cleanDigits.slice(-10);
                const last10Num = parseInt(last10);
                const with91Num = parseInt("91" + last10);
                query.$or = [
                    { mobileNumber: last10Num },
                    { mobileNumber: with91Num },
                    { mobileNumber: last10 },
                    { mobileNumber: "91" + last10 },
                    { mobileNumber: "+91" + last10 }
                ];
            }

            const applicant = await staffModel.findOne(query);
            if (!applicant) {
                return res.status(400).send({ status: 400, message: "Applicant not found", data: {} });
            }

            const submittedOtp = String(otp).trim();
            if (otpType === 'email') {
                if (String(applicant.emailOtp).trim() !== submittedOtp || applicant.emailOtpExpires < Date.now()) {
                    return res.status(400).send({ status: 400, message: "Invalid or expired email OTP", data: {} });
                }
                applicant.isEmailVerified = true;
                applicant.emailOtp = undefined;
            } else {
                if (String(applicant.mobileOtp).trim() !== submittedOtp || applicant.mobileOtpExpires < Date.now()) {
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
    },

    saveEvaluationRemarks: async (req, res) => {
        try {
            const { id } = req.params;
            const { recruiterRemarks, interviewerRemarks } = req.body;

            const applicant = await staffModel.findById(id);
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
