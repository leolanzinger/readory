//
//  Turn.swift
//  Readory_test
//
//  Created by Leonardo Lanzinger on 27/01/16.
//  Copyright © 2016 Leonardo Lanzinger. All rights reserved.
//
//  Model class that controls the flow of a turn and checks the
//  combination of picked cards
//

import Foundation

@objc class Turn: NSObject {
    
    var firstCard: Int!
    var secondCard: Int!
    
    override init() {
        super.init()
        self.firstCard = -1
        self.secondCard = -1
    }
    
    /*
        Check if the first card is not already selected, then add the scanned card
        (if it's a front card -> marker is less than 10). If first card is already selected,
        then add the scanned front card to the second card.
        Return TRUE only when the turn is complete and checkTwoCards needs to be called
        by the viewController.
    */
    func checkCard(marker_id :Int) -> Int{
        if (self.firstCard == -1 && self.secondCard == -1 && marker_id < 10) {
            self.firstCard = marker_id
            return 1
        }
        else if (self.firstCard != -1 && self.firstCard != marker_id && self.secondCard == -1 && marker_id < 10) {
            self.secondCard = marker_id
            return 2
        }
        else {
            return 0
        }
    }
    
    /*
        Check if the two picked cards are the same or not.
        Table with card combination can be found at: 
        https://docs.google.com/spreadsheets/d/1b3wDgCXIFUgwYHqEf_eoiWoAzkr0y-xHb8ZA4aSK8eo/edit#gid=0
    */
    func checkTwoCards() -> Bool {
        switch firstCard {
        case 0:
            if (secondCard == 1) {
                return true
            }
            else {
                return false
            }
        case 1:
            if (secondCard == 0) {
                return true
            }
            else {
                return false
            }
        case 2:
            if (secondCard == 3) {
                return true
            }
            else {
                return false
            }
        case 3:
            if (secondCard == 2) {
                return true
            }
            else {
                return false
            }
        case 4:
            if (secondCard == 5) {
                return true
            }
            else {
                return false
            }
        case 5:
            if (secondCard == 4) {
                return true
            }
            else {
                return false
            }
        case 6:
            if (secondCard == 7) {
                return true
            }
            else {
                return false
            }
        case 7:
            if (secondCard == 6) {
                return true
            }
            else {
                return false
            }
        case 8:
            if (secondCard == 9) {
                return true
            }
            else {
                return false
            }
        case 9:
            if (secondCard == 8) {
                return true
            }
            else {
                return false
            }
        default:
            return false
        }
    }
}