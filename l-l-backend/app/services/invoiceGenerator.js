import { PDFDocument, rgb, StandardFonts } from 'pdf-lib';

const invoiceGenerator = {
    generateInvoice: async (data) => {
        // data: { invoiceNumber, date, customerName, customerEmail, planName, basicAmount, cgst, sgst, totalAmount }

        const pdfDoc = await PDFDocument.create();
        const page = pdfDoc.addPage([595.28, 841.89]); // A4 size
        const { width, height } = page.getSize();
        const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
        const boldFont = await pdfDoc.embedFont(StandardFonts.HelveticaBold);

        const drawText = (text, x, y, size = 12, isBold = false, color = rgb(0, 0, 0)) => {
            page.drawText(String(text), { x, y, size, font: isBold ? boldFont : font, color });
        };

        // Header
        page.drawRectangle({ x: 0, y: height - 100, width: width, height: 100, color: rgb(0.1, 0.1, 0.4) });
        drawText("INVOICE", 40, height - 50, 30, true, rgb(1, 1, 1));
        drawText("ResearchVia Subscription", 40, height - 80, 14, false, rgb(0.9, 0.9, 0.9));

        // Company Details (Mock)
        drawText("ResearchVia", 400, height - 40, 14, true, rgb(1, 1, 1));
        drawText("support@researchvia.in", 400, height - 55, 10, false, rgb(0.9, 0.9, 0.9));
        drawText("GSTIN: 23ABMCS3444G1ZC", 400, height - 70, 9, false, rgb(0.9, 0.9, 0.9));
        drawText("SEBI REG: INH000015808", 400, height - 85, 9, false, rgb(0.9, 0.9, 0.9));

        let yPos = height - 150;

        // Metadata
        drawText("Invoice Number:", 40, yPos, 10, true);
        drawText(data.invoiceNumber || 'N/A', 140, yPos, 10);

        drawText("Date:", 400, yPos, 10, true);
        drawText(new Date(data.date).toLocaleDateString(), 450, yPos, 10);

        yPos -= 20;

        // Bill To
        yPos -= 30;
        const billToY = yPos;
        drawText("Bill To:", 40, billToY, 12, true);

        if (data.customerAddress) {
            drawText("Address:", 350, billToY, 12, true);
        }

        yPos -= 20;
        let leftY = yPos;

        if (data.gstin && data.firmName) {
            drawText(data.firmName, 40, leftY, 10);
            leftY -= 15;
            drawText(data.customerName || 'Customer', 40, leftY, 10);
        } else {
            drawText(data.customerName || 'Customer', 40, leftY, 10);
        }

        if (data.customerEmail) {
            leftY -= 15;
            drawText(data.customerEmail, 40, leftY, 10);
        }
        if (data.customerPhone) {
            leftY -= 15;
            drawText(data.customerPhone, 40, leftY, 10);
        }
        if (data.gstin && data.firmName) {
            leftY -= 15;
            drawText(`GSTIN: ${data.gstin}`, 40, leftY, 10);
        }

        if (data.customerAddress) {
            let rightY = yPos;
            const addressText = String(data.customerAddress);
            const words = addressText.split(' ');
            let currentLine = '';
            for (const word of words) {
                if ((currentLine + ' ' + word).length > 30) {
                    drawText(currentLine.trim(), 350, rightY, 10);
                    rightY -= 15;
                    currentLine = word;
                } else {
                    currentLine += (currentLine ? ' ' : '') + word;
                }
            }
            if (currentLine) {
                drawText(currentLine.trim(), 350, rightY, 10);
                rightY -= 15;
            }
            yPos = Math.min(leftY, rightY);
        } else {
            yPos = leftY;
        }

        // Table
        yPos -= 50;
        const col1 = 40;
        const col2 = 300;
        const col3 = 450;

        // Header
        page.drawLine({ start: { x: 40, y: yPos + 5 }, end: { x: 550, y: yPos + 5 }, thickness: 1, color: rgb(0.5, 0.5, 0.5) });
        drawText("Description", col1, yPos, 10, true);
        drawText("Total", col3, yPos, 10, true);
        yPos -= 15;
        page.drawLine({ start: { x: 40, y: yPos + 10 }, end: { x: 550, y: yPos + 10 }, thickness: 1, color: rgb(0.5, 0.5, 0.5) });

        yPos -= 20;
        drawText(`Subscription Plan: ${data.planName}`, col1, yPos, 10);
        drawText(data.totalAmount.toFixed(2), col3, yPos, 10);

        yPos -= 40;
        page.drawLine({ start: { x: 40, y: yPos + 20 }, end: { x: 550, y: yPos + 20 }, thickness: 1, color: rgb(0.9, 0.9, 0.9) });

        // Totals
        const summaryX = 350;
        drawText("Sub Total:", summaryX, yPos, 10);
        drawText(data.basicAmount.toFixed(2), col3, yPos, 10);
        yPos -= 20;

        if (data.discount && data.discount > 0) {
            drawText("Discount:", summaryX, yPos, 10);
            drawText(`-${data.discount.toFixed(2)}`, col3, yPos, 10);
            yPos -= 20;
        }

        drawText("CGST:", summaryX, yPos, 10);
        drawText(data.cgst.toFixed(2), col3, yPos, 10);
        yPos -= 20;
        drawText("SGST:", summaryX, yPos, 10);
        drawText(data.sgst.toFixed(2), col3, yPos, 10);

        yPos -= 20;
        page.drawLine({ start: { x: summaryX, y: yPos + 10 }, end: { x: 550, y: yPos + 10 }, thickness: 1 });
        drawText("Total Amount:", summaryX, yPos, 12, true);
        drawText(data.totalAmount.toFixed(2), col3, yPos, 12, true);

        // Installment History Table (If applicable)
        if (data.installments && data.installments.length > 0) {
            yPos -= 50;
            drawText("Payment History / Installments", 40, yPos, 12, true, rgb(0.1, 0.1, 0.4));
            yPos -= 20;

            // Table Header
            page.drawRectangle({ x: 40, y: yPos - 5, width: 510, height: 20, color: rgb(0.9, 0.9, 0.95) });
            drawText("Date", 50, yPos, 10, true);
            drawText("Method", 200, yPos, 10, true);
            drawText("Amount", 450, yPos, 10, true);
            yPos -= 20;

            for (const inst of data.installments) {
                // Check for page break if yPos is too low
                if (yPos < 100) {
                    // Logic for new page could be complex, for now assume installments fit or truncate
                    break;
                }
                const instDate = new Date(inst.date).toLocaleDateString();
                drawText(instDate, 50, yPos, 9);
                drawText(inst.method || 'OFFLINE', 200, yPos, 9);
                drawText(`Rs.${inst.amount.toFixed(2)}`, 450, yPos, 9);
                yPos -= 15;
            }
        }

        // Footer
        drawText("Thank you for your business!", 200, 50, 10, false, rgb(0.5, 0.5, 0.5));

        const pdfBytes = await pdfDoc.save();
        return pdfBytes;
    }
}

export default invoiceGenerator;
