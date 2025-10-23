package com.pes.frontend

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val GOOGLE_MAPS_CHANNEL = "com.pes.frontend/google_maps"
    private var googleMapsApiKey: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GOOGLE_MAPS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setGoogleMapsApiKey" -> {
                        val apiKey = call.argument<String>("apiKey")
                        if (apiKey != null) {
                            googleMapsApiKey = apiKey
                            result.success("Google Maps API Key set successfully")
                        } else {
                            result.error("INVALID_ARGUMENT", "API Key is required", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
