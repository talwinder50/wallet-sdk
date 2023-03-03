import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:app/models/credential_data.dart';

import 'package:app/models/credential_preview.dart';

class CredentialMetaDataCard extends StatelessWidget {
  CredentialData credentialData;
  CredentialMetaDataCard({required this.credentialData, Key? key}) : super(key: key);

  late var issueDate = '';
  late var expiryDate = '';
  getClaimList() {
    var data = json.decode(credentialData.credentialDisplayData!);
    var credentialClaimsData = data['credential_displays'][0]['claims'] as List;
    return credentialClaimsData.map<CredentialPreviewData>((json) => CredentialPreviewData.fromJson(json)).toList();
  }

  getIssuanceDate() {
    var claimsList = getClaimList();
    for (var claims in claimsList){
      if (claims.label.contains("Issue Date")) {
        var issueDate = claims.value;
        return  issueDate;
      }
    }
    final now = DateTime.now();
    String formatter = DateFormat('yMMMMd').format(now);// 28/03/2020
    return  formatter;
  }

  getExpiryDate(){
    var claimsList = getClaimList();
    for (var claims in claimsList){
      if (claims.label.contains("Expiry Date")) {
        var expiryDate = claims.value;
        return expiryDate;
      }
    }
    return 'Never';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 4,
                offset: const Offset(4, 4),
              )
            ]),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
      child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
            child: SizedBox(
              height: 60,
              child: ListTile(
                  title: const Text(
                    'Added on',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff190C21),
                    ),
                    textAlign: TextAlign.start,
                  ),
                  subtitle: Text(
                    getIssuanceDate(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xff6C6D7C),
                    ),
                    textAlign: TextAlign.start,
                  )
              ),
            )
        ),
        Flexible(
            child: SizedBox(
                height: 60,
                child: ListTile(
                    title: const Text(
                      'Expires on',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff190C21),
                      ),
                      textAlign: TextAlign.start,
                    ),
                    //TODO need to add fallback and network image url
                    subtitle: Text(
                      getExpiryDate(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xff6C6D7C),
                      ),
                      textAlign: TextAlign.start,
                    )
                )
            )
        ),
        const Flexible(
            child: SizedBox(
                height: 60,
                child: ListTile(
                    title: Text(
                      'Last used',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff190C21),
                      ),
                      textAlign: TextAlign.start,
                    ),
                    //TODO need to add fallback and network image url
                    subtitle: Text(
                      'Never',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xff6C6D7C),
                      ),
                      textAlign: TextAlign.start,
                    )
                )
            )
        )
      ],
      )
    );
  }
}