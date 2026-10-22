/**
 * Airtel IQ SMS Gateway Configuration & Service
 * Supports /api/v1/send-sms and /api/v1/send-prepaid-sms
 */

const getAirtelConfig = () => {
    const username = (process.env.AIRTEL_SMS_USERNAME || '72c6a4e7_e819_42ce_bf7b_3a166fb99082').trim();
    const password = (process.env.AIRTEL_SMS_PASSWORD || '5L5JNW4PjF').trim();

    let authHeader = (process.env.AIRTEL_SMS_AUTH_HEADER || '').trim();
    if (!authHeader && username && password) {
        authHeader = `Basic ${Buffer.from(`${username}:${password}`).toString('base64')}`;
    }
    if (!authHeader) {
        authHeader = 'Basic NzJjNmE0ZTdfZTgxOV80MmNlX2JmN2JfM2ExNjZmYjk5MDgyOjVMNUpOVzRQakY=';
    }

    return {
        url: (process.env.AIRTEL_SMS_URL || 'https://iqsms.airtel.in/api/v1/send-sms').trim(),
        authHeader,
        username,
        password,
        customerId: (process.env.AIRTEL_SMS_CUSTOMER_ID || '0c1cfe83-ab73-4de5-af3f-4b5776f7213a').trim(),
        dltTemplateId: (process.env.AIRTEL_SMS_DLT_TEMPLATE_ID || '1077306650024919117').trim(),
        entityId: (process.env.AIRTEL_SMS_ENTITY_ID || '1001408907209480917').trim(),
        sourceAddress: (process.env.AIRTEL_SMS_SOURCE_ADDRESS || 'SWATPL').trim(),
        messageType: (process.env.AIRTEL_SMS_MESSAGE_TYPE || 'TRANSACTIONAL').trim(),
        appName: (process.env.AIRTEL_SMS_APP_NAME || 'BizXResearch').trim()
    };
};

// Verified working fallback credentials to prevent OTP outages
const FALLBACK_CREDENTIALS = {
    customerId: '6c717fbf-7e03-4636-831d-dcd452fdbc33',
    entityId: '1001927485480112556',
    authHeader: 'Basic ZjM2MGUzNWRfMTliM180YmM1X2I0YTRfOTlhZmI0ZGVmOGFhOk9Pem93UnpKdE0='
};

/**
 * Normalizes any phone number format to a 10-digit Indian mobile number
 * @param {string|number} phone
 * @returns {string} 10-digit clean mobile number
 */
export const normalizePhone10 = (phone) => {
    if (!phone) return '';
    const digits = phone.toString().replace(/\D/g, '');
    return digits.slice(-10);
};

/**
 * Dispatches HTTP POST to Airtel IQ SMS gateway
 */
const postToAirtel = async (url, authHeader, payload) => {
    const response = await fetch(url, {
        method: 'POST',
        headers: {
            'accept': 'application/json',
            'content-type': 'application/json',
            'Authorization': authHeader
        },
        body: JSON.stringify(payload),
        signal: AbortSignal.timeout(10000)
    });
    const data = await response.json().catch(() => null);
    return { status: response.status, data };
};

/**
 * Sends an OTP SMS via Airtel IQ SMS API
 * Template Name: Login Otp Temp
 * Template Content: "Your OTP to login to {#var#} by SWATPL is {#var#}. Please do not share this OTP with anyone."
 * DLT Template ID: 1077306650024919117
 * Header / Sender: SWATPL
 * Entity ID: 1001408907209480917
 *
 * @param {string|number} phone - Recipient phone number
 * @param {string|number} otp - 4-digit or 6-digit OTP code
 * @param {string} [customAppName] - Optional variable 1 name (defaults to 'BizXResearch')
 * @returns {Promise<{success: boolean, status: number, data?: any, error?: string}>}
 */
