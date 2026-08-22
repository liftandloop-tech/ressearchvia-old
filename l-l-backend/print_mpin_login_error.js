import axios from "axios";

async function run() {
    try {
        console.log("Sending MPIN login request for ABHISHEK OJHA...");
        const response = await axios.post("http://localhost:8080/api/staff/staff-mpin-login", {
            phone: "919669192889",
            mpin: "1111"
        });
        console.log("Response Status:", response.status);
        console.log("Response Body:", response.data);
    } catch (e) {
        console.log("API Request Failed with Status:", e.response?.status);
        console.log("Headers:", e.response?.headers);
        console.log("Body:", e.response?.data);
    }
}
run();
