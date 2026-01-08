# 🚀 Dependency Setup Guide - RunningMan

This guide will help you set up the project with proper dependency management using Swift Package Manager.

---

## 🎯 Quick Start

### Prerequisites

- macOS 13.0+ (Ventura or later)
- Xcode 16.0+
- Swift 6.0+
- Git
- Firebase account with project created

---

## 📦 Option 1: Create Xcode Project with SPM (Recommended)

This is the standard approach for iOS applications.

### Step 1: Create Xcode Project

```bash
# Open Xcode
# File > New > Project
# Select: iOS > App
# Product Name: RunningMan
# Organization Identifier: com.gi.joe
# Interface: SwiftUI
# Language: Swift
# Use Core Data: NO
# Include Tests: YES

# Or use this if you have command line tools:
# Note: This creates a basic structure - you'll import your existing files
```

### Step 2: Import Existing Source Files

1. In Xcode, delete the default `ContentView.swift` and other boilerplate files
2. Drag and drop all `.swift` files from the repository into the project navigator
3. Ensure files are added to the `RunningMan` target
4. Add `Assets.xcassets`, `GoogleService-Info.plist`, and `Info.plist`

### Step 3: Add Firebase via SPM

1. In Xcode: `File > Add Packages...`
2. Enter URL: `https://github.com/firebase/firebase-ios-sdk`
3. Dependency Rule: **Up to Next Major Version** `11.5.0`
4. Click "Add Package"
5. Select the following products:
   - ✅ FirebaseAuth
   - ✅ FirebaseCore
   - ✅ FirebaseFirestore
6. Click "Add Package"

### Step 4: Configure Project Settings

**General Tab:**
- Deployment Target: iOS 17.0
- Bundle Identifier: `com.gi.joe.RunningMan`

**Signing & Capabilities:**
- Add capabilities:
  - ✅ Background Modes (Location updates, Background fetch)
  - ✅ Push Notifications
  - ✅ HealthKit (if using health features)

**Info Tab:**
Add privacy usage descriptions (should already be in Info.plist):
- Privacy - Location When In Use Usage Description
- Privacy - Location Always and When In Use Usage Description
- Privacy - Health Share Usage Description
- Privacy - Health Update Usage Description

### Step 5: Build and Run

```bash
# In Xcode:
# Select your device or simulator
# Product > Build (Cmd + B)
# Product > Run (Cmd + R)
```

---

## 📦 Option 2: Swift Package Manager Only (Modular Architecture)

**⚠️ Advanced:** This approach is for modularizing your app into reusable Swift Packages.

### Step 1: Create Package.swift

```bash
cd /home/user/RunningMan
touch Package.swift
```

### Step 2: Configure Package.swift

Add the following content:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RunningMan",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "RunningManCore",
            targets: ["Core"]
        ),
        .library(
            name: "RunningManFeatures",
            targets: ["Features"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk",
            from: "11.5.0"
        ),
    ],
    targets: [
        // Core module
        .target(
            name: "Core",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
            ],
            path: "Core"
        ),

        // Features module
        .target(
            name: "Features",
            dependencies: ["Core"],
            path: "Features"
        ),

        // Tests
        .testTarget(
            name: "RunningManTests",
            dependencies: ["Core", "Features"]
        ),
    ]
)
```

### Step 3: Reorganize Files (if needed)

Ensure your directory structure matches:

```
RunningMan/
├── Package.swift
├── Core/
│   ├── Services/
│   ├── Models/
│   └── ...
├── Features/
│   ├── Sessions/
│   ├── Authentication/
│   └── ...
└── Tests/
    └── RunningManTests/
```

### Step 4: Resolve Dependencies

```bash
swift package resolve
swift build  # Test that it compiles
```

### Step 5: Generate Xcode Project

```bash
swift package generate-xcodeproj
open RunningMan.xcodeproj
```

**Note:** This generates an `.xcodeproj` that's tied to your Package.swift. Any changes to dependencies should be made in Package.swift.

---

## 🔧 Manual Dependency Installation (Not Recommended)

If you absolutely cannot use SPM or CocoaPods:

### Using Pre-built Firebase XCFrameworks

```bash
# Download Firebase iOS SDK
curl -L https://github.com/firebase/firebase-ios-sdk/releases/download/11.5.0/Firebase.zip -o Firebase.zip
unzip Firebase.zip

