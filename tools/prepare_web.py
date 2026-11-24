"""Bundle the modular JS SDK version selected by the locked FlutterFire package."""
import json
import re
from pathlib import Path
from urllib.parse import unquote, urlparse
from urllib.request import url2pathname, urlopen

root = Path(__file__).resolve().parents[1]
config = root / ".dart_tool/package_config.json"
core = next(p for p in json.loads(config.read_text())["packages"] if p["name"] == "firebase_core_web")
uri = urlparse(core["rootUri"])
package = Path(url2pathname(uri.path)) if uri.scheme == "file" else config.parent / unquote(uri.path)
source = (package / "lib/src/firebase_sdk_version.dart").read_text()
version = re.search(r"supportedFirebaseJsSdkVersion = '([0-9.]+)'", source)[1]
base = f"https://www.gstatic.com/firebasejs/{version}/"
target = root / "web/firebase-sdk"
target.mkdir(exist_ok=True)
for name in ("firebase-app.js", "firebase-auth.js", "firebase-database.js"):
    with urlopen(base + name, timeout=45) as response:
        code = response.read().decode()
    (target / name).write_text(code.replace(base, "./"), encoding="utf-8")
print(f"Firebase Web SDK {version}")
