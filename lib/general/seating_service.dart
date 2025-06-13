import 'package:cloud_firestore/cloud_firestore.dart';
import '../../logic/seating_optimizer.dart';

class SeatingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> generateSmartSeating(String eventId) async {
    print('🔸 SeatingService: Starting for event $eventId');

    // 1. קבלת נתוני האירוע
    final eventSnap = await _db.collection('events').doc(eventId).get();
    if (!eventSnap.exists) {
      throw Exception('Event $eventId does not exist');
    }
    final eventData = eventSnap.data()!;

    // 2. רשימת המוזמנים
    final List<dynamic> allowed =
        eventData['allowedParticipants'] ?? <dynamic>[];

    // 3. שליפת הכיסאות (elements type="chair")
    final elementQuery = await _db
        .collection('events')
        .doc(eventId)
        .collection('elements')
        .where('type', isEqualTo: 'chair')
        .get();
    final elementDocs = elementQuery.docs;
    if (elementDocs.isEmpty) {
      throw Exception('❌ No seating chairs defined for this event');
    }

    // 4. בניית רשימת ה־TableInfo מתוך הכיסאות
    final tables = elementDocs.map((doc) {
      final data = doc.data();
      final tags = List<String>.from(data['tags'] ?? <String>[]);
      final features = tags
          .map(_mapTagToFeature)
          .whereType<SeatFeature>()
          .toSet();
      return TableInfo(capacity: 1, features: features);
    }).toList();

    // 5. קביעת EventType לפי סוג האירוע
    final eventTypeStr = (eventData['eventType'] ?? '').toLowerCase();
    late final EventType eventType;
    if (eventTypeStr.contains('classroom')) {
      eventType = EventType.classroomWorkshop;
    } else if (eventTypeStr.contains('family')) {
      eventType = EventType.familySocial;
    } else {
      eventType = EventType.conferenceProfessional;
    }

    // 6. יצירת parties עם העדפות מה־Firestore
    final parties = <Party>[];
    for (final rawPhone in allowed) {
      final phone = rawPhone.toString();
      final prefsSnap = await _db
          .collection('users')
          .doc(phone)
          .collection('preferences')
          .doc(eventId)
          .get();

      // ברירת מחדל
      var preferTo = <String>[];
      var avoidTo = <String>[];
      var opts = <String, dynamic>{};

      if (prefsSnap.exists) {
        final p = prefsSnap.data()!;
        preferTo = List<String>.from(p['preferToList'] ?? <String>[]);
        avoidTo = List<String>.from(p['preferNotToList'] ?? <String>[]);
        opts = Map<String, dynamic>.from(p['options'] ?? <String, bool>{});
      }

      final wantedTags = <SeatFeature>{};
      //noinspection DartDynamicAccess
      opts.forEach((key, val) {
        if (val == true) {
          final f = _mapOptionToFeature(key);
          if (f != null) wantedTags.add(f);
        }
      });

      parties.add(Party(
        phone,
        1,
        PartyPref(
          preferToSitWith: preferTo.toSet(),
          avoidToSitWith: avoidTo.toSet(),
          desiredFeatures: wantedTags,
          avoidFeatures: <SeatFeature>{},
        ),
      ));
    }

    // 7. קריאה לאופטימייזר
    final optimizer = SeatingOptimizer(
      parties: parties,
      tables: tables,
      params: SeatingParams(),
      eventType: eventType,
    );
    final result = optimizer.optimise();

    // 8. שמירה ראשונית של המפה וה־score
    final seatingMap = <String, int>{};
    result.tableOf.forEach((uid, tableIndex) {
      seatingMap[uid] = tableIndex;
    });
    await _db.collection('events').doc(eventId).update({
      'seating': seatingMap,
      'score': result.score,
      'status': 'closed',
    });

    // 9. עדכון השדה occupiedBy בכל element
    final WriteBatch batch = _db.batch();
    for (int i = 0; i < elementDocs.length; i++) {
      final docRef = elementDocs[i].reference;
      // מי הוקצה לכיסא i?
      final entry = seatingMap.entries.firstWhere(
            (e) => e.value == i,
        orElse: () => const MapEntry('', -1),
      );
      final occupant = entry.key; // "" אם אין

      if (occupant.isNotEmpty) {
        batch.update(docRef, {'occupiedBy': occupant});
      } else {
        batch.update(docRef, {'occupiedBy': FieldValue.delete()});
      }
    }
    await batch.commit();

    print('🔸 SeatingService: Done for event $eventId');
  }

  // מפות עזר למיפוי תגים ו־options ל־SeatFeature
  SeatFeature? _mapTagToFeature(String tag) {
    switch (tag) {
      case 'near_stage':
        return SeatFeature.stage;
      case 'near_ac':
        return SeatFeature.airConditioner;
      case 'near_window':
        return SeatFeature.window;
      case 'near_exit':
        return SeatFeature.exit;
      default:
        return null;
    }
  }

  SeatFeature? _mapOptionToFeature(String key) {
    switch (key) {
      case 'Stage':
        return SeatFeature.stage;
      case 'Screen':
        return SeatFeature.screen;
      case 'Charging Point':
        return SeatFeature.charging;
      case 'Writing Table':
        return SeatFeature.desk;
      case 'Window':
        return SeatFeature.window;
      case 'Entrance':
        return SeatFeature.entrance;
      case 'AC':
        return SeatFeature.airConditioner;
      default:
        return null;
    }
  }
}