export const sendOtpSms = async (phone, otp, customAppName = null) => {
    try {
        const cleanPhone = normalizePhone10(phone);
        if (!cleanPhone || cleanPhone.length !== 10) {
            console.error(`[Airtel IQ SMS] Invalid mobile number: "${phone}"`);
            return { success: false, status: 400, error: 'Invalid phone number' };
        }

        const config = getAirtelConfig();
        const appName = customAppName || config.appName;
        const message = `Your OTP to login to ${appName} by SWATPL is ${otp}. Please do not share this OTP with anyone.`;

        const payload = {
            customerId: config.customerId,
            destinationAddress: cleanPhone,
            dltTemplateId: config.dltTemplateId,
            entityId: config.entityId,
            message: message,
            messageType: config.messageType,
            sourceAddress: config.sourceAddress
        };

        console.log(`[Airtel IQ SMS] Dispatching OTP to ${cleanPhone} via ${config.sourceAddress} (Entity: ${config.entityId}, Template: ${config.dltTemplateId})...`);

        let result = await postToAirtel(config.url, config.authHeader, payload);

        // Self-heal & Fallback handling:
        // If primary attempt fails (e.g. 400 PE-TM hash error or pending DLT sync),
        // fallback to active verified DLT credentials so users never experience OTP downtime.
        if (result.status !== 200 && (config.entityId !== FALLBACK_CREDENTIALS.entityId || config.authHeader !== FALLBACK_CREDENTIALS.authHeader)) {
            console.warn(`[Airtel IQ SMS] Primary attempt returned status ${result.status} (${result.data?.errorMessage || 'Failed'}). Retrying with active verified DLT credentials...`);

            const fallbackPayload = {
                ...payload,
                customerId: FALLBACK_CREDENTIALS.customerId,
                entityId: FALLBACK_CREDENTIALS.entityId
            };

            result = await postToAirtel(config.url, FALLBACK_CREDENTIALS.authHeader, fallbackPayload);
        }

        if (result.status === 200 && result.data) {
            const data = result.data;
            if (data.incorrectNum && data.incorrectNum.includes(cleanPhone)) {
                console.error(`[Airtel IQ SMS] Rejected destination number ${cleanPhone}:`, data);
                return { success: false, status: 400, data, error: 'Recipient number rejected by SMS gateway' };
            }

            console.log(`[Airtel IQ SMS] Successfully dispatched OTP to ${cleanPhone}. Message Request ID: ${data.messageRequestId || 'N/A'}`);
            return { success: true, status: 200, data };
        }

        console.warn(`[Airtel IQ SMS] Gateway response error (${result.status}):`, result.data);
        return { success: false, status: result.status, data: result.data, error: result.data?.errorMessage || 'Gateway error' };
    } catch (error) {
        console.error(`[Airtel IQ SMS] Gateway error for ${phone}:`, error.message);
        return { success: false, status: 500, error: error.message };
    }
};

/**
 * Generic SMS sender supporting fallback if message doesn't match standard OTP format
 */
export const sendSms = async (phone, messageText) => {
    const otpMatch = messageText && messageText.match(/\b\d{4,6}\b/);
    if (otpMatch) {
        return await sendOtpSms(phone, otpMatch[0]);
    }

    const cleanPhone = normalizePhone10(phone);
    const config = getAirtelConfig();
    try {
        const payload = {
            customerId: config.customerId,
            destinationAddress: cleanPhone,
            dltTemplateId: config.dltTemplateId,
            entityId: config.entityId,
            message: messageText,
            messageType: config.messageType,
            sourceAddress: config.sourceAddress
        };
        let result = await postToAirtel(config.url, config.authHeader, payload);
        if (result.status !== 200 && (config.entityId !== FALLBACK_CREDENTIALS.entityId || config.authHeader !== FALLBACK_CREDENTIALS.authHeader)) {
            result = await postToAirtel(config.url, FALLBACK_CREDENTIALS.authHeader, {
                ...payload,
                customerId: FALLBACK_CREDENTIALS.customerId,
                entityId: FALLBACK_CREDENTIALS.entityId
            });
        }
        return { success: result.status === 200, status: result.status, data: result.data };
    } catch (error) {
        console.error(`[Airtel IQ SMS] sendSms error:`, error.message);
        return { success: false, status: 500, error: error.message };
    }
};

export default {
    sendOtpSms,
    sendSms,
    normalizePhone10,
    getAirtelConfig
};
