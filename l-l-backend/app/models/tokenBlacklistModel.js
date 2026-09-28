import mongoose from "mongoose";

const tokenBlacklistSchema = new mongoose.Schema({
    token: {
        type: String,
        required: true,
        unique: true,
        index: true
    },
    userId: {
        type: String,
        default: null
    },
    userType: {
        type: String,
        default: null
    },
    expiresAt: {
        type: Date,
        required: true,
        index: { expires: 0 } // Automatic TTL expiration by MongoDB
    },
    reason: {
        type: String,
        default: 'USER_LOGOUT'
    }
}, { timestamps: true });

const TokenBlacklist = mongoose.model("TokenBlacklist", tokenBlacklistSchema);
export default TokenBlacklist;
