# 🔐 Security Checklist - RunningMan

This checklist ensures your Firebase and iOS app security is properly configured.

---

## 🎯 Priority Matrix

| Priority | Description | Timeline |
|----------|-------------|----------|
| 🔴 **P0 - CRITICAL** | Must be done immediately | This week |
| 🟡 **P1 - HIGH** | Should be done soon | Within 2 weeks |
| 🟢 **P2 - MEDIUM** | Important but not urgent | Within 1 month |
| ⚪ **P3 - LOW** | Nice to have | As time permits |

---

## 🔥 Firebase Security

### API Key Restrictions 🔴 **P0**

- [ ] **Restrict API Key in Google Cloud Console**
  1. Go to [Google Cloud Console](https://console.cloud.google.com/)
  2. Select project: `squadrun-f78b3`
  3. APIs & Services > Credentials
  4. Find API key: `AIzaSyCdvK1y9JLI-jV7pkHds_UjLRDlXjYF3lg`
  5. Click "Edit"
  6. Under "Application restrictions":
     - Select "iOS apps"
     - Add bundle ID: `com.gi.joe.RunningMan`
  7. Under "API restrictions":
     - Select "Restrict key"
     - Enable only:
       - ✅ Cloud Firestore API
       - ✅ Firebase Authentication API
       - ✅ Firebase Storage API (if using)
       - ✅ Firebase Cloud Messaging API (if using push notifications)
  8. Click "Save"

**Why:** Prevents unauthorized use of your API key if it leaks.

### Firestore Security Rules 🔴 **P0**

Your current `firestore.rules` (from CLAUDE.md) needs review:

**Current Issue:**
```javascript
function isSquadMember(squadId) {
  return request.auth != null &&
         exists(/databases/$(database)/documents/squads/$(squadId)/members/$(request.auth.uid));
}
```

**Problem:** The `exists()` check may be expensive and could fail if the member document structure changes.

**Recommended Fix:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper function to check squad membership
    function isSquadMember(squadId) {
      return request.auth != null &&
             get(/databases/$(database)/documents/squads/$(squadId)).data.members[request.auth.uid] != null;
    }

    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }

    // Squads collection
    match /squads/{squadId} {
      // Anyone authenticated can create a squad
      allow create: if isAuthenticated();

      // Only members can read and update
      allow read, update: if isSquadMember(squadId);

      // Only admin can delete (add admin check if needed)
      allow delete: if isSquadMember(squadId);

      // Members subcollection
      match /members/{memberId} {
        allow read: if isSquadMember(squadId);
        allow write: if isSquadMember(squadId);
      }

      // Sessions subcollection
      match /sessions/{sessionId} {
        allow read: if isSquadMember(squadId);
        allow create: if isSquadMember(squadId);
        allow update, delete: if isSquadMember(squadId);

        // LiveFeed subcollection
        match /liveFeed/{itemId} {
          allow read: if isSquadMember(squadId);
          allow create: if isSquadMember(squadId);
          // Only creator can delete their own feed items
          allow delete: if isSquadMember(squadId) &&
                           request.auth.uid == resource.data.senderId;
        }

        // Participants subcollection
        match /participants/{userId} {
          allow read: if isSquadMember(squadId);
          // Users can only write their own participant data
          allow create, update: if isSquadMember(squadId) &&
                                   request.auth.uid == userId;
          allow delete: if isSquadMember(squadId) &&
                          request.auth.uid == userId;
        }
      }
    }

    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if request.auth.uid == userId;
    }
  }
}
```

**Action Items:**
- [ ] Copy the recommended rules to Firebase Console
- [ ] Test with Firebase Emulator Suite (see Testing section below)
- [ ] Deploy rules: `firebase deploy --only firestore:rules`

### Firebase App Check 🟡 **P1**

Protects your backend from abuse (bots, scrapers):

- [ ] **Enable App Check**
  1. Firebase Console > Project Settings > App Check
  2. Register your iOS app
  3. Provider: **DeviceCheck** (for production)
  4. Enable enforcement for:
     - ✅ Firestore
     - ✅ Authentication
     - ✅ Storage (if using)

**Why:** Ensures only your legitimate iOS app can access Firebase services.

### Firebase Authentication Security 🟡 **P1**

- [ ] **Enable Email Enumeration Protection**
  1. Firebase Console > Authentication > Settings
  2. User account management
  3. Enable "Email enumeration protection"

- [ ] **Configure Password Policy**
  1. Authentication > Settings > Password policy
  2. Minimum length: 8 characters
  3. Require: Uppercase + Lowercase + Number + Special char

- [ ] **Enable Multi-Factor Authentication (Optional)** ⚪ **P3**
  1. Authentication > Sign-in method
  2. Multi-factor authentication > Enable SMS or TOTP

### Firebase Storage Rules (if using) 🟡 **P1**

If you implement photo sharing:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // Squad session photos
    match /squads/{squadId}/sessions/{sessionId}/photos/{photoId} {
      // Only authenticated squad members can upload
      allow write: if request.auth != null &&
                      request.resource.size < 5 * 1024 * 1024 && // 5MB limit
                      request.resource.contentType.matches('image/.*');

      // Anyone can read (for now - adjust based on your privacy needs)
      allow read: if request.auth != null;
    }

    // User profile pictures
    match /users/{userId}/profile.{ext} {
      allow write: if request.auth.uid == userId &&
                      request.resource.size < 2 * 1024 * 1024 && // 2MB limit
                      request.resource.contentType.matches('image/.*');
      allow read: if request.auth != null;
    }
  }
}
```

