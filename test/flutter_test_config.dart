import 'dart:async';
import 'dart:io';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moover/ui/reimburse/reimburse_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Dijalankan Flutter sebelum setiap file tes. Cache tile bawaan flutter_map
/// (peta S07/S08) adalah singleton yang memanggil path_provider (plugin, tidak
/// ada di tes). Dibuat di sini, di luar zona waktu palsu testWidgets, dengan
/// folder sementara; bila dibuat di dalam satu tes, tes berikutnya menunggu
/// cache selamanya.
/// SQLite reimburse: FFI tanpa isolate (selesai lewat microtask, aman di
/// waktu palsu) + DB di memori, dibuat ulang tiap tes dari seed.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  BuiltInMapCachingProvider.getOrCreateInstance(
    cacheDirectory: Directory.systemTemp.createTempSync('moover_tiles').path,
  );
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;
  reimburseDbPath = inMemoryDatabasePath;
  setUp(reimburseStore.reset);
  await testMain();
}
