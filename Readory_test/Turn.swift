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
    var hints = [Int]()
    
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
        if (firstCard % 2 == 0) {
            if (secondCard == (firstCard + 1)) {
                return true
            }
            else {
                return false
            }
        }
        else {
            if (secondCard == (firstCard - 1)) {
                return true
            }
            else {
                return false
            }
        }
    }
    
    /*
        Check if a card should be displayed as hint
    */
    func checkHint(marker_id :Int) -> Bool {
        if (self.hints.contains(marker_id)) {
            return true
        }
        else {
            // check if the other corresponding card hint is already displayed
            if (marker_id % 2 == 0) {
                if (self.hints.contains(marker_id + 1)) {
                    return false
                }
                else {
                    self.hints.append(marker_id)
                    return true
                }
            }
            else {
                if (self.hints.contains(marker_id - 1)) {
                    return false
                }
                else {
                    self.hints.append(marker_id)
                    return true
                }

            }
        }
    }
    
    /*
        This method explicitly tells whether or not the recognized 
        marker is the same card as the chosen one
    */
    func findCorrectHint(marker_id :Int) -> Bool {
        if (marker_id % 2 == 0) {
            if (firstCard == marker_id + 1 - 10) {
                return true
            }
            else {
                return false
            }
        }
        else {
            if (firstCard == marker_id - 1 - 10) {
                return true
            }
            else {
                return false
            }
        }
    }
}