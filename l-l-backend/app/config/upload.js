import multer from "multer";
import path from "path";
import fs from "fs";
import crypto from "crypto";

/**
 * STRICT SECURITY CONFIGURATION:
 * 1. Dual Extension Protection (e.g. .jpg.php, .php.jpg, .exe.pdf)
 * 2. Trojan, WebShell & Executable Binary Signature Detection (MZ, ELF, Mach-O, Shebang, PHP, ASP, JSP)
 * 3. Database Injection Safety (SQL, NoSQL, Path Traversal, and XSS sanitization in filenames)
 * 4. Magic Byte Verification for legitimate images, PDFs, spreadsheets, and media
 */

// Extensions that must NEVER appear anywhere in the filename
const FORBIDDEN_EXTENSIONS = new Set([
  // Executable / Binary / Dynamic libraries
  'exe', 'dll', 'so', 'dylib', 'bin', 'com', 'cmd', 'bat', 'scr', 'cpl', 'msc', 'msi', 'msp', 'reg', 'drv', 'sys',
  // Shell scripts & automation
  'sh', 'bash', 'zsh', 'csh', 'ksh', 'ps1', 'ps1xml', 'ps2', 'ps2xml', 'psc1', 'psc2', 'vbs', 'vbe', 'wsf', 'wsh', 'inf', 'scf', 'hta',
  // PHP variants
  'php', 'phtml', 'php2', 'php3', 'php4', 'php5', 'php6', 'php7', 'php8', 'phps', 'phar', 'pgif', 'pht', 'phtm', 'inc',
  // ASP / .NET / IIS
  'asp', 'aspx', 'axd', 'asx', 'ashx', 'asmx', 'cer', 'csr', 'config', 'asa', 'asax',
  // Java / JSP
  'jsp', 'jspx', 'jsw', 'jsv', 'jspa', 'jar', 'war', 'ear', 'class', 'action', 'do',
  // Python / Ruby / Perl / CGI
  'py', 'pyc', 'pyd', 'pyo', 'pyw', 'rb', 'pl', 'pm', 'cgi',
  // Web / Script injection / SVG (can contain <script> XSS)
  'htm', 'html', 'shtm', 'shtml', 'xhtml', 'xht', 'svg', 'xml', 'js', 'mjs', 'cjs', 'ts',
  // Server config / sensitive dotfiles
  'htaccess', 'htpasswd', 'env', 'ini', 'conf', 'yml', 'yaml', 'toml',
]);

// Known legitimate file extensions for dual-extension detection
const KNOWN_FILE_EXTENSIONS = new Set([
  'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'pdf', 'csv', 'xls', 'xlsx',
  'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp', 'zip', 'rar', 'tar', 'gz',
  'doc', 'docx', 'ppt', 'pptx', 'txt'
]);

// Allowed extensions per upload category
const ALLOWED_EXTENSIONS_BY_TYPE = {
  'image': ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'],
  'pancard': ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'pdf'],
  'pan': ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'pdf'],
  'aadhaar': ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'pdf'],
  'nism': ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'pdf'],
  'education': ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'pdf'],
  'photo': ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'],
  'resume': ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'pdf'],
  'serviceAgreement': ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'pdf'],
  'agreement': ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'pdf'],
  'signedDocument': ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'pdf'],
  'report': ['pdf', 'png', 'jpg', 'jpeg', 'gif', 'webp'],
  'bulk-import': ['csv', 'xls', 'xlsx'],
  'kyc-video': ['mp4', 'mov', 'avi', 'mkv', '3gp', 'webm'],
  'staff-video': ['mp4', 'mov', 'avi', 'mkv', '3gp', 'webm'],
  'payment-proof': ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'pdf'],
};

/**
 * Sanitize filename to prevent:
 * - SQL Injection (quotes, comments, semicolons)
 * - NoSQL Injection (dollar operators, JSON curly braces)
 * - Path Traversal (../, \, /, null bytes)
 * - Stored XSS (<script>, <svg>, HTML tags)
 * - Command Injection ($, `, ;, |, &)
 */
