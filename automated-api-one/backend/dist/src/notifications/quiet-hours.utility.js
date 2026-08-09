"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isWithinQuietHours = isWithinQuietHours;
exports.getNextActiveTime = getNextActiveTime;
const luxon_1 = require("luxon");
function isWithinQuietHours(date, timezone = 'Asia/Kolkata', startStr = '22:00', endStr = '08:00') {
    try {
        const dt = luxon_1.DateTime.fromJSDate(date).setZone(timezone);
        if (!dt.isValid)
            return false;
        const [startHour, startMin] = startStr.split(':').map(Number);
        const [endHour, endMin] = endStr.split(':').map(Number);
        const startMins = startHour * 60 + startMin;
        const endMins = endHour * 60 + endMin;
        const currentMins = dt.hour * 60 + dt.minute;
        if (startMins > endMins) {
            return currentMins >= startMins || currentMins < endMins;
        }
        else {
            return currentMins >= startMins && currentMins < endMins;
        }
    }
    catch {
        return false;
    }
}
function getNextActiveTime(date, timezone = 'Asia/Kolkata', endStr = '08:00') {
    try {
        const dt = luxon_1.DateTime.fromJSDate(date).setZone(timezone);
        const [endHour, endMin] = endStr.split(':').map(Number);
        let target = dt.set({ hour: endHour, minute: endMin, second: 0, millisecond: 0 });
        if (dt >= target) {
            target = target.plus({ days: 1 });
        }
        return target.toJSDate();
    }
    catch {
        return new Date(date.getTime() + 8 * 3600000);
    }
}
//# sourceMappingURL=quiet-hours.utility.js.map