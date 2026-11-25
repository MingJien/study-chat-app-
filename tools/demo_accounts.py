"""Create three persistent student identities on the loopback Emulator only."""
import json
from urllib.error import HTTPError
from urllib.request import Request, urlopen

AUTH = "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:"
DB = "http://127.0.0.1:9000"
PASSWORD = "StudyChat-local-demo"

def call(url, method, data=None):
    payload = json.dumps(data).encode() if data is not None else None
    request = Request(url, data=payload, method=method, headers={"Content-Type": "application/json"})
    with urlopen(request, timeout=8) as response:
        return json.load(response)

def seed_demo_accounts():
    for slug, name in [("an", "Minh An"), ("binh", "Hải Bình"), ("chi", "Lan Chi")]:
        account = {"email": f"{slug}@demo.example.test", "password": PASSWORD, "returnSecureToken": True}
        try:
            user = call(AUTH + "signUp?key=demo-key", "POST", account)
        except HTTPError as error:
            if json.load(error).get("error", {}).get("message") != "EMAIL_EXISTS":
                raise
            user = call(AUTH + "signInWithPassword?key=demo-key", "POST", account)
        uid, token = user["localId"], user["idToken"]
        profile = f"{DB}/profiles/{uid}.json?ns=demo-classroom-tv2-default-rtdb&auth={token}"
        saved = call(profile, "GET")
        if not saved:
            call(profile, "PUT", {"uid": uid, "displayName": name, "className": "Lập trình mobile"})
        if not user.get("displayName"):
            call(AUTH + "update?key=demo-key", "POST", {"idToken": token, "displayName": (saved or {}).get("displayName", name)})

if __name__ == '__main__':
    seed_demo_accounts()
