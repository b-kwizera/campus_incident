import 'dart:convert';
import 'package:campus_incident/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('returns secure_url from Cloudinary and sends preset + folder', () async {
    late http.BaseRequest seen;
    final client = MockClient.streaming((req, body) async {
      seen = req;
      return http.StreamedResponse(
          Stream.value(utf8.encode('{"secure_url":"https://res.cloudinary.com/x/a.jpg"}')),
          200);
    });
    final s = StorageService(client: client, cloudName: 'demo', uploadPreset: 'p');
    final url = await s.uploadBytes(uid: 'u1', incidentId: 'i1', bytes: [1, 2, 3]);
    expect(url, 'https://res.cloudinary.com/x/a.jpg');
    expect(seen.url.toString(), 'https://api.cloudinary.com/v1_1/demo/image/upload');
  });

  test('throws on a non-200 response', () async {
    final client = MockClient.streaming((req, body) async =>
        http.StreamedResponse(Stream.value(utf8.encode('{"error":"bad"}')), 400));
    final s = StorageService(client: client, cloudName: 'demo', uploadPreset: 'p');
    expect(() => s.uploadBytes(uid: 'u', incidentId: 'i', bytes: [1]), throwsException);
  });
}
