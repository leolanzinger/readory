//
//  TurnSuccessViewController.swift
//  Readory_test
//
//  Created by Leonardo Lanzinger on 26/01/16.
//  Copyright © 2016 Leonardo Lanzinger. All rights reserved.
//

import UIKit

class TurnSuccessViewController: UIViewController {
    
    @IBOutlet weak var turnLabel: UILabel!
    @IBOutlet weak var playAgainButton: UIButton!
    
    var finish:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // update the score
        finish = Game.sharedInstance.turnWon()
        if (finish) {
            turnLabel.text = "Correct answer!"
            playAgainButton.hidden = true
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(false)
        if (finish) {
            // wait two seconds
            let delay = 2 * Double(NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            dispatch_after(time, dispatch_get_main_queue()) {
                // go to finish game screen
                self.performSegueWithIdentifier("gameFinished", sender: self)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func playAgain(sender: AnyObject) {
        // go to play game screen
        performSegueWithIdentifier("playAgainSegue", sender: self)
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
