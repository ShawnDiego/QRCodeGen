//
//  Item.swift
//  QRCode
//
//  Created by 邵文萱(ShaoWenxuan)-顺丰科技技术集团 on 2024/12/23.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
