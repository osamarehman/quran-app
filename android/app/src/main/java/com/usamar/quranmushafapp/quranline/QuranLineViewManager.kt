package com.usamar.quranmushafapp.quranline

import android.graphics.Color
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp

class QuranLineViewManager : SimpleViewManager<QuranLineView>() {

  override fun getName(): String = REACT_CLASS

  override fun createViewInstance(reactContext: ThemedReactContext): QuranLineView {
    return QuranLineView(reactContext)
  }

  @ReactProp(name = "text")
  fun setText(view: QuranLineView, value: String?) {
    view.setText(value ?: "")
  }

  @ReactProp(name = "fontSize", defaultFloat = 20f)
  fun setFontSize(view: QuranLineView, value: Float) {
    view.setFontSize(value)
  }

  @ReactProp(name = "fontFamily")
  fun setFontFamily(view: QuranLineView, value: String?) {
    view.setFontFamilyKey(value ?: "IndopakNastaleeqExt")
  }

  @ReactProp(name = "color", customType = "Color")
  fun setColor(view: QuranLineView, value: Int?) {
    view.setColorInt(value ?: Color.BLACK)
  }

  @ReactProp(name = "minScale", defaultFloat = 0.7f)
  fun setMinScale(view: QuranLineView, value: Float) {
    view.setMinScale(value)
  }

  @ReactProp(name = "maxWordSqueeze", defaultFloat = 0.3f)
  fun setMaxWordSqueeze(view: QuranLineView, value: Float) {
    view.setMaxWordSqueeze(value)
  }

  @ReactProp(name = "letterTighten", defaultFloat = -0.03f)
  fun setLetterTighten(view: QuranLineView, value: Float) {
    view.setLetterTighten(value)
  }

  @ReactProp(name = "safetyMarginPx", defaultFloat = 2f)
  fun setSafetyMarginPx(view: QuranLineView, value: Float) {
    view.setSafetyMarginPx(value)
  }

  companion object {
    const val REACT_CLASS = "QuranLineView"
  }
}
