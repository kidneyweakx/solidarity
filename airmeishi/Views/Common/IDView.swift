//
//  IDView.swift
//  airmeishi
//
//  Identity & Events: shows verified participation history and lets user import .eml
//

import SwiftUI
import UniformTypeIdentifiers

enum EventLayoutMode: String, CaseIterable, Identifiable {
    case list
    case grid
    case timeline
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .list: return "List"
        case .grid: return "Grid"
        case .timeline: return "Timeline"
        }
    }
}

struct IDView: View {
    @StateObject private var repo = EventRepository.shared
    @State private var mode: EventLayoutMode = .list
    @State private var showingImporter = false
    @State private var showingSettings = false
    @State private var importError: String?
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("ID")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Picker("Layout", selection: $mode) {
                            ForEach(EventLayoutMode.allCases) { m in
                                Text(m.title).tag(m)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 220)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 12) {
                            Button {
                                showingImporter = true
                            } label: {
                                Image(systemName: "square.and.arrow.down")
                            }
                            Button {
                                showingSettings = true
                            } label: {
                                Image(systemName: "gear")
                            }
                        }
                    }
                }
        }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [UTType(filenameExtension: "eml")!]) { result in
            handleImport(result: result)
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                List {
                    NavigationLink("Privacy Settings") {
                        PrivacySettingsHost()
                    }
                    NavigationLink("Backup Settings") {
                        BackupSettingsView()
                    }
                }
                .navigationTitle("Settings")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { showingSettings = false }
                    }
                }
            }
        }
        .alert("Import Failed", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importError ?? "")
        }
        .onAppear { _ = repo.load() }
    }
    
    @ViewBuilder
    private var content: some View {
        switch mode {
        case .list:
            ListView(events: repo.events.sortedByEventDateDesc())
        case .grid:
            GridView(events: repo.events.sortedByEventDateDesc())
        case .timeline:
            TimelineView(events: repo.events.sortedByEventDateDesc())
        }
    }
    
    private func handleImport(result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let data = try Data(contentsOf: url)
            let zk = ZKEmailVerificationManager.shared
            let info = try zk.parseLumaEmail(data).get()
            let verified = try zk.verifyLumaEmailWithZK(data, srsPath: nil).get()
            let participation = EventParticipation(
                id: UUID().uuidString,
                eventId: info.eventId,
                eventName: info.eventName,
                organizer: info.organizer,
                eventDate: info.eventDate,
                location: info.location,
                sourceEmail: info.fromAddress,
                verificationMethod: .zkemail,
                isVerified: verified,
                proofDataPath: nil,
                createdAt: Date(),
                updatedAt: Date(),
                notes: info.subject
            )
            let _ = repo.upsert(participation)
        } catch {
            importError = error.localizedDescription
        }
    }
}

private struct ListView: View {
    let events: [EventParticipation]
    var body: some View {
        List(events) { e in
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(e.eventName).font(.headline)
                    Text(e.eventDate, style: .date).font(.subheadline).foregroundColor(.secondary)
                    if let loc = e.location, !loc.isEmpty { Text(loc).font(.caption).foregroundColor(.secondary) }
                }
                Spacer()
                Image(systemName: e.isVerified ? "checkmark.seal.fill" : "exclamationmark.triangle")
                    .foregroundColor(e.isVerified ? .green : .orange)
            }
        }
        .listStyle(.insetGrouped)
    }
}

private struct GridView: View {
    let events: [EventParticipation]
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(events) { e in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(e.eventName).font(.headline).lineLimit(2)
                            Spacer()
                            Image(systemName: e.isVerified ? "checkmark.seal.fill" : "exclamationmark.triangle")
                                .foregroundColor(e.isVerified ? .green : .orange)
                        }
                        Text(e.eventDate, style: .date).font(.caption).foregroundColor(.secondary)
                        if let loc = e.location, !loc.isEmpty { Text(loc).font(.caption2).foregroundColor(.secondary) }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: .secondarySystemBackground)))
                }
            }
            .padding()
        }
    }
}

private struct TimelineView: View {
    let events: [EventParticipation]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(events) { e in
                    HStack(alignment: .top, spacing: 12) {
                        VStack {
                            Circle().fill(e.isVerified ? .green : .orange).frame(width: 10, height: 10)
                            Rectangle().fill(Color.secondary).frame(width: 2, height: 40)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(e.eventName).font(.headline)
                            Text(e.eventDate, style: .date).font(.subheadline).foregroundColor(.secondary)
                            if let loc = e.location, !loc.isEmpty { Text(loc).font(.caption).foregroundColor(.secondary) }
                        }
                        Spacer()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
        }
    }
}

private struct PrivacySettingsHost: View {
    @State private var prefs = SharingPreferences()
    var body: some View {
        PrivacySettingsView(sharingPreferences: $prefs)
    }
}

#Preview {
    IDView()
}


