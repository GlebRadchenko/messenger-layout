//
//  TestDiffable.swift
//  MessengerLayout
//
//  Created by Gleb Radchenko on 7/10/18.
//  Copyright © 2018 Gleb Radchenko. All rights reserved.
//

import Foundation
import MessengerKit

public class Message: GroupDiffable {
    public typealias Group = DayGroup
    
    var id: Int
    var date: Date
    
    init(id: Int, date: Date) {
        self.id = id
        self.date = date
    }
    
    public static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Date {
    public func dayDate() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: self)
        return calendar.date(from: components)!
    }
}

public class DayGroup: DiffableGroup {
    public typealias Item = Message
    public typealias Identifier = String
    
    public var id: String
    public var items: [Message]
    
    public var date: Date
    
    required public init(items: [Message]) {
        let fItem = items.first!
        self.id = DayGroup.id(for: fItem)
        self.items = items
        self.date = fItem.date.dayDate()
    }
    
    static public func id(for item: Message) -> String {
        let calendar = Calendar.current
        let date = item.date.dayDate()
        
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        return "\(year)-\(month)-\(day)"
    }
    
    static public func < (lhs: DayGroup, rhs: DayGroup) -> Bool {
        return lhs.date < rhs.date
    }
    
    static public func == (lhs: DayGroup, rhs: DayGroup) -> Bool {
        return lhs.id == rhs.id
    }
}

public class MessengerStorage: DiffableGroupStorage<DayGroup> {
    
}

public class TestDiffable {
    public var storage: MessengerStorage
    
    public init() {
        self.storage = MessengerStorage(items: [])
    }
    
    public func test1() {
        self.storage = MessengerStorage(items: [m(id: 1)])
        let newMessages = [m(id: 2), m(id: 3), m(id: 4)]
        let updates = storage.merge(items: newMessages)
        print(updates)
    }
    
    public func test2() {
        self.storage = MessengerStorage(items: [m(id: 2), m(id: 3), m(id: 4)])
        let newMessages = [m(id: 3)]
        let updates = storage.merge(items: newMessages)
        print(updates)
    }
    
    public func test3() {
        self.storage = MessengerStorage(items: messages(from: 0, to: 10000))
        let updates = storage.merge(items: messages(from: 5000, to: 20000))
        print(updates)
    }
    
    func m(id: Int) -> Message {
        return Message(id: id, date: Date())
    }
    
    func messages(from a: Int, to b: Int) -> [Message] {
        return (a...b).map { Message(id: $0, date: Date()) }
    }
}
