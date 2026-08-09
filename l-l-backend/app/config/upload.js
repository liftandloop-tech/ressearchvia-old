import multer from "multer";
import path from "path";
import fs from "fs";

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    let type = req.uploadType || req.query.type;
    if (!type) {
      if (req.originalUrl.includes("pancard-upload")) type = "pancard";
      else if (req.originalUrl.includes("aadhaar-upload")) type = "aadhaar";
      else if (req.originalUrl.includes("image-change")) type = "image";
      else if (req.originalUrl.includes("upload-qr")) type = "image";
      else if (req.originalUrl.includes("kyc-video-upload")) type = "kyc-video";
      else if (req.originalUrl.includes("upload-proof")) type = "payment-proof";
      else if (req.originalUrl.includes("update-payment")) type = "payment-proof";
    }

    let uploadPath = "app/uploads/";
    if (type === "image") {
      uploadPath = "app/uploads/image"
    } else if (type === "pancard" || type === "pan" || type === "nism" || type === "education" || type === "photo" || type === "resume") {
      uploadPath = "app/uploads/kycimg"
    } else if (type === 'aadhaar') {
      uploadPath = "app/uploads/kycimg"
    } else if (type === 'report') {
      uploadPath = "app/uploads/reports"
    } else if (type === 'bulk-import') {
      uploadPath = "app/uploads/temp"
    } else if (type === 'kyc-video' || type === 'staff-video') {
      uploadPath = "app/uploads/kycvid"
    } else if (type === 'payment-proof') {
      uploadPath = "app/uploads/receipts"
    }

    // Ensure directory exists
    if (!fs.existsSync(uploadPath)) {
      fs.mkdirSync(uploadPath, { recursive: true });
    }

    cb(null, uploadPath);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + "-" + uniqueSuffix + path.extname(file.originalname));
  },
});

const fileFilter = (req, file, cb) => {
  console.log("DEBUG: fileFilter called");
  console.log("DEBUG: req.originalUrl:", req.originalUrl);
  console.log("DEBUG: req.query BEFORE logic:", req.query);
  console.log("DEBUG: File:", file.originalname, file.mimetype);

  // Use req.uploadType (set by route middleware) first, then fall back
  let uploadType = req.uploadType || req.query.type;

  if (!uploadType) {
    if (req.originalUrl && req.originalUrl.includes("pancard-upload")) {
      uploadType = "pancard";
    }
    else if (req.originalUrl && req.originalUrl.includes("aadhaar-upload")) {
      uploadType = "aadhaar";
    }
    else if (req.originalUrl && req.originalUrl.includes("image-change")) {
      uploadType = "image";
    }
    else if (req.originalUrl && req.originalUrl.includes("upload-qr")) {
      uploadType = "image";
    }
    else if (req.originalUrl && req.originalUrl.includes("kyc-video-upload")) {
      uploadType = "kyc-video";
    }
    else if (req.originalUrl && req.originalUrl.includes("upload-proof")) {
      uploadType = "payment-proof";
    }
    else if (req.originalUrl && req.originalUrl.includes("update-payment")) {
      uploadType = "payment-proof";
    }
  }
  console.log("DEBUG: uploadType resolved to:", uploadType);

  let allowedTypes = ''
  if (uploadType === "image") {
    allowedTypes = /jpeg|jpg|png|gif|bmp|webp/;
  } else if (uploadType === "pancard" || uploadType === "pan" || uploadType === "nism" || uploadType === "education" || uploadType === "aadhaar" || uploadType === "photo" || uploadType === "resume") {
    allowedTypes = /jpeg|jpg|png|gif|bmp|webp|pdf/;
  } else if (uploadType === "report") {
    allowedTypes = /pdf|png|jpg|jpeg|gif|webp/;
  }
  else if (uploadType === "bulk-import") {
    allowedTypes = /csv|xls|xlsx/;
  }
  else if (uploadType === "kyc-video" || uploadType === "staff-video") {
    allowedTypes = /mp4|mov|avi|mkv|3gp|webm/;
  }
  else if (uploadType === "payment-proof") {
    allowedTypes = /jpeg|jpg|png|gif|bmp|webp|pdf/;
  }
  else {
    return cb(new Error("Invalid upload type"));
  }
  const ext = path.extname(file.originalname).toLowerCase();
  if (allowedTypes.test(ext)) {
    cb(null, true);
  } else if (uploadType === "image" && file.mimetype && (file.mimetype.startsWith("image/") || file.mimetype === "application/octet-stream")) {
    cb(null, true);
  } else {
    return cb(new Error("Invalid upload type: " + file.originalname + " (" + file.mimetype + ")"));
  }
};

const upload = multer({ storage: storage, fileFilter: fileFilter });

export default upload;
