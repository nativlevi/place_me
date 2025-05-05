import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';

class SeatingPreferencesScreen extends StatefulWidget {
  final String eventType;
  final String phone;

  const SeatingPreferencesScreen({
    Key? key,
    required this.eventType,
    required this.phone,
  }) : super(key: key);

  @override
  _SeatingPreferencesScreenState createState() =>
      _SeatingPreferencesScreenState();
}

class _SeatingPreferencesScreenState extends State<SeatingPreferencesScreen> {
  // controllers לשני ה-TextFields
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _notToController = TextEditingController();

  late Map<String, bool> preferences;
  bool showInLists = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initPreferencesKeys();
    _loadPreferencesFromFirestore();
  }

  @override
  void dispose() {
    _toController.dispose();
    _notToController.dispose();
    super.dispose();
  }

  /// בונה את המפת העדפות עם ברירות מחדל (false)
  void _initPreferencesKeys() {
    switch (widget.eventType) {
      case 'Classroom/Workshop':
        preferences = {
          'Board': false,
          'Air Conditioner': false,
          'Window': false,
          'Entrance': false,
        };
        break;
      case 'Family/Social Event':
        preferences = {
          'Dance Floor': false,
          'Speakers': false,
          'Exit': false,
        };
        break;
      case 'Conference/Professional Event':
        preferences = {
          'Stage': false,
          'Writing Table': false,
          'Screen': false,
          'Charging Point': false,
        };
        break;
      default:
        preferences = {};
    }
  }

  /// טוען את העדפות המשתתף (אם כבר קיימות) ומעדכן את ה־UI
  Future<void> _loadPreferencesFromFirestore() async {
    final safeType = widget.eventType.replaceAll('/', '_');
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.phone)
        .collection('preferences')
        .doc(safeType);

    final snap = await docRef.get();
    if (!snap.exists) return;

    final data = snap.data()!;
    setState(() {
      // טקסטים
      _toController.text = data['preferTo'] ?? '';
      _notToController.text = data['preferNotTo'] ?? '';
      // ויזיביליטי
      showInLists = data['showInLists'] ?? true;
      // מפת אפשרויות
      final opts = (data['options'] as Map<String, dynamic>?) ?? {};
      opts.forEach((key, val) {
        if (preferences.containsKey(key)) {
          preferences[key] = val as bool;
        }
      });
    });
  }

  /// שומר חזרה את כל ההעדפות
  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);

    final safeType = widget.eventType.replaceAll('/', '_');
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.phone)
        .collection('preferences')
        .doc(safeType);

    final payload = {
      'preferTo': _toController.text.trim(),
      'preferNotTo': _notToController.text.trim(),
      'showInLists': showInLists,
      'options': preferences,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await docRef.set(payload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences saved!')),
      );
      Navigator.pop(context); // חזרה למסך הקודם
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving preferences: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// בונה כרטיס Toggle עבור כל אפשרות
  Widget _buildToggleCard(String title) {
    final val = preferences[title]!;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.grey[200],
      child: Column(
        children: [
          ListTile(
            leading: _getIconForPreference(title),
            title: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Source Sans Pro',
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Switch(
              value: val,
              onChanged: (b) => setState(() => preferences[title] = b),
              activeColor: const Color(0xFFF3B519),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              val
                  ? 'You prefer to be close to the $title.'
                  : 'You prefer to be far from the $title.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _getIconForPreference(String preference) {
    switch (preference) {
      case 'Board':
        return Image.asset('icons/board_icon.png', width: 32, height: 32);
      case 'Air Conditioner':
        return Image.asset('icons/ac_icon.png', width: 32, height: 32);
      case 'Window':
        return Image.asset('icons/window_icon.png', width: 32, height: 32);
      case 'Entrance':
        return Image.asset('icons/door_icon.png', width: 32, height: 32);
      case 'Dance Floor':
        return Image.asset('icons/dance_icon.png', width: 32, height: 32);
      case 'Speakers':
        return Image.asset('icons/speaker_icon.png', width: 32, height: 32);
      case 'Exit':
        return Image.asset('icons/exit_icon.png', width: 32, height: 32);
      case 'Stage':
        return Image.asset('icons/stage_icon.png', width: 32, height: 32);
      case 'Writing Table':
        return Image.asset('icons/table_icon.png', width: 32, height: 32);
      case 'Screen':
        return Image.asset('icons/screen_icon.png', width: 32, height: 32);
      case 'Charging Point':
        return Image.asset('icons/charging_icon.png', width: 32, height: 32);
      default:
        return Image.asset('icons/default_icon.png', width: 32, height: 32);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFD0DDD0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Choose Preferences',
          style: TextStyle(
            fontFamily: 'Satreva',
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Color(0xFF727D73),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            // שדה "I want to sit next to"
            TextField(
              controller: _toController,
              decoration: InputDecoration(
                prefixIcon:
                const Icon(Icons.person, color: Color(0xFF3D3D3D)),
                hintText: 'I want to sit next to:',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 15),

            // שדה "I don’t want to sit next to"
            TextField(
              controller: _notToController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_off,
                    color: Color(0xFF3D3D3D)),
                hintText: 'I don’t want to sit next to:',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // כרטיס Visibility
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              color: Colors.grey[200],
              child: ListTile(
                leading: Icon(
                  showInLists ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF3D3D3D),
                ),
                title: Text(
                  showInLists
                      ? 'You are visible in the lists'
                      : 'You are hidden from the lists',
                  style: const TextStyle(
                    fontFamily: 'Source Sans Pro',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Switch(
                  value: showInLists,
                  onChanged: (v) => setState(() => showInLists = v),
                  activeColor: const Color(0xFFF3B519),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // רשימת ההעדפות
            ...preferences.keys
                .map((k) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: _buildToggleCard(k),
            ))
                .toList(),

            const SizedBox(height: 20),

            // כפתור שמירה
            ElevatedButton(
              onPressed: _isSaving ? null : _savePreferences,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D3D3D),
                padding: const EdgeInsets.symmetric(
                    vertical: 15, horizontal: 100),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: _isSaving
                  ? SizedBox(
                height: 50,
                width: 50,
                child: Lottie.network(
                  'https://lottie.host/86d6dc6e-3e3d-468c-8bc6-2728590bb291/HQPr260dx6.json',
                ),
              )
                  : const Text(
                'SAVE',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
