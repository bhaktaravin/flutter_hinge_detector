package com.example.flutter_hinge_detector

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import androidx.window.layout.WindowInfoTracker
import androidx.window.layout.FoldingFeature
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.flow.collect
import kotlin.math.acos
import kotlin.math.sqrt

class MainActivity : FlutterActivity(), SensorEventListener {
    private val CHANNEL = "hinge_detector"
    private lateinit var sensorManager: SensorManager
    private var hingeAngleSensor: Sensor? = null
    private var currentHingeAngle: Float = 0.0f
    private lateinit var windowInfoTracker: WindowInfoTracker

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getHingeAngle" -> {
                    result.success(getHingeAngle())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        setupHingeDetection()
    }

    private fun setupHingeDetection() {
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        
        // Try to get the hinge angle sensor (available on some foldable devices)
        hingeAngleSensor = sensorManager.getDefaultSensor(Sensor.TYPE_HINGE_ANGLE)
        
        if (hingeAngleSensor != null) {
            sensorManager.registerListener(this, hingeAngleSensor, SensorManager.SENSOR_DELAY_NORMAL)
        }

        // Also try WindowManager API for foldable devices
        try {
            windowInfoTracker = WindowInfoTracker.getOrCreate(this)
            lifecycleScope.launchWhenStarted {
                windowInfoTracker.windowLayoutInfo(this@MainActivity).collect { layoutInfo ->
                    val foldingFeature = layoutInfo.displayFeatures
                        .filterIsInstance<FoldingFeature>()
                        .firstOrNull()
                    
                    if (foldingFeature != null) {
                        val angle = when (foldingFeature.state) {
                            FoldingFeature.State.FLAT -> 180.0f
                            FoldingFeature.State.HALF_OPENED -> 90.0f
                            else -> currentHingeAngle
                        }
                        currentHingeAngle = angle
                    }
                }
            }
        } catch (e: Exception) {
            // WindowManager API not available
        }
    }

    private fun getHingeAngle(): Float {
        return currentHingeAngle
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type == Sensor.TYPE_HINGE_ANGLE) {
            currentHingeAngle = event.values[0]
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // Not used
    }

    override fun onDestroy() {
        super.onDestroy()
        if (hingeAngleSensor != null) {
            sensorManager.unregisterListener(this)
        }
    }
}
