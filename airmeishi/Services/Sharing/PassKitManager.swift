//
//  PassKitManager.swift
//  airmeishi
//
//  Apple Wallet pass generation and management service with PassKit integration
//

import Foundation
import PassKit
import UIKit
import CryptoKit

/// Manages Apple Wallet pass generation, updates, and revocation
class PassKitManager: NSObject, ObservableObject {
    static let shared = PassKitManager()
    
    @Published var isGeneratingPass = false
    @Published var lastGeneratedPass: PKPass?
    @Published var passError: CardError?
    
    // Pass configuration - these would be configured with your Apple Developer account
    private let passTypeIdentifier = "pass.kidneyweakx.airmeishi.businesscard"
    private let teamIdentifier = "5N42RJ485D"
    private let organizationName = "Airmeishi"
    
    // NOTE: We no longer embed a QR image into the pass bundle. The Wallet
    // barcode payload will be a simple import string (name + job) that other
    // apps can parse.
    
    private override init() {
        super.init()
    }
    
    // MARK: - Pass Generation
    
    /// Generate Apple Wallet pass for business card
    ///
    /// NOTE: This feature requires a Pass Type ID certificate from your Apple Developer account.
    /// To enable Apple Wallet passes:
    /// 1. Create a Pass Type ID in Apple Developer Portal
    /// 2. Generate and download Pass Certificate (.p12)
    /// 3. Implement proper .pkpass signing (PKCS#7)
    /// 4. Use a ZIP library to create the .pkpass bundle
    ///
    /// For v1.0, this feature is disabled to avoid crashes.
    func generatePass(
        for businessCard: BusinessCard,
        sharingLevel: SharingLevel = .professional
    ) -> CardResult<Data> {
        isGeneratingPass = false
        passError = .passGenerationError("Apple Wallet feature coming in v1.1")

        // TODO v1.1: Implement proper .pkpass generation with certificate signing
        return .failure(.passGenerationError(
            "Apple Wallet passes require additional setup. " +
            "This feature will be available in a future update. " +
            "For now, you can share your card via QR code, AirDrop, or proximity sharing."
        ))

        /* DISABLED FOR v1.0 - Requires Apple Pass Certificate
        isGeneratingPass = true
        passError = nil

        defer {
            isGeneratingPass = false
        }

        // Create pass data structure
        let passData = createPassData(for: businessCard, sharingLevel: sharingLevel)

        // Create pass bundle (simplified, unsigned)
        return createPassBundle(passData: passData, businessCard: businessCard)
        */
    }
    
    /// Add pass to Apple Wallet
    func addPassToWallet(_ passData: Data) -> CardResult<Void> {
        do {
            let pass = try PKPass(data: passData)
            
            guard PKPassLibrary.isPassLibraryAvailable() else {
                return .failure(.passGenerationError("Pass Library not available"))
            }
            
            let passLibrary = PKPassLibrary()
            
            if passLibrary.containsPass(pass) {
                return .failure(.passGenerationError("Pass already exists in Wallet"))
            }
            
            // In a real implementation, you would present PKAddPassesViewController
            // For now, we'll just indicate success
            DispatchQueue.main.async {
                self.lastGeneratedPass = pass
            }
            
            return .success(())
            
        } catch {
            return .failure(.passGenerationError("Failed to create pass: \(error.localizedDescription)"))
        }
    }
    
    /// Update existing pass in Wallet
    func updatePass(
        passSerial: String,
        businessCard: BusinessCard,
        sharingLevel: SharingLevel
    ) -> CardResult<Data> {
        // Generate new pass data with updated information
        return generatePass(for: businessCard, sharingLevel: sharingLevel)
    }
    
    /// Revoke pass by updating server-side status
    func revokePass(passSerial: String) -> CardResult<Void> {
        // In a real implementation, this would:
        // 1. Update the pass status on your server
        // 2. Send push notification to update the pass
        // 3. Mark the pass as invalid in your database
        
        // For now, we'll simulate the revocation
        let revocationData = PassRevocation(
            passSerial: passSerial,
            revokedAt: Date(),
            reason: "User revoked access"
        )
        
        // Store revocation locally
        return storePassRevocation(revocationData)
    }
    
