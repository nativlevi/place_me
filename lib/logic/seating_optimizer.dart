// seating_optimizer.dart – extended version with per‑event seating preferences
// ------------------------------------------------------------------------
// Implements Simulated Annealing seating optimisation that now includes:
//   1. Social preferences (friends / avoid list) – as before.
//   2. *Positional* preferences that vary by **event type**:
//        • Classroom/Workshop   → Board, AC, Window, Entrance
//        • Family/Social Event  → DanceFloor, Speakers, Exit
//        • Conference/Professional → Stage, Desk, Screen, Charging
//   3. Each table (or section) is tagged עם מאפייני מיקום (SeatFeature).
//      אם מאפיין רצוי קיים – בונוס. אם מאפיין לא‑רצוי קיים – קנס.
//
//  Data ﻿structures added:
//     enum EventType & SeatFeature
//     class TableInfo (features + capacity)
//     class PartyPref   – social lists + desired/avoid features
// ------------------------------------------------------------------------

import 'dart:math';

// --------------------------- ENUMS --------------------------------------

enum EventType { classroomWorkshop, familySocial, conferenceProfessional }

enum SeatFeature {
  board,
  airConditioner,
  window,
  entrance,
  danceFloor,
  speakers,
  exit,
  stage,
  desk,
  screen,
  charging,
}

// ---------------------------- DATA MODELS -------------------------------

class Party {
  final String id;
  final int size;
  final PartyPref pref;

  const Party(this.id, this.size, this.pref);
}

class PartyPref {
  final Set<String> preferToSitWith;      // ids
  final Set<String> avoidToSitWith;       // ids
  final Set<SeatFeature> desiredFeatures; // want to be near
  final Set<SeatFeature> avoidFeatures;   // prefer far
  final bool showInLists;                 // visibility flag (not used here)

  const PartyPref({
    this.preferToSitWith = const {},
    this.avoidToSitWith = const {},
    this.desiredFeatures = const {},
    this.avoidFeatures = const {},
    this.showInLists = true,
  });
}

class TableInfo {
  final int capacity;
  final Set<SeatFeature> features; // what exists near this table

  const TableInfo({required this.capacity, this.features = const {}});
}

class SeatingParams {
  final int wFriend;
  final int wAvoid;
  final int wFeatureBonus;
  final int wFeaturePenalty;
  final int minFill; // minimum seats per table (optional)

  const SeatingParams({
    this.wFriend = 1,
    this.wAvoid = 5,
    this.wFeatureBonus = 2,
    this.wFeaturePenalty = 2,
    this.minFill = 0,
  });
}

class SeatingSolution {
  final Map<String, int> tableOf; // partyId → table index
  final int score;
  SeatingSolution(this.tableOf, this.score);
}

// ----------------------- OPTIMISER --------------------------------------

class SeatingOptimizer {
  final List<Party> parties;
  final List<TableInfo> tables;
  final SeatingParams params;
  final EventType eventType;

  final _rng = Random();
  late final Map<String, Party> _byId;

  SeatingOptimizer({
    required this.parties,
    required this.tables,
    required this.params,
    required this.eventType,
  }) {
    _byId = {for (var p in parties) p.id: p};
  }

  SeatingSolution optimise({int iterations = 20000, double startT = 1.0, double cool = 0.9995}) {
    var assign = _randomAssignment();
    var bestAssign = Map<String, int>.from(assign);
    var bestScore = _score(assign);
    var currentScore = bestScore;
    var T = startT;

    for (var i = 0; i < iterations; i++) {
      final neighbour = _randomNeighbour(assign);
      if (neighbour == null) continue;
      final neighScore = _score(neighbour);
      final delta = neighScore - currentScore;
      if (delta > 0 || _rng.nextDouble() < exp(delta / max(T, 1e-9))) {
        assign = neighbour;
        currentScore = neighScore;
        if (neighScore > bestScore) {
          bestAssign = Map<String, int>.from(neighbour);
          bestScore = neighScore;
        }
      }
      T *= cool;
    }
    return SeatingSolution(bestAssign, bestScore);
  }

  // -------------------- ASSIGN & NEIGHBOUR -------------------------

