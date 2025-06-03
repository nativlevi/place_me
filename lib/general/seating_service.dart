import 'package:cloud_firestore/cloud_firestore.dart';
import '../../logic/seating_optimizer.dart';

class SeatingService {
final FirebaseFirestore _db = FirebaseFirestore.instance;

Future<void> generateSmartSeating(String eventId) async {
  final _db = FirebaseFirestore.instance;

  final eventDoc = await _db.collection('events').doc(eventId).get();
  if (!eventDoc.exists) return;
  final eventData = eventDoc.data()!;

  final List<dynamic> allowed = eventData['allowedParticipants'] ?? [];
  final List<Map<String, dynamic>> seats = List<Map<String, dynamic>>.from(eventData['seats'] ?? []);
  final eventTypeStr = (eventData['eventType'] ?? '').toLowerCase();

  // 1. המרה ל־EventType
  late final EventType eventType;
  if (eventTypeStr.contains('classroom')) {
    eventType = EventType.classroomWorkshop;
  } else if (eventTypeStr.contains('family')) {
    eventType = EventType.familySocial;
  } else {
    eventType = EventType.conferenceProfessional;
  }

  // 2. המרת seats ל־TableInfo
  final tables = seats.map((seat) {
    final List<String> tags = List<String>.from(seat['tags'] ?? []);
    final tagEnums = tags.map((t) => _mapTagToFeature(t)).whereType<SeatFeature>().toSet();
    return TableInfo(capacity: 1, features: tagEnums);
  }).toList();

  // 3. יצירת parties מתוך allowedParticipants
  final parties = <Party>[];
  for (var phone in allowed) {
    final prefsQuery = await _db
        .collection('users')
        .doc(phone)
        .collection('preferences')
        .where('eventId', isEqualTo: eventId)
        .get();

    Map<String, dynamic> pref = {};
    if (prefsQuery.docs.isNotEmpty) {
      pref = prefsQuery.docs.first.data();
    }

    final preferTo = List<String>.from(pref['preferToList'] ?? []);
    final avoidTo = List<String>.from(pref['preferNotToList'] ?? []);
    final Map<String, dynamic> opts = pref['options'] ?? {};
    final wantedTags = <SeatFeature>{};
    final avoidTags = <SeatFeature>{};

    opts.forEach((k, v) {
      if (v == true) {
        final f = _mapOptionToFeature(k);
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
        avoidFeatures: avoidTags,
      ),
    ));
  }

  final optimizer = SeatingOptimizer(
    parties: parties,
    tables: tables,
    params: SeatingParams(),
    eventType: eventType,
  );

  final result = optimizer.optimise();

  final Map<String, dynamic> seating = {};
  result.tableOf.forEach((uid, tableIndex) {
    seating[uid] = tableIndex;
  });

  await _db.collection('events').doc(eventId).update({
    'seating': seating,
    'score': result.score,
    'status': 'closed',
  });
}

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
