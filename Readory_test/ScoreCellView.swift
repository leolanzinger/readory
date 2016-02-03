//
//  ScoreCellView.swift
//  Readory_test
//
//  Created by Leonardo Lanzinger on 03/02/16.
//  Copyright © 2016 Leonardo Lanzinger. All rights reserved.
//

import UIKit

class ScoreCellView: UITableViewCell {

    @IBOutlet weak var playerImage: UIImageView!
    @IBOutlet weak var playerScore: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
