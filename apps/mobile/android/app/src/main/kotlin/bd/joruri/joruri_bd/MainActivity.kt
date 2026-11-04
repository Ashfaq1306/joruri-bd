package bd.joruri.joruri_bd

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Two small native helpers for the Flutter side (channel "joruri/native"):
 *  - installApk: opens Android's installer for an update the app downloaded
 *    (apps outside Google Play cannot install silently; the person taps Update).
 *  - sign-in links: an e-mail sign-in link (https://joruri-bd.firebaseapp.com/__/auth/...)
 *    opens this activity; the link is handed to Flutter to finish signing in.
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var initialLink: String? = null

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

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        linkFrom(intent)?.let { channel?.invokeMethod("link", it) }
    }

    private fun canInstallApks(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.O || packageManager.canRequestPackageInstalls()

    private fun linkFrom(intent: Intent?): String? =
        if (intent?.action == Intent.ACTION_VIEW) intent.dataString else null
}
