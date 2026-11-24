import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../domain/chat.dart';

/// REST writes have no offline queue. RTDB streams deliver committed messages.
class ChatRest {
  ChatRest(this.auth, this.endpoint, this.client);
  final FirebaseAuth auth;
  final Uri endpoint;
  final http.Client client;
  Future<Object?> request(
    String uid,
    String method,
    String path, [
    Object? body,
  ]) async {
    final user = auth.currentUser;
    if (user == null || user.uid != uid) {
      throw const ChatFailure('Phiên đăng nhập đã thay đổi.');
    }
    final token = await user.getIdToken();
    if (token == null || auth.currentUser?.uid != uid) {
      throw const ChatFailure('Cần đăng nhập lại.');
    }
    final uri = endpoint.replace(
      pathSegments: [
        if (path.isNotEmpty)
          ...path.split('/').take(path.split('/').length - 1),
        '${path.split('/').last}.json',
      ],
      queryParameters: {...endpoint.queryParameters, 'auth': token},
    );
    final request = http.Request(method, uri);
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    try {
      final result = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 12));
      if (result.statusCode == 401 || result.statusCode == 403) {
        throw const ChatFailure('Bạn không có quyền thực hiện thao tác này.');
      }
      if (result.statusCode != 200) {
        throw const ChatFailure(
          'Firebase chưa xác nhận thao tác. Hãy thử lại.',
        );
      }
      return jsonDecode(utf8.decode(result.bodyBytes));
    } on TimeoutException {
      throw const ChatFailure('Kết nối quá hạn. Có thể thử lại cùng tin nhắn.');
    } on http.ClientException {
      throw const ChatFailure(
        'Mất kết nối tới Firebase. Hãy kiểm tra mạng rồi thử lại.',
      );
    }
  }
}
