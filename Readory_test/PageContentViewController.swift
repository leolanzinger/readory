//
//  PageContentViewController.swift
//  UIPageViewController
//
//  Created by Shrikar Archak on 1/15/15.
//  Copyright (c) 2015 Shrikar Archak. All rights reserved.
//

import UIKit

class PageContentViewController: UIViewController {
    
    @IBOutlet weak var onBoardingImage: UIImageView!
    @IBOutlet weak var onBoardingNumber: UILabel!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var onBoardingStack: UIStackView!
    @IBOutlet weak var onBoardingLabel: UILabel!
    
    var pageIndex: Int!
    var titleText : String!
    var imageName : String!
    var ok_button : UIButton!
    var max: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ok_button = self.okButton
        self.onBoardingImage.image = UIImage(named: imageName)
        self.onBoardingNumber.text = String(pageIndex)
        self.onBoardingLabel.text = self.titleText
        self.onBoardingLabel.alpha = 0.1
        UIView.animateWithDuration(1.0, animations: { () -> Void in
            self.onBoardingLabel.alpha = 1.0
        })
        if (pageIndex < max) {
            okButton.hidden = true
        }
        else {
            onBoardingStack.hidden = true
        }
        
    }
}