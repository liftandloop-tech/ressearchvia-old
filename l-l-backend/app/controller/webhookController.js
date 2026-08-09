import userKycModel from "../models/userKycModel.js";
import userModel from "../models/userModel.js";
import crypto from "crypto";
import KycService from "../services/kycService.js";

const webhookController = {
    digioWebhook: async (req, res) => {
        try {
            console.log("Digio Webhook Received:", JSON.stringify(req.body, null, 2));

            const { payload, event } = req.body;

            // Validate Secret
            const signature = req.headers['x-digio-signature'];
            const secret = "Research@12";

            const validateSignature = (body, signature, secret) => {
                if (!signature) return false;
                // Digio signature is HMAC-SHA256 of the raw request body
                const hmac = crypto.createHmac('sha256', secret);
                const digest = hmac.update(JSON.stringify(body)).digest('hex');
                return signature === digest;
            };

            // Uncomment to enforce validation
            /*
            if (!validateSignature(req.body, signature, secret)) {
                 console.log("Invalid Webhook Signature. Expected:", signature);
                 // return res.status(401).send("Invalid Signature");
            }
            */

            if (!payload || !payload.document) {
                return res.status(200).send("OK - No document payload");
            }

            const documentId = payload.document.id;
            const status = event.toLowerCase(); // doc.signed, doc.sign.failed, etc.

            // Find the User KYC record associated with this Document ID
            // We search inside the digioObject which stores the full Digio response
            let userKyc = await userKycModel.findOne({
                "digioObject.id": documentId
            });

            if (!userKyc) {
                // Try fallback search if ID format differs or nested differently
                userKyc = await userKycModel.findOne({
                    "digioObject.document_id": documentId
                });
            }

            if (!userKyc) {
                console.log(`User KYC record not found for Document ID: ${documentId}`);
                // Return 200 to Digio so they don't retry endlessly for a missing local record
                return res.status(200).send("Record not found locally");
            }

            let newKycStatus = userKyc.kycStatus;
            let userStatus = "PENDING"; // Default

            if (status.includes("signed")) {
                newKycStatus = "verified"; // Or 'signed' depending on your enum
                userStatus = "VERIFIED";
            } else if (status.includes("rejected")) {
                newKycStatus = "rejected";
                userStatus = "REJECTED";
            } else if (status.includes("failed")) {
                newKycStatus = "failed"; // Or 'rejected'
                userStatus = "FAILED";
            }

            // Update userKycModel
            userKyc.kycStatus = newKycStatus;

            // Save the latest webhook payload for audit trails
            if (!userKyc.webhookHistory) {
                userKyc.webhookHistory = [];
            }
            userKyc.webhookHistory.push({
                event: event,
                payload: payload,
                receivedAt: new Date()
            });

            await userKyc.save();

            // --- GATE 2 SYNC: Update kycGates.esign in userModel ---
            // IMPORTANT: We do NOT touch user.kycStatus directly here.
            // The overall kycStatus is computed by determineNextStep() from all 3 gate
            // statuses. The webhook's job is only to record what Digio decided.
            const user = await userModel.findById(userKyc.userId);
            if (user) {
                // Safely initialize kycGates if missing (backward compat for old records)
                if (!user.kycGates) user.kycGates = {};
                if (!user.kycGates.esign) user.kycGates.esign = {};

                if (newKycStatus === "verified") {
                    user.kycGates.esign.status = 'VERIFIED';
                    user.kycGates.esign.rejectionReason = null;
                    user.kycGates.esign.reviewedAt = new Date();
                    if (!user.kycGates.esign.submittedAt) {
                        user.kycGates.esign.submittedAt = new Date();
                    }
                    console.log(`[Digio Webhook] E-Sign gate VERIFIED for user: ${userKyc.userId}`);

                } else if (newKycStatus === "rejected" || newKycStatus === "failed") {
                    user.kycGates.esign.status = 'REJECTED';
                    user.kycGates.esign.rejectionReason = `Digio signing ${newKycStatus}: ${event}`;
                    user.kycGates.esign.reviewedAt = new Date();
                    console.log(`[Digio Webhook] E-Sign gate REJECTED for user: ${userKyc.userId} — ${event}`);
                }

                user.markModified('kycGates');
                await user.save();

                // Keep the overall status synced based on all gates
                await KycService.syncOverallStatus(user._id, { type: 'SYSTEM', id: 'DIGIO_WEBHOOK' });
            }

            return res.status(200).send("Webhook Processed");

        } catch (error) {
            console.error("Webhook Error:", error);
            return res.status(500).send("Internal Server Error");
        }
    }
}

export default webhookController;
