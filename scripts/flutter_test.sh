#!/bin/bash
#
# Copyright Avast Software. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

cd demo/app
flutter pub get
flutter build apk --debug

cd ../../test/integration
INITIATE_ISSUANCE_URL=$(../../build/bin/integration-cli issuance)
INITIATE_VERIFICATION_URL=$(../../build/bin/integration-cli verification)

echo "INITIATE_ISSUANCE_URL:${INITIATE_ISSUANCE_URL}"
echo "INITIATE_VERIFICATION_URL:${INITIATE_VERIFICATION_URL}"

cd ../../demo/app
adb reverse tcp:8075 tcp:8075
flutter test integration_test --dart-define=INITIATE_ISSUANCE_URL="${INITIATE_ISSUANCE_URL}" --dart-define=INITIATE_VERIFICATION_URL="${INITIATE_VERIFICATION_URL}"