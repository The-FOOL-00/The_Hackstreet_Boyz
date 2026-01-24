# 🔥 FIREBASE PHONE AUTH - STEP BY STEP SETUP

## Your SHA Certificates

**SHA-1:** `C8:BC:40:BE:5E:6F:6B:88:63:A7:3B:F8:B2:7C:10:B5:6A:53:DE:89`

**SHA-256:** `7A:A3:4C:1F:13:A0:BC:62:E9:B4:5D:09:7A:3F:A6:5D:FF:2C:18:00:27:60:9B:CD:8D:DB:83:0D:B8:93:DE:4B`

---

## Step 1: Add SHA Certificates to Firebase (CRITICAL!)

1. Open: https://console.firebase.google.com/project/luscid-9921a/settings/general/android:com.example.luscid
2. Scroll to **"Your apps"** section
3. Find your Android app: **com.example.luscid**
4. Click **"Add fingerprint"**
5. Paste SHA-1: `C8:BC:40:BE:5E:6F:6B:88:63:A7:3B:F8:B2:7C:10:B5:6A:53:DE:89`
6. Click **"Save"**
7. Click **"Add fingerprint"** again
8. Paste SHA-256: `7A:A3:4C:1F:13:A0:BC:62:E9:B4:5D:09:7A:3F:A6:5D:FF:2C:18:00:27:60:9B:CD:8D:DB:83:0D:B8:93:DE:4B`
9. Click **"Save"**

---

## Step 2: Enable Phone Authentication

1. Open: https://console.firebase.google.com/project/luscid-9921a/authentication/providers
2. Click **"Phone"** provider
3. Toggle **"Enable"** switch ON
4. Click **"Save"**

---

## Step 3: Add Test Phone Numbers (For Testing Without SMS)

1. In the Phone provider settings (same page as Step 2)
2. Expand **"Phone numbers for testing"**
3. Add these test numbers:

| Phone Number | Verification Code |
|--------------|-------------------|
| +1 650-555-3434 | 123456 |
| +91 9999999999 | 123456 |

4. Click **"Save"**

---

## Step 4: Enable Required APIs in Google Cloud

1. Open: https://console.cloud.google.com/apis/library?project=luscid-9921a
2. Search for **"Android Device Verification API"**
3. Click **"Enable"**
4. Search for **"Identity Toolkit API"** 
5. Click **"Enable"**

---

## Step 5: Test Phone Authentication

### Option A: Use Test Phone Number (No SMS)

1. Open the Luscid app on your device
2. Scroll down to bottom
3. Click **"Phone Login (Test)"** button
4. Select country: **+91** (India) or **+1** (USA)
5. Enter: `9999999999` (if +91) or `6505553434` (if +1)
6. Click **"Send OTP"**
7. Enter code: `123456`
8. Click **"Verify"**

### Option B: Use Real Phone Number

1. Click **"Phone Login (Test)"** button
2. Select your country code
3. Enter your real phone number
4. Click **"Send OTP"**
5. Check your phone for SMS
6. Enter the 6-digit code
7. Click **"Verify"**

---

## ⚠️ Common Errors & Fixes

### Error: "We have blocked all requests from this device"

**Cause:** SHA certificates not added to Firebase

**Fix:** Complete Step 1 above

### Error: "invalid-phone-number"

**Cause:** Wrong phone format

**Fix:** Use format `+[country code][number]` (e.g., `+919876543210`)

### Error: "missing-phone-number"

**Cause:** Empty phone field

**Fix:** Enter a valid phone number

### No SMS Received

1. Use test phone numbers first (Step 3)
2. Check SMS quota in Firebase Console
3. Wait a few minutes and try again
4. Check phone has signal

---

## 🔍 Verify Setup

Run this checklist:

- [ ] SHA-1 added to Firebase Console
- [ ] SHA-256 added to Firebase Console  
- [ ] Phone provider enabled in Firebase
- [ ] Test phone numbers added
- [ ] Android Device Verification API enabled
- [ ] Identity Toolkit API enabled
- [ ] App running on device
- [ ] "Phone Login (Test)" button visible

---

## 📱 Quick Test

```bash
# 1. Restart app
flutter run

# 2. On device:
#    - Scroll to bottom of home screen
#    - Click "Phone Login (Test)"
#    - Enter: +91 9999999999
#    - Click "Send OTP"
#    - Enter: 123456
#    - Click "Verify"

# Expected: Should navigate to Profile Setup screen
```

---

## 🎯 Current Status

### ✅ Already Done
- Phone auth service implemented
- OTP verification screen created  
- Profile setup screen created
- Android permissions added
- SHA certificates generated
- Test button added to home screen

### 🔧 To Do Now
1. Add SHA certificates to Firebase (Step 1)
2. Enable Phone provider (Step 2)
3. Add test numbers (Step 3)
4. Enable APIs (Step 4)
5. Test with test number (Step 5A)

---

## 📞 Need Help?

**Firebase Console:** https://console.firebase.google.com/project/luscid-9921a

**Your Project ID:** luscid-9921a

**Your Package:** com.example.luscid

**SHA-1:** C8:BC:40:BE:5E:6F:6B:88:63:A7:3B:F8:B2:7C:10:B5:6A:53:DE:89
