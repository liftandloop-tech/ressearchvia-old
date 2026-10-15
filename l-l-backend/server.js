import 'dotenv/config';
import express from "express"
import http from "http"
import helmet from "helmet"
import cors from "cors"
import MONGO_CLIENT from "./app/config/db.config.js"
import initRoutes from "./app/routes/index.js"
import logoutCronJob from "./app/config/crons.js"
import planCronJob from "./app/config/planCrons.js"
import segmentCronJob from "./app/config/segmentCron.js"
import partialCronJob from "./app/config/partialCrons.js"
import { initScheduler } from "./app/config/scheduledNotificationCron.js";
import departmentModel from "./app/models/departmentModel.js";
import roleModel from "./app/models/roleModel.js";
import permissionGroupModel from "./app/models/permissionGroupModel.js";
import userModel from "./app/models/userModel.js";

const app = express();
const PORT = process.env.PORT || 8080;

import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Preflight & CORS handling
const explicitOrigins = [
    // New frontend URL
    'https://spios.coolify.researchvia.in',
    // Old frontend URLs & portals
    'https://spadmin.researchvia.in',
    'https://admintest.researchvia.in',
    'https://researchvia.in',
    'https://www.researchvia.in',
    'https://tradetest.researchvia.in',
    'https://api.researchvia.in',
    'https://test.researchvia.in',
    // Local development origins
    'http://localhost:3000',
    'http://localhost:8080',
    'http://localhost:5173',
    'http://localhost:4000',
    'http://localhost:8000',
    'http://localhost:8088',
    'http://localhost',
    'http://127.0.0.1:3000',
    'http://127.0.0.1:8080',
    'http://127.0.0.1:5173',
];

