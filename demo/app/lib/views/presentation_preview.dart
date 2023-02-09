import 'dart:developer';

import 'package:app/views/credential_shared.dart';
import 'package:app/views/dashboard.dart';
import 'package:app/widgets/credential_verified_information_view.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:app/models/store_credential_data.dart';
import 'package:app/widgets/common_title_appbar.dart';
import 'package:app/models/credential_data.dart';
import 'package:app/widgets/primary_button.dart';
import 'package:app/widgets/Credential_card_outline.dart';
import 'package:app/widgets/credential_metadata_card.dart';
import 'package:app/main.dart';

class PresentationPreview extends StatefulWidget {
  final String matchedCredential;
  final CredentialData credentialData;
  const PresentationPreview({super.key, required this.credentialData, required this.matchedCredential});

  @override
  State<PresentationPreview> createState() => PresentationPreviewState();
}

class PresentationPreviewState extends State<PresentationPreview> {
  var uuid = const Uuid();
  late final String userLoggedIn;
  // Todo fetch the name of the  verifier name from the presentation
  late String verifierName = 'Verifier';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) async {
      UserLoginDetails userLoginDetails =  await getUser();
      userLoggedIn = userLoginDetails.username!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  const CustomTitleAppBar(pageTitle: 'Share Credential', addCloseIcon: true, height: 60,),
      body: SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ListTile(
              //todo Issue-174 read the meta data from the backend on page load
              leading: Image.asset('lib/assets/images/credLogo.png'),
              title: Text(verifierName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              subtitle: const Text('verifier.com', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
              trailing: Image.asset('lib/assets/images/verified.png', width: 82, height: 26),
            ),
            CredentialCardOutline(item: widget.credentialData),
            const CredentialMetaDataCard(),
            CredentialVerifiedInformation(credentialData: widget.credentialData, height: MediaQuery.of(context).size.height*0.38,),
            SingleChildScrollView(
              scrollDirection: Axis.vertical,
            child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 150,
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.topCenter,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xffDBD7DC),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 0, 24, 0),
                      ),
                      PrimaryButton(
                          onPressed: () async {
                            await WalletSDKPlugin.presentCredential();
                            var activityLogger = await WalletSDKPlugin.activityLogger();
                            log("while presenting credential $activityLogger");
                            _navigateToCredentialShareSuccess(verifierName);
                          },
                          width: double.infinity,
                          child: const Text('Share Credential', style: TextStyle(fontSize: 16, color: Colors.white))
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
                      ),
                      PrimaryButton(
                        onPressed: (){
                          _navigateToDashboard();
                        },
                        width: double.infinity,
                        gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xffFFFFFF), Color(0xffFFFFFF)]),
                        child: const Text('Cancel', style: TextStyle(fontSize: 16, color: Color(0xff6C6D7C))),
                      ),
                    ],
                  ),
                ), //last one
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
  _navigateToDashboard() async {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const Dashboard()));
  }
  _navigateToCredentialShareSuccess(String verifierName) async {
    Navigator.push(context, MaterialPageRoute(builder: (context) => CredentialShared(verifierName: verifierName, credentialData: widget.credentialData,)));
  }
}