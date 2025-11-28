//
//  WriteNotesView.swift
//  student-res
//
//  Created by Prabhnoor Kaur
//

import SwiftUI
import PhotosUI

struct WriteNotesView: View {
    @State private var personalNotes: [PersonalNote] = []
    @State private var showAddNote = false
    @State private var selectedNote: PersonalNote? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if personalNotes.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "note.text")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No notes yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Tap + to create your first note")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(personalNotes.sorted(by: { $0.updatedAt > $1.updatedAt })) { note in
                            PersonalNoteRowView(note: note) {
                                selectedNote = note
                            }
                        }
                        .onDelete(perform: deleteNotes)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddNote = true
                    }) {
                        Image(systemName: "square.and.pencil")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showAddNote) {
                AddPersonalNoteView(onSave: { title, content, attachments in
                    addPersonalNote(title: title, content: content, attachments: attachments)
                })
            }
            .sheet(item: $selectedNote) { note in
                EditPersonalNoteView(note: note, onSave: { updatedNote in
                    updatePersonalNote(updatedNote)
                }, onDelete: {
                    deleteNote(note)
                })
            }
            .onAppear {
                loadPersonalNotes()
            }
        }
    }
    
    private func loadPersonalNotes() {
        if let data = UserDefaults.standard.data(forKey: "personalNotes"),
           let decoded = try? JSONDecoder().decode([PersonalNote].self, from: data) {
            personalNotes = decoded
        }
    }
    
    private func savePersonalNotes() {
        if let encoded = try? JSONEncoder().encode(personalNotes) {
            UserDefaults.standard.set(encoded, forKey: "personalNotes")
        }
    }
    
    private func addPersonalNote(title: String, content: String, attachments: [String]) {
        let newNote = PersonalNote(
            id: UUID().uuidString,
            title: title,
            content: content,
            subject: nil,
            semester: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        personalNotes.append(newNote)
        savePersonalNotes()
        showAddNote = false
    }
    
    private func updatePersonalNote(_ note: PersonalNote) {
        if let index = personalNotes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = note
            updatedNote.updatedAt = Date()
            personalNotes[index] = updatedNote
            savePersonalNotes()
        }
        selectedNote = nil
    }
    
    private func deleteNote(_ note: PersonalNote) {
        personalNotes.removeAll { $0.id == note.id }
        savePersonalNotes()
        selectedNote = nil
    }
    
    private func deleteNotes(at offsets: IndexSet) {
        personalNotes.remove(atOffsets: offsets)
        savePersonalNotes()
    }
}

struct PersonalNoteRowView: View {
    let note: PersonalNote
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(note.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Text(note.content)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                HStack {
                    Text(note.updatedAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(note.updatedAt, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

struct AddPersonalNoteView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var content = ""
    @State private var attachments: [String] = []
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage? = nil
    @State private var showDocumentPicker = false
    
    let onSave: (String, String, [String]) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextField("Title", text: $title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                    .background(Color(.systemBackground))
                
                Divider()
                
                TextEditor(text: $content)
                    .font(.body)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                
                HStack(spacing: 20) {
                    Button(action: {
                        showImagePicker = true
                    }) {
                        Image(systemName: "photo")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        showDocumentPicker = true
                    }) {
                        Image(systemName: "paperclip")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text("\(content.count) characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(title.isEmpty ? "Untitled" : title, content, attachments)
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                NoteImagePicker(selectedImage: $selectedImage)
            }
        }
    }
}

struct EditPersonalNoteView: View {
    let note: PersonalNote
    let onSave: (PersonalNote) -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String
    @State private var content: String
    @State private var attachments: [String] = []
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage? = nil
    @State private var showDocumentPicker = false
    
    init(note: PersonalNote, onSave: @escaping (PersonalNote) -> Void, onDelete: @escaping () -> Void) {
        self.note = note
        self.onSave = onSave
        self.onDelete = onDelete
        _title = State(initialValue: note.title)
        _content = State(initialValue: note.content)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextField("Title", text: $title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                    .background(Color(.systemBackground))
                
                Divider()
                
                TextEditor(text: $content)
                    .font(.body)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                
            
                HStack(spacing: 20) {
                    Button(action: {
                        showImagePicker = true
                    }) {
                        Image(systemName: "photo")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        showDocumentPicker = true
                    }) {
                        Image(systemName: "paperclip")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button(role: .destructive, action: {
                            onDelete()
                            dismiss()
                        }) {
                            Label("Delete Note", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    
                    Text("\(content.count) characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
            }
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        var updatedNote = note
                        updatedNote.title = title.isEmpty ? "Untitled" : title
                        updatedNote.content = content
                        onSave(updatedNote)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                NoteImagePicker(selectedImage: $selectedImage)
            }
        }
    }
}

struct NoteImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: NoteImagePicker
        
        init(_ parent: NoteImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    WriteNotesView()
}

