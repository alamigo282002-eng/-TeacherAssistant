package com.example.helper

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * ودجت سطح المكتب والشاشة الرئيسية لنظام أندرويد لتطبيق مساعد المعلم
 */
class TeacherAppWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private const val PREFS_NAME = "FlutterSharedPreferences"

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, TeacherAppWidgetProvider::class.java)
            val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            for (id in allWidgetIds) {
                updateAppWidget(context, appWidgetManager, id)
            }
        }

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            // Read preferences written by Flutter
            val teacherName = prefs.getString("flutter.teacher_name", "المعلم") ?: "المعلم"
            val nextGroupName = prefs.getString("flutter.widget_next_group", "لا توجد حصص حالياً") ?: "لا توجد حصص حالياً"
            val nextGroupTime = prefs.getString("flutter.widget_next_time", "جاهز للتحضير") ?: "جاهز للتحضير"
            val todaysCount = prefs.getString("flutter.widget_today_count", "0") ?: "0"

            val views = RemoteViews(context.packageName, R.layout.widget_teacher_assistant)

            views.setTextViewText(R.id.widget_title, "أ. $teacherName 📚")
            
            // Format current date in Arabic
            val sdf = SimpleDateFormat("EEEE، d MMMM", Locale("ar"))
            val todayDate = sdf.format(Date())
            views.setTextViewText(R.id.widget_date, todayDate)

            views.setTextViewText(R.id.widget_group_name, nextGroupName)
            views.setTextViewText(R.id.widget_time_details, nextGroupTime)
            views.setTextViewText(R.id.widget_stats_text, "مجموعات اليوم: $todaysCount")

            // Intent to open Flutter app on widget click
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            views.setOnClickPendingIntent(R.id.widget_btn_open, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
