import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/cloudinary_config.dart';

/// Uploads incident photos to Cloudinary using an unsigned upload preset.
/// (Firebase Storage needs the paid Blaze plan, so a free service is used.)
class StorageService {
  StorageService({
    http.Client? client,
    this.cloudName = cloudinaryCloudName,
    this.uploadPreset = cloudinaryUploadPreset,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String cloudName;
  final String uploadPreset;

  Future<String> uploadIncidentPhoto({
    required String uid,
    required String incidentId,
    required File file,
  }) async {
    final bytes = await file.readAsBytes();
    return uploadBytes(uid: uid, incidentId: incidentId, bytes: bytes);
  }

  /// Split out so the request/response handling can be unit tested.
  Future<String> uploadBytes({
    required String uid,
    required String incidentId,
    required List<int> bytes,
  }) async {
    final uri =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final req = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = 'incident_photos/$uid'
      ..fields['public_id'] = incidentId
      ..files.add(http.MultipartFile.fromBytes('file', bytes,
          filename: '$incidentId.jpg'));
    final streamed =
        await _client.send(req).timeout(const Duration(seconds: 30));
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200) {
      throw Exception('Photo upload failed (${res.statusCode}): ${res.body}');
    }
    final url = (jsonDecode(res.body) as Map<String, dynamic>)['secure_url'];
    if (url is! String) throw Exception('Upload response had no image URL');
    return url;
  }

  /// Intentionally a no-op: deleting from Cloudinary needs the API secret,
  /// which must never be shipped inside a mobile app. The Firestore document
  /// (the only place the URL is stored) is deleted, so the image becomes
  /// unreachable. Documented as a limitation in the report.
  Future<void> deleteByUrl(String? url) async {}
}
