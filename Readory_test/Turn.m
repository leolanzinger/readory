//
//  Turn.m
//  Readory_test
//
//  Created by Leonardo Lanzinger on 27/01/16.
//  Copyright © 2016 Leonardo Lanzinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Readory_test-Swift.h"
#import "Turn.h"


@implementation TurnWrapper

- (id)init {
    self = [super init];
    self.turn = [[Turn alloc] init];
    return self;
}

- (int)checkCard:(int)marker_id {
    int result = [self.turn checkCard:marker_id];
    if (result == 0) {
        return 0;
    }
    else if (result == 1){
        return 1;
    }
    else if (result == 2) {
        return 2;
    }
    else {
        return 0;
    }
}

- (bool)checkTwoCards {
    bool result = [self.turn checkTwoCards];
    if (result) {
        return true;
    }
    else {
        return false;
    }
}

-(bool)checkHint:(int)marker_id {
    return [self.turn checkHint:marker_id];
}



@end