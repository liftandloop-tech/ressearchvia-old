import users from "../models/userModel.js";
import devices from "../models/deviceModel.js";
import mongoose from "mongoose";

export async function getUserTokens(userIds) {
    if (!userIds || userIds.length === 0) return [];

    const userIdsArray = Array.isArray(userIds) ? userIds : [userIds];

    // Split into ObjectIds (for _id) and strings (for custom userId)
    const objectIds = [];
    const customIds = [];

    userIdsArray.forEach(id => {
        // Check if valid ObjectId string
        if (mongoose.Types.ObjectId.isValid(id) && (typeof id === 'string' ? id.length === 24 : true)) {
            objectIds.push(new mongoose.Types.ObjectId(id.toString()));
        } else {
            customIds.push(id.toString());
        }
    });

    // 1. Fetch tokens from users collection (Legacy/Individual fcmToken field)
    let userQuery = { fcmToken: { $exists: true, $ne: null } };
    if (objectIds.length > 0 && customIds.length > 0) {
        userQuery.$or = [
            { _id: { $in: objectIds } },
            { userId: { $in: customIds } }
        ];
    } else if (objectIds.length > 0) {
        userQuery._id = { $in: objectIds };
    } else if (customIds.length > 0) {
        userQuery.userId = { $in: customIds };
    }

    const userList = await users.find(userQuery).select("fcmToken");
    const userTokens = userList.map(u => u.fcmToken).filter(t => t);

    // 2. Fetch tokens from devices collection (Modern system, multi-device)
    let deviceQuery = { isActive: true, pushToken: { $exists: true, $ne: null } };
    if (objectIds.length > 0) {
        deviceQuery.userId = { $in: objectIds };
    }
    // Note: devices model only uses ObjectId for userId, so we don't check customIds there unless needed.

    const deviceList = await devices.find(deviceQuery).select("pushToken");
    const deviceTokens = deviceList.map(d => d.pushToken).filter(t => t);

    // Combine and deduplicate
    const combinedTokens = [...new Set([...userTokens, ...deviceTokens])];

    return combinedTokens;
}

