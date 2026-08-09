package com.example.spresearchvia

import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable edge-to-edge BEFORE super.onCreate() for Android 15 (API 35) and above
        if (Build.VERSION.SDK_INT >= 35) {
            // This must be called before super.onCreate()
            WindowCompat.setDecorFitsSystemWindows(window, false)
        }

        super.onCreate(savedInstanceState)
    }
}
