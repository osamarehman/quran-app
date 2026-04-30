package com.usamar.quranmushafapp.quranline

import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.ReadableType
import com.facebook.react.common.MapBuilder
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp
import org.json.JSONArray
import org.json.JSONObject

class LynxQuranLineViewManager : SimpleViewManager<LynxQuranLineView>() {

  override fun getName(): String = REACT_CLASS

  override fun createViewInstance(reactContext: ThemedReactContext): LynxQuranLineView {
    return LynxQuranLineView(reactContext)
  }

  @ReactProp(name = "bundleUri")
  fun setBundleUri(view: LynxQuranLineView, value: String?) {
    view.setBundleUri(value)
  }

  // Generic data prop. The JS side passes the entire payload as a JSON-
  // serialisable map; the native side stringifies and ships it through
  // lynxView.updateData() so the Lynx app re-renders.
  @ReactProp(name = "data")
  fun setData(view: LynxQuranLineView, value: ReadableMap?) {
    val json = if (value == null) JSONObject() else readableMapToJson(value)
    view.updateData(json)
  }

  override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any> {
    return MapBuilder.of<String, Any>(
      "onLynxLoaded",
      MapBuilder.of("registrationName", "onLynxLoaded"),
    )
  }

  private fun readableMapToJson(map: ReadableMap): JSONObject {
    val json = JSONObject()
    val it = map.keySetIterator()
    while (it.hasNextKey()) {
      val key = it.nextKey()
      when (map.getType(key)) {
        ReadableType.Null -> json.put(key, JSONObject.NULL)
        ReadableType.Boolean -> json.put(key, map.getBoolean(key))
        ReadableType.Number -> json.put(key, map.getDouble(key))
        ReadableType.String -> json.put(key, map.getString(key))
        ReadableType.Map -> map.getMap(key)?.let { json.put(key, readableMapToJson(it)) }
        ReadableType.Array -> map.getArray(key)?.let { json.put(key, readableArrayToJson(it)) }
      }
    }
    return json
  }

  private fun readableArrayToJson(arr: ReadableArray): JSONArray {
    val json = JSONArray()
    for (i in 0 until arr.size()) {
      when (arr.getType(i)) {
        ReadableType.Null -> json.put(JSONObject.NULL)
        ReadableType.Boolean -> json.put(arr.getBoolean(i))
        ReadableType.Number -> json.put(arr.getDouble(i))
        ReadableType.String -> json.put(arr.getString(i))
        ReadableType.Map -> arr.getMap(i)?.let { json.put(readableMapToJson(it)) }
        ReadableType.Array -> arr.getArray(i)?.let { json.put(readableArrayToJson(it)) }
      }
    }
    return json
  }

  companion object {
    const val REACT_CLASS = "LynxQuranLineView"
  }
}
