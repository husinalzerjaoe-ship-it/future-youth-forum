from pathlib import Path

manifest = Path("android/app/src/main/AndroidManifest.xml")
if not manifest.exists():
    raise SystemExit("Android manifest was not generated")

resource = Path("android/app/src/main/res/drawable/ic_launcher_logo.xml")
resource.parent.mkdir(parents=True, exist_ok=True)
resource.write_text("""<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path android:fillColor="#171936" android:pathData="M22,0 H86 C98,0 108,10 108,22 V86 C108,98 98,108 86,108 H22 C10,108 0,98 0,86 V22 C0,10 10,0 22,0 Z"/>
    <path android:fillColor="#292653" android:pathData="M54,13 A41,41 0,1 0 54,95 A41,41 0,1 0 54,13 Z"/>
    <path android:fillColor="#6554D9" android:pathData="M54,23 L64,43 L85,54 L64,65 L54,85 L44,65 L23,54 L44,43 Z"/>
    <path android:fillColor="#8FE8FF" android:pathData="M54,36 L61,49 L74,54 L61,59 L54,72 L47,59 L34,54 L47,49 Z"/>
    <path android:fillColor="#FFFFFF" android:pathData="M81,17 L84,24 L91,27 L84,30 L81,37 L78,30 L71,27 L78,24 Z"/>
    <path android:fillColor="#42D6D7" android:pathData="M25,73 L28,80 L35,83 L28,86 L25,93 L22,86 L15,83 L22,80 Z"/>
</vector>
""", encoding="utf-8")

text = manifest.read_text(encoding="utf-8")
text = text.replace('android:icon="@mipmap/ic_launcher"', 'android:icon="@drawable/ic_launcher_logo"')
text = text.replace('android:roundIcon="@mipmap/ic_launcher"', 'android:roundIcon="@drawable/ic_launcher_logo"')
manifest.write_text(text, encoding="utf-8")
main_activity = Path("android/app/src/main/kotlin/com/futureyouth/forum/MainActivity.kt")
main_activity.parent.mkdir(parents=True, exist_ok=True)
main_activity.write_text("""package com.futureyouth.forum

import android.app.DownloadManager
import android.content.Context
import android.net.Uri
import android.os.Environment
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.futureyouth.forum/downloads")
            .setMethodCallHandler { call, result ->
                if (call.method != "downloadFile") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    val url = call.argument<String>("url") ?: throw IllegalArgumentException("Missing URL")
                    val fileName = (call.argument<String>("fileName") ?: "forum-download")
                        .replace(Regex("[^A-Za-z0-9._-]"), "_")
                    val request = DownloadManager.Request(Uri.parse(url))
                        .setTitle(fileName)
                        .setDescription("تنزيل من ملتقى شباب المستقبل")
                        .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
                        .setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fileName)
                        .setAllowedOverMetered(true)
                        .setAllowedOverRoaming(false)
                    val manager = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
                    result.success(manager.enqueue(request))
                } catch (error: Exception) {
                    result.error("DOWNLOAD_FAILED", error.message, null)
                }
            }
    }
}
""", encoding="utf-8")

print("Applied Future Youth Forum launcher icon and Android Downloads integration")
