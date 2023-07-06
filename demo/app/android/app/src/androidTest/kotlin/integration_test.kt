import android.content.Context
import android.net.Uri
import android.util.Log
import androidx.test.filters.SmallTest
import androidx.test.platform.app.InstrumentationRegistry
import com.google.common.truth.Truth.assertThat
import dev.trustbloc.wallet.BuildConfig
import dev.trustbloc.wallet.sdk.api.KeyWriter
import dev.trustbloc.wallet.sdk.api.StringArray
import dev.trustbloc.wallet.sdk.verifiable.CredentialsArray
import dev.trustbloc.wallet.sdk.credential.Inquirer
import dev.trustbloc.wallet.sdk.did.Creator
import dev.trustbloc.wallet.sdk.did.Resolver
import dev.trustbloc.wallet.sdk.did.ResolverOpts
import dev.trustbloc.wallet.sdk.localkms.Localkms
import dev.trustbloc.wallet.sdk.openid4ci.*
import dev.trustbloc.wallet.sdk.openid4vp.Interaction as VPInteraction
import dev.trustbloc.wallet.sdk.version.Version
import dev.trustbloc.wallet.sdk.otel.Otel
import okhttp3.*
import org.junit.Before
import org.junit.Test
import walletsdk.kmsStorage.KmsStore
import java.io.IOException
import java.net.URI


@SmallTest
class IntegrationTest {
    lateinit var instrumentationContext: Context

    @Before
    fun setup() {
        instrumentationContext = InstrumentationRegistry.getInstrumentation().context
    }

      @Test
    fun fullFlow() {
         val trace = Otel.newTrace()

         assertThat(Version.getVersion()).isEqualTo("testVer")
        assertThat(Version.getGitRevision()).isEqualTo("testRev")
        assertThat(Version.getBuildTime()).isEqualTo("testTime")

        val kms = Localkms.newKMS(KmsStore(instrumentationContext))

        val resolverOpts = ResolverOpts()
        resolverOpts.setResolverServerURI("http://localhost:8072/1.0/identifiers")
        val didResolver = Resolver(resolverOpts)

        val crypto = kms.crypto

        val didCreator = Creator(kms as KeyWriter)
        val userDID = didCreator.create("ion", null)

        // Issue VCs
        val requestURI = BuildConfig.INITIATE_ISSUANCE_URL

        val requiredOpenID4CIArgs = InteractionArgs(requestURI, crypto, didResolver)

        val ciOpts = InteractionOpts()
        ciOpts.addHeader(trace.traceHeader())

        val ciInteraction = Interaction(requiredOpenID4CIArgs, ciOpts)

        val pinRequired = ciInteraction.preAuthorizedCodeGrantParams().pinRequired()
        assertThat(pinRequired).isFalse()

        val issuedCreds = ciInteraction.requestCredential(userDID.assertionMethod())
        assertThat(issuedCreds.length()).isGreaterThan(0)

        //Presenting VCs
        val authorizationRequestURI = BuildConfig.INITIATE_VERIFICATION_URL

        val openID4VPInteractionRequiredArgs = dev.trustbloc.wallet.sdk.openid4vp.Args(
            authorizationRequestURI,
            crypto,
            didResolver
        )

        val vpOpts = dev.trustbloc.wallet.sdk.openid4vp.Opts()
        vpOpts.addHeader(trace.traceHeader())

        val vpInteraction = VPInteraction(openID4VPInteractionRequiredArgs, vpOpts)

        val credentialsQuery = vpInteraction.getQuery()

        val inquirer = Inquirer(null)

        // TODO: maybe better to rename getSubmissionRequirements to something like matchCredentialsWithRequirements
        val submissionRequirements =
                inquirer.getSubmissionRequirements(credentialsQuery, issuedCreds)

        assertThat(submissionRequirements.len()).isGreaterThan(0)
        val requirement = submissionRequirements.atIndex(0)
        // rule "all" means that we need to satisfy all input descriptors.
        // In case of multiple input descriptors we need to send one credential per descriptor
        // that satisfy it.
        assertThat(requirement.rule()).isEqualTo("all")

        // In current test case we have only one input descriptor. so we need send only one credential.
        assertThat(submissionRequirements.atIndex(0).descriptorLen()).isEqualTo(1)

        val requirementDescriptor = requirement.descriptorAtIndex(0)
        // matchedVCs contains list of credentials that match given input descriptor.
        assertThat(requirementDescriptor.matchedVCs.length()).isGreaterThan(0)

        val selectedCreds = CredentialsArray()
        // Pick first credential from matched creds
        selectedCreds.add(requirementDescriptor.matchedVCs.atIndex(0))

        // Presenting from selected credentials.
        vpInteraction.presentCredential(selectedCreds)
    }

