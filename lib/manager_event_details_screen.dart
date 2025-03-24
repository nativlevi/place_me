import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final TextEditingController participantNameController =
      TextEditingController();
  final TextEditingController participantPhoneController =
      TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? eventType;
  List<File> eventImages = [];
  List<Map<String, String>> manualParticipants = [];
  FilePickerResult? participantFile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && args.containsKey('eventType')) {
      eventType = args['eventType'];
    }
  }

  Future<void> addAllowedUser(String phoneNumber) async {
    if (!phoneNumber.startsWith('+')) {
      phoneNumber = '+972${phoneNumber.substring(1)}'; // הפורמט הבינלאומי
    }

    await FirebaseFirestore.instance
        .collection("allowed_users")
        .doc(phoneNumber)
        .set({
      "phone": phoneNumber,
      "addedAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> pickEventImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? pickedImages = await picker.pickMultiImage();

    if (pickedImages != null) {
      setState(() {
        eventImages.addAll(pickedImages.map((image) => File(image.path)));
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a valid file (CSV or XLSX)')),
      );
    }
  }

  void removeImage(int index) {
    setState(() {
      eventImages.removeAt(index);
    });
  }

  void addManualParticipant() {
    final participantName = participantNameController.text.trim();
    final participantPhone = participantPhoneController.text.trim();

    if (participantName.isNotEmpty && participantPhone.isNotEmpty) {
      setState(() {
        manualParticipants
            .add({'name': participantName, 'phone': participantPhone});
        participantNameController.clear();
        participantPhoneController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter both name and phone number')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFD0DDD0), // Light green background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Event Details',
          style: TextStyle(
            fontFamily: 'Satreva',
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Color(0xFF727D73),
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Type
                Text(
                  'Event Type: $eventType',
                  style: TextStyle(
                    fontFamily: 'Source Sans Pro',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D3D3D),
                  ),
                ),
                SizedBox(height: 20),

                // Event Name
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.event, color: Color(0xFF3D3D3D)),
                    hintText: 'Enter Event Name',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the event name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Event Location
                TextFormField(
                  controller: locationController,
                  decoration: InputDecoration(
                    prefixIcon:
                        Icon(Icons.location_on, color: Color(0xFF3D3D3D)),
                    hintText: 'Enter Location',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the location';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Select Date and Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => selectDate(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3D3D3D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                        child: Text(
                          selectedDate == null
                              ? 'Select Date'
                              : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => selectTime(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3D3D3D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                        child: Text(
                          selectedTime == null
                              ? 'Select Time'
                              : '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Upload Event Images
                Text(
                  'Upload clear and high-quality images in PNG, JPG, or JPEG format.',
                  style: TextStyle(
                    fontFamily: 'Source Sans Pro',
                    fontSize: 16,
                    color: Color(0xFF727D73),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: pickEventImages,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3D3D3D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  icon: Icon(Icons.image, color: Colors.white),
                  label: Text(
                    eventImages.isEmpty
                        ? 'Upload Images'
                        : 'Images Selected (${eventImages.length})',
                    style: TextStyle(color: Colors.white),
                  ),
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
                              onTap: () =>
                                  removeImage(eventImages.indexOf(file)),
                              child: Icon(Icons.close, color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                SizedBox(height: 20),

                // Upload Participant List
                Text(
                  'Upload a participant list in CSV or Excel format.',
                  style: TextStyle(
                    fontFamily: 'Source Sans Pro',
                    fontSize: 16,
                    color: Color(0xFF727D73),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: pickParticipantFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3D3D3D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  icon: Icon(Icons.upload_file, color: Colors.white),
                  label: Text(
                    participantFile == null
                        ? 'Upload Participant List'
                        : 'File Selected',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                if (participantFile != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      'Selected File: ${participantFile!.files.single.name}',
                      style: TextStyle(
                        color: Colors.green,
                        fontFamily: 'Source Sans Pro',
                      ),
                    ),
                  ),
                SizedBox(height: 20),

                // Add Manual Participants
                Text(
                  'Add participants manually:',
                  style: TextStyle(
                    fontFamily: 'Source Sans Pro',
                    fontSize: 16,
                    color: Color(0xFF727D73),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: participantNameController,
                        decoration: InputDecoration(
                          prefixIcon:
                              Icon(Icons.person, color: Color(0xFF3D3D3D)),
                          hintText: 'Name',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: participantPhoneController,
                        decoration: InputDecoration(
                          prefixIcon:
                              Icon(Icons.phone, color: Color(0xFF3D3D3D)),
                          hintText: 'Phone',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: addManualParticipant,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3D3D3D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
                if (manualParticipants.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Column(
                      children: [
                        ...manualParticipants.map((participant) {
                          return Text(
                            '- ${participant['name']} (${participant['phone']})',
                            style: TextStyle(
                              fontFamily: 'Source Sans Pro',
                              fontSize: 16,
                              color: Color(0xFF3D3D3D),
                            ),
                          );
                        }).toList(),

                        // Add Manual Participants
                        Text(
                          'Add participants manually:',
                          style: TextStyle(
                            fontFamily: 'Source Sans Pro',
                            fontSize: 16,
                            color: Color(0xFF727D73),
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: participantNameController,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.person,
                                      color: Color(0xFF3D3D3D)),
                                  hintText: 'Name',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: participantPhoneController,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.phone,
                                      color: Color(0xFF3D3D3D)),
                                  hintText: 'Phone',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: addManualParticipant,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF3D3D3D),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                              ),
                              child: Icon(Icons.add, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                if (manualParticipants.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: manualParticipants.map((participant) {
                        return Text(
                          '- ${participant['name']} (${participant['phone']})',
                          style: TextStyle(
                            fontFamily: 'Source Sans Pro',
                            fontSize: 16,
                            color: Color(0xFF3D3D3D),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                SizedBox(height: 20),

                // Submit Button
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
                    child: Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3D3D3D),
                      padding:
                          EdgeInsets.symmetric(vertical: 15, horizontal: 100),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
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
