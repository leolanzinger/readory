//
//  Game.m
//  Readory_test
//
//  Created by Leonardo Lanzinger on 15/02/16.
//  Copyright © 2016 Leonardo Lanzinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Readory_test-Swift.h"
#import "Game.h"

@implementation GameWrapper

- (id)init {
    self = [super init];
    self.game = [Game sharedInstance];
    return self;
}

- (NSArray*)getAllMarks {
    return [self.game getAllMarkers];
}

- (NSString*)getTurnType {
    return [self.game getCurrentTurnType];
}

- (int)getLowestBackMark {
    return [self.game getLowestBackMarker];
}

- (NSString*)getFirstMod {
    return [self.game getFirstMarkerModel];
}

@end
