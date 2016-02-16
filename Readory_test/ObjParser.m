//
//  ObjParser.m
//  Readory_test
//
//  Created by Leonardo Lanzinger on 16/02/16.
//  Copyright © 2016 Leonardo Lanzinger. All rights reserved.
//


/*
 [[VuforiaObject3D alloc] init];
 
 obj3D.numVertices = numVertices;
 obj3D.vertices = vertices;
 obj3D.normals = normals;
 obj3D.texCoords = texCoords;
 
 obj3D.numIndices = numIndices;
 obj3D.indices = indices;
 
 obj3D.texture = augmentationTexture[textureIndex];
*/

#import "ObjParser.h"

@implementation ObjParser

- (VuforiaObject3D*)loadObject: (NSString*) url {
    
    // initialize vuforia object
    VuforiaObject3D* object = [[VuforiaObject3D alloc] init];
    
    // read from file
    self.fileRoot = [[NSBundle mainBundle]
                pathForResource:url ofType:@"obj"];
    NSError* error = nil;
    NSString *objData = [NSString stringWithContentsOfFile:self.fileRoot
                                                        encoding:NSUTF8StringEncoding
                                                        error:&error];
    
    if(error) { // If error object was instantiated, handle it.
        NSLog(@"ERROR while loading from file: %@", error);
    }
    
    NSUInteger vertexCount = 0, faceCount = 0, vtCount = 0, vnCount = 0;
    // Iterate through file once to discover how many vertices, normals, and faces there are
    NSArray *lines = [objData componentsSeparatedByString:@"\n"];
    for (NSString * line in lines)
    {
        if ([line hasPrefix:@"v "])
            vertexCount++;
        else if ([line hasPrefix:@"vt "])
            vtCount++;
        else if ([line hasPrefix:@"vn "])
            vnCount ++;
        else if ([line hasPrefix:@"f "])
            faceCount++;
    }
    
    // set everything to vuforia object
    object.numVertices = vertexCount;
    object.numIndices = faceCount;
    
    float* vert = malloc(sizeof(float) * object.numVertices * 3);
    float* norm = malloc(sizeof(float) * vnCount * 3);
    float* text = malloc(sizeof(float) * vtCount * 3);
    short* indices = malloc(sizeof(short) * faceCount * 3);
    vertexCount = 0;
    int normCount = 0;
    int textCount = 0;
    faceCount = 0;
    
    for (NSString * line in lines)
    {
        // set vertices
        if ([line hasPrefix:@"v "]) {
            NSString *lineTrunc = [line substringFromIndex:2];
            NSArray *lineVertices = [lineTrunc componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            vert[vertexCount] = [[lineVertices objectAtIndex:0] floatValue];
            vertexCount++;
            vert[vertexCount] = [[lineVertices objectAtIndex:1] floatValue];
            vertexCount++;
            vert[vertexCount] = [[lineVertices objectAtIndex:2] floatValue];
            vertexCount++;
        }
        // set normals
        else if ([line hasPrefix:@"vn "]) {
            NSString *lineTrunc = [line substringFromIndex:2];
            NSArray *lineVertices = [lineTrunc componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            norm[normCount] = [[lineVertices objectAtIndex:0] floatValue];
            normCount++;
            norm[normCount] = [[lineVertices objectAtIndex:1] floatValue];
            normCount++;
            norm[normCount] = [[lineVertices objectAtIndex:2] floatValue];
            normCount++;
        }
        // set text coords
        else if ([line hasPrefix:@"vt "]) {
            NSString *lineTrunc = [line substringFromIndex:2];
            NSArray *lineVertices = [lineTrunc componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            text[textCount] = [[lineVertices objectAtIndex:0] floatValue];
            textCount++;
            text[textCount] = [[lineVertices objectAtIndex:1] floatValue];
            textCount++;
            text[textCount] = [[lineVertices objectAtIndex:2] floatValue];
            textCount++;
        }
        // set faces
        else if ([line hasPrefix:@"f "]) {
            NSString *lineTrunc = [line substringFromIndex:2];
            NSArray *faceIndexGroups = [lineTrunc componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

            NSString *oneGroup = [faceIndexGroups objectAtIndex:0];
            NSArray *groupPartsOne = [oneGroup componentsSeparatedByString:@"/"];
            indices[faceCount] = [[groupPartsOne  objectAtIndex:0] integerValue];
            //faces[faceCount][0] = [[groupPartsOne  objectAtIndex:0] integerValue];
            //faces[faceCount][1] = [[groupPartsOne  objectAtIndex:1] integerValue];
            //faces[faceCount][2] = [[groupPartsOne  objectAtIndex:2] integerValue];
            faceCount++;
            
            NSString *twoGroup = [faceIndexGroups objectAtIndex:1];
            NSArray *groupPartsTwo = [twoGroup componentsSeparatedByString:@"/"];
            indices[faceCount] = [[groupPartsTwo  objectAtIndex:0] integerValue];
            //faces[faceCount][3] = [[groupPartsTwo  objectAtIndex:0] integerValue];
            //faces[faceCount][4] = [[groupPartsTwo  objectAtIndex:1] integerValue];
            //faces[faceCount][5] = [[groupPartsTwo  objectAtIndex:2] integerValue];
            faceCount++;
            
            NSString *threeGroup = [faceIndexGroups objectAtIndex:2];
            NSArray *groupPartsThree = [threeGroup componentsSeparatedByString:@"/"];
            indices[faceCount] = [[groupPartsThree  objectAtIndex:0] integerValue];
            //faces[faceCount][6] = [[groupPartsThree  objectAtIndex:0] integerValue];
            //faces[faceCount][7] = [[groupPartsThree  objectAtIndex:1] integerValue];
            //faces[faceCount][8] = [[groupPartsThree  objectAtIndex:2] integerValue];
            faceCount++;
        }
    }
    
    // check if texture coords is empty populate it with 0
    if (textCount == 0) {
        for (int i = 0; i < textCount; i++) {
            text[i] = 0;
        }
    }
    
    // store into object
    object.vertices = vert;
    object.normals = norm;
    object.texCoords = text;
    object.indices = indices;
    
    return object;
}

@end
