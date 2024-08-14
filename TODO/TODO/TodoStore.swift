//
//  TodoStore.swift
//  sadari
//
//  Created by 윤예성 on 7/29/24.
//
import Foundation

class TodoStore: ObservableObject {
    @Published var todos: [Todo] = [] {
        didSet {
            saveTodos()
        }
    }

    private let todosKey = "todos"

    init() {
        loadTodos()
    }

    func add(_ todo: Todo) {
        todos.append(todo)
    }

    func remove(_ todo: Todo) {
        todos.removeAll { $0.id == todo.id }
    }

    func toggleDone(_ todo: Todo) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index].isDone.toggle()
        }
    }

    private func saveTodos() {
        if let encoded = try? JSONEncoder().encode(todos) {
            UserDefaults.standard.set(encoded, forKey: todosKey)
        }
    }

    private func loadTodos() {
        if let savedTodos = UserDefaults.standard.data(forKey: todosKey) {
            if let decodedTodos = try? JSONDecoder().decode([Todo].self, from: savedTodos) {
                todos = decodedTodos
            }
        }
    }
}
