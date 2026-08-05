# VMS — Release Build & Play Console Upload Guide

How to build a signed release APK / AAB for **com.synergynoida.vms** and upload it to the Google Play Console.

---

## 1. What makes up the signing setup

Three pieces have to agree with each other:

| Piece | Location | Purpose |
|---|---|---|
| Keystore | `/Users/synergy/Documents/vms/synergynoidavms` | The private key that signs the app |
| `key.properties` | `android/key.properties` | Tells Gradle where the keystore is + its passwords |
| Signing config | `android/app/build.gradle.kts` | Reads `key.properties` and applies it to the `release` build type |

### Keystore

Already created. Details:

```
Alias:     key0
Type:      PKCS12
Key:       2048-bit RSA, SHA256withRSA
Owner:     CN=gatepro, OU=synergy, O=synergy, L=noida, ST=up, C=91
Valid to:  21 Dec 2053
```

Inspect it any time with:

```bash
keytool -list -v -keystore /Users/synergy/Documents/vms/synergynoidavms
```

> **The keystore is irreplaceable.** If you lose it you can never publish an update to the same Play listing — you'd have to publish a brand-new app under a new package name. Back it up somewhere outside the project folder (password manager, encrypted drive). Never commit it to git.

### `android/key.properties`

```properties
storePassword=123456
keyPassword=123456
keyAlias=key0
storeFile=/Users/synergy/Documents/vms/synergynoidavms
```

This file is already listed in `android/.gitignore`, so it stays out of the repo.

### Signing config in `android/app/build.gradle.kts`

This file is **Kotlin DSL** (`.kts`), not Groovy — the syntax differs. The working config:

```kotlin
import java.util.Properties
import java.io.FileInputStream

plugins { /* ... */ }

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    // ...
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}
```

Notes on why it's written this way:

- `import` statements must be at the very top of a `.kts` file, above `plugins {}`.
- `val` / `Properties()` — Kotlin has no `def` and no `new`.
- `create("release")` — in Kotlin DSL you create a named signing config; `release { }` alone only works for build types that already exist.
- `keyAlias = ...` — Kotlin needs the `=`; Groovy's space-separated `keyAlias value` is a syntax error here.
- `rootProject.file("key.properties")` resolves to `android/key.properties`, because the app module's root project is `android/`.
- The `if (keystorePropertiesFile.exists())` fallback means a fresh clone without `key.properties` still builds with debug keys instead of failing.

---

## 2. Build commands

Run all of these from the project root: `/Users/synergy/Documents/vms`

### App Bundle (.aab) — this is what Play Console needs

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### APK — for direct install / sideloading / testing

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Split APKs per architecture (smaller downloads, not for Play)

```bash
flutter build apk --release --split-per-abi
```

### Clean rebuild, if something looks stale

```bash
flutter clean && flutter pub get && flutter build appbundle --release
```

---

## 3. Verify the bundle is signed with the right key

```bash
jarsigner -verify -verbose:summary -certs build/app/outputs/bundle/release/app-release.aab
```

You want to see `jar verified.` and `CN=gatepro, OU=synergy, ...`.

If it says `CN=Android Debug` instead, the release signing config was not applied — check that `key.properties` exists and the `storeFile` path is correct.

---

## 4. Version numbers

Play Console rejects any upload whose `versionCode` was already used. The version comes from `pubspec.yaml`:

```yaml
version: 1.0.0+1
#        ^^^^^ ^
#        name  code
```

Before **every** new upload, bump the number after `+`:

```yaml
version: 1.0.1+2
```

Then rebuild. `versionName` (`1.0.1`) is what users see; `versionCode` (`2`) must strictly increase.

---

## 5. Upload to Play Console

1. Go to <https://play.google.com/console> and open (or create) the app.
2. **Release → Testing → Internal testing** for a first trial run, or **Release → Production** to go live.
3. Click **Create new release**.
4. On the first release Play will ask about **Play App Signing** — accept it. Google then holds the final signing key, and your `synergynoidavms` keystore becomes the *upload* key. Keep backing it up anyway; you need it for every future upload.
5. Upload `app-release.aab`.
6. Fill in the release notes, then **Review release → Start rollout**.

Before the first production release Play also requires the store listing, content rating questionnaire, data safety form, target audience, and a privacy policy URL to be completed.

---

## 6. Troubleshooting

**`Unresolved reference: def` / `Expecting an element` in build.gradle.kts**
Groovy syntax in a Kotlin DSL file. See section 1.

**`Keystore file not found` / `storeFile is null`**
The path in `key.properties` is wrong or the file moved. It must be an absolute path, or relative to `android/app/`.

**`Failed to read key key0 from store ... wrong password`**
`storePassword` / `keyPassword` in `key.properties` don't match the keystore. Verify with:
```bash
keytool -list -v -keystore /Users/synergy/Documents/vms/synergynoidavms
```

**"You uploaded an APK that is not signed with the upload certificate"**
The build used debug keys, or a different keystore. Re-run the `jarsigner -verify` check in section 4.

**"Version code 1 has already been used"**
Bump `version:` in `pubspec.yaml` — section 4.

**Bundle is large (~53 MB)**
Normal for a Flutter app with Firebase. Play delivers per-device slices from the AAB, so the actual user download is considerably smaller than the bundle.

---

## 7. Quick reference

```bash
# Build the bundle for Play
flutter build appbundle --release

# Build an installable APK
flutter build apk --release

# Confirm the signature
jarsigner -verify -verbose:summary -certs build/app/outputs/bundle/release/app-release.aab

# Inspect the keystore
keytool -list -v -keystore /Users/synergy/Documents/vms/synergynoidavms
```
