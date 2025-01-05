import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class ManagerDetailsUpdateScreen extends StatefulWidget {
  @override
  _ManagerDetailsUpdateScreenState createState() =>
      _ManagerDetailsUpdateScreenState();
}

class _ManagerDetailsUpdateScreenState
    extends State<ManagerDetailsUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? eventType;
  XFile? eventImage;
  FilePickerResult? participantFile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && args.containsKey('eventType')) {
      eventType = args['eventType'];
    }
  }

  void selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> pickEventImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        eventImage = pickedImage;
      });
    }
  }

  Future<void> pickParticipantFile() async {
    final FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['csv', 'xlsx']);
    if (result != null) {
      setState(() {
        participantFile = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event Details'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              Navigator.pushNamed(context, '/guide'); // נווט למסך העזרה
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Event Type: $eventType',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Event Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the event name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: locationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the location';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => selectDate(context),
                        child: Text(selectedDate == null
                            ? 'Select Date'
                            : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => selectTime(context),
                        child: Text(selectedTime == null
                            ? 'Select Time'
                            : '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: pickEventImage,
                  icon: Icon(Icons.image),
                  label: Text(eventImage == null
                      ? 'Upload Event Image'
                      : 'Image Selected'),
                ),
                if (eventImage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      'Selected Image: ${eventImage!.name}',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: pickParticipantFile,
                  icon: Icon(Icons.upload_file),
                  label: Text(participantFile == null
                      ? 'Upload Participant List'
                      : 'File Selected'),
                ),
                if (participantFile != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      'Selected File: ${participantFile!.files.single.name}',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/add_participant');
                  },
                  icon: Icon(Icons.person_add),
                  label: Text('Add Participant Manually'),
                ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate() &&
                          selectedDate != null &&
                          selectedTime != null) {
                        // Save event details
                        print('Event Type: $eventType');
                        print('Event Name: ${nameController.text}');
                        print('Location: ${locationController.text}');
                        print('Date: ${selectedDate.toString()}');
                        print('Time: ${selectedTime.toString()}');
                        print('Image: ${eventImage?.path}');
                        print('File: ${participantFile?.files.single.name}');

                        // Navigate to dashboard or next step
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please fill all fields')),
                        );
                      }
                    },
                    child: Text('Submit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
