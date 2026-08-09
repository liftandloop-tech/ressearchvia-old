import { DateTime } from 'luxon';

/**
 * Checks if the given date is within quiet hours.
 * Default quiet hours are 22:00 to 08:00.
 */
export function isWithinQuietHours(
  date: Date,
  timezone = 'Asia/Kolkata',
  startStr = '22:00',
  endStr = '08:00',
): boolean {
  try {
    const dt = DateTime.fromJSDate(date).setZone(timezone);
    if (!dt.isValid) return false;

    const [startHour, startMin] = startStr.split(':').map(Number);
    const [endHour, endMin] = endStr.split(':').map(Number);

    const startMins = startHour * 60 + startMin;
    const endMins = endHour * 60 + endMin;
    const currentMins = dt.hour * 60 + dt.minute;

    if (startMins > endMins) {
      // Overnight (e.g. 22:00 -> 08:00)
      return currentMins >= startMins || currentMins < endMins;
    } else {
      // Daytime (e.g. 09:00 -> 17:00)
      return currentMins >= startMins && currentMins < endMins;
    }
  } catch {
    return false;
  }
}

/**
 * Calculates the next active time (when quiet hours end).
 */
export function getNextActiveTime(
  date: Date,
  timezone = 'Asia/Kolkata',
  endStr = '08:00',
): Date {
  try {
    const dt = DateTime.fromJSDate(date).setZone(timezone);
    const [endHour, endMin] = endStr.split(':').map(Number);

    // Create a DateTime representing endStr today
    let target = dt.set({ hour: endHour, minute: endMin, second: 0, millisecond: 0 });

    if (dt >= target) {
      target = target.plus({ days: 1 });
    }

    return target.toJSDate();
  } catch {
    // Fallback: 8 hours from now
    return new Date(date.getTime() + 8 * 3600000);
  }
}
