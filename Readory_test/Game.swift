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

public class Game {
    
    var players:Int!
    var turn:Int!
    var playingPlayer:Int!
    var score = [Int](count: 6, repeatedValue: 0)
    var matches:Int!
    let n_pairs = 5
    var playerNames = ["LAMA", "TIGER", "PARROT", "WOLF", "FOX"]
    var imageNames = ["lama_cl_xxhdpi", "lion_cl_xxhdpi", "parrot_cl_xxhdpi", "wolf_cl_xxhdpi", "fox_cl_xxhdpi"]
    
    class var sharedInstance: Game {
        struct Singleton {
            static let instance = Game()
        }
        return Singleton.instance
    }
    
    init() {
        self.turn = 1
        self.playingPlayer = 1
        self.matches = 0
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
    
}