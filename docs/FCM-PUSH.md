# TechRen OS Push (FCM)

In-app inbox, Socket.IO chat toasts, and schedulers stay as-is. FCM adds **OS tray notifications** when the app is backgrounded or killed.

## Backend (Railway)

Set these from a Firebase **service account** JSON (Project settings → Service accounts → Generate new private key):

```env
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-...@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

Never commit the JSON or real private key. See `backend/.env.example`.

APIs (JWT required):

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/v1/notifications/device-token` | Upsert token for current user |
| PUT | `/api/v1/notifications/device-token` | Refresh old → new token |
| DELETE | `/api/v1/notifications/device-token` | Deactivate token (logout) |
| GET/PUT | `/api/v1/notifications/settings/me` | Student category prefs |

Legacy `POST /students/:id/fcm-token` still upserts into `DeviceToken`.

Payment reminders and `payment_lock` always push to the student (mute ignored). Other student categories respect settings. Parent alerts use parent device tokens + `ParentNotificationSettings`.

## Flutter native configs (you add locally)

| Platform | File | Notes |
|----------|------|--------|
| Android | `techren_edu/android/app/google-services.json` | Gradle applies the Google Services plugin only if this file exists |
| iOS | `techren_edu/ios/Runner/GoogleService-Info.plist` | Enable Push Notifications + Background Modes → Remote notifications; upload APNs key in Firebase |

Both paths are gitignored. Optional: run FlutterFire CLI to generate `lib/firebase_options.dart` (native plist/json is enough for default `Firebase.initializeApp()`).

## Android channel

Default FCM channel id: `techren_notifications` (TechRen Notifications). Matches backend `android.notification.channelId`.

## Deep links

FCM `data` includes string fields: `eventType`, `notificationId`, `screen`, `conversationId`, etc. Tap opens the matching route after session restore. Foreground: in-app toasts for payment/feedback/attendance/chat; shared `notificationId` / `messageId` dedup avoids triple-fire with Socket.IO.
