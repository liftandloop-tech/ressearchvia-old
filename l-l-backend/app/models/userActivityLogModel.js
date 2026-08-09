import mongoose from "mongoose";

/**
 * UserActivityLog - Compliance-grade audit trail.
 * Records every significant user event with precise timestamps.
 * NEVER delete records from this collection.
 */
const userActivityLogSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "users",
        required: true,
        index: true
    },
    // Event type taxonomy
    eventType: {
        type: String,
        required: true,
        enum: [
            // Session events
            'USER_LOGIN',               // User logged in via MPIN
            'USER_LOGOUT',              // User logged out
            'APP_SESSION_START',        // App opened / token refreshed
            'NEW_DEVICE_LOGIN',         // First login on a new device

            // Manager / staff assignments
            'MANAGER_ASSIGNED',         // A manager was assigned to user
            'MANAGER_REMOVED',          // A manager was removed

            // Profile events (admin-triggered)
            'ADMIN_PROFILE_EDIT',       // Admin edited user profile
            'PROFILE_UPDATED',          // User updated own profile

            // KYC
            'KYC_STATUS_CHANGED',       // KYC status transition

            // Trading calls / reports
            'CALL_ASSIGNED',            // A trading call/report published and assigned
            'TRADING_CALL_OPENED',      // User opened a trading call

            // Payment / subscription changes
            'PAYMENT_APPROVED',         // Payment approved by admin
            'PAYMENT_REJECTED',         // Payment rejected by admin
            'SUBSCRIPTION_EXTENDED',    // Subscription extended by admin
            'SUBSCRIPTION_REVOKED',     // Subscription revoked by admin
            'SUBSCRIPTION_SUSPENDED',   // Subscription suspended
            'SUBSCRIPTION_ACTIVATED',   // Subscription reactivated
            'PLAN_CREATED',             // Admin manually created plan
            'PLAN_TOPUP',               // Partial plan top-up
            'SUBSCRIPTION_METADATA_UPDATED', // Admin updated plan/segment/dates
            'UPDATE_PAYMENT_DISCOUNT',  // Admin applied a discount to a payment intent

            // Account
            'ACCOUNT_CREATED',          // User account created
            'ACCOUNT_SUSPENDED',        // Account suspended/deactivated
            'ACCOUNT_ACTIVATED',        // Account reactivated
            'TEMP_PIN_GENERATED',       // Admin generated a one-time login PIN
            'ALIAS_LOGIN',              // User/Admin logged in via Alias PIN
        ],
        index: true
    },
    // Severity level for compliance triage
    severity: {
        type: String,
        required: true,
        enum: ['INFO', 'WARNING', 'SECURITY', 'CRITICAL'],
        default: 'INFO',
        index: true
    },
    // Millisecond-precise timestamp (separate from Mongoose createdAt)
    eventTimestamp: {
        type: Date,
        required: true,
        default: () => new Date(),
        index: true
    },
    // IP address of the request
    ipAddress: {
        type: String,
        default: null
    },
    // Device info
    deviceId: {
        type: String,
        default: null
    },
    platform: {
        type: String,
        enum: ['android', 'ios', 'web', null],
        default: null
    },
    // Human-readable description for the admin panel
    description: {
        type: String,
        required: true
    },
    // Who performed the action (user / admin / system)
    performedBy: {
        id: { type: String, default: null },
        name: { type: String, default: null },
        role: { type: String, default: null }
    },
    // Extra context (flexible key-value store)
    metadata: {
        type: Object,
        default: {}
    }
}, {
    timestamps: true,
    versionKey: false
});

// Compound indices for fast per-user queries
userActivityLogSchema.index({ userId: 1, eventTimestamp: -1 });
userActivityLogSchema.index({ eventType: 1, eventTimestamp: -1 });
userActivityLogSchema.index({ severity: 1, eventTimestamp: -1 });
userActivityLogSchema.index({ userId: 1, severity: 1, eventTimestamp: -1 });

const UserActivityLog = mongoose.model("userActivityLog", userActivityLogSchema);
export default UserActivityLog;
