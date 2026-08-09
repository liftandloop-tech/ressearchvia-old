export class MockNotificationService {
  sendSMS = jest.fn().mockImplementation((mobile: string, message: string) => {
    return Promise.resolve({
      success: true,
      messageId: `msg91_mock_${Date.now()}`,
    });
  });

  sendPush = jest
    .fn()
    .mockImplementation((userId: string, title: string, body: string) => {
      return Promise.resolve({
        success: true,
        messageId: `fcm_mock_${Date.now()}`,
      });
    });

  sendEmail = jest
    .fn()
    .mockImplementation((email: string, subject: string, body: string) => {
      return Promise.resolve({
        success: true,
        messageId: `resend_mock_${Date.now()}`,
      });
    });
}