    // MARK: - Pass Data Creation
    
    /// Create pass.json data structure
    private func createPassData(
        for businessCard: BusinessCard,
        sharingLevel: SharingLevel
    ) -> [String: Any] {
        let filteredCard = businessCard.filteredCard(for: sharingLevel)
        let passSerial = UUID().uuidString
        let importValue = generateImportString(for: filteredCard, sharingLevel: sharingLevel)
        
        var passData: [String: Any] = [
            "formatVersion": 1,
            "passTypeIdentifier": passTypeIdentifier,
            "serialNumber": passSerial,
            "teamIdentifier": teamIdentifier,
            "organizationName": organizationName,
            "description": "Business Card - \(filteredCard.name)",
            "logoText": "Airmeishi",
            "foregroundColor": "rgb(255, 255, 255)",
            "backgroundColor": "rgb(60, 60, 67)",
            "labelColor": "rgb(255, 255, 255)"
        ]
        
        // Create generic pass structure
        var generic: [String: Any] = [:]
        
        // Primary fields (most prominent)
        var primaryFields: [[String: Any]] = []
        primaryFields.append([
            "key": "name",
            "label": "Name",
            "value": filteredCard.name
        ])
        
        // Secondary fields
        var secondaryFields: [[String: Any]] = []
        if let title = filteredCard.title {
            secondaryFields.append([
                "key": "title",
                "label": "Title",
                "value": title
            ])
        }
        if let company = filteredCard.company {
            secondaryFields.append([
                "key": "company",
                "label": "Company",
                "value": company
            ])
        }
        
        // Auxiliary fields (smaller, bottom area)
        var auxiliaryFields: [[String: Any]] = []
        if let email = filteredCard.email {
            auxiliaryFields.append([
                "key": "email",
                "label": "Email",
                "value": email
            ])
        }
        if let phone = filteredCard.phone {
            auxiliaryFields.append([
                "key": "phone",
                "label": "Phone",
                "value": phone
            ])
        }
        
        // Back fields (detailed information on back of pass)
        var backFields: [[String: Any]] = []
        
        // Add skills if available
        if !filteredCard.skills.isEmpty {
            let skillsText = filteredCard.skills.map { "\($0.name) (\($0.proficiencyLevel.rawValue))" }.joined(separator: ", ")
            backFields.append([
                "key": "skills",
                "label": "Skills",
                "value": skillsText
            ])
        }
        
        // Add sharing level info
        backFields.append([
            "key": "sharingLevel",
            "label": "Sharing Level",
            "value": sharingLevel.displayName
        ])
        
        // Add creation date
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        backFields.append([
            "key": "created",
            "label": "Created",
            "value": formatter.string(from: Date())
        ])
        
        generic["primaryFields"] = primaryFields
        generic["secondaryFields"] = secondaryFields
        generic["auxiliaryFields"] = auxiliaryFields
        generic["backFields"] = backFields
        
        passData["generic"] = generic
        
        // Add barcode/QR code payload: simple import string (name + job)
        passData["barcodes"] = [[
            "message": importValue,
            "format": "PKBarcodeFormatQR",
            "messageEncoding": "iso-8859-1"
        ]]
        
        return passData
    }
    