---

## 📱 iOS App Security

### Info.plist Privacy Descriptions 🔴 **P0**

Ensure all privacy descriptions are clear and accurate:

- [ ] **Location Permissions**
  ```xml
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>RunningMan needs your location to track your running route and share it with your squad in real-time.</string>

  <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
  <string>RunningMan tracks your location in the background during active running sessions to provide real-time updates to your squad.</string>
  ```

- [ ] **HealthKit Permissions**
  ```xml
  <key>NSHealthShareUsageDescription</key>
  <string>RunningMan reads your heart rate and workout data to display accurate running statistics.</string>

  <key>NSHealthUpdateUsageDescription</key>
  <string>RunningMan saves your running sessions to the Health app for comprehensive fitness tracking.</string>
  ```

### Keychain Security 🟡 **P1**

Your `KeychainHelper.swift` already implements keychain storage. Verify:

- [ ] **Keychain Access Group** (for app extensions/widgets)
  ```swift
  let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: "com.gi.joe.RunningMan",
      kSecAttrAccessGroup as String: "group.com.gi.joe.RunningMan", // If using app groups
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock, // Good balance
      // ...
  ]
  ```

- [ ] **Biometric Protection** (for sensitive actions)
  Your `BiometricAuthHelper.swift` is already implemented ✅

### Network Security 🟡 **P1**

- [ ] **App Transport Security (ATS)**
  Ensure your `Info.plist` enforces HTTPS:
  ```xml
  <key>NSAppTransportSecurity</key>
  <dict>
      <key>NSAllowsArbitraryLoads</key>
      <false/>
  </dict>
  ```

- [ ] **Certificate Pinning** (Optional, Advanced) ⚪ **P3**
  For production, consider pinning Firebase certificates

### Code Obfuscation 🟢 **P2**

- [ ] **Obfuscate Sensitive Strings**
  Avoid hardcoding secrets in code:
  ```swift
  // ❌ Bad
  let apiKey = "sk_live_1234567890"

  // ✅ Good - use environment variables or secure configuration
  let apiKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String
  ```

---

## 🧪 Security Testing

### Firebase Emulator Suite 🔴 **P0**

Test your security rules locally before deploying:

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize emulators (if not already done)
firebase init emulators
# Select: Firestore, Authentication

# Start emulators
firebase emulators:start

# In another terminal, run your tests
# Your app should connect to localhost:8080 for Firestore
```

**Update AppDelegate for emulator:**
```swift
#if DEBUG
import FirebaseAuth
import FirebaseFirestore

// In your app initialization
let settings = Firestore.firestore().settings
settings.host = "localhost:8080"
settings.isSSLEnabled = false
Firestore.firestore().settings = settings

