# Push Notifications (Firebase Cloud Messaging)

Foreground **and** background/terminated push notifications for Android and iOS,
with the **default system sound** on both.

Firebase project: **gatelq** · iOS bundle: `com.synergynoida.vms` · Android
package: `com.synergynoida.vms`.

---

## 1. How it works

| App state | Android | iOS |
|-----------|---------|-----|
| **Foreground** (open) | We render a local notification via `flutter_local_notifications` (Android does **not** auto-show FCM notifications when open). | The OS shows the banner because we set `setForegroundNotificationPresentationOptions(alert/badge/sound: true)`. |
| **Background / terminated** | The OS renders the FCM `notification` payload automatically on the `high_importance_channel` (default sound). | The OS renders it via APNs (default sound when the payload asks for it). |
| **Tap** | `onMessageOpenedApp` / `getInitialMessage` / local-notification tap → navigate. | Same. |

> **Sound rule:** a notification only plays a sound if the message contains a
> **`notification`** block (not a data-only message), and — on iOS — the APNs
> payload sets `sound`. The Firebase Console "Test message" does this for you.

---

## 2. Files changed / added

### Dart
- **`lib/services/notification_service.dart`** *(new)* — all FCM + local
  notification logic:
  - `navigatorKey` — global key for navigating on tap.
  - `kDefaultChannel` — the Android channel `high_importance_channel`
    (importance high + default sound).
  - `firebaseMessagingBackgroundHandler` — top-level, `@pragma('vm:entry-point')`
    background handler.
  - `NotificationService.initialize()` — permissions, foreground presentation,
    channel creation, Android 13+ runtime permission, message streams, token
    logging, cold-start handling.
- **`lib/main.dart`** — registers the background handler and calls
  `NotificationService.instance.initialize()` before `runApp`.
- **`lib/myapp.dart`** — adds `navigatorKey: navigatorKey` to `MaterialApp`.

### Android — `android/app/src/main/AndroidManifest.xml`
- Added `INTERNET` permission (FCM needs network).
- Added `POST_NOTIFICATIONS` permission (**required on Android 13 / API 33+**).
- `firebase_messaging_auto_init_enabled` → `true`.
- Added `default_notification_channel_id` = `high_importance_channel` so the OS
  uses our channel (and its sound) for background notifications.

### iOS
- **`ios/Runner/Info.plist`** — `FirebaseMessagingAutoInitEnabled` → `true`.
  (`UIBackgroundModes` already had `remote-notification` + `fetch`.)
- **`ios/Runner/AppDelegate.swift`** — left minimal on purpose. With Firebase's
  method-swizzling proxy (default on) it correctly forwards APNs, so no changes
  are needed.
- **`ios/Runner/Runner.entitlements`** — `aps-environment` = `development`
  (fine for debug builds on a real device). **See §5 before releasing.**
- `pod install` was run — `FirebaseMessaging` + `flutter_local_notifications`
  pods are integrated.

### Dependencies — `pubspec.yaml`
- Added `flutter_local_notifications: ^19.0.0` (resolved to 19.5.0).
  (`firebase_core` and `firebase_messaging` were already present.)

### Android build — `android/app/build.gradle.kts`
- `flutter_local_notifications` 19.x needs **core library desugaring**, so:
  - `compileOptions { isCoreLibraryDesugaringEnabled = true }`
  - `dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }`
  Without these the build fails with
  *"Dependency ':flutter_local_notifications' requires core library desugaring to be enabled"*.

---

## 3. Run it

```bash
flutter pub get
cd ios && LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 pod install && cd ..
flutter run
```

> `LANG/LC_ALL` are set because CocoaPods 1.16 crashes with an
> `Encoding::CompatibilityError` when the shell locale is not UTF-8.

**iOS must run on a real iPhone** — the Simulator has no APNs, so there is no
FCM token and no push delivery.

---

## 4. Testing

1. Run the app; copy the `✅ FCM token: ...` line from the console.
2. Firebase Console → **Messaging** → **New campaign / Send test message**.
3. Paste the token, send, and verify:
   - **Foreground:** open the app → banner + default sound.
   - **Background:** press home (app still running) → tray notification + sound.
   - **Terminated:** swipe the app away → send → notification arrives; tapping
     it opens the app and navigates.

### Sending from your backend (HTTP v1)

Send a **notification** message so the OS shows it and plays sound:

```json
{
  "message": {
    "token": "<DEVICE_FCM_TOKEN>",
    "notification": { "title": "New visitor", "body": "Someone is at the gate" },
    "android": {
      "notification": {
        "channel_id": "high_importance_channel",
        "sound": "default"
      }
    },
    "apns": {
      "payload": { "aps": { "sound": "default" } }
    }
  }
}
```

- Android sound comes from the `high_importance_channel` channel (default sound);
  `channel_id` is optional because the manifest sets it as the default.
- iOS sound **requires** `apns.payload.aps.sound = "default"`.

---

## 5. Before you ship (release checklist)

- **iOS `aps-environment`:** currently `development`. For TestFlight / App Store
  builds it must be `production`. Easiest: in Xcode → *Runner* target →
  *Signing & Capabilities*, keep the **Push Notifications** capability enabled
  and let Xcode manage the entitlement per build configuration, or set the
  entitlement value to `production` for the Release build.
- **APNs key in Firebase:** already configured (APNs Auth Key `77RGRNPJDJ`,
  Team `853R23ZSA7`) — nothing to do.
- **Custom sound (optional):** this setup uses the **default** sound. To switch
  to a custom sound later: add `res/raw/<name>.wav` on Android, set
  `sound: RawResourceAndroidNotificationSound('<name>')` on the channel, add the
  `.wav` to the Xcode *Copy Bundle Resources* phase on iOS, and send
  `"sound": "<name>.wav"` in the APNs payload.

---

## 6. Where to change the tap destination

`NotificationService._navigateToTarget()` currently pushes `DashboardScreen`.
Edit that method (or branch on `message.data`) to route wherever you need.