    /// Create complete pass bundle with all required files
    private func createPassBundle(
        passData: [String: Any],
        businessCard: BusinessCard
    ) -> CardResult<Data> {
        do {
            // Create pass.json
            _ = try JSONSerialization.data(withJSONObject: passData, options: .prettyPrinted)
            
            // Serialize final pass.json
            let finalPassJsonData = try JSONSerialization.data(withJSONObject: passData, options: .prettyPrinted)
            
            // Create manifest.json (checksums of all files)
            var manifest: [String: String] = [:]
            manifest["pass.json"] = sha1Hash(finalPassJsonData)
            
            // Add logo if available (placeholder for now)
            if let logoData = createLogoImage().pngData() {
                manifest["logo.png"] = sha1Hash(logoData)
                manifest["logo@2x.png"] = sha1Hash(logoData)
            }
            
            // Add profile image if available
            if let profileImageData = businessCard.profileImage {
                manifest["thumbnail.png"] = sha1Hash(profileImageData)
                manifest["thumbnail@2x.png"] = sha1Hash(profileImageData)
            }
            
            let manifestData = try JSONSerialization.data(withJSONObject: manifest, options: .prettyPrinted)
            
            // Create signature (placeholder - in real implementation, you'd sign with your pass certificate)
            let signature = createSignature(for: manifestData)
            
            // Create ZIP archive with all files
            return createZipArchive(
                passJson: finalPassJsonData,
                manifest: manifestData,
                signature: signature,
                logo: createLogoImage().pngData(),
                profileImage: businessCard.profileImage
            )
            
        } catch {
            return .failure(.passGenerationError("Failed to create pass bundle: \(error.localizedDescription)"))
        }
    }
    
    // MARK: - Helper Methods
    
    /// Calculate SHA1 hash for manifest
    private func sha1Hash(_ data: Data) -> String {
        let digest = Insecure.SHA1.hash(data: data)
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
    
    /// Create placeholder signature (in real implementation, use pass certificate)
    private func createSignature(for manifestData: Data) -> Data {
        // This is a placeholder. In a real implementation, you would:
        // 1. Load your pass certificate and private key
        // 2. Sign the manifest.json with PKCS#7 detached signature
        // 3. Return the signature data
        
        return "PLACEHOLDER_SIGNATURE".data(using: .utf8) ?? Data()
    }
    
    /// Create placeholder logo image
    private func createLogoImage() -> UIImage {
        let size = CGSize(width: 160, height: 50)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Create simple logo placeholder
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Add text
            let text = "Airmeishi"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 20),
                .foregroundColor: UIColor.black
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    /// Create ZIP archive with all pass files
    private func createZipArchive(
        passJson: Data,
        manifest: Data,
        signature: Data,
        logo: Data?,
        profileImage: Data?
    ) -> CardResult<Data> {
        // In a real implementation, you would use a ZIP library to create the .pkpass file
        // For now, we'll return the pass.json as a placeholder
        
        // This is a simplified implementation - a real .pkpass file is a ZIP archive
        // containing pass.json, manifest.json, signature, and image files
        
        return .success(passJson)
    }
    
    /// Store pass revocation data
    private func storePassRevocation(_ revocation: PassRevocation) -> CardResult<Void> {
        let encoder = JSONEncoder()
        
        do {
            let data = try encoder.encode(revocation)
            UserDefaults.standard.set(data, forKey: "revocation_\(revocation.passSerial)")
            return .success(())
        } catch {
            return .failure(.storageError("Failed to store revocation: \(error.localizedDescription)"))
        }
    }
}

// MARK: - Supporting Models

/// Pass revocation data structure
struct PassRevocation: Codable {
    let passSerial: String
    let revokedAt: Date
    let reason: String
}

/// Pass update notification payload
struct PassUpdatePayload: Codable {
    let passSerial: String
    let updatedAt: Date
    let businessCard: BusinessCard
    let sharingLevel: SharingLevel
}

// MARK: - Public Helper (Import String)

extension PassKitManager {
    /// Generate a simple import URL string that contains the name and job title.
    /// Example: airmeishi://contact?name=John%20Doe&job=Engineer
    func generateImportString(for businessCard: BusinessCard, sharingLevel: SharingLevel) -> String {
        let filtered = businessCard.filteredCard(for: sharingLevel)
        let nameEncoded = urlEncode(filtered.name)
        let titleEncoded = urlEncode(filtered.title ?? "")
        return "airmeishi://contact?name=\(nameEncoded)&job=\(titleEncoded)"
    }
    
    private func urlEncode(_ value: String) -> String {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }
}