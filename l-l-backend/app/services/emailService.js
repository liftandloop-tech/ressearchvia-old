import nodemailer from 'nodemailer';

const emailUser = (process.env.EMAIL_USER || 'support@futurepride.in').replace(/^["']|["']$/g, '');
const emailPass = (process.env.EMAIL_PASS || 'Futurepride@2026').replace(/^["']|["']$/g, '');

const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST || 'smtp.hostinger.com',
    port: Number(process.env.SMTP_PORT) || 465,
    secure: process.env.SMTP_SECURE === 'false' ? false : true, // true for 465, false for other ports
    connectionTimeout: 10000,
    greetingTimeout: 10000,
    socketTimeout: 15000,
    auth: {
        user: emailUser,
        pass: emailPass
    }
});

/**
 * Standard branded Future Pride HTML email wrapper
 */
const htmlTemplate = (content, title = 'FUTURE PRIDE') => `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${title}</title>
    <style>
        body { font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, Roboto, Helvetica, Arial, sans-serif; background-color: #f1f5f9; margin: 0; padding: 24px 12px; -webkit-font-smoothing: antialiased; }
        .container { max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 16px rgba(15, 23, 42, 0.08); border: 1px solid #e2e8f0; }
        .header { background: linear-gradient(135deg, #163174 0%, #0d1e48 100%); padding: 28px 24px; text-align: center; color: #ffffff; }
        .brand-title { margin: 0; font-size: 24px; font-weight: 800; letter-spacing: 1.5px; text-transform: uppercase; color: #ffffff; }
        .brand-subtitle { margin: 6px 0 0 0; font-size: 12px; color: #cbd5e1; text-transform: uppercase; letter-spacing: 2px; }
        .content { padding: 32px 28px; color: #334155; line-height: 1.65; font-size: 15px; }
        .footer { background-color: #f8fafc; padding: 24px; text-align: center; font-size: 12px; color: #64748b; border-top: 1px solid #e2e8f0; }
        .footer p { margin: 4px 0; }
        .footer a { color: #163174; text-decoration: none; font-weight: 600; }
        .button { display: inline-block; padding: 12px 28px; background-color: #163174; color: #ffffff !important; text-decoration: none; border-radius: 6px; font-weight: 700; font-size: 14px; letter-spacing: 0.5px; margin-top: 16px; }
        .otp-box { text-align: center; margin: 24px 0; padding: 20px; background: #f8fafc; border: 2px dashed #163174; border-radius: 8px; }
        .otp-code { font-family: 'Courier New', Courier, monospace; font-size: 36px; font-weight: 800; letter-spacing: 8px; color: #163174; display: inline-block; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1 class="brand-title">${title}</h1>
            <p class="brand-subtitle">Wealth Management &amp; Research</p>
        </div>
        <div class="content">
            ${content}
        </div>
        <div class="footer">
            <p>&copy; ${new Date().getFullYear()} <strong>Future Pride</strong>. All rights reserved.</p>
            <p>Support: <a href="mailto:support@futurepride.in">support@futurepride.in</a> | Website: <a href="https://futurepride.in">futurepride.in</a></p>
        </div>
    </div>
</body>
</html>
`;

const emailService = {
    /**
     * Send general branded email
     */
    sendEmail: async ({ to, subject, htmlContent, title = 'FUTURE PRIDE', attachments = [] }) => {
        try {
            const isFullHtml = typeof htmlContent === 'string' && (htmlContent.includes('<!DOCTYPE') || htmlContent.includes('<html'));
            const mailOptions = {
                from: `"Future Pride" <${emailUser}>`,
                to: to, // Can be array of strings or comma-separated string
                subject: subject,
                html: isFullHtml ? htmlContent : htmlTemplate(htmlContent, title),
                attachments: attachments
            };

            const info = await transporter.sendMail(mailOptions);
            return { success: true, messageId: info.messageId };
        } catch (error) {
            console.error("Error sending email:", error);
            return { success: false, error: error.message };
        }
    },

    /**
     * Dedicated branded OTP email helper
     */
    sendOtpEmail: async ({ to, otp, recipientName = 'User', purpose = 'Staff Portal Login' }) => {
        try {
            const subject = `Your Future Pride Verification Code: ${otp}`;
            const bodyHtml = `
                <h2 style="color:#163174;margin-top:0;font-size:20px;">Verification Code (OTP)</h2>
                <p>Hello <strong>${recipientName}</strong>,</p>
                <p>You requested a One-Time Password (OTP) for <strong>${purpose}</strong>.</p>
                <div class="otp-box" style="text-align:center;margin:24px 0;padding:20px;background:#f8fafc;border:2px dashed #163174;border-radius:8px;">
                    <span class="otp-code" style="font-family:'Courier New',Courier,monospace;font-size:36px;font-weight:800;letter-spacing:8px;color:#163174;display:inline-block;">${otp}</span>
                </div>
                <p style="font-size:13px;color:#475569;">This code is valid for <strong>5 minutes</strong>. For security reasons, please do not share this OTP with anyone, including Future Pride staff.</p>
                <p style="font-size:12px;color:#94a3b8;margin-top:24px;border-top:1px solid #e2e8f0;padding-top:14px;">If you did not initiate this request, please contact our support team immediately at <a href="mailto:support@futurepride.in" style="color:#163174;text-decoration:none;">support@futurepride.in</a>.</p>
                <br/>
                <p style="margin:0;color:#163174;font-weight:700;">Future Pride IT &amp; Security Team</p>
            `;

            return await emailService.sendEmail({
                to,
                subject,
                htmlContent: bodyHtml,
                title: 'FUTURE PRIDE'
            });
        } catch (error) {
            console.error("Error in sendOtpEmail:", error);
            return { success: false, error: error.message };
        }
    },

    // Helper to just return the template for preview
    getTemplatePreview: (content, title = 'FUTURE PRIDE') => {
        return htmlTemplate(content, title);
    }
};

export default emailService;
