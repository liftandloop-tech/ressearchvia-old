"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const axios_1 = __importDefault(require("axios"));
async function main() {
    try {
        const jwt = require('jsonwebtoken');
        const token = jwt.sign({
            _id: '65d49a71b12d3c001f3e792c',
            phone: '+919770784982',
            type: 'ACCESS'
        }, 'no_1$32@4');
        console.log('Using token:', token);
        const response = await axios_1.default.post('http://localhost:3000/brokers/link', {
            brokerCode: 'ANGEL_ONE',
            brokerClientId: 'M320967'
        }, {
            headers: {
                Authorization: `Bearer ${token}`
            }
        });
        console.log('Response status:', response.status);
        console.log('Response data:', response.data);
    }
    catch (error) {
        if (error.response) {
            console.log('Error Response status:', error.response.status);
            console.log('Error Response data:', error.response.data);
        }
        else {
            console.error('Error:', error.message);
        }
    }
}
main();
//# sourceMappingURL=test-link.js.map