const envOriginStr = process.env.ALLOW_ACCESS_ORIGIN || '*';
const configuredOrigins = [
    ...explicitOrigins,
    ...(process.env.FRONTEND_URL ? [process.env.FRONTEND_URL.trim().replace(/^['"]|['"]$/g, '').replace(/\/+$/, '')] : []),
    ...envOriginStr.split(',').map(s => s.trim().replace(/^['"]|['"]$/g, '')).filter(Boolean)
];

const isOriginAllowed = (origin) => {
    if (!origin) return true; // Non-browser / curl / mobile apps
    if (envOriginStr === '*' || configuredOrigins.includes('*')) return true;
    if (configuredOrigins.includes(origin)) return true;
    // Allow subdomains of researchvia.in (e.g. *.coolify.researchvia.in, *.researchvia.in)
    if (/^https?:\/\/([a-z0-9-]+\.)*researchvia\.in(:[0-9]+)?$/i.test(origin)) return true;
    // Allow localhost / local IP patterns
    if (/^https?:\/\/(localhost|127\.0\.0\.1)(:[0-9]+)?$/i.test(origin)) return true;
    return true; // Fallback permissive so valid clients connect
};

const defaultAllowedHeaders = [
    'Content-Type',
    'Authorization',
    'authorization',
    'X-Requested-With',
    'Accept',
    'Origin',
    'Range',
    'x-platform',
    'device-id',
    'X-Platform',
    'Device-Id',
    'x-digio-signature',
    'x-razorpay-signature',
    'sentry-trace',
    'baggage',
    'Cache-Control',
    'Pragma',
];

const corsOptionsDelegate = (req, callback) => {
    const origin = req.headers.origin;
    const reqHeaders = req.headers['access-control-request-headers'];

    // Dynamically include whatever headers the client requested in preflight
    let allowedHeaders = defaultAllowedHeaders;
    if (reqHeaders) {
        const requestedList = reqHeaders.split(',').map(h => h.trim());
        allowedHeaders = Array.from(new Set([...defaultAllowedHeaders, ...requestedList]));
    }

    callback(null, {
        origin: isOriginAllowed(origin) ? (origin || true) : false,
        credentials: true,
        methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
        allowedHeaders,
        exposedHeaders: ['Content-Range', 'X-Content-Range', 'Content-Disposition'],
        maxAge: 86400,
        optionsSuccessStatus: 200,
    });
};

app.use(cors(corsOptionsDelegate));

// Explicit preflight handler to prevent Caddy / proxy / gateway header dropping
app.use((req, res, next) => {
    if (req.method === 'OPTIONS') {
        const origin = req.headers.origin;
        if (origin && isOriginAllowed(origin)) {
            res.header('Access-Control-Allow-Origin', origin);
            res.header('Access-Control-Allow-Credentials', 'true');
        } else {
            res.header('Access-Control-Allow-Origin', origin || '*');
            res.header('Access-Control-Allow-Credentials', 'true');
        }
        res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS');

        const reqHeaders = req.headers['access-control-request-headers'];
        if (reqHeaders) {
            res.header('Access-Control-Allow-Headers', reqHeaders);
        } else {
            res.header('Access-Control-Allow-Headers', defaultAllowedHeaders.join(', '));
        }

        res.header('Access-Control-Max-Age', '86400');
        res.header('Vary', 'Origin, Access-Control-Request-Headers');
        return res.sendStatus(200);
    }
    next();
});

app.use(express.urlencoded({ extended: true, limit: '50mb' }));
// app.use(express.urlencoded({ extended: false, limit: '50mb' })); // Removed duplicate
app.use(express.json({
    limit: '50mb',
    // We keep verify here just in case you ever want to secure it again
    verify: (req, res, buf) => {
        req.rawBody = buf.toString();
    }
}));
app.use(helmet({ 
    crossOriginResourcePolicy: false,
    contentSecurityPolicy: false,
    frameguard: false, // Allow framing for PDF previews
})); 

app.use('/uploads', (req, res, next) => {
    const origin = req.headers.origin;
    if (origin && isOriginAllowed(origin)) {
        res.header("Access-Control-Allow-Origin", origin);
        res.header("Access-Control-Allow-Credentials", "true");
    } else {
        res.header("Access-Control-Allow-Origin", "*");
    }
    res.header("Access-Control-Allow-Methods", "GET, OPTIONS");
    const reqHeaders = req.headers['access-control-request-headers'];
    res.header("Access-Control-Allow-Headers", reqHeaders || defaultAllowedHeaders.join(', '));
    res.header("Access-Control-Expose-Headers", "Content-Length, Content-Range");
    
    // Explicitly handle OPTIONS preflight for static assets
    if (req.method === 'OPTIONS') {
        return res.sendStatus(200);
    }
    next();
}, express.static(path.join(__dirname, 'app/uploads'), {
    setHeaders: (res, path) => {
        res.set('Access-Control-Allow-Origin', '*');
    }
}));
//dbconnect
await MONGO_CLIENT();

// Ensure default RBAC (Admin department, permission groups, and roles) exists
try {
    const adminDept = await departmentModel.findOne({ code: 'ADMIN' });
    const adminRole = await roleModel.findOne({ name: 'Admin' });
    const adminGroup = await permissionGroupModel.findOne({ name: 'admin' });
    if (!adminDept || !adminRole || !adminGroup || adminDept.name !== 'Admin') {
        console.log('[BOOTSTRAP] Default Admin RBAC incomplete or needs sync. Running seedCompleteRBAC...');
        const { seedCompleteRBAC } = await import("./seed_complete_rbac.js");
        await seedCompleteRBAC();
    }
    // Self-heal primary super admin accounts to ensure userType & role are super_admin
    await userModel.updateMany(
        { email: { $in: ['support@futurepride.in', 'admin@futurepride.in'] } },
        { $set: { userType: 'super_admin', role: 'super_admin', adminAccessGranted: true } }
    );
} catch (rbacErr) {
    console.warn('[BOOTSTRAP] RBAC auto-seed / admin bootstrap check warning:', rbacErr.message);
}

initRoutes(app)
logoutCronJob()
planCronJob()
segmentCronJob()
partialCronJob()
initScheduler();
let server = http.createServer(app)

process.on('unhandledRejection', (reason, promise) => {
    console.error('[FATAL PROCESS GUARD] Unhandled Rejection at:', promise, 'reason:', reason);
});

process.on('uncaughtException', (err, origin) => {
    console.error(`[FATAL PROCESS GUARD] Uncaught Exception (${origin}):`, err);
});

server.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running at:`)
    console.log(`- Local:   http://localhost:${PORT}`)
    console.log(`- Network: http://192.168.29.90:${PORT}`)
})

