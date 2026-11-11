import 'package:get/get.dart';
import 'package:spresearch_web/services/api.service.dart';

class BranchService extends ApiService {
  Future<Response> getBranches({bool? isActive, String? search}) {
    final query = <String, String>{};
    if (isActive != null) query['isActive'] = isActive.toString();
    if (search != null && search.trim().isNotEmpty) query['search'] = search.trim();
    return get('/branches', query: query.isNotEmpty ? query : null);
  }

  Future<Response> getBranch(String id) => get('/branches/$id');

  Future<Response> createBranch(Map<String, dynamic> data) =>
      post('/branches', data);

  Future<Response> updateBranch(String id, Map<String, dynamic> data) =>
      put('/branches/$id', data);

  Future<Response> deleteBranch(String id) =>
      delete('/branches/$id');
}

