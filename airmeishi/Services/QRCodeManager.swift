//
//  QRCodeManager.swift
//  airmeishi
//
//  QR code generation and scanning service with encrypted sharing and privacy controls
//

import Foundation
import CoreImage
import AVFoundation
import UIKit
import CryptoKit

/// Manages QR code generation and scanning with encrypted sharing capabilities
class QRCodeManager: NSObject, ObservableObject {
    static let shared = QRCodeManager()
    
    @Published var isScanning = false
    @Published var isGenerating = false
    @Published var lastScannedCard: BusinessCard?
    @Published var scanError: CardError?
    
    private let encryptionManager = EncryptionManager.shared
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    private override init() {
        super.init()
    }
    
    // MARK: - QR Code Generation
    
    /// Generate QR code for business card with selective field disclosure
    func generateQRCode(
        for businessCard: BusinessCard,
        sharingLevel: SharingLevel,
        expirationDate: Date? = nil
    ) -> CardResult<UIImage> {
        isGenerating = true
        defer { isGenerating = false }
        
        // Create filtered card based on sharing level
        let filteredCard = businessCard.filteredCard(for: sharingLevel)
        
        // Create sharing payload
        let sharingPayload = QRSharingPayload(
            businessCard: filteredCard,
            sharingLevel: sharingLevel,
            expirationDate: expirationDate ?? Date().addingTimeInterval(24 * 60 * 60), // 24 hours default
            shareId: UUID(),
            createdAt: Date()
        )
        
        // Encrypt the payload
        let encryptionResult = encryptionManager.encrypt(sharingPayload)
        
        switch encryptionResult {
        case .success(let encryptedData):
            // Convert to base64 for QR code
            let base64String = encryptedData.base64EncodedString()
            
            // Generate QR code image
            return generateQRCodeImage(from: base64String)
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// Generate one-time sharing link with rate limiting
    func generateSharingLink(
        for businessCard: BusinessCard,
        sharingLevel: SharingLevel,
        maxUses: Int = 1
    ) -> CardResult<String> {
        let shareId = UUID()
        let expirationDate = Date().addingTimeInterval(60 * 60) // 1 hour
        
        let sharingPayload = QRSharingPayload(
            businessCard: businessCard.filteredCard(for: sharingLevel),
            sharingLevel: sharingLevel,
            expirationDate: expirationDate,
            shareId: shareId,
            createdAt: Date(),
            maxUses: maxUses,
            currentUses: 0
        )
        
        // Store the sharing payload for later retrieval
        let storeResult = storeSharingPayload(sharingPayload)
        
        switch storeResult {
        case .success:
            // Create sharing URL
            let baseURL = "https://airmeishi.app/share" // This would be your actual domain
            let shareURL = "\(baseURL)/\(shareId.uuidString)"
            return .success(shareURL)
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - QR Code Scanning
    
    /// Start QR code scanning session
    func startScanning() -> CardResult<AVCaptureVideoPreviewLayer> {
        guard !isScanning else {
            return .failure(.sharingError("Scanning already in progress"))
        }
        
        // Request camera permission
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        _ = self.setupCaptureSession()
                    } else {
                        self.scanError = .sharingError("Camera access denied")
                    }
                }
            }
            return .failure(.sharingError("Camera permission required"))
        case .denied, .restricted:
            return .failure(.sharingError("Camera access denied"))
        @unknown default:
            return .failure(.sharingError("Unknown camera permission status"))
        }
        
        return setupCaptureSession()
    }
    
    /// Stop QR code scanning session
    func stopScanning() {
        isScanning = false
        captureSession?.stopRunning()
        captureSession = nil
        previewLayer = nil
    }
    
