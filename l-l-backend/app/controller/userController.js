import userService from "../services/userService.js";

const usersController = {

	login: async (req, res) => {
		try {
			// Inject Device ID from Header if present
			const deviceId = req.headers['device-id'] || req.get('device-id');
			if (deviceId) {
				console.log(`[UserController] Login Request with Device ID: ${deviceId}`);
				req.body.deviceId = deviceId;
			} else {
				console.log(`[UserController] Login Request MISSING device-id header`);
			}

			// Pass full req so service can extract IP for compliance logging
			const response = await userService.login(req);
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},

	refreshToken: async (req, res) => {
		try {
			// Inject Device ID from Header if present (Critical for Session Takeover)
			const deviceId = req.headers['device-id'] || req.get('device-id');
			if (deviceId) {
				req.body.deviceId = deviceId;
			}
			const response = await userService.refreshToken(req);
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},

	sendOpt: async (req, res) => {
		try {
			const response = await userService.sendOpt(req);
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},
	verifyOtp: async (req, res) => {
		try {
			const response = await userService.verifyOtp(req);
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},
	userCreate: async (req, res) => {
		try {
			const response = await userService.userCreate(req);
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},
	adminCreate: async (req, res) => {
		try {
			const response = await userService.adminCreate(req);
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},
	adminUpdateUser: async (req, res) => {
		try {
			const response = await userService.adminUpdateUser({
				body: req.body,
				params: req.params,
				req,
				user: req.user
			});
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},
	adminLogin: async (req, res) => {
		try {
			const response = await userService.adminLogin(req);
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},

	userSignUp: async (req, res) => {
		try {
			const response = await userService.userSignUp(req);
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},

	setMpin: async (req, res) => {
		try {
			// Inject Device ID
			const deviceId = req.headers['device-id'] || req.get('device-id');
			if (deviceId) {
				req.body.deviceId = deviceId;
			}
			const response = await userService.setMpin(req);
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},

	// forgetPassword: async (req, res) => {
	// 	try {
	// 		let response = await userService.forgetPassword(req)
	// 		res.status(response.status).send(response);
	// 	} catch (error) {
	// 		res.status(400).send({ status: 400, message: error.message, data: {} });
	// 	}
	// },
	changePassword: async (req, res) => {
		try {
			let response = await userService.changePassword(req)
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},
	resetPassword: async (req, res) => {
		try {
			let response = await userService.resetPassword(req)
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},
	updateProfile: async (req, res) => {
		try {
			let response = await userService.updateProfile(req)
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},
	userList: async (req, res) => {
		try {
			// Pass current user ID for exclusion
			let response = await userService.userList({ query: req.query, currentUserId: req.user?._id })
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},
	userDelete: async (req, res) => {
		try {
			let response = await userService.userDelete({
				params: req.params,
				user: req.user,
				req
			})
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},
	userSuspend: async (req, res) => {
		try {
			let response = await userService.suspendUser({
				params: req.params,
				body: req.body,
				user: req.user,
				req
			});
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},
	userActivate: async (req, res) => {
		try {
			let response = await userService.activateUser({
				params: req.params,
				body: req.body,
				user: req.user,
				req
			});
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},
	logOutUser: async (req, res) => {
		try {
			const response = await userService.logOutUser(req);
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},
	userImageUpdate: async (req, res) => {
		try {
			const response = await userService.userImageUpdate(req);
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},
	userDetails: async (req, res) => {
		try {
			const response = await userService.userDetails(req);
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},

	dashboardCount: async (req, res) => {
		try {
			const response = await userService.dashboardCount(req);
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},
	bypassPayment: async (req, res) => {
		try {
			const response = await userService.bypassPayment(req);
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},
	acceptDisclaimer: async (req, res) => {
		try {
			// Middleware 'auth.tokenVerified' should populate req.user
			const userId = req.user._id;
			const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
			const { version } = req.body;
			const response = await userService.acceptDisclaimer({ userId, ip, version });
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},
	adminGenerateTempPin: async (req, res) => {
		try {
			const response = await userService.adminGenerateTempPin({
				params: req.params,
				user: req.user,
				req
			});
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	}
}
export default usersController