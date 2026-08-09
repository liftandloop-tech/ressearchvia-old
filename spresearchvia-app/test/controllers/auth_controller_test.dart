import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:spresearchvia/controllers/auth.controller.dart';
import 'package:spresearchvia/services/api_client.service.dart';
import 'package:spresearchvia/services/secure_storage.service.dart';

class MockApiClient implements ApiClient {
  Future<Response> Function(String path)? getHandler;

  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool forceRefresh = false,
  }) async {
    if (getHandler != null) {
      return getHandler!(path);
    }
    throw UnimplementedError();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSecureStorageService implements SecureStorageService {
  bool? cachedStatus;
  String? userId;
  bool? lastCachedStatus;

  @override
  Future<bool?> getCachedSubscriptionStatus() async => cachedStatus;

  @override
  Future<String?> getUserId() async => userId;

  @override
  Future<void> cacheSubscriptionStatus(bool status) async {
    lastCachedStatus = status;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AuthController authController;
  late MockApiClient mockApiClient;
  late MockSecureStorageService mockStorage;

  setUp(() {
    mockApiClient = MockApiClient();
    mockStorage = MockSecureStorageService();
    authController = AuthController(
      apiClient: mockApiClient,
      storage: mockStorage,
    );
  });

  group('AuthController - hasActiveSubscription', () {
    test('returns true when activePlan is valid', () async {
      mockStorage.userId = 'user123';
      mockStorage.cachedStatus = null;

      mockApiClient.getHandler = (path) async {
        return Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 200,
          data: {
            'data': {
              'activePlan': {
                'status': 'active',
                'endDate': DateTime.now()
                    .add(const Duration(days: 30))
                    .toIso8601String(),
              },
              'userPlan': [],
            },
          },
        );
      };

      final result = await authController.hasActiveSubscription(
        forceRefresh: true,
      );
      expect(result, true);
      expect(mockStorage.lastCachedStatus, true);
    });

/*
    test(
      'returns true when activePlan is null but userPlan has active item',
      () async {
        mockStorage.userId = 'user123';

        mockApiClient.getHandler = (path) async {
          return Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 200,
            data: {
              'data': {
                'activePlan': null,
                'userPlan': [
                  {
                    'status': 'expired',
                    'endDate': DateTime.now()
                        .subtract(const Duration(days: 10))
                        .toIso8601String(),
                  },
                  {
                    'status': 'active',
                    'endDate': DateTime.now()
                        .add(const Duration(days: 30))
                        .toIso8601String(),
                  },
                ],
              },
            },
          );
        };

        final result = await authController.hasActiveSubscription(
          forceRefresh: true,
        );
        expect(result, true);
        expect(mockStorage.lastCachedStatus, true);
      },
    );
*/

    test('returns false when no active plan exists', () async {
      mockStorage.userId = 'user123';

      mockApiClient.getHandler = (path) async {
        return Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 200,
          data: {
            'data': {
              'activePlan': null,
              'userPlan': [
                {
                  'status': 'expired',
                  'endDate': DateTime.now()
                      .subtract(const Duration(days: 10))
                      .toIso8601String(),
                },
              ],
            },
          },
        );
      };

      final result = await authController.hasActiveSubscription(
        forceRefresh: true,
      );
      expect(result, false);
      expect(mockStorage.lastCachedStatus, false);
    });
  });
}
