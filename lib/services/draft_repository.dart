import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:heif_converter/heif_converter.dart';

/// Demo ini hanya menyimpan satu draft pada SATU perangkat.
/// Tidak memerlukan login, tabel database, maupun Worksheet 9.
class DraftRepository {
  static const _draftKey = 'kosfinder_device_demo_draft_v1';
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<Map<String, dynamic>> load() async {
    final raw = await _prefs.getString(_draftKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    return {};
  }

  Future<void> save(Map<String, dynamic> draft) async {
    await _prefs.setString(_draftKey, jsonEncode(draft));
  }

  
Future<String> savePermanentPhoto(XFile selected) async {
  final ext = selected.name.split('.').last.toLowerCase();

  // Periksa ukuran file asli.
  if (await selected.length() > 5 * 1024 * 1024) {
    throw const FormatException('Ukuran foto maksimal 5 MB.');
  }

  final root = await getApplicationDocumentsDirectory();
  final folder = Directory('${root.path}/kosfinder_photos');
  await folder.create(recursive: true);

  final timestamp = DateTime.now().microsecondsSinceEpoch;

  // HEIC/HEIF dikonversi menjadi JPG.
  if (ext == 'heic' || ext == 'heif') {
    final output = '${folder.path}/$timestamp.jpg';

    final convertedPath = await HeifConverter.convert(
      selected.path,
      output: output,
    );

    if (convertedPath == null || !await File(convertedPath).exists()) {
      throw const FormatException('Konversi HEIC ke JPG gagal.');
    }

    final convertedFile = File(convertedPath);

    // Periksa ukuran setelah konversi.
    if (await convertedFile.length() > 5 * 1024 * 1024) {
      await convertedFile.delete();
      throw const FormatException(
        'Ukuran foto setelah konversi melebihi 5 MB.',
      );
    }

    return convertedFile.path;
  }

  // JPG/JPEG/PNG tetap disimpan seperti sebelumnya.
  if (!{'jpg', 'jpeg', 'png'}.contains(ext)) {
    throw const FormatException(
      'Foto harus berupa JPG/JPEG/PNG/HEIC/HEIF.',
    );
  }

  final output = File('${folder.path}/$timestamp.$ext');
  await selected.saveTo(output.path);

  return output.path;
}


Future<void> deletePermanentPhoto(String photoPath) async {
  final root = await getApplicationDocumentsDirectory();
  final folder = Directory('${root.path}/kosfinder_photos');

  final photoFile = File(photoPath);

  // Pastikan file berada langsung di folder foto milik aplikasi.
  if (photoFile.parent.absolute.path != folder.absolute.path) {
    throw const FormatException(
      'Foto tidak berada di folder penyimpanan aplikasi.',
    );
  }

  if (await photoFile.exists()) {
    await photoFile.delete();
  }
}

}
