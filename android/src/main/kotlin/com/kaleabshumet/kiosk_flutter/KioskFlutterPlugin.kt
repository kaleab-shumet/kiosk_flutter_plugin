package com.kaleabshumet.kiosk_flutter

import android.app.Activity
import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.kaleabshumet.kioskmode_native.DummyNative
import com.kaleabshumet.kioskmode_native.KioskManager
import com.kaleabshumet.kioskmode_native.PermissionType

/** KioskFlutterPlugin */
class KioskFlutterPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel : MethodChannel
  private lateinit var applicationContext: Context
  private var activity: Activity? = null
  private lateinit var kioskManager: KioskManager

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "kiosk_flutter")
    channel.setMethodCallHandler(this)
    applicationContext = flutterPluginBinding.applicationContext
    kioskManager = KioskManager(applicationContext)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
        "getPlatformVersion" -> {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        }
        "getDummyMessage" -> {
            try {
                val message = DummyNative.getDummyMessage()
                result.success(message)
            } catch (e: Exception) {
                result.error("DummyError", "Failed to get dummy message", e.toString())
            }
        }
       
                "getMissingPermissions" -> {
            try {
                val missingPermissions = kioskManager.getMissingPermissions()
                val permissionsList = missingPermissions.map {
                    mapOf("label" to it.label, "type" to it.type.name)
                }
                result.success(permissionsList)
            } catch (e: Exception) {
                result.error("GetMissingPermissionsError", "Failed to get missing permissions", e.toString())
            }
        }
        "isKioskModeActive" -> {
            result.success(kioskManager.isKioskModeActive())
        }
        "startKioskMode" -> {
            val currentActivity = activity
            if (currentActivity == null) {
                result.error("ActivityError", "Activity not available to start kiosk mode.", null)
                return
            }
            kioskManager.activateKioskMode(currentActivity)
            result.success(null) 
        }
        "stopKioskMode" -> {
            val currentActivity = activity
            if (currentActivity == null) {
                result.error("ActivityError", "Activity not available to stop kiosk mode.", null)
                return
            }
            // attemptDeactivateKioskMode shows a dialog and has callbacks.
            // For simplicity, we'll make this call synchronous from Flutter's perspective
            // and rely on the user interaction with the PIN dialog.
            // A more robust solution might involve passing results back asynchronously.
            kioskManager.attemptDeactivateKioskMode(currentActivity,
                onDeactivated = {
                    // Optionally, could send an event back to Flutter if needed
                    // For now, the Dart side will re-check status after calling this.
                },
                onCancelled = {
                    // Optionally, could send an event back to Flutter
                }
            )
            result.success(null) // Indicate the call was received, actual deactivation depends on PIN
        }
        "openPermissionSettings" -> {
            val currentActivity = activity
            if (currentActivity == null) {
                result.error("ActivityError", "Activity not available to open settings.", null)
                return
            }
            try {
                val permissionTypeString = call.argument<String>("permissionType")
                if (permissionTypeString != null) {
                    val permissionType = PermissionType.valueOf(permissionTypeString.uppercase()) // Use uppercase for enum matching
                    kioskManager.openPermissionScreen(currentActivity, permissionType)
                    result.success(null)
                } else {
                    result.error("ArgsError", "permissionType argument is missing", null)
                }
            } catch (e: IllegalArgumentException) {
                result.error("ArgsError", "Invalid permissionType string: ${call.argument<String>("permissionType")}", e.toString())
            } catch (e: Exception) {
                result.error("SettingsError", "Failed to open permission settings", e.toString())
            }
        }
        "isSetAsDefaultLauncher" -> {
            try {
                result.success(kioskManager.isSetAsDefaultLauncher())
            } catch (e: Exception) {
                result.error("IsDefaultLauncherError", "Failed to check default launcher status", e.toString())
            }
        }
        "openSettings" -> {
            val settingString = call.argument<String>("setting")
            if (settingString == null) {
                result.error("ArgsError", "'setting' argument is missing or not a string", null)
                return
            }
            val currentActivity = activity
            if (currentActivity == null) {
                result.error("ActivityError", "Activity not available to open settings.", null)
                return
            }
            try {
                kioskManager.openSettings(currentActivity, settingString)
                result.success(null)
            } catch (e: Exception) {
                result.error("OpenSettingsError", "Failed to open settings: $settingString", e.toString())
            }
        }
        else -> {
            result.notImplemented()
        }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  // --- ActivityAware methods --- 
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }
}
