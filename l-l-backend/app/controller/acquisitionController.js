import * as acquisitionService from "../services/acquisitionService.js";

export const initiateRegistration = async (req, res) => {
    try {
        const { type, paymentMode, segmentId, planId, isPartial } = req.body; // 'YEARLY' | 'LIFETIME'
        const userId = req.user._id; // Corrected from req.user.userId
        const result = await acquisitionService.initiateRegistrationPurchase(userId, type, paymentMode, segmentId, planId, isPartial);
        res.status(200).json({ status: 200, message: "Order created", data: result });
    } catch (error) {
        res.status(400).json({ status: 400, message: error.message });
    }
};

export const initiatePlan = async (req, res) => {
    try {
        const { planId, paymentMode, isPartial, segmentId, gstin } = req.body;
        const userId = req.user._id;
        const result = await acquisitionService.initiatePlanPurchase(userId, planId, paymentMode, isPartial, segmentId, false, gstin);
        res.status(200).json({ status: 200, message: "Order created", data: result });
    } catch (error) {
        res.status(400).json({ status: 400, message: error.message });
    }
};

export const verifyPayment = async (req, res) => {
    try {
        const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;
        const result = await acquisitionService.verifyPayment(razorpay_order_id, razorpay_payment_id, razorpay_signature);
        res.status(200).json({ status: 200, message: "Payment verified", data: result });
    } catch (error) {
        res.status(400).json({ status: 400, message: error.message });
    }
};

export const adminOnboardUser = async (req, res) => {
    try {
        const adminId = req.user.userId;
        const { userData, entitlements } = req.body;
        // userData: { mobile, name, email ... }
        // entitlements: { registrationType, plans: [] }

        const result = await acquisitionService.onboardOfflineUser(adminId, userData, entitlements);
        res.status(200).json({ status: 200, message: "User onboarded successfully", data: result });
    } catch (error) {
        res.status(400).json({ status: 400, message: error.message });
    }
};
export const uploadProof = async (req, res) => {
    try {
        const { paymentIntentId, transactionDate, amountPaid, utrNumber } = req.body;
        const files = req.files;
        const userId = req.user?._id || req.user?.userId;
        if (!paymentIntentId || !files || files.length === 0) throw new Error("Missing Payment ID or File");

        const result = await acquisitionService.uploadProof(paymentIntentId, files, { transactionDate, amountPaid, utrNumber }, userId);
        res.status(200).json({ status: 200, message: "Proof uploaded", data: result });
    } catch (error) {
        res.status(400).json({ status: 400, message: error.message });
    }
};
export const approvePartialPayment = async (req, res) => {
    try {
        const { paymentIntentId, historyId, comment, discount } = req.body;
        const adminId = req.user._id;
        if (!paymentIntentId || !historyId) throw new Error("Missing Intent ID or History ID");

        const result = await acquisitionService.approvePartialPayment(paymentIntentId, historyId, adminId, comment, discount);
        res.status(200).json({ status: 200, message: "Payment installment approved", data: result });
    } catch (error) {
        console.error("Error approving partial payment:", error.stack);
        res.status(400).json({ status: 400, message: error.message });
    }
};

export const rejectPartialPayment = async (req, res) => {
    try {
        const { paymentIntentId, historyId } = req.body;
        if (!paymentIntentId || !historyId) throw new Error("Missing Intent ID or History ID");

        const result = await acquisitionService.rejectPartialPayment(paymentIntentId, historyId);
        res.status(200).json({ status: 200, message: "Payment installment rejected", data: result });
    } catch (error) {
        res.status(400).json({ status: 400, message: error.message });
    }
};

export const getActivePartialInfo = async (req, res) => {
    try {
        const userId = req.user._id;
        const result = await acquisitionService.getActivePartialInfo(userId);
        res.status(200).json({ status: 200, data: result });
    } catch (error) {
        res.status(400).json({ status: 400, message: error.message });
    }
};

export const getPartialHistory = async (req, res) => {
    try {
        const userId = req.user._id;
        const { intentId } = req.params;
        const result = await acquisitionService.getPartialPaymentHistory(userId, intentId);
        res.status(200).json({ status: 200, data: result });
    } catch (error) {
        res.status(400).json({ status: 400, message: error.message });
    }
};
export const updatePaymentDiscount = async (req, res) => {
    try {
        const { paymentIntentId, discount } = req.body;
        const adminId = req.user._id;
        if (!paymentIntentId) throw new Error("Missing Payment Intent ID");

        const result = await acquisitionService.updatePaymentDiscount(paymentIntentId, discount, adminId);
        res.status(200).json({ status: 200, message: "Discount updated successfully", data: result });
    } catch (error) {
        res.status(400).json({ status: 400, message: error.message });
    }
};

export const getRegistrationDetails = async (req, res) => {
    try {
        const userId = req.user._id;
        const result = await acquisitionService.getRegistrationDetails(userId);
        res.status(200).json({ status: 200, data: result });
    } catch (error) {
        res.status(400).json({ status: 400, message: error.message });
    }
};

export const updateSubscriptionMetadata = async (req, res) => {
    try {
        const { paymentIntentId, newSegmentId, newPlanId, newStartDate, newExpiryDate } = req.body;
        const clientVersion = req.body.clientVersion !== undefined ? Number(req.body.clientVersion) : undefined;
        const adminId = req.user._id;

        const result = await acquisitionService.updateSubscriptionMetadata({
            paymentIntentId,
            newSegmentId,
            newPlanId,
            newStartDate,
            newExpiryDate,
            adminId,
            clientVersion,
            req
        });

        res.status(200).json({ status: 200, message: "Subscription updated successfully", data: result });
    } catch (error) {
        const status = error.status || 400;
        res.status(status).json({ status, message: error.message });
    }
};

export const adminApproveWithProof = async (req, res) => {
    try {
        const { paymentIntentId, utrNumber, amountPaid, paymentMethod, historyId, comment, discount } = req.body;
        const files = req.files || [];
        const adminId = req.user?._id || req.user?.userId;
        if (!paymentIntentId) throw new Error("Missing Payment Intent ID");
        if (!utrNumber || !utrNumber.trim()) throw new Error("Transaction UTR or Reference ID is required");

        const result = await acquisitionService.adminApproveWithProof({
            paymentIntentId,
            utrNumber: utrNumber.trim(),
            amountPaid,
            paymentMethod: paymentMethod || 'RAZORPAY',
            historyId,
            comment,
            discount: discount ? Number(discount) : 0,
            adminId,
            files,
            req
        });
        res.status(200).json({ status: 200, message: "Payment approved with proof successfully", data: result });
    } catch (error) {
        console.error("Error in adminApproveWithProof controller:", error);
        res.status(400).json({ status: 400, message: error.message });
    }
};

