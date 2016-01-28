//
//  TurnFailViewController.swift
//  Readory_test
//
//  Created by Leonardo Lanzinger on 26/01/16.
//  Copyright © 2016 Leonardo Lanzinger. All rights reserved.
//

import UIKit

class TurnFailViewController: UIViewController {
    
    @IBOutlet weak var turnLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // update the score
        Game.sharedInstance.turnLost();
        
        // append the player that is about to play the turn
        turnLabel.text = turnLabel.text! + " " + String(Game.sharedInstance.playingPlayer) + " turn!" 
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
}