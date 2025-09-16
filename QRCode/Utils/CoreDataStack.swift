import Foundation
import CoreData

/// CoreData堆栈管理器
class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()
    
    private init() {}
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "QRCodeDataModel")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("Core Data加载失败: \(error), \(error.userInfo)")
                // 现在应该可以正常工作了，因为用户已经创建了模型文件
            } else {
                print("Core Data成功加载")
            }
        })
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Core Data Saving support
    func save() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                print("Core Data保存成功")
            } catch {
                let nsError = error as NSError
                print("Core Data保存失败: \(nsError), \(nsError.userInfo)")
            }
        }
    }
} 