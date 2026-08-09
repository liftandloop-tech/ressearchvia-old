import { RiskCode } from '../enums/risk-code.enum';

export interface RiskDecision {
  approved: boolean;
  reason?: string;
  code?: RiskCode;
}
