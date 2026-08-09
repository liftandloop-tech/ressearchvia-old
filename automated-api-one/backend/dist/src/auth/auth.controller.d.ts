import { AuthService } from './auth.service';
export declare class SendOtpDto {
    mobile: string;
}
export declare class VerifyOtpDto {
    mobile: string;
    otp: string;
}
export declare class SetupMpinDto {
    mpin: string;
}
export declare class LoginMpinDto {
    mobile: string;
    mpin: string;
    deviceId: string;
    deviceName?: string;
    platform?: string;
}
export declare class AuthController {
    private readonly authService;
    constructor(authService: AuthService);
    sendOtp(dto: SendOtpDto): Promise<{
        success: boolean;
        message: string;
    }>;
    verifyOtp(dto: VerifyOtpDto): Promise<{
        accessToken: string;
        isMpinSet: boolean;
        userId: string;
    }>;
    setupMpin(req: any, dto: SetupMpinDto): Promise<{
        success: boolean;
    }>;
    loginMpin(dto: LoginMpinDto): Promise<{
        accessToken: string;
        userId: string;
    }>;
}
