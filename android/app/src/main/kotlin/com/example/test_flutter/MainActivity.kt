package com.example.test_flutter

import android.content.ComponentName
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "MyFinance"
    }

    private val CHANNEL = "com.myfinance.app/notification_listener"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isNotificationAccessGranted" -> {
                    result.success(isNotificationAccessGranted())
                }
                "openNotificationAccessSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Cannot open notification settings: ${e.message}", null)
                    }
                }
                "getUnprocessedNotifications" -> {
                    val list = MyFinanceNotificationListener.drainQueue(this)
                    result.success(list)
                }
                "acknowledgeNotification" -> {
                    val pkg = call.argument<String>("packageName") ?: ""
                    val title = call.argument<String>("title") ?: ""
                    val text = call.argument<String>("text") ?: ""
                    val timestamp = call.argument<Number>("timestamp")?.toLong() ?: 0L
                    MyFinanceNotificationListener.acknowledgeNotification(
                        this,
                        pkg,
                        title,
                        text,
                        timestamp
                    )
                    result.success(true)
                }
                "clearNotificationQueue" -> {
                    MyFinanceNotificationListener.clearQueue(this)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        Log.d(TAG, "MainActivity.onResume: registering activeListener")
        // Forward notifications in real-time only when activity is in foreground
        MyFinanceNotificationListener.activeListener = { dataMap ->
            runOnUiThread {
                Log.d(TAG, "MainActivity: invoking onNotificationReceived for pkg=${dataMap["packageName"]}")
                methodChannel?.invokeMethod("onNotificationReceived", dataMap)
            }
        }
        requestNotificationListenerRebindIfGranted()
    }

    private fun requestNotificationListenerRebindIfGranted() {
        if (!isNotificationAccessGranted()) {
            Log.d(TAG, "requestRebind: skipped (notification access not granted)")
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                val componentName = ComponentName(this, MyFinanceNotificationListener::class.java)
                NotificationListenerService.requestRebind(componentName)
                Log.d(TAG, "requestRebind: requested for $componentName")
            } catch (e: Exception) {
                Log.e(TAG, "requestRebind: failed", e)
            }
        } else {
            Log.d(TAG, "requestRebind: skipped (SDK ${Build.VERSION.SDK_INT} < N)")
        }
    }

    override fun onPause() {
        Log.d(TAG, "MainActivity.onPause: clearing activeListener")
        MyFinanceNotificationListener.activeListener = null
        super.onPause()
    }

    override fun onDestroy() {
        MyFinanceNotificationListener.activeListener = null
        super.onDestroy()
    }

    private fun isNotificationAccessGranted(): Boolean {
        return try {
            val enabledListeners = NotificationManagerCompat.getEnabledListenerPackages(this)
            if (enabledListeners.contains(packageName)) {
                return true
            }

            val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
            flat != null && flat.contains(packageName)
        } catch (e: Exception) {
            false
        }
    }
}
