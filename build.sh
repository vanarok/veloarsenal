#!/bin/zsh
# Собирает Велоарсенал.app и ставит в ~/Applications
set -euo pipefail
cd "${0:A:h}"
OUT=build
APP="$OUT/Велоарсенал.app"
rm -rf "$OUT" && mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$OUT/icon.iconset"

swiftc -O macos/main.swift -o "$APP/Contents/MacOS/Veloarsenal"

for s in 16 32 128 256 512; do
  sips -z $s $s macos/icon.png --out "$OUT/icon.iconset/icon_${s}x${s}.png" >/dev/null
  sips -z $((s*2)) $((s*2)) macos/icon.png --out "$OUT/icon.iconset/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$OUT/icon.iconset" -o "$APP/Contents/Resources/icon.icns"

cp macos/Info.plist "$APP/Contents/Info.plist"
# Личный список вещей (private/inventory.json, не в git) подставляется как стартовый инвентарь
if [[ -f private/inventory.json ]]; then
  python3 - private/inventory.json docs/index.html "$APP/Contents/Resources/index.html" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
items = data.get("items", data) if isinstance(data, dict) else data
body = data.get("body", {}) if isinstance(data, dict) else {}
page = open(sys.argv[2], encoding="utf-8").read()
js = lambda v: json.dumps(v, ensure_ascii=False).replace("</", "<\\/")
tag = "<script>window.VA_DEFAULT_INVENTORY = " + js(items) + "; window.VA_DEFAULT_BODY = " + js(body) + ";</script>"
open(sys.argv[3], "w", encoding="utf-8").write(page.replace("<!-- VA_DEFAULT_INVENTORY -->", tag, 1))
PY
else
  cp docs/index.html "$APP/Contents/Resources/index.html"
fi
codesign --force --deep -s - "$APP"

pkill -f "MacOS/Veloarsenal" && sleep 1 || true
rm -rf ~/Applications/Велоарсенал.app
ditto "$APP" ~/Applications/Велоарсенал.app
echo "Готово: ~/Applications/Велоарсенал.app"
if [[ "${1:-}" == "--open" ]]; then open ~/Applications/Велоарсенал.app; fi
