/*
Copyright Avast Software. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
*/

package integration

import (
	"testing"

	"github.com/stretchr/testify/require"

	"github.com/trustbloc/wallet-sdk/cmd/wallet-sdk-gomobile/api"
	"github.com/trustbloc/wallet-sdk/cmd/wallet-sdk-gomobile/credential"
	"github.com/trustbloc/wallet-sdk/cmd/wallet-sdk-gomobile/did"
	"github.com/trustbloc/wallet-sdk/cmd/wallet-sdk-gomobile/ld"
	"github.com/trustbloc/wallet-sdk/cmd/wallet-sdk-gomobile/localkms"
	"github.com/trustbloc/wallet-sdk/cmd/wallet-sdk-gomobile/openid4ci"
	"github.com/trustbloc/wallet-sdk/cmd/wallet-sdk-gomobile/openid4vp"
	"github.com/trustbloc/wallet-sdk/test/integration/pkg/setup/oidc4ci"
	"github.com/trustbloc/wallet-sdk/test/integration/pkg/setup/oidc4vp"
	"github.com/trustbloc/wallet-sdk/test/integration/pkg/testenv"
)

func TestOpenID4VPFullFlow(t *testing.T) {
	testHelper := newVPTestHelper(t)

	issuedCredentials := testHelper.issueCredentials(t)

	setup := oidc4vp.NewSetup(testenv.NewHttpRequest())

	err := setup.AuthorizeVerifier("test_org")
	require.NoError(t, err)

	initiateURL, err := setup.InitiateInteraction("v_myprofile_jwt")
	require.NoError(t, err)

	didResolver, err := did.NewResolver("")
	require.NoError(t, err)

	interaction := openid4vp.NewInteraction(
		initiateURL, testHelper.KMS, testHelper.KMS.GetCrypto(), didResolver, ld.NewDocLoader())

	// TODO: remove after ion resolution is added.
	t.SkipNow()

	query, err := interaction.GetQuery()
	require.NoError(t, err)

	verifiablePres, err := credential.NewInquirer(ld.NewDocLoader()).
		Query(query, credential.NewCredentialsOpt(issuedCredentials))
	require.NoError(t, err)

	keyID, err := testHelper.DIDDoc.AssertionMethodKeyID()
	require.NoError(t, err)

	err = interaction.PresentCredential(verifiablePres, keyID)
	require.NoError(t, err)
}

type vpTestHelper struct {
	KMS    *localkms.KMS
	DIDDoc *api.DIDDocResolution
}

func newVPTestHelper(t *testing.T) *vpTestHelper {
	kms, err := localkms.NewKMS(nil)
	require.NoError(t, err)

	// create DID
	c, err := did.NewCreatorWithKeyWriter(kms)
	require.NoError(t, err)

	didDoc, err := c.Create("key", &api.CreateDIDOpts{})
	require.NoError(t, err)

	return &vpTestHelper{
		KMS:    kms,
		DIDDoc: didDoc,
	}
}

func (h *vpTestHelper) issueCredentials(t *testing.T) *api.VerifiableCredentialsArray {
	oidc4ciSetup, err := oidc4ci.NewSetup(testenv.NewHttpRequest())
	require.NoError(t, err)

	err = oidc4ciSetup.AuthorizeIssuer("test_org")
	require.NoError(t, err)

	credentials := api.NewVerifiableCredentialsArray()

	for i := 0; i < 2; i++ {
		initiateIssuanceURL, err := oidc4ciSetup.InitiatePreAuthorizedIssuance("bank_issuer")
		require.NoError(t, err)

		signerCreator, err := localkms.CreateSignerCreator(h.KMS)
		require.NoError(t, err)

		didResolver, err := did.NewResolver("")
		require.NoError(t, err)

		didID, err := h.DIDDoc.ID()
		require.NoError(t, err)

		clientConfig := openid4ci.ClientConfig{
			UserDID:       didID,
			ClientID:      "ClientID",
			SignerCreator: signerCreator,
			DIDResolver:   didResolver,
		}

		interaction, err := openid4ci.NewInteraction(initiateIssuanceURL, &clientConfig)
		require.NoError(t, err)

		authorizeResult, err := interaction.Authorize()
		require.NoError(t, err)
		require.False(t, authorizeResult.UserPINRequired)

		result, err := interaction.RequestCredential(&openid4ci.CredentialRequestOpts{})

		require.NoError(t, err)
		require.NotEmpty(t, result)

		for i := 0; i < result.Length(); i++ {
			credentials.Add(result.AtIndex(i))
		}

	}

	return credentials
}