export function sanitizeFilename(originalName) {
  if (!originalName || typeof originalName !== 'string') return 'document';

  // 1. Extract base name to eliminate directory traversal paths
  let clean = path.basename(originalName);

  // 2. Strip null bytes and control characters (ASCII 0-31, 127-159)
  clean = clean.replace(/[\x00-\x1f\x7f-\x9f\0%00]/g, '');

  // 3. Strip SQL/NoSQL/XSS/Command injection characters
  clean = clean.replace(/['"`$;{}<>[\]\\|&*^~#%+!:=]/g, '');

  // 4. Collapse consecutive dots and replace whitespace with underscores
  clean = clean.replace(/\.{2,}/g, '.').replace(/\s+/g, '_');

  // 5. Allow only safe characters: [a-zA-Z0-9._-]
  clean = clean.replace(/[^a-zA-Z0-9._-]/g, '');

  // 6. Enforce safe length limit (max 80 chars) to prevent column overflow
  if (clean.length > 80) {
    const ext = path.extname(clean);
    const base = path.basename(clean, ext);
    clean = base.substring(0, 80 - ext.length) + ext;
  }

  // 7. Ensure not empty or dot-only
  if (!clean || clean.replace(/\./g, '').trim().length === 0) {
    clean = 'document';
  }

  return clean;
}

/**
 * Validates filename against dual-extensions, null bytes, and dangerous scripts
 */
function validateFilenameSafety(originalName) {
  if (!originalName || typeof originalName !== 'string') return;

  // Null byte or newline injection
  if (/[\0\r\n]|%00/i.test(originalName)) {
    throw new Error('Security violation: Null byte or newline injection detected in filename.');
  }

  // Path traversal sequence
  if (/[\/\\]|\.\./.test(originalName)) {
    throw new Error('Security violation: Path traversal sequence detected in filename.');
  }

  const clean = originalName.toLowerCase().replace(/[^a-z0-9._-]/g, '');
  const parts = clean.split('.').filter(Boolean);
  if (parts.length === 0) return;

  // Check every segment for forbidden dangerous extensions
  for (const part of parts) {
    if (FORBIDDEN_EXTENSIONS.has(part)) {
      throw new Error(`Security violation: Forbidden dangerous extension detected ('${part}').`);
    }
  }

  // Dual extension detection (e.g. image.jpg.php, document.pdf.exe, file.png.jpg)
  if (parts.length > 2) {
    const intermediateParts = parts.slice(1, -1);
    for (const part of intermediateParts) {
      if (KNOWN_FILE_EXTENSIONS.has(part)) {
        throw new Error(`Security violation: Suspicious dual file extension detected ('${part}.${parts[parts.length - 1]}').`);
      }
    }
  }
}

/**
 * Helper to resolve upload type consistently across destination and fileFilter
 */
function resolveUploadType(req) {
  let uploadType = req.uploadType || req.query?.type || req.query?.docType;
  if (!uploadType) {
    if (req.originalUrl && req.originalUrl.includes("pancard-upload")) uploadType = "pancard";
    else if (req.originalUrl && req.originalUrl.includes("aadhaar-upload")) uploadType = "aadhaar";
    else if (req.originalUrl && req.originalUrl.includes("image-change")) uploadType = "image";
    else if (req.originalUrl && req.originalUrl.includes("upload-qr")) uploadType = "image";
    else if (req.originalUrl && req.originalUrl.includes("kyc-video-upload")) uploadType = "kyc-video";
    else if (req.originalUrl && req.originalUrl.includes("upload-proof")) uploadType = "payment-proof";
    else if (req.originalUrl && req.originalUrl.includes("update-payment")) uploadType = "payment-proof";
    else if (req.originalUrl && req.originalUrl.includes("update-file")) {
      if (req.originalUrl.includes("serviceAgreement") || req.originalUrl.includes("agreement") || req.originalUrl.includes("signedDocument")) {
        uploadType = "serviceAgreement";
      } else if (req.originalUrl.includes("docType=video")) {
        uploadType = "kyc-video";
      } else {
        uploadType = "pancard";
      }
    }
  }
  return uploadType;
}

/**
 * Safely derives an allowed extension from MIME type and upload type
 */
function deriveSafeExtension(mimetype, uploadType) {
  const mime = (mimetype || '').toLowerCase();
  const isVideo = (uploadType === 'kyc-video' || uploadType === 'staff-video');

  if (mime.includes('pdf')) return '.pdf';
  if (mime.includes('png')) return '.png';
  if (mime.includes('webp')) return '.webp';
  if (mime.includes('gif')) return '.gif';
  if (mime.includes('bmp')) return '.bmp';
  if (mime.includes('video') || mime.includes('mp4')) return '.mp4';
  if (mime.includes('quicktime') || mime.includes('mov')) return '.mov';
  if (mime.includes('csv')) return '.csv';
  if (mime.includes('spreadsheet') || mime.includes('excel') || mime.includes('xlsx')) return '.xlsx';
  if (mime.includes('image') || mime.includes('jpeg') || mime.includes('jpg')) return '.jpg';

  return isVideo ? '.mp4' : '.jpg';
}

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const type = resolveUploadType(req);

    let uploadPath = "app/uploads/";
    if (type === "image") {
      uploadPath = "app/uploads/image";
    } else if (type === "pancard" || type === "pan" || type === "nism" || type === "education" || type === "photo" || type === "resume" || type === "serviceAgreement" || type === "agreement" || type === "signedDocument" || type === 'aadhaar') {
      uploadPath = "app/uploads/kycimg";
    } else if (type === 'report') {
      uploadPath = "app/uploads/reports";
    } else if (type === 'bulk-import') {
      uploadPath = "app/uploads/temp";
    } else if (type === 'kyc-video' || type === 'staff-video') {
      uploadPath = "app/uploads/kycvid";
    } else if (type === 'payment-proof') {
      uploadPath = "app/uploads/receipts";
    }

    if (!fs.existsSync(uploadPath)) {
      fs.mkdirSync(uploadPath, { recursive: true });
    }

    cb(null, uploadPath);
  },
  filename: function (req, file, cb) {
    const uploadType = resolveUploadType(req);
    const uniqueSuffix = Date.now() + "-" + crypto.randomBytes(6).toString('hex');
    const cleanFieldname = (file.fieldname || 'doc').replace(/[^a-zA-Z0-9_-]/g, '') || 'doc';

    // Sanitize the originalname directly on the file object for DB and logging safety
    file.originalname = sanitizeFilename(file.originalname);

    let rawExt = path.extname(file.originalname).toLowerCase();
    const allowed = ALLOWED_EXTENSIONS_BY_TYPE[uploadType] || [];

    let safeExt = '';
    if (rawExt && allowed.includes(rawExt.replace('.', ''))) {
      safeExt = rawExt;
    } else {
      safeExt = deriveSafeExtension(file.mimetype, uploadType);
    }

    cb(null, `${cleanFieldname}-${uniqueSuffix}${safeExt}`);
  },
});

