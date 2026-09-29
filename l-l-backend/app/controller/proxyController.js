import Razorpay from "razorpay";
import crypto from "crypto";
import mongoose from "mongoose";
import proxyService from "../services/proxyService.js";
import userModel from "../models/userModel.js";
import { prisma, toUuid } from "../config/prismaClient.js";

function normalizeBrokerEnum(code) {
  if (!code) return 'ANGEL_ONE';
  const str = code.toString().toUpperCase();
  if (str.includes('ZEBU')) return 'ZEBU';
  return 'ANGEL_ONE';
}

async function ensurePostgresUser(uuidUserId, mongoUser) {
  if (!uuidUserId) return null;
  try {
    let pgUser = await prisma.user.findUnique({
      where: { id: uuidUserId }
    });

    if (pgUser) return pgUser;

    const rawMobile = (mongoUser?.phone || mongoUser?.userObject?.APP_MOB_NO?.toString() || "").replace(/\D/g, "");
    let mobile = rawMobile.slice(-10);
    if (mobile.length < 10) {
      mobile = "9" + Math.floor(100000000 + Math.random() * 900000000);
    }

    // Check if mobile already exists in Postgres
    const existingByMobile = await prisma.user.findFirst({
      where: { mobile }
    });

    if (existingByMobile) {
      return existingByMobile;
    }

    const mpinHash = mongoUser?.mpinHash || "$2b$10$defaultDummyHashForPostgresSyncDummyHash123";
    const email = mongoUser?.email || mongoUser?.userObject?.APP_EMAIL || null;
    const firstName = mongoUser?.fullName || mongoUser?.userObject?.APP_NAME || "Client";

    pgUser = await prisma.user.create({
      data: {
        id: uuidUserId,
        mobile: mobile,
        mpinHash: mpinHash,
        firstName: firstName.slice(0, 100),
        email: email ? email.slice(0, 255) : null,
        status: "ACTIVE"
      }
    });

    return pgUser;
  } catch (err) {
    console.error("[ProxyController] ensurePostgresUser error:", err.message);
    try {
      const fallbackMobile = "9" + Date.now().toString().slice(-9);
      const fallbackUser = await prisma.user.create({
        data: {
          id: uuidUserId,
          mobile: fallbackMobile,
          mpinHash: "$2b$10$defaultDummyHashForPostgresSyncDummyHash123",
          firstName: "Client",
          status: "ACTIVE"
        }
      });
      return fallbackUser;
    } catch (e2) {
      console.error("[ProxyController] ensurePostgresUser fallback error:", e2.message);
      return null;
    }
  }
}

