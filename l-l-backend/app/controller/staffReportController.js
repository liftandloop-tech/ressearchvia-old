import staffAttendanceModel from "../models/staffAttendanceModel.js";
import leadModel from "../models/leadModel.js";
import staffModel from "../models/staffModel.js";

const staffReportController = {
    getAttendanceReport: async (req, res) => {
        try {
            const { startDate, endDate, staffId } = req.query;
            const filter = {};

            if (staffId) {
                filter.staffId = staffId;
            }
            if (startDate || endDate) {
                filter.loginTime = {};
                if (startDate) filter.loginTime.$gte = new Date(startDate);
                if (endDate) filter.loginTime.$lte = new Date(endDate);
            }

            const records = await staffAttendanceModel.find(filter)
                .populate('staffId', 'fullName staffId emailAddress mobileNumber deparment')
                .sort({ loginTime: -1 });

            res.status(200).send({ status: 200, message: "Attendance report fetched", data: { records } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    getConversionReport: async (req, res) => {
        try {
            const performance = await leadModel.aggregate([
                {
                    $group: {
                        _id: "$assignedRM",
                        totalLeads: { $sum: 1 },
                        convertedLeads: {
                            $sum: { $cond: [{ $eq: ["$stage", "Converted"] }, 1, 0] }
                        }
                    }
                },
                {
                    $lookup: {
                        from: "staffs",
                        localField: "_id",
                        foreignField: "_id",
                        as: "staffDetails"
                    }
                },
                { $unwind: { path: "$staffDetails", preserveNullAndEmptyArrays: true } },
                {
                    $project: {
                        _id: 1,
                        totalLeads: 1,
                        convertedLeads: 1,
                        conversionRate: {
                            $cond: [
                                { $gt: ["$totalLeads", 0] },
                                { $multiply: [{ $divide: ["$convertedLeads", "$totalLeads"] }, 100] },
                                0
                            ]
                        },
                        staffName: "$staffDetails.fullName",
                        staffId: "$staffDetails.staffId",
                        department: "$staffDetails.deparment"
                    }
                }
            ]);

            res.status(200).send({ status: 200, message: "Conversion report fetched", data: { performance } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    getPerformanceOverview: async (req, res) => {
        try {
            // Aggregated working hours per staff
            const attendanceStats = await staffAttendanceModel.aggregate([
                {
                    $group: {
                        _id: "$staffId",
                        totalMinutes: { $sum: "$totalWorkingMinutes" },
                        sessionsCount: { $sum: 1 }
                    }
                }
            ]);

            // Aggregated conversions
            const leadStats = await leadModel.aggregate([
                {
                    $group: {
                        _id: "$assignedRM",
                        totalLeads: { $sum: 1 },
                        convertedLeads: {
                            $sum: { $cond: [{ $eq: ["$stage", "Converted"] }, 1, 0] }
                        }
                    }
                }
            ]);

            const staffList = await staffModel.find({ status: 'Active' }, 'fullName staffId deparment');

            const overview = staffList.map(staff => {
                const att = attendanceStats.find(a => a._id.toString() === staff._id.toString()) || { totalMinutes: 0, sessionsCount: 0 };
                const ld = leadStats.find(l => l._id && l._id.toString() === staff._id.toString()) || { totalLeads: 0, convertedLeads: 0 };

                return {
                    staffId: staff.staffId,
                    fullName: staff.fullName,
                    department: staff.deparment,
                    totalWorkingHours: Math.round((att.totalMinutes / 60) * 10) / 10,
                    sessionsCount: att.sessionsCount,
                    totalLeads: ld.totalLeads,
                    convertedLeads: ld.convertedLeads,
                    conversionRate: ld.totalLeads > 0 ? Math.round((ld.convertedLeads / ld.totalLeads) * 100) : 0
                };
            });

            res.status(200).send({ status: 200, message: "Performance overview fetched", data: { overview } });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    }
};

export default staffReportController;
