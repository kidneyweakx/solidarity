# App Store Submission Guide for Solid(ar)ity

**Version:** 1.0.0
**Date:** 2025-01-15

---

## 📋 Pre-Submission Checklist

### ✅ App Information
- [x] App Name: **Solid(ar)ity**
- [x] Subtitle: Privacy-First Business Card Sharing
- [x] Category: **Business** / Networking
- [x] Content Rating: **4+** (No objectionable content)
- [x] Price: **Free** (with optional in-app purchases for premium features)

### ✅ App Description

**Short Description (170 characters):**
```
Privacy-first business card sharing with zero-knowledge proofs. Share contacts locally without servers. Your data never leaves your device.
```

**Full Description:**
```
Solid(ar)ity: Privacy-Preserving Business Card Sharing

ZERO DATA COLLECTION
Your business cards stay on your device. No servers, no cloud, no tracking.

PEER-TO-PEER SHARING
• Share via proximity (MultipeerConnectivity)
• Generate QR codes
• Export to Apple Wallet
• AirDrop integration

ZERO-KNOWLEDGE PRIVACY
• Advanced cryptography (Semaphore protocol)
• Prove group membership without revealing identity
• Selective disclosure: share only what you choose
• Privacy levels: Public, Professional, Personal

KEY FEATURES
• Offline-first: works without internet
• Local encryption (AES-GCM)
• Group management with ZK proofs
• Apple Wallet integration
• No account required

SECURITY BY DESIGN
• Private keys stored in iOS Keychain
• No third-party analytics or tracking
• Open-source: verify our privacy claims
• Industry-standard cryptography

PERFECT FOR:
• Professionals protecting their privacy
• Conference networking
• Business events
• Privacy-conscious individuals

TRANSPARENCY:
Open-source project. View our code:
https://github.com/kidneyweakx/solidarity
```

### ✅ Keywords
```
business card, privacy, networking, QR code, zero knowledge, P2P, local-first, encryption, contact sharing, professional networking
```

### ✅ Screenshots Required
- [ ] 6.7" (iPhone 14 Pro Max): 5-10 screenshots
- [ ] 6.5" (iPhone 11 Pro Max): 5-10 screenshots
- [ ] 5.5" (iPhone 8 Plus): Optional

**Screenshot Ideas:**
1. Empty wallet view (business card creation)
2. Card list view with sample cards
3. QR code sharing screen
4. Proximity sharing (nearby peers)
5. Group management view
6. Privacy settings (selective disclosure)
7. Apple Wallet pass generation
8. ZK proof generation (optional, with explanation)

### ✅ App Privacy Details

**Data Collection: NONE**
- [x] We do not collect data

**Data Types NOT Collected:**
- Contact Info
- User Content
- Identifiers
- Usage Data
- Diagnostics

**Privacy Practices:**
- [x] Data is not collected
- [x] Data is not linked to user
- [x] Data is not used for tracking

### ✅ App Store Connect - Privacy Section

**Privacy Policy URL:**
```
https://github.com/kidneyweakx/solidarity/blob/main/PRIVACY_POLICY.md
```

**Terms of Service URL:**
```
https://github.com/kidneyweakx/solidarity/blob/main/TERMS_OF_SERVICE.md
```

**Encryption Compliance Documentation:**
```
https://github.com/kidneyweakx/solidarity/blob/main/ENCRYPTION_EXPORT_COMPLIANCE.md
```
(如果審核詢問加密相關問題時提供)

---

## 🔐 Cryptography and Export Compliance

### Encryption Declaration

**Does your app use encryption?** ✅ YES

**Purpose of Encryption:**
1. **Local Data Protection** (AES-GCM)
   - Encrypts business cards stored on device
   - Encrypts group membership data
   - Protects user privacy

2. **Peer-to-Peer Communication** (Apple MultipeerConnectivity)
   - Uses Apple's built-in TLS encryption
   - Secure device-to-device sharing

