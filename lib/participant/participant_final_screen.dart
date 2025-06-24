import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:place_me/manager/interactive_room_editor.dart'; // יש לוודא שזה נכון

class ParticipantFinalScreen extends StatelessWidget {
  final String eventId;
  final String participantPhone; // כאן נעביר את הפלאפון (או מזהה) של המשתתף

  const ParticipantFinalScreen({
    Key? key,
    required this.eventId,
    required this.participantPhone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InteractiveRoomEditor(
        eventId: eventId,
        readOnly: true,
        highlightPhone: participantPhone, // עובר ל־highlightPhone
      ),
    );
  }
}