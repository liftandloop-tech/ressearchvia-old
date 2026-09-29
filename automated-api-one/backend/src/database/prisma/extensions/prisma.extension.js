"use strict";
var __assign = (this && this.__assign) || function () {
    __assign = Object.assign || function(t) {
        for (var s, i = 1, n = arguments.length; i < n; i++) {
            s = arguments[i];
            for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
                t[p] = s[p];
        }
        return t;
    };
    return __assign.apply(this, arguments);
};
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g = Object.create((typeof Iterator === "function" ? Iterator : Object).prototype);
    return g.next = verb(0), g["throw"] = verb(1), g["return"] = verb(2), typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
var __rest = (this && this.__rest) || function (s, e) {
    var t = {};
    for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p) && e.indexOf(p) < 0)
        t[p] = s[p];
    if (s != null && typeof Object.getOwnPropertySymbols === "function")
        for (var i = 0, p = Object.getOwnPropertySymbols(s); i < p.length; i++) {
            if (e.indexOf(p[i]) < 0 && Object.prototype.propertyIsEnumerable.call(s, p[i]))
                t[p[i]] = s[p[i]];
        }
    return t;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.prismaExtension = void 0;
var modelsWithSoftDelete = [
    'User',
    'SegmentMaster',
    'UserSegment',
    'UserBroker',
    'Subscription',
    'Consent',
    'UserDevice',
];
var prismaExtension = function (prisma) {
    return prisma.$extends({
        query: {
            $allModels: {
                delete: function (_a) {
                    return __awaiter(this, arguments, void 0, function (_b) {
                        var modelKey;
                        var model = _b.model, args = _b.args, query = _b.query;
                        return __generator(this, function (_c) {
                            if (modelsWithSoftDelete.includes(model)) {
                                modelKey = model.charAt(0).toLowerCase() + model.slice(1);
                                return [2 /*return*/, prisma[modelKey].update({
                                        where: args.where,
                                        data: { deletedAt: new Date() },
                                    })];
                            }
                            return [2 /*return*/, query(args)];
                        });
                    });
                },
                deleteMany: function (_a) {
                    return __awaiter(this, arguments, void 0, function (_b) {
                        var modelKey;
                        var model = _b.model, args = _b.args, query = _b.query;
                        return __generator(this, function (_c) {
                            if (modelsWithSoftDelete.includes(model)) {
                                modelKey = model.charAt(0).toLowerCase() + model.slice(1);
                                return [2 /*return*/, prisma[modelKey].updateMany({
                                        where: args.where,
                                        data: { deletedAt: new Date() },
                                    })];
                            }
                            return [2 /*return*/, query(args)];
                        });
                    });
                },
                findFirst: function (_a) {
                    return __awaiter(this, arguments, void 0, function (_b) {
                        var model = _b.model, args = _b.args, query = _b.query;
                        return __generator(this, function (_c) {
                            if (modelsWithSoftDelete.includes(model)) {
                                args.where = args.where || {};
                                if (args.where.deletedAt === undefined) {
                                    args.where.deletedAt = null;
                                }
                            }
                            return [2 /*return*/, query(args)];
                        });
                    });
                },
                findMany: function (_a) {
                    return __awaiter(this, arguments, void 0, function (_b) {
                        var model = _b.model, args = _b.args, query = _b.query;
                        return __generator(this, function (_c) {
                            if (modelsWithSoftDelete.includes(model)) {
                                args.where = args.where || {};
                                if (args.where.deletedAt === undefined) {
                                    args.where.deletedAt = null;
                                }
                            }
                            return [2 /*return*/, query(args)];
                        });
                    });
                },
                findUnique: function (_a) {
                    return __awaiter(this, arguments, void 0, function (_b) {
                        var model = _b.model, args = _b.args, query = _b.query;
                        return __generator(this, function (_c) {
                            if (modelsWithSoftDelete.includes(model)) {
                                args.where = args.where || {};
                                if (args.where.deletedAt === undefined) {
                                    args.where.deletedAt = null;
                                }
                            }
                            return [2 /*return*/, query(args)];
                        });
                    });
                },
                count: function (_a) {
                    return __awaiter(this, arguments, void 0, function (_b) {
                        var model = _b.model, args = _b.args, query = _b.query;
                        return __generator(this, function (_c) {
                            if (modelsWithSoftDelete.includes(model)) {
                                args.where = args.where || {};
                                if (args.where.deletedAt === undefined) {
                                    args.where.deletedAt = null;
                                }
                            }
                            return [2 /*return*/, query(args)];
                        });
                    });
                },
            },
        },
        model: {
            $allModels: {
                paginate: function () {
                    return __awaiter(this, arguments, void 0, function (args) {
                        var page, limit, skip, _a, _p, _l, findManyArgs, _b, data, total;
                        if (args === void 0) { args = {}; }
                        return __generator(this, function (_c) {
                            switch (_c.label) {
                                case 0:
                                    page = args.page || 1;
                                    limit = args.limit || 10;
                                    skip = (page - 1) * limit;
                                    _a = args, _p = _a.page, _l = _a.limit, findManyArgs = __rest(_a, ["page", "limit"]);
                                    return [4 /*yield*/, Promise.all([
                                            this.findMany(__assign(__assign({}, findManyArgs), { take: limit, skip: skip })),
                                            this.count({ where: args.where }),
                                        ])];
                                case 1:
                                    _b = _c.sent(), data = _b[0], total = _b[1];
                                    return [2 /*return*/, {
                                            data: data,
                                            total: total,
                                            page: page,
                                            limit: limit,
                                            totalPages: Math.ceil(total / limit),
                                        }];
                            }
                        });
                    });
                },
            },
            user: {
                findActive: function () {
                    return __awaiter(this, void 0, void 0, function () {
                        return __generator(this, function (_a) {
                            return [2 /*return*/, prisma.user.findMany({
                                    where: {
                                        status: 'ACTIVE',
                                        deletedAt: null,
                                    },
                                })];
                        });
                    });
                },
            },
        },
    });
};
exports.prismaExtension = prismaExtension;