3. **Zero-Knowledge Proofs** (Semaphore Protocol)
   - Privacy-preserving identity verification
   - Cryptographic group membership proofs
   - NO financial transactions

**Export Compliance:**
- [x] Encryption is for **user authentication and privacy protection only**
- [x] NOT used for financial transactions
- [x] NOT a cryptocurrency wallet
- [x] Uses standard iOS frameworks (PassKit, Keychain)
- [x] Exempt from export compliance (Category 5 Part 2)

**ECCN Classification:** `5D992.c` or exempt under category 5 Part 2
(Encryption for authentication and privacy, not for financial transactions)

---

## 🛡️ Zero-Knowledge Proof Technology Explanation

### For App Review Team

**What is Zero-Knowledge Proof (ZKP)?**

Zero-Knowledge Proofs are cryptographic methods that allow one party to prove a statement is true WITHOUT revealing any additional information.

**Example in Solid(ar)ity:**
- User wants to prove: "I am a member of Company X employees"
- Without revealing: Which specific employee they are
- The proof confirms membership without exposing identity

**Why This is NOT Cryptocurrency:**
- No blockchain transactions
- No financial transfers
- No tokens or coins
- No wallet functionality (besides Apple Wallet for contact cards)
- Used solely for **privacy-preserving identity verification**

**Technical Details:**
- **Protocol:** Semaphore (audited, open-source ZK protocol)
- **Framework:** Mopro (mobile ZK proof generation)
- **Computation:** All on-device, no network calls
- **Storage:** Private keys in iOS Keychain (hardware-backed)

**Privacy Benefits:**
1. Verify group membership without doxxing users
2. Selective disclosure: share minimal information
3. Unlinkability: different proofs can't be correlated

**Use Cases in App:**
- Professional group verification (e.g., "Conference attendees")
- Alumni networks
- Company employee verification
- Privacy-preserving credential sharing

**NOT Used For:**
- Financial transactions
- Cryptocurrency payments
- Blockchain interactions
- Money transfers

---

## 🧪 Testing Instructions for App Review

### Test Account
**No account required!** The app works completely offline.

### How to Test Core Features:

#### 1. Create a Business Card
1. Open app → Tap "Add Card"
2. Fill in sample information (Name, Title, Company)
3. Save card

#### 2. Test QR Code Sharing
1. Select a card → Tap QR icon
2. QR code displays immediately
3. (Optional) Scan with another device

#### 3. Test Proximity Sharing
⚠️ **Requires two physical devices or simulators with network access**
1. Device A: Tap "Share" → Start advertising
2. Device B: Tap "Matching" tab → Browse for nearby
3. Device B should see Device A
4. Connect and exchange cards

**Note:** Proximity sharing may not work in simulator networking mode. Testing on physical devices recommended.

#### 4. Test Group Management (ZK Feature)
1. Tap "ID" tab → "Group Management"
2. Create a test group (e.g., "Test Group 2025")
3. App generates ZK identity automatically (stored in Keychain)
4. Add members manually or via proximity

#### 5. Test Apple Wallet Export
1. Select a card → Tap "Add to Wallet"
2. Pass is generated locally
3. Add to Apple Wallet (or preview)

#### 6. Test Privacy Settings
1. Edit a card → Tap privacy icon
2. Configure selective disclosure levels
3. Test sharing with different privacy levels

### What Reviewers Should Verify:

✅ **Privacy:**
- No network requests to external servers (use network inspector)
- All data stored locally (check app container)
- No analytics or tracking SDKs

✅ **Functionality:**
- Business card CRUD works
- QR codes generate correctly
- P2P sharing works (if testable)
- Apple Wallet integration functions

✅ **Cryptography:**
- Used for privacy/security only
- No financial transactions
- No cryptocurrency features

✅ **User Experience:**
- Clear onboarding (if applicable)
- No crashes or major bugs
- Privacy policy accessible

