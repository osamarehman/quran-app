package com.usamar.quranmushafapp.quranline

import android.content.Context
import android.view.ViewGroup
import android.widget.FrameLayout
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.events.RCTEventEmitter
import com.lynx.tasm.LynxView
import com.lynx.tasm.LynxViewBuilder
import com.lynx.tasm.TemplateData
import com.lynx.tasm.ThreadStrategyForRendering
import com.lynx.tasm.provider.AbsTemplateProvider
import org.json.JSONObject
import java.io.IOException

// Hosts a Lynx view inside the React Native tree. Each instance renders
// one Mushaf line via the bundled Lynx app loaded from either:
//   - a dev URL (Lynx Rspeedy dev server on `adb reverse`-forwarded port), or
//   - an asset bundle baked into the APK (release builds).
// Props from the RN side (text, fontSize, color, …) are pushed into the
// Lynx tree via lynxView.updateData(JSON).
class LynxQuranLineView(context: Context) : FrameLayout(context) {

  private val reactContext: ThemedReactContext? = (context as? ThemedReactContext)
  private val lynxView: LynxView
  private var bundleUri: String = DEFAULT_DEV_URL
  private var loaded = false
  private var pendingData: JSONObject = JSONObject()
  private var lastViewportW = 0
  private var lastViewportH = 0

