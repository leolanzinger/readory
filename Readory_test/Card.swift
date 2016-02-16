//
//  Card.swift
//  Readory_test
//
//  Created by Leonardo Lanzinger on 15/02/16.
//  Copyright © 2016 Leonardo Lanzinger. All rights reserved.
//
//  This class represent a card instance
//

import Foundation

class Card: NSObject {

    var id:Int?
    var front_marker:Int?
    var back_marker:Int?
    var hint:Int!
    var corresponding:Int?
    
    func get3dModel(turn_type:String) -> String {
        return "marker_" + "\(hint)" + "_" + turn_type
    }
}