---

## 📝 Review Notes / Message to Apple Review Team

```
Dear App Review Team,

Thank you for reviewing Solid(ar)ity!

KEY POINTS:

1. PRIVACY-FIRST ARCHITECTURE
   - Zero data collection
   - No servers or cloud services
   - All data stored locally on user's device
   - No third-party SDKs for analytics or tracking

2. CRYPTOGRAPHY USAGE
   - Encryption is for LOCAL DATA PROTECTION and USER AUTHENTICATION only
   - NOT a cryptocurrency wallet or financial app
   - Zero-Knowledge Proofs used for privacy-preserving identity verification
   - Compliant with export regulations (Category 5 Part 2 exempt)

3. ZERO-KNOWLEDGE PROOF TECHNOLOGY
   - Uses Semaphore protocol (industry-standard, audited)
   - Purpose: Verify group membership without revealing identity
   - Example: "I am a conference attendee" without disclosing which one
   - NOT related to cryptocurrency or blockchain transactions

4. TESTING NOTES
   - No account required
   - Proximity sharing requires two devices (MultipeerConnectivity)
   - May test on simulator, but P2P works best on physical devices
   - All features work offline

5. VERSION 1.0.0 SCOPE
   - ENS (Ethereum Name Service) integration is planned for v1.1+
   - Current version (v1.0.0) focuses on core privacy and P2P sharing
   - No blockchain or Web3 features in this submission
   - Future versions may include optional ENS username resolution

6. OPEN SOURCE
   - Source code: https://github.com/kidneyweakx/solidarity
   - Privacy policy and terms available in-app and on GitHub

If you have questions about ZK technology or cryptography usage, please reference:
- Semaphore Protocol: https://semaphore.appliedzkp.org/
- Mopro Framework: https://zkmopro.org/

We're happy to provide additional clarification if needed.

Best regards,
Solid(ar)ity Development Team
```

---

## 🚨 Common Rejection Reasons & How We've Addressed Them

### Guideline 2.1 - App Completeness
✅ **Status:** App is feature-complete
- All core features implemented
- No placeholder content
- No "Coming Soon" features blocking functionality

### Guideline 2.3.10 - Accurate Metadata
✅ **Status:** Metadata is accurate
- Description matches actual functionality
- Screenshots reflect current app version
- No misleading claims

### Guideline 5.1.1 - Privacy: Data Collection and Storage
✅ **Status:** Zero data collection
- Privacy manifest included (PrivacyInfo.xcprivacy)
- Privacy policy clearly states no data collection
- No third-party SDKs

### Guideline 5.3.3 - Cryptography (Export Compliance)
✅ **Status:** Compliant
- Encryption for authentication and privacy only
- No financial transactions
- Not a cryptocurrency app
- Exempt under Category 5 Part 2

---

## 📄 Required Documents Included

- [x] `PRIVACY_POLICY.md` - Detailed privacy policy
- [x] `TERMS_OF_SERVICE.md` - Legal terms
- [x] `README.md` - Project overview
- [x] `PrivacyInfo.xcprivacy` - Apple privacy manifest
- [x] `APP_STORE_READINESS_REPORT.md` - Pre-submission checklist (if needed)

---

## 🎯 Post-Approval Checklist

After approval:
- [ ] Monitor crash reports (via Xcode Organizer)
- [ ] Set up GitHub Issues for user feedback
- [ ] Create release notes for future updates
- [ ] Plan feature roadmap (v1.1, v1.2)

---

## 📞 Support & Contact

**For Apple Review Team:**
- GitHub Issues: https://github.com/kidneyweakx/solidarity/issues
- Email: (Create GitHub issue for fastest response)

**For Users:**
- In-app: Settings → Help & Support
- GitHub: https://github.com/kidneyweakx/solidarity

---

**Good luck with the submission! 🚀**

*Last Updated: 2025-01-15*
