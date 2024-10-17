//
//  NotesView.swift
//  RenduProjet2
//
//  Created by RENAUD Brévin on 15/10/2024.
//

import SwiftUI

struct Note: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    var isPinned: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), title: String, content: String, isPinned: Bool = false, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.isPinned = isPinned
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
    }
}

class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var sortOption: SortOption = .updatedAt
    
    enum SortOption: String, CaseIterable {
        case title = "Titre"
        case createdAt = "Date de création"
        case updatedAt = "Date de mise à jour"
    }
    
    init() {
        loadNotes()
    }
    
    func addNote(_ note: Note) {
        notes.append(note)
        saveNotes()
    }
    
    
    func deleteNote(at offsets: IndexSet) {
        notes.remove(atOffsets: offsets)
        saveNotes()
    }
    
    
    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = note
            updatedNote.updatedAt = Date()
            notes[index] = updatedNote
            saveNotes()
        }
    }
    
    

    func togglePin(for note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index].isPinned.toggle()
            notes[index].updatedAt = Date()
            saveNotes()
        }
    }
    
    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: "notes")
        }
    }
    
    private func loadNotes() {
        if let data = UserDefaults.standard.data(forKey: "notes"),
           let decoded = try? JSONDecoder().decode([Note].self, from: data) {
            notes = decoded
        }
    }
    
    
    func sortedNotes() -> [Note] {
        let sortedNotes = notes.sorted { (note1, note2) -> Bool in
            switch sortOption {
            case .title:
                return note1.title < note2.title
            case .createdAt:
                return note1.createdAt > note2.createdAt
            case .updatedAt:
                return note1.updatedAt > note2.updatedAt
            }
        }
        return sortedNotes.sorted { $0.isPinned && !$1.isPinned }
    }
}




struct NotesView: View {
    @StateObject private var viewModel = NotesViewModel()
    @State private var isAddingNote = false
    @State private var editingNote: Note?
    
    var body: some View {
        NavigationView {
            List {
                if !viewModel.sortedNotes().filter({ $0.isPinned }).isEmpty {
                    Section(header: Text("Notes épinglées")) {
                        ForEach(viewModel.sortedNotes().filter { $0.isPinned }) { note in
                            NoteRow(note: note, viewModel: viewModel, editingNote: $editingNote)
                        }
                        
                    }
                    .listRowBackground(Color.yellow.opacity(0.2))
                }
                
                Section(header: Text("Notes")) {
                    ForEach(viewModel.sortedNotes().filter { !$0.isPinned }) { note in
                        NoteRow(note: note, viewModel: viewModel, editingNote: $editingNote)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Notes")
            .toolbar {
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Trier par", selection: $viewModel.sortOption) {
                            ForEach(NotesViewModel.SortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Label("Trier", systemImage: "arrow.up.arrow.down")
                    }
                }
                ToolbarItem(placement:  .navigationBarTrailing) {
                    Button(action: { isAddingNote = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingNote) {
                AddEditNoteView(viewModel: viewModel, isPresented: $isAddingNote, note: nil)
            }
            .sheet(item: $editingNote) { note in
                AddEditNoteView(viewModel: viewModel, isPresented: .constant(true), note: note) {
                    editingNote = nil  // Fermer la note après la save
                }
            }
        }
    }
}

struct NoteRow: View {
    let note: Note
    @ObservedObject var viewModel: NotesViewModel
    @Binding var editingNote: Note?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(note.title)
                    .font(.headline)
                Spacer()
                Button(action: {
                    viewModel.togglePin(for: note)
                }) {
                    Image(systemName: note.isPinned ? "pin.fill" : "pin").foregroundColor(note.isPinned ? Color.yellow : Color.blue)
                }
            }
            Text(note.content)
                .font(.subheadline)
                .lineLimit(2)
                .foregroundColor(.gray)
            Text("Mise à jour : \(formattedDate(note.updatedAt))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                if let index = viewModel.notes.firstIndex(where: { $0.id == note.id }) {
                    viewModel.deleteNote(at: IndexSet(integer: index))
                }
            } label: {
                Label("Supprimer", systemImage: "trash")
            }
            
            Button {
                editingNote = note
            } label: {
                Label("Modifier", systemImage: "pencil")
                    .background(Color.blue)
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct AddEditNoteView: View {
    @ObservedObject var viewModel: NotesViewModel
    @Binding var isPresented: Bool
    let note: Note?
    var onSave: (() -> Void)?
    
    @State private var title: String
    @State private var content: String
    @State private var isPinned: Bool
    
    init(viewModel: NotesViewModel, isPresented: Binding<Bool>, note: Note?, onSave: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self._isPresented = isPresented
        self.note = note
        self.onSave = onSave
        self._title = State(initialValue: note?.title ?? "")
        self._content = State(initialValue: note?.content ?? "")
        self._isPinned = State(initialValue: note?.isPinned ?? false)
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Titre", text: $title)
                TextEditor(text: $content)
                    .frame(minHeight: 100)
                Toggle("Épingler", isOn: $isPinned)
                
                if let note = note {
                    Section(header: Text("Note Info")) {
                        Text("Créée le : \(formattedDate(note.createdAt))")
                        Text("Mise à jour : \(formattedDate(note.updatedAt))")
                    }
                }
                
                Button(note == nil ? "Ajouter" : "Mettre à jour") {
                    if let existingNote = note {
                        let updatedNote = Note(id: existingNote.id, title: title, content: content, isPinned: isPinned, createdAt: existingNote.createdAt, updatedAt: Date())
                        viewModel.updateNote(updatedNote)
                    } else {
                        let newNote = Note(title: title, content: content, isPinned: isPinned)
                        viewModel.addNote(newNote)
                    }
                    isPresented = false
                    onSave?()
                }
                .disabled(title.isEmpty || content.isEmpty)
            }
            .navigationTitle(note == nil ? "Nouvelle note" : "Modifier la note")
            .navigationBarItems(trailing: Button("Annuler") {
                isPresented = false
            })
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}


// Extension pour créer une couleur à partir d'une valeur hexadécimale (Généré par IA)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

