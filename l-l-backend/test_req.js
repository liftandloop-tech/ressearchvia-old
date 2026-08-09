import jwt from "jsonwebtoken";
import axios from "axios";
import fs from "fs";
import FormData from "form-data";

async function runTest() {
  const token = jwt.sign({ _id: "697b31f3a010e491c162b01f", email: "test@test.com" }, "no_1$32@4#43");
  
  // write a fake image
  fs.writeFileSync("test.img", "fake image content");
  
  const form = new FormData();
  form.append("file", fs.createReadStream("test.img"), {
    filename: "Screenshot 2026-02-07 at 5.35.42â¯PM.png",
    contentType: "application/octet-stream"
  });
  
  try {
    const res = await axios.post("http://localhost:8080/api/settings/upload-qr", form, {
      headers: {
        Authorization: "Bearer " + token,
        ...form.getHeaders()
      }
    });
    console.log(res.status, res.data);
  } catch(e) {
    if (e.response) {
      console.log("Error status:", e.response.status);
      console.log("Error data:", e.response.data);
    } else {
      console.error(e.message);
    }
  }
}
runTest();
