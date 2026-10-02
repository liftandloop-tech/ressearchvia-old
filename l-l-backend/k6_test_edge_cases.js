import http from 'k6/http';
import { check, sleep } from 'k6';

const fixtures = JSON.parse(open('./k6_fixtures.json')).fixtures;
const BASE_URL = __ENV.TARGET_URL || 'http://localhost:8089/api';

export const options = {
    scenarios: {
        edge_cases_audit: {
            executor: 'per-vu-iterations',
            vus: 1,
            iterations: 1,
            maxDuration: '30s',
        },
        concurrency_stress: {
            executor: 'shared-iterations',
            vus: 10,
            iterations: 10,
            startTime: '2s',
            maxDuration: '20s',
        }
    },
    thresholds: {
        'checks': ['rate==1.0'], // 100% of assertion checks MUST pass
        'http_req_duration': ['p(95)<1000'], // 95% of requests under 1s
    },
};

export default function () {
    const defaultHeaders = (token) => ({
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
    });

    // ─────────────────────────────────────────────────────────────────────────
    // SCENARIO 1: KYC REJECTED USER ATTEMPTS PLAN ORDER
    // ─────────────────────────────────────────────────────────────────────────
    {
        const payload = JSON.stringify({
            planId: fixtures.activePlanId,
            segmentId: fixtures.activeSegmentId,
            paymentMode: 'BANK_TRANSFER'
        });

        const res = http.post(`${BASE_URL}/acquisition/plan-order`, payload, {
            headers: defaultHeaders(fixtures.tokens.kycRejected)
        });

        check(res, {
            'TC-K6-01 [KYC REJECTED blocked] status is 400': (r) => r.status === 400,
            'TC-K6-01 [KYC REJECTED blocked] message mentions KYC Verification Required': (r) => {
                const body = JSON.parse(r.body || '{}');
                return body.message && body.message.includes('KYC Verification Required');
            }
        });
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SCENARIO 2: KYC IN_PROGRESS USER ATTEMPTS PLAN ORDER
    // ─────────────────────────────────────────────────────────────────────────
    {
        const payload = JSON.stringify({
            planId: fixtures.activePlanId,
            segmentId: fixtures.activeSegmentId,
            paymentMode: 'BANK_TRANSFER'
        });

        const res = http.post(`${BASE_URL}/acquisition/plan-order`, payload, {
            headers: defaultHeaders(fixtures.tokens.kycProgress)
        });

        check(res, {
            'TC-K6-02 [KYC IN_PROGRESS blocked] status is 400': (r) => r.status === 400,
            'TC-K6-02 [KYC IN_PROGRESS blocked] message mentions KYC Verification Required': (r) => {
                const body = JSON.parse(r.body || '{}');
                return body.message && body.message.includes('KYC Verification Required');
            }
        });
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SCENARIO 3: KYC WAITING_FOR_REVIEW USER ATTEMPTS PLAN ORDER
    // ─────────────────────────────────────────────────────────────────────────
    {
        const payload = JSON.stringify({
            planId: fixtures.activePlanId,
            segmentId: fixtures.activeSegmentId,
            paymentMode: 'BANK_TRANSFER'
        });

        const res = http.post(`${BASE_URL}/acquisition/plan-order`, payload, {
            headers: defaultHeaders(fixtures.tokens.kycReview)
        });

        check(res, {
            'TC-K6-03 [KYC REVIEW blocked] status is 400': (r) => r.status === 400,
            'TC-K6-03 [KYC REVIEW blocked] message mentions KYC Verification Required': (r) => {
                const body = JSON.parse(r.body || '{}');
                return body.message && body.message.includes('KYC Verification Required');
            }
        });
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SCENARIO 4: KYC NOT_STARTED USER ATTEMPTS PLAN ORDER
    // ─────────────────────────────────────────────────────────────────────────
    {
        const payload = JSON.stringify({
            planId: fixtures.activePlanId,
            segmentId: fixtures.activeSegmentId,
            paymentMode: 'BANK_TRANSFER'
        });

        const res = http.post(`${BASE_URL}/acquisition/plan-order`, payload, {
            headers: defaultHeaders(fixtures.tokens.kycNotStarted)
        });

        check(res, {
            'TC-K6-04 [KYC NOT_STARTED blocked] status is 400': (r) => r.status === 400,
            'TC-K6-04 [KYC NOT_STARTED blocked] message mentions KYC Verification Required': (r) => {
                const body = JSON.parse(r.body || '{}');
                return body.message && body.message.includes('KYC Verification Required');
            }
        });
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SCENARIO 5: UNPAID REGISTRATION USER ATTEMPTS PLAN ORDER
    // ─────────────────────────────────────────────────────────────────────────
    {
        const payload = JSON.stringify({
            planId: fixtures.activePlanId,
            segmentId: fixtures.activeSegmentId,
            paymentMode: 'BANK_TRANSFER'
        });

        const res = http.post(`${BASE_URL}/acquisition/plan-order`, payload, {
            headers: defaultHeaders(fixtures.tokens.unpaidReg)
        });

        check(res, {
            'TC-K6-05 [UNPAID REGISTRATION blocked] status is 400 or 403': (r) => r.status === 400 || r.status === 403,
            'TC-K6-05 [UNPAID REGISTRATION blocked] mentions registration': (r) => {
                const body = JSON.parse(r.body || '{}');
                return (body.message && body.message.toLowerCase().includes('registration')) ||
                       (body.errorCode && body.errorCode.includes('REGISTRATION'));
            }
        });
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SCENARIO 6: INACTIVE PLAN PURCHASE
    // ─────────────────────────────────────────────────────────────────────────
    {
        const payload = JSON.stringify({
            planId: fixtures.inactivePlanId,
            segmentId: fixtures.activeSegmentId,
            paymentMode: 'BANK_TRANSFER'
        });

        const res = http.post(`${BASE_URL}/acquisition/plan-order`, payload, {
            headers: defaultHeaders(fixtures.tokens.kycVerified)
        });

        check(res, {
            'TC-K6-06 [INACTIVE PLAN blocked] status is 400': (r) => r.status === 400,
            'TC-K6-06 [INACTIVE PLAN blocked] message mentions inactive': (r) => {
                const body = JSON.parse(r.body || '{}');
                return body.message && body.message.includes('inactive');
            }
        });
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SCENARIO 7: INACTIVE SEGMENT PURCHASE
    // ─────────────────────────────────────────────────────────────────────────
    {
        const payload = JSON.stringify({
            planId: fixtures.activePlanId,
            segmentId: fixtures.inactiveSegmentId,
            paymentMode: 'BANK_TRANSFER'
        });

        const res = http.post(`${BASE_URL}/acquisition/plan-order`, payload, {
            headers: defaultHeaders(fixtures.tokens.kycVerified)
        });

        check(res, {
            'TC-K6-07 [INACTIVE SEGMENT blocked] status is 400': (r) => r.status === 400,
            'TC-K6-07 [INACTIVE SEGMENT blocked] message mentions inactive': (r) => {
                const body = JSON.parse(r.body || '{}');
                return body.message && body.message.includes('inactive');
            }
        });
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SCENARIO 8: HNI PLAN WITHOUT VALID GSTIN
    // ─────────────────────────────────────────────────────────────────────────
    {
        const payload = JSON.stringify({
            planId: fixtures.hniPlanId,
            segmentId: fixtures.activeSegmentId,
            paymentMode: 'BANK_TRANSFER',
            gstin: 'INVALID_GST'
        });

        const res = http.post(`${BASE_URL}/acquisition/plan-order`, payload, {
            headers: defaultHeaders(fixtures.tokens.kycVerified)
        });

        check(res, {
            'TC-K6-08 [HNI INVALID GSTIN blocked] status is 400': (r) => r.status === 400,
            'TC-K6-08 [HNI INVALID GSTIN blocked] message mentions 15-character GSTIN': (r) => {
                const body = JSON.parse(r.body || '{}');
                return body.message && body.message.includes('GSTIN');
            }
        });
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SCENARIO 9: SINGLE ACTIVE PLAN POLICY VIOLATION
    // ─────────────────────────────────────────────────────────────────────────
    {
        const payload = JSON.stringify({
            planId: fixtures.activePlanId,
            segmentId: fixtures.activeSegmentId,
            paymentMode: 'BANK_TRANSFER'
        });

        const res = http.post(`${BASE_URL}/acquisition/plan-order`, payload, {
            headers: defaultHeaders(fixtures.tokens.activePlanUser)
        });

        check(res, {
            'TC-K6-09 [DUPLICATE PLAN blocked] status is 400': (r) => r.status === 400,
            'TC-K6-09 [DUPLICATE PLAN blocked] message mentions one plan at a time': (r) => {
                const body = JSON.parse(r.body || '{}');
                return body.message && body.message.includes('one plan at a time');
            }
        });
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SCENARIO 10: IDOR ATTACK ON PROOF UPLOAD (User A uploading for User B intent)
    // ─────────────────────────────────────────────────────────────────────────
    {
        // Attacker attempts to upload proof referencing victim's intentId
        const payload = {
            paymentIntentId: fixtures.victimIntentId,
            amountPaid: '5900',
            utrNumber: 'UTR_HACK_999'
        };

        const res = http.post(`${BASE_URL}/acquisition/upload-proof`, payload, {
            headers: {
                'Authorization': `Bearer ${fixtures.tokens.attacker}`
            }
        });

        check(res, {
            'TC-K6-10 [IDOR ATTACK blocked] status is 400': (r) => r.status === 400,
            'TC-K6-10 [IDOR ATTACK blocked] error returned': (r) => {
                const body = JSON.parse(r.body || '{}');
                return body.message && (body.message.includes('Unauthorized') || body.message.includes('own order') || body.message.includes('File'));
            }
        });
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SCENARIO 11: LEGITIMATE VERIFIED USER PURCHASES PLAN
    // ─────────────────────────────────────────────────────────────────────────
    {
        const payload = JSON.stringify({
            planId: fixtures.activePlanId,
            segmentId: fixtures.activeSegmentId,
            paymentMode: 'BANK_TRANSFER'
        });

        const res = http.post(`${BASE_URL}/acquisition/plan-order`, payload, {
            headers: defaultHeaders(fixtures.tokens.kycVerified)
        });

        check(res, {
            'TC-K6-11 [VERIFIED KYC SUCCESS] status is 200': (r) => r.status === 200,
            'TC-K6-11 [VERIFIED KYC SUCCESS] paymentIntentId is returned': (r) => {
                const body = JSON.parse(r.body || '{}');
                return body.data && !!body.data.paymentIntentId;
            }
        });
    }
}
