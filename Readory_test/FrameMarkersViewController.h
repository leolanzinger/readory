//
//  FrameMarkerViewController.h
//  Readory_test
//
//  Created by Leonardo Lanzinger on 19/01/16.
//  Copyright © 2016 Leonardo Lanzinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FrameMarkersEAGLView.h"
#import "SampleApplicationSession.h"
#import <QCAR/DataSet.h>

@interface FrameMarkersViewController : UIViewController <SampleApplicationControl> {
    
    // menu options
    BOOL continuousAutofocusEnabled;
    BOOL flashEnabled;
    BOOL frontCameraEnabled;
}

@property (nonatomic, strong) FrameMarkersEAGLView* eaglView;
@property (nonatomic, strong) SampleApplicationSession * vapp;
@property (nonatomic, strong) UITapGestureRecognizer * tapGestureRecognizer;

-(void)handleSuccessPick;
-(void)handleFailPick;

@end
