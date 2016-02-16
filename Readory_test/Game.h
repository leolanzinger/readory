//
//  Game.h
//  Readory_test
//
//  Created by Leonardo Lanzinger on 15/02/16.
//  Copyright © 2016 Leonardo Lanzinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Readory_test-Swift.h"

@interface GameWrapper : NSObject

@property Game *game;

-(id) init;
-(NSArray*) getAllMarks;
-(NSString*) getTurnType;
-(int) getLowestBackMark;
-(NSString*) getFirstMod;

@end