# Manually add XCFrameworks to Xcode:
# 1. Drag FirebaseAuth.xcframework, FirebaseCore.xcframework, FirebaseFirestore.xcframework
#    into your Xcode project
# 2. In target settings > General > Frameworks, Libraries, and Embedded Content
#    Set each to "Do Not Embed"
```

**⚠️ Warning:** This approach is error-prone and not recommended.

---

## 🔐 Firebase Configuration

### Step 1: Download GoogleService-Info.plist

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `squadrun-f78b3`
3. Project Settings > Your Apps > iOS App
4. Download `GoogleService-Info.plist`
5. **Replace** the existing one in the repo (or verify it matches)

### Step 2: Verify Configuration

Open `GoogleService-Info.plist` and verify:
- `BUNDLE_ID` matches `com.gi.joe.RunningMan`
- `PROJECT_ID` is `squadrun-f78b3`

### Step 3: Initialize Firebase in App

Your `RunningManApp.swift` should already have:

```swift
import SwiftUI
import FirebaseCore

@main
struct RunningManApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

---

## 🧪 Verification Checklist

After setup, verify everything works:

```bash
# 1. Dependencies resolved
swift package resolve  # (if using Package.swift)

# 2. Project builds successfully
# In Xcode: Cmd + B

# 3. No import errors
# Check that all Firebase imports resolve

# 4. Firebase initializes
# Run the app and check console for Firebase initialization logs

# 5. Firebase services work
# Try logging in (should connect to Firebase Auth)
```

---

## 📊 Dependency Versions

| Package | Version | Release Date | Status |
|---------|---------|--------------|--------|
| Firebase iOS SDK | 11.5.0 | Jan 2026 | ✅ Latest |

**Pinned Dependencies (Package.resolved):**
After running `swift package resolve`, Xcode creates `Package.resolved` which locks exact versions. **Commit this file** to ensure reproducible builds.

---

## 🔄 Updating Dependencies

### Update All Dependencies

```bash
# In Xcode:
File > Packages > Update to Latest Package Versions

# Or via command line:
swift package update
```

### Update Specific Package

```bash
# In Xcode:
File > Packages > Resolve Package Versions

# Or edit Package.swift and change version constraint:
.package(url: "https://github.com/firebase/firebase-ios-sdk", from: "11.6.0")
```

### Check for Updates

```bash
swift package show-dependencies --format json
```

---

## 🐛 Troubleshooting

### Issue: "Package.resolved conflicts"

```bash
# Reset package cache
rm -rf .build
rm Package.resolved
swift package resolve
```

### Issue: "Module 'Firebase' not found"

**Solution:**
1. Ensure Firebase packages are added to your target
2. Clean build folder: `Product > Clean Build Folder` (Cmd + Shift + K)
3. Restart Xcode

### Issue: "Signing certificate not found"

**Solution:**
1. Xcode > Preferences > Accounts
2. Add your Apple ID
3. Select your team in project settings

### Issue: "Firebase not initializing"

**Solution:**
1. Verify `GoogleService-Info.plist` is in the project
2. Check it's included in the target (Target Membership)
3. Ensure `FirebaseApp.configure()` is called in `init()`

---

## 📚 Additional Resources

- [Firebase iOS SDK Releases](https://github.com/firebase/firebase-ios-sdk/releases)
- [Swift Package Manager Documentation](https://swift.org/package-manager/)
- [Xcode SPM Guide](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app)
- [Firebase iOS Setup Guide](https://firebase.google.com/docs/ios/setup)

---

## 🎯 Next Steps

After completing this setup:

1. ✅ Review `DEPENDENCY_AUDIT_REPORT.md` for security recommendations
2. ✅ Test Firebase authentication and Firestore connectivity
3. ✅ Configure Firebase security rules (see `CLAUDE.md`)
4. ✅ Set up Firebase Emulator for local testing
5. ✅ Configure API key restrictions in Google Cloud Console

---

**Last Updated:** January 8, 2026
**For Issues:** Open a GitHub issue or consult the Firebase documentation
