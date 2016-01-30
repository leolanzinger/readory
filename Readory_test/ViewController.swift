//
//  ViewController.swift
//  Created by Kyle Weiner on 10/17/14.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var playersLabel: UILabel!
    
    var selectedPlayers:Int!
    var players:Int! = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // set the number of players label only if 
        // number of players is set
        if (players > 0) {
            playersLabel.text = "You are playing with " + String(players) + " player"
            if (players > 1) {
                playersLabel.text = playersLabel.text! + "s"
            }
        }
    }
    
    @IBAction func onePlayer(sender: AnyObject) {
        self.selectedPlayers = 1
        performSegueWithIdentifier("confirmGame", sender: self)
    }
    
    
    @IBAction func twoPlayers(sender: AnyObject) {
        self.selectedPlayers = 2
        performSegueWithIdentifier("confirmGame", sender: self)
    }
    
    @IBAction func threePlayers(sender: AnyObject) {
        self.selectedPlayers = 3
        performSegueWithIdentifier("confirmGame", sender: self)
    }
    
    @IBAction func fourPlayers(sender: AnyObject) {
        self.selectedPlayers = 4
        performSegueWithIdentifier("confirmGame", sender: self)
    }
    
    @IBAction func fivePlayers(sender: AnyObject) {
        self.selectedPlayers = 5
        performSegueWithIdentifier("confirmGame", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "startGame") {
            Game.init()
            Game.sharedInstance.setPlayers(self.players)
        }
        else if (segue.identifier == "confirmGame") {
            let secondViewController = segue.destinationViewController as! ViewController
            let plyrs = self.selectedPlayers as Int
            secondViewController.players = plyrs
        }
    }
    
}