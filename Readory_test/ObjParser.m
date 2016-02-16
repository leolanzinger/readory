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

- (id)init {
    self = [super init];
    return self;
}

- (VuforiaObject3D*)loadObject: (NSString*) url {
    
    // initialize vuforia object
    self.object = [[VuforiaObject3D alloc] init];
    
    // read from file
    self.fileRoot = [[NSBundle mainBundle]
                pathForResource:url ofType:@"obj"];
    NSString* fileContents =
    [NSString stringWithContentsOfFile:self.fileRoot
                              encoding:NSUTF8StringEncoding error:nil];
    
    // first, separate by new line
    NSArray* allLinedStrings =
    [fileContents componentsSeparatedByCharactersInSet:
     [NSCharacterSet newlineCharacterSet]];
    
    
    NSString *objData = [NSString stringWithContentsOfFile:self.fileRoot];
    NSUInteger vertexCount = 0, faceCount = 0;
    // Iterate through file once to discover how many vertices, normals, and faces there are
    NSArray *lines = [objData componentsSeparatedByString:@"\n"];
    for (NSString * line in lines)
    {
        if ([line hasPrefix:@"v "])
            vertexCount++;
        else if ([line hasPrefix:@"f "])
            faceCount++;
    }
    
    // set everything to vuforia object
    self.object.numVertices = vertexCount;
    
    float* vert = malloc(self.object.numVertices * 3);
    float* norm = malloc(self.object.numVertices * 3);
    float* text = malloc(self.object.numVertices * 2);
    vertexCount = 0;
    int normCount = 0;
    int textCount = 0;
    int faces[faceCount][9];
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
        // set faceselse
        if ([line hasPrefix:@"f "]) {
            NSString *lineTrunc = [line substringFromIndex:2];
            NSArray *faceIndexGroups = [lineTrunc componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            /*
            // Unrolled loop, a little ugly but functional
             
            From the WaveFront OBJ specification:
            o       The first reference number is the geometric vertex.
            o       The second reference number is the texture vertex. It follows the first slash.
            o       The third reference number is the vertex normal. It follows the second slash.
            */
            NSString *oneGroup = [faceIndexGroups objectAtIndex:0];
            NSArray *groupPartsOne = [oneGroup componentsSeparatedByString:@"/"];
            faces[faceCount][0] = [[groupPartsOne  objectAtIndex:0] integerValue];
            faces[faceCount][1] = [[groupPartsOne  objectAtIndex:1] integerValue];
            faces[faceCount][2] = [[groupPartsOne  objectAtIndex:2] integerValue];
            
            NSString *twoGroup = [faceIndexGroups objectAtIndex:1];
            NSArray *groupPartsTwo = [twoGroup componentsSeparatedByString:@"/"];
            faces[faceCount][3] = [[groupPartsTwo  objectAtIndex:0] integerValue];
            faces[faceCount][4] = [[groupPartsTwo  objectAtIndex:1] integerValue];
            faces[faceCount][5] = [[groupPartsTwo  objectAtIndex:2] integerValue];
            
            NSString *threeGroup = [faceIndexGroups objectAtIndex:2];
            NSArray *groupPartsThree = [threeGroup componentsSeparatedByString:@"/"];
            faces[faceCount][6] = [[groupPartsThree  objectAtIndex:0] integerValue];
            faces[faceCount][7] = [[groupPartsThree  objectAtIndex:1] integerValue];
            faces[faceCount][8] = [[groupPartsThree  objectAtIndex:2] integerValue];
            
            faceCount++;
        }
    }
    
    // check if texture coords is empty populate it with 0
    if (textCount == 0) {
        for (int i = 0; i < self.object.numVertices*2; i++) {
            text[i] = 0;
        }
    }
    
    // store into object
    self.object.vertices = vert;
    self.object.normals = norm;
    self.object.texCoords = text;
    
    
    
    return self.object;
}

@end
