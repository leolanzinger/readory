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
    
    var firstCard: Card!
    var secondCard: Card!
    var hints = [Card]()
    var g: Game!
    
    override init() {
        super.init()
        self.firstCard = nil
        self.secondCard = nil
        g = Game.swiftSharedInstance
    }
    
    /*
        Check if the first card is not already selected, then add the scanned card
        (if it's a front card -> marker is less than the first card back marker). If first card is already selected,
        then add the scanned front card to the second card.
        Return TRUE only when the turn is complete and checkTwoCards needs to be called
        by the viewController.
    */
    func checkCard(m_id :Int) -> Int{
        let cards = g.cards
        let pl_card = g.findCardFromMarker(m_id, marker_type: "front")
        if (self.firstCard == nil && self.secondCard == nil && !g.played_cards.contains(pl_card)) {
            self.firstCard = pl_card
            return 1
        }
        else if (self.firstCard != nil && self.firstCard.front_marker != m_id && self.secondCard == nil && !g.played_cards.contains(pl_card)) {
            self.secondCard = pl_card
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
        if (firstCard.corresponding == secondCard.id) {
            g.setAlreadyPlayed(firstCard, sCard: secondCard)
            return true
        }
        else {
            return false
        }
    }
    
    /*
        Check if a card should be displayed as hint
    */
    func checkHint(marker_id :Int) -> Bool {
        var pl_card = g.findCardFromMarker(marker_id, marker_type: "back")
        if (!g.played_cards.contains(pl_card)) {
            if (self.hints.contains(g.findCardFromMarker(marker_id, marker_type: "back"))) {
                return true
            }
            else {
                // check if the other corresponding card hint is already displayed
                var picked_card = g.findCardFromMarker(marker_id, marker_type: "back")
                if (self.hints.contains(g.findCardFromMarker(g.cards[picked_card.corresponding!].back_marker!, marker_type: "back"))) {
                    return false
                }
                else {
                    self.hints.append(picked_card)
                    return true
                }
            }
        }
        else {
            return false
        }
    }
}