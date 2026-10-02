import axios from "axios";
import crypto from "crypto";
import callLogModel from "../models/callLogModel.js";
import leadModel from "../models/leadModel.js";

const getBaseUrl = () => process.env.TELEPHONY_BASE_URL || 'https://api.vonage.com/t/vbc.prod/telephony/v3';
const getProvisioningUrl = () => process.env.PROVISIONING_BASE_URL || 'https://api.vonage.com/t/vbc.prod/provisioning';
const getAccountId = () => process.env.TELEPHONY_ACCOUNT_ID || process.env.VONAGE_ACCOUNT_ID || '';
const getBearerToken = () => process.env.TELEPHONY_BEARER_TOKEN || process.env.VONAGE_BEARER_TOKEN || '';

const getAuthHeader = () => {
    const token = getBearerToken();
    if (!token) return "";
    return token.startsWith("Bearer ") ? token : `Bearer ${token}`;
};

/**
 * Format and sanitize phone numbers for PSTN calls.
 * Removes non-digits and applies optional carrier PSTN prefix.
 */
export const cleanPhoneNumber = (phone) => {
    if (!phone) return "";
    let cleaned = String(phone).replace(/\D/g, "");
    if (cleaned.length === 12 && cleaned.startsWith("91")) {
        cleaned = cleaned.substring(2);
    } else if (cleaned.length === 11 && cleaned.startsWith("0")) {
        cleaned = cleaned.substring(1);
    }
    const prefix = process.env.TELEPHONY_PSTN_PREFIX || "";
    return prefix ? `${prefix}${cleaned}` : cleaned;
};

/**
 * Check whether real Telephony API credentials are configured
 */
export const isConfigured = () => {
    return Boolean(getAccountId() && getBearerToken());
};

/**
 * Helper to extract descriptive error messages from API responses
 */
const extractErrorMessage = (apiError) => {
    if (!apiError.response?.data) return apiError.message;
    const d = apiError.response.data;
    if (typeof d === 'string') return d;
    if (d.message) return d.message;
    if (d.error) return d.error;
    if (Array.isArray(d.errors)) {
        return d.errors.map(e => e.message || e.field || JSON.stringify(e)).join(', ');
    }
    return JSON.stringify(d);
};

/**
 * Initiate Click-to-Dial via Airtel/Vonage Virtual SIM API
 * POST /cc/accounts/{account_id}/calls
 */
