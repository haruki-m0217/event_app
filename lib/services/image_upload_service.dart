import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ImageUploadService {
  static const String _apiKey = 'd38a98576625c5237270a5ff27e3bf12';
  static const String _uploadUrl = 'https://api.imgbb.com/1/upload';

  /// 画像バイトデータをimgbbにアップロードし、ダウンロードURLを返す
  static Future<String> uploadBytes(Uint8List bytes) async {
    final base64Image = base64Encode(bytes);
    final response = await http.post(
      Uri.parse(_uploadUrl),
      body: {
        'key': _apiKey,
        'image': base64Image,
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        return json['data']['url'] as String;
      }
    }
    throw Exception('imgbbへのアップロードに失敗しました: ${response.body}');
  }
}
