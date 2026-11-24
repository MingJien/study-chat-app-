import * as app from './firebase-sdk/firebase-app.js';
import * as auth from './firebase-sdk/firebase-auth.js';
import * as database from './firebase-sdk/firebase-database.js';

// FlutterFire accepts preloaded SDK modules. Keep the browser demo local.
// Bind the demo Auth instance before its asynchronous session restoration begins.
// FlutterFire's Dart-side useAuthEmulator runs after plugin initialization.
function initializeAuth(application, options) {
  const instance = auth.initializeAuth(application, options);
  if (instance.app.options.projectId === 'demo-classroom-tv2' && !instance.emulatorConfig) {
    auth.connectAuthEmulator(instance, 'http://127.0.0.1:9099');
  }
  return instance;
}
Object.assign(window, {firebase_core: app, firebase_auth: {...auth, initializeAuth}, firebase_database: database});
await import('./flutter_bootstrap.js');
