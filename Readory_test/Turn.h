//
//  Turn.h
//  Readory_test
//
//  Created by Leonardo Lanzinger on 27/01/16.
//  Copyright © 2016 Leonardo Lanzinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Readory_test-Swift.h"

@interface TurnWrapper: NSObject

@property Turn *turn;

-(id) init;
-(int) checkCard:(int)marker_id;
-(bool) checkTwoCards;
-(bool) checkHint:(int)marker_id;
-(bool) findCorrectHint:(int)marker_id;

@end