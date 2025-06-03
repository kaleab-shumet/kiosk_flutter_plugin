// KioskManager.kt
package com.kaleabshumet.kioskmode_native // Or your preferred package

import android.app.Activity
import android.app.AlertDialog
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import android.app.AppOpsManager
import android.os.Build
import android.view.LayoutInflater // Required for inflating dialog layout
import android.view.View
import android.widget.Button
import android.widget.EditText
import com.example.kiosk_flutter.R // Assuming R file is accessible, adjust if needed

// Data classes and enums can be top-level or nested if preferred
data class PermissionItem(val label: String, val type: PermissionType)
enum class PermissionType { OVERLAY, HOME, USAGE_STATS }

class KioskManager(private val context: Context) {

    private val prefs: SharedPreferences = context.getSharedPreferences("kiosk_prefs", Context.MODE_PRIVATE)
    private var currentKioskMode: Boolean = false // Internal state

    companion object {
        const val ACTIVATE_KIOSK_EXTRA = "ACTIVATE_KIOSK"
        private const val PREF_KIOSK_MODE = "kiosk_mode_active"
        private const val PREF_KIOSK_BUTTON_ENABLED = "kiosk_button_enabled_state" // Renamed for clarity
        private const val PREF_KIOSK_BUTTON_TEXT = "kiosk_button_text_state"     // Renamed for clarity
        private const val DEFAULT_PIN = "7272" // Keep PIN configurable if needed
    }

    init {
        currentKioskMode = prefs.getBoolean(PREF_KIOSK_MODE, false)
    }

    fun initializeKioskModeFromIntent(intent: Intent?) {
        if (intent?.getBooleanExtra(ACTIVATE_KIOSK_EXTRA, false) == true && !isKioskModeActive()) {
            activateKioskModeInternal() // Silently activate if intent requests
        }
    }

    fun isKioskModeActive(): Boolean {
        // Always read the latest value from SharedPreferences to ensure consistency across instances
        return prefs.getBoolean(PREF_KIOSK_MODE, false)
    }

    // --- Permission Management ---
    fun getMissingPermissions(): List<PermissionItem> {
        val list = mutableListOf<PermissionItem>()
        if (!Settings.canDrawOverlays(context)) {
            list.add(PermissionItem("Draw over other apps", PermissionType.OVERLAY))
        }
        if (!isSetAsDefaultLauncher()) {
            list.add(PermissionItem("Set as Default Launcher", PermissionType.HOME))
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP && !hasUsageStatsPermission()) {
            list.add(PermissionItem("Usage Access", PermissionType.USAGE_STATS))
        }
        return list
    }

