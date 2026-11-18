from pathlib import Path
import xml.etree.ElementTree as ET

path = Path("android/app/src/main/AndroidManifest.xml")
if not path.exists():
    raise SystemExit("Run flutter create --platforms=android --org com.alm3tz . first")
ET.register_namespace("android", "http://schemas.android.com/apk/res/android")
ns = "{http://schemas.android.com/apk/res/android}"
tree = ET.parse(path)
root = tree.getroot()
if not any(p.attrib.get(ns+"name") == "android.permission.INTERNET" for p in root.findall("uses-permission")):
    ET.SubElement(root, "uses-permission", {ns+"name": "android.permission.INTERNET"})
app = root.find("application")
if app is None:
    raise SystemExit("Android manifest has no application element")
name = "com.google.android.gms.ads.APPLICATION_ID"
for entry in list(app.findall("meta-data")):
    if entry.attrib.get(ns+"name") == name:
        app.remove(entry)
ET.SubElement(app, "meta-data", {ns+"name": name, ns+"value": "ca-app-pub-7952445820014663~9340646779"})
app.set(ns+"label", "رحلة الألغاز")
app.set(ns+"icon", "@drawable/game_icon")
icon_src = Path("android_assets/game_icon.xml")
icon_dest = Path("android/app/src/main/res/drawable/game_icon.xml")
icon_dest.parent.mkdir(parents=True, exist_ok=True)
icon_dest.write_bytes(icon_src.read_bytes())
tree.write(path, encoding="utf-8", xml_declaration=True)
print("AdMob App ID configured")
