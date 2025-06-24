import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ManagerFinalScreen extends StatelessWidget {
  final String eventId;
  const ManagerFinalScreen({Key? key, required this.eventId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text('Seating & Preferences'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            tooltip: 'Export CSV',
            onPressed: () async {
              await _exportCsv(context, eventId);
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('events').doc(eventId).snapshots(),
        builder: (ctx, eventSnap) {
          if (eventSnap.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (!eventSnap.hasData || !eventSnap.data!.exists)
            return Center(child: Text('Event not found'));

          final eventData = eventSnap.data!.data() as Map<String, dynamic>;
          final seating = Map<String, dynamic>.from(eventData['seating'] ?? {});
          final participants =
          List<String>.from(eventData['allowedParticipants'] ?? []);

          if (seating.isEmpty) {
            return Center(child: Text('No seating plan yet'));
          }

          return FutureBuilder<QuerySnapshot>(
            future: _db
                .collectionGroup('preferences')
                .where('eventId', isEqualTo: eventId)
                .get(),
            builder: (ctx2, prefSnap) {
              if (prefSnap.connectionState == ConnectionState.waiting)
                return Center(child: CircularProgressIndicator());
              if (prefSnap.hasError)
                return Center(child: Text('Error loading preferences'));

              final Map<String, Map<String, dynamic>> prefsMap = {};
              for (var doc in prefSnap.data!.docs) {
                final path = doc.reference.path.split('/');
                final uid = path[path.indexOf('users') + 1];
                prefsMap[uid] = doc.data() as Map<String, dynamic>;
              }

              return FutureBuilder<Map<String, String>>(
                future: _loadNamesMap(eventId),
                builder: (context, namesSnap) {
                  if (!namesSnap.hasData) return Center(child: CircularProgressIndicator());
                  final namesMap = namesSnap.data!;

                  return FutureBuilder<QuerySnapshot>(
                    future: _db
                        .collectionGroup('preferences')
                        .where('eventId', isEqualTo: eventId)
                        .get(),
                    builder: (ctx2, prefSnap) {
                      if (prefSnap.connectionState == ConnectionState.waiting)
                        return Center(child: CircularProgressIndicator());
                      if (prefSnap.hasError)
                        return Center(child: Text('Error loading preferences'));

                      final Map<String, Map<String, dynamic>> prefsMap = {};
                      for (var doc in prefSnap.data!.docs) {
                        final path = doc.reference.path.split('/');
                        final uid = path[path.indexOf('users') + 1];
                        prefsMap[uid] = doc.data() as Map<String, dynamic>;
                      }

                      return ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: participants.length,
                        itemBuilder: (ctx3, i) {
                          final uid = participants[i];
                          final displayName = namesMap[uid] ?? uid;

                          final seatInfo = seating[uid];
                          String seatText = seatInfo is Map
                              ? 'Row: ${seatInfo['row']}, Col: ${seatInfo['col']}'
                              : 'Chair: $seatInfo';

                          final prefs = prefsMap[uid] ?? {};

                          final rawTo = prefs['preferToList'];
                          final toList = (rawTo is Map)
                              ? rawTo.keys.map((k) => k.toString()).toList()
                              : (rawTo is List) ? rawTo.map((e) => e.toString()).toList() : [];

                          final rawNot = prefs['preferNotToList'];
                          final notToList = (rawNot is Map)
                              ? rawNot.keys.map((k) => k.toString()).toList()
                              : (rawNot is List) ? rawNot.map((e) => e.toString()).toList() : [];

                          final options = (prefs['options'] as Map<String, dynamic>?) ?? {};

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Icon(Icons.event_seat),
                                    SizedBox(width: 8),
                                    Text('User: $displayName',
                                        style: TextStyle(fontWeight: FontWeight.bold)),
                                  ]),
                                  SizedBox(height: 4),
                                  Text(seatText),
                                  if (options.isNotEmpty) ...[
                                    SizedBox(height: 8),
                                    Text('Options:', style: TextStyle(fontWeight: FontWeight.w500)),
                                    ...options.entries.map((e) => Text('• ${e.key}: ${e.value}')),
                                  ],
                                  if (toList.isNotEmpty) ...[
                                    SizedBox(height: 8),
                                    Text('Prefer to be with:', style: TextStyle(fontWeight: FontWeight.w500)),
                                    ...toList.map((u) => Text('• $u')),
                                  ],
                                  if (notToList.isNotEmpty) ...[
                                    SizedBox(height: 8),
                                    Text('Prefer not to be with:', style: TextStyle(fontWeight: FontWeight.w500)),
                                    ...notToList.map((u) => Text('• $u')),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, String>> _loadNamesMap(String eventId) async {
    final _db = FirebaseFirestore.instance;
    final Map<String, String> namesMap = {};

    final usersQuery = await _db.collection('users').get();
    for (var userDoc in usersQuery.docs) {
      final data = userDoc.data() as Map<String, dynamic>;
      var rawPhone = (data['phone'] ?? '').toString().trim();
      final name = (data['name'] ?? '').toString().trim();
      if (rawPhone.isEmpty) continue;

      if (rawPhone.startsWith('0')) {
        rawPhone = '+972${rawPhone.substring(1)}';
      }
      namesMap[rawPhone] = name;
    }

    final parts = await _db
        .collection('events')
        .doc(eventId)
        .collection('participants')
        .get();

    for (var doc in parts.docs) {
      final data = doc.data();
      final phone = (data['phone'] ?? '').toString().trim();
      final name = (data['name'] ?? '').toString().trim();
      if (phone.isNotEmpty && name.isNotEmpty) {
        namesMap[phone] = name;
      }
    }

    return namesMap;
  }


  Future<void> _exportCsv(BuildContext context, String eventId) async {
    final _db = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;

    try {
      final evDoc = await _db.collection('events').doc(eventId).get();
      final evData = evDoc.data()!;
      final seating = Map<String, dynamic>.from(evData['seating'] ?? {});
      final participants = List<String>.from(evData['allowedParticipants'] ?? []);

      final prefQuery = await _db
          .collectionGroup('preferences')
          .where('eventId', isEqualTo: eventId)
          .get();
      final prefsMap = <String, Map<String, dynamic>>{};
      for (var doc in prefQuery.docs) {
        final uid = doc.reference.path.split('/')[1]; // assumed path: users/UID/preferences/…
        prefsMap[uid] = doc.data() as Map<String, dynamic>;
      }

      final namesMap = await _loadNamesMap(eventId);

      final rows = <List<String>>[];
      rows.add(['Name', 'Phone', 'Table', 'Chair', 'Prefer To', 'Avoid', 'Options']);

      for (var phone in participants) {
        final name = namesMap[phone] ?? phone;
        final seat = seating[phone];
        final prefs = prefsMap[phone] ?? {};

        final toList = _extractList(prefs['preferToList']);
        final notToList = _extractList(prefs['preferNotToList']);
        final options = prefs['options'] ?? {};
        final optText = (options as Map).entries.map((e) => '${e.key}=${e.value}').join('; ');

        String tableStr = '', chairStr = '';
        if (seat is Map) {
          tableStr = seat['row']?.toString() ?? '';
          chairStr = seat['col']?.toString() ?? '';
        } else {
          tableStr = seat?.toString() ?? '';
        }

        rows.add([
          name,
          "'$phone", // כדי למנוע עיבוד אוטומטי באקסל
          tableStr,
          chairStr,
          toList.join(', '),
          notToList.join(', '),
          optText,
        ]);
      }

      final csv = const ListToCsvConverter().convert(rows);
      final bytes = utf8.encode(csv);

      // 📌 שמירה ב־Firebase
      final ref = storage.ref().child('events/$eventId/seating_export.csv');
      final upload = await ref.putData(Uint8List.fromList(bytes));
      final url = await upload.ref.getDownloadURL();
      await _db.collection('events').doc(eventId).update({'seatingExportUrl': url});

      // 📌 שמירה מקומית במכשיר
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/seating_export.csv';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // 📌 אופציה לשיתוף
      await Share.shareFiles([filePath], mimeTypes: ['text/csv'], subject: 'Seating Arrangement');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ CSV saved locally & uploaded')),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error exporting CSV: $e')),
      );
    }
  }

  List<String> _extractList(dynamic raw) {
    if (raw is Map) return raw.keys.map((k) => k.toString()).toList();
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return [];
  }


}
