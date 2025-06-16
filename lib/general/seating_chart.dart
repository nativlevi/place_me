import 'package:flutter/material.dart';

class SeatingChart extends StatelessWidget {
  /// מפה של uid -> מפת {row, col}
  final Map<String, Map<String, int>> seating;

  /// רשימת המשתתפים (לשמור סוף–סוף סדר עקבי)
  final List<String> participants;

  /// כמה עמודות במצע
  final int columns;

  /// (אופציונלי) העדפות לכל uid
  final Map<String, Map<String, dynamic>> prefsMap;

  /// מפה של uid -> שם מלא
  final Map<String, String> namesMap;

  const SeatingChart({
    Key? key,
    required this.seating,
    required this.participants,
    required this.namesMap,
    this.columns = 4,
    this.prefsMap = const {},
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // מחשבים כמה שורות צריך
    final rows = (participants.length + columns - 1) ~/ columns;

    // בונים list בגודל rows*columns עם uid או ריק
    final grid = List.generate(rows * columns, (index) {
      final r = index ~/ columns;
      final c = index % columns;
      // מחפשים uid ששורה־עמודה שלו תואמת
      final uid = seating.entries
          .firstWhere(
            (e) => e.value['row'] == r && e.value['col'] == c,
            orElse: () => MapEntry('', {}),
          )
          .key;
      return uid; // "" אם אין שם מישהו
    });

    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: 1.0,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: grid.length,
      itemBuilder: (ctx, idx) {
        final uid = grid[idx];
        if (uid.isEmpty) {
          // מושב ריק
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(child: Text('Empty')),
          );
        }

        final prefs = prefsMap[uid] ?? {};
        final satisfied = prefs['options']?.containsValue(true) ?? false;
        final displayName = namesMap[uid] ?? uid;

        return Container(
          decoration: BoxDecoration(
            color: satisfied ? Colors.green[100] : Colors.blue[100],
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_seat, size: 24),
              SizedBox(height: 4),
              Tooltip(
                message: uid,
                child: Text(
                  displayName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(fontSize: 12),
                ),
              ),
              SizedBox(height: 4),
              if (satisfied)
                Icon(Icons.check_circle, color: Colors.green, size: 18)
              else
                Icon(Icons.info_outline, color: Colors.grey, size: 18),
            ],
          ),
        );
      },
    );
  }
}
