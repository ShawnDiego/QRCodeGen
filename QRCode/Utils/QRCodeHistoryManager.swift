import Foundation
import SwiftUI
import CoreData

/// 二维码历史记录管理器
class QRCodeHistoryManager: ObservableObject {
    private let coreDataStack = CoreDataStack.shared
    @Published var historyItems: [QRCodeHistoryItem] = []
    
    init() {
        print("历史记录管理器已初始化 - CoreData持久化存储模式")
        loadHistoryItems()
    }
    
    // MARK: - 加载历史记录
    func loadHistoryItems() {
        // 在后台线程执行数据库操作和图片生成，避免UI卡顿
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let request: NSFetchRequest<QRCodeHistoryEntity> = QRCodeHistoryEntity.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(keyPath: \QRCodeHistoryEntity.createTime, ascending: false)]
                
                let entities = try self.coreDataStack.context.fetch(request)
                let items = entities.compactMap { $0.toHistoryItem }
                
                // 在主线程更新UI
                DispatchQueue.main.async {
                    self.historyItems = items
                    print("成功加载\(items.count)个历史记录")
                }
            } catch {
                print("加载历史记录失败: \(error)")
                // 如果CoreData失败，在主线程清空历史记录
                DispatchQueue.main.async {
                    self.historyItems = []
                }
            }
        }
    }
    
    // MARK: - 添加历史记录
    func addHistoryItem(_ item: QRCodeHistoryItem) {
        // 检查是否已存在相同文本的记录
        if historyItems.contains(where: { $0.text == item.text }) {
            return
        }
        
        // 先在UI中立即显示，提供更好的用户体验
        historyItems.insert(item, at: 0)
        
        // 在后台线程保存到CoreData
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let entity = QRCodeHistoryEntity.from(item, context: self.coreDataStack.context)
                try self.coreDataStack.context.save()
                print("历史记录已保存到数据库")
            } catch {
                print("保存历史记录失败: \(error)")
                // 如果保存失败，从UI中移除该项目
                DispatchQueue.main.async {
                    if let index = self.historyItems.firstIndex(where: { $0.id == item.id }) {
                        self.historyItems.remove(at: index)
                    }
                }
            }
        }
    }
    
    // MARK: - 批量添加历史记录
    func addBatchHistoryItems(_ items: [QRCodeHistoryItem]) {
        let newItems = items.filter { item in
            !historyItems.contains(where: { $0.text == item.text })
        }
        
        if newItems.isEmpty { return }
        
        // 先在UI中立即显示
        historyItems.insert(contentsOf: newItems, at: 0)
        
        // 在后台线程批量保存到CoreData
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                for item in newItems {
                    _ = QRCodeHistoryEntity.from(item, context: self.coreDataStack.context)
                }
                try self.coreDataStack.context.save()
                print("批量保存\(newItems.count)个历史记录到数据库")
            } catch {
                print("批量保存历史记录失败: \(error)")
                // 如果保存失败，从UI中移除这些项目
                DispatchQueue.main.async {
                    for item in newItems {
                        if let index = self.historyItems.firstIndex(where: { $0.id == item.id }) {
                            self.historyItems.remove(at: index)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 删除历史记录
    func deleteHistoryItem(withId id: UUID) {
        // 先从UI中立即移除
        if let index = historyItems.firstIndex(where: { $0.id == id }) {
            let removedItem = historyItems.remove(at: index)
            
            // 在后台线程从CoreData删除
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                do {
                    let request: NSFetchRequest<QRCodeHistoryEntity> = QRCodeHistoryEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                    
                    let entities = try self.coreDataStack.context.fetch(request)
                    for entity in entities {
                        self.coreDataStack.context.delete(entity)
                    }
                    try self.coreDataStack.context.save()
                    print("历史记录已从数据库删除")
                } catch {
                    print("删除历史记录失败: \(error)")
                    // 如果删除失败，重新添加到UI
                    DispatchQueue.main.async {
                        self.historyItems.insert(removedItem, at: index)
                    }
                }
            }
        }
    }
    
    // MARK: - 删除所有历史记录
    func deleteAllHistoryItems() {
        // 先备份当前记录，以防删除失败需要恢复
        let backupItems = historyItems
        
        // 立即清空UI
        historyItems.removeAll()
        
        // 在后台线程从CoreData删除
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let request: NSFetchRequest<NSFetchRequestResult> = QRCodeHistoryEntity.fetchRequest()
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
                
                try self.coreDataStack.context.execute(deleteRequest)
                try self.coreDataStack.context.save()
                print("所有历史记录已从数据库删除")
            } catch {
                print("删除所有历史记录失败: \(error)")
                // 如果删除失败，恢复UI中的记录
                DispatchQueue.main.async {
                    self.historyItems = backupItems
                }
            }
        }
    }
    
    // MARK: - 根据批次时间戳获取记录
    func getBatchItems(with timestamp: Date) -> [QRCodeHistoryItem] {
        return historyItems.filter { $0.batchTimestamp == timestamp }
    }
} 