  Map<String, int> _randomAssignment() {
    final assign = <String, int>{};
    final usedSeats = List<int>.filled(tables.length, 0);
    final shuffled = [...parties]..shuffle(_rng);
    for (var p in shuffled) {
      final opts = [for (var t = 0; t < tables.length; t++) if (usedSeats[t] + p.size <= tables[t].capacity) t];
      final t = opts[_rng.nextInt(opts.length)];
      assign[p.id] = t;
      usedSeats[t] += p.size;
    }
    return assign;
  }

  Map<String, int>? _randomNeighbour(Map<String, int> current) {
    final neighbour = Map<String, int>.from(current);
    if (_rng.nextBool()) {
      // swap two parties
      final ids = parties.map((p) => p.id).toList()..shuffle(_rng);
      neighbour[ids[0]] = current[ids[1]]!;
      neighbour[ids[1]] = current[ids[0]]!;
    } else {
      // move one party
      final p = parties[_rng.nextInt(parties.length)];
      var newT = _rng.nextInt(tables.length);
      neighbour[p.id] = newT;
    }
    return _feasible(neighbour) ? neighbour : null;
  }

  bool _feasible(Map<String, int> assign) {
    final seats = List<int>.filled(tables.length, 0);
    assign.forEach((pid, t) => seats[t] += _byId[pid]!.size);
    for (var i = 0; i < tables.length; i++) {
      if (seats[i] > tables[i].capacity) return false;
      if (params.minFill > 0 && seats[i] > 0 && seats[i] < params.minFill) return false;
    }
    return true;
  }

  // ----------------------- SCORING ---------------------------------

  int _score(Map<String, int> assign) {
    var score = 0;
    // build per-table lists
    final perTable = List.generate(tables.length, (_) => <String>[]);
    assign.forEach((pid, t) => perTable[t].add(pid));

    // social score
    for (var tableIdx = 0; tableIdx < perTable.length; tableIdx++) {
      final list = perTable[tableIdx];
      for (var i = 0; i < list.length; i++) {
        final pi = _byId[list[i]]!;
        for (var j = i + 1; j < list.length; j++) {
          final pjId = list[j];
          if (pi.pref.preferToSitWith.contains(pjId) || _byId[pjId]!.pref.preferToSitWith.contains(pi.id)) {
            score += params.wFriend;
          }
          if (pi.pref.avoidToSitWith.contains(pjId) || _byId[pjId]!.pref.avoidToSitWith.contains(pi.id)) {
            score -= params.wAvoid;
          }
        }
      }
      // feature score per party
      final features = tables[tableIdx].features;
      for (var pid in list) {
        final pref = _byId[pid]!.pref;
        for (var f in pref.desiredFeatures) {
          if (features.contains(f)) score += params.wFeatureBonus;
        }
        for (var f in pref.avoidFeatures) {
          if (features.contains(f)) score -= params.wFeaturePenalty;
        }
      }
    }
    return score;
  }
}

// ---------------------- EXAMPLE USAGE ----------------------------------

void main() {
  // Define tables with features (dummy example)
  final tables = [
    TableInfo(capacity: 10, features: {SeatFeature.board}),
    TableInfo(capacity: 10, features: {SeatFeature.airConditioner}),
    TableInfo(capacity: 8, features: {SeatFeature.window}),
    TableInfo(capacity: 8, features: {SeatFeature.entrance}),
  ];

  // Parties with preferences
  final parties = [
    Party('alice', 2, PartyPref(
      preferToSitWith: {'bob'},
      desiredFeatures: {SeatFeature.board},
    )),
    Party('bob', 1, PartyPref(
      preferToSitWith: {'alice'},
      avoidFeatures: {SeatFeature.airConditioner},
    )),
    Party('charlie', 3, PartyPref(
      avoidToSitWith: {'dave'},
      desiredFeatures: {SeatFeature.window},
    )),
    Party('dave', 2, PartyPref()),
  ];

  final params = SeatingParams(wFriend: 1, wAvoid: 5, wFeatureBonus: 2, wFeaturePenalty: 2, minFill: 4);

  final optimiser = SeatingOptimizer(
    parties: parties,
    tables: tables,
    params: params,
    eventType: EventType.classroomWorkshop,
  );

  final sol = optimiser.optimise();
  print('Best score: ${sol.score}');
  print(sol.tableOf);
}
