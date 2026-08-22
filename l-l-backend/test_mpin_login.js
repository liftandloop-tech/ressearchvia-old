import axios from "axios";

async function run() {
    try {
        console.log("Sending MPIN login request...");
        const response = await axios.post("http://localhost:8080/api/staff/staff-mpin-login", {
            phone: "919669192889",
            mpin: "1234" // assuming 1234 is the mpin, but let's see
        });
        console.log("Response:", response.data);
    } catch (e) {
        console.error("Status:", e.response?.status);
        console.error("Body:", e.response?.data);
    }
}
run();
