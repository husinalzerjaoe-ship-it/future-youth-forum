from pathlib import Path
import re
import shutil
import xml.etree.ElementTree as ET

ROOT = Path(".")
ANDROID = ROOT / "android" / "app"
GRADLE = ANDROID / "build.gradle.kts"
if not GRADLE.exists():
    GRADLE = ANDROID / "build.gradle"
if not GRADLE.exists():
    raise SystemExit("Android app Gradle file not found")

text = GRADLE.read_text(encoding="utf-8")
dep_lines = [
    'implementation("org.godotengine:godot:4.7.2.stable")',
    'implementation("androidx.core:core-splashscreen:1.2.0")',
    'implementation("androidx.fragment:fragment:1.9.1")',
]
if "org.godotengine:godot:4.7.2.stable" not in text:
    match = re.search(r"dependencies\\s*\\{", text)
    additions = "\\n".join("    " + line for line in dep_lines) + "\\n"
    if not match:
        # New Flutter Kotlin DSL templates may omit a dependencies block.
        text = text.rstrip() + "\\n\\ndependencies {\\n" + additions + "}\\n"
    else:
        start_block = match.end()
        depth, end_block = 1, start_block
        while end_block < len(text) and depth:
            if text[end_block] == "{": depth += 1
            elif text[end_block] == "}": depth -= 1
            end_block += 1
        if depth:
            raise SystemExit("Unclosed Gradle dependencies block")
        text = text[:end_block - 1] + additions + text[end_block - 1:]

# Preserve Godot's project metadata files inside the APK assets directory.
assets = ANDROID / "src" / "main" / "assets"
assets.mkdir(parents=True, exist_ok=True)
for item in ["project.godot", "scenes", "scripts"]:
    source = ROOT / "godot" / item
    target = assets / item
    if target.is_dir():
        shutil.rmtree(target)
    elif target.exists():
        target.unlink()
    if source.is_dir():
        shutil.copytree(source, target)
    elif source.exists():
        shutil.copy2(source, target)
    else:
        raise SystemExit(f"Missing Godot project item: {source}")

# Keep Godot's project metadata and script files in the APK.
if GRADLE.name.endswith(".kts"):
    if "androidResources {" not in text:
        android_match = re.search(r"android\s*\{", text)
        if not android_match:
            raise SystemExit("Gradle android block not found")
        pos = android_match.end()
        text = text[:pos] + '\n    androidResources {\n        ignoreAssetsPattern = "!.svn:!.git:!.gitignore:!.ds_store:!*.scc:<dir>_*:!CVS:!thumbs.db:!picasa.ini:!*~"\n    }\n' + text[pos:]
else:
    if "ignoreAssetsPattern" not in text:
        android_match = re.search(r"android\s*\{", text)
        if not android_match:
            raise SystemExit("Gradle android block not found")
        pos = android_match.end()
        text = text[:pos] + '\n    androidResources {\n        ignoreAssetsPattern "!.svn:!.git:!.gitignore:!.ds_store:!*.scc:<dir>_*:!CVS:!thumbs.db:!picasa.ini:!*~"\n    }\n' + text[pos:]
GRADLE.write_text(text, encoding="utf-8")

# The audio_service plugin requires AudioServiceActivity as Flutter's host.
manifest = ANDROID / "src" / "main" / "AndroidManifest.xml"
tree = ET.parse(manifest)
root = tree.getroot()
ns = "{http://schemas.android.com/apk/res/android}"
app = root.find("application")
if app is None:
    raise SystemExit("Android application element not found")
for activity in app.findall("activity"):
    if activity.get(ns + "name") == "com.ryanheise.audioservice.AudioServiceActivity":
        activity.set(ns + "name", ".MainActivity")
        activity.set(ns + "configChanges",
            "orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode")
        activity.set(ns + "hardwareAccelerated", "true")
        activity.set(ns + "windowSoftInputMode", "adjustResize")
        break
else:
    raise SystemExit("AudioServiceActivity host declaration not found")

if not any(a.get(ns + "name") == ".GodotGameActivity" for a in app.findall("activity")):
    ET.SubElement(app, "activity", {
        ns + "name": ".GodotGameActivity",
        ns + "exported": "false",
        ns + "screenOrientation": "fullUser",
        ns + "configChanges": "layoutDirection|locale|orientation|keyboardHidden|screenSize|smallestScreenSize|density|keyboard|navigation|screenLayout|uiMode",
        ns + "theme": "@android:style/Theme.Material.Light.NoActionBar",
    })
ET.indent(tree, space="    ")
tree.write(manifest, encoding="utf-8", xml_declaration=True)

kotlin_dir = ANDROID / "src" / "main" / "kotlin" / "com" / "futureyouth" / "forum"
kotlin_dir.mkdir(parents=True, exist_ok=True)
(kotlin_dir / "MainActivity.kt").write_text("""package com.futureyouth.forum

import android.content.Intent
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "future_youth/godot")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openGame" -> {
                        startActivity(Intent(this, GodotGameActivity::class.java))
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
""", encoding="utf-8")
(kotlin_dir / "GodotGameActivity.kt").write_text("""package com.futureyouth.forum

import org.godotengine.godot.GodotActivity

/** Native Godot 4.7.2 runtime screen bundled inside Future Youth Forum. */
class GodotGameActivity : GodotActivity()
""", encoding="utf-8")

print("Configured Godot 4.7.2 Android runtime, bundled project assets and Flutter launch channel.")
