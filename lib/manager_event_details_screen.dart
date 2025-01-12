import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as img;

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
  List<File> eventImages = [];
  FilePickerResult? participantFile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && args.containsKey('eventType')) {
      eventType = args['eventType'];
    }
  }

  Future<void> pickEventImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? pickedImages = await picker.pickMultiImage();

    if (pickedImages != null) {
      for (var image in pickedImages) {
        final file = File(image.path);
        final processedImage = await enhanceImage(file);
        setState(() {
          eventImages.add(processedImage);
        });
      }
    }
  }

  // פונקציה לשיפור תמונה
  Future<File> enhanceImage(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final decodedImage = img.decodeImage(imageBytes);

    if (decodedImage != null) {
      // שיפור התאורה
      final brightenedImage = img.adjustColor(decodedImage, brightness: 0.1);
      // הפחתת רעש
      final denoisedImage = img.gaussianBlur(brightenedImage, 1);

      // המרה חזרה לקובץ
      final processedBytes = img.encodeJpg(denoisedImage);
      final processedFile = await File(imageFile.path).writeAsBytes(processedBytes);
      return processedFile;
    } else {
      return imageFile;
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

  void removeImage(int index) {
    setState(() {
      eventImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event Details'),
        backgroundColor: Colors.blueAccent,
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
                  onPressed: pickEventImages,
                  icon: Icon(Icons.image),
                  label: Text(eventImages.isEmpty
                      ? 'Upload Event Images'
                      : 'Images Selected (${eventImages.length})'),
                ),
                SizedBox(height: 10),
                if (eventImages.isNotEmpty)
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: eventImages.map((file) {
                      return Stack(
                        children: [
                          Image.file(
                            file,
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => removeImage(eventImages.indexOf(file)),
                              child: Icon(Icons.close, color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
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
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
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

  void selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }
}