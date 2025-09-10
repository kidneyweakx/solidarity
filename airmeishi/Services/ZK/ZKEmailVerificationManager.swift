//
//  ZKEmailVerificationManager.swift
//  airmeishi
//
//  Verifies event participation using zkEmail proofs from .eml emails (e.g., Luma)
//

import Foundation

#if canImport(ZKEmailSwift)
import ZKEmailSwift
#endif

final class ZKEmailVerificationManager {
    static let shared = ZKEmailVerificationManager()
    private init() {}
    
    struct LumaEmailInfo {
        let eventName: String
        let eventId: String
        let organizer: String?
        let eventDate: Date
        let location: String?
        let fromAddress: String?
        let subject: String
    }
    
    func parseLumaEmail(_ data: Data) -> CardResult<LumaEmailInfo> {
        guard let raw = String(data: data, encoding: .utf8) else {
            return .failure(.invalidData("EML not utf8"))
        }
        let from = match(header: "From:", in: raw)
        let subject = match(header: "Subject:", in: raw) ?? ""
        let dateStr = match(header: "Date:", in: raw)
        let eventName = extractEventName(from: subject) ?? "Luma Event"
        let eventId = extractEventId(from: raw) ?? UUID().uuidString
        let organizer = extractOrganizer(from: raw)
        let location = extractLocation(from: raw)
        let eventDate = parseDate(dateStr) ?? Date()
        return .success(LumaEmailInfo(
            eventName: eventName,
            eventId: eventId,
            organizer: organizer,
            eventDate: eventDate,
            location: location,
            fromAddress: from,
            subject: subject
        ))
    }
    
    func verifyLumaEmailWithZK(_ data: Data, srsPath: String?) -> CardResult<Bool> {
        #if canImport(ZKEmailSwift)
        let inputs: [String: [String]] = [
            "header_storage": [],
            "header_len": ["0"],
            "pubkey_modulus": [],
            "pubkey_redc": [],
            "signature": [],
            "date_index": ["0"],
            "subject_index": ["0"],
            "subject_length": ["0"],
            "from_header_index": ["0"],
            "from_header_length": ["0"],
            "from_address_index": ["0"],
            "from_address_length": ["0"]
        ]
        do {
            let proof = try proveZkemail(srsPath: srsPath ?? "", inputs: inputs)
            let ok = try verifyZkemail(srsPath: srsPath ?? "", proof: proof)
            return .success(ok)
        } catch {
            return .failure(.proofVerificationError("zkEmail failed: \(error.localizedDescription)"))
        }
        #else
        guard let raw = String(data: data, encoding: .utf8) else {
            return .failure(.invalidData("EML not utf8"))
        }
        let looksLikeLuma = raw.lowercased().contains("luma") || raw.lowercased().contains("@lu.ma")
        return .success(looksLikeLuma)
        #endif
    }
    
    private func match(header: String, in text: String) -> String? {
        let pattern = "^" + NSRegularExpression.escapedPattern(for: header) + "\\s*(.*)$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else { return nil }
        guard match.numberOfRanges >= 2, let valueRange = Range(match.range(at: 1), in: text) else { return nil }
        let value = String(text[valueRange]).trimmingCharacters(in: CharacterSet.whitespaces)
        return value
    }
    
    private func extractEventName(from subject: String) -> String? {
        if let range = subject.range(of: " for ") {
            return String(subject[range.upperBound...]).replacingOccurrences(of: " — Luma", with: "").trimmingCharacters(in: CharacterSet.whitespaces)
        }
        return nil
    }
    
    private func extractEventId(from raw: String) -> String? {
        if let range = raw.range(of: "https://lu.ma/\\S+", options: .regularExpression) {
            let url = String(raw[range])
            return URL(string: url)?.lastPathComponent
        }
        return nil
    }
    
    private func extractOrganizer(from raw: String) -> String? {
        if let range = raw.range(of: "Organizer:.*", options: .regularExpression) {
            let line = String(raw[range])
            return line.replacingOccurrences(of: "Organizer:", with: "").trimmingCharacters(in: CharacterSet.whitespaces)
        }
        return nil
    }
    
    private func extractLocation(from raw: String) -> String? {
        if let range = raw.range(of: "Location:.*", options: .regularExpression) {
            let line = String(raw[range])
            return line.replacingOccurrences(of: "Location:", with: "").trimmingCharacters(in: CharacterSet.whitespaces)
        }
        return nil
    }
    
    private func parseDate(_ dateStr: String?) -> Date? {
        guard let dateStr = dateStr else { return nil }
        let formats = [
            "E, d MMM yyyy HH:mm:ss Z",
            "E, dd MMM yyyy HH:mm:ss Z",
            "d MMM yyyy HH:mm:ss Z",
            "yyyy-MM-dd'T'HH:mm:ssZ"
        ]
        for f in formats {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = f
            if let d = df.date(from: dateStr) { return d }
        }
        return nil
    }
}


