import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:frontend_new/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class AuthService extends ChangeNotifier {
  User? _user;
  String? _token;
  String? _error;
  bool _isLoading = false;
  final Dio _dio = Dio();
  static final String baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:5000/api';

  User? get user => _user;
  String? get token => _token;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  AuthService() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
      await _fetchUser();
    }
    notifyListeners();
  }

  Future<void> _fetchUser() async {
    try {
      final response = await _dio.get('/auth/me');
      _user = User.fromJson(response.data);
    } catch (e) {
      _token = null;
      _user = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('=== Login Debug Info ===');
      print('API URL: $baseUrl');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        if (responseData['token'] == null) {
          throw Exception('로그인 응답에 토큰이 없습니다.');
        }

        // 토큰 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', responseData['token']);
        
        // 사용자 정보 저장
        if (responseData['user'] != null) {
          final userData = responseData['user'];
          print('User data from server: $userData');
          
          try {
            _user = User(
              id: userData['id']?.toString() ?? '',
              name: userData['name']?.toString() ?? '',
              email: userData['email']?.toString() ?? '',
              gender: userData['gender']?.toString() ?? '미입력',
              birthDate: userData['birth_date'] != null 
                ? DateTime.parse(userData['birth_date'].toString()) 
                : DateTime.now(),
              address: userData['address']?.toString() ?? '미입력',
              detailAddress: userData['detail_address']?.toString() ?? '',
              disabilityType: userData['disability_type']?.toString() ?? '',
              gmfcsLevel: userData['gmfcs_level']?.toString() ?? '',
              developmentalType: userData['developmental_type']?.toString() ?? '',
              otherDisabilityName: userData['other_disability_name']?.toString() ?? '',
            );
          } catch (e) {
            print('Error creating User object: $e');
            print('User data that caused error: $userData');
            throw Exception('사용자 정보 처리 중 오류가 발생했습니다: $e');
          }
        }
        
        _token = responseData['token'];
        _dio.options.headers['Authorization'] = 'Bearer $_token';
        
        notifyListeners();
        return responseData;
      } else {
        throw Exception(responseData['error'] ?? '로그인에 실패했습니다.');
      }
    } catch (e) {
      print('Login error: $e');
      _token = null;
      _user = null;
      notifyListeners();
      throw Exception('로그인 중 오류가 발생했습니다: $e');
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      print('=== Registration Debug Info ===');
      print('API URL: $baseUrl');
      
      // 데이터 구조 변환
      final requestData = {
        'email': userData['email'],
        'password': userData['password'],
        'name': userData['name'],
        'gender': userData['gender'],
        'birth_date': userData['birthDate'].toString().split('T')[0],
        'address': userData['address'],
        'detail_address': userData['detailAddress'],
        'user_type': 'disabled',
        'disability_type': userData['disabilityType'],
        'disability_detail': userData['disabilityDetail'] ?? '',
      };
      
      print('Request Data: ${jsonEncode(requestData)}');
      
      final client = http.Client();
      try {
        print('Sending HTTP request...');
        
        // HTTP 요청 URL 생성
        final uri = Uri.parse('$baseUrl/auth/register');
        print('Request URI: ${uri.toString()}');
        
        // HTTP 헤더 설정
        final headers = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };
        print('Request Headers: $headers');
        
        // HTTP 요청 전송
        final response = await client.post(
          uri,
          headers: headers,
          body: jsonEncode(requestData),
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            print('Request timed out after 30 seconds');
            throw const HttpException('서버 응답 시간이 초과되었습니다. 서버 상태를 확인해주세요.');
          },
        );

        print('Response received');
        print('Status code: ${response.statusCode}');
        print('Response headers: ${response.headers}');
        print('Response body: ${response.body}');

        if (response.statusCode == 201) {
          final data = jsonDecode(response.body);
          print('Successfully parsed response data');
          
          // 토큰 저장
          if (data['token'] != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('token', data['token']);
            print('Token saved to SharedPreferences');
          }
          return data;
        } else {
          print('Server returned error status code: ${response.statusCode}');
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['error'] ?? errorData['message'] ?? '회원가입에 실패했습니다.';
          
          if (errorMessage.contains('Email already exists')) {
            throw Exception('이미 가입된 이메일입니다. 다른 이메일을 사용해주세요.');
          } else if (errorMessage.contains('Invalid email format')) {
            throw Exception('올바른 이메일 형식이 아닙니다.');
          } else if (errorMessage.contains('Invalid password format')) {
            throw Exception('비밀번호는 8자 이상이며, 대문자, 소문자, 숫자를 포함해야 합니다.');
          } else {
            throw Exception(errorMessage);
          }
        }
      } catch (e) {
        print('Error during HTTP request: $e');
        rethrow;
      } finally {
        client.close();
        print('HTTP client closed');
      }
    } catch (e) {
      print('=== Error Details ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      
      if (e is HttpException) {
        throw Exception(e.message);
      } else if (e is SocketException) {
        throw Exception('서버에 연결할 수 없습니다. 서버 주소와 포트를 확인해주세요.');
      } else {
        throw Exception('회원가입 중 오류가 발생했습니다: $e');
      }
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _dio.options.headers.remove('Authorization');

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    notifyListeners();
  }

  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String gender,
    required DateTime birthDate,
    required String address,
    required String detailAddress,
    required String disabilityType,
    String? gmfcsLevel,
    String? developmentalType,
    String? otherDisabilityName,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/auth/signup',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'gender': gender,
          'birthDate': birthDate.toIso8601String(),
          'address': address,
          'detailAddress': detailAddress,
          'disability': {
            'type': disabilityType,
            'gmfcsLevel': gmfcsLevel,
            'developmentalType': developmentalType,
            'otherDisabilityName': otherDisabilityName,
          },
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? '회원가입 중 오류가 발생했습니다.');
      }
      throw Exception('네트워크 오류가 발생했습니다.');
    }
  }

  Future<bool> checkEmailDuplicate(String email) async {
    try {
      final response = await _dio.post(
        '$baseUrl/auth/check-email',
        data: {'email': email},
      );
      return response.data['isDuplicate'] ?? false;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? '이메일 중복 확인 중 오류가 발생했습니다.');
      }
      throw Exception('네트워크 오류가 발생했습니다.');
    }
  }

  Future<void> updateDisabilityInfo({
    required String disabilityType,
    String? otherDisabilityName,
    String? gmfcsLevel,
    String? developmentalType,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('로그인이 필요합니다');
      }

      final response = await _dio.put(
        '/api/user/disability-info',
        data: {
          'disabilityType': disabilityType,
          if (otherDisabilityName != null) 'otherDisabilityName': otherDisabilityName,
          if (gmfcsLevel != null) 'gmfcsLevel': gmfcsLevel,
          if (developmentalType != null) 'developmentalType': developmentalType,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('장애 정보 업데이트에 실패했습니다');
      }
    } catch (e) {
      throw Exception('장애 정보 업데이트 중 오류가 발생했습니다: ${e.toString()}');
    }
  }
} 