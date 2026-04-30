package com.usamar.quranmushafapp.quranline

import android.content.Context
import android.graphics.Paint
import android.graphics.Typeface
import android.os.Build
import android.text.Layout
import android.text.StaticLayout
import android.text.TextDirectionHeuristics
import android.text.TextPaint
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod

// Async natural-width measurement for one line of Arabic text. Used by
// the JS-side useMushafPageScale hook to compute a single page-wide
// fontSize scale before any line is rendered, so all cells render at
// uniform fontSize (instead of each line shrinking independently and
// producing the ragged look the user observed).
class QuranLineMeasureModule(reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext) {

  override fun getName(): String = MODULE_NAME

  @ReactMethod
  fun measure(text: String, fontSizeSp: Double, fontFamily: String, promise: Promise) {
    try {
      val ctx: Context = reactApplicationContext
      val density = ctx.resources.displayMetrics.density
      val paint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
        textSize = fontSizeSp.toFloat() * density
        typeface = typefaceFor(ctx, fontFamily)
      }
      val widthPx = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        StaticLayout.Builder.obtain(text, 0, text.length, paint, Int.MAX_VALUE)
          .setAlignment(Layout.Alignment.ALIGN_NORMAL)
          .setIncludePad(false)
          .setLineSpacing(0f, 1f)
          .setTextDirection(TextDirectionHeuristics.RTL)
          .build()
          .getLineWidth(0)
      } else {
        Layout.getDesiredWidth(text, paint)
      }
      // Return in dp (logical pixels) so JS can compare against container
      // widths it sees in onLayout, which are also in dp.
      promise.resolve((widthPx / density).toDouble())
    } catch (e: Exception) {
      promise.reject("MEASURE_ERROR", e)
    }
  }

  private fun typefaceFor(ctx: Context, key: String): Typeface {
    val asset = when (key) {
      "IndopakNastaleeq", "IndopakNastaleeqExt" -> "IndopakNastaleeqExt"
      else -> key
    }
    cache[asset]?.let { return it }
    val tf = try {
      Typeface.createFromAsset(ctx.assets, "fonts/$asset.ttf")
    } catch (_: RuntimeException) {
      Typeface.DEFAULT
    }
    cache[asset] = tf
    return tf
  }

  companion object {
    const val MODULE_NAME = "QuranLineMeasure"
    private val cache = mutableMapOf<String, Typeface>()
  }
}
