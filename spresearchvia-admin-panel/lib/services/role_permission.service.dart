import 'package:get/get.dart';
import 'package:spresearch_web/services/api.service.dart';

class RolePermissionService extends ApiService {
  // Department endpoints
  Future<Response> getDepartments() => get('/departments');

  Future<Response> getDepartmentPages() => get('/departments/pages');

  Future<Response> createDepartment(Map<String, dynamic> data) =>
      post('/departments', data);

  Future<Response> updateDepartment(String id, Map<String, dynamic> data) =>
      put('/departments/$id', data);

  Future<Response> deleteDepartment(String id) =>
      delete('/departments/$id');

  // Permission Group endpoints
  Future<Response> getPermissionGroups({String? departmentId}) {
    final query = departmentId != null ? '?departmentId=$departmentId' : '';
    return get('/permission-groups$query');
  }
  
  Future<Response> createPermissionGroup(Map<String, dynamic> data) =>
      post('/permission-groups', data);

  Future<Response> updatePermissionGroup(String id, Map<String, dynamic> data) =>
      put('/permission-groups/$id', data);

  Future<Response> deletePermissionGroup(String id) =>
      delete('/permission-groups/$id');

  // Role endpoints
  Future<Response> getRoles({String? departmentId}) {
    final query = departmentId != null ? '?departmentId=$departmentId' : '';
    return get('/roles$query');
  }

  Future<Response> createRole(Map<String, dynamic> data) =>
      post('/roles', data);

  Future<Response> updateRole(String id, Map<String, dynamic> data) =>
      put('/roles/$id', data);

  Future<Response> deleteRole(String id) =>
      delete('/roles/$id');
}
