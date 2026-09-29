package com.example.test_flutter

import android.app.Notification
import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONArray
import org.json.JSONObject

class MyFinanceNotificationListener : NotificationListenerService() {

    companion object {
        const val PREFS_NAME = "MyFinanceNotificationPrefs"
        const val KEY_QUEUE = "raw_notifications_queue"

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
            "id.dana",
            "com.gojek.app",
            "com.gopay.wallet",
            "ovo.id",
            "com.shopee.id"
        )
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return

        try {
            val packageName = sbn.packageName ?: return
            val notification = sbn.notification ?: return
            val extras = notification.extras ?: return

            val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
            val text = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
                ?: extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
                ?: ""

            if (title.isBlank() && text.isBlank()) return

            val isTargetApp = TARGET_PACKAGES.contains(packageName)
            val combined = (title + " " + text).lowercase()

            // Filter: Target app or content having currency/financial signals
            val hasFinancialSignal = combined.contains("rp") ||
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
            saveToQueue(dataMap)

            // If Flutter is active, also dispatch in real-time
            activeListener?.invoke(dataMap)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun saveToQueue(item: Map<String, Any>) {
        synchronized(this) {
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val existingJson = prefs.getString(KEY_QUEUE, "[]") ?: "[]"
            val array = try {
                JSONArray(existingJson)
            } catch (e: Exception) {
                JSONArray()
            }

            // Deduplicate in raw queue by checking last 50 items
            val itemPkg = item["packageName"] as? String ?: ""
            val itemTitle = item["title"] as? String ?: ""
            val itemText = item["text"] as? String ?: ""
            val itemTime = item["timestamp"] as? Long ?: 0L

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
        }
    }
}
