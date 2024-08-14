//
//  Todo.swift
//  sadari
//
//  Created by 윤예성 on 7/29/24.
//

import Foundation

struct Todo: Identifiable, Codable {
    let id = UUID()
    var title: String
    var isDone: Bool
    var date: Date
    var time: Date
    var category: String
    var repeatOption: String
}
