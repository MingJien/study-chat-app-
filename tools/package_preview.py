"""Package the CanvasKit (dart2js) build from the TV2 web CI artifact."""
import argparse
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

parser = argparse.ArgumentParser()
parser.add_argument("artifact", type=Path)
args = parser.parse_args()
output = Path(__file__).resolve().parents[1] / "preview/study-chat-web.zip"
output.parent.mkdir(exist_ok=True)
with ZipFile(args.artifact) as source, ZipFile(output.with_suffix(".tmp"), "w", ZIP_DEFLATED, compresslevel=9) as target:
    names = set(source.namelist())
    for required in ("index.html", "main.dart.js", "sqlite3.wasm", "sqflite_sw.js", "firebase-sdk/firebase-app.js"):
        if required not in names:
            raise ValueError(f"Missing {required}")
    for name in sorted(names):
        if name.endswith(("/", ".symbols")) or name.startswith(("canvaskit/skwasm", "canvaskit/wimp")):
            continue
        target.writestr(name, source.read(name))
output.with_suffix(".tmp").replace(output)
print(output, output.stat().st_size, "bytes")
