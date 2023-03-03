import 'package:app/views/credential_shared.dart';
import 'package:app/views/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:app/models/store_credential_data.dart';
import 'package:app/widgets/common_title_appbar.dart';
import 'package:app/models/credential_data.dart';
import 'package:app/widgets/primary_button.dart';
import 'package:app/main.dart';
import 'package:app/services/storage_service.dart';
import 'package:app/models/activity_data_object.dart';
import 'package:app/widgets/credential_card.dart';

class PresentationPreviewMultiCred extends StatefulWidget {
  final List<CredentialData> credentialData;
  const PresentationPreviewMultiCred({super.key, required this.credentialData});

  @override
  State<PresentationPreviewMultiCred> createState() => PresentationPreviewMultiCredState();
}

class PresentationPreviewMultiCredState extends State<PresentationPreviewMultiCred> {
  final StorageService _storageService = StorageService();
  final Future<SharedPreferences> prefs = SharedPreferences.getInstance();
  var uuid = const Uuid();
  late final String userLoggedIn;
  // Todo fetch the name of the  verifier name from the presentation
  late String verifierName = 'Verifier';
  bool checked = false;
  late CredentialData selectedCredentialData = widget.credentialData[0];
  int selectedRadio = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) async {
      UserLoginDetails userLoginDetails =  await getUser();
      userLoggedIn = userLoginDetails.username!;
    });
  }

  setSelectedRadio(int val) {
    setState(() {
      selectedRadio = val;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
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
              for (var i = 0; i < widget.credentialData.length; i++)
                RadioListTile(
                controlAffinity: ListTileControlAffinity.leading,
                title: CredentialCard(credentialData:  widget.credentialData[i], isDashboardWidget: false, isDetailArrowRequired: false,),
                activeColor: Colors.deepPurple,
                autofocus: false,
                value:  i,
                groupValue: selectedRadio,
                onChanged: (val) {
                      print("Radio $val");
                      selectedCredentialData = widget.credentialData[i];
                      setSelectedRadio(val!);
               },
           ),
            Padding(
              padding: EdgeInsets.only(top: width*0.8),
            ),
            Align(
                alignment: Alignment.bottomCenter,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 0, 24, 0),
                      ),
                      PrimaryButton(
                          onPressed: () async {
                            final SharedPreferences pref = await prefs;
                            await WalletSDKPlugin.presentCredential();
                            var activities = await WalletSDKPlugin.storeActivityLogger();
                            var credID = pref.getString('credID');
                            _storageService.addActivities(ActivityDataObj(credID!, activities));
                            _navigateToCredentialShareSuccess(verifierName);
                          },
                          width: double.infinity,
                          child: const Text('Share Credential', style: TextStyle(fontSize: 16, color: Colors.white))
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
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
      Navigator.push(context, MaterialPageRoute(builder: (context) => CredentialShared(verifierName: verifierName, credentialData: selectedCredentialData)));
  }
}