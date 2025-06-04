package com.example.kiosk_flutter_example

import io.flutter.embedding.android.FlutterActivity
import com.kaleabshumet.kioskmode_native.KioskManager // Import KioskManager

class MainActivity : FlutterActivity() {
    private var backPressCount = 0
    private var lastBackPressTime: Long = 0
    private val BACK_PRESS_INTERVAL_MS = 2000 // 2 seconds
    private val REQUIRED_BACK_PRESSES = 5

    private lateinit var kioskManager: KioskManager

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // It's good practice to initialize KioskManager once the context is reliably available.
        // Application context can be used if activity context is not strictly needed for initialization.
        kioskManager = KioskManager(applicationContext)
    }

    override fun onBackPressed() {
        // Ensure kioskManager is initialized
        if (!this::kioskManager.isInitialized) {
            kioskManager = KioskManager(applicationContext)
        }

        if (kioskManager.isKioskModeActive()) {
            val currentTime = System.currentTimeMillis()
            if ((currentTime - lastBackPressTime) > BACK_PRESS_INTERVAL_MS) {
                backPressCount = 1 // Reset count if presses are too far apart
            } else {
                backPressCount++
            }
            lastBackPressTime = currentTime

            if (backPressCount >= REQUIRED_BACK_PRESSES) {
                backPressCount = 0 // Reset count after triggering
                kioskManager.showPinDialog(this) { success ->
                    if (success) {
                        kioskManager.deactivateKioskModeInternal(this)
                        kioskManager.clearKioskUIChanges(this)
                        // Flutter UI should update on next onResume or via a specific callback if needed
                    }
                }
                // Whether PIN dialog was shown or not (if sequence met), consume the back press.
                // The PIN dialog interaction is async.
            }
            // If kiosk mode is active (regardless of 5-tap sequence stage, unless PIN shown and handled),
            // consume the back press.
            return
        } else {
            // Kiosk mode is not active
            backPressCount = 0 // Reset count for next time
            super.onBackPressed() // Allow default back press behavior
        }
    }

    override fun onUserLeaveHint() {
        // Ensure kioskManager is initialized
        if (!this::kioskManager.isInitialized) {
            kioskManager = KioskManager(applicationContext)
        }

        kioskManager.handleOnUserLeaveHint(this, MainActivity::class.java)
        super.onUserLeaveHint()
    }
}
