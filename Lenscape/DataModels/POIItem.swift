//
//  POIItem.swift
//  Lenscape
//
//  Created by Thongrapee Panyapatiphan on 3/30/2561 BE.
//  Copyright © 2561 Lenscape. All rights reserved.
//

import Foundation

/// Point of Interest Item which implements the GMUClusterItem protocol.
class POIItem: NSObject, GMUClusterItem {
    var position: CLLocationCoordinate2D
    var name: String!
    
    init(position: CLLocationCoordinate2D, name: String) {
        self.position = position
        self.name = name
    }
}