import SwiftUI
import Shared
import Observation

// MARK: - Service
struct JournalService {
    var addEntry: (String, String) async throws -> Void
    var deleteEntry: (String) async throws -> Void
    var entriesStream: () -> AsyncThrowingStream<[JournalEntryModel], Error>
}

extension JournalService {
    static let live: JournalService = {
        // Create the driver and repository
        let driverFactory = DatabaseDriverFactory()
        let repository = JournalFactory.shared.createRepository(driverFactory: driverFactory)
        
        return JournalService(
            addEntry: { mood, note in
                try await repository.addEntry(mood: mood, note: note)
            },
            deleteEntry: { id in
                try await repository.deleteEntry(id: id)
            },
            entriesStream: {
                AsyncThrowingStream { continuation in
                    let task = Task {
                        do {
                            // Collect the Flow from Kotlin
                            for await entries in repository.entries {
                                continuation.yield(entries)
                            }
                            continuation.finish()
                        } catch {
                            continuation.finish(throwing: error)
                        }
                    }
                    
                    continuation.onTermination = { @Sendable _ in
                        task.cancel()
                    }
                }
            }
        )
    }()
}

// MARK: - Store
@MainActor
@Observable
class JournalStore {
    private(set) var entries: [JournalEntryModel] = []
    private let service: JournalService
    
    init(service: JournalService = .live) {
        self.service = service
        Task { await observeEntries() }
    }
    
    private func observeEntries() async {
        do {
            for try await newEntries in service.entriesStream() {
                self.entries = newEntries
            }
        } catch {
            print("Error observing journal: \(error)")
        }
    }
    
    func addEntry(mood: String, note: String) async {
        do {
            try await service.addEntry(mood, note)
        } catch {
            print("Failed to add entry: \(error)")
        }
    }
    
    func deleteEntry(id: String) async {
        do {
            try await service.deleteEntry(id)
        } catch {
            print("Failed to delete entry: \(error)")
        }
    }
}

// MARK: - View
struct JournalView: View {
    @State private var store = JournalStore()
    @State private var showingAddSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                if store.entries.isEmpty {
                    ContentUnavailableView("No Entries", systemImage: "book", description: Text("Start writing your journal today."))
                } else {
                    ForEach(store.entries, id: \.id) { entry in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(entry.mood)
                                    .font(.headline)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                
                                Spacer()
                                
                                Text(formatDate(entry.dateIso))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if !entry.note.isEmpty {
                                Text(entry.note)
                                    .font(.body)
                                    .padding(.top, 2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let entry = store.entries[index]
                            Task { await store.deleteEntry(id: entry.id) }
                        }
                    }
                }
            }
            .navigationTitle("Daily Journal")
            .toolbar {
                Button(action: { showingAddSheet = true }) {
                    Label("Add Entry", systemImage: "plus")
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddEntryView(store: store)
            }
        }
    }
    
    private func formatDate(_ isoString: String) -> String {
        // Simple formatter
        // Note: ISO8601DateFormatter is expensive to create repeatedly, but ok for now
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: isoString) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        return isoString
    }
}

struct AddEntryView: View {
    var store: JournalStore
    @Environment(\.dismiss) var dismiss
    @State private var mood = "Happy"
    @State private var note = ""
    
    let moods = ["Happy", "Excited", "Neutral", "Tired", "Sad", "Stressed"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("How are you feeling?")) {
                    Picker("Mood", selection: $mood) {
                        ForEach(moods, id: \.self) { m in
                            Text(m)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Notes")) {
                    TextField("What's on your mind?", text: $note, axis: .vertical)
                        .lineLimit(5...10)
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await store.addEntry(mood: mood, note: note)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
