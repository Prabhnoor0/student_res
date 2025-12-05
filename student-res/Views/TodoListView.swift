//
//  TodoListView.swift
//  student-res
//
//  Created by Prabhnoor Kaur
//

import SwiftUI

struct TodoListView: View {
    @State private var todos: [TodoItem] = []
    @State private var newTodoTitle = ""
    @State private var newTodoDescription = ""
    @State private var showAddTodo = false
    @State private var selectedTodo: TodoItem? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if todos.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "checklist")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No tasks yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Tap + to add your first task")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(todos.filter { !$0.isCompleted }) { todo in
                            TodoRowView(todo: todo, onToggle: {
                                toggleTodo(todo)
                            }, onDelete: {
                                deleteTodo(todo)
                            })
                        }
                        
                        if todos.contains(where: { $0.isCompleted }) {
                            Section(header: Text("Completed")) {
                                ForEach(todos.filter { $0.isCompleted }) { todo in
                                    TodoRowView(todo: todo, onToggle: {
                                        toggleTodo(todo)
                                    }, onDelete: {
                                        deleteTodo(todo)
                                    })
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("To-Do List")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddTodo = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showAddTodo) {
                AddTodoView(onSave: { title, description, dueDate in
                    addTodo(title: title, description: description, dueDate: dueDate)
                })
            }
            .onAppear {
                loadTodos()
            }
        }
    }
    
    private func loadTodos() {
        if let data = UserDefaults.standard.data(forKey: "todos"),
           let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            todos = decoded
        }
    }
    
    private func saveTodos() {
        if let encoded = try? JSONEncoder().encode(todos) {
            UserDefaults.standard.set(encoded, forKey: "todos")
        }
    }
    
    private func addTodo(title: String, description: String?, dueDate: Date?) {
        let newTodo = TodoItem(
            id: UUID().uuidString,
            title: title,
            description: description,
            isCompleted: false,
            dueDate: dueDate,
            createdAt: Date()
        )
        todos.append(newTodo)
        saveTodos()
        showAddTodo = false
    }
    
    private func toggleTodo(_ todo: TodoItem) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index].isCompleted.toggle()
            saveTodos()
        }
    }
    
    private func deleteTodo(_ todo: TodoItem) {
        todos.removeAll { $0.id == todo.id }
        saveTodos()
    }
}

struct TodoRowView: View {
    let todo: TodoItem
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(todo.isCompleted ? .green : .gray)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .font(.headline)
                    .strikethrough(todo.isCompleted)
                    .foregroundColor(todo.isCompleted ? .secondary : .primary)
                
                if let description = todo.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .strikethrough(todo.isCompleted)
                }
                
                if let dueDate = todo.dueDate {
                    HStack {
                        Image(systemName: "calendar")
                        Text(dueDate, style: .date)
                    }
                    .font(.caption)
                    .foregroundColor(dueDate < Date() && !todo.isCompleted ? .red : .secondary)
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

struct AddTodoView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate: Date? = nil
    @State private var showDatePicker = false
    
    let onSave: (String, String?, Date?) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task Title", text: $title)
                    
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Due Date")) {
                    Toggle("Set Due Date", isOn: Binding(
                        get: { dueDate != nil },
                        set: { if $0 { dueDate = Date() } else { dueDate = nil } }
                    ))
                    
                    if dueDate != nil {
                        DatePicker("Due Date", selection: Binding(
                            get: { dueDate ?? Date() },
                            set: { dueDate = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(title, description.isEmpty ? nil : description, dueDate)
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

#Preview {
    TodoListView()
}

