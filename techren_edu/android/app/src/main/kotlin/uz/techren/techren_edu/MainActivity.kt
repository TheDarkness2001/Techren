package uz.techren.techren_edu

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageInstaller
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * In-app APK update (Telegram-style):
 * download stays inside the app → PackageInstaller shows the system
 * "Update" confirmation → Android replaces the package and relaunches.
 * One Install tap is required by Android (cannot fully silent-update when sideloaded).
 */
class MainActivity : FlutterActivity() {
    private val channelName = "uz.techren.techren_edu/updater"
    private val installAction = "uz.techren.techren_edu.INSTALL_STATUS"

    private var installReceiver: BroadcastReceiver? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "installApk" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrBlank()) {
                            result.error("bad_args", "Missing path", null)
                            return@setMethodCallHandler
                        }
                        try {
                            pendingResult = result
                            installApk(File(path))
                            // Result is completed from the install status receiver / fallback path.
                        } catch (e: Exception) {
                            pendingResult = null
                            result.error("install_failed", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        unregisterInstallReceiver()
        super.onDestroy()
    }

    private fun installApk(file: File) {
        if (!file.exists() || file.length() < 1024) {
            throw IllegalStateException("APK not found or incomplete: ${file.absolutePath}")
        }

        // Android 8+: user must allow installs from this app once (Settings).
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !packageManager.canRequestPackageInstalls()
        ) {
            startActivity(
                Intent(
                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:$packageName"),
                ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
            throw IllegalStateException(
                "Allow installs from TechRen EDU, then tap Update again.",
            )
        }

        try {
            installWithPackageInstaller(file)
        } catch (e: Exception) {
            // Older / restricted devices — still in-app via system package UI.
            installWithActionView(file)
            pendingResult?.success(true)
            pendingResult = null
        }
    }

    private fun installWithPackageInstaller(file: File) {
        registerInstallReceiver()

        val installer = packageManager.packageInstaller
        val params = PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            params.setRequireUserAction(PackageInstaller.SessionParams.USER_ACTION_NOT_REQUIRED)
        }

        val sessionId = installer.createSession(params)
        installer.openSession(sessionId).use { session ->
            file.inputStream().use { input ->
                session.openWrite("techren-edu.apk", 0, file.length()).use { out ->
                    input.copyTo(out)
                    session.fsync(out)
                }
            }

            val callback = Intent(installAction).setPackage(packageName)
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_MUTABLE
                } else {
                    0
                }
            val pending = PendingIntent.getBroadcast(this, sessionId, callback, flags)
            session.commit(pending.intentSender)
        }
    }

    private fun installWithActionView(file: File) {
        val uri = FileProvider.getUriForFile(
            this,
            "$packageName.fileprovider",
            file,
        )
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun registerInstallReceiver() {
        unregisterInstallReceiver()
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                when (intent.getIntExtra(PackageInstaller.EXTRA_STATUS, PackageInstaller.STATUS_FAILURE)) {
                    PackageInstaller.STATUS_PENDING_USER_ACTION -> {
                        // System "Update / Install" confirmation — same as Telegram sideload.
                        val confirm = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            intent.getParcelableExtra(Intent.EXTRA_INTENT, Intent::class.java)
                        } else {
                            @Suppress("DEPRECATION")
                            intent.getParcelableExtra(Intent.EXTRA_INTENT)
                        }
                        if (confirm != null) {
                            confirm.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(confirm)
                        }
                        // Keep pendingResult until success/failure after user confirms.
                    }
                    PackageInstaller.STATUS_SUCCESS -> {
                        pendingResult?.success(true)
                        pendingResult = null
                        // New package is installed; relaunch so user lands in the new build.
                        val launch = packageManager.getLaunchIntentForPackage(packageName)
                        if (launch != null) {
                            launch.addFlags(
                                Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP,
                            )
                            startActivity(launch)
                        }
                        finishAffinity()
                    }
                    else -> {
                        val msg = intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE)
                            ?: "Install failed"
                        pendingResult?.error("install_failed", msg, null)
                        pendingResult = null
                    }
                }
            }
        }
        installReceiver = receiver
        val filter = IntentFilter(installAction)
        ContextCompat.registerReceiver(
            this,
            receiver,
            filter,
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
    }

    private fun unregisterInstallReceiver() {
        installReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (_: Exception) {
            }
        }
        installReceiver = null
    }
}
