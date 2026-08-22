import pg from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from "@prisma/client";
import Razorpay from "razorpay";
import crypto from "crypto";
import proxyService from "../services/proxyService.js";
import userModel from "../models/userModel.js";

// Resolve Postgres Prisma Client using driver adapter for Prisma 7
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

function toUuid(id) {
  if (!id) return null;
  const str = id.toString().replace(/-/g, '');
  if (str.length === 32) {
    return `${str.slice(0,8)}-${str.slice(8,12)}-${str.slice(12,16)}-${str.slice(16,20)}-${str.slice(20,32)}`;
  }
  if (str.length === 24) {
    const padded = str + '00000000';
    return `${padded.slice(0,8)}-${padded.slice(8,12)}-${padded.slice(12,16)}-${padded.slice(16,20)}-${padded.slice(20,32)}`;
  }
  return id.toString();
}

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

      let userBroker = null;
      try {
        if (uuidUserId) {
          userBroker = await prisma.userBroker.findFirst({
            where: {
              userId: uuidUserId,
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

      if (!userBroker) {
        return res.status(200).send({
          status: "success",
          remark: "No linked broker profile found yet.",
          data: {
            brokerCode: 'angel',
            brokerName: 'Angel One',
            hasProxy: false,
            availableBrokers,
          },
        });
      }

      if (!userBroker.proxyIp) {
        return res.status(200).send({
          status: "success",
          remark: "No proxy IP assigned yet.",
          data: {
            brokerCode: userBroker.broker.code,
            brokerName: userBroker.broker.name,
            hasProxy: false,
            availableBrokers,
          },
        });
      }

      res.status(200).send({
        status: "success",
        remark: "",
        data: {
          brokerCode: userBroker.broker.code,
          brokerName: userBroker.broker.name,
          hasProxy: true,
          ip: userBroker.proxyIp,
          port: userBroker.proxyPort,
          hostname: userBroker.proxyHostname,
          ipUserid: userBroker.proxyUsername,
          expiry: userBroker.proxyExpiry,
          status: new Date(userBroker.proxyExpiry) > new Date() ? "active" : "expired",
          availableBrokers,
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

      // Override pricing with fixed ₹1 + 18% GST (Test Mode), min duration 3 months
      const fixedPricing = {
        min_month: 3,
        base_price: 1,
        gst_percent: 18,
        monthly_total: 1.18,
        price_tiers: [
          { min_month: 3, price: 1 }
        ]
      };

      if (!result.brokers) {
        result.brokers = {};
      }

      // Standardize pricing for all supported brokers
      const brokerKeys = Object.keys(result.brokers);
      if (brokerKeys.length === 0) {
        result.brokers = {
          angel: { ipv4: fixedPricing },
          zebu: { ipv4: fixedPricing }
        };
      } else {
        for (const key of brokerKeys) {
          result.brokers[key] = {
            ...(result.brokers[key] || {}),
            ipv4: fixedPricing
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

      if (!validity || typeof validity !== "number" || validity < 3) {
        return res.status(400).send({ status: "failed", remark: "Validity duration must be at least 3 months." });
      }

      let userBroker = null;
      try {
        if (uuidUserId) {
          userBroker = await prisma.userBroker.findFirst({
            where: {
              userId: uuidUserId,
              status: "ACTIVE",
            },
            include: {
              broker: true,
            },
          });
        }
      } catch (dbErr) {
        console.warn("[ProxyController] createProxyOrder userBroker DB query fallback:", dbErr.message);
      }

      const targetBrokerCode = userBroker?.broker?.code || brokerCode || 'angel';

      // Calculate total: ₹1 base * 1.18 GST = ₹1.18 per month (Testing Mode)
      const baseAmount = 1 * validity;
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

      let userBroker = null;
      try {
        if (uuidUserId) {
          userBroker = await prisma.userBroker.findFirst({
            where: {
              userId: uuidUserId,
              status: "ACTIVE",
            },
            include: {
              broker: true,
            },
          });
        }
      } catch (dbErr) {
        console.warn("[ProxyController] verifyProxyPayment DB query fallback:", dbErr.message);
      }

      const targetBrokerEnum = normalizeBrokerEnum(userBroker?.broker?.code || brokerCode);
      const partnerBrokerName = targetBrokerEnum === 'ZEBU' ? 'zebu' : 'angel';

      // If user has no userBroker record yet, create a pending linking profile for this broker
      if (!userBroker) {
        let dbBroker = await prisma.broker.findFirst({
          where: {
            code: targetBrokerEnum
          }
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

        const pgUser = await ensurePostgresUser(uuidUserId, user);
        const actualUserId = pgUser?.id || uuidUserId;

        userBroker = await prisma.userBroker.create({
          data: {
            userId: actualUserId,
            brokerId: dbBroker.id,
            brokerClientId: "PENDING_LINKING",
            status: "ACTIVE"
          },
          include: {
            broker: true
          }
        });
      }

      let result;

      const mobileNumber = user.phone || user.userObject?.APP_MOB_NO?.toString() || "9999999999";
      const emailAddress = user.email || user.userObject?.APP_EMAIL || "user@example.com";

      const isFakeProxy = userBroker.proxyUsername && userBroker.proxyUsername.startsWith('usr_');

      if (isRenewal && userBroker.proxyUsername && !isFakeProxy) {
        // Request partner renewal (only for real partner-issued IPs)
        try {
          result = await proxyService.renewIp({
            validity,
            oldIpUserid: userBroker.proxyUsername,
          });
        } catch (renewErr) {
          const errBody = renewErr.response?.data;
          console.error("[ProxyController] renewIp failed:", errBody || renewErr.message);
          return res.status(502).send({
            status: "failed",
            remark: errBody?.detail?.[0]?.msg || errBody?.detail || "Failed to renew proxy IP with partner. Please contact support.",
          });
        }
      } else {
        // Issue new IP (either fresh purchase or renewal of a fake/invalid proxy)
        try {
          const partnerValidity = Math.max(validity, 3);
          result = await proxyService.issueIp({
            brokername: partnerBrokerName,
            validity: partnerValidity,
            iptype: "ipv4",
            mobile: mobileNumber,
            email: emailAddress,
          });
        } catch (issueErr) {
          const errBody = issueErr.response?.data;
          console.error("[ProxyController] issueIp failed:", errBody || issueErr.message);
          return res.status(502).send({
            status: "failed",
            remark: errBody?.detail?.[0]?.msg || errBody?.detail || "Failed to issue proxy IP with partner. Please try again later.",
          });
        }
      }

      console.log("[ProxyController] verifyProxyPayment result:", result);

      if (!result || result.status !== "success" || !result.ip_details) {
        console.error("[ProxyController] Partner returned failure:", result);
        return res.status(400).send({
          status: "failed",
          remark: result?.remark || "Partner could not allocate IP. Please try again or contact support.",
        });
      }

      // Update Postgres UserBroker profile with Proxy details
      let expiryDate;
      if (isRenewal && result.ip_details.updated_validity) {
        const expiryParts = result.ip_details.updated_validity.split("-");
        expiryDate = new Date(`${expiryParts[2]}-${expiryParts[1]}-${expiryParts[0]}T23:59:59.000Z`);

        await prisma.userBroker.update({
          where: { id: userBroker.id },
          data: {
            proxyExpiry: expiryDate,
          },
        });
      } else if (result.ip_details) {
        const expiryParts = result.ip_details.validity.split("-");
        expiryDate = new Date(`${expiryParts[2]}-${expiryParts[1]}-${expiryParts[0]}T23:59:59.000Z`);

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
      }

      res.status(200).send({
        status: "success",
        remark: isRenewal ? "Proxy IP successfully renewed." : "Proxy IP successfully issued and assigned.",
        data: {
          ip: result.ip_details.ip || userBroker.proxyIp,
          port: result.ip_details.port || userBroker.proxyPort,
          expiry: result.ip_details.validity || result.ip_details.updated_validity,
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
