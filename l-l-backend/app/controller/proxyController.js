import pg from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from "@prisma/client";
import proxyService from "../services/proxyService.js";
import userModel from "../models/userModel.js";

// Resolve Postgres Prisma Client using driver adapter for Prisma 7
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

const proxyController = {
  /**
   * Fetch active proxy info for the logged-in client.
   */
  getProxyInfo: async (req, res) => {
    try {
      const userId = req.user._id;

      // Find user's active broker link in postgres
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
        return res.status(200).send({
          status: "success",
          remark: "No linked broker profile found.",
          data: null,
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
        },
      });
    } catch (error) {
      console.error("[ProxyController] getProxyInfo error:", error);
      res.status(500).send({ status: "failed", remark: error.message });
    }
  },

  /**
   * Fetch pricing tiers and broker info.
   */
  getBrokerPricing: async (req, res) => {
    try {
      const result = await proxyService.getBrokerInfo();
      res.status(200).send(result);
    } catch (error) {
      console.error("[ProxyController] getBrokerPricing error:", error);
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
