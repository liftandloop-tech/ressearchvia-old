import '../services/api_client.service.dart';
import '../core/config/api.config.dart';
import '../core/models/segment.dart';
import '../services/snackbar.service.dart';
import '../services/api_exception.service.dart';

class RegistrationService {
  final ApiClient _apiClient = ApiClient();

  /// Fetch all segments for registration dropdown
  Future<List<Segment>> fetchSegments() async {
    try {
      final response = await _apiClient.get(ApiConfig.subscriptionsSegmentList);
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['data'] != null && data['data']['segmentsData'] != null) {
          final List<dynamic> segmentsData = data['data']['segmentsData'];
          return segmentsData
              .map((json) => Segment.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      final apiError = ApiErrorHandler.handleError(e);
      SnackbarService.showError('Failed to load segments: ${apiError.message}');
      return [];
    }
  }

  /// Fetch plans for a specific segment
  Future<List<RegistrationPlan>> fetchPlansForSegment(String segmentId) async {
    try {
      final url = '${ApiConfig.subscriptionsPlanList}?segmentId=$segmentId';
      final response = await _apiClient.get(url);
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['data'] != null && data['data']['data'] != null) {
          final List<dynamic> plansData = data['data']['data'];
          return plansData
              .map((json) => RegistrationPlan.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      final apiError = ApiErrorHandler.handleError(e);
      SnackbarService.showError('Failed to load plans: ${apiError.message}');
      return [];
    }
  }

  /// Fetch all plans (optional - for initial load)
  Future<List<RegistrationPlan>> fetchAllPlans() async {
    try {
      final response = await _apiClient.get(ApiConfig.subscriptionsPlanList);
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['data'] != null && data['data']['data'] != null) {
          final List<dynamic> plansData = data['data']['data'];
          return plansData
              .map((json) => RegistrationPlan.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      final apiError = ApiErrorHandler.handleError(e);
      SnackbarService.showError('Failed to load plans: ${apiError.message}');
      return [];
    }
  }
}
