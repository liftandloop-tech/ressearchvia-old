import 'dotenv/config';
import express from "express"
import http from "http"
import bodyParser from "body-parser"
import helmet from "helmet"
import dotenv from "dotenv"
import cors from "cors"
import MONGO_CLIENT from "./app/config/db.config.js"
import initRoutes from "./app/routes/index.js"
import logoutCronJob from "./app/config/crons.js"
import planCronJob from "./app/config/planCrons.js"
import segmentCronJob from "./app/config/segmentCron.js"
import partialCronJob from "./app/config/partialCrons.js"
import { initScheduler } from "./app/config/scheduledNotificationCron.js";

dotenv.config();
const app = express();
const PORT = process.env.PORT || 8080;
var corsOptions = {
    origin: process.env.ALLOW_ACCESS_ORIGIN,
};

import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

app.use(express.urlencoded({ extended: true, limit: '50mb' }));
app.use(cors(corsOptions));
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
initRoutes(app)
logoutCronJob()
planCronJob()
segmentCronJob()
partialCronJob()
initScheduler();
let server = http.createServer(app)

server.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running at:`)
    console.log(`- Local:   http://localhost:${PORT}`)
    console.log(`- Network: http://192.168.29.90:${PORT}`)
})
