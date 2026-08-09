"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const class_validator_1 = require("class-validator");
const brokers_controller_1 = require("./brokers/brokers.controller");
async function main() {
    const dto = new brokers_controller_1.LinkBrokerDto();
    dto.brokerCode = 'ANGEL_ONE';
    dto.brokerClientId = 'M320967';
    const errors = await (0, class_validator_1.validate)(dto);
    if (errors.length > 0) {
        console.log('Validation failed:', errors);
    }
    else {
        console.log('Validation succeeded!');
    }
}
main();
//# sourceMappingURL=test-val.js.map