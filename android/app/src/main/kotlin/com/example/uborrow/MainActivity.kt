package com.example.uborrow

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onResume() {
        super.onResume()
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)

            // Main notification channel for UBorrow
            val uborrow = NotificationChannel(
                "uborrow_notifications",
                "UBorrow Notifications",
                NotificationManager.IMPORTANCE_HIGH
            )
            uborrow.description = "Notifications for UBorrow app"
            uborrow.enableVibration(true)
            uborrow.enableLights(true)
            notificationManager?.createNotificationChannel(uborrow)

            // Request notifications channel
            val requestChannel = NotificationChannel(
                "uborrow_requests",
                "Borrow Requests",
                NotificationManager.IMPORTANCE_HIGH
            )
            requestChannel.description = "Notifications for borrow and need requests"
            requestChannel.enableVibration(true)
            notificationManager?.createNotificationChannel(requestChannel)

            // Chat messages channel
            val messageChannel = NotificationChannel(
                "uborrow_messages",
                "Messages",
                NotificationManager.IMPORTANCE_HIGH
            )
            messageChannel.description = "Notifications for new messages"
            messageChannel.enableVibration(true)
            notificationManager?.createNotificationChannel(messageChannel)
        }
    }
}
