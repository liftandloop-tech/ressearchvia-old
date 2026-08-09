import staffAttendanceModel from "../models/staffAttendanceModel.js";

const staffAttendanceController = {
    loginSession: async (req, res) => {
        try {
            const { staffId, isRemote, deviceInfo } = req.body;
            if (!staffId) {
                return res.status(400).send({ status: 400, message: "Staff ID is required", data: {} });
            }
            
            // Remote check logic: if not explicitly local or matches configured office IP
            const officeIPs = ['127.0.0.1', '::1', '192.168.1.1'];
            const ip = req.ip || req.connection.remoteAddress;
            const remoteDetected = !officeIPs.includes(ip) || isRemote === true;

            const session = await staffAttendanceModel.create({
                staffId,
                loginTime: new Date(),
                isRemote: remoteDetected,
                deviceInfo: deviceInfo || req.headers['user-agent']
            });

            res.status(200).send({ status: 200, message: "Login recorded successfully", data: { session } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    logoutSession: async (req, res) => {
        try {
            const { sessionId } = req.body;
            if (!sessionId) {
                return res.status(400).send({ status: 400, message: "Session ID is required", data: {} });
            }

            const session = await staffAttendanceModel.findById(sessionId);
            if (!session) {
                return res.status(404).send({ status: 404, message: "Session not found", data: {} });
            }

            session.logoutTime = new Date();
            const diffMs = session.logoutTime - session.loginTime;
            session.totalWorkingMinutes = Math.round(diffMs / 60000);
            await session.save();

            res.status(200).send({ status: 200, message: "Logout recorded successfully", data: { session } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    pingSession: async (req, res) => {
        try {
            const { sessionId, faceDetected } = req.body;
            if (!sessionId) {
                return res.status(400).send({ status: 400, message: "Session ID is required", data: {} });
            }

            const session = await staffAttendanceModel.findById(sessionId);
            if (!session) {
                return res.status(404).send({ status: 404, message: "Session not found", data: {} });
            }

            session.activityLogs.push({
                timestamp: new Date(),
                faceDetected: faceDetected === true || faceDetected === 'true'
            });
            await session.save();

            res.status(200).send({ status: 200, message: "Ping recorded successfully", data: { session } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    getDailyWorkSummary: async (req, res) => {
        try {
            const { staffId } = req.params;
            const startOfDay = new Date();
            startOfDay.setHours(0, 0, 0, 0);

            const sessions = await staffAttendanceModel.find({
                staffId,
                loginTime: { $gte: startOfDay }
            });

            let totalMinutes = 0;
            let faceDetectionFailureCount = 0;
            let totalPings = 0;

            sessions.forEach(s => {
                const end = s.logoutTime || new Date();
                totalMinutes += Math.round((end - s.loginTime) / 60000);
                s.activityLogs.forEach(log => {
                    totalPings++;
                    if (!log.faceDetected) faceDetectionFailureCount++;
                });
            });

            res.status(200).send({
                status: 200,
                message: "Daily work summary retrieved",
                data: {
                    sessionsCount: sessions.length,
                    totalWorkingMinutes: totalMinutes,
                    totalPings,
                    faceDetectionFailureCount,
                    sessions
                }
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    }
};

export default staffAttendanceController;