    /// Process scanned QR code data
    func processScannedData(_ data: String) {
        // Try to decode as base64 encrypted data
        guard let encryptedData = Data(base64Encoded: data) else {
            scanError = .sharingError("Invalid QR code format")
            return
        }
        
        // Decrypt the payload
        let decryptionResult = encryptionManager.decrypt(encryptedData, as: QRSharingPayload.self)
        
        switch decryptionResult {
        case .success(let payload):
            // Check expiration
            if payload.expirationDate < Date() {
                scanError = .sharingError("Shared card has expired")
                return
            }
            
            // Check usage limits
            if let maxUses = payload.maxUses,
               let currentUses = payload.currentUses,
               currentUses >= maxUses {
                scanError = .sharingError("Share link has reached maximum uses")
                return
            }
            
            // Successfully decoded business card
            DispatchQueue.main.async {
                self.lastScannedCard = payload.businessCard
                self.scanError = nil
            }
            
        case .failure(let error):
            scanError = error
        }
    }
    
    // MARK: - Private Methods
    
    /// Generate QR code image from string data
    private func generateQRCodeImage(from string: String) -> CardResult<UIImage> {
        guard let data = string.data(using: .utf8) else {
            return .failure(.sharingError("Failed to convert string to data"))
        }
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return .failure(.sharingError("QR code generator not available"))
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // High error correction
        
        guard let ciImage = filter.outputImage else {
            return .failure(.sharingError("Failed to generate QR code"))
        }
        
        // Scale up the image for better quality
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = ciImage.transformed(by: transform)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return .failure(.sharingError("Failed to create QR code image"))
        }
        
        let uiImage = UIImage(cgImage: cgImage)
        return .success(uiImage)
    }
    
    /// Setup camera capture session for QR scanning
    private func setupCaptureSession() -> CardResult<AVCaptureVideoPreviewLayer> {
        let session = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return .failure(.sharingError("No camera available"))
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            } else {
                return .failure(.sharingError("Could not add video input"))
            }
            
            let metadataOutput = AVCaptureMetadataOutput()
            
            if session.canAddOutput(metadataOutput) {
                session.addOutput(metadataOutput)
                
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            } else {
                return .failure(.sharingError("Could not add metadata output"))
            }
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            
            self.captureSession = session
            self.previewLayer = previewLayer
            
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
                DispatchQueue.main.async {
                    self.isScanning = true
                }
            }
            
            return .success(previewLayer)
            
        } catch {
            return .failure(.sharingError("Failed to setup camera: \(error.localizedDescription)"))
        }
    }
    
    /// Store sharing payload for link-based sharing
    private func storeSharingPayload(_ payload: QRSharingPayload) -> CardResult<Void> {
        // In a real implementation, this would store to a server or local cache
        // For now, we'll use UserDefaults as a simple storage mechanism
        let encoder = JSONEncoder()
        
        do {
            let data = try encoder.encode(payload)
            UserDefaults.standard.set(data, forKey: "sharing_\(payload.shareId.uuidString)")
            return .success(())
        } catch {
            return .failure(.storageError("Failed to store sharing payload: \(error.localizedDescription)"))
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRCodeManager: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            // Process the scanned data
            processScannedData(stringValue)
            
            // Stop scanning after successful scan
            stopScanning()
        }
    }
}

// MARK: - Supporting Models

/// Payload structure for QR code sharing with encryption
struct QRSharingPayload: Codable {
    let businessCard: BusinessCard
    let sharingLevel: SharingLevel
    let expirationDate: Date
    let shareId: UUID
    let createdAt: Date
    let maxUses: Int?
    let currentUses: Int?
    
    init(
        businessCard: BusinessCard,
        sharingLevel: SharingLevel,
        expirationDate: Date,
        shareId: UUID,
        createdAt: Date,
        maxUses: Int? = nil,
        currentUses: Int? = nil
    ) {
        self.businessCard = businessCard
        self.sharingLevel = sharingLevel
        self.expirationDate = expirationDate
        self.shareId = shareId
        self.createdAt = createdAt
        self.maxUses = maxUses
        self.currentUses = currentUses
    }
}