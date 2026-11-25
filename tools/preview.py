"""Serve the CI-built Flutter Web ZIP and run the local Firebase demo."""
import argparse
import http.server
import json
import mimetypes
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import time
from urllib.parse import unquote, urlsplit
from urllib.request import urlopen
import zipfile

from demo_accounts import seed_demo_accounts

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / ".local-data/firebase"
ARCHIVE = ROOT / "preview/study-chat-web.zip"
PROJECT = "demo-classroom-tv2"

def emulators_ready():
    try:
        with urlopen("http://127.0.0.1:4400/emulators", timeout=1) as reply:
            services = json.load(reply)
        return all(services.get(name, {}).get("port") == port for name, port in [("auth", 9099), ("database", 9000)])
    except (OSError, ValueError):
        return False

def start_emulators():
    if emulators_ready():
        return None
    cli = shutil.which("npx.cmd" if os.name == "nt" else "npx")
    env = dict(os.environ)
    # Prefer the installed JDK to the Oracle javapath redirector on Windows.
    java_home = Path(env.get("JAVA_HOME", "")) / "bin"
    if os.name == "nt" and not (java_home / "java.exe").is_file():
        installed = Path(env.get("ProgramFiles", "C:/Program Files")) / "Java"
        candidates = sorted(installed.glob("jdk-*/bin/java.exe"), reverse=True)
        if candidates:
            java_home = candidates[0].parent
    if (java_home / ("java.exe" if os.name == "nt" else "java")).is_file():
        env["JAVA_HOME"] = str(java_home.parent.resolve())
        env["PATH"] = str(java_home.resolve()) + os.pathsep + env.get("PATH", "")
    if not cli or not shutil.which("java", path=env.get("PATH")):
        sys.exit("Can Node.js 22+ va Java 21+ de chay Firebase Emulator.")
    DATA.parent.mkdir(exist_ok=True)
    args = [cli, "--yes", "--prefer-offline", "firebase-tools@15.37.0", "emulators:start", "--only", "auth,database", "--project", PROJECT, "--export-on-exit", str(DATA)]
    if (DATA / "firebase-export-metadata.json").is_file():
        args += ["--import", str(DATA)]
    env.setdefault("JAVA_TOOL_OPTIONS", "-Xmx192m")
    proc = subprocess.Popen(args, cwd=ROOT, env=env, creationflags=subprocess.CREATE_NEW_PROCESS_GROUP if os.name == "nt" else 0)
    try:
        while not emulators_ready():
            if proc.poll() is not None:
                raise SystemExit("Firebase Emulator khoi dong that bai. Xem log o tren.")
            time.sleep(0.4)
    except BaseException:
        stop_emulators(proc)
        raise
    return proc

def stop_emulators(proc):
    if proc is not None and proc.poll() is None:
        proc.send_signal(signal.CTRL_BREAK_EVENT if os.name == "nt" else signal.SIGINT)
        try:
            proc.wait(timeout=20)
        except subprocess.TimeoutExpired:
            proc.terminate()

class WebHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        name = unquote(urlsplit(self.path).path).lstrip("/") or "index.html"
        if name == "__tv2/status":
            payload = b'{"app":"study-chat-tv2"}'
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
            return
        try:
            with zipfile.ZipFile(self.server.archive) as archive:
                payload = archive.read(name)
        except KeyError:
            self.send_error(404)
            return
        mime = {".wasm": "application/wasm", ".mjs": "text/javascript", ".js": "text/javascript"}.get(Path(name).suffix) or mimetypes.guess_type(name)[0] or "application/octet-stream"
        self.send_response(200)
        self.send_header("Content-Type", mime)
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()
        try:
            self.wfile.write(payload)
        except (BrokenPipeError, ConnectionResetError):
            pass
    def log_message(self, fmt, *args):
        if len(args) < 2 or str(args[1]) != "200":
            super().log_message(fmt, *args)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--archive", type=Path, default=ARCHIVE)
    parser.add_argument("--web-only", action="store_true")
    args = parser.parse_args()
    if not args.archive.is_file():
        sys.exit("Thieu preview/study-chat-web.zip. Tai artifact study-chat-tv2-web tu GitHub Actions.")
    print("TV2 START", flush=True)
    try:
        with urlopen(f"http://127.0.0.1:{args.port}/__tv2/status", timeout=1) as reply:
            running = json.load(reply).get("app") == "study-chat-tv2"
    except (OSError, ValueError):
        running = False
    if running and (args.web_only or emulators_ready()):
        if not args.web_only:
            seed_demo_accounts()
        print(f"TV2 READY http://127.0.0.1:{args.port}", flush=True)
        return
    with http.server.ThreadingHTTPServer(("127.0.0.1", args.port), WebHandler) as server:
        server.archive = args.archive
        proc = None
        try:
            if not args.web_only:
                proc = start_emulators()
                seed_demo_accounts()
            print(f"TV2 READY http://127.0.0.1:{args.port}", flush=True)
            server.serve_forever()
        except KeyboardInterrupt:
            pass
        finally:
            stop_emulators(proc)

if __name__ == "__main__":
    main()
