import 'package:get/get.dart';
import '../../controllers/segment_plan.controller.dart';

class SegmentPlanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SegmentPlanController());
  }
}
