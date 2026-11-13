package com.example.kidsphonics

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build

class MainActivity : FlutterActivity() {
    private var playerWelcome: PlayerWelcomeSpeech? = null
    private var activityForeground = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        playerWelcome?.dispose()
        playerWelcome = PlayerWelcomeSpeech(this, flutterEngine.dartExecutor.binaryMessenger)
        playerWelcome?.setForeground(activityForeground)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kidsphonics/app_info")
            .setMethodCallHandler { call, result ->
                if (call.method != "getInfo") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    @Suppress("DEPRECATION")
                    val info = packageManager.getPackageInfo(packageName, 0)
                    @Suppress("DEPRECATION")
                    val build = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        info.longVersionCode.toString()
                    } else {
                        info.versionCode.toString()
                    }
                    result.success(mapOf("version" to info.versionName, "build" to build))
                } catch (error: Exception) {
                    result.error("APP_INFO_UNAVAILABLE", "Could not read app version", null)
                }
            }
    }

    override fun onResume() {
        super.onResume()
        activityForeground = true
        playerWelcome?.setForeground(true)
    }

    override fun onPause() {
        activityForeground = false
        playerWelcome?.setForeground(false)
        super.onPause()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        playerWelcome?.dispose()
        playerWelcome = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
