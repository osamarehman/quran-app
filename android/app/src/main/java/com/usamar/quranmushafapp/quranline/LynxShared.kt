package com.usamar.quranmushafapp.quranline

import android.content.Context
import com.lynx.tasm.LynxGroup
import com.lynx.tasm.TemplateBundle

// App-wide shared Lynx state. Each per-cell LynxQuranLineView uses these:
//   - sharedBundle: parses the asset bundle ONCE; every cell renders from
//     this pre-parsed handle instead of re-parsing the bytes per view.
//   - sharedGroup: a LynxGroup with enableJSGroupThread=true so all views
//     in the group share a single JS runtime thread instead of spinning
//     up one per LynxView. Massive win when ~16 cells render at once.
object LynxShared {
  @Volatile private var bundle: TemplateBundle? = null
  @Volatile private var group: LynxGroup? = null

  @Synchronized
  fun getBundle(context: Context, assetName: String): TemplateBundle {
    bundle?.let { if (it.isValid()) return it }
    val bytes = context.applicationContext.assets.open(assetName).use { it.readBytes() }
    val parsed = TemplateBundle.fromTemplate(bytes)
    bundle = parsed
    return parsed
  }

  @Synchronized
  fun getGroup(): LynxGroup {
    group?.let { return it }
    val g = LynxGroup.LynxGroupBuilder()
      .setGroupName("quran-mushaf")
      .setEnableJSGroupThread(true)
      .build()
    group = g
    return g
  }

  // Useful if the bundle is hot-swapped (re-deploy of main.lynx.bundle).
  // Currently unused — included for completeness.
  @Synchronized
  fun invalidateBundle() {
    bundle?.release()
    bundle = null
  }
}
