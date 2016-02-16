/*===============================================================================
 Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.
 
 Vuforia is a trademark of PTC Inc., registered in the United States and other
 countries.
 ===============================================================================*/

#import <UIKit/UIKit.h>

#import <QCAR/UIGLViewProtocol.h>
#import "Texture.h"
#import "SampleGLResourceHandler.h"
#import "SampleApplicationSession.h"
#import "Turn.h"
#import "Game.h"
#import "ObjParser.h"

//#import "FrameMarkersViewController.h"

// TODO: should be dynamic, not hardcoded
static const int kNumAugmentationTextures = 2;


// FrameMarkers is a subclass of UIView and conforms to the informal protocol
// UIGLViewProtocol
@interface FrameMarkersEAGLView : UIView <UIGLViewProtocol, SampleGLResourceHandler> {
@private
    // OpenGL ES context
    EAGLContext *context;
    
    // The OpenGL ES names for the framebuffer and renderbuffers used to render
    // to this view
    GLuint defaultFramebuffer;
    GLuint colorRenderbuffer;
    GLuint depthRenderbuffer;
    
    // Shader handles
    GLuint shaderProgramID;
    GLint vertexHandle;
    GLint normalHandle;
    GLint textureCoordHandle;
    GLint mvpMatrixHandle;
    GLint texSampler2DHandle;
    
    
    
    // Texture used when rendering augmentation
    Texture* augmentationTexture[kNumAugmentationTextures];
    NSMutableArray *objects3D;  // objects to draw
    
    BOOL offTargetTrackingEnabled;
}

@property (nonatomic, weak) SampleApplicationSession * vapp;
@property (nonatomic, weak) UIViewController* vc;
// turn object
@property (nonatomic, strong) TurnWrapper *turnWrapper;

// game wrapper
@property (nonatomic, strong) GameWrapper *game;

- (id)initWithFrame:(CGRect)frame appSession:(SampleApplicationSession *) app;

- (void)setVC:(UIViewController*)vc_object;

- (void)finishOpenGLESCommands;
- (void)freeOpenGLESResources;
- (void)correctTurn;
- (void)wrongTurn;

@end

