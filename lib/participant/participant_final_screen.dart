// lib/screens/participant_final_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/general/seating_chart.dart';  // הנחה: יצרנו את הרכיב ב־widgets/seating_chart.dart

class ParticipantFinalScreen extends StatelessWidget {
  final String eventId;
  final String participantId;

  const ParticipantFinalScreen({Key? key, required this.eventId, required this.participantId}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    final _db = FirebaseFirestore.instance;
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text('Your Seat')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('events').doc(eventId).snapshots(),
        builder: (ctx, eventSnap) {
          if (eventSnap.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (!eventSnap.hasData || !eventSnap.data!.exists)
            return Center(child: Text('Event not found'));

          final data = eventSnap.data?.data();
          if (data == null || data is! Map) return Center(child: Text('Event data missing'));
          final eventData = data as Map<String, dynamic>;
          // 1. שליפת גריד הישיבה (row,col) ו allowedParticipants
          final seatingRaw = Map<String, dynamic>.from(eventData['seating'] ?? {});

          // ממיר למבנה המתאים
          final Map<String, Map<String,int>> seating = {};
          seatingRaw.forEach((uid, rc) {
            if (rc is int) {
              // המקרה הישן: ערך בודד – נשים אותו כ־col, row = 0
              seating[uid] = {'row': 0, 'col': rc};
            } else if (rc is Map) {
              // המקרה החדש: מפה מוכנה
              final m = Map<String, int>.from(rc);
              seating[uid] = {'row': m['row']!, 'col': m['col']!};
            }
          });
          final participants =
          List<String>.from(eventData['allowedParticipants'] ?? []);

// 2. שליפת העדפות + שמות המשתתפים
          return FutureBuilder(
            future: Future.wait([
              _db
                  .collection('users')
                  .doc(participantId)
                  .collection('preferences')
                  .where('eventId', isEqualTo: eventId)
                  .get(),
              _db.collection('users').get(), // שליפת שמות
            ]),
            builder: (ctx2, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return Center(child: CircularProgressIndicator());
              if (snapshot.hasError)
                return Center(child: Text('Error loading data'));

              final prefSnap = snapshot.data![0] as QuerySnapshot;
              final usersSnap = snapshot.data![1] as QuerySnapshot;

              // העדפות המשתמש הנוכחי
              Map<String, dynamic> myPrefs = {};
              if (prefSnap.docs.isNotEmpty) {
                myPrefs = prefSnap.docs.first.data() as Map<String, dynamic>;
              }

              // מיפוי uid → name
              final Map<String, String> namesMap = {};
              for (var doc in usersSnap.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final phone = data['phone']?.toString();
                if (phone == null) continue;
                final name = data['name']?.toString() ?? phone; // ← כאן תעדיף שם על פני טלפון
                namesMap[phone] = name;
              }


              // מיקום אישי
              final myPos = seating[participantId];
              if (participantId.isEmpty || !seating.containsKey(participantId)) {
                return Center(child: Text('Your seat not assigned yet'));
              }
              print('🧾 namesMap = $namesMap');

              return SeatingChart(
                seating: seating,
                participants: participants,
                columns: 4,
                prefsMap: {participantId: myPrefs},
                namesMap: namesMap,
              );
            },
          );
        },
      ),
    );
  }
}
