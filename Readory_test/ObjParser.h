//
//  ObjParser.h
//  Readory_test
//
//  Created by Leonardo Lanzinger on 16/02/16.
//  Copyright © 2016 Leonardo Lanzinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VuforiaObject3D.h"

@interface ObjParser : NSObject

@property NSString* fileRoot;
@property VuforiaObject3D* object;

-(id) init;
-(VuforiaObject3D*) loadObject: (NSString*) url;

@end
