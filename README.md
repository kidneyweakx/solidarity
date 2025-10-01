<div align="center">
<h1>Solid(ar)ity</h1>
<p>A privacy-preserving, proximity-based business card sharing app built with zero-knowledge proofs and P2P networking.</p>

<img src="./airmeishi/Assets.xcassets/AppIcon.appiconset/1024.png" width="50%" height="50%"></img>

![License: Apache 2.0](https://img.shields.io/github/license/kidneyweakx/solidarity)
</div>

## What is Solid(ar)ity?

Solid(ar)ity is a **fully decentralized, privacy-first** business card sharing app that works entirely offline. No servers. No cloud. No tracking. Just pure peer-to-peer magic.

Exchange business cards with people nearby while maintaining complete control over your personal information through zero-knowledge proofs and selective disclosure.

### Why it matters

In a world where every interaction gets tracked, stored, and monetized, Solid(ar)ity gives you back control. Your data lives on your device. You decide what to share, when, and with whom. Period.

### Key Features

- **Truly Offline-First**: Works completely without internet—P2P networking via MultipeerConnectivity
- **Zero-Knowledge Identity**: Built on Semaphore protocol for anonymous group membership verification
- **Selective Disclosure**: Share only what's relevant—public, professional, or personal levels
- **Multiple Sharing Methods**: QR codes, AirDrop, WiFi Direct, ShareLink—whatever works for you
- **Apple Wallet Integration**: Save contacts directly to Apple Wallet with PassKit
- **Group Verification**: Create trusted circles with cryptographic proof of membership
- **No Middleman**: All data stored locally with AES-GCM encryption. No servers, ever.

## How it Works

1. **Create your card** with only the information you want to share
2. **Set privacy levels** for each field (public/professional/personal)
3. **Share nearby** via P2P, QR code, or AirDrop—no internet needed
4. **Verify membership** in trusted groups using zero-knowledge proofs
5. **Everything stays local**—your data never touches a server

## Built With

- **SwiftUI** - Native iOS interface
- **MultipeerConnectivity** - Apple's P2P networking
- **Semaphore Protocol** - Zero-knowledge proof system via [SemaphoreSwift](https://github.com/zkmopro/SemaphoreSwift)
- **Mopro** - ZK proof generation with native Swift bindings
- **PassKit** - Apple Wallet integration
- **Local Storage** - AES-GCM encrypted file system, no databases

## App Store Launch Checklist

To ship Solid(ar)ity to the App Store, here's what must be done:

### 1. **Core Functionality** ✓
- [x] Business card creation and editing
- [x] Proximity-based P2P sharing
- [x] QR code generation and scanning
- [x] Zero-knowledge proof integration
- [x] Apple Wallet (PassKit) support
- [x] Group management
- [x] Local encrypted storage

### 2. **Privacy & Compliance** 🔴 CRITICAL
- [ ] **Privacy Policy** - Required by App Store. Must explain:
  - What data is collected (even if minimal)
  - How ZK proofs work without exposing identity
  - Local-only storage policy
  - No third-party data sharing
- [ ] **Terms of Service** - Standard legal protection
- [ ] **Privacy Manifest** (`PrivacyInfo.xcprivacy`) - Required for API usage disclosure
- [ ] **App Store Privacy Labels** - Fill out accurately in App Store Connect
- [ ] Review **Info.plist** permission strings:
  - `NSLocalNetworkUsageDescription` ✓
  - `NSBonjourServices` ✓
  - `NSCameraUsageDescription` (for QR scanning)
  - `NSContactsUsageDescription` (if accessing Contacts)
  - `NSPhotoLibraryUsageDescription` (if saving QR codes)

### 3. **App Store Assets** 🔴 CRITICAL
- [ ] **App Icon** - 1024x1024px without alpha channel
- [ ] **Screenshots** (Required for all screen sizes):
  - iPhone 6.7" (iPhone 15 Pro Max)
  - iPhone 6.5" (iPhone 14 Plus)
  - iPhone 5.5" (iPhone 8 Plus) - Optional but recommended
  - iPad Pro 12.9" (if supporting iPad)
- [ ] **App Preview Videos** (Optional but highly recommended - shows P2P magic)
- [ ] **Marketing Copy**:
  - App name (30 characters max)
  - Subtitle (30 characters max)
  - Promotional text (170 characters)
  - Description (4000 characters max)
  - Keywords (100 characters total)

### 4. **Code Quality & Testing** 🟡 IMPORTANT
- [ ] **Remove all test code** and debug features
- [ ] **Crash testing** - Use TestFlight with beta testers
- [ ] **Performance testing** - Profile with Instruments
- [ ] **Network permission handling** - Graceful fallback if denied
- [ ] **Error handling** - No crashes, all edge cases covered
- [ ] **Memory leaks** - Check with Instruments
- [ ] **Accessibility** - VoiceOver support, Dynamic Type
- [ ] **Localization** - At least English, consider Chinese/Japanese
- [ ] **Dark mode** - Full support for light and dark themes

### 5. **Technical Requirements** 🔴 CRITICAL
- [ ] **Deployment target**: Set to iOS 16.0 minimum (not 18.5) for broader reach
- [ ] **Code signing**: Valid Apple Developer account
- [ ] **App ID & Provisioning**: Proper configuration
- [ ] **Entitlements**:
  - Associated Domains (if using universal links)
  - Network extensions (for local networking)
  - Keychain access groups
- [ ] **Third-party SDKs**: All dependencies must be secure and maintained
  - ✓ SemaphoreSwift (active)
  - ✓ Mopro (active)
  - 🟡 Web3Auth (verify license compliance)
  - 🟡 Web3.swift (verify license compliance)
- [ ] **Remove backend references**:
  - Delete `APIClient.swift`
  - Delete `APIAuthManager.swift`
  - Delete `APIConfig.swift`
  - Delete `APIModels.swift`
  - Remove from CLAUDE.md documentation

### 6. **User Experience Polish** 🟡 IMPORTANT
- [ ] **Onboarding** - First-time user tutorial (keep it < 3 screens)
- [ ] **Empty states** - Beautiful placeholders for no cards/contacts
- [ ] **Loading states** - Smooth animations during ZK proof generation
- [ ] **Error messages** - User-friendly, actionable (not technical jargon)
- [ ] **Haptic feedback** - Subtle feedback for key interactions
- [ ] **App rating prompt** - Implemented with `StoreKit` after positive interactions

### 7. **Security Audit** 🔴 CRITICAL
- [ ] **Keychain security** - Verify Semaphore private keys are properly protected
- [ ] **Encryption audit** - AES-GCM implementation review
- [ ] **ZK proof validation** - Ensure no identity leakage
- [ ] **Code obfuscation** - Consider for cryptographic components
- [ ] **Penetration testing** - Test P2P attack vectors

### 8. **App Store Review Preparation** 🔴 CRITICAL
- [ ] **Demo account** - Not needed (P2P works offline)
- [ ] **Demo video** - Show how to test with two devices
- [ ] **Review notes**: Explain clearly:
  - "App works offline via MultipeerConnectivity"
  - "Test with two devices on same WiFi network"
  - "No login required, data stored locally"
  - "ZK proofs ensure privacy"
- [ ] **Compliance questions**:
  - Encryption: YES (AES-GCM, but exempt under self-classification)
  - COPPA: NO (not targeted at children under 13)
  - Ads: NO
  - Third-party analytics: NO

### 9. **Launch Preparation** 🟡 IMPORTANT
- [ ] **Support infrastructure**:
  - Support email: support@knyx.dev ✓
  - Website with FAQ
  - Community (Discord/Telegram?)
- [ ] **Beta testing via TestFlight**:
  - Internal testing (25 users)
  - External testing (10,000 users max)
  - Collect feedback, fix critical bugs
- [ ] **Pricing strategy**:
  - Free with optional premium features? (Group limits?)
  - Paid upfront? ($2.99-4.99?)
  - Freemium with Apple Wallet export as premium?
- [ ] **Launch date coordination** with marketing

### 10. **Post-Launch** 🟡 IMPORTANT
- [ ] **Monitor crashes** via App Store Connect
- [ ] **Respond to reviews** within 24 hours
- [ ] **Plan v1.1** with user-requested features
- [ ] **Analytics** (privacy-preserving, on-device only)

---

## What Makes This App Store Ready?

**The "One More Thing" Pitch:**

> Most business card apps collect your data, send it to servers, and monetize your connections. Solid(ar)ity is different. It's the **only** business card app that:
> - Works completely offline
> - Uses zero-knowledge cryptography
> - Never touches a server
> - Respects your privacy by design
>
> **This is how networking should work.**

### Minimum Viable Launch (MVP)
Ship with:
- ✓ Business card creation/editing
- ✓ QR code sharing (fastest to demo)
- ✓ Proximity sharing (P2P)
- ✓ Apple Wallet integration (killer feature)
- ✓ Basic groups (limit to 3 groups for free tier?)

### Post-Launch Features
- Advanced group management
- ENS integration (most users won't use this v1)
- Web3Auth (adds complexity, remove for v1 if optional)
- Cross-platform (Android, web)

---

**Bottom Line**: You're 70% there. Focus on polish, privacy compliance, and App Store assets. The tech is solid. Make the experience simple enough that your grandmother could use it, but powerful enough that privacy advocates applaud.

## Development

### Quick Start

```bash
git clone https://github.com/kidneyweakx/solidarity.git
cd airmeishi
open airmeishi.xcodeproj
```

Dependencies auto-resolve via Swift Package Manager. Press Cmd+R to run.

### Testing

```bash
# Run all tests
xcodebuild test -project airmeishi.xcodeproj -scheme airmeishi \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Test proximity features (requires 2 simulators or devices)
```

### Dependencies

- [SemaphoreSwift](https://github.com/zkmopro/SemaphoreSwift) - ZK proofs
- [Mopro](https://zkmopro.org/) - Native proof generation
- PassKit, MultipeerConnectivity (Apple frameworks)

---

## License

Apache 2.0 - See [LICENSE](LICENSE)

## Credits

- [Semaphore Protocol](https://semaphore.appliedzkp.org/) - Zero-knowledge proof system
- [Mopro](https://zkmopro.org/) - Mobile ZK proof framework
- Apple MultipeerConnectivity - P2P networking

---

**Solid(ar)ity** - Privacy-first networking for the decentralized web.
