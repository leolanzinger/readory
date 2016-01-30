//
//  ViewController.swift
//  Created by Kyle Weiner on 10/17/14.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var countLabel: CountLabel!
    
    var selectedPlayers:Int!
    var players:Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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