//
//  Diffable.swift
//  MessengerLayout
//
//  Created by Gleb Radchenko on 7/10/18.
//  Copyright © 2018 Gleb Radchenko. All rights reserved.
//

import Foundation

public protocol Diffable: class, Equatable {
    
}

public protocol GroupDiffable: Diffable {
    associatedtype Group: DiffableGroup
}

extension GroupDiffable {
    public var groupID: Group.Identifier {
        return Group.id(for: self as! Group.Item)
    }
}

public protocol DiffableGroup: class, Comparable {
    associatedtype Item: GroupDiffable
    associatedtype Identifier: Hashable
    
    var id: Identifier { get }
    
    var items: [Item] { get set }
    
    init(items: [Item])
    
    static func id(for item: Item) -> Identifier
}

extension DiffableGroup {
    @discardableResult
    public func merge(newItems: [Item]) -> [GroupMutateCommand<Self>] {
        var commands: [GroupMutateCommand<Self>] = []
        let currentItemsCount = items.count
        let newItemsCount = newItems.count
        
        let delta = currentItemsCount - newItemsCount
        
        if delta > 0 {
            let deleteCommands: [GroupMutateCommand<Self>] = (newItemsCount..<currentItemsCount)
                .map { .itemCommand(command: .remove(index: $0)) }
            commands.append(contentsOf: deleteCommands)
        } else if delta < 0 {
            let insertCommands: [GroupMutateCommand<Self>] = (currentItemsCount..<newItemsCount)
                .map { .itemCommand(command: .insert(index: $0)) }
            commands.append(contentsOf: insertCommands)
        }
        
        let compareCount = min(currentItemsCount, newItemsCount)
        (0..<compareCount).forEach { (index) in
            let currentItem = items[index]
            let newItem = newItems[index]
            
            if currentItem != newItem {
                commands.append(.itemCommand(command: .update(index: index)))
            }
        }
        
        items = newItems
        return commands
    }
}

public class DiffableGroupStorage<G: DiffableGroup> {
    public typealias Group = G.Item.Group
    public typealias GroupID = Group.Identifier
    
    public fileprivate(set) var groupStorage: [GroupID: G] = [:]
    public fileprivate(set) var orderedGroups: [G] = []
    public fileprivate(set) var groupIndexes: [G.Identifier: Int] = [:]
    
    public init(items: [G.Item]) {
        merge(items: items)
    }
    
    @discardableResult
    public func merge(items: [G.Item]) -> [GroupID: [GroupMutateCommand<Group>]] {
        var changes: [GroupID: [GroupMutateCommand<Group>]] = [:]
        
        let currentGroupIDs = Set(groupStorage.keys)
        let keyedItems = items.keyedElements()
        let newGroupIDs = Set(keyedItems.keys)
        
        let removingGroupIDs = currentGroupIDs.subtracting(newGroupIDs)
        removingGroupIDs.forEach { (groupID) in
            changes[groupID] = [.removeGroup(id: groupID)]
        }
        
        keyedItems.forEach { (groupID, items) in
            if groupStorage[groupID] == nil {
                groupStorage[groupID] = G(items: items)
                changes[groupID] = [.insertGroup(id: groupID)]
            } else {
                guard let groupChanges = groupStorage[groupID]?.merge(newItems: items), !groupChanges.isEmpty else {
                    return
                }
                
                changes[groupID] = groupChanges as? [GroupMutateCommand<Group>]
            }
        }
        
        orderGroups()
        
        return changes
    }
    
    fileprivate func orderGroups() {
        orderedGroups = groupStorage.values.sorted()
        orderedGroups.enumerated().forEach { (index, group) in
            groupIndexes[group.id] = index
        }
    }
    
    public func index(for group: G) -> Int {
        return groupIndexes[group.id]!
    }
}

extension Collection where Element: GroupDiffable {
    func keyedElements() -> [Element.Group.Identifier: [Element]] {
        var storage: [Element.Group.Identifier: [Element]] = [:]
        
        forEach { (element) in
            let groupID = element.groupID
            if storage[groupID] == nil {
                storage[groupID] = []
            }
            
            storage[groupID]?.append(element)
        }
        
        return storage
    }
}

//MARK: - Commands
public enum GroupMutateCommand<G: DiffableGroup> {
    case insertGroup(id: G.Identifier)
    case removeGroup(id: G.Identifier)
    
    case itemCommand(command: ItemMutateCommand)
}

public enum ItemMutateCommand {
    case insert(index: Int)
    case remove(index: Int)
    case update(index: Int)
    case move(fromIndex: Int, toIndex: Int)
}
