# Firebase Phone Authentication Setup Guide

## 🔥 Firebase Console Configuration

### Step 1: Enable Phone Authentication

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **luscid-9921a**
3. Navigate to **Authentication** → **Sign-in method**
4. Click on **Phone** provider
5. Click **Enable**
6. Save

### Step 2: Configure Test Phone Numbers (Optional for Testing)

1. In the Phone provider settings
2. Scroll to **Phone numbers for testing**
3. Add test numbers with OTP codes:
   - Phone: `+1 650-555-3434` → Code: `654321`
   - Phone: `+91 99999 99999` → Code: `123456`
4. These can be used without sending real SMS

### Step 3: Android Configuration

#### SHA-1 Certificate (Required!)

Firebase Phone Auth requires SHA-1 certificate fingerprint:

```bash
# Get debug SHA-1 (for development)
cd android
./gradlew signingReport

# OR on Windows
gradlew.bat signingReport
```

Look for the **SHA1** under `Variant: debug` and **SHA-256**.

#### Add SHA-1 to Firebase:

1. In Firebase Console → **Project Settings**
2. Scroll to **Your apps** section
3. Select your Android app (`com.example.luscid`)
4. Click **Add fingerprint**
5. Paste the SHA-1 certificate
6. Also add SHA-256
7. Download the updated `google-services.json`
8. Replace it in `android/app/google-services.json`

### Step 4: Enable SafetyNet (Android)

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project **luscid-9921a**
3. Enable **Android Device Verification API**
4. This helps prevent abuse

---

## 📱 Testing Phone Authentication

### Option 1: Use Test Phone Numbers

In the app, enter a test phone number you configured:
- Phone: `+1 650-555-3434`
- OTP: `654321`

### Option 2: Use Real Phone Number

1. Click **Phone Login (Test)** button on home screen
2. Select country code (default: +91 India)
3. Enter your real phone number
4. Click **Send OTP**
5. You should receive an SMS with 6-digit code
6. Enter the code on OTP verification screen
7. Click **Verify**

---

## 🐛 Troubleshooting

### Error: "We have blocked all requests from this device"

**Cause:** No SHA-1 certificate added to Firebase

**Fix:**
```bash
cd android
./gradlew signingReport
```
Copy the SHA-1 and add to Firebase Console.

### Error: "invalid-phone-number"

**Cause:** Phone number not in E.164 format

**Fix:** Ensure format is `+[country code][number]`
- ✅ Correct: `+919876543210`
- ❌ Wrong: `9876543210`, `+91 98765 43210`

### Error: "quota-exceeded"

**Cause:** Too many SMS sent in a day

**Fix:** Use test phone numbers or wait 24 hours

### No SMS Received

1. Check phone number is correct
2. Check SMS quota in Firebase Console
3. Try test phone numbers first
4. Check Android permissions are granted
5. Verify SafetyNet is enabled

---

## 🔐 Security Best Practices

### 1. Restrict API Keys

In Google Cloud Console:
1. Go to **APIs & Services** → **Credentials**
2. Find your API key
3. Click **Edit**
4. Under **Application restrictions**: Select **Android apps**
5. Add your package name: `com.example.luscid`
6. Add SHA-1 fingerprint

### 2. Set Up App Check (Recommended)

Prevents abuse of your Firebase services:
1. In Firebase Console → **App Check**
2. Register your app
3. For Android: Use Play Integrity
4. For debug builds: Add debug tokens

### 3. Implement Rate Limiting

In Firebase Realtime Database rules:
```json
{
  "rules": {
    "users": {
      "$uid": {
        ".write": "auth.uid === $uid",
        ".read": "auth.uid === $uid"
      }
    }
  }
}
```

---

## 📋 Current Status

### ✅ Completed
- Phone auth service implemented
- OTP verification screen created
- Profile setup screen created
- Android permissions added to manifest
- Firebase initialized in app

### ⚠️ Needs Configuration
- [ ] Add SHA-1 certificate to Firebase Console
- [ ] Enable Phone Authentication in Firebase Console
- [ ] Configure test phone numbers (optional)
- [ ] Enable SafetyNet API
- [ ] Test with real phone number

---

## 🚀 Quick Start Commands

```bash
# Get SHA-1 certificate
cd android
./gradlew signingReport

# Run app
flutter run

# Test phone auth
# 1. Open app
# 2. Scroll down on home screen
# 3. Click "Phone Login (Test)"
# 4. Enter phone number
# 5. Click "Send OTP"
```

---

## 📞 Support

If you encounter issues:

1. Check Firebase Console logs: **Authentication** → **Users** → **Audit logs**
2. Check Android Logcat for errors
3. Verify all steps above are completed
4. Try test phone numbers first before real numbers

---

## 🔗 Useful Links

- [Firebase Phone Auth Docs](https://firebase.google.com/docs/auth/android/phone-auth)
- [Get SHA-1 Certificate](https://developers.google.com/android/guides/client-auth)
- [Firebase Console](https://console.firebase.google.com/)
- [Google Cloud Console](https://console.cloud.google.com/)
