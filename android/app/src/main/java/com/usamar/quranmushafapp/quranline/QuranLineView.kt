package com.usamar.quranmushafapp.quranline

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.os.Build
import android.text.Layout
import android.text.StaticLayout
import android.text.TextDirectionHeuristics
import android.text.TextPaint
import android.view.View

class QuranLineView(context: Context) : View(context) {

  private val paint: TextPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
    textSize = 20f * resources.displayMetrics.density
    color = Color.BLACK
  }

  private var rawText: String = ""
  private var fontFamilyKey: String = DEFAULT_FAMILY
  private var baseTextSizePx: Float = paint.textSize
  private var minScale: Float = 0.7f
  private var maxWordSqueeze: Float = 0.3f
  private var letterTighten: Float = -0.03f
  private var safetyMarginPx: Float = 2f
  private var layout: StaticLayout? = null
  private var lastWidth: Int = 0

  fun setText(value: String) {
    if (value == rawText) return
    rawText = value
    rebuildLayout()
    invalidate()
  }

  fun setFontSize(spOrPx: Float) {
    val px = spOrPx * resources.displayMetrics.density
    if (px == baseTextSizePx) return
    baseTextSizePx = px
    paint.textSize = px
    rebuildLayout()
    invalidate()
  }

  fun setFontFamilyKey(key: String) {
    if (key == fontFamilyKey) return
    fontFamilyKey = key
    paint.typeface = typefaceFor(key)
    rebuildLayout()
    invalidate()
  }

  fun setColorInt(value: Int) {
    if (value == paint.color) return
    paint.color = value
    invalidate()
  }

  fun setMinScale(value: Float) {
    val clamped = value.coerceIn(0.3f, 1f)
    if (clamped == minScale) return
    minScale = clamped
    rebuildLayout()
    invalidate()
  }

  fun setMaxWordSqueeze(value: Float) {
    val clamped = value.coerceIn(0f, 1f)
    if (clamped == maxWordSqueeze) return
    maxWordSqueeze = clamped
    rebuildLayout()
    invalidate()
  }

  fun setLetterTighten(value: Float) {
    val clamped = value.coerceIn(-0.2f, 0f)
    if (clamped == letterTighten) return
    letterTighten = clamped
    rebuildLayout()
    invalidate()
  }

  fun setSafetyMarginPx(value: Float) {
    val clamped = value.coerceIn(0f, 20f)
    if (clamped == safetyMarginPx) return
    safetyMarginPx = clamped
    rebuildLayout()
    invalidate()
  }

  override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
    super.onSizeChanged(w, h, oldw, oldh)
    if (w != lastWidth) {
      lastWidth = w
      rebuildLayout()
    }
  }

  override fun onDraw(canvas: Canvas) {
    val l = layout ?: return
    canvas.save()
    // First clip to the view's actual bounds — this is the hard guarantee
    // that nothing we draw can ever leak into the next cell, regardless of
    // how tall the StaticLayout's line 0 ends up (Arabic diacritics stack
    // high) or whether shrink-to-fit hit its floor.
    canvas.clipRect(0f, 0f, width.toFloat(), height.toFloat())
    // Anchor on the baseline rather than line bounds. Using line bounds
    // for centering (height - lineBottom)/2 gives DIFFERENT vertical
    // positions per cell once shrink kicks in, which reads as bleeding
    // into neighbors. A constant baseline ratio gives consistent anchoring
    // across cells regardless of per-line fontSize.
    val baselineY = height * 0.72f
    val offset = baselineY - (if (l.lineCount > 0) l.getLineBaseline(0) else 0)
    canvas.translate(0f, offset)
    l.draw(canvas)
    canvas.restore()
  }

  // Multi-stage fit, in order from least to most invasive:
  //   1. Squeeze inter-word spacing (Paint.wordSpacing, API 29+).
  //   2. Tighten letter-spacing slightly.
  //   3. Scale fontSize down (floor: minScale).
  // Each stage measures with Layout.getDesiredWidth — that's the natural
  // single-line width, NOT the wrapped StaticLayout.getLineWidth(0) which
  // would lie to us once text wrapped to a second line.
  private fun rebuildLayout() {
    val available = (width - paddingLeft - paddingRight).coerceAtLeast(0)
    if (available <= 0 || rawText.isEmpty()) {
      layout = null
      return
    }
    paint.typeface = typefaceFor(fontFamilyKey)
    paint.textSize = baseTextSizePx
    paint.letterSpacing = 0f
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) paint.wordSpacing = 0f

    // Natural per-line auto-fit. Squeeze ONLY what each line needs:
    //   1. tighten word-spacing (capped at maxWordSqueeze × fontSize)
    //   2. tighten letter-spacing (capped at letterTighten em)
    //   3. shrink fontSize (floor: minScale)
    // Lines that already fit get no adjustment — that's why short lines
    // and long lines look consistent rather than uniformly squished.
    // Re-measure with a real StaticLayout draft (Layout.getDesiredWidth
    // under-reports Arabic shaped width, which previously made the
    // constrained layout ellipsize the RTL end — visually the LEFT).
    val target = (available - safetyMarginPx).coerceAtLeast(0f)
    var natural = measureNaturalWidth(rawText)

    if (natural > target && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && maxWordSqueeze > 0f) {
      val spaceCount = rawText.count { it == ' ' || it == ' ' }
      if (spaceCount > 0) {
        val deficit = natural - target
        val perSpace = deficit / spaceCount
        val cap = baseTextSizePx * maxWordSqueeze
        paint.wordSpacing = -perSpace.coerceAtMost(cap)
        natural = measureNaturalWidth(rawText)
      }
    }

    if (natural > target && letterTighten < 0f) {
      // Estimate per-glyph share of remaining deficit; cap at the letterTighten floor.
      val glyphCount = rawText.length.coerceAtLeast(1)
      val deficitEm = (natural - target) / paint.textSize / glyphCount
      paint.letterSpacing = (-deficitEm).coerceAtLeast(letterTighten)
      natural = measureNaturalWidth(rawText)
    }

    if (natural > target) {
      val scale = (target / natural).coerceAtLeast(minScale)
      paint.textSize = baseTextSizePx * scale
      // Arabic shaping with kerning/ligatures isn't perfectly linear under
      // fontSize scaling — re-measure and shrink one more notch if the
      // post-scale layout would still wrap (which would silently dump
      // words to a clipped second line).
      val natural2 = measureNaturalWidth(rawText)
      if (natural2 > available) {
        val rescale = (available / natural2).coerceAtLeast(minScale / scale)
        paint.textSize *= rescale
      }
    }

    layout = buildStaticLayout(rawText, available)
  }

  private fun measureNaturalWidth(text: String): Float {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
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
  }

  private fun buildStaticLayout(text: String, width: Int): StaticLayout {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      val builder = StaticLayout.Builder.obtain(text, 0, text.length, paint, width)
        .setAlignment(Layout.Alignment.ALIGN_NORMAL)
        .setIncludePad(false)
        .setLineSpacing(0f, 1f)
        .setMaxLines(1)
        // No ellipsize: shrink-to-fit (above) is responsible for making
        // text fit. If it ever doesn't, we'd rather clip cleanly than
        // show "..." which on RTL renders as dots on the LEFT and reads
        // as broken left-side padding.
        .setTextDirection(TextDirectionHeuristics.RTL)
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        builder.setJustificationMode(Layout.JUSTIFICATION_MODE_INTER_WORD)
      }
      builder.build()
    } else {
      @Suppress("DEPRECATION")
      StaticLayout(text, paint, width, Layout.Alignment.ALIGN_NORMAL, 1f, 0f, false)
    }
  }

  private fun typefaceFor(key: String): Typeface {
    // Map JS-side font-family names to the actual asset filename. We
    // currently ship a single TTF (IndopakNastaleeqExt) but JS may send
    // 'IndopakNastaleeq' (the expo-font-registered family name).
    val asset = when (key) {
      "IndopakNastaleeq", "IndopakNastaleeqExt" -> "IndopakNastaleeqExt"
      else -> key
    }
    cache[asset]?.let { return it }
    val tf = try {
      Typeface.createFromAsset(context.assets, "fonts/$asset.ttf")
    } catch (_: RuntimeException) {
      Typeface.DEFAULT
    }
    cache[asset] = tf
    return tf
  }

  companion object {
    private const val DEFAULT_FAMILY = "IndopakNastaleeqExt"
    private val cache = mutableMapOf<String, Typeface>()
  }
}