    @Test
     fun testAuthFlow() {
        val trace = Otel.newTrace()

        assertThat(Version.getVersion()).isEqualTo("testVer")
        assertThat(Version.getGitRevision()).isEqualTo("testRev")
        assertThat(Version.getBuildTime()).isEqualTo("testTime")

        val kms = Localkms.newKMS(KmsStore(instrumentationContext))

        val resolverOpts = ResolverOpts()
        resolverOpts.setResolverServerURI("http://localhost:8072/1.0/identifiers")
        val didResolver = Resolver(resolverOpts)

        val crypto = kms.crypto

        val didCreator = Creator(kms as KeyWriter)
        val userDID = didCreator.create("ion", null)

        // Issue VCs
        val requestURI = BuildConfig.INITIATE_ISSUANCE_URLS_AUTH_CODE_FLOW
        println("requestURI ->")
        println( requestURI)

        val requiredOpenID4CIArgs = InteractionArgs(requestURI, crypto, didResolver)
        println("requiredOpenID4CIArgs")
        println(requiredOpenID4CIArgs)
        val ciOpts = InteractionOpts()
        ciOpts.addHeader(trace.traceHeader())

        val ciInteraction = Interaction(requiredOpenID4CIArgs, ciOpts)

        val authCodeGrant = ciInteraction.authorizationCodeGrantTypeSupported()
        assertThat(authCodeGrant).isTrue()

        val scopes = StringArray()
        scopes.append("openid").append("profile")

        val createAuthorizationURLOpts = CreateAuthorizationURLOpts().setScopes(scopes)

        val authorizationLink = ciInteraction.createAuthorizationURL("oidc4vc_client", "http://127.0.0.1/callback", createAuthorizationURLOpts)
        assertThat(authorizationLink).isNotEmpty()

        var redirectUrl = URI(authorizationLink)

        val client = OkHttpClient.Builder()
            .retryOnConnectionFailure(true)
            .followRedirects(false)
            .build()

        var request = Request.Builder()
            .url(redirectUrl.toString())
            .header("Connection", "close")
            .build()
        val response = client.newCall(request).execute()
        assertThat(response.isRedirect).isTrue()
        var location = response.headers["Location"]
        assertThat(location).contains("cognito-mock.trustbloc.local")
            if (location != null) {
                if (location.contains("cognito-mock.trustbloc.local")){
                    var upr = URI(location.replace("cognito-mock.trustbloc.local", "localhost"));
                    assertThat(upr.toString()).contains("localhost")
                    var request = Request.Builder()
                        .url(upr.toString())
                        .header("Connection", "close")
                        .build()
                    val response = client.newCall(request).clone().execute()
                    location = response.headers["location"]
                    assertThat(location).contains("oidc/redirect")
                    var request2 = Request.Builder()
                        .url(location.toString())
                        .header("Connection", "close")
                        .build()
                    val response2 = client.newCall(request2).clone().execute()
                    location = response2.headers["location"]
                    assertThat(location).contains("127.0.0.1")
                    var issuedCreds = ciInteraction.requestCredentialWithAuth(userDID.assertionMethod(), location, null)
                    assertThat(issuedCreds.length()).isGreaterThan(0)
                }
            }
    }
}
