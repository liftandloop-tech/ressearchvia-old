import planPurchaseService from "../services/planPurchaseService.js";

const planPurchaseController = {
  purchasePlan: async (req, res) => {
    try {
      const response = await planPurchaseService.purchasePlan(req);
      res.status(response.status).send(response);
    } catch (error) {
      res.status(400).send({ status: 400, message: error.message, data: {} });
    }
  },
  extendSubscription: async (req, res) => {
    try {
      const response = await planPurchaseService.extendSubscription({ body: req.body, user: req.user, req });
      res.status(response.status).send(response);
    } catch (error) {
      res.status(400).send({ status: 400, message: error.message, data: {} });
    }
  },
  revokeSubscription: async (req, res) => {
    try {
      const response = await planPurchaseService.revokeSubscription({ body: req.body, user: req.user, req });
      res.status(response.status).send(response);
    } catch (error) {
      res.status(400).send({ status: 400, message: error.message, data: {} });
    }
  },
  changePlan: async (req, res) => {
    try {
      const response = await planPurchaseService.changePlan(req);
      res.status(response.status).send(response);
    } catch (error) {
      res.status(400).send({ status: 400, message: error.message, data: {} });
    }
  },
  paymentVerify: async (req, res) => {
    try {
      const response = await planPurchaseService.paymentVerify(req);
      res.status(response.status).send(response);
    } catch (error) {
      res.status(400).send({ status: 400, message: error.message, data: {} });
    }
  },
  expirePlan: async (req, res) => {
    try {
      await planPurchaseService.expirePlan();
      await planPurchaseService.sendExpiryReminders();
    } catch (error) {
      console.error("Error in expirePlan cron:", error);
      if (res) res.status(400).send({ status: 400, message: error.message, data: {} });
    }
  },
  expiry: async (req, res) => {
    try {
      const response = await planPurchaseService.expiryReminders(req);
      // res.status(response.status).send(response);
    } catch (error) {
      // res.status(400).send({ status: 400, message: error.message, data: {} });
    }
  },
  expiryReminderOnOff: async (req, res) => {
    try {
      const response = await planPurchaseService.expiryReminderOnOff(req);
      res.status(response.status).send(response);
    } catch (error) {
      res.status(400).send({ status: 400, message: error.message, data: {} });
    }
  },
  getUserActivePlan: async (req, res) => {
    try {
      const response = await planPurchaseService.getUserActivePlan(req);
      res.status(response.status).send(response);
    } catch (error) {
      res.status(400).send({ status: 400, message: error.message, data: {} });
    }
  },
  subcriptionHistory: async (req, res) => {
    try {
      const response = await planPurchaseService.subcriptionHistory(req);
      res.status(response.status).send(response);
    } catch (error) {
      res.status(400).send({ status: 400, message: error.message, data: {} });
    }
  },
  recentPaymentList: async (req, res) => {
    try {
      const response = await planPurchaseService.recentPaymentList(req);
      res.status(response.status).send(response);
    } catch (error) {
      res.status(400).send({ status: 400, message: error.message, data: {} });
    }
  },
  purchaseRegistration: async (req, res) => {
    try {
      const response = await planPurchaseService.purchaseRegistration(req);
      res.status(response.status).send(response);
    } catch (error) {
      res.status(400).send({ status: 400, message: error.message, data: {} });
    }
  },
  suspendSubscription: async (req, res) => {
    try {
      const response = await planPurchaseService.suspendSubscription({ body: req.body, user: req.user, req });
      res.status(response.status).send(response);
    } catch (error) {
      res.status(400).send({ status: 400, message: error.message, data: {} });
    }
  },
  activateSubscription: async (req, res) => {
    try {
      const response = await planPurchaseService.activateSubscription({ body: req.body, user: req.user, req });
      res.status(response.status).send(response);
    } catch (error) {
      res.status(400).send({ status: 400, message: error.message, data: {} });
    }
  },
  updateSubscriptionDates: async (req, res) => {
    try {
      const response = await planPurchaseService.updateSubscriptionDates({ body: req.body, user: req.user });
      res.status(response.status).send(response);
    } catch (error) {
      res.status(400).send({ status: 400, message: error.message, data: {} });
    }
  },
  adminCreatePlan: async (req, res) => {
    try {
      const response = await planPurchaseService.adminCreatePlan({ body: req.body, user: req.user, req });
      res.status(response.status).send(response);
    } catch (error) {
      res.status(400).send({ status: 400, message: error.message, data: {} });
    }
  },
  uploadPaymentProof: async (req, res) => {
    try {
      const response = await planPurchaseService.uploadPaymentProof({ body: req.body, files: req.files });
      res.status(response.status).send(response);
    } catch (error) {
      res.status(400).send({ status: 400, message: error.message, data: {} });
    }
  },
  adminTopUpPartialPlan: async (req, res) => {
    try {
      const response = await planPurchaseService.adminTopUpPartialPlan({ body: req.body, user: req.user, req });
      res.status(response.status).send(response);
    } catch (error) {
      res.status(400).send({ status: 400, message: error.message, data: {} });
    }
  },
  adminUpdatePayment: async (req, res) => {
    try {
      const response = await planPurchaseService.adminUpdatePayment({ body: req.body, user: req.user, req });
      res.status(response.status).send(response);
    } catch (error) {
      res.status(400).send({ status: 400, message: error.message, data: {} });
    }
  },
  adminPreviewCorrection: async (req, res) => {
    try {
      const response = await planPurchaseService.adminPreviewCorrection({ body: req.body });
      res.status(response.status).send(response);
    } catch (error) {
      res.status(400).send({ status: 400, message: error.message, data: {} });
    }
  },
  billingHistory: async (req, res) => {
    try {
      const response = await planPurchaseService.subcriptionBillingHistory(req);
      res.status(response.status).send(response);
    } catch (error) {
      res.status(400).send({ status: 400, message: error.message, data: {} });
    }
  },
};
export default planPurchaseController;
