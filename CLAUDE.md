# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Solid(ar)ity (project name: airmeishi) is a privacy-preserving, proximity-based business card sharing iOS app built with SwiftUI. It combines P2P networking (MultipeerConnectivity) with zero-knowledge proofs (Semaphore protocol via SemaphoreSwift and Mopro) to enable secure, anonymous contact exchange with selective disclosure.

**Key Technologies:**
- SwiftUI for UI
- MultipeerConnectivity for P2P device discovery and sharing
- Semaphore Protocol (via SemaphoreSwift package) for ZK identity and group membership proofs
- MoproFFI for native ZK proof generation
- Web3Auth for authentication
- ENS for decentralized naming
- PassKit for Apple Wallet integration
- Swift Testing framework (not XCTest)

**Target:** iOS 18.5+, Swift 5.0

## Development Commands

### Build and Run
```bash
# Open in Xcode
open airmeishi.xcodeproj

# Build from command line
xcodebuild -project airmeishi.xcodeproj -scheme airmeishi -configuration Debug build

# Run on simulator (replace device name as needed)
xcodebuild -project airmeishi.xcodeproj -scheme airmeishi -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### Testing
```bash
# Run all tests
xcodebuild test -project airmeishi.xcodeproj -scheme airmeishi -destination 'platform=iOS Simulator,name=iPhone 16'

# Run specific test file
xcodebuild test -project airmeishi.xcodeproj -scheme airmeishi -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:airmeishiTests/ProximityManagerTests

# The project uses Swift Testing framework, not XCTest
# Tests are in: airmeishiTests/, airmeishiUITests/
```

### Dependencies
Dependencies are managed via Swift Package Manager and auto-resolve when opening the project in Xcode. Main packages:
- **SemaphoreSwift** (https://github.com/zkmopro/SemaphoreSwift @ main) - ZK proof implementation
- **MoproFFI** - Native ZK proof framework
- **Web3Auth** - Web3 authentication
- **Web3.swift** - Ethereum interaction

## Architecture

### Core Service Layer Pattern
The app follows a shared singleton manager pattern with `@MainActor` isolation where needed:

**Identity & Privacy Layer:**
- `SemaphoreIdentityManager` - Manages Semaphore ZK identity lifecycle, commitments, and proof generation. Stores private keys in Keychain.
- `SemaphoreGroupManager` - Manages Semaphore groups for verified communities (group creation, membership, root calculation).
- `ProofGenerationManager` - Orchestrates ZK proof generation for various scenarios.
- `SelectiveDisclosureService` - Handles privacy-preserving selective field disclosure.

**Sharing & Connectivity Layer:**
- `ProximityManager` (MultipeerConnectivity wrapper) - Core P2P discovery and sharing. Handles advertising, browsing, peer connections, and card/group invite transmission.
  - Key methods: `startAdvertising(with:sharingLevel:)`, `startBrowsing()`, `sendCard(_:to:sharingLevel:)`, `sendGroupInvite(to:group:inviterName:)`
  - Publishes: `nearbyPeers`, `receivedCards`, `connectionStatus`, `pendingInvitation`, `pendingGroupInvite`
- `AirDropManager` - AirDrop sharing integration
- `ShareLinkManager` - ShareLink/universal link handling
- `QRCodeManager` - QR code generation and scanning
- `PassKitManager` - Apple Wallet pass generation

**Data Management Layer:**
- `CardManager` - Business card CRUD operations
- `ContactRepository` - Contact storage and retrieval with verification status
- `StorageManager` - Local file-based persistence with encryption
- `EncryptionManager` - AES-GCM encryption for sensitive data
- `BackupManager` - Backup/restore functionality

**Supporting Services:**
- `DeepLinkManager` - Universal link and deep link routing
- `ThemeManager` - App theming and appearance

### Data Models
- `BusinessCard` - Main card model with skills, social networks, and `SharingPreferences`
  - `SharingPreferences` controls which fields are visible at each `SharingLevel` (public/professional/personal)
  - `filteredCard(for:)` returns privacy-filtered version
- `Contact` - Received card with source, tags, verification status
- `AnimalCharacter` - Visual identification avatar
- `SharingLevel` - Privacy levels: `.public`, `.professional`, `.personal`
- `VerificationStatus` - ZK proof verification state

### View Structure
Views are organized by feature area:
- `Views/Common/` - `ContentView`, `MainTabView`, shared components
- `Views/CardViews/` - Business card creation, editing, PassKit generation
- `Views/MatchViews/` - Proximity sharing UI (`MatchingOrbitView`, `NearbyPeersSheet`, invitation popups)
- `Views/IDViews/` - Settings, privacy controls, group management
- `Views/ShoutoutViews/` - Event/participation features

### Zero-Knowledge Proof Flow
1. **Identity Creation:** `SemaphoreIdentityManager.loadOrCreateIdentity()` generates a Semaphore identity (stored in Keychain).
2. **Group Management:** `SemaphoreGroupManager` maintains groups with member commitments and calculates Merkle roots.
3. **Proof Generation:** When sharing with ZK enabled:
   - `ProofGenerationManager.generateSelectiveDisclosureProof(businessCard:selectedFields:recipientId:)` creates a proof
   - Proof is attached to `ProximitySharingPayload` and sent via `ProximityManager`
4. **Verification:** Receiver uses `ProximityVerificationHelper.verify(commitment:proof:message:scope:)` to verify the proof without revealing identity.

### Proximity Sharing Flow
1. **Advertise:** User calls `ProximityManager.shared.startAdvertising(with: card, sharingLevel: .professional)`
2. **Discover:** Nearby devices call `startBrowsing()` and receive `nearbyPeers` updates
3. **Connect:** Browser invites peer via `connectToPeer(_:)` or `invitePeerToGroup(_:group:inviterName:)`
4. **Exchange:** On connection, cards/invites are auto-sent. Receiver gets `receivedCards` updates and saves to `ContactRepository`.
5. **Verification:** If ZK proofs are included, verification status is set on the `Contact`.

### Testing Notes
- Use Swift Testing framework (`@Test`, `#expect`, `Issue.record`)
- Key test files: `ProximityManagerTests`, `ContactManagementTests`, `DeepLinkManagerTests`, `QRCodeManagerTests`
- Always clear test data with `StorageManager.shared.clearAllData()` in setup

