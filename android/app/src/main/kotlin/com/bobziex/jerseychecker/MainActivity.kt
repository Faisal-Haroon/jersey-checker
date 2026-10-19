package com.bobziex.jerseychecker

import android.media.MediaScannerConnection
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.bobziex.jerseychecker/media_scanner"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "scanFile") {
                val filePath = call.argument<String>("path")
                if (filePath != null) {
                    MediaScannerConnection.scanFile(
                        applicationContext,
                        arrayOf(filePath),
                        null
                    ) { _, _ -> }
                    result.success(true)
                } else {
                    result.error("INVALID_PATH", "Path was null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
