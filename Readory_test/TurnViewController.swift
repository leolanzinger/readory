//
//  TurnViewController.swift
//  Readory_test
//
//  Created by Leonardo Lanzinger on 15/01/16.
//  Copyright © 2016 Leonardo Lanzinger. All rights reserved.
//

import UIKit

class TurnViewController: UIViewController {

    @IBOutlet weak var playerName: UILabel!
    @IBOutlet weak var playerImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // append the player that is about to play the turn
        playerName.text = String(Game.sharedInstance.playerNames[Game.sharedInstance.playingPlayer - 1])
        playerImage.image = UIImage(named:Game.sharedInstance.imageNames[Game.sharedInstance.playingPlayer - 1])!
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
