//
//  BackupManager.swift
//  airmeishi
//
//  Handles optional iCloud and Google Drive backup (stubs)
//

import Foundation

final class BackupManager: ObservableObject {
    static let shared = BackupManager()
    private init() {}
    
    enum Provider: String, Codable, CaseIterable, Identifiable {
        case iCloud
        case googleDrive
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .iCloud: return "iCloud"
            case .googleDrive: return "Google Drive"
            }
        }
    }
    
    struct Settings: Codable {
        var enabled: Bool
        var providers: Set<Provider>
        var lastBackupAt: Date?
    }
    
    @Published private(set) var settings: Settings = Settings(enabled: false, providers: [], lastBackupAt: nil)
    private let storage = StorageManager.shared
    
    func loadSettings() {
        switch storage.loadUserPreferences(Settings.self) {
        case .success(let s): settings = s
        case .failure: settings = Settings(enabled: false, providers: [], lastBackupAt: nil)
        }
    }
    
    @discardableResult
    func update(_ transform: (inout Settings) -> Void) -> CardResult<Void> {
        var s = settings
        transform(&s)
        let result = storage.saveUserPreferences(s)
        switch result {
        case .success:
            settings = s
            return .success(())
        case .failure(let e):
            return .failure(e)
        }
    }
    
    func performBackupNow() -> CardResult<Void> {
        guard settings.enabled, !settings.providers.isEmpty else {
            return .failure(.configurationError("Backup disabled or no provider selected"))
        }
        // Gather files
        // For now, just mark timestamp
        return update { s in
            s.lastBackupAt = Date()
        }
    }
}


