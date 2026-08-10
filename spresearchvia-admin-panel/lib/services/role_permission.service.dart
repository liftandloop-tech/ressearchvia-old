import 'package:get/get.dart';
import 'package:spresearch_web/services/api.service.dart';

class RolePermissionService extends ApiService {
  // Permission Group endpoints
  Future<Response> getPermissionGroups() => get('/permission-groups');
  
  Future<Response> createPermissionGroup(Map<String, dynamic> data) =>
      post('/permission-groups', data);

  Future<Response> updatePermissionGroup(String id, Map<String, dynamic> data) =>
      put('/permission-groups/$id', data);

  Future<Response> deletePermissionGroup(String id) =>
      delete('/permission-groups/$id');

  // Role endpoints
  Future<Response> getRoles() => get('/roles');

  Future<Response> createRole(Map<String, dynamic> data) =>
      post('/roles', data);

  Future<Response> updateRole(String id, Map<String, dynamic> data) =>
      put('/roles/$id', data);

  Future<Response> deleteRole(String id) =>
      delete('/roles/$id');
}
