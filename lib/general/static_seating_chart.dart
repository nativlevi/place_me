// lib/general/static_seating_chart.dart

import 'package:flutter/material.dart';

class StaticSeatingChart extends StatelessWidget {
  final Map<String, Map<String, int>> seating; // uid -> {row: int, col: int}
  final List<String> participants; // רשימת כל המשתתפים המורשים
  final int columns; // מספר עמודות בגריד
  final Map<String, String> namesMap; // phone -> name
  final String currentParticipantId; // ה-uid של המשתתף הנוכחי
  final Map<String, dynamic>? eventLayout; // פריסת החדר מהמנהל (אם קיימת)

  const StaticSeatingChart({
    Key? key,
    required this.seating,
    required this.participants,
    required this.columns,
    required this.namesMap,
    required this.currentParticipantId,
    this.eventLayout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // חישוב מספר השורות הנדרש
    final maxRow = seating.values.isNotEmpty
        ? seating.values
            .map((pos) => pos['row']!)
            .reduce((a, b) => a > b ? a : b)
        : 0;
    final rows = maxRow + 1;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // כותרת
          Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Event Seating Layout',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3D3D3D),
              ),
            ),
          ),

          // מקרא
          Container(
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem(Colors.red, 'Your Seat'),
                _buildLegendItem(Colors.blue, 'Occupied'),
                _buildLegendItem(Colors.grey[300]!, 'Empty'),
              ],
            ),
          ),

          // הגריד של הכסאות
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                child: _buildSeatingGrid(rows),
              ),
            ),
          ),

          // מידע על הכסא של המשתתף
          Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: _buildParticipantInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[400]!),
          ),
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSeatingGrid(int rows) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: rows * columns,
      itemBuilder: (context, index) {
        final row = index ~/ columns;
        final col = index % columns;

        return _buildSeatWidget(row, col);
      },
    );
  }

  Widget _buildSeatWidget(int row, int col) {
    // מצא את המשתתף שיושב במקום הזה
    String? occupantId;
    for (var entry in seating.entries) {
      final pos = entry.value;
      if (pos['row'] == row && pos['col'] == col) {
        occupantId = entry.key;
        break;
      }
    }

    // קבע את הצבע והתוכן
    Color seatColor;
    Color textColor = Colors.white;
    String seatText = '${row + 1}-${col + 1}';
    bool isCurrentUser = occupantId == currentParticipantId;

    if (occupantId != null) {
      if (isCurrentUser) {
        seatColor = Colors.red;
        seatText = 'YOU';
      } else {
        seatColor = Colors.blue;
        // הצג שם אם זמין
        final name = namesMap[occupantId];
        if (name != null && name.isNotEmpty) {
          seatText = name.length > 8 ? '${name.substring(0, 8)}...' : name;
        } else {
          seatText = 'Occupied';
        }
      }
    } else {
      seatColor = Colors.grey[300]!;
      textColor = Colors.grey[600]!;
    }

    return Container(
      decoration: BoxDecoration(
        color: seatColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrentUser ? Colors.red[800]! : Colors.grey[400]!,
          width: isCurrentUser ? 3 : 1,
        ),
        boxShadow: isCurrentUser
            ? [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chair,
              color: textColor,
              size: isCurrentUser ? 24 : 20,
            ),
            SizedBox(height: 2),
            Text(
              seatText,
              style: TextStyle(
                color: textColor,
                fontSize: isCurrentUser ? 12 : 10,
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantInfo() {
    final myPos = seating[currentParticipantId];
    if (myPos == null) {
      return Text(
        'Your seat assignment is not available yet.',
        style: TextStyle(
          fontSize: 16,
          color: Colors.red[700],
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final myName = namesMap[currentParticipantId] ?? 'You';
    final row = myPos['row']! + 1;
    final col = myPos['col']! + 1;

    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.person,
              color: Colors.red[700],
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Your Assignment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.chair,
              color: Colors.red[600],
              size: 20,
            ),
            SizedBox(width: 12),
            Text(
              'Seat: Row $row, Column $col',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (myName != 'You') ...[
          SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.badge,
                color: Colors.red[600],
                size: 20,
              ),
              SizedBox(width: 12),
              Text(
                'Name: $myName',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
