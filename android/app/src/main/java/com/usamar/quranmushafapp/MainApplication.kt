package com.usamar.quranmushafapp

import android.app.Application
import android.content.res.Configuration
import android.graphics.Typeface

import com.facebook.react.PackageList
import com.facebook.react.ReactApplication
import com.facebook.react.ReactNativeApplicationEntryPoint.loadReactNative
import com.facebook.react.ReactNativeHost
import com.facebook.react.ReactPackage
import com.facebook.react.ReactHost
import com.facebook.react.common.ReleaseLevel
import com.facebook.react.defaults.DefaultNewArchitectureEntryPoint
import com.facebook.react.defaults.DefaultReactNativeHost

import expo.modules.ApplicationLifecycleDispatcher
import expo.modules.ReactNativeHostWrapper

import com.usamar.quranmushafapp.quranline.QuranLinePackage

import com.lynx.service.http.LynxHttpService
import com.lynx.service.image.LynxImageService
import com.lynx.service.log.LynxLogService
import com.lynx.tasm.LynxEnv
import com.lynx.tasm.behavior.shadow.text.TypefaceCache
import com.lynx.tasm.service.LynxServiceCenter
import com.usamar.quranmushafapp.quranline.LynxShared

class MainApplication : Application(), ReactApplication {

  override val reactNativeHost: ReactNativeHost = ReactNativeHostWrapper(
      this,
      object : DefaultReactNativeHost(this) {
        override fun getPackages(): List<ReactPackage> =
            PackageList(this).packages.apply {
              add(QuranLinePackage())
            }

          override fun getJSMainModuleName(): String = ".expo/.virtual-metro-entry"

          override fun getUseDeveloperSupport(): Boolean = BuildConfig.DEBUG

          override val isNewArchEnabled: Boolean = BuildConfig.IS_NEW_ARCHITECTURE_ENABLED
      }
  )

  override val reactHost: ReactHost
    get() = ReactNativeHostWrapper.createReactHost(applicationContext, reactNativeHost)

  override fun onCreate() {
    super.onCreate()
    DefaultNewArchitectureEntryPoint.releaseLevel = try {
      ReleaseLevel.valueOf(BuildConfig.REACT_NATIVE_RELEASE_LEVEL.uppercase())
    } catch (e: IllegalArgumentException) {
      ReleaseLevel.STABLE
    }
    loadReactNative(this)
    ApplicationLifecycleDispatcher.onApplicationCreate(this)
    initLynx()
  }

  private fun initLynx() {
    // Lynx services power image/log/http inside Lynx-rendered views.
    // Fresco is already initialized by RN, so we don't re-init it here.
    LynxServiceCenter.inst().registerService(LynxImageService.getInstance())
    LynxServiceCenter.inst().registerService(LynxLogService)
    LynxServiceCenter.inst().registerService(LynxHttpService)
    // LynxEnv is the global Lynx engine handle. Must be initialized before
    // any LynxView is constructed.
    LynxEnv.inst().init(this, null, null, null)

    // Register the IndoPak Nastaleeq font with Lynx's TypefaceCache so
    // CSS `font-family: IndopakNastaleeq` resolves to the same TTF the
    // RN side uses. Avoids the broken `webpack:///` URL in the bundled
    // CSS that doesn't resolve outside the Rspeedy dev server.
    try {
      // Lynx's TypefaceCache auto-constructs the filename as
      // "<dirPrefix>/<fontName>.ttf" — so the fontName MUST equal the
      // base TTF filename. Asset is at assets/fonts/IndopakNastaleeqExt.ttf
      // → fontName="IndopakNastaleeqExt", dirPrefix="fonts".
      TypefaceCache.cacheFullStyleTypefacesFromAssets(
        assets,
        "IndopakNastaleeqExt",
        "fonts",
      )
      android.util.Log.i("Lynx", "Registered IndopakNastaleeqExt from assets")
    } catch (t: Throwable) {
      android.util.Log.w("Lynx", "Font registration failed: ${t.message}")
    }

    // Prewarm shared Lynx resources off the main thread so the first
    // Mushaf page mount doesn't pay the bundle-parse + group-init cost.
    Thread {
      try {
        LynxShared.getBundle(this, "main.lynx.bundle")
        LynxShared.getGroup()
        android.util.Log.i("Lynx", "Prewarmed shared bundle + group")
      } catch (t: Throwable) {
        android.util.Log.w("Lynx", "Prewarm failed: ${t.message}")
      }
    }.start()
    if (BuildConfig.DEBUG) {
      // Reflective DevTools registration so release builds (which don't
      // include the devtool artifacts) compile cleanly. The classes only
      // exist on the debug classpath via debugImplementation in build.gradle.
      try {
        val devToolServiceCls = Class.forName("com.lynx.service.devtool.LynxDevToolService")
        val instance = devToolServiceCls.getField("INSTANCE").get(null)
        // enable all sessions debug for DevTool Desktop connection
        devToolServiceCls.getMethod("enableAllSessions").invoke(instance)
        devToolServiceCls.getMethod("setLynxDebugPresetValue", java.lang.Boolean.TYPE).invoke(instance, true)
        devToolServiceCls.getMethod("setLogBoxPresetValue", java.lang.Boolean.TYPE).invoke(instance, true)
        devToolServiceCls.getMethod("setLoadQJSBridge", java.lang.Boolean.TYPE).invoke(instance, true)
        // register service
        LynxServiceCenter.inst().registerService(instance as com.lynx.tasm.service.IServiceProvider)
        // Per-view features — left OFF by default since they cost
        // measurable per-frame time even when no DevTool desktop is
        // connected. Toggle ON manually when you actively want to
        // inspect the Lynx tree from the Lynx DevTool desktop app.
        LynxEnv.inst().enableLynxDebug(false)
        LynxEnv.inst().enableDevtool(false)
        LynxEnv.inst().enableLogBox(true)
        android.util.Log.i("Lynx", "DevTools enabled (debug build)")
      } catch (t: Throwable) {
        android.util.Log.w("Lynx", "DevTools init skipped: ${t.message}")
      }
    }
  }

  override fun onConfigurationChanged(newConfig: Configuration) {
    super.onConfigurationChanged(newConfig)
    ApplicationLifecycleDispatcher.onConfigurationChanged(this, newConfig)
  }
}
