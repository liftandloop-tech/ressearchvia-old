import axios from "axios";
import { v4 as uuidv4 } from "uuid";

class ProxyService {
  constructor() {
    this.baseUrl = process.env.PROXY_API_URL || "https://partners-uat.staticip.in";
    this.partnerUserid = process.env.PROXY_PARTNER_USERID || "SPResearchvia";
    this.partnerPassword = process.env.PROXY_PARTNER_PASSWORD || "tk29yom43u725g5u";
  }

  async _request(endpoint, body) {
    try {
      const response = await axios.post(`${this.baseUrl}${endpoint}`, {
        partner_userid: this.partnerUserid,
        partner_password: this.partnerPassword,
        ...body,
      }, {
        timeout: 15000,
      });

      return response.data;
    } catch (error) {
      console.error(`ProxyService error at ${endpoint}:`, error.message);
      throw error;
    }
  }

  /**
   * Issues a new static IP for a given broker.
   */
  async issueIp({ brokername, validity, iptype = "ipv4", mobile, email }) {
    const orderId = uuidv4();
    let attempts = 0;
    const maxAttempts = 3;

    while (attempts < maxAttempts) {
      attempts++;
      const result = await this._request("/api/issue_ip", {
        order_id: orderId,
        brokername,
        validity,
        iptype,
        end_user_mobile: mobile,
        end_user_email: email,
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

      // If already in progress, query order status
      if (result.error_code === 601) {
        console.log("Order is already in progress, checking order status...");
        return this.checkOrderStatus(orderId);
      }

      return { orderId, ...result };
    }
    
    // Timeout fallback: query order status
    return this.checkOrderStatus(orderId);
  }

  /**
   * Renews an existing static IP.
   */
  async renewIp({ validity, oldIpUserid }) {
    const orderId = uuidv4();
    let attempts = 0;
    const maxAttempts = 3;

    while (attempts < maxAttempts) {
      attempts++;
      const result = await this._request("/api/renew_ip", {
        order_id: orderId,
        validity,
        old_ip_userid: oldIpUserid,
      });

      if (result.status === "success") {
        return { orderId, ...result };
      }

      if (result.error_code === 501 && attempts < maxAttempts) {
        console.warn(`Attempt ${attempts} failed with infrastructure error 501. Retrying renew...`);
        await new Promise((res) => setTimeout(res, 2000));
        continue;
      }

      if (result.error_code === 601) {
        return this.checkOrderStatus(orderId);
      }

      return { orderId, ...result };
    }

    return this.checkOrderStatus(orderId);
  }

  /**
   * Checks the status of a previous order attempt.
   */
  async checkOrderStatus(orderId) {
    return this._request("/api/order_status", { order_id: orderId });
  }

  /**
   * Checks the partner balance.
   */
  async checkBalance() {
    return this._request("/api/check_balance", {});
  }

  /**
   * Retrieves broker info including pricing tiers.
   */
  async getBrokerInfo() {
    return this._request("/api/broker_info", {});
  }

  /**
   * Queries details of a previously issued IP.
   */
  async getIpInfo(ipUserid) {
    return this._request("/api/ip_info", { ip_userid: ipUserid });
  }
}

export default new ProxyService();
