
class CredentialData {
  final String rawCredential;
  final String credentialDisplayData;
  final String issuerURL;
  final String activityLoggerData;


  CredentialData({ required this.rawCredential, required this.issuerURL, required this.credentialDisplayData, required this.activityLoggerData});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['rawCredential'] = rawCredential;
    data['credentialDisplayData'] = credentialDisplayData;
    data['issuerURL'] = issuerURL;
    data['activityLoggerData'] = activityLoggerData;
    return data;
  }

  factory CredentialData.fromJson( Map<String, dynamic> json) {
    return CredentialData(
      rawCredential: json['rawCredential'],
      credentialDisplayData: json['credentialDisplayData'],
      issuerURL: json['issuerURL'],
      activityLoggerData: json['activityLoggerData'],
    );
  }
}

