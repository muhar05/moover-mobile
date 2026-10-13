import 'dart:async';
import 'dart:io';

import 'package:flutter_map/flutter_map.dart';

/// Dijalankan Flutter sebelum setiap file tes. Cache tile bawaan flutter_map
/// (peta S07/S08) adalah singleton yang memanggil path_provider (plugin, tidak
/// ada di tes). Dibuat di sini, di luar zona waktu palsu testWidgets, dengan
/// folder sementara; bila dibuat di dalam satu tes, tes berikutnya menunggu
/// cache selamanya.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  BuiltInMapCachingProvider.getOrCreateInstance(
    cacheDirectory: Directory.systemTemp.createTempSync('moover_tiles').path,
  );
  await testMain();
}
