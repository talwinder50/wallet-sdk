import 'dart:convert';
import 'dart:developer';
import 'package:app/models/credential_data.dart';
import 'package:app/views/credential_details.dart';
import 'package:flutter/material.dart';

class CredentialCard extends StatefulWidget {
  CredentialData credentialData;
  bool isDashboardWidget;
  List<Object?>? activityLogger;

  CredentialCard({required this.credentialData, required this.isDashboardWidget, this.activityLogger,  Key? key}) : super(key: key);
  @override
  State<CredentialCard> createState() => _CredentialCardState();
}

class _CredentialCardState extends State<CredentialCard> {
  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> issuer = jsonDecode(widget.credentialData.credentialDisplayData!);
    final credentialDisplayName = issuer['credential_displays'][0]['overview']['name'];
    log("what is data credential card ${widget.credentialData.activityLoggerData}");
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
      child: Container(
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    offset: const Offset(3, 3),
                    color: Colors.grey.shade300,
                    blurRadius: 5)
              ]),
          child: ListTile(
            title: Text(
              credentialDisplayName!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xff190C21),
              ),
              textAlign: TextAlign.start,
            ),
            //TODO need to add fallback and network image url
            leading: const Image(
                image: AssetImage('lib/assets/images/genericCredential.png'),
                width: 47,
                height: 47,
                fit: BoxFit.cover,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_circle_right, size: 32, color: Color(0xffB6B7C7)),
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CredentialDetails(credentialData: widget.credentialData, credentialName: credentialDisplayName!, isDashboardWidget: widget.isDashboardWidget, activityLogger: widget.activityLogger,)),
                );
              },
            ),
          )),
    );
  }
}