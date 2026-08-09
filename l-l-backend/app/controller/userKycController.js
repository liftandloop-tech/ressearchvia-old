import userKycService from "../services/userKycService.js"
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const usersKycController = {
	pancardUpload: async (req, res) => {
		try {
			const response = await userKycService.pancardUpload(req);
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},
	aadhaarUpload: async (req, res) => {
		try {
			const response = await userKycService.aadhaarUpload(req);
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},
	usersDocKyc: async (req, res) => {
		try {
			const response = await userKycService.usersDocKyc(req);
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},
	kycStatusChange: async (req, res) => {
		try {
			const response = await userKycService.kycChangeStatus(req);
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},
	updateGateStatus: async (req, res) => {
		try {
			const response = await userKycService.updateGateStatus(req);
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},
	kycDocList: async (req, res) => {
		try {
			const response = await userKycService.kycDocList(req);
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},
	uploadKycVideo: async (req, res) => {
		try {
			const response = await userKycService.uploadKycVideo(req);
			res.status(response.status).send(response);
		} catch (error) {
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},
	updateAdminKycDocument: async (req, res) => {
		try {
			console.log('[Admin Doc Update] Request:', {
				userId: req.params.id,
				docType: req.query.docType,
				hasFile: !!req.file,
				query: req.query
			});
			const response = await userKycService.updateAdminKycDocument(req);
			res.status(response.status).send(response);
		} catch (error) {
			console.error('[Admin Doc Update] Controller Error:', error);
			res.status(400).send({ status: 400, message: error.message, data: {} });
		}
	},
	streamKycVideo: async (req, res) => {
		try {
			const { filename } = req.params;
			const __filename = fileURLToPath(import.meta.url);
			const __dirname = path.dirname(__filename);
			const videoPath = path.join(__dirname, "../uploads/kycvid", filename);

			if (!fs.existsSync(videoPath)) {
				return res.status(404).send("Video not found");
			}

			const stat = fs.statSync(videoPath);
			const fileSize = stat.size;
			const range = req.headers.range;

			if (range) {
				const parts = range.replace(/bytes=/, "").split("-");
				const start = parseInt(parts[0], 10);
				const end = parts[1] ? parseInt(parts[1], 10) : fileSize - 1;
				const chunksize = (end - start) + 1;
				const file = fs.createReadStream(videoPath, { start, end });
				const head = {
					'Content-Range': `bytes ${start}-${end}/${fileSize}`,
					'Accept-Ranges': 'bytes',
					'Content-Length': chunksize,
					'Content-Type': 'video/mp4',
					'Access-Control-Allow-Origin': '*',
				};
				res.writeHead(206, head);
				file.pipe(res);
			} else {
				const head = {
					'Content-Length': fileSize,
					'Content-Type': 'video/mp4',
					'Access-Control-Allow-Origin': '*',
				};
				res.writeHead(200, head);
				fs.createReadStream(videoPath).pipe(res);
			}
		} catch (error) {
			console.error("Stream Error:", error);
			res.status(500).send(error.message);
		}
	},
	serveKycImage: async (req, res) => {
		try {
			const { filename } = req.params;
			const __filename = fileURLToPath(import.meta.url);
			const __dirname = path.dirname(__filename);
			const imagePath = path.join(__dirname, "../uploads/kycimg", filename);

			if (!fs.existsSync(imagePath)) {
				return res.status(404).send("Image not found");
			}
			res.header("Access-Control-Allow-Origin", "*");
			res.sendFile(imagePath);
		} catch (error) {
			console.error("Image Serve Error:", error);
			res.status(500).send(error.message);
		}
	},
	downloadDigioDocument: async (req, res) => {
		try {
			const { document_id } = req.query;
			if (!document_id) {
				return res.status(400).send({ status: 400, message: "document_id is required" });
			}
			const response = await userKycService.downloadDigioDocument(document_id);

			if (response.status === 200) {
				const buffer = Buffer.from(response.data);
				res.setHeader('Content-Type', 'application/pdf');
				res.setHeader('Content-Disposition', `attachment; filename=agreement_${document_id}.pdf`);
				res.setHeader('Content-Length', buffer.length);
				return res.end(buffer);
			} else {

				return res.status(response.status).send(response);
			}
		} catch (error) {
			console.error("[Digio Download Controller Error]:", error);
			res.status(500).send({ status: 500, message: error.message });
		}
	}
}

export default usersKycController