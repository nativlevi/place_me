import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InteractiveRoomEditor extends StatefulWidget {
  final String eventId;
  final bool readOnly;
  final String? highlightPhone;

  const InteractiveRoomEditor({
    required this.eventId,
    this.readOnly = false,
    this.highlightPhone,
    Key? key,
  }) : super(key: key);

  @override
  _InteractiveRoomEditorState createState() => _InteractiveRoomEditorState();
}

class _InteractiveRoomEditorState extends State<InteractiveRoomEditor> {
  List<Map<String, dynamic>> elements = [];
  Offset? _dragStart;
  final GlobalKey _stackKey = GlobalKey();
  Rect? _selectionRect;
  Set<String> _selectedIds = {};
  String? _eventType;
  Map<String, List<String>> _featuresByType = {
    'Classroom/Workshop': ['Board', 'Air Conditioner', 'Window', 'Entrance'],
    'Family/Social Event': ['Dance Floor', 'Speakers', 'Exit'],
    'Conference/Professional Event': [
      'Stage',
      'Writing Table',
      'Screen',
      'Charging Point'
    ],
  };

  Map<String, dynamic> seating = {};
  int? highlightChairIndex;

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .get()
        .then((doc) {
      final type = doc.data()?['eventType'] as String?;
      setState(() => _eventType = type);

      // טעינת seating להדגשת כיסא
      final seatMap = doc.data()?['seating'] as Map<String, dynamic>?;
      if (seatMap != null && widget.highlightPhone != null) {
        final value = seatMap[widget.highlightPhone];
        if (value != null) {
          setState(() => highlightChairIndex =
          value is int ? value : int.tryParse(value.toString()));
        }
      }
    });

    _loadElements();
  }

  Future<void> _ensureEventTypeFeatures(String type) async {
    final featuresToAdd = _featuresByType[type] ?? [];
    final colRef = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .collection('elements');

    final existingSnapshot = await colRef.get();
    final existingFeatures = existingSnapshot.docs
        .where((doc) => doc['type'] == 'feature')
        .map((doc) => doc['label'] as String)
        .toSet();

    final box = context.findRenderObject() as RenderBox?;
    final size = box?.size ?? Size(400, 400);

    int i = 0;
    for (var feature in featuresToAdd) {
      if (existingFeatures.contains(feature)) continue;

      final doc = colRef.doc();
      final element = {
        'id': doc.id,
        'type': 'feature',
        'label': feature,
        'x': 60.0 + (i * 70) % size.width,
        'y': 60.0 + (i * 70 ~/ size.width) * 70,
        'w': 60.0,
        'h': 60.0,
        'rotation': 0.0,
      };
      await doc.set(element);
      elements.add(element);
      i++;
    }

    setState(() {});
  }

  Future<void> _duplicateSelection() async {
    const double offsetX = 60.0;
    const double offsetY = 60.0;

    final batch = FirebaseFirestore.instance.batch();
    final colRef = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .collection('elements');

    final toDuplicate =
    elements.where((e) => _selectedIds.contains(e['id'])).toList();
    final List<Map<String, dynamic>> newOnes = [];

    for (var e in toDuplicate) {
      final oldX = (e['x'] as num?)?.toDouble() ?? 0.0;
      final oldY = (e['y'] as num?)?.toDouble() ?? 0.0;
      final type = e['type'] as String;
      final newId = colRef.doc().id;
      final newX = oldX + offsetX;
      final newY = oldY + offsetY;

      final newElem = {
        'id': newId,
        'type': type,
        'x': newX,
        'y': newY,
      };
      batch.set(colRef.doc(newId), newElem);
      newOnes.add(newElem);
    }

    await batch.commit();

    setState(() {
      elements.addAll(newOnes);
      _selectedIds = newOnes.map((e) => e['id'] as String).toSet();
    });
  }

  Future<void> _loadElements() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .collection('elements')
        .get();

    setState(() {
      elements = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Widget _buildOptionsSheet() {
    final allFeatures =
    _featuresByType.values.expand((l) => l).toSet().toList();

    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildCardOption(
                        Icons.format_align_center,
                        'יישר כיסאות',
                        _alignSelectionToTable,
                      ),
                      _buildCardOption(
                        Icons.space_bar,
                        'יישר + מרווח',
                        _alignSelectionWithSpacing,
                      ),
                      _buildCardOption(
                        Icons.group_work,
                        'קבץ',
                        _groupSelection,
                      ),
                      _buildCardOption(
                        Icons.rotate_right,
                        'סובב',
                        _rotateSelection,
                      ),
                      const Divider(height: 32),
                      _buildCardOption(
                        Icons.event_seat,
                        'כיסא',
                            () => _addElement('chair'),
                      ),
                      _buildCardOption(
                        Icons.table_restaurant,
                        'שולחן',
                            () => _addElement('table'),
                      ),
                      const Divider(height: 32),
                      _buildCardOption(
                        Icons.copy,
                        'שכפל בחירה',
                        _duplicateSelection,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardOption(IconData icon, String title, VoidCallback onTap) {
    if (widget.readOnly) return SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        leading: Icon(icon, color: Color(0xFF3D3D3D)),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Source Sans Pro',
            fontSize: 16,
            color: Color(0xFF3D3D3D),
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }

  Future<void> _addFeatureElement(String featureType) async {
    final box = context.findRenderObject() as RenderBox;
    final size = box.size;
    final defaultPos = Offset(size.width / 2, size.height / 2);

    final docRef = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .collection('elements')
        .doc();

    final newElement = {
      'id': docRef.id,
      'type': 'feature',
      'label': featureType,
      'x': defaultPos.dx,
      'y': defaultPos.dy,
      'w': 60.0,
      'h': 60.0,
      'rotation': 0.0,
    };

    await docRef.set(newElement);
    setState(() => elements.add(newElement));
  }

  Future<void> _editTableShape(Map<String, dynamic> table) async {
    const options = ['rectangle', 'square', 'circle'];
    String selectedShape = table['shape'] ?? 'rectangle';

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('בחר צורת שולחן'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((shape) {
            return RadioListTile<String>(
              title: Text(_shapeLabel(shape)),
              value: shape,
              groupValue: selectedShape,
              onChanged: (value) {
                if (value != null) {
                  Navigator.pop(context, value);
                }
              },
            );
          }).toList(),
        ),
      ),
    );

    if (result != null && result != table['shape']) {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('elements')
          .doc(table['id'])
          .update({'shape': result});
      setState(() => table['shape'] = result);
    }
  }

  String _shapeLabel(String shape) {
    switch (shape) {
      case 'square':
        return 'ריבוע';
      case 'rectangle':
        return 'מלבן';
      case 'circle':
        return 'עיגול';
      default:
        return shape;
    }
  }

  Future<void> _addElement(String type) async {
    final box = context.findRenderObject() as RenderBox;
    final size = box.size;
    final defaultPos = Offset(size.width / 2, size.height / 2);

    final docRef = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .collection('elements')
        .doc();

    final newElement = {
      'id': docRef.id,
      'type': type,
      'x': defaultPos.dx,
      'y': defaultPos.dy,
      'w': type == 'table' ? 120.0 : 40.0,
      'h': type == 'table' ? 80.0 : 40.0,
      'features': <String>[],
      if (type == 'table') 'shape': 'rectangle',
      'rotation': 0.0,
    };

    await docRef.set(newElement);
    setState(() => elements.add(newElement));
  }

  Widget _buildDraggableElement(Map<String, dynamic> e) {
    final double rotation = (e['rotation'] ?? 0.0) as double;
    final dx = (e['x'] as num?)?.toDouble() ?? 0.0;
    final dy = (e['y'] as num?)?.toDouble() ?? 0.0;
    final pos = Offset(dx, dy);
    final List features = (e['features'] as List?) ?? [];
    final bool hasFeat = features.isNotEmpty;
    final bool selected = _selectedIds.contains(e['id']);
    final isChair = e['type'] == 'chair';
    final int? chairIndex =
    e['index'] is int ? e['index'] : int.tryParse('${e['index'] ?? ''}');
    final bool isHighlighted = isChair &&
        highlightChairIndex != null &&
        chairIndex == highlightChairIndex;

    return Positioned(
      left: dx,
      top: dy,
      child: GestureDetector(
        onTap: widget.readOnly
            ? null
            : (e['type'] == 'chair'
            ? () => _editChairFeatures(e)
            : e['type'] == 'table'
            ? () => _editTableShape(e)
            : null),
        onLongPress: widget.readOnly ? null : () => _removeElement(e['id']),
        child: widget.readOnly
            ? _elementIcon(e, selected, isHighlighted)
            : Draggable<Map<String, dynamic>>(
          data: e,
          childWhenDragging: Container(),
          onDragEnd: (details) async {
            if (widget.readOnly) return;
            if (_selectedIds.isEmpty || !_selectedIds.contains(e['id'])) {
              final box = _stackKey.currentContext?.findRenderObject()
              as RenderBox?;
              if (box == null) return;
              final local = box.globalToLocal(details.offset);
              await _moveSingle(e, local);
              return;
            }
            final box = context.findRenderObject() as RenderBox;
            final local = box.globalToLocal(details.offset);
            final w = (e['w'] ?? 40.0) as double;
            final h = (e['h'] ?? 40.0) as double;
            final alignedOffset = local - Offset(w / 2, h / 2);
            final delta = local - pos;
            final batch = FirebaseFirestore.instance.batch();
            final col = FirebaseFirestore.instance
                .collection('events')
                .doc(widget.eventId)
                .collection('elements');
            setState(() {
              for (var elm in elements) {
                if (_selectedIds.contains(elm['id'])) {
                  final oldX = (elm['x'] as num?)?.toDouble() ?? 0.0;
                  final oldY = (elm['y'] as num?)?.toDouble() ?? 0.0;
                  final newX = oldX + delta.dx;
                  final newY = oldY + delta.dy;
                  elm['x'] = newX;
                  elm['y'] = newY;
                  batch
                      .update(col.doc(elm['id']), {'x': newX, 'y': newY});
                }
              }
            });
            await batch.commit();
          },
          child: _elementIcon(e, selected, isHighlighted),
          feedback: _elementIcon(e, selected, isHighlighted),
        ),
      ),
    );
  }

  Future<void> _editChairFeatures(Map<String, dynamic> chair) async {
    if (_eventType == null) return;
    final opts = _featuresByType[_eventType!] ?? [];
    final selected =
    Set<String>.from((chair['features'] ?? []) as List<dynamic>);
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('בחר מאפיינים לכיסא'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => SizedBox(
            width: 300,
            child: ListView(
              shrinkWrap: true,
              children: opts.map((feat) {
                return CheckboxListTile(
                  title: Row(
                    children: [
                      Icon(_featureIconFor(feat), color: Colors.black54),
                      SizedBox(width: 8),
                      Text(feat),
                    ],
                  ),
                  value: selected.contains(feat),
                  onChanged: (v) {
                    setStateDialog(() {
                      if (v == true)
                        selected.add(feat);
                      else
                        selected.remove(feat);
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text('ביטול')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, selected),
              child: Text('שמור')),
        ],
      ),
    );

    if (result != null) {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('elements')
          .doc(chair['id'])
          .update({'features': result.toList()});
      setState(() => chair['features'] = result.toList());
    }
  }

  Future<void> _moveSingle(Map<String, dynamic> e, Offset target) async {
    const grid = 20.0;
    final newX = (target.dx / grid).round() * grid;
    final newY = (target.dy / grid).round() * grid;
    await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .collection('elements')
        .doc(e['id'])
        .update({'x': newX, 'y': newY});
    setState(() {
      e['x'] = newX;
      e['y'] = newY;
    });
  }

  void _removeElement(String id) async {
    await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .collection('elements')
        .doc(id)
        .delete();

    setState(() {
      elements.removeWhere((e) => e['id'] == id);
    });
  }

  BoxDecoration _backgroundForEventType() {
    return BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/background.webp'),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(
          Colors.white.withOpacity(0.6),
          BlendMode.dstATop,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFD0DDD0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Seating Arrangement',
          style: TextStyle(
            fontFamily: 'Satreva',
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Color(0xFF727D73),
          ),
        ),
        actions: [
          if (!widget.readOnly)
            IconButton(
              icon: const Icon(Icons.save, color: Color(0xFF3D3D3D)),
              tooltip: 'Save',
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/manager_home');
              },
            ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: widget.readOnly
            ? null
            : (d) {
          setState(() {
            _dragStart = d.localPosition;
            _selectionRect = Rect.fromLTWH(
                d.localPosition.dx, d.localPosition.dy, 0, 0);
          });
        },
        onPanUpdate: widget.readOnly
            ? null
            : (d) {
          setState(() {
            final cur = d.localPosition;
            _selectionRect = Rect.fromPoints(_dragStart!, cur);
          });
        },
        onPanEnd: widget.readOnly
            ? null
            : (_) {
          final sel = <String>{};
          final rect = _selectionRect;
          if (rect != null) {
            for (var e in elements) {
              final x = e['x'] as double;
              final y = e['y'] as double;
              if (rect.contains(Offset(x, y))) sel.add(e['id']);
            }
          }
          setState(() {
            _selectedIds = sel;
            _selectionRect = null;
          });
        },
        child: Container(
          decoration: _backgroundForEventType(),
          child: Stack(
            key: _stackKey,
            children: [
              for (var e in elements) _buildDraggableElement(e),
              if (_selectionRect != null)
                Positioned.fromRect(
                  rect: _selectionRect!,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      border: Border.all(color: Colors.blue),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: widget.readOnly
          ? null
          : FloatingActionButton(
        child: Icon(Icons.more_vert),
        onPressed: () => showModalBottomSheet(
          context: context,
          builder: (_) => _buildOptionsSheet(),
        ),
      ),
    );
  }

  Future<void> _alignSelectionWithSpacing() async {
    const double spacing = 50.0;
    final chairs = elements
        .where((e) => _selectedIds.contains(e['id']) && e['type'] == 'chair')
        .toList();
    if (chairs.isEmpty) return;

    chairs.sort((a, b) => ((a['x'] as num).compareTo(b['x'] as num)));

    final startX = (chairs.first['x'] as num).toDouble();
    final rowY = (chairs.first['y'] as num).toDouble();

    final batch = FirebaseFirestore.instance.batch();
    final colRef = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .collection('elements');

    for (var i = 0; i < chairs.length; i++) {
      final newX = startX + i * spacing;
      final id = chairs[i]['id'] as String;
      chairs[i]['x'] = newX;
      chairs[i]['y'] = rowY;
      batch.update(colRef.doc(id), {'x': newX, 'y': rowY});
    }

    await batch.commit();
    setState(() {});
  }

  Future<void> _groupSelection() async {
    if (_selectedIds.length < 2) return;
    final docRef = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .collection('elements')
        .doc();

    final groupElement = {
      'type': 'group',
      'children': _selectedIds.toList(),
      'id': docRef.id,
      'x': 0.0,
      'y': 0.0,
    };

    final batch = FirebaseFirestore.instance.batch();
    final col = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .collection('elements');

    for (var id in _selectedIds) {
      batch.delete(col.doc(id));
      elements.removeWhere((e) => e['id'] == id);
    }
    batch.set(col.doc(docRef.id), groupElement);
    await batch.commit();

    setState(() {
      elements.add(groupElement);
      _selectedIds = {docRef.id};
    });
  }

  Future<void> _rotateSelection() async {
    if (_selectedIds.isEmpty) return;
    double cx = 0, cy = 0;
    int count = 0;
    for (var e in elements) {
      if (_selectedIds.contains(e['id'])) {
        cx += (e['x'] as num?)?.toDouble() ?? 0;
        cy += (e['y'] as num?)?.toDouble() ?? 0;
        count++;
      }
    }
    if (count == 0) return;
    cx /= count;
    cy /= count;

    final batch = FirebaseFirestore.instance.batch();
    final col = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .collection('elements');

    setState(() {
      for (var e in elements) {
        if (_selectedIds.contains(e['id'])) {
          final x = (e['x'] as num?)?.toDouble() ?? 0.0;
          final y = (e['y'] as num?)?.toDouble() ?? 0.0;
          final dx = x - cx, dy = y - cy;
          final newX = (-dy) + cx;
          final newY = dx + cy;

          final rotation = ((e['rotation'] as num?)?.toDouble() ?? 0.0) +
              (90 * 3.14159 / 180);

          e['x'] = newX;
          e['y'] = newY;
          e['rotation'] = rotation;

          batch.update(col.doc(e['id']), {
            'x': newX,
            'y': newY,
            'rotation': rotation,
          });
        }
      }
    });
    await batch.commit();
  }

  Widget _elementIcon(
      Map<String, dynamic> e, bool selected, bool isHighlighted) {
    final type = e['type'];
    final rotation = (e['rotation'] ?? 0.0) as double;
    final shape = e['shape'] as String?;
    final label = (e['label'] ?? '') as String;
    final features = (e['features'] as List?) ?? [];
    final hasFeat = features.isNotEmpty;

    final String? myPhone = widget.highlightPhone;

    Color bg;
    if (selected) {
      bg = Colors.yellow.withOpacity(0.8);
    } else if (type == 'chair') {
      if (widget.readOnly) {
        // מצב תצוגה בלבד: רק הכיסא של המשתמש אדום, שאר הכיסאות אפורים
        if (e['occupiedBy'] == widget.highlightPhone) {
          bg = Colors.red;
        } else {
          bg = Colors.grey;
        }
      } else {
        // מצב עריכה רגיל
        bg = hasFeat ? Colors.green : Colors.blue;
      }
    } else if (type == 'feature') {
      bg = Colors.orangeAccent;
    } else {
      bg = Colors.brown;
    }

    Widget icon;

    if (type == 'table') {
      double width = 120;
      double height = 80;
      IconData iconData = Icons.table_restaurant;
      BorderRadius borderRadius = BorderRadius.circular(12);

      if (shape == 'circle') {
        width = 80;
        height = 80;
        iconData = Icons.table_bar;
        borderRadius = BorderRadius.circular(40);
      } else if (shape == 'square') {
        width = 80;
        height = 80;
        borderRadius = BorderRadius.circular(4);
      } else if (shape == 'rectangle') {
        width = 140;
        height = 60;
        borderRadius = BorderRadius.circular(8);
      }

      icon = Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: borderRadius,
        ),
        child: Icon(iconData, size: 40, color: Colors.white),
      );
    } else if (type == 'chair') {
      icon = Container(
        width: 40,
        height: 40,
        decoration:
        BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Icon(Icons.event_seat, size: 24, color: Colors.white),
      );
    } else if (type == 'feature') {
      IconData featureIcon;
      switch (label.toLowerCase()) {
        case 'board':
          featureIcon = Icons.border_color;
          break;
        case 'air conditioner':
          featureIcon = Icons.ac_unit;
          break;
        case 'window':
          featureIcon = Icons.window;
          break;
        case 'entrance':
          featureIcon = Icons.login;
          break;
        case 'exit':
          featureIcon = Icons.logout;
          break;
        case 'dance floor':
          featureIcon = Icons.directions_run;
          break;
        case 'speakers':
          featureIcon = Icons.surround_sound;
          break;
        case 'stage':
          featureIcon = Icons.theater_comedy;
          break;
        case 'writing table':
          featureIcon = Icons.edit;
          break;
        case 'screen':
          featureIcon = Icons.tv;
          break;
        case 'charging point':
          featureIcon = Icons.battery_charging_full;
          break;
        default:
          featureIcon = Icons.device_unknown;
      }

      icon = Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(featureIcon, color: Colors.white),
      );
    } else {
      icon = SizedBox.shrink();
    }

    return Transform.rotate(
      angle: rotation,
      child: icon,
    );
  }

  Future<void> _alignSelectionToTable() async {
    final table =
    elements.firstWhere((e) => e['type'] == 'table', orElse: () => {});
    if (table.isEmpty) return;

    final double tableY = table['y'];
    final double tableHeight = 32 + 16 * 2;

    final batch = FirebaseFirestore.instance.batch();
    final colRef = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .collection('elements');

    setState(() {
      for (var e in elements) {
        if (_selectedIds.contains(e['id']) && e['type'] == 'chair') {
          final newY = tableY + tableHeight + 10;
          e['y'] = newY;
          batch.update(colRef.doc(e['id']), {'y': newY});
        }
      }
    });

    await batch.commit();
  }
}

IconData _featureIconFor(String label) {
  switch (label.toLowerCase()) {
    case 'board':
      return Icons.border_color;
    case 'air conditioner':
      return Icons.ac_unit;
    case 'window':
      return Icons.window;
    case 'entrance':
      return Icons.login;
    case 'exit':
      return Icons.logout;
    case 'dance floor':
      return Icons.directions_run;
    case 'speakers':
      return Icons.surround_sound;
    case 'stage':
      return Icons.theater_comedy;
    case 'writing table':
      return Icons.edit;
    case 'screen':
      return Icons.tv;
    case 'charging point':
      return Icons.battery_charging_full;
    default:
      return Icons.device_unknown;
  }
}
