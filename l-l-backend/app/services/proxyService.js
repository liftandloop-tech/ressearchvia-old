import axios from "axios";
import { v4 as uuidv4 } from "uuid";

class ProxyService {
  constructor() {
    this.baseUrl =
      process.env.PROXY_API_URL ||
      process.env.STATIC_IP_PARTNER_BASE_URL ||
      "https://partners-uat.staticip.in";
    this.partnerUserid =
      process.env.PROXY_PARTNER_USERID ||
      process.env.STATIC_IP_PARTNER_ID ||
      "SPResearchvia";
    this.partnerPassword =
      process.env.PROXY_PARTNER_PASSWORD ||
      process.env.STATIC_IP_PARTNER_PASSWORD ||
      "tk29yom43u725g5u";
  }

  async _request(endpoint, body) {
    try {
      const response = await axios.post(
        `${this.baseUrl}${endpoint}`,
        {
          partner_userid: this.partnerUserid,
          partner_password: this.partnerPassword,
          ...body,
        },
        {
          timeout: 20000,
        }
      );

      return response.data;
    } catch (error) {
      console.error(`ProxyService error at ${endpoint}:`, error.response?.data || error.message);
      throw error;
    }
  }

  /**
   * Issues a new static IP for a given broker.
   * Conforms strictly to Partner API Integration Guide Version 1.2:
   * - Retries with same order_id on infrastructure 501 error
   * - Queries /api/order_status on timeout or 601 (in progress)
   */
  async issueIp({ brokername, validity, iptype = "ipv4", mobile, email }) {
    const orderId = uuidv4();
    let attempts = 0;
    const maxAttempts = 3;

    // Sanitize mobile to 10 digits
    const cleanMobile = mobile ? String(mobile).replace(/\D/g, "").slice(-10) : undefined;
    const cleanEmail = email ? String(email).trim() : undefined;

    while (attempts < maxAttempts) {
      attempts++;
      try {
        const result = await this._request("/api/issue_ip", {
          order_id: orderId,
          brokername,
          validity: Number(validity),
          iptype,
          end_user_mobile: cleanMobile,
          end_user_email: cleanEmail,
        });

        if (result.status === "success") {
          return { orderId, ...result };
        }

        // If it is code 501 (proxy server error), we can safely retry using the same order_id
        if (result.error_code === 501 && attempts < maxAttempts) {
          console.warn(`Attempt ${attempts} failed with infrastructure error 501. Retrying same order_id...`);
          await new Promise((res) => setTimeout(res, 2000));
          continue;
        }

        // If order already in progress (code 601), query order status
        if (result.error_code === 601) {
          console.log(`Order ${orderId} is in progress (601). Polling /api/order_status...`);
          return await this.checkOrderStatus(orderId);
        }

        // Permanent failure (101, 102, 103, 104, 201, 202, 301, 302, etc.)
        return { orderId, ...result };
      } catch (err) {
        console.error(`Attempt ${attempts} encountered error during issue_ip:`, err.message);
        // Timeout or network drop: query /api/order_status using the same order_id
        if (attempts >= maxAttempts) {
          console.log(`Max attempts reached. Checking status for order ${orderId}...`);
          return await this.checkOrderStatus(orderId);
        }
        await new Promise((res) => setTimeout(res, 2000));
      }
    }

    return await this.checkOrderStatus(orderId);
  }

  /**
   * Renews an existing static IP.
   * Note: As per API spec Section 2, there is NO minimum-month requirement for renewals.
   */
  async renewIp({ validity, oldIpUserid, brokername = "angel" }) {
    const orderId = uuidv4();
    let attempts = 0;
    const maxAttempts = 3;

    while (attempts < maxAttempts) {
      attempts++;
      try {
        const result = await this._request("/api/renew_ip", {
          order_id: orderId,
          brokername,
          validity: Number(validity),
          old_ip_userid: oldIpUserid,
        });

        if (result.status === "success") {
          return { orderId, ...result };
        }

        if (result.error_code === 501 && attempts < maxAttempts) {
          console.warn(`Renew attempt ${attempts} failed with 501. Retrying same order_id...`);
          await new Promise((res) => setTimeout(res, 2000));
          continue;
        }

        if (result.error_code === 601) {
          return await this.checkOrderStatus(orderId);
        }

        return { orderId, ...result };
      } catch (err) {
        console.error(`Renew attempt ${attempts} encountered network error:`, err.message);
        if (attempts >= maxAttempts) {
          return await this.checkOrderStatus(orderId);
        }
        await new Promise((res) => setTimeout(res, 2000));
      }
    }

    return await this.checkOrderStatus(orderId);
  }

  /**
   * Checks the status of a previous order attempt (replays original result).
   */
  async checkOrderStatus(orderId, maxPollAttempts = 3) {
    let attempt = 0;
    while (attempt < maxPollAttempts) {
      attempt++;
      try {
        const res = await this._request("/api/order_status", { order_id: orderId });
        if (res.status === "processing" && attempt < maxPollAttempts) {
          console.log(`Order ${orderId} is still processing. Waiting 2s...`);
          await new Promise((r) => setTimeout(r, 2000));
          continue;
        }
        return res;
      } catch (err) {
        if (attempt >= maxPollAttempts) {
          return {
            status: "failed",
            error_code: 601,
            remark: "Order status check timed out. Please verify with support.",
          };
        }
        await new Promise((r) => setTimeout(r, 2000));
      }
    }

    return {
      status: "failed",
      error_code: 601,
      remark: "Order is still being processed.",
    };
  }

  /**
   * Checks the partner wallet balance.
   */
  async checkBalance() {
    return this._request("/api/check_balance", {});
  }

  /**
   * Retrieves broker info including pricing tiers and minimum validity.
   */
  async getBrokerInfo() {
    return this._request("/api/broker_info", {});
  }

  /**
   * Lists all available supported brokers from the partner API.
   */
  async listBrokers() {
    return this._request("/api/list_brokers", {});
  }

  /**
   * Queries details of a previously issued IP by its ip_userid.
   */
  async getIpInfo(ipUserid) {
    return this._request("/api/ip_info", { ip_userid: ipUserid });
  }
}

export default new ProxyService();
