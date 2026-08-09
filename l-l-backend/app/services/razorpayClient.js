import Razorpay from "razorpay";

const instance = {
    client: null
};

export const getRazorpay = () => {
    if (!instance.client) {
        if (process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_ID !== 'test_key') {
            instance.client = new Razorpay({
                key_id: process.env.RAZORPAY_KEY_ID,
                key_secret: process.env.RAZORPAY_KEY_SECRET,
            });
        } else {
            // Return a mock or null if test key
            console.log("Using Mock Razorpay (or not safe to init)");
            instance.client = {
                orders: { create: async () => ({ id: 'mock_order' }) },
                payments: { fetch: async () => ({ status: 'captured' }) }
            }
        }
    }
    return instance.client;
};

// Allow overriding for tests
export const setRazorpay = (mockClient) => {
    instance.client = mockClient;
}
