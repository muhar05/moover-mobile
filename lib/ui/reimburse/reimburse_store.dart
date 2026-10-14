import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sqflite/sqflite.dart';

import '../core/themes/theme.dart';

/// Tipe dan penyimpanan reimburse (KAK §5.1.15–16, §6.4, §6.7). Keputusan
/// pemilik project 2026-10-14 (belum di DESIGN.md): data disimpan di SQLite
/// perangkat untuk demo; tipe di sini jadi usulan data ke backend
/// (docs/REIMBURSE_DATA.md). API U20–U24 masih Usulan (API_CONTRACT.md).
/// ponytail: tanpa server, tanpa sinkronisasi; ganti [ReimburseStore] dengan
/// klien API saat U20–U24 Terverifikasi (offline/antrean: Q-T5).

/// Kategori KAK §5.1.15. Nilai DB = [name].
enum ReimburseCategory {
  // Lucide tidak punya ikon tol: karcis (pemilik project 2026-10-11).
  toll('Tol', LucideIcons.ticket),
  parking('Parkir', LucideIcons.circleParking),
  fuel('BBM', LucideIcons.fuel),
  other('Lainnya', LucideIcons.receipt);

  const ReimburseCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Status KAK §6.7 (Submitted/Approved/Rejected/Paid); label DESIGN.md §4.7,
/// tone Lampiran A.2. Nilai DB = [name].
enum ReimburseStatus {
  submitted('Diajukan', StatusTone.neutral),
  approved('Disetujui', StatusTone.info),
  rejected('Ditolak', StatusTone.err),
  paid('Dibayar', StatusTone.ok);

  const ReimburseStatus(this.label, this.tone);
  final String label;
  final StatusTone tone;
}

/// Satu tahap timeline (KAK §6.4 langkah 5: waktu, pelaku, catatan).
/// Riwayat penolakan tetap ada (§6.4 langkah 3).
typedef TimelineEntry = ({
  ReimburseStatus status,
  DateTime at,
  String actor,
  String? note,
});

/// Bukti transfer Finance saat Dibayar (KAK §5.6.2). [proof] = path file
/// lokal; null = bukti contoh.
typedef Transfer = ({DateTime date, int amount, String? proof});

/// Isian form S15 (baru dan ajukan ulang).
typedef ReimburseDraft = ({
  DateTime date,
  ReimburseCategory category,
  int amount,
  String description,
  String? tripNumber,
  String? receiptPhoto,
});

typedef Reimbursement = ({
  int id,
  // Format RMB-YYYYMM-NNNN dari mock web (belum Terverifikasi). Di server
  // nomor diterbitkan sistem (KAK §5.1.15); di demo dibuat di perangkat.
  String number,
  ReimburseDraft draft,
  ReimburseStatus status,
  List<TimelineEntry> timeline,
  Transfer? transfer,
});

/// Catatan penolakan terakhir (ditampilkan di S15 ajukan ulang dan S16).
String? rejectionNote(Reimbursement r) => r.timeline.reversed
    .where((e) => e.status == ReimburseStatus.rejected)
    .firstOrNull
    ?.note;

/// Format D4: "Rp 1.234.567".
String formatRupiah(int amount) =>
    'Rp ${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => '.')}';

String _day(DateTime d) => d.toIso8601String().substring(0, 10);

/// Pelaku timeline. Nama pelaku dari server: Belum terverifikasi.
const driverActor = 'Anda (driver)';

/// Path DB; tes menggantinya dengan [inMemoryDatabasePath].
@visibleForTesting
String reimburseDbPath = 'moover.db';

/// Status muat: [items] null + [failed] false = memuat.
class ReimburseStore extends ChangeNotifier {
  Database? _db;
  List<Reimbursement>? items;
  bool failed = false;

  Reimbursement? byId(int id) => items?.where((r) => r.id == id).firstOrNull;

  Future<Database> _open() async => _db ??= await openDatabase(
    reimburseDbPath,
    version: 1,
    onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    onCreate: (db, _) async {
      for (final sql in schema) {
        await db.execute(sql);
      }
      await _seed(db);
    },
  );