const proxyController = {
  /**
   * Fetch active proxy info for the logged-in client.
   */
  getProxyInfo: async (req, res) => {
    const availableBrokers = [
      { code: 'angel', name: 'Angel One' },
      { code: 'zebu', name: 'Mynt by Zebu' },
    ];

    try {
      const rawUserId = req.user?._id || req.user?.id;
      const uuidUserId = toUuid(rawUserId);
      const user = await userModel.findById(rawUserId);
      const requestedBroker = req.query?.brokerCode?.toString().toLowerCase();

      let effectiveUserId = uuidUserId;
      try {
        const pgUser = await ensurePostgresUser(uuidUserId, user);
        if (pgUser?.id) {
          effectiveUserId = pgUser.id;
        }
      } catch (err) {
        console.warn("[ProxyController] ensurePostgresUser error in getProxyInfo:", err.message);
      }

      let userBroker = null;
      try {
        if (requestedBroker) {
          const targetEnum = normalizeBrokerEnum(requestedBroker);
          userBroker = await prisma.userBroker.findFirst({
            where: {
              userId: { in: [effectiveUserId, uuidUserId].filter(Boolean) },
              broker: {
                code: targetEnum,
              },
              status: "ACTIVE",
            },
            include: {
              broker: true,
            },
          });
        }

        if (!userBroker) {
          userBroker = await prisma.userBroker.findFirst({
            where: {
              userId: { in: [effectiveUserId, uuidUserId].filter(Boolean) },
              status: "ACTIVE",
              proxyIp: { not: null },
            },
            include: {
              broker: true,
            },
            orderBy: { updatedAt: "desc" },
          });
        }

        if (!userBroker) {
          userBroker = await prisma.userBroker.findFirst({
            where: {
              userId: { in: [effectiveUserId, uuidUserId].filter(Boolean) },
              status: "ACTIVE",
            },
            include: {
              broker: true,
            },
          });
        }
      } catch (dbErr) {
        console.warn("[ProxyController] userBroker DB query fallback:", dbErr.message);
      }

      // Check if proxy details are present in user.proxies, user.proxy, or userBroker
      let mongoProxy = null;
      if (requestedBroker && user?.proxies?.[requestedBroker]) {
        mongoProxy = user.proxies[requestedBroker];
      } else if (user?.proxy) {
        if (!requestedBroker || user.proxy.brokerCode?.toLowerCase() === requestedBroker) {
          mongoProxy = user.proxy;
        } else if (user?.proxies?.[requestedBroker]) {
          mongoProxy = user.proxies[requestedBroker];
        } else {
          mongoProxy = user.proxy;
        }
      } else if (user?.assignedProxy) {
        mongoProxy = user.assignedProxy;
      }

      const allProxies = user?.proxies || (mongoProxy ? { [mongoProxy.brokerCode || 'angel']: mongoProxy } : {});

      if (!userBroker && !mongoProxy) {
        return res.status(200).send({
          status: "success",
          remark: "No linked broker profile found yet.",
          data: {
            brokerCode: requestedBroker || 'angel',
            brokerName: requestedBroker === 'zebu' ? 'Mynt by Zebu' : 'Angel One',
            hasProxy: false,
            availableBrokers,
            proxies: allProxies,
          },
        });
      }

      const proxyIp = mongoProxy?.ip || userBroker?.proxyIp;
      const proxyPort = mongoProxy?.port || userBroker?.proxyPort || 443;
      const proxyHostname = mongoProxy?.hostname || userBroker?.proxyHostname;
      const proxyUsername = mongoProxy?.ipUserid || userBroker?.proxyUsername;
      const proxyExpiry = mongoProxy?.expiry || userBroker?.proxyExpiry;
      const brokerCode = mongoProxy?.brokerCode || (userBroker?.broker?.code?.toLowerCase()?.includes('zebu') ? 'zebu' : 'angel') || requestedBroker || 'angel';
      const brokerName = mongoProxy?.brokerName || (brokerCode === 'zebu' ? 'Mynt by Zebu' : 'Angel One');

      if (!proxyIp) {
        return res.status(200).send({
          status: "success",
          remark: "No proxy IP assigned yet.",
          data: {
            brokerCode,
            brokerName,
            hasProxy: false,
            availableBrokers,
            proxies: allProxies,
          },
        });
      }

      const isExpired = proxyExpiry ? new Date(proxyExpiry) <= new Date() : false;

      res.status(200).send({
        status: "success",
        remark: "",
        data: {
          brokerCode,
          brokerName,
          hasProxy: true,
          ip: proxyIp,
          port: proxyPort,
          hostname: proxyHostname,
          ipUserid: proxyUsername,
          expiry: proxyExpiry,
          status: isExpired ? "expired" : "active",
          availableBrokers,
          proxies: allProxies,
        },
      });
    } catch (error) {
      console.error("[ProxyController] getProxyInfo error:", error);
      res.status(200).send({
        status: "success",
        remark: "Fallback response on error",
        data: {
          brokerCode: 'angel',
          brokerName: 'Angel One',
          hasProxy: false,
          availableBrokers,
        },
      });
    }
  },

  /**
   * Fetch pricing tiers and broker info.
   */
  getBrokerPricing: async (req, res) => {
    try {
      let result;
      try {
        result = await proxyService.getBrokerInfo();
      } catch (err) {
        result = { status: "success", brokers: {} };
      }

      // Set pricing to ₹500/mo + 18% GST (total ₹590/mo), with broker-specific minimum duration
      const getPricingForBroker = (brokerKey, rawBrokerData) => {
        const isAngel = brokerKey.toLowerCase().includes('angel');
        const apiMin = rawBrokerData?.ipv4?.min_month;
        const minMonth = apiMin ? Number(apiMin) : (isAngel ? 3 : 1);
        return {
          min_month: minMonth,
          base_price: 500,
          gst_percent: 18,
          monthly_total: 590,
          price_tiers: [
            { min_month: minMonth, price: 500 }
          ]
        };
      };

      if (!result.brokers) {
        result.brokers = {};
      }

      // Standardize pricing for all supported brokers
      const brokerKeys = Object.keys(result.brokers);
      if (brokerKeys.length === 0) {
        result.brokers = {
          angel: { ipv4: getPricingForBroker('angel', null) },
          zebu: { ipv4: getPricingForBroker('zebu', null) }
        };
      } else {
        for (const key of brokerKeys) {
          result.brokers[key] = {
            ...(result.brokers[key] || {}),
            ipv4: getPricingForBroker(key, result.brokers[key])
          };
        }
      }

      res.status(200).send(result);
    } catch (error) {
      console.error("[ProxyController] getBrokerPricing error:", error);
      res.status(500).send({ status: "failed", remark: error.message });
    }
  },

  /**
   * Create Razorpay Order for Proxy IP purchase or renewal
   */
  createProxyOrder: async (req, res) => {
    try {
      const rawUserId = req.user?._id || req.user?.id;
      const { validity, brokerCode } = req.body;
      const uuidUserId = toUuid(rawUserId);

      const targetBrokerCode = (brokerCode || 'angel').toString().toLowerCase();
      const isAngel = targetBrokerCode.includes('angel');
      let minMonth = isAngel ? 3 : 1;

      try {
        const brokerInfo = await proxyService.getBrokerInfo();
        const partnerKey = isAngel ? 'angel' : 'zebu';
        const partnerBroker = brokerInfo?.brokers?.[partnerKey];
        if (partnerBroker?.ipv4?.min_month) {
          minMonth = Number(partnerBroker.ipv4.min_month);
        }
      } catch (infoErr) {
        console.warn("[ProxyController] Failed to fetch live min_month from broker_info:", infoErr.message);
      }

      if (!validity || typeof validity !== "number" || validity < minMonth) {
        return res.status(400).send({
          status: "failed",
          remark: `Validity duration must be at least ${minMonth} month(s) for ${isAngel ? 'Angel One' : 'Zebu'}.`
        });
      }

      // Calculate total: ₹500 base * 1.18 GST = ₹590 per month
      const basePrice = 500;
      const baseAmount = basePrice * validity;
      const gstAmount = Number((baseAmount * 0.18).toFixed(2));
      const totalAmountRupees = Number((baseAmount + gstAmount).toFixed(2));
      const amountInPaise = Math.round(totalAmountRupees * 100);

      const razorpay = new Razorpay({
        key_id: process.env.RAZORPAY_KEY_ID,
        key_secret: process.env.RAZORPAY_KEY_SECRET,
      });

      const receipt = `PROXY_${rawUserId.toString().slice(-6)}_${Date.now()}`;
      const orderOptions = {
        amount: amountInPaise,
        currency: "INR",
        receipt,
        notes: {
          userId: rawUserId.toString(),
          brokerCode: targetBrokerCode,
          validity: validity.toString(),
          type: "STATIC_PROXY_IP"
        }
      };

      const order = await razorpay.orders.create(orderOptions);

      res.status(200).send({
        status: "success",
        data: {
          razorpayOrderId: order.id,
          amount: amountInPaise,
          amountRupees: totalAmountRupees,
          baseAmount,
          gstAmount,
          currency: "INR",
          keyId: process.env.RAZORPAY_KEY_ID,
          validity,
          brokerCode: targetBrokerCode
        }
      });
    } catch (error) {
      console.error("[ProxyController] createProxyOrder error:", error);
      res.status(500).send({ status: "failed", remark: error.message });
    }
  },

  /**
   * Verify Razorpay Payment Signature and Allocate/Renew Proxy IP
   */
  verifyProxyPayment: async (req, res) => {
    try {
      const rawUserId = req.user?._id || req.user?.id;
      const uuidUserId = toUuid(rawUserId);

      const {
        razorpayOrderId,
        razorpayPaymentId,
        razorpaySignature,
        validity,
        isRenewal,
        brokerCode
      } = req.body;

      if (!razorpayOrderId || !razorpayPaymentId || !razorpaySignature || !validity) {
        return res.status(400).send({ status: "failed", remark: "Missing required payment verification parameters." });
      }

      // Verify HMAC SHA256 Signature
      const secret = process.env.RAZORPAY_KEY_SECRET;
      const generatedSignature = crypto
        .createHmac("sha256", secret)
        .update(razorpayOrderId + "|" + razorpayPaymentId)
        .digest("hex");

      if (generatedSignature !== razorpaySignature) {
        return res.status(400).send({ status: "failed", remark: "Invalid Razorpay payment signature." });
      }

      // Fetch user & linked broker
      const user = await userModel.findById(rawUserId);
      if (!user) {
        return res.status(404).send({ status: "failed", remark: "User account not found." });
      }

      let effectiveUserId = uuidUserId;
      try {
        const pgUser = await ensurePostgresUser(uuidUserId, user);
        if (pgUser?.id) {
          effectiveUserId = pgUser.id;
        }
      } catch (pgErr) {
        console.warn("[ProxyController] ensurePostgresUser warning in verifyProxyPayment:", pgErr.message);
      }

      const targetBrokerEnum = normalizeBrokerEnum(brokerCode);
      const partnerBrokerName = targetBrokerEnum === 'ZEBU' ? 'zebu' : 'angel';

      let dbBroker = null;
      try {
        dbBroker = await prisma.broker.findFirst({
          where: { code: targetBrokerEnum }
        });

        if (!dbBroker) {
          dbBroker = await prisma.broker.create({
            data: {
              name: targetBrokerEnum === 'ZEBU' ? 'Mynt by Zebu' : 'Angel One',
              code: targetBrokerEnum,
              status: "ACTIVE"
            }
          });
        }
      } catch (brokerDbErr) {
        console.warn("[ProxyController] broker query warning:", brokerDbErr.message);
      }

      let userBroker = null;
      try {
        if (dbBroker) {
          userBroker = await prisma.userBroker.findUnique({
            where: {
              userId_brokerId: {
                userId: effectiveUserId,
                brokerId: dbBroker.id,
              }
            },
            include: { broker: true }
          });

          if (!userBroker) {
            userBroker = await prisma.userBroker.create({
              data: {
                userId: effectiveUserId,
                brokerId: dbBroker.id,
                brokerClientId: "PENDING_LINKING",
                status: "ACTIVE"
              },
              include: { broker: true }
            });
          }
        }
      } catch (ubErr) {
        console.warn("[ProxyController] userBroker query/create warning:", ubErr.message);
        if (dbBroker && !userBroker) {
          try {
            userBroker = await prisma.userBroker.findFirst({
              where: {
                userId: effectiveUserId,
                brokerId: dbBroker.id,
              },
              include: { broker: true }
            });
          } catch (e2) {
            console.warn("[ProxyController] userBroker fallback query error:", e2.message);
          }
        }
      }

      let result;
      const rawMobile = (user.phone || user.userObject?.APP_MOB_NO?.toString() || "9999999999").replace(/\D/g, "");
      const mobileNumber = rawMobile.slice(-10);
      const emailAddress = user.email || user.userObject?.APP_EMAIL || "user@example.com";

      const currentProxyUsername = userBroker?.proxyUsername || user?.proxy?.ipUserid;
      const isFakeProxy = currentProxyUsername && currentProxyUsername.startsWith('usr_');

      if (isRenewal && currentProxyUsername && !isFakeProxy) {
        // Request partner renewal (only for real partner-issued IPs)
        try {
          result = await proxyService.renewIp({
            validity,
            oldIpUserid: currentProxyUsername,
            brokername: partnerBrokerName,
          });
        } catch (renewErr) {
          console.error("[ProxyController] renewIp failed:", renewErr.message);
          return res.status(502).send({
            status: "failed",
            remark: "Failed to renew proxy IP with partner. Please contact support.",
          });
        }
      } else {
        // Issue new IP (either fresh purchase or renewal of a fake/invalid proxy)
        try {
          let brokerMin = 1;
          try {
            const brokerInfo = await proxyService.getBrokerInfo();
            const partnerBroker = brokerInfo?.brokers?.[partnerBrokerName];
            if (partnerBroker?.ipv4?.min_month) {
              brokerMin = partnerBroker.ipv4.min_month;
            }
          } catch (e) {
            brokerMin = partnerBrokerName === 'zebu' ? 1 : 3;
          }
          const partnerValidity = Math.max(validity, brokerMin);
          result = await proxyService.issueIp({
            brokername: partnerBrokerName,
            validity: partnerValidity,
            iptype: "ipv4",
            mobile: mobileNumber,
            email: emailAddress,
          });
        } catch (issueErr) {
          console.error("[ProxyController] issueIp failed:", issueErr.message);
          return res.status(502).send({
            status: "failed",
            remark: "Failed to issue proxy IP with partner. Please try again later.",
          });
        }
      }

      console.log("[ProxyController] verifyProxyPayment Partner result:", result);

      if (!result || result.status !== "success" || !result.ip_details) {
        console.error("[ProxyController] Partner returned failure:", result);
        return res.status(400).send({
          status: "failed",
          remark: result?.remark || "Partner could not allocate IP. Please try again or contact support.",
        });
      }

      // Parse Expiry Date from DD-MM-YYYY
      const dateStr = result.ip_details.validity || result.ip_details.updated_validity;
      let expiryDate = new Date();
      if (dateStr) {
        const parts = dateStr.split("-");
        if (parts.length === 3) {
          expiryDate = new Date(`${parts[2]}-${parts[1]}-${parts[0]}T23:59:59.000Z`);
        }
      }

      // Update Postgres UserBroker profile with Proxy details if available
      try {
        if (userBroker?.id) {
          await prisma.userBroker.update({
            where: { id: userBroker.id },
            data: {
              proxyIp: result.ip_details.ip,
              proxyPort: result.ip_details.port || 443,
              proxyHostname: result.ip_details.hostname,
              proxyUsername: result.ip_details.ip_userid || userBroker.proxyUsername,
              proxyPassword: result.ip_details.ip_password || userBroker.proxyPassword,
              proxyExpiry: expiryDate,
            },
          });
        }
      } catch (pgUpdateErr) {
        console.warn("[ProxyController] Postgres UserBroker update warning:", pgUpdateErr.message);
      }

      // Update MongoDB User with proxy details as fallback
      try {
        await userModel.collection.updateOne(
          { _id: new mongoose.Types.ObjectId(rawUserId.toString()) },
          {
            $set: {
              proxy: {
                ip: result.ip_details.ip,
                port: result.ip_details.port || 443,
                hostname: result.ip_details.hostname,
                ipUserid: result.ip_details.ip_userid,
                ipPassword: result.ip_details.ip_password,
                expiry: expiryDate,
                brokerCode: partnerBrokerName,
                brokerName: targetBrokerEnum === 'ZEBU' ? 'Mynt by Zebu' : 'Angel One',
                orderId: result.order_id,
                razorpayOrderId,
                razorpayPaymentId,
                purchasedAt: new Date(),
              },
              [`proxies.${partnerBrokerName}`]: {
                ip: result.ip_details.ip,
                port: result.ip_details.port || 443,
                hostname: result.ip_details.hostname,
                ipUserid: result.ip_details.ip_userid,
                ipPassword: result.ip_details.ip_password,
                expiry: expiryDate,
                brokerCode: partnerBrokerName,
                brokerName: targetBrokerEnum === 'ZEBU' ? 'Mynt by Zebu' : 'Angel One',
                orderId: result.order_id,
                razorpayOrderId,
                razorpayPaymentId,
                purchasedAt: new Date(),
              }
            }
          }
        );
      } catch (mongoUpdateErr) {
        console.warn("[ProxyController] MongoDB user proxy update warning:", mongoUpdateErr.message);
      }

      res.status(200).send({
        status: "success",
        remark: isRenewal ? "Proxy IP successfully renewed." : "Proxy IP successfully issued and assigned.",
        data: {
          ip: result.ip_details.ip,
          port: result.ip_details.port || 443,
          expiry: dateStr,
          status: "active",
          brokerCode: partnerBrokerName,
        },
      });
    } catch (error) {
      console.error("[ProxyController] verifyProxyPayment error:", error);
      res.status(500).send({ status: "failed", remark: error.message });
    }
  },

  /**
   * Request static IP issuance for the user.
   */
  issueProxy: async (req, res) => {
    try {
      const userId = req.user._id;
      const { validity } = req.body; // months

      if (!validity || typeof validity !== "number" || validity <= 0) {
        return res.status(400).send({ status: "failed", remark: "Invalid validity duration." });
      }

      // Check linked broker
      const userBroker = await prisma.userBroker.findFirst({
        where: {
          userId: userId.toString(),
          status: "ACTIVE",
        },
        include: {
          broker: true,
        },
      });

      if (!userBroker) {
        return res.status(400).send({ status: "failed", remark: "Please link your broker account first." });
      }

      // Fetch user wallet balance from MongoDB
      const user = await userModel.findById(userId);
      if (!user) {
        return res.status(404).send({ status: "failed", remark: "User account not found." });
      }

      // Fetch pricing details to calculate required fund
      const brokerInfo = await proxyService.getBrokerInfo();
      const brokerCode = userBroker.broker.code.toLowerCase().replace("_", "");
      const brokerData = brokerInfo.brokers[brokerCode] || brokerInfo.brokers["angel"]; // Fallback search

      const iptype = "ipv4";
      const config = brokerData[iptype];

      if (!config) {
        return res.status(400).send({ status: "failed", remark: "Selected broker does not support IPv4 proxies." });
      }

      if (validity < config.min_month) {
        return res.status(400).send({
          status: "failed",
          remark: `Validity is not permitted. Minimum validity is ${config.min_month} months.`,
        });
      }

      // Calculate cost based on tiers
      // Rule: Pick the tier with the LARGEST min_month that is <= validity
      let selectedPrice = 0;
      let sortedTiers = config.price_tiers.sort((a, b) => b.min_month - a.min_month);
      for (const tier of sortedTiers) {
        if (validity >= tier.min_month) {
          selectedPrice = tier.price;
          break;
        }
      }

      const totalCost = selectedPrice * validity;

      // Check balance
      if (user.wallet_balance < totalCost) {
        return res.status(400).send({
          status: "failed",
          error_code: 302,
          remark: "fund is not sufficient",
          available_fund: user.wallet_balance,
          required_fund: totalCost,
        });
      }

      // Charge Partner Proxy
      const result = await proxyService.issueIp({
        brokername: brokerCode,
        validity,
        iptype,
        mobile: user.phone,
        email: user.email,
      });

      if (result.status !== "success") {
        return res.status(400).send(result);
      }

      // Deduct balance from Mongo User Profile
      user.wallet_balance -= totalCost;
      await user.save();

      // Store proxy details in Postgres UserBroker profile
      const expiryParts = result.ip_details.validity.split("-");
      const expiryDate = new Date(`${expiryParts[2]}-${expiryParts[1]}-${expiryParts[0]}T23:59:59.000Z`);

      await prisma.userBroker.update({
        where: { id: userBroker.id },
        data: {
          proxyIp: result.ip_details.ip,
          proxyPort: result.ip_details.port,
          proxyHostname: result.ip_details.hostname,
          proxyUsername: result.ip_details.ip_userid,
          proxyPassword: result.ip_details.ip_password,
          proxyExpiry: expiryDate,
        },
      });

      res.status(200).send({
        status: "success",
        remark: "Proxy IP successfully issued and assigned.",
        data: {
          ip: result.ip_details.ip,
          port: result.ip_details.port,
          expiry: result.ip_details.validity,
        },
      });
    } catch (error) {
      console.error("[ProxyController] issueProxy error:", error);
      res.status(500).send({ status: "failed", remark: error.message });
    }
  },

  /**
   * Renew static IP for the user.
   */
  renewProxy: async (req, res) => {
    try {
      const userId = req.user._id;
      const { validity } = req.body;

      if (!validity || typeof validity !== "number" || validity <= 0) {
        return res.status(400).send({ status: "failed", remark: "Invalid validity duration." });
      }

      const userBroker = await prisma.userBroker.findFirst({
        where: {
          userId: userId.toString(),
          status: "ACTIVE",
        },
        include: {
          broker: true,
        },
      });

      if (!userBroker || !userBroker.proxyUsername) {
        return res.status(400).send({ status: "failed", remark: "No active proxy found to renew." });
      }

      const user = await userModel.findById(userId);
      if (!user) {
        return res.status(404).send({ status: "failed", remark: "User account not found." });
      }

      // Calculate Renewal cost
      const brokerInfo = await proxyService.getBrokerInfo();
      const brokerCode = userBroker.broker.code.toLowerCase().replace("_", "");
      const brokerData = brokerInfo.brokers[brokerCode] || brokerInfo.brokers["angel"];
      const config = brokerData["ipv4"];

      let selectedPrice = 0;
      let sortedTiers = config.price_tiers.sort((a, b) => b.min_month - a.min_month);
      for (const tier of sortedTiers) {
        if (validity >= tier.min_month) {
          selectedPrice = tier.price;
          break;
        }
      }

      const totalCost = selectedPrice * validity;

      if (user.wallet_balance < totalCost) {
        return res.status(400).send({
          status: "failed",
          error_code: 302,
          remark: "fund is not sufficient",
          available_fund: user.wallet_balance,
          required_fund: totalCost,
        });
      }

      // Request partner renewal
      const result = await proxyService.renewIp({
        validity,
        oldIpUserid: userBroker.proxyUsername,
      });

      if (result.status !== "success") {
        return res.status(400).send(result);
      }

      user.wallet_balance -= totalCost;
      await user.save();

      const expiryParts = result.ip_details.updated_validity.split("-");
      const expiryDate = new Date(`${expiryParts[2]}-${expiryParts[1]}-${expiryParts[0]}T23:59:59.000Z`);

      await prisma.userBroker.update({
        where: { id: userBroker.id },
        data: {
          proxyExpiry: expiryDate,
        },
      });

      res.status(200).send({
        status: "success",
        remark: "Proxy IP successfully renewed.",
        data: {
          expiry: result.ip_details.updated_validity,
        },
      });
    } catch (error) {
      console.error("[ProxyController] renewProxy error:", error);
      res.status(500).send({ status: "failed", remark: error.message });
    }
  },
};

export default proxyController;
