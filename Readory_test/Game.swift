//
//  game.swift
//  Readory_test
//
//  Created by Leonardo Lanzinger on 19/01/16.
//  Copyright © 2016 Leonardo Lanzinger. All rights reserved.
//
//  Game model class that controls the logic of the game
//

import Foundation

@objc public class Game : NSObject {
    
    var players:Int!
    var turn:Int!
    var playingPlayer:Int!
    var score = [Int](count: 6, repeatedValue: 0)
    var cards = [Card]()
    var matches:Int!
    var n_pairs:Int!
    var played_cards = [Card]()
    var playerNames = ["LAMA", "TIGER", "PARROT", "WOLF", "FOX"]
    var imageNames = ["lama_cl_xxhdpi", "lion_cl_xxhdpi", "parrot_cl_xxhdpi", "wolf_cl_xxhdpi", "fox_cl_xxhdpi"]
    var turn_types = ["misspelling", "translation", "association", "synonym"]
    var turn_type: Int!
    
    class var swiftSharedInstance: Game {
        struct Singleton {
            static let instance = Game()
        }
        return Singleton.instance
    }
    
    class func sharedInstance() -> Game {
        return Game.swiftSharedInstance
    }
    
    override init() {
        super.init()
        self.turn = 1
        self.playingPlayer = 1
        self.matches = 0
        self.turn_type = 0
        self.played_cards = []
        
        // parse cards.xml
        guard let
            xmlPath = NSBundle.mainBundle().pathForResource("cards", ofType: "xml"),
            data = NSData(contentsOfFile: xmlPath)
            else { return }
        do {
            let xmlDoc = try AEXMLDocument(xmlData: data)
            for card in xmlDoc.root["card"].all! {
                let c:Card = Card()
                c.id = Int(card.attributes["id"]!)
                c.front_marker = Int(card.attributes["front"]!)
                c.back_marker = Int(card.attributes["back"]!)
                c.hint = Int(card.attributes["hint"]!)
                c.corresponding = Int(card.attributes["corresponding"]!)
                self.cards.append(c)
            }
            self.n_pairs = (self.cards.count) / 2
        }
        catch {
            print("\(error)")
        }
    }
    
    //  set the number of players that are going to use the game 
    //  and set the score to zero for all participants
    func setPlayers (num_players: Int) {
        self.players = num_players
        for index in 0...(num_players) {
            self.score[index] = 0
        }
    }
    
    //  perform these two functions after every turn to update
    //  the turn mechanism
    func turnWon() -> Bool{
        turn = turn + 1
        score[playingPlayer]++
        matches = matches + 1
        turn_type = (turn_type + 1) % (turn_types.count + 1)
        if (matches == n_pairs) {
            return true
        }
        else {
            return false
        }
    }
    
    func turnLost() {
        turn = turn + 1
        playingPlayer = (playingPlayer + 1) % (players + 1)
        if (playingPlayer == 0) {
            playingPlayer = 1
        }
    }
    
    // return a card object from a given marker id and its type
    func findCardFromMarker(marker_id:Int, marker_type:String) -> Card {
        if (marker_type == "front") {
            return self.cards.filter{$0.front_marker! == marker_id}.first!
        }
        else if (marker_type == "back") {
            return self.cards.filter{$0.back_marker! == marker_id}.first!
        }
        else {
            return Card()
        }
    }
    
    // return the id of all available markers
    func getAllMarkers() -> [Int] {
        var markers = [Int]()
        for card in self.cards {
            markers.append(card.front_marker!)
            markers.append(card.back_marker!)
        }
        return markers
    }
    
    // return the id of the lowest back marker
    func getLowestBackMarker() -> Int {
        return self.cards[0].back_marker!
    }
    
    func setAlreadyPlayed(fCard : Card, sCard : Card) {
        played_cards.append(fCard)
        played_cards.append(sCard)
    }
    
    func getCurrentTurnType() -> NSString {
        return turn_types[turn_type]
    }
    
    // custom function TODO: UPDATE IT
    func getFirstMarkerModel() -> NSString {
        let model = self.cards[0].get3dModel(turn_types[turn_type])
        return model
    }
    
    // get the model index depending on the marker
    func getModelFromMarker(marker_id: Int) -> Int {
        let c = self.cards.filter{$0.back_marker! == marker_id}.first!
        return c.hint
    }
}