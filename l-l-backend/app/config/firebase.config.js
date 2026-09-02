import admin from "firebase-admin";
import dotenv from "dotenv";

dotenv.config();

const initializeFirebase = () => {
  if (admin.apps.length) return admin;

  try {
    let serviceAccount;

    // ✅ Preferred: Base64 (Coolify / Docker safe)
    if (process.env.FIREBASE_SERVICE_ACCOUNT_BASE64) {
      const decoded = Buffer.from(
        process.env.FIREBASE_SERVICE_ACCOUNT_BASE64,
        "base64"
      ).toString("utf8");

      serviceAccount = JSON.parse(decoded);
      console.log("Firebase Admin initialized using BASE64 credentials.");

    // ⚠️ Fallback: raw JSON (local only)
    } else if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
      serviceAccount = JSON.parse(
        process.env.FIREBASE_SERVICE_ACCOUNT_JSON
      );

      // Fix private key if escaped
      if (serviceAccount.private_key) {
        serviceAccount.private_key =
          serviceAccount.private_key.replace(/\\n/g, "\n");
      }

      console.log("Firebase Admin initialized using JSON env.");

    } else {
      if (process.env.NODE_ENV === "production") {
        throw new Error("Firebase credentials not provided");
      }
      console.warn("⚠️ Firebase credentials not provided. Skipping Firebase Admin initialization in development mode.");
      return null;
    }

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });

  } catch (error) {
    console.error("❌ Firebase Admin initialization failed:");
    console.error(error.message);
    if (process.env.NODE_ENV === "production") {
      process.exit(1); // fail fast in prod
    }
    return null;
  }

  return admin;
};

const firebaseAdmin = initializeFirebase();
export default firebaseAdmin;

