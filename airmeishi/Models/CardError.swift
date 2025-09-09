//
//  CardError.swift
//  airmeishi
//
//  Error handling for business card operations
//

import Foundation

/// Comprehensive error types for business card operations
enum CardError: Error, LocalizedError, Equatable {
    case invalidData(String)
    case storageError(String)
    case encryptionError(String)
    case networkError(String)
    case passGenerationError(String)
    case ocrError(String)
    case sharingError(String)
    case validationError(String)
    case notFound(String)
    case unauthorized(String)
    case rateLimited(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .storageError(let message):
            return "Storage error: \(message)"
        case .encryptionError(let message):
            return "Encryption error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .passGenerationError(let message):
            return "Pass generation error: \(message)"
        case .ocrError(let message):
            return "OCR error: \(message)"
        case .sharingError(let message):
            return "Sharing error: \(message)"
        case .validationError(let message):
            return "Validation error: \(message)"
        case .notFound(let message):
            return "Not found: \(message)"
        case .unauthorized(let message):
            return "Unauthorized: \(message)"
        case .rateLimited(let message):
            return "Rate limited: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidData:
            return "Please check the data format and try again."
        case .storageError:
            return "Please check available storage space and try again."
        case .encryptionError:
            return "Please restart the app and try again."
        case .networkError:
            return "Please check your internet connection and try again."
        case .passGenerationError:
            return "Please check your Apple Wallet settings and try again."
        case .ocrError:
            return "Please ensure the image is clear and try again."
        case .sharingError:
            return "Please check sharing permissions and try again."
        case .validationError:
            return "Please correct the highlighted fields and try again."
        case .notFound:
            return "The requested item could not be found."
        case .unauthorized:
            return "Please check your permissions and try again."
        case .rateLimited:
            return "Please wait a moment before trying again."
        }
    }
    
    var failureReason: String? {
        switch self {
        case .invalidData:
            return "The provided data is not in the expected format."
        case .storageError:
            return "Unable to read from or write to local storage."
        case .encryptionError:
            return "Failed to encrypt or decrypt data."
        case .networkError:
            return "Network request failed or timed out."
        case .passGenerationError:
            return "Unable to generate Apple Wallet pass."
        case .ocrError:
            return "Text recognition failed or returned low confidence results."
        case .sharingError:
            return "Unable to share business card data."
        case .validationError:
            return "Required fields are missing or invalid."
        case .notFound:
            return "The requested resource does not exist."
        case .unauthorized:
            return "Access denied or insufficient permissions."
        case .rateLimited:
            return "Too many requests in a short time period."
        }
    }
}

/// Result type alias for business card operations
typealias CardResult<T> = Result<T, CardError>