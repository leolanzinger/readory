//
//  ViewController.swift
//  Created by Kyle Weiner on 10/17/14.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var countLabel: CountLabel!
    
    var players:Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onePlayerSelected(sender: AnyObject) {
        self.players = 1
        performSegueWithIdentifier("startGame", sender: self)
    }
    @IBAction func twoPlayersSelected(sender: AnyObject) {
        self.players = 2
        performSegueWithIdentifier("startGame", sender: self)
    }
    
    @IBAction func threePlayersSelected(sender: AnyObject) {
        self.players = 3
        performSegueWithIdentifier("startGame", sender: self)
    }
    
    @IBAction func fourPlayersSelected(sender: AnyObject) {
        self.players = 4
        performSegueWithIdentifier("startGame", sender: self)
    }

    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "startGame") {
            Game.init()
            Game.sharedInstance.setPlayers(self.players)
        }
    }
    
}