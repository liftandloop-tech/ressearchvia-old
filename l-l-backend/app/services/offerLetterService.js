import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { PDFDocument, rgb, StandardFonts } from 'pdf-lib';
import emailService from './emailService.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function formatAddress(currentAddress, permanentAddress, currentLocation) {
    const formatObj = (addr) => {
        if (!addr) return '';
        if (typeof addr === 'string') return addr.trim();
        if (typeof addr === 'object') {
            const parts = [
                addr.addressLine1 || addr.line1 || addr.street,
                addr.addressLine2 || addr.line2,
                addr.city,
                addr.state,
                addr.pincode || addr.pinCode || addr.postalCode
            ].filter(Boolean);
            return parts.join(', ').trim();
        }
        return '';
    };

    const curr = formatObj(currentAddress);
    if (curr) return curr;
    const perm = formatObj(permanentAddress);
    if (perm) return perm;
    if (currentLocation) return String(currentLocation).trim();
    return '';
}

function splitIntoTwoLines(text, maxChars = 58) {
    if (!text || text.length <= maxChars) return [text || '', ''];
    const words = text.split(' ');
    let line1 = '';
    let line2 = '';
    for (const w of words) {
        if ((line1 + ' ' + w).trim().length <= maxChars) {
            line1 = (line1 + ' ' + w).trim();
        } else {
            line2 = (line2 + ' ' + w).trim();
        }
    }
    return [line1, line2];
}

const offerLetterService = {
    /**
     * Generates a filled Offer Letter PDF Buffer using the official company template.
     */
    generateOfferLetterPdf: async (applicant, options = {}) => {
        const templatePath = path.join(__dirname, '../serviceAgreement/offer_letter_template.pdf');
        if (!fs.existsSync(templatePath)) {
            throw new Error(`Offer letter template not found at ${templatePath}`);
        }

        const templateBytes = fs.readFileSync(templatePath);
        const pdfDoc = await PDFDocument.load(templateBytes);

        const fontBold = await pdfDoc.embedFont(StandardFonts.HelveticaBold);
        const fontRegular = await pdfDoc.embedFont(StandardFonts.Helvetica);
        const black = rgb(0.1, 0.1, 0.1);

        const candidateName = (
            applicant.fullName ||
            [applicant.firstName, applicant.lastName].filter(Boolean).join(' ') ||
            'Applicant'
        ).trim();

        const addressStr = formatAddress(applicant.currentAddress, applicant.permanentAddress, applicant.currentLocation);
        const [addrLine1, addrLine2] = splitIntoTwoLines(addressStr, 58);

        const mobile = applicant.mobileNumber ? `${applicant.countryCode || '+91'} ${applicant.mobileNumber}` : '';
        const email = applicant.emailAddress || '';
        const contactStr = [mobile, email].filter(Boolean).join(' | ');

        const designation = (
            options.designation ||
            applicant.targetRole ||
            applicant.currentDesignation ||
            'Business Development Executive'
        ).trim();

        const joiningDate = (
            options.joiningDate ||
            (applicant.joiningDate ? new Date(applicant.joiningDate).toLocaleDateString('en-GB') : null) ||
            new Date(Date.now() + 7 * 86400000).toLocaleDateString('en-GB')
        ).trim();

        const issueDate = (
            options.issueDate ||
            new Date().toLocaleDateString('en-GB')
        ).trim();

        const page = pdfDoc.getPage(0);

        // 1. DATE: at y = 643.54
        page.drawText(issueDate, {
            x: 460,
            y: 643.54,
            size: 10,
            font: fontRegular,
            color: black
        });

        // 2. Name: at y = 630.1
        page.drawText(candidateName, {
            x: 120,
            y: 630.1,
            size: 10,
            font: fontBold,
            color: black
        });

        // 3. Address: at y = 603.22
        if (addrLine2) {
            page.drawText(addrLine1, {
                x: 120,
                y: 603.22,
                size: 8.5,
                font: fontRegular,
                color: black
            });
            page.drawText(addrLine2, {
                x: 120,
                y: 591.22,
                size: 8.5,
                font: fontRegular,
                color: black
            });
        } else if (addrLine1) {
            page.drawText(addrLine1, {
                x: 120,
                y: 603.22,
                size: 9,
                font: fontRegular,
                color: black
            });
        }

        // 4. Contact: at y = 576.31
        if (contactStr) {
            page.drawText(contactStr, {
                x: 120,
                y: 576.31,
                size: 9.5,
                font: fontRegular,
                color: black
            });
        }

        // 5. Dear: at y = 528.07
        page.drawText(`${candidateName},`, {
            x: 102,
            y: 528.07,
            size: 10,
            font: fontBold,
            color: black
        });

        // 6. Congratulations and welcome to: at y = 505.51
        page.drawText("SP RESEARCHVIA PVT. LTD.", {
            x: 224,
            y: 505.51,
            size: 9.5,
            font: fontBold,
            color: black
        });

        // 7. We are pleased to offer you a position as ... commencing on ...: at y = 483.07
        const defaultSize = 9.5;
        const maxRoleW = 86;
        const actualW = fontBold.widthOfTextAtSize(designation, defaultSize);
        const roleSize = actualW > maxRoleW ? Math.max(6.5, (maxRoleW / actualW) * defaultSize) : defaultSize;
        page.drawText(designation, {
            x: 258,
            y: 483.07,
            size: roleSize,
            font: fontBold,
            color: black
        });

        page.drawText(joiningDate, {
            x: 422,
            y: 483.07,
            size: 9,
            font: fontRegular,
            color: black
        });

        // 8. Designation : at y = 343.25
        page.drawText(designation, {
            x: 150,
            y: 343.25,
            size: 10,
            font: fontBold,
            color: black
        });

        // 9. Date of joining : at y = 320.69
        page.drawText(joiningDate, {
            x: 150,
            y: 320.69,
            size: 10,
            font: fontRegular,
            color: black
        });

        // 10. For: at y = 275.69
        page.drawText("SP RESEARCHVIA PVT. LTD.", {
            x: 95,
            y: 275.69,
            size: 10,
            font: fontBold,
            color: black
        });

        // Signatory placeholder
        page.drawText("Authorized Signatory", {
            x: 72,
            y: 220,
            size: 9.5,
            font: fontRegular,
            color: black
        });

        const pdfBytes = await pdfDoc.save();
        const safeName = candidateName.replace(/[^a-zA-Z0-9]/g, '_');
        return {
            pdfBytes: Buffer.from(pdfBytes),
            candidateName,
            email: applicant.emailAddress,
            designation,
            joiningDate,
            issueDate,
            fileName: `Offer_Letter_${safeName}.pdf`
        };
    },

    /**
     * Saves generated PDF to local uploads folder and returns public relative URL.
     */
    saveOfferLetterPdf: async (applicantId, pdfBuffer, fileName) => {
        const uploadDir = path.join(__dirname, '../uploads/offer_letters');
        if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
        }

        const safeFileName = fileName || `offer_letter_${applicantId}_${Date.now()}.pdf`;
        const diskFileName = `offer_${applicantId}_${Date.now()}.pdf`;
        const filePath = path.join(uploadDir, diskFileName);

        fs.writeFileSync(filePath, pdfBuffer);

        return {
            filePath,
            fileName: safeFileName,
            diskFileName,
            relativeUrl: `uploads/offer_letters/${diskFileName}`
        };
    },

    /**
     * Sends branded offer letter email to applicant with PDF attachment.
     */
    sendOfferLetterEmail: async ({ applicant, pdfBuffer, designation, joiningDate, fileName }) => {
        const candidateName = (
            applicant.fullName ||
            [applicant.firstName, applicant.lastName].filter(Boolean).join(' ') ||
            'Candidate'
        ).trim();

        const subject = `Job Offer: Appointment Letter - SP RESEARCHVIA PVT. LTD.`;

        const bodyHtml = `
            <div style="font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif;color:#1e293b;line-height:1.6;">
                <h2 style="color:#163174;margin-top:0;font-size:22px;border-bottom:2px solid #e2e8f0;padding-bottom:10px;">
                    Offer-cum-Appointment Letter
                </h2>
                <p style="font-size:15px;">Dear <strong>${candidateName}</strong>,</p>
                <p style="font-size:14px;color:#334155;">
                    Congratulations! Following your recent interview and selection process, we are delighted to offer you the position of 
                    <strong style="color:#163174;">${designation}</strong> at <strong>SP RESEARCHVIA PVT. LTD.</strong>
                </p>
                
                <div style="background:#f8fafc;border:1px solid #cbd5e1;border-radius:8px;padding:16px 20px;margin:20px 0;">
                    <table style="width:100%;font-size:14px;border-collapse:collapse;">
                        <tr>
                            <td style="padding:6px 0;color:#64748b;width:140px;">Position / Role:</td>
                            <td style="padding:6px 0;font-weight:600;color:#0f172a;">${designation}</td>
                        </tr>
                        <tr>
                            <td style="padding:6px 0;color:#64748b;">Date of Joining:</td>
                            <td style="padding:6px 0;font-weight:600;color:#16a34a;">${joiningDate}</td>
                        </tr>
                        <tr>
                            <td style="padding:6px 0;color:#64748b;">Company:</td>
                            <td style="padding:6px 0;font-weight:600;color:#0f172a;">SP RESEARCHVIA PVT. LTD.</td>
                        </tr>
                    </table>
                </div>

                <p style="font-size:14px;color:#334155;">
                    Please find your official <strong>Offer-cum-Appointment Letter</strong> attached to this email as a PDF document. 
                    Kindly review the terms and conditions outlined in the letter.
                </p>
                
                <p style="font-size:14px;color:#334155;">
                    We look forward to welcoming you to our team! If you have any questions or require any assistance prior to your joining date, please feel free to reach out to HR.
                </p>

                <p style="margin-top:28px;font-size:13px;color:#475569;">
                    Warm regards,<br/>
                    <strong style="color:#163174;font-size:14px;">Human Resources Team</strong><br/>
                    SP RESEARCHVIA PVT. LTD.<br/>
                    <a href="mailto:info@researchvia.in" style="color:#2563eb;text-decoration:none;">info@researchvia.in</a>
                </p>
            </div>
        `;

        const attachmentName = fileName || `Offer_Letter_${candidateName.replace(/[^a-zA-Z0-9]/g, '_')}.pdf`;

        return await emailService.sendEmail({
            to: applicant.emailAddress,
            subject,
            htmlContent: bodyHtml,
            title: 'SP RESEARCHVIA',
            attachments: [
                {
                    filename: attachmentName,
                    content: pdfBuffer,
                    contentType: 'application/pdf'
                }
            ]
        });
    }
};

export default offerLetterService;