## Important Patterns

**Singleton Managers:** Most services use `.shared` singleton pattern. Inject as `@StateObject` or `@EnvironmentObject` in SwiftUI views.

**Result Types:** Service methods return `Result<T, CardError>` for error handling. Always handle both cases.

**Main Actor Isolation:** UI-related managers like `ContactRepository` are `@MainActor`. Call from main thread or use `Task { @MainActor in ... }`.

**Notifications:** Proximity events broadcast via `NotificationCenter` (e.g., `.matchingReceivedCard`, `.groupInviteReceived`, `.matchingPeerListUpdated`).

**Privacy-First:** Always filter cards via `filteredCard(for: sharingLevel)` before sharing. Respect `SharingPreferences.useZK` flag.

## Common Workflows

**Adding a New Sharing Method:**
1. Create manager in `Services/Sharing/`
2. Implement payload encoding/decoding
3. Add UI in `Views/MatchViews/`
4. Update `ProximityManager` if it involves P2P

**Adding ZK Proof Type:**
1. Define proof model in `Services/ZK/ProofModels.swift`
2. Add generation logic in `ProofGenerationManager`
3. Add verification in `ProximityVerificationHelper` or similar
4. Update `ProximitySharingPayload` if needed

**Testing Proximity Features:**
1. Use two simulators or devices
2. Ensure Info.plist has `NSLocalNetworkUsageDescription` and `NSBonjourServices: ["_airmeishi-share._tcp."]`
3. Check `ProximityManager.checkNetworkPermissions()` for diagnostics

## File Organization
```
airmeishi/
├── Models/              # Data models (BusinessCard, Contact, etc.)
├── Services/
│   ├── ZK/             # Semaphore identity, groups, proofs
│   ├── Sharing/        # Proximity, AirDrop, QR, PassKit
│   ├── Card/           # Card management, OCR
│   ├── Utils/          # Storage, encryption, theme
│   └── Backup/         # Backup/restore
├── Views/
│   ├── CardViews/      # Card editing, PassKit
│   ├── MatchViews/     # Proximity UI, QR scanning
│   ├── IDViews/        # Settings, groups, privacy
│   ├── ShoutoutViews/  # Events
│   └── Common/         # Shared components, tabs
└── airmeishiApp.swift  # App entry point

airmeishiClip/          # App Clip target
airmeishiTests/         # Unit/integration tests
airmeishiUITests/       # UI tests
```

## Branch & Commit Strategy
- **Main branch:** `main`
- **Current working branch:** `v1.0.0` (as of last commit)
- Always create PRs targeting `main`
- Commit messages follow conventional format (feat/fix/refactor)