Auth.auth().useEmulator(withHost: "localhost", port: 9099)
#endif
```

### Security Rules Unit Tests 🟡 **P1**

Create `firestore.test.js`:

```javascript
const { assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { initializeTestEnvironment } = require('@firebase/rules-unit-testing');

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'squadrun-f78b3',
    firestore: {
      rules: fs.readFileSync('firestore.rules', 'utf8'),
    },
  });
});

test('Authenticated user can create squad', async () => {
  const alice = testEnv.authenticatedContext('alice');
  await assertSucceeds(
    alice.firestore().collection('squads').add({
      name: 'Morning Runners',
      members: { alice: 'admin' },
    })
  );
});

test('Unauthenticated user cannot read squads', async () => {
  const unauth = testEnv.unauthenticatedContext();
  await assertFails(
    unauth.firestore().collection('squads').doc('squad1').get()
  );
});

// Add more tests...
```

**Run tests:**
```bash
npm test
```

### Penetration Testing Checklist 🟢 **P2**

- [ ] Test Firebase rules with different user roles
- [ ] Attempt to access other users' data
- [ ] Test API key restrictions
- [ ] Verify session timeout and token refresh
- [ ] Test input validation (XSS, injection attacks)
- [ ] Verify HTTPS enforcement
- [ ] Test biometric bypass attempts

---

## 📊 Monitoring & Alerts

### Firebase Security Monitoring 🟡 **P1**

- [ ] **Enable Firebase Crashlytics**
  ```swift
  // In AppDelegate
  FirebaseCrashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
  ```

- [ ] **Set Up Firebase Performance Monitoring**
  1. Add dependency: `FirebasePerformance`
  2. Monitor slow network requests
  3. Track app startup time

- [ ] **Configure Usage Alerts**
  1. Firebase Console > Project Settings > Usage and Billing
  2. Set budget alerts (Firestore reads/writes, Storage, Functions)

### Security Audit Schedule 🟢 **P2**

- [ ] **Weekly:** Review Firebase Console logs for anomalies
- [ ] **Monthly:** Update dependencies (`swift package update`)
- [ ] **Quarterly:** Full security audit (use this checklist)
- [ ] **Annually:** Third-party penetration testing

---

## 🚨 Incident Response Plan

### If API Key is Compromised 🔴 **P0**

1. **Immediately:**
   - [ ] Delete the compromised key in Google Cloud Console
   - [ ] Create a new API key with restrictions
   - [ ] Update `GoogleService-Info.plist` in your app
   - [ ] Force update for all users (or rotate gracefully)

2. **Within 24 hours:**
   - [ ] Review Firebase logs for unauthorized access
   - [ ] Audit Firestore data for tampering
   - [ ] Notify users if data was accessed

3. **Within 1 week:**
   - [ ] Conduct post-mortem
   - [ ] Update security procedures
   - [ ] Implement additional monitoring

### If User Data is Breached 🔴 **P0**

1. **Immediately:**
   - [ ] Isolate affected systems
   - [ ] Disable compromised accounts
   - [ ] Preserve logs and evidence

2. **Within 72 hours (GDPR requirement):**
   - [ ] Notify affected users
   - [ ] Report to relevant authorities (if required by law)
   - [ ] Offer remediation (password reset, etc.)

---

## ✅ Final Checklist

Before launching to production:

- [ ] All P0 items completed
- [ ] All P1 items completed
- [ ] Firebase security rules tested
- [ ] API keys restricted
- [ ] App Check enabled
- [ ] Privacy descriptions accurate
- [ ] Security rules unit tests passing
- [ ] Manual penetration testing done
- [ ] Monitoring and alerts configured
- [ ] Incident response plan documented
- [ ] Team trained on security procedures

---

## 📚 Resources

- [Firebase Security Best Practices](https://firebase.google.com/support/guides/security-checklist)
- [OWASP Mobile Security Project](https://owasp.org/www-project-mobile-security/)
- [Apple iOS Security Guide](https://support.apple.com/guide/security/welcome/web)
- [GDPR Compliance Guide](https://gdpr.eu/developers/)

---

**Last Updated:** January 8, 2026
**Next Review:** April 8, 2026

**Responsible:** Development Team
**Approved By:** [Your Name/Title]