const fileFilter = (req, file, cb) => {
  try {
    // 1. Filename safety check (dual extension, path traversal, null bytes, dangerous scripts)
    validateFilenameSafety(file.originalname);

    // 2. Resolve and validate upload type
    const uploadType = resolveUploadType(req);
    if (!uploadType || !ALLOWED_EXTENSIONS_BY_TYPE[uploadType]) {
      return cb(new Error("Invalid upload type: " + (uploadType || "unknown")));
    }

    const allowed = ALLOWED_EXTENSIONS_BY_TYPE[uploadType];
    const ext = path.extname(file.originalname).toLowerCase().replace('.', '');
    const mime = (file.mimetype || '').toLowerCase();

    const isVideoType = (uploadType === "kyc-video" || uploadType === "staff-video");
    const isDocOrImageType = (uploadType !== "kyc-video" && uploadType !== "staff-video" && uploadType !== "bulk-import");
    const isBulkImport = (uploadType === "bulk-import");

    // If extension is present, it must be in the whitelist
    if (ext && allowed.includes(ext)) {
      return cb(null, true);
    }

    // For camera/blob captures where extension might be omitted
    if (!ext) {
      if (isDocOrImageType && (mime.startsWith("image/") || mime.includes("pdf") || mime === "application/octet-stream")) {
        return cb(null, true);
      }
      if (isVideoType && (mime.startsWith("video/") || mime === "application/octet-stream")) {
        return cb(null, true);
      }
      if (isBulkImport && (mime.includes("csv") || mime.includes("excel") || mime.includes("sheet"))) {
        return cb(null, true);
      }
    }

    return cb(new Error(`Invalid file type for ${uploadType}: ${file.originalname} (${file.mimetype})`));
  } catch (err) {
    return cb(err);
  }
};