    private fun hasUsageStatsPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            return true // Not applicable before Lollipop
        }
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager ?: return false
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            context.packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    fun isSetAsDefaultLauncher(): Boolean {
        val pm = context.packageManager
        val intent = Intent(Intent.ACTION_MAIN).apply { addCategory(Intent.CATEGORY_HOME) }
        val resolveInfo = pm.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
        return resolveInfo?.activityInfo?.packageName == context.packageName
    }

    fun openSettings(activity: Activity, settingAction: String) {
        try {
            val intent = Intent(settingAction)
            if (intent.resolveActivity(activity.packageManager) != null) {
                activity.startActivity(intent)
            } else {
                // Fallback or error logging if the setting action is not recognized
                android.util.Log.w("KioskManager", "No activity found to handle setting: $settingAction")
                // Optionally, try a more generic settings screen
                // activity.startActivity(Intent(Settings.ACTION_SETTINGS))
            }
        } catch (e: Exception) {
            android.util.Log.e("KioskManager", "Error opening settings: $settingAction", e)
            // Rethrow or handle as appropriate for your plugin's error strategy
            throw e 
        }
    }

    fun openPermissionScreen(activity: Activity, type: PermissionType) {
        val intent = when (type) {
            PermissionType.OVERLAY -> Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:${context.packageName}"))
            PermissionType.HOME -> Intent(Settings.ACTION_HOME_SETTINGS)
            PermissionType.USAGE_STATS -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS) else null
        }
        intent?.let { activity.startActivity(it) }
    }

    // --- Kiosk Mode Activation/Deactivation ---
    fun activateKioskMode(activity: Activity) {
        activateKioskModeInternal()
        applyKioskUIChanges(activity)
    }

    private fun activateKioskModeInternal() {
        currentKioskMode = true
        prefs.edit().putBoolean(PREF_KIOSK_MODE, currentKioskMode).apply()
        // If you had a target app package, you'd set it here
        // prefs.edit().putString("kiosk_target_app_package", "com.example.targetapp").apply()
    }

    fun attemptDeactivateKioskMode(activity: Activity, onDeactivated: () -> Unit, onCancelled: () -> Unit) {
        showPinDialog(activity) { success ->
            if (success) {
                deactivateKioskModeInternal(activity) // Pass activity
                clearKioskUIChanges(activity)
                onDeactivated()
            } else {
                onCancelled()
            }
        }
    }

    fun deactivateKioskModeInternal(activity: Activity) { // Add activity parameter, make public
        currentKioskMode = false
        prefs.edit().putBoolean(PREF_KIOSK_MODE, currentKioskMode).apply()
        // prefs.edit().remove("kiosk_target_app_package").apply() // Clear target if set

        // Attempt to clear this app as the default launcher
        try {
            activity.packageManager.clearPackagePreferredActivities(activity.packageName)
        } catch (e: Exception) {
            // Log or handle exception if necessary, e.g., security exception if not allowed
            android.util.Log.e("KioskManager", "Failed to clear preferred activities", e)
        }
    }

    // --- UI Management for Kiosk Mode ---
    fun applyKioskUIChanges(activity: Activity) {
        if (isKioskModeActive()) {
            activity.window.decorView.systemUiVisibility = (
                    View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                            or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                            or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                            or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                            or View.SYSTEM_UI_FLAG_FULLSCREEN
                            or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                    )
        }
    }

    fun clearKioskUIChanges(activity: Activity) {
        activity.window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_LAYOUT_STABLE
    }

    // --- PIN Dialog ---
    fun showPinDialog(activity: Activity, onResult: (Boolean) -> Unit) {
        val dialogView = LayoutInflater.from(activity).inflate(R.layout.dialog_pin, null)
        val pinEditText = dialogView.findViewById<EditText>(R.id.pinEditText)
        val okButton = dialogView.findViewById<Button>(R.id.okButton)
        val cancelButton = dialogView.findViewById<Button>(R.id.cancelButton)

        val dialog = AlertDialog.Builder(activity)
            .setView(dialogView)
            .setCancelable(false)
            .create()

        okButton.setOnClickListener {
            val pin = pinEditText.text.toString()
            if (pin == DEFAULT_PIN) { // Use the constant
                dialog.dismiss()
                onResult(true)
            } else {
                pinEditText.error = "Incorrect PIN"
            }
        }
        cancelButton.setOnClickListener {
            dialog.dismiss()
            onResult(false)
        }
        dialog.show()
    }

    // --- Activity Lifecycle Event Handlers ---
    /**
     * Call this from Activity's onBackPressed.
     * @return true if the back press was handled by kiosk mode (i.e., blocked), false otherwise.
     */
    fun handleOnBackPressed(): Boolean {
        return isKioskModeActive() // If kiosk mode is active, consume the back press
    }

    /**
     * Call this from Activity's onUserLeaveHint.
     * This brings the kiosk activity back to the front if the user tries to leave.
     */
    fun handleOnUserLeaveHint(activity: Activity, kioskActivityClass: Class<out Activity>) {
        if (isKioskModeActive()) {
            val intent = Intent(activity, kioskActivityClass)
            intent.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            activity.startActivity(intent)
        }
    }

    // --- Persisting UI State (Optional, but good for consistency) ---
    fun saveButtonState(enabled: Boolean, text: String) {
        prefs.edit()
            .putBoolean(PREF_KIOSK_BUTTON_ENABLED, enabled)
            .putString(PREF_KIOSK_BUTTON_TEXT, text)
            .apply()
    }

    fun getSavedButtonEnabledState(default: Boolean = false): Boolean {
        return prefs.getBoolean(PREF_KIOSK_BUTTON_ENABLED, default)
    }

    fun getSavedButtonTextState(default: String = "Activate Kiosk Mode"): String {
        return prefs.getString(PREF_KIOSK_BUTTON_TEXT, default) ?: default
    }
}