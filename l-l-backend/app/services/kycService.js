import userModel from '../models/userModel.js';

const KycService = {

    /**
     * Deterministic State Transition for KYC
     * @param {String} userId - The user ID (MongoDB _id)
     * @param {String} targetStatus - The desired new status
     * @param {Object} actor - { id: string, type: 'USER'|'ADMIN'|'SYSTEM' }
     * @param {String} reason - Audit reason or rejection note
     */
    transitionStatus: async (userId, targetStatus, actor, reason = null) => {
        const user = await userModel.findById(userId);
        if (!user) throw new Error("User not found");

        const currentStatus = user.kycStatus;

        // 1. VALIDATE TRANSITIONS (State Machine Rules)
        const allowed = {
            'NOT_STARTED': ['IN_PROGRESS'],
            'IN_PROGRESS': ['WAITING_FOR_REVIEW', 'VERIFIED', 'NOT_STARTED'], // VERIFIED allowed only for SYSTEM auto-KYC
            'WAITING_FOR_REVIEW': ['VERIFIED', 'REJECTED', 'IN_PROGRESS'], // Admin decision or revert
            'VERIFIED': ['REJECTED', 'WAITING_FOR_REVIEW'], // Admin override or Re-KYC (e.g. Video Upload)
            'REJECTED': ['IN_PROGRESS', 'WAITING_FOR_REVIEW'] // Retry
        };

        // Strict Enforcement
        if (currentStatus !== targetStatus) {
            if (!allowed[currentStatus] || !allowed[currentStatus].includes(targetStatus)) {
                // Allow SYSTEM/ADMIN force override? No, stick to the machine logic for now.
                throw new Error(`[KYC] Invalid Transition: ${currentStatus} -> ${targetStatus}`);
            }
        } else {
            // Redundant transition, possibly just update checks or logs
            return user;
        }

        // 2. VALIDATE DATA COMPLETENESS (Guard Rails)
        if (targetStatus === 'WAITING_FOR_REVIEW') {
            // Ensure at least PAN or basic docs exist
            if (!user.kycDocs || (!user.kycDocs.panImage && !user.panNumber)) {
                // throw new Error("Cannot move to Review without PAN details");
                // Soft warning for now as legacy data might differ
            }
        }

        if (targetStatus === 'VERIFIED') {
            if (currentStatus === 'IN_PROGRESS' && actor.type !== 'SYSTEM') {
                throw new Error("Only SYSTEM can auto-verify from IN_PROGRESS (Digio)");
            }
        }

        if (targetStatus === 'REJECTED' && !reason) {
            throw new Error("Rejection reason is mandatory");
        }

        // 3. APPLY UPDATE
        user.kycStatus = targetStatus;

        // Propagate Admin decision down to individual gates
        if (!user.kycGates) user.kycGates = {};
        if (!user.kycGates.documents) user.kycGates.documents = {};
        if (!user.kycGates.esign) user.kycGates.esign = {};
        if (!user.kycGates.video) user.kycGates.video = {};

        if (targetStatus === 'REJECTED') {
            // If Admin rejects, mark non-verified gates as REJECTED
            const markRejected = (gate) => {
                if (gate.status !== 'VERIFIED') {
                    gate.status = 'REJECTED';
                    gate.rejectionReason = reason || 'Admin Rejected';
                }
            };
            markRejected(user.kycGates.documents);
            markRejected(user.kycGates.esign);
            markRejected(user.kycGates.video);
            user.markModified('kycGates');
        } else if (targetStatus === 'VERIFIED') {
            // If Admin verifies, verify all gates
            user.kycGates.documents.status = 'VERIFIED';
            user.kycGates.esign.status = 'VERIFIED';
            user.kycGates.video.status = 'VERIFIED';
            user.markModified('kycGates');
        }

        // Clear rejection reason if moving out of REJECTED
        if (targetStatus !== 'REJECTED') {
            user.kycRejectionReason = null;
        } else {
            user.kycRejectionReason = reason || 'Admin Rejected';
        }

        // 4. AUDIT LOG
        user.kycHistory.push({
            fromStatus: currentStatus,
            toStatus: targetStatus,
            changedBy: `${actor.type}:${actor.id}`,
            reason: reason,
            timestamp: new Date()
        });

        if (targetStatus === 'WAITING_FOR_REVIEW') {
            user.kycSubmittedAt = new Date();
        }

        await user.save();
        return user;
    },

    /**
     * Synchronize the overall kycStatus string with the individual gates.
     */
    syncOverallStatus: async (userId, actor = { type: 'SYSTEM', id: 'SYNC' }) => {
        const user = await userModel.findById(userId);
        if (!user) throw new Error("User not found");

        const kycGates = user.kycGates || {};
        const docStatus = kycGates.documents?.status ?? 'NOT_STARTED';
        const esignStatus = kycGates.esign?.status ?? 'NOT_STARTED';
        const videoStatus = kycGates.video?.status ?? 'NOT_STARTED';

        let computedStatus = 'NOT_STARTED';

        // 1. REJECTED: Any single gate rejection blocks overall status
        if (docStatus === 'REJECTED' || esignStatus === 'REJECTED' || videoStatus === 'REJECTED') {
            computedStatus = 'REJECTED';
        } 
        // 2. VERIFIED: All 3 must be VERIFIED
        else if (docStatus === 'VERIFIED' && esignStatus === 'VERIFIED' && videoStatus === 'VERIFIED') {
            computedStatus = 'VERIFIED';
        }
        // 3. WAITING_FOR_REVIEW: All 3 are "submitted" (not NOT_STARTED)
        else if (docStatus !== 'NOT_STARTED' && esignStatus !== 'NOT_STARTED' && videoStatus !== 'NOT_STARTED') {
            computedStatus = 'WAITING_FOR_REVIEW';
        }
        // 4. IN_PROGRESS: At least one gate is started (PENDING/VERIFIED)
        else if (docStatus !== 'NOT_STARTED' || esignStatus !== 'NOT_STARTED' || videoStatus !== 'NOT_STARTED') {
            computedStatus = 'IN_PROGRESS';
        }
        // 5. Default: NOT_STARTED

        if (user.kycStatus !== computedStatus) {
            const currentStatus = user.kycStatus;
            user.kycStatus = computedStatus;

            if (computedStatus !== 'REJECTED') {
                user.kycRejectionReason = null;
            } else {
                let reasons = [];
                if (docStatus === 'REJECTED') reasons.push('Documents: ' + (kycGates.documents?.rejectionReason || 'Rejected'));
                if (esignStatus === 'REJECTED') reasons.push('E-Sign: ' + (kycGates.esign?.rejectionReason || 'Rejected'));
                if (videoStatus === 'REJECTED') reasons.push('Video: ' + (kycGates.video?.rejectionReason || 'Rejected'));
                user.kycRejectionReason = reasons.join(' | ');
            }

            if (!user.kycHistory) user.kycHistory = [];
            user.kycHistory.push({
                fromStatus: currentStatus,
                toStatus: computedStatus,
                changedBy: `${actor.type}:${actor.id}`,
                reason: `Auto-sync overall status from gates`,
                timestamp: new Date()
            });

            await user.save();
        }
        return user;
    }
};

export default KycService;
