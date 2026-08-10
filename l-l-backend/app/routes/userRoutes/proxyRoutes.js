import express from "express";
import auth from "../../config/auth.js";
import proxyController from "../../controller/proxyController.js";

const Router = express.Router();

const proxyRoutes = () => {
  Router.get("/info", auth.tokenVerified, proxyController.getProxyInfo);
  Router.get("/pricing", auth.tokenVerified, proxyController.getBrokerPricing);
  Router.post("/issue", auth.tokenVerified, proxyController.issueProxy);
  Router.post("/renew", auth.tokenVerified, proxyController.renewProxy);

  return Router;
};

export default proxyRoutes;
