//
//  ViewController.swift
//  Created by Kyle Weiner on 10/17/14.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var playersLabel: UILabel!
    
    @IBOutlet weak var lionPic: UIImageView!
    @IBOutlet weak var parrotPic: UIImageView!
    @IBOutlet weak var wolfPic: UIImageView!
    @IBOutlet weak var foxPic: UIImageView!
    @IBOutlet weak var lamaPic: UIImageView!
    
    var selectedPlayers:Int!
    var players:Int! = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // set the number of players label only if 
        // number of players is set
        if (players > 0) {
            playersLabel.text = "YOU ARE PLAYING WITH " + String(players) + " PLAYER"
            if (players > 1) {
                playersLabel.text = playersLabel.text! + "S"
                // show lion picture
                lionPic.hidden = false
                if (players > 2) {
                    // show parrot pic
                    parrotPic.hidden = false
                    if (players > 3) {
                        // show wolf pic
                        wolfPic.hidden = false
                        if (players > 4) {
                            // show fox pic
                            foxPic.hidden = false
                        }
                    }
                }
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