  override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
    super.onSizeChanged(w, h, oldw, oldh)
    if ((w != lastViewportW || h != lastViewportH) && w > 0 && h > 0) {
      lastViewportW = w
      lastViewportH = h
      lynxView.updateScreenMetrics(w, h)
      lynxView.updateViewport(w, h)
      // Bundle render is deferred until both data AND viewport are known.
      // If we already have data and just got our viewport, render now.
      // If already loaded, forward updated viewport metrics so the Lynx
      // layout engine knows the real bounds (it relayouts internally).
      if (!loaded && pendingData.length() > 0) {
        reloadWithCurrentData()
      }
    }
  }

  init {
    val builder = LynxViewBuilder()
    // Share the JS runtime + element manager across all per-cell views
    // on the page. Without this, every LynxView spins up its own JS
    // engine — fine for a single LynxView, painful when 16 mount at once
    // for a Mushaf page.
    builder.setLynxGroup(LynxShared.getGroup())
    // Threading: maximum parallelism. MULTI_THREADS splits JS + layout +
    // TASM (style/layout pipeline) onto separate threads instead of
    // serialising on UI. With Mushaf's 16 cells per page each rendering
    // a single line, the layout work fans out instead of head-of-line
    // blocking. EnableMultiAsyncThread + EnableAutoConcurrency let the
    // engine run independent stages concurrently within a single view.
    builder.setThreadStrategyForRendering(ThreadStrategyForRendering.MULTI_THREADS)
    builder.setEnableMultiAsyncThread(true)
    builder.setEnableAutoConcurrency(true)
    builder.setEnableLayoutSafepoint(true)
    builder.setEnableCreateViewAsync(true)
    // VSync-aligned dispatch keeps work batched against display refresh
    // — smoother scrolling, less jitter on swipe between pages.
    builder.setEnableVSyncAlignedMessageLoop(true)
    builder.setTemplateProvider(AssetTemplateProvider(context))
    // Seed the engine with the device screen size so the layout pass has
    // a real viewport on first render, even before our host's onSizeChanged
    // fires. updateViewport() in onSizeChanged then refines this if the
    // host's actual size differs.
    val dm = context.resources.displayMetrics
    builder.setScreenSize(dm.widthPixels, dm.heightPixels)
    lynxView = builder.build(context)
    addView(
      lynxView,
      LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT),
    )
    // Defer the initial bundle load until the data prop arrives, so the
    // very first render in Lynx already has real props instead of the
    // hardcoded fallback. RN dispatches props synchronously after the
    // view is created, so this happens within the same frame.
  }

  fun setBundleUri(value: String?) {
    val next = value?.takeIf { it.isNotBlank() } ?: DEFAULT_DEV_URL
    if (next == bundleUri && loaded) return
    bundleUri = next
    loaded = false
    // Don't kick the render here — wait for setData() so the first render
    // already has real props via TemplateData. RN dispatches props in JSX
    // order, so setData arrives within the same frame.
  }

  // Push a JSON-shaped data payload to the Lynx app. The Lynx app
  // re-renders against this data the same way React renders against props.
  // - If the bundle has already loaded, we send an updateData() which the
  //   Lynx side observes via useInitDataChanged().
  // - If it's still loading, we stash the payload as pendingData and replay
  //   it as the *initial* TemplateData when the load fires, so the very
  //   first render in Lynx gets the real props (not the fallback).
  fun updateData(data: JSONObject) {
    pendingData = data
    if (loaded) {
      lynxView.updateData(data.toString())
    } else if (lastViewportW > 0 && lastViewportH > 0) {
      // Viewport already known; safe to render with this initial data.
      reloadWithCurrentData()
    }
    // else: viewport not yet known. onSizeChanged will fire and pick up
    // the pendingData we just stored, then call reloadWithCurrentData()
    // itself with both viewport AND data ready.
  }

  private fun reloadWithCurrentData() {
    val initialData =
      if (pendingData.length() > 0) TemplateData.fromString(pendingData.toString()) else null
    // Render from the shared TemplateBundle when we can — the bundle is
    // parsed once at app boot and reused across every Mushaf cell.
    // Saves ~80 KB of bytecode parsing per cell × 16 cells = noticeable
    // page-mount latency. Fall back to renderTemplateUrl for non-asset
    // bundleUri (e.g. Lynx dev server URL during local iteration).
    val isAsset = !(bundleUri.startsWith("http://") || bundleUri.startsWith("https://"))
    if (isAsset) {
      try {
        val bundle = LynxShared.getBundle(context, bundleUri)
        lynxView.renderTemplateBundle(bundle, initialData, null)
      } catch (e: Exception) {
        android.util.Log.w("Lynx", "Falling back to URL render: ${e.message}")
        lynxView.renderTemplateUrl(bundleUri, initialData)
      }
    } else {
      lynxView.renderTemplateUrl(bundleUri, initialData)
    }
    loaded = true
    emitEvent("onLynxLoaded", Arguments.createMap().apply { putString("uri", bundleUri) })
  }

  private fun emitEvent(name: String, payload: WritableMap) {
    val rc = reactContext ?: return
    rc.getJSModule(RCTEventEmitter::class.java).receiveEvent(id, name, payload)
  }

  // Template provider that handles both asset:// and http(s):// loads.
  // Lynx hands every renderTemplateUrl() call to this provider; we route
  // by URI scheme: HTTP for dev (Rspeedy server), assets for release.
  private class AssetTemplateProvider(context: Context) : AbsTemplateProvider() {
    private val ctx: Context = context.applicationContext
    override fun loadTemplate(uri: String, callback: Callback) {
      Thread {
        try {
          val bytes = if (uri.startsWith("http://") || uri.startsWith("https://")) {
            java.net.URL(uri).openStream().use { it.readBytes() }
          } else {
            ctx.assets.open(uri).use { it.readBytes() }
          }
          callback.onSuccess(bytes)
        } catch (e: IOException) {
          callback.onFailed(e.message ?: "load failed: $uri")
        } catch (e: Exception) {
          callback.onFailed(e.message ?: "load failed: $uri")
        }
      }.start()
    }
  }

  companion object {
    // Default to the URL the Rspeedy dev server prints. JS can override
    // via the `bundleUri` prop.
    // Production bundle baked into android/app/src/main/assets/. Rebuild
    // with `npm run build` in the lynx/ folder + copy to assets after
    // changing Lynx-side code. Dev URL loading was abandoned because
    // Lynx Android 3.7.0 lacks WebSocket (the Rspeedy HMR client crashes).
    private const val DEFAULT_DEV_URL = "main.lynx.bundle"
  }
}