/**
 * Deep File Content Inspection:
 * Inspects file header & magic bytes after write to block Trojans, WebShells, and executable payloads
 */
async function scanAndValidateFile(file, req) {
  if (!file || !file.path) return;
  if (!fs.existsSync(file.path)) return;

  const fd = fs.openSync(file.path, 'r');
  const buffer = Buffer.alloc(4096);
  let bytesRead = 0;
  try {
    bytesRead = fs.readSync(fd, buffer, 0, 4096, 0);
  } finally {
    fs.closeSync(fd);
  }

  if (bytesRead === 0) {
    throw new Error('Security violation: Empty uploaded file.');
  }

  const chunk = buffer.subarray(0, bytesRead);

  // 1. Binary Executable Signatures (MZ, ELF, Mach-O, Shebang)
  // Windows PE (EXE / DLL / SYS / SCR)
  if (bytesRead >= 2 && chunk[0] === 0x4D && chunk[1] === 0x5A) {
    throw new Error('Security violation: Windows executable binary header (MZ) detected.');
  }

  // Linux ELF binary
  if (bytesRead >= 4 && chunk[0] === 0x7F && chunk[1] === 0x45 && chunk[2] === 0x4C && chunk[3] === 0x46) {
    throw new Error('Security violation: Linux ELF binary detected.');
  }

  // Mach-O / Java Class
  if (bytesRead >= 4) {
    const magic32 = chunk.readUInt32BE(0);
    if (magic32 === 0xCAFEBABE || magic32 === 0xFEEDFACE || magic32 === 0xFEEDFACF || magic32 === 0xCEFAEDFE) {
      throw new Error('Security violation: Executable Mach-O / Java bytecode detected.');
    }
  }

  // Executable script shebang (#!)
  if (bytesRead >= 2 && chunk[0] === 0x23 && chunk[1] === 0x21) {
    throw new Error('Security violation: Script shebang (#! executable) detected.');
  }

  // 2. WebShell & Malicious Script Text Patterns
  const contentStr = chunk.toString('utf8').toLowerCase();
  const MALICIOUS_PATTERNS = [
    '<?php',
    '<?=',
    '<script language="php"',
    'eval(base64_decode',
    'eval(gzinflate',
    'passthru(',
    'shell_exec(',
    'system($_',
    'exec($_',
    'assert($_',
    '<%@ page',
    '<jsp:directive',
    '<jsp:scriptlet'
  ];

  for (const pattern of MALICIOUS_PATTERNS) {
    if (contentStr.includes(pattern)) {
      throw new Error(`Security violation: Malicious script pattern detected in file content (${pattern}).`);
    }
  }

  // 3. Magic Byte Verification against file extension
  const ext = (path.extname(file.filename || file.path) || path.extname(file.originalname || '')).toLowerCase();

  if (ext === '.pdf') {
    if (bytesRead < 5 || chunk.toString('ascii', 0, 5) !== '%PDF-') {
      throw new Error('Security violation: Invalid PDF file signature.');
    }
  } else if (ext === '.jpg' || ext === '.jpeg') {
    if (bytesRead < 3 || chunk[0] !== 0xFF || chunk[1] !== 0xD8 || chunk[2] !== 0xFF) {
      throw new Error('Security violation: Invalid JPEG file signature.');
    }
  } else if (ext === '.png') {
    if (bytesRead < 8 || chunk[0] !== 0x89 || chunk[1] !== 0x50 || chunk[2] !== 0x4E || chunk[3] !== 0x47) {
      throw new Error('Security violation: Invalid PNG file signature.');
    }
  } else if (ext === '.gif') {
    const gifHeader = chunk.toString('ascii', 0, 6);
    if (gifHeader !== 'GIF87a' && gifHeader !== 'GIF89a') {
      throw new Error('Security violation: Invalid GIF file signature.');
    }
  } else if (ext === '.webp') {
    if (bytesRead < 12 || chunk.toString('ascii', 0, 4) !== 'RIFF' || chunk.toString('ascii', 8, 12) !== 'WEBP') {
      throw new Error('Security violation: Invalid WEBP file signature.');
    }
  } else if (ext === '.bmp') {
    if (bytesRead < 2 || chunk[0] !== 0x42 || chunk[1] !== 0x4D) {
      throw new Error('Security violation: Invalid BMP file signature.');
    }
  } else if (ext === '.xlsx') {
    if (bytesRead < 4 || chunk[0] !== 0x50 || chunk[1] !== 0x4B) {
      throw new Error('Security violation: Invalid XLSX file signature.');
    }
  } else if (ext === '.csv') {
    if (chunk.includes(0x00)) {
      throw new Error('Security violation: Binary null byte detected in CSV file.');
    }
  }
}

