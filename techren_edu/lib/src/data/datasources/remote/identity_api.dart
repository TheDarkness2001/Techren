import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../domain/entities/branch.dart';
import '../../../domain/entities/dashboard_data.dart';
import '../../../domain/entities/paginated_result.dart';
import '../../../domain/entities/person.dart';

PaginatedResult<T> _parsePaginated<T>(
  Response<dynamic> response,
  T Function(Map<String, dynamic>) fromJson,
) {
  final data = response.data as Map<String, dynamic>;
  final items = (data['data'] as List<dynamic>).map((e) => fromJson(e as Map<String, dynamic>)).toList();
  final meta = data['meta'] as Map<String, dynamic>? ?? {};
  return PaginatedResult(
    items: items,
    page: meta['page'] as int? ?? 1,
    limit: meta['limit'] as int? ?? 20,
    total: meta['total'] as int? ?? items.length,
    totalPages: meta['totalPages'] as int? ?? 1,
  );
}

class IdentityApi {
  IdentityApi(this._client);

  final DioClient _client;

  Future<DashboardData> getDashboard() async {
    final response = await _client.dio.get('/dashboard');
    return DashboardData.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<PaginatedResult<Branch>> getBranches(PageMeta meta) async {
    final response = await _client.dio.get('/branches', queryParameters: meta.toQuery());
    return _parsePaginated(response, Branch.fromJson);
  }

  Future<Branch> createBranch({required String name, String? address, String? phone}) async {
    final response = await _client.dio.post('/branches', data: {
      'name': name,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
    });
    return Branch.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Branch> updateBranch({
    required String id,
    required String name,
    String? address,
    String? phone,
  }) async {
    final response = await _client.dio.put('/branches/$id', data: {
      'name': name,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
    });
    return Branch.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Branch> setBranchStatus(String id, bool isActive) async {
    final response = await _client.dio.patch('/branches/$id/status', data: {'isActive': isActive});
    return Branch.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<BranchStats> getBranchStats(String branchId) async {
    final response = await _client.dio.get('/branches/$branchId/stats');
    return BranchStats.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<PaginatedResult<Person>> getStudents(PageMeta meta) async {
    final response = await _client.dio.get('/students', queryParameters: meta.toQuery());
    return _parsePaginated(
      response,
      (json) => Person.fromJson({...json, 'userType': 'student'}),
    );
  }

  Future<PaginatedResult<Person>> getTeachers(PageMeta meta) async {
    final response = await _client.dio.get('/teachers', queryParameters: meta.toQuery());
    return _parsePaginated(
      response,
      (json) => Person.fromJson({...json, 'userType': 'teacher'}),
    );
  }

  Future<Person> createStudent({
    required String name,
    required String email,
    required String password,
    String? parentName,
    String? parentPhone,
    String? branchId,
  }) async {
    final response = await _client.dio.post('/students', data: {
      'name': name,
      'email': email,
      'password': password,
      if (parentName != null) 'parentName': parentName,
      if (parentPhone != null) 'parentPhone': parentPhone,
      if (branchId != null) 'branchId': branchId,
    });
    return Person.fromJson({...response.data['data'] as Map<String, dynamic>, 'userType': 'student'});
  }

  Future<Person> createTeacher({
    required String name,
    required String email,
    required String password,
    String? phone,
    String role = 'teacher',
    String? branchId,
  }) async {
    final response = await _client.dio.post('/teachers', data: {
      'name': name,
      'email': email,
      'password': password,
      if (phone != null) 'phone': phone,
      'role': role,
      if (branchId != null) 'branchId': branchId,
    });
    return Person.fromJson({...response.data['data'] as Map<String, dynamic>, 'userType': 'teacher'});
  }

  Future<Person> updateStudent({
    required String id,
    required String name,
    required String email,
    String? parentName,
    String? parentPhone,
    String? password,
  }) async {
    final response = await _client.dio.put('/students/$id', data: {
      'name': name,
      'email': email,
      if (parentName != null) 'parentName': parentName,
      if (parentPhone != null) 'parentPhone': parentPhone,
      if (password != null && password.isNotEmpty) 'password': password,
    });
    return Person.fromJson({...response.data['data'] as Map<String, dynamic>, 'userType': 'student'});
  }

  Future<Person> updateTeacher({
    required String id,
    required String name,
    required String email,
    String? phone,
    String? password,
  }) async {
    final response = await _client.dio.put('/teachers/$id', data: {
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
      if (password != null && password.isNotEmpty) 'password': password,
    });
    return Person.fromJson({...response.data['data'] as Map<String, dynamic>, 'userType': 'teacher'});
  }

  Future<Person> setStudentStatus(String id, String status) async {
    final response = await _client.dio.patch('/students/$id/status', data: {'status': status});
    return Person.fromJson({...response.data['data'] as Map<String, dynamic>, 'userType': 'student'});
  }

  Future<Person> setTeacherStatus(String id, String status) async {
    final response = await _client.dio.put('/teachers/$id', data: {'status': status});
    return Person.fromJson({...response.data['data'] as Map<String, dynamic>, 'userType': 'teacher'});
  }

  Future<Person> uploadStudentPhoto(
    String id, {
    String? filePath,
    Uint8List? bytes,
    required String fileName,
  }) async {
    final form = FormData.fromMap({
      'photo': await _photoPart(filePath: filePath, bytes: bytes, fileName: fileName),
    });
    final response = await _client.dio.post('/students/$id/photo', data: form);
    return Person.fromJson({...response.data['data'] as Map<String, dynamic>, 'userType': 'student'});
  }

  Future<Person> uploadTeacherPhoto(
    String id, {
    String? filePath,
    Uint8List? bytes,
    required String fileName,
  }) async {
    final form = FormData.fromMap({
      'photo': await _photoPart(filePath: filePath, bytes: bytes, fileName: fileName),
    });
    final response = await _client.dio.post('/teachers/$id/photo', data: form);
    return Person.fromJson({...response.data['data'] as Map<String, dynamic>, 'userType': 'teacher'});
  }

  Future<MultipartFile> _photoPart({
    String? filePath,
    Uint8List? bytes,
    required String fileName,
  }) async {
    if (bytes != null) {
      return MultipartFile.fromBytes(bytes, filename: fileName);
    }
    if (filePath != null && filePath.isNotEmpty) {
      return MultipartFile.fromFile(filePath, filename: fileName);
    }
    throw ArgumentError('Photo bytes or file path is required');
  }
}