  Future<void> load() async {
    failed = false;
    notifyListeners();
    try {
      final db = await _open();
      final rows = await db.query(
        'reimbursement',
        orderBy: 'expense_date DESC, id DESC',
      );
      final steps = await db.query('reimbursement_timeline', orderBy: 'id');
      items = [
        for (final r in rows)
          _fromRow(r, [
            for (final s in steps)
              if (s['reimbursement_id'] == r['id'])
                (
                  status: ReimburseStatus.values.byName(s['status']! as String),
                  at: DateTime.parse(s['at']! as String),
                  actor: s['actor']! as String,
                  note: s['note'] as String?,
                ),
          ]),
      ];
    } on Exception {
      failed = true;
    }
    notifyListeners();
  }

  /// Simpan pengajuan baru (status Diajukan); kembalikan nomornya.
  Future<String> submit(ReimburseDraft d) async {
    final db = await _open();
    final month = '${d.date.year}${d.date.month.toString().padLeft(2, '0')}';
    final number = await db.transaction((tx) async {
      final count = Sqflite.firstIntValue(
        await tx.rawQuery(
          'SELECT COUNT(*) FROM reimbursement WHERE number LIKE ?',
          ['RMB-$month-%'],
        ),
      )!;
      final number = 'RMB-$month-${(count + 1).toString().padLeft(4, '0')}';
      final id = await tx.insert('reimbursement', {
        'number': number,
        ..._draftRow(d),
        'status': ReimburseStatus.submitted.name,
      });
      await _step(tx, id, ReimburseStatus.submitted, DateTime.now(), null);
      return number;
    });
    await load();
    return number;
  }

  /// Ajukan ulang yang Ditolak (KAK §6.4): isian diganti, status kembali
  /// Diajukan, timeline penolakan tetap.
  Future<void> resubmit(int id, ReimburseDraft d) async {
    final db = await _open();
    await db.transaction((tx) async {
      await tx.update(
        'reimbursement',
        {..._draftRow(d), 'status': ReimburseStatus.submitted.name},
        where: 'id = ?',
        whereArgs: [id],
      );
      await _step(
        tx,
        id,
        ReimburseStatus.submitted,
        DateTime.now(),
        'Diajukan ulang setelah diperbaiki.',
      );
    });
    await load();
  }

