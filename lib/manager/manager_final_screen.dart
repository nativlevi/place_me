import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:csv/csv.dart';

class ManagerFinalScreen extends StatelessWidget {
  final String eventId;
  const ManagerFinalScreen({Key? key, required this.eventId}) : super(key: key);

  // פונקציית נרמול טלפון - מסירה רווחים, דואגת לפורמט קבוע עם "+".
  String normalizePhone(String phone) {
    var p = phone.replaceAll(RegExp(r'[\s\-\.]'), '');
    if (p.startsWith('00')) p = '+' + p.substring(2);
    if (p.startsWith('972') && !p.startsWith('+')) p = '+$p';
    if (p.startsWith('0')) p = '+972' + p.substring(1);
    if (!p.startsWith('+')) p = '+$p';
    return p;
  }

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
                prefsMap[normalizePhone(uid)] =
                    doc.data() as Map<String, dynamic>;
              }

              return FutureBuilder<QuerySnapshot>(
                future: _db.collection('users').get(),
                builder: (ctx3, usersSnap) {
                  if (usersSnap.connectionState == ConnectionState.waiting)
                    return Center(child: CircularProgressIndicator());
                  if (usersSnap.hasError)
                    return Center(child: Text('Error loading users'));

                  final Map<String, String> namesMap = {};
                  for (var userDoc in usersSnap.data!.docs) {
                    final data = userDoc.data() as Map<String, dynamic>;
                    final phoneFromId = normalizePhone(userDoc.id);
                    final phoneFromField =
                        normalizePhone(data['phone'] ?? userDoc.id);
                    final name = data['name'] ?? phoneFromId;
                    namesMap[phoneFromId] = name;
                    namesMap[phoneFromField] = name;
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: participants.length,
                    itemBuilder: (ctx4, i) {
                      final rawPhone = participants[i];
                      final normalizedPhone = normalizePhone(rawPhone);
                      final seatInfo = seating[rawPhone];
                      String seatText;
                      if (seatInfo is Map) {
                        seatText =
                            'Row: ${seatInfo['row']}, Col: ${seatInfo['col']}';
                      } else {
                        seatText = 'Chair: $seatInfo';
                      }
                      final prefs = prefsMap[normalizedPhone] ?? {};

                      final rawTo = prefs['preferToList'];
                      final List<String> toList = [];
                      if (rawTo is Map) {
                        toList.addAll(rawTo.keys.map((k) => k.toString()));
                      } else if (rawTo is List) {
                        toList.addAll(rawTo.map((e) => e.toString()));
                      }

                      final rawNot = prefs['preferNotToList'];
                      final List<String> notToList = [];
                      if (rawNot is Map) {
                        notToList.addAll(rawNot.keys.map((k) => k.toString()));
                      } else if (rawNot is List) {
                        notToList.addAll(rawNot.map((e) => e.toString()));
                      }

                      final options =
                          (prefs['options'] as Map<String, dynamic>?) ?? {};

                      final name = namesMap[normalizedPhone] ?? normalizedPhone;

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
                                Text('User: $name',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ]),
                              SizedBox(height: 4),
                              Text(seatText),
                              if (options.isNotEmpty) ...[
                                SizedBox(height: 8),
                                Text('Options:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500)),
                                ...options.entries
                                    .map((e) => Text('• ${e.key}: ${e.value}')),
                              ],
                              if (toList.isNotEmpty) ...[
                                SizedBox(height: 8),
                                Text('Prefer to be with:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500)),
                                ...toList.map((u) => Text('• $u')),
                              ],
                              if (notToList.isNotEmpty) ...[
                                SizedBox(height: 8),
                                Text('Prefer not to be with:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500)),
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
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context, String eventId) async {
    final _db = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;

    String normalizePhone(String phone) {
      var p = phone.replaceAll(RegExp(r'[\s\-\.]'), '');
      if (p.startsWith('00')) p = '+' + p.substring(2);
      if (p.startsWith('972') && !p.startsWith('+')) p = '+$p';
      if (p.startsWith('0')) p = '+972' + p.substring(1);
      if (!p.startsWith('+')) p = '+$p';
      return p;
    }

    try {
      // שליפת נתוני האירוע
      final doc = await _db.collection('events').doc(eventId).get();
      final eventData = doc.data()!;
      final seating = Map<String, dynamic>.from(eventData['seating'] ?? {});
      final participants =
          List<String>.from(eventData['allowedParticipants'] ?? []);

      // שליפת העדפות
      final prefQuery = await _db
          .collectionGroup('preferences')
          .where('eventId', isEqualTo: eventId)
          .get();

      final Map<String, Map<String, dynamic>> prefsMap = {};
      for (var doc in prefQuery.docs) {
        final path = doc.reference.path.split('/');
        final uid = path[path.indexOf('users') + 1];
        prefsMap[normalizePhone(uid)] = doc.data() as Map<String, dynamic>;
      }

      // שליפת שמות המשתתפים
      final usersQuery = await _db.collection('users').get();
      final Map<String, String> namesMap = {};
      for (var userDoc in usersQuery.docs) {
        final data = userDoc.data() as Map<String, dynamic>;
        final phoneFromId = normalizePhone(userDoc.id);
        final phoneFromField = normalizePhone(data['phone'] ?? userDoc.id);
        final name = data['name'] ?? phoneFromId;
        namesMap[phoneFromId] = name;
        namesMap[phoneFromField] = name;
      }

      // בניית שורות CSV
      final rows = <List<String>>[];
      rows.add(
          ['Name', 'Phone', 'Table', 'Chair', 'Prefer To', 'Avoid', 'Options']);

      for (var phone in participants) {
        final normalizedPhone = normalizePhone(phone);
        final name = namesMap[normalizedPhone] ?? normalizedPhone;
        final seat = seating[phone];
        final prefs = prefsMap[normalizedPhone] ?? {};

        // העדפה לשבת עם
        final rawTo = prefs['preferToList'];
        final toList = (rawTo is Map)
            ? rawTo.keys.map((k) => k.toString()).toList()
            : (rawTo is List)
                ? rawTo.map((e) => e.toString()).toList()
                : [];

        // העדפה לא לשבת עם
        final rawNot = prefs['preferNotToList'];
        final notToList = (rawNot is Map)
            ? rawNot.keys.map((k) => k.toString()).toList()
            : (rawNot is List)
                ? rawNot.map((e) => e.toString()).toList()
                : [];

        // מאפיינים
        final options = prefs['options'] ?? {};
        final optText = (options as Map)
            .entries
            .map((e) => '${e.key}=${e.value}')
            .join('; ');

        String tableStr = '';
        String chairStr = '';

        if (seat is Map) {
          tableStr = seat['row']?.toString() ?? '';
          chairStr = seat['col']?.toString() ?? '';
        } else {
          tableStr = seat.toString();
          chairStr = '';
        }

        rows.add([
          name,
          normalizedPhone,
          tableStr,
          chairStr,
          toList.join(', '),
          notToList.join(', '),
          optText,
        ]);
      }

      final csv = const ListToCsvConverter().convert(rows);
      final bytes = utf8.encode(csv);

      final ref = storage.ref().child('events/$eventId/seating_export.csv');
      final upload = await ref.putData(Uint8List.fromList(bytes));
      final url = await upload.ref.getDownloadURL();

      // שמירה במסמך האירוע
      await _db.collection('events').doc(eventId).update({
        'seatingExportUrl': url,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV exported and saved to Firebase Storage!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting CSV: $e')),
      );
    }
  }
}