/**
 * Remove uploaded files if any security violation occurs
 */
function cleanupUploadedFiles(req) {
  try {
    const files = [];
    if (req.file) files.push(req.file);
    if (req.files) {
      if (Array.isArray(req.files)) {
        files.push(...req.files);
      } else if (typeof req.files === 'object') {
        for (const key of Object.keys(req.files)) {
          if (Array.isArray(req.files[key])) {
            files.push(...req.files[key]);
          }
        }
      }
    }
    for (const f of files) {
      if (f && f.path && fs.existsSync(f.path)) {
        try {
          fs.unlinkSync(f.path);
        } catch (_) {}
      }
    }
  } catch (_) {}
}

const baseMulter = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 100 * 1024 * 1024, // 100 MB max
    files: 10,
    fieldNameSize: 100,
    fieldSize: 10 * 1024 * 1024
  }
});

/**
 * Middleware wrapper that executes base multer and immediately runs deep content security scan
 */
function createSecureMiddleware(multerMiddleware) {
  return function (req, res, next) {
    const callback = typeof next === 'function' ? next : () => {};

    multerMiddleware(req, res, async function (err) {
      if (err) {
        cleanupUploadedFiles(req);
        return callback(err);
      }

      try {
        const files = [];
        if (req.file) files.push(req.file);
        if (req.files) {
          if (Array.isArray(req.files)) {
            files.push(...req.files);
          } else if (typeof req.files === 'object') {
            for (const key of Object.keys(req.files)) {
              if (Array.isArray(req.files[key])) {
                files.push(...req.files[key]);
              }
            }
          }
        }

        // Run deep content inspection
        for (const file of files) {
          await scanAndValidateFile(file, req);
        }

        return callback();
      } catch (scanErr) {
        cleanupUploadedFiles(req);
        return callback(scanErr);
      }
    });
  };
}

const upload = {
  single: (field) => createSecureMiddleware(baseMulter.single(field)),
  array: (field, maxCount) => createSecureMiddleware(baseMulter.array(field, maxCount)),
  fields: (fields) => createSecureMiddleware(baseMulter.fields(fields)),
  none: () => createSecureMiddleware(baseMulter.none()),
  any: () => createSecureMiddleware(baseMulter.any()),
};

export default upload;
