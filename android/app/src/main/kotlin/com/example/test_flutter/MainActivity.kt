package com.example.test_flutter

import android.content.Context
import android.content.Intent
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

class MainActivity : FlutterActivity() {
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
                    val list = getAndClearUnprocessedNotifications()
                    result.success(list)
                }
                "clearNotificationQueue" -> {
                    clearQueue()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Forward notifications in real-time when activity is running
        MyFinanceNotificationListener.activeListener = { dataMap ->
            runOnUiThread {
                methodChannel?.invokeMethod("onNotificationReceived", dataMap)
            }
        }
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

    private fun getAndClearUnprocessedNotifications(): List<Map<String, Any>> {
        val prefs = getSharedPreferences(
            MyFinanceNotificationListener.PREFS_NAME,
            Context.MODE_PRIVATE
        )
        val json = prefs.getString(MyFinanceNotificationListener.KEY_QUEUE, "[]") ?: "[]"
        val resultList = mutableListOf<Map<String, Any>>()

        try {
            val array = JSONArray(json)
            for (i in 0 until array.length()) {
                val obj = array.optJSONObject(i) ?: continue
                val map = mutableMapOf<String, Any>()
                map["packageName"] = obj.optString("packageName")
                map["title"] = obj.optString("title")
                map["text"] = obj.optString("text")
                map["timestamp"] = obj.optLong("timestamp")
                resultList.add(map)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // Clear queue after retrieval
        prefs.edit().remove(MyFinanceNotificationListener.KEY_QUEUE).apply()
        return resultList
    }

    private fun clearQueue() {
        val prefs = getSharedPreferences(
            MyFinanceNotificationListener.PREFS_NAME,
            Context.MODE_PRIVATE
        )
        prefs.edit().remove(MyFinanceNotificationListener.KEY_QUEUE).apply()
    }
}
