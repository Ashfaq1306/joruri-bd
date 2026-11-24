package bd.joruri.joruri_bd

import android.app.Activity
import android.content.Intent
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import com.google.android.gms.common.api.ResolvableApiException
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.LocationSettingsRequest
import com.google.android.gms.location.Priority
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Small native helpers for the Flutter side (channel "joruri/native"):
 *  - enableLocation: Google's one-tap "Turn on device location" dialog
 *    (the same one bKash shows), so nobody has to find the setting.
 *  - installApk: opens Android's installer for an update the app downloaded
 *    (apps outside Google Play cannot install silently; the person taps Update).
 *  - sign-in links: an e-mail sign-in link (https://joruri-bd.firebaseapp.com/__/auth/...)
 *    opens this activity; the link is handed to Flutter to finish signing in.
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var initialLink: String? = null
    private var pendingLocation: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        initialLink = linkFrom(intent)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "joruri/native").apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "initialLink" -> {
                        result.success(initialLink)
                        initialLink = null
                    }
                    "canInstallApks" -> result.success(canInstallApks())
                    "isLocationOn" -> result.success(isLocationOn())
                    "enableLocation" -> enableLocation(result)
                    "openInstallSettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName")))
                        }
                        result.success(null)
                    }
                    "installApk" -> {
                        val path = call.argument<String>("path")
                        if (path == null || !File(path).exists()) {
                            result.error("missing", "APK not found", null)
                        } else if (!canInstallApks()) {
                            result.success("needsPermission")
                        } else {
                            try {
                                val uri = FileProvider.getUriForFile(this@MainActivity, "$packageName.updates", File(path))
                                val install = Intent(Intent.ACTION_VIEW)
                                    .setDataAndType(uri, "application/vnd.android.package-archive")
                                    .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(install)
                                result.success("started")
                            } catch (e: Exception) {
                                result.error("failed", e.message, null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    /**
     * "on": location is (now) on. "declined": the person tapped No thanks.
     * "unavailable": no Google Play services or the dialog cannot be shown;
     * Flutter then opens the phone's location settings instead.
     */
    private fun enableLocation(result: MethodChannel.Result) {
        if (isLocationOn()) return result.success("on")
        if (pendingLocation != null) return result.success("unavailable")
        val request = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 10_000).build()
        val settings = LocationSettingsRequest.Builder().addLocationRequest(request).setAlwaysShow(true).build()
        try {
            LocationServices.getSettingsClient(this).checkLocationSettings(settings)
                .addOnSuccessListener { result.success("on") }
                .addOnFailureListener { e ->
                    if (e is ResolvableApiException) {
                        try {
                            pendingLocation = result
                            e.startResolutionForResult(this, LOCATION_REQUEST)
                        } catch (_: Exception) {
                            pendingLocation = null
                            result.success("unavailable")
                        }
                    } else {
                        result.success("unavailable")
                    }
                }
        } catch (_: Exception) {
            result.success("unavailable")
        }
    }

    @Deprecated("Needed for ResolvableApiException.startResolutionForResult")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == LOCATION_REQUEST) {
            val result = pendingLocation ?: return
            pendingLocation = null
            result.success(if (resultCode == Activity.RESULT_OK || isLocationOn()) "on" else "declined")
        }
    }

    private fun isLocationOn(): Boolean {
        val lm = getSystemService(LOCATION_SERVICE) as LocationManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            lm.isLocationEnabled
        } else {
            lm.isProviderEnabled(LocationManager.GPS_PROVIDER) || lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        linkFrom(intent)?.let { channel?.invokeMethod("link", it) }
    }

    private companion object {
        const val LOCATION_REQUEST = 7301
    }

    private fun canInstallApks(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.O || packageManager.canRequestPackageInstalls()

    private fun linkFrom(intent: Intent?): String? =
        if (intent?.action == Intent.ACTION_VIEW) intent.dataString else null
}
