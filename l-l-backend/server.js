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
const allowOrigin = process.env.ALLOW_ACCESS_ORIGIN || '*';
const corsOptions = {
    origin: (origin, callback) => {
        // Allow all origins when configured as '*' or unset, otherwise reflect requesting origin
        if (!origin || allowOrigin === '*' || allowOrigin.split(',').map(s => s.trim()).includes(origin)) {
            callback(null, true);
        } else {
            callback(null, true); // Fallback permissive for admin panel domain
        }
    },
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept', 'Origin', 'Range'],
    exposedHeaders: ['Content-Range', 'X-Content-Range', 'Content-Disposition'],
    credentials: true,
};

app.use(cors(corsOptions));

// Explicit preflight handler to prevent Caddy / proxy header dropping
app.use((req, res, next) => {
    if (req.method === 'OPTIONS') {
        res.header('Access-Control-Allow-Origin', req.headers.origin || '*');
        res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS');
        res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Accept, Origin, Range');
        res.header('Access-Control-Allow-Credentials', 'true');
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
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Methods", "GET, OPTIONS");
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept, Authorization, Range");
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

