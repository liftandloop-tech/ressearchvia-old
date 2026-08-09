import nodemailer from 'nodemailer';

const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: process.env.SMTP_PORT || 587,
    secure: process.env.SMTP_SECURE === 'true', // true for 465, false for other ports
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS
    }
});

const htmlTemplate = (content, title = 'ATTENTION!!!') => `
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: 'Poppins', sans-serif; background-color: #f4f4f4; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        .header { background-color: #4CAF50; padding: 20px; text-align: center; color: white; }
        .header h1 { margin: 0; font-size: 24px; text-transform: uppercase; }
        .content { padding: 30px; color: #333333; line-height: 1.6; }
        .footer { background-color: #f4f4f4; padding: 20px; text-align: center; font-size: 12px; color: #888888; }
        .button { display: inline-block; padding: 10px 20px; background-color: #4CAF50; color: white; text-decoration: none; border-radius: 5px; margin-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>${title}</h1>
        </div>
        <div class="content">
            ${content}
        </div>
        <div class="footer">
            <p>&copy; ${new Date().getFullYear()} ResearchVia. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
`;

const emailService = {
    sendEmail: async ({ to, subject, htmlContent, attachments = [] }) => {
        try {
            const mailOptions = {
                from: process.env.EMAIL_USER,
                to: to, // Can be array of strings
                subject: subject,
                html: htmlTemplate(htmlContent),
                attachments: attachments
            };

            const info = await transporter.sendMail(mailOptions);
            return { success: true, messageId: info.messageId };
        } catch (error) {
            console.error("Error sending email:", error);
            return { success: false, error: error.message };
        }
    },

    // Helper to just return the template for preview
    getTemplatePreview: (content) => {
        return htmlTemplate(content, 'ATTENTION!!!');
    }
};

export default emailService;
