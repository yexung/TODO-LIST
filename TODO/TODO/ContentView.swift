//
//  ContentView.swift
//  sadari
//
//  Created by 윤예성 on 7/29/24.
//
import SwiftUI
import UserNotifications

struct ContentView: View {
    @ObservedObject var store = TodoStore()
    @State private var newTodoTitle: String = ""
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var newTodoCategory: String = ""
    @State private var categories = ["Work", "Personal", "Other"]
    @State private var showAddTodoSheet = false
    @State private var repeatOption = "None"
    @State private var repeatOptions = ["None", "Daily", "Weekdays", "Weekends"]
    @State private var showDeleteConfirmation = false
    @State private var todoToDelete: Todo?

    var body: some View {
        NavigationView {
            VStack {
                // 날짜 선택기
                DatePicker("날짜 선택", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                
                // 텍스트 필드와 추가 버튼
                HStack {
                    TextField("새 할 일", text: $newTodoTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.leading, 20)

                    Button(action: {
                        showAddTodoSheet.toggle()
                    }) {
                        Image(systemName: "plus")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 20)

                // 할 일 목록
                List {
                    ForEach(store.todos.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) && (newTodoCategory.isEmpty || $0.category == newTodoCategory) }) { todo in
                        HStack {
                            Button(action: {
                                store.toggleDone(todo)
                            }) {
                                Image(systemName: todo.isDone ? "checkmark.square" : "square")
                                    .foregroundColor(todo.isDone ? .green : .gray)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            Text(todo.title)
                                .strikethrough(todo.isDone, color: .black)
                                .foregroundColor(todo.isDone ? .gray : .primary)
                            
                            Spacer()
                            
                            Text(todo.category)
                                .foregroundColor(.secondary)
                        }
                        .contextMenu {
                            Button(action: {
                                todoToDelete = todo
                                showDeleteConfirmation.toggle()
                            }) {
                                Text("삭제")
                                Image(systemName: "trash")
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .frame(minHeight: 400) // 최소 높이 설정
            }
            .navigationBarTitle("할 일 목록", displayMode: .inline)
            .onAppear {
                requestNotificationPermission()
            }
            .sheet(isPresented: $showAddTodoSheet) {
                VStack {
                    Text("할 일 추가")
                        .font(.headline)
                        .padding()

                    TextField("할 일 제목", text: $newTodoTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    DatePicker("시간 선택", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(WheelDatePickerStyle())
                        .padding()

                    Picker("카테고리 선택", selection: $newTodoCategory) {
                        ForEach(categories, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()

                    Picker("반복", selection: $repeatOption) {
                        ForEach(repeatOptions, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()

                    HStack {
                        Button(action: {
                            showAddTodoSheet = false
                        }) {
                            Text("취소")
                                .foregroundColor(.red)
                                .padding()
                        }

                        Spacer()

                        Button(action: {
                            addTodo()
                            showAddTodoSheet = false
                        }) {
                            Text("추가")
                                .padding()
                        }
                    }
                    .padding()
                }
                .padding()
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("삭제 확인"),
                    message: Text("이 항목을 삭제하시겠습니까?"),
                    primaryButton: .destructive(Text("삭제")) {
                        if let todo = todoToDelete {
                            deleteSingleOrAllTodos(todo: todo)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private func addTodo() {
        guard !newTodoTitle.isEmpty else { return }
        let newTodo = Todo(title: newTodoTitle, isDone: false, date: selectedDate, time: selectedTime, category: newTodoCategory, repeatOption: repeatOption)
        store.add(newTodo)
        
        scheduleNotification(for: newTodo)
        
        if repeatOption != "None" {
            var dateComponents = DateComponents()
            switch repeatOption {
            case "Daily":
                dateComponents.day = 1
            case "Weekdays":
                dateComponents.day = 1
            case "Weekends":
                dateComponents.day = 1
            default:
                break
            }
            
            var nextDate = Calendar.current.date(byAdding: dateComponents, to: selectedDate)!
            
            for _ in 1...10 { // 예시로 10번 반복
                if repeatOption == "Weekdays" && (Calendar.current.isDateInWeekend(nextDate) || Calendar.current.isDateInWeekend(nextDate.addingTimeInterval(60*60*24))) {
                    nextDate = Calendar.current.date(byAdding: .day, value: 1, to: nextDate)!
                    continue
                }
                
                if repeatOption == "Weekends" && !Calendar.current.isDateInWeekend(nextDate) {
                    nextDate = Calendar.current.date(byAdding: .day, value: 1, to: nextDate)!
                    continue
                }
                
                let repeatedTodo = Todo(title: newTodoTitle, isDone: false, date: nextDate, time: selectedTime, category: newTodoCategory, repeatOption: repeatOption)
                store.add(repeatedTodo)
                scheduleNotification(for: repeatedTodo)
                nextDate = Calendar.current.date(byAdding: dateComponents, to: nextDate)!
            }
        }

        newTodoTitle = ""
        newTodoCategory = ""
    }

    private func scheduleNotification(for todo: Todo) {
        let content = UNMutableNotificationContent()
        content.title = "Todo-List"
        content.body = todo.title
        content.sound = .default

        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: todo.date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: todo.time)
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: todo.id.uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    private func deleteSingleOrAllTodos(todo: Todo) {
        let todosToDelete = store.todos.filter { $0.title == todo.title && $0.category == todo.category && $0.repeatOption == todo.repeatOption }
        
        for todo in todosToDelete {
            store.remove(todo)
            removeNotification(for: todo)
        }
    }

    private func removeNotification(for todo: Todo) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [todo.id.uuidString])
    }

    private func deleteTodo(at offsets: IndexSet) {
        offsets.map { store.todos.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) && (newTodoCategory.isEmpty || $0.category == newTodoCategory) }[$0] }.forEach { todo in
            store.remove(todo)
            removeNotification(for: todo)
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission request error: \(error)")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
