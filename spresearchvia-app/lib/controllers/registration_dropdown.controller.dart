import 'package:get/get.dart';
import '../services/registration.service.dart';
import '../core/models/segment.dart';

class RegistrationDropdownController extends GetxController {
  final RegistrationService _registrationService = RegistrationService();
  
  // Segments
  final segments = <Segment>[].obs;
  final selectedSegment = Rxn<Segment>();
  final isLoadingSegments = false.obs;
  
  // Plans
  final plans = <RegistrationPlan>[].obs;
  final selectedPlan = Rxn<RegistrationPlan>();
  final isLoadingPlans = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSegments();
  }

  Future<void> fetchSegments() async {
    try {
      isLoadingSegments.value = true;
      final fetchedSegments = await _registrationService.fetchSegments();
      segments.value = fetchedSegments
          .where((s) => s.segmentStatus?.toLowerCase() == 'active')
          .toList();
      
      // Auto-select segment "index" if available, else first segment
      if (segments.isNotEmpty) {
        final indexSegmentIdx = segments.indexWhere(
          (s) => s.segmentName.toLowerCase() == 'index option',
        );
        selectSegment(indexSegmentIdx != -1 ? segments[indexSegmentIdx] : segments.first);
      }
    } catch (e) {
      Get.log('Error fetching segments: $e');
    } finally {
      isLoadingSegments.value = false;
    }
  }

  void selectSegment(Segment segment) {
    selectedSegment.value = segment;
    // Clear plan selection when segment changes
    selectedPlan.value = null;
    // Fetch plans for the selected segment
    fetchPlansForSegment(segment.id);
  }

  Future<void> fetchPlansForSegment(String segmentId) async {
    try {
      isLoadingPlans.value = true;
      final fetchedPlans = await _registrationService.fetchPlansForSegment(segmentId);
      plans.value = fetchedPlans;
      
      // Auto-select plan "spark" if available, else first plan
      if (plans.isNotEmpty) {
        final sparkPlanIdx = plans.indexWhere(
          (p) => p.planName.toLowerCase() == 'spark',
        );
        selectedPlan.value = sparkPlanIdx != -1 ? plans[sparkPlanIdx] : plans.first;
      }
    } catch (e) {
      Get.log('Error fetching plans: $e');
    } finally {
      isLoadingPlans.value = false;
    }
  }

  void selectPlan(RegistrationPlan plan) {
    selectedPlan.value = plan;
  }

  // Getters for easy access
  String? get selectedSegmentId => selectedSegment.value?.id;
  String? get selectedSegmentName => selectedSegment.value?.segmentName;
  String? get selectedPlanId => selectedPlan.value?.id;
  String? get selectedPlanName => selectedPlan.value?.planName;
}
