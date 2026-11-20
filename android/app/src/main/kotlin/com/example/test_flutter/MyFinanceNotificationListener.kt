package com.example.test_flutter

import android.app.Notification
import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

class MyFinanceNotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "MyFinance"
        const val PREFS_NAME = "MyFinanceNotificationPrefs"
        const val KEY_QUEUE = "raw_notifications_queue"

        // Shared lock between NotificationListenerService and MainActivity
        private val queueLock = Any()

        // Static callback to communicate directly with MainActivity if active
        var activeListener: ((Map<String, Any>) -> Unit)? = null

        // Supported target packages for banks and e-wallets
        val TARGET_PACKAGES = setOf(
            "com.bca",
            "com.bca.mybca",
            "mybca.bca.co.id",
            "id.bmri.livin",
            "com.bri.bmo",
            "id.co.bni.newmbanking",
            "com.jago.digitalBanking",
            "id.dana",
            "com.gojek.app",
            "com.gopay.wallet",
            "ovo.id",
            "com.shopee.id"
        )

        fun enqueueNotification(context: Context, item: Map<String, Any>) {
            synchronized(queueLock) {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val existingJson = prefs.getString(KEY_QUEUE, "[]") ?: "[]"
                val array = try {
                    JSONArray(existingJson)
                } catch (e: Exception) {
                    JSONArray()
                }

                val itemPkg = item["packageName"] as? String ?: ""
                val itemTitle = item["title"] as? String ?: ""
                val itemText = item["text"] as? String ?: ""
                val itemTime = (item["timestamp"] as? Number)?.toLong() ?: 0L

                for (i in 0 until array.length()) {
                    val obj = array.optJSONObject(i) ?: continue
                    if (obj.optString("packageName") == itemPkg &&
                        obj.optString("title") == itemTitle &&
                        obj.optString("text") == itemText &&
                        Math.abs(obj.optLong("timestamp") - itemTime) < 5000
                    ) {
                        // Duplicate notification within 5 seconds, ignore
                        return
                    }
                }

                val newObj = JSONObject().apply {
                    put("packageName", itemPkg)
                    put("title", itemTitle)
                    put("text", itemText)
                    put("timestamp", itemTime)
                }

                array.put(newObj)
                prefs.edit().putString(KEY_QUEUE, array.toString()).apply()
                Log.d(TAG, "enqueueNotification: saved pkg=$itemPkg queueSize=${array.length()}")
            }
        }

        fun drainQueue(context: Context): List<Map<String, Any>> {
            synchronized(queueLock) {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val json = prefs.getString(KEY_QUEUE, "[]") ?: "[]"
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

                prefs.edit().remove(KEY_QUEUE).apply()
                Log.d(TAG, "drainQueue: drained ${resultList.size} notifications")
                return resultList
            }
        }

        fun acknowledgeNotification(
            context: Context,
            packageName: String,
            title: String,
            text: String,
            timestamp: Long
        ) {
            synchronized(queueLock) {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val json = prefs.getString(KEY_QUEUE, "[]") ?: "[]"
                val array = try {
                    JSONArray(json)
                } catch (e: Exception) {
                    return
                }

                val remaining = JSONArray()
                var removed = false
                for (i in 0 until array.length()) {
                    val obj = array.optJSONObject(i) ?: continue
                    if (!removed &&
                        obj.optString("packageName") == packageName &&
                        obj.optString("title") == title &&
                        obj.optString("text") == text &&
                        obj.optLong("timestamp") == timestamp
                    ) {
                        removed = true
                        continue
                    }
                    remaining.put(obj)
                }

                if (removed) {
                    if (remaining.length() == 0) {
                        prefs.edit().remove(KEY_QUEUE).apply()
                    } else {
                        prefs.edit().putString(KEY_QUEUE, remaining.toString()).apply()
                    }
                }
            }
        }

        fun clearQueue(context: Context) {
            synchronized(queueLock) {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                prefs.edit().remove(KEY_QUEUE).apply()
            }
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "onListenerConnected: NotificationListenerService bound to system")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.w(TAG, "onListenerDisconnected: NotificationListenerService unbound from system")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return

        try {
            val packageName = sbn.packageName ?: return
            val notification = sbn.notification ?: return
            val extras = notification.extras ?: return

            val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
            val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
            val normalText = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
            val textLines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
                ?.joinToString(" ") { it.toString() }
            val text = bigText ?: normalText ?: textLines ?: ""

            Log.d(TAG, "onNotificationPosted: pkg=$packageName title='$title' text='$text'")

            if (title.isBlank() && text.isBlank()) {
                Log.d(TAG, "onNotificationPosted: skipped blank title & text for pkg=$packageName")
                return
            }

            val isTargetApp = TARGET_PACKAGES.contains(packageName)
            val combined = (title + " " + text).lowercase()

            // Filter: Target app or content having currency/financial signals
            val hasFinancialSignal = combined.contains("rp") ||
                    combined.contains("idr") ||
                    combined.contains("transfer") ||
                    combined.contains("pembayaran") ||
                    combined.contains("qris") ||
                    combined.contains("top up") ||
                    combined.contains("saldo") ||
                    combined.contains("masuk") ||
                    combined.contains("keluar") ||
                    combined.contains("debit") ||
                    combined.contains("credit")

            if (!isTargetApp && !hasFinancialSignal) {
                Log.d(TAG, "onNotificationPosted: filtered out pkg=$packageName (not target & no financial signal)")
                return
            }

            val timestamp = sbn.postTime

            val dataMap = mapOf(
                "packageName" to packageName,
                "title" to title,
                "text" to text,
                "timestamp" to timestamp
            )

            // Save to persistent SharedPreferences queue so it is NEVER lost even if app is closed
            enqueueNotification(this, dataMap)

            // If Flutter is active in foreground, also dispatch in real-time
            val listener = activeListener
            if (listener != null) {
                Log.d(TAG, "onNotificationPosted: dispatching real-time via activeListener pkg=$packageName")
                listener.invoke(dataMap)
            } else {
                Log.d(TAG, "onNotificationPosted: activeListener is null (app background/closed), queued only")
            }
        } catch (e: Exception) {
            Log.e(TAG, "onNotificationPosted: error", e)
        }
    }
}
