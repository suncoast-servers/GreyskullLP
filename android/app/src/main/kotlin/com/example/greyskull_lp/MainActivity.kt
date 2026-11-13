package com.app.greyskull

import android.util.Log
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "greyskull/screen"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setAwake" -> {
                        val awake = call.argument<Boolean>("awake") ?: false
                        if (awake) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        }
                        val hasFlag = (window.attributes.flags and
                            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON) != 0
                        Log.d("GreyskullScreen", "setAwake=$awake keepScreenOn=$hasFlag")
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