  @visibleForTesting
  Future<void> reset() async {
    await _db?.close();
    _db = null;
    items = null;
    failed = false;
  }
}

final reimburseStore = ReimburseStore();

/// Folder file foto nota (folder DB aplikasi, tetap ada saat cache dibersihkan).
/// ponytail: tanpa path_provider (bukan dependency langsung); file tidak
/// dihapus saat pengajuan diganti. Upload ke server: Q-T1.
Future<String> keepReceiptPhoto(String tempPath) async {
  final dir = await getDatabasesPath();
  final file = await File(tempPath)
      .copy('$dir/nota_${DateTime.now().microsecondsSinceEpoch}.jpg');
  return file.path;
}

/// Skema SQLite (cermin tipe di atas; lihat docs/REIMBURSE_DATA.md).
const schema = [
  '''
CREATE TABLE reimbursement (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  number TEXT NOT NULL UNIQUE,
  expense_date TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('toll','parking','fuel','other')),
  amount INTEGER NOT NULL CHECK (amount > 0),
  description TEXT NOT NULL,
  trip_number TEXT,
  receipt_photo TEXT,
  status TEXT NOT NULL
    CHECK (status IN ('submitted','approved','rejected','paid')),
  transfer_date TEXT,
  transfer_amount INTEGER,
  transfer_proof TEXT
)''',
  '''
CREATE TABLE reimbursement_timeline (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  reimbursement_id INTEGER NOT NULL
    REFERENCES reimbursement(id) ON DELETE CASCADE,
  status TEXT NOT NULL
    CHECK (status IN ('submitted','approved','rejected','paid')),
  at TEXT NOT NULL,
  actor TEXT NOT NULL,
  note TEXT
)''',
];

Map<String, Object?> _draftRow(ReimburseDraft d) => {
  'expense_date': _day(d.date),
  'category': d.category.name,
  'amount': d.amount,
  'description': d.description,
  'trip_number': d.tripNumber,
  'receipt_photo': d.receiptPhoto,
};

Future<void> _step(
  DatabaseExecutor db,
  int id,
  ReimburseStatus status,
  DateTime at,
  String? note, {
  String actor = driverActor,
}) => db.insert('reimbursement_timeline', {
  'reimbursement_id': id,
  'status': status.name,
  'at': at.toIso8601String(),
  'actor': actor,
  'note': note,
});

Reimbursement _fromRow(Map<String, Object?> r, List<TimelineEntry> timeline) {
  final transferDate = r['transfer_date'] as String?;
  return (
    id: r['id']! as int,
    number: r['number']! as String,
    draft: (
      date: DateTime.parse(r['expense_date']! as String),
      category: ReimburseCategory.values.byName(r['category']! as String),
      amount: r['amount']! as int,
      description: r['description']! as String,
      tripNumber: r['trip_number'] as String?,
      receiptPhoto: r['receipt_photo'] as String?,
    ),
    status: ReimburseStatus.values.byName(r['status']! as String),
    timeline: timeline,
    transfer: transferDate == null
        ? null
        : (
            date: DateTime.parse(transferDate),
            amount: r['transfer_amount']! as int,
            proof: r['transfer_proof'] as String?,
          ),
  );
}

/// MOCK/DEMO: contoh awal saat DB dibuat, satu per status (dari data mock
/// tab Reimburse sebelumnya). Pelaku fiktif berdasarkan peran KAK.
Future<void> _seed(Database db) async {
  const approver = 'Group Head HC (contoh)';
  const finance = 'Finance (contoh)';
  final seeds =
      <
        (
          String,
          String,
          ReimburseCategory,
          int,
          String,
          String?,
          ReimburseStatus,
          List<(ReimburseStatus, String, String, String?)>,
        )
      >[
        (
          'RMB-202610-0001',
          '2026-10-01',
          ReimburseCategory.other,
          75000,
          'Cuci kendaraan dinas (contoh)',
          null,
          ReimburseStatus.rejected,
          [
            (ReimburseStatus.submitted, '2026-10-01T17:05', driverActor, null),
            (
              ReimburseStatus.rejected,
              '2026-10-02T09:20',
              approver,
              'Foto nota buram, nominal tidak terbaca. Unggah ulang foto nota.',
            ),
          ],
        ),
        (
          'RMB-202610-0002',
          '2026-10-03',
          ReimburseCategory.parking,
          20000,
          'Parkir di Kantor Cabang (contoh)',
          null,
          ReimburseStatus.paid,
          [
            (ReimburseStatus.submitted, '2026-10-03T16:40', driverActor, null),
            (ReimburseStatus.approved, '2026-10-04T08:15', approver, null),
            (
              ReimburseStatus.paid,
              '2026-10-06T11:00',
              finance,
              'Ditransfer ke rekening driver.',
            ),
          ],
        ),
        (
          'RMB-202610-0003',
          '2026-10-06',
          ReimburseCategory.fuel,
          300000,
          'Isi BBM sebelum trip luar kota (contoh)',
          null,
          ReimburseStatus.approved,
          [
            (ReimburseStatus.submitted, '2026-10-06T18:10', driverActor, null),
            (ReimburseStatus.approved, '2026-10-07T10:30', approver, null),
          ],
        ),
        (
          'RMB-202610-0004',
          '2026-10-08',
          ReimburseCategory.toll,
          45000,
          'Tol Kantor Pusat → Bandara (contoh)',
          'TRP-20261008-0003',
          ReimburseStatus.submitted,
          [(ReimburseStatus.submitted, '2026-10-08T17:30', driverActor, null)],
        ),
      ];
  for (final (number, date, category, amount, desc, trip, status, steps)
      in seeds) {
    final id = await db.insert('reimbursement', {
      'number': number,
      'expense_date': date,
      'category': category.name,
      'amount': amount,
      'description': desc,
      'trip_number': trip,
      'status': status.name,
      if (status == ReimburseStatus.paid) ...{
        'transfer_date': '2026-10-06',
        'transfer_amount': amount,
      },
    });
    for (final (s, at, actor, note) in steps) {
      await _step(db, id, s, DateTime.parse(at), note, actor: actor);
    }
  }
}
