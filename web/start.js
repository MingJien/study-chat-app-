import * as app from './firebase-sdk/firebase-app.js';
import * as auth from './firebase-sdk/firebase-auth.js';
import * as database from './firebase-sdk/firebase-database.js';

// FlutterFire accepts preloaded SDK modules. Keep the browser demo local.
Object.assign(window, {firebase_core: app, firebase_auth: auth, firebase_database: database});
await import('./flutter_bootstrap.js');