export const initiateClickToDial = async ({
    fromDestination,
    fromType = 'extension',
    toDestination,
    leadId,
    staffId,
    companyId = 'default_company'
}) => {
    const cleanedTo = cleanPhoneNumber(toDestination);
    if (!cleanedTo) {
        throw new Error("Invalid destination phone number");
    }

    if (!fromDestination) {
        throw new Error("Staff extension or device destination is required");
    }

    const accountId = getAccountId();
    let callId;
    let rawApiResponse = null;
    let initialStatus = 'ringing';

    if (isConfigured()) {
        try {
            const url = `${getBaseUrl()}/cc/accounts/${accountId}/calls`;
            const payload = {
                from: {
                    destination: String(fromDestination),
                    type: fromType || 'extension'
                },
                to: {
                    destination: String(cleanedTo),
                    type: 'pstn'
                },
                type: 'click2dial'
            };

            const response = await axios.post(url, payload, {
                headers: {
                    'Authorization': getAuthHeader(),
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                },
                timeout: 10000
            });

            rawApiResponse = response.data;
            if (typeof response.data === 'string') {
                callId = response.data.replace(/["']/g, '').trim();
            } else if (response.data && typeof response.data === 'object') {
                callId = response.data.call_id || response.data.id || response.data.callId || response.data.statusMessage || response.data.message;
            }

            if (!callId || typeof callId !== 'string' || callId.length < 5) {
                callId = crypto.randomUUID();
            }
        } catch (apiError) {
            console.error('[TelephonyService] API Error initiating call:', apiError.response?.data || apiError.message);
            const errMsg = extractErrorMessage(apiError);
            throw new Error(`Telephony API Error: ${errMsg}`);
        }
    } else {
        // Mock simulation mode for dev / testing when credentials are not yet configured
        callId = crypto.randomUUID();
        rawApiResponse = {
            simulated: true,
            message: "Running in mock mode. Configure TELEPHONY_ACCOUNT_ID and TELEPHONY_BEARER_TOKEN in .env for live calls."
        };
        console.log(`[TelephonyService Mock] Initiated simulated click2dial from ${fromDestination} to ${cleanedTo}, callId: ${callId}`);
    }

    // Create call record in database
    const callLog = await callLogModel.create({
        leadId,
        staffId: staffId || null,
        provider: 'airtel_vonage',
        accountId: accountId || 'mock_account',
        callId,
        from: {
            destination: String(fromDestination),
            type: fromType
        },
        to: {
            destination: String(cleanedTo),
            type: 'pstn'
        },
        type: 'click2dial',
        status: initialStatus,
        startedAt: new Date(),
        rawResponse: rawApiResponse,
        companyId
    });

    return {
        success: true,
        callId,
        callLog
    };
};

/**
 * Fetch live status of a call
 * GET /cc/accounts/{account_id}/calls/{call_id}
 */
export const getCallStatus = async (callId) => {
    const callLog = await callLogModel.findOne({ callId }).populate('leadId', 'fullName mobileNumber emailAddress stage');
    if (!callLog) {
        throw new Error("Call record not found");
    }

    const accountId = getAccountId();

    if (isConfigured() && callLog.status !== 'completed' && callLog.status !== 'cancelled' && callLog.status !== 'failed' && callLog.status !== 'unanswered') {
        try {
            const url = `${getBaseUrl()}/cc/accounts/${accountId}/calls/${callId}`;
            const response = await axios.get(url, {
                headers: {
                    'Authorization': getAuthHeader(),
                    'Accept': 'application/json'
                },
                timeout: 8000
            });

            const data = response.data;
            if (data) {
                if (data.status) {
                    callLog.status = data.status;
                }
                if (data.legs && Array.isArray(data.legs)) {
                    callLog.legIds = data.legs.map(l => l.leg_id).filter(Boolean);
                }
                if (data.status === 'on-call' && !callLog.answeredAt) {
                    callLog.answeredAt = new Date();
                }
                await callLog.save();
            }
        } catch (error) {
            // In Vonage/Airtel VBC, completed calls are immediately purged from the active calls table and return 404
            if (error.response?.status === 404) {
                if (callLog.status !== 'completed' && callLog.status !== 'cancelled' && callLog.status !== 'failed' && callLog.status !== 'unanswered') {
                    // If call was previously connected (on-call or had answeredAt), it completed successfully
                    if (callLog.status === 'on-call' || callLog.answeredAt) {
                        callLog.status = 'completed';
                    } else {
                        // Was never answered
                        callLog.status = 'unanswered';
                    }
                    callLog.endedAt = new Date();
                    const startTime = callLog.answeredAt || callLog.startedAt || new Date();
                    callLog.durationSeconds = Math.max(0, Math.floor((callLog.endedAt - startTime) / 1000));
                    await callLog.save();
                }
            } else {
                console.error('[TelephonyService] Error getting call status:', error.message);
            }
        }
    } else if (!isConfigured() && callLog.status !== 'completed' && callLog.status !== 'cancelled') {
        // Mock state progression for development
        const elapsedSeconds = Math.floor((Date.now() - new Date(callLog.startedAt).getTime()) / 1000);
        if (elapsedSeconds >= 4 && callLog.status === 'ringing') {
            callLog.status = 'on-call';
            callLog.answeredAt = new Date(Date.now() - (elapsedSeconds - 4) * 1000);
            await callLog.save();
        }
    }

    return callLog;
};

/**
 * Terminate / Hangup an ongoing call
 * DELETE /cc/accounts/{account_id}/calls/{call_id}
 */
export const terminateCall = async (callId) => {
    const callLog = await callLogModel.findOne({ callId });
    if (!callLog) {
        throw new Error("Call record not found");
    }

    const accountId = getAccountId();

    if (isConfigured()) {
        try {
            const url = `${getBaseUrl()}/cc/accounts/${accountId}/calls/${callId}`;
            await axios.delete(url, {
                headers: {
                    'Authorization': getAuthHeader(),
                    'Accept': 'application/json'
                },
                timeout: 8000
            });
        } catch (error) {
            console.warn('[TelephonyService] Hangup request returned:', error.response?.data || error.message);
        }
    }

    // Set final status based on whether call was connected or still ringing
    if (callLog.status === 'ringing' || callLog.status === 'initiated') {
        callLog.status = 'cancelled';
    } else {
        callLog.status = 'completed';
    }

    callLog.endedAt = new Date();
    const startTime = callLog.answeredAt || callLog.startedAt || new Date();
    callLog.durationSeconds = Math.max(0, Math.floor((callLog.endedAt - startTime) / 1000));
    await callLog.save();

    return callLog;
};

/**
 * Fetch available extensions from Provisioning API
 * GET /api/accounts/{account_id}/extensions
 */
export const getAccountExtensions = async () => {
    if (!isConfigured()) {
        return [
            { extension_number: "101", caller_id: "Sales Desk 1", dnd_enabled: false },
            { extension_number: "102", caller_id: "Sales Desk 2", dnd_enabled: false },
            { extension_number: "103", caller_id: "Support Desk", dnd_enabled: false }
        ];
    }

    const accountId = getAccountId();

    try {
        const url = `${getProvisioningUrl()}/api/accounts/${accountId}/extensions`;
        const response = await axios.get(url, {
            headers: {
                'Authorization': getAuthHeader(),
                'Accept': 'application/json'
            },
            timeout: 10000
        });

        const data = response.data;
        const embedded = data?._embedded;
        let list = [];

        if (embedded?.data) {
            list = Array.isArray(embedded.data) ? embedded.data : [embedded.data];
        } else if (embedded?.extensions) {
            list = Array.isArray(embedded.extensions) ? embedded.extensions : [embedded.extensions];
        } else if (data?.data) {
            list = Array.isArray(data.data) ? data.data : [data.data];
        } else if (data?.extensions) {
            list = Array.isArray(data.extensions) ? data.extensions : [data.extensions];
        } else if (Array.isArray(data)) {
            list = data;
        }

        return list.map(item => {
            const userName = item.user ? `${item.user.first_name || ''} ${item.user.last_name || ''}`.trim() : '';
            return {
                extension_number: String(item.extension_number || item.extension || ''),
                caller_id: item.caller_id || item.caller_id_name || userName || `Ext ${item.extension_number}`,
                dnd_enabled: Boolean(item.dnd_enabled || item.dnd_status),
                external_id: item.external_id || null,
                phone_numbers: item.dids || item.phone_numbers || []
            };
        }).filter(ext => ext.extension_number);
    } catch (error) {
        console.error('[TelephonyService] Error fetching extensions:', error.response?.data || error.message);
        throw new Error(`Failed to fetch telephony extensions: ${extractErrorMessage(error)}`);
    }
};

/**
 * Log call notes and convert into formal Lead Follow-up record
 */
export const logFollowUpFromCall = async (callLogId, { notes, status, nextFollowUpDate, stage, userId }) => {
    const callLog = await callLogModel.findById(callLogId);
    if (!callLog) {
        throw new Error("Call log not found");
    }

    const lead = await leadModel.findById(callLog.leadId);
    if (!lead) {
        throw new Error("Associated lead not found");
    }

    // Update Call Log notes and disposition
    callLog.notes = notes || callLog.notes;
    callLog.disposition = status || 'Completed';
    await callLog.save();

    // Append follow-up in lead followUps array
    const followUpEntry = {
        notes: notes || `Call session (${callLog.durationSeconds || 0}s duration, status: ${callLog.status})`,
        followUpDate: new Date(),
        followUpType: 'Call',
        status: status || 'Completed',
        nextFollowUpDate: nextFollowUpDate ? new Date(nextFollowUpDate) : null,
        createdAt: new Date()
    };

    lead.followUps.push(followUpEntry);
    if (stage) {
        lead.stage = stage;
    }
    await lead.save();

    return {
        callLog,
        lead
    };
};

export default {
    isConfigured,
    cleanPhoneNumber,
    initiateClickToDial,
    getCallStatus,
    terminateCall,
    getAccountExtensions,
    logFollowUpFromCall
};
