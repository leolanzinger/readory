#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <sys/time.h>

#import <QCAR/QCAR.h>
#import <QCAR/State.h>
#import <QCAR/Tool.h>
#import <QCAR/Renderer.h>
#import <QCAR/TrackableResult.h>
#import <QCAR/VideoBackgroundConfig.h>
#import <QCAR/MarkerResult.h>

#import "VuforiaObject3D.h"

#import "A_object.h"
#import "C_object.h"
#import "Q_object.h"
#import "R_object.h"
#import "Teapot.h"
#import "star.h"

#import "FrameMarkersEAGLView.h"
#import "Texture.h"
#import "SampleApplicationUtils.h"
#import "SampleApplicationShaderUtils.h"

#import "FrameMarkersViewController.h"

#import "Turn.h"
#import "ObjParser.h"

//******************************************************************************
// *** OpenGL ES thread safety ***
//
// OpenGL ES on iOS is not thread safe.  We ensure thread safety by following
// this procedure:
// 1) Create the OpenGL ES context on the main thread.
// 2) Start the QCAR camera, which causes QCAR to locate our EAGLView and start
//    the render thread.
// 3) QCAR calls our renderFrameQCAR method periodically on the render thread.
//    The first time this happens, the defaultFramebuffer does not exist, so it
//    is created with a call to createFramebuffer.  createFramebuffer is called
//    on the main thread in order to safely allocate the OpenGL ES storage,
//    which is shared with the drawable layer.  The render (background) thread
//    is blocked during the call to createFramebuffer, thus ensuring no
//    concurrent use of the OpenGL ES context.
//
//******************************************************************************


namespace {
    // --- Data private to this unit ---
    // Letter object scale factor and translation
    const float kLetterScale = 25.0f;
    const float kLetterTranslate = 25.0f;
    
    // Texture filenames
    const char* textureFilenames[] = {
        "letter_Q.png",
        "blue_texture.png"/*,
        "letter_A.png",
        "letter_R.png",
        "TextureTeapotRed.png"*/
    };
    
    FrameMarkersViewController* vc;
    // initialize a first card id variable to -1
    int firstCard;

}


@interface FrameMarkersEAGLView (PrivateMethods)

- (void)initShaders;
- (void)createFramebuffer;
- (void)deleteFramebuffer;
- (void)setFramebuffer;
- (BOOL)presentFramebuffer;

@end


@implementation FrameMarkersEAGLView

@synthesize vapp;

// You must implement this method, which ensures the view's underlying layer is
// of type CAEAGLLayer
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}


//------------------------------------------------------------------------------
#pragma mark - Lifecycle

- (id)initWithFrame:(CGRect)frame appSession:(SampleApplicationSession *) app
{
    self = [super initWithFrame:frame];
    
    if (self) {
        vapp = app;
        // Enable retina mode if available on this device
        if (YES == [vapp isRetinaDisplay]) {
            [self setContentScaleFactor:2.0f];
        }
        
        objects3D = [[NSMutableArray alloc] initWithCapacity:4];
        
        // Load the augmentation textures
        for (int i = 0; i < kNumAugmentationTextures; ++i) {
            augmentationTexture[i] = [[Texture alloc] initWithImageFile:[NSString stringWithCString:textureFilenames[i] encoding:NSASCIIStringEncoding]];
        }
        
        // Create the OpenGL ES context
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        // The EAGLContext must be set for each thread that wishes to use it.
        // Set it the first time this method is called (on the main thread)
        if (context != [EAGLContext currentContext]) {
            [EAGLContext setCurrentContext:context];
        }
        
        // Generate the OpenGL ES texture and upload the texture data for use
        // when rendering the augmentation
        for (int i = 0; i < kNumAugmentationTextures; ++i) {
            GLuint textureID;
            glGenTextures(1, &textureID);
            [augmentationTexture[i] setTextureID:textureID];
            glBindTexture(GL_TEXTURE_2D, textureID);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, [augmentationTexture[i] width], [augmentationTexture[i] height], 0, GL_RGBA, GL_UNSIGNED_BYTE, (GLvoid*)[augmentationTexture[i] pngData]);
        }
        [self setup3dObjects];
        
        offTargetTrackingEnabled = NO;
        
        [self initShaders];
        
        // set the first card to -1
        firstCard = -1;

    }
    
    return self;
}


- (void)dealloc
{
    [self deleteFramebuffer];
    
    // Tear down context
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    for (int i = 0; i < kNumAugmentationTextures; ++i) {
        augmentationTexture[i] = nil;
    }
}


- (void)finishOpenGLESCommands
{
    // Called in response to applicationWillResignActive.  The render loop has
    // been stopped, so we now make sure all OpenGL ES commands complete before
    // we (potentially) go into the background
    if (context) {
        [EAGLContext setCurrentContext:context];
        glFinish();
    }
}


- (void)freeOpenGLESResources
{
    // Called in response to applicationDidEnterBackground.  Free easily
    // recreated OpenGL ES resources
    [self deleteFramebuffer];
    glFinish();
}


- (void) add3DObjectWith:(int)numVertices ofVertices:(const float *)vertices normals:(const float *)normals texcoords:(const float *)texCoords with:(int)numIndices ofIndices:(const unsigned short *)indices usingTextureIndex:(NSInteger)textureIndex
{
    VuforiaObject3D *obj3D = [[VuforiaObject3D alloc] init];
    
    obj3D.numVertices = numVertices;
    obj3D.vertices = vertices;
    obj3D.normals = normals;
    obj3D.texCoords = texCoords;
    
    obj3D.numIndices = numIndices;
    obj3D.indices = indices;
    
    obj3D.texture = augmentationTexture[textureIndex];
    
    [objects3D addObject:obj3D];
}

- (void) setup3dObjects
{
    // build the array of objects we want drawn and their texture
    // in this example we have 4 textures and 4 objects - Q, C, A, R
    
    [self add3DObjectWith:NUM_Q_OBJECT_VERTEX ofVertices:QobjectVertices normals:QobjectNormals texcoords:QobjectTexCoords
                     with:NUM_Q_OBJECT_INDEX ofIndices:QobjectIndices usingTextureIndex:0];
    
    [self add3DObjectWith:NUM_C_OBJECT_VERTEX ofVertices:CobjectVertices normals:CobjectNormals texcoords:CobjectTexCoords
                     with:NUM_C_OBJECT_INDEX ofIndices:CobjectIndices usingTextureIndex:1]; /*
    
    [self add3DObjectWith:NUM_A_OBJECT_VERTEX ofVertices:AobjectVertices normals:AobjectNormals texcoords:AobjectTexCoords
                     with:NUM_A_OBJECT_INDEX ofIndices:AobjectIndices usingTextureIndex:2];
    
    [self add3DObjectWith:NUM_R_OBJECT_VERTEX ofVertices:RobjectVertices normals:RobjectNormals texcoords:RobjectTexCoords
                     with:NUM_R_OBJECT_INDEX ofIndices:RobjectIndices usingTextureIndex:3];
    
    [self add3DObjectWith:NUM_TEAPOT_OBJECT_VERTEX ofVertices:teapotVertices normals:teapotNormals texcoords:teapotTexCoords
                     with:NUM_TEAPOT_OBJECT_INDEX ofIndices:teapotIndices usingTextureIndex:4];
     */
    
    
    // import the game shared instance
    self.game = [[GameWrapper alloc] init];
    
    // load the object parser
    self.objParser = [[ObjParser alloc] init];
    
    
    // init the turn object
    self.turnWrapper = [[TurnWrapper alloc] init];
    
    // load programmatically obj files
    //NSString *url = [self.game getFirstMod];
    //VuforiaObject3D *parsedObj = [self.objParser loadObject:url];
    
}

- (void) setOffTargetTrackingMode:(BOOL) enabled {
    offTargetTrackingEnabled = enabled;
}


//------------------------------------------------------------------------------
#pragma mark - UIGLViewProtocol methods

// Draw the current frame using OpenGL
//
// This method is called by QCAR when it wishes to render the current frame to
// the screen.
//
// *** QCAR will call this method periodically on a background thread ***
- (void)renderFrameQCAR
{
    [self setFramebuffer];
    bool isFrontCamera = false;
    
    // Clear colour and depth buffers
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Retrieve tracking state and render video background and
    QCAR::State state = QCAR::Renderer::getInstance().begin();
    QCAR::Renderer::getInstance().drawVideoBackground();
    
    glEnable(GL_DEPTH_TEST);
    // We must detect if background reflection is active and adjust the culling direction.
    // If the reflection is active, this means the pose matrix has been reflected as well,
    // therefore standard counter clockwise face culling will result in "inside out" models.
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    if(QCAR::Renderer::getInstance().getVideoBackgroundConfig().mReflection == QCAR::VIDEO_BACKGROUND_REFLECTION_ON) {
        glFrontFace(GL_CW);  //Front camera
        isFrontCamera = true;
    } else {
        glFrontFace(GL_CCW);   //Back camera
    }
    
    // Did we find any trackables this frame?
    for(int i = 0; i < state.getNumTrackableResults(); ++i) {
        // Get the trackable
        const QCAR::TrackableResult* trackableResult = state.getTrackableResult(i);
        QCAR::Matrix44F modelViewMatrix = QCAR::Tool::convertPose2GLMatrix(trackableResult->getPose());
        // Check the type of the trackable:
        if (!trackableResult->isOfType(QCAR::MarkerResult::getClassType())) {
            continue;
        }
        const QCAR::MarkerResult* markerResult = static_cast<
        const QCAR::MarkerResult*>(trackableResult);
        const QCAR::Marker& marker = markerResult->getTrackable();
        
        NSLog(@"[%s] tracked", marker.getName());
        if (trackableResult->getStatus() == QCAR::TrackableResult::EXTENDED_TRACKED) {
            NSLog(@"[%s] tracked with target out of view!", marker.getName());
        }
        
        // check the card marker
        if (marker.getMarkerId() < [self.game getLowestBackMark]) {
            int card_res = [self.turnWrapper checkCard:marker.getMarkerId()];
            // if both cards hav been recognized
            if (card_res == 2) {
                bool turn_res = [self.turnWrapper checkTwoCards];
                // if cards are correct
                if (turn_res) {
                    // go to turn win
                    [self correctTurn];
                }
                else {
                    // go to turn fail
                    [self wrongTurn];
                }
            }
            // the first card has been recognized: add it as the first card variable
            // and init the hints
            else if (card_res == 1) {
                firstCard = marker.getMarkerId();
            
                UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Card recognized"
                                                                           message:@"A card has been recognized, flip another one"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {}];
            
                [alert addAction:defaultAction];
                [self.vc presentViewController:alert animated:YES completion:nil];
            }
            // no cards have been recognized, do nothing
            else {
            }
        }
        
        // Choose the object and texture based on the marker ID
        //int textureIndex = marker.getMarkerId();
        //NSLog(@"[%d] marker-id tracked", marker.getMarkerId());
        
        // create the 3d object of the hint
        int lowest_marker = [self.game getLowestBackMark];
        if (marker.getMarkerId() != firstCard && firstCard != -1 && marker.getMarkerId() >= lowest_marker) {
            // check if the markerId should be displayed
            if ([self.turnWrapper checkHint:marker.getMarkerId()]) {
                // display the hint
                VuforiaObject3D *obj3D = [[VuforiaObject3D alloc] init];
                // if the hint is the right card let's display 'C'
                /*if ([turnWrapper findCorrectHint:marker.getMarkerId()]) {
                   //obj3D  = [objects3D objectAtIndex:1];
                    
                    NSLog(@"tracked correct hint marker");
                    
                    //blender object
                    BlenderExportedObject object = text_001Object;
                    
                    obj3D.numVertices = object.numVertices;
                    obj3D.vertices = object.vertices;
                    obj3D.normals = object.normals;
                    obj3D.texCoords = object.texCoords;
                    obj3D.numIndices = object.numIndices;
                    obj3D.indices = object.indices;
                    obj3D.texture = augmentationTexture[1];
                }
                // else display 'Q'
                else {*/
                    obj3D = [objects3D objectAtIndex:0];
                //}
                
                // Render with OpenGL 2
                QCAR::Matrix44F modelViewProjection;
                if (isFrontCamera) {
                    SampleApplicationUtils::scalePoseMatrix(-1, 1, 1, &modelViewMatrix.data[0]);
                }
                SampleApplicationUtils::translatePoseMatrix(-kLetterTranslate, -kLetterTranslate, 0.f, &modelViewMatrix.data[0]);
                SampleApplicationUtils::scalePoseMatrix(kLetterScale, kLetterScale, kLetterScale, &modelViewMatrix.data[0]);
                SampleApplicationUtils::multiplyMatrix(&vapp.projectionMatrix.data[0], &modelViewMatrix.data[0], &modelViewProjection.data[0]);
                
                glUseProgram(shaderProgramID);
                
                glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, obj3D.vertices);
                glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0, obj3D.normals);
                glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, obj3D.texCoords);
                
                glEnableVertexAttribArray(vertexHandle);
                glEnableVertexAttribArray(normalHandle);
                glEnableVertexAttribArray(textureCoordHandle);
                
                glActiveTexture(GL_TEXTURE0);
                glBindTexture(GL_TEXTURE_2D, [obj3D.texture textureID]);
                glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE, (const GLfloat*)&modelViewProjection.data[0]);
                glUniform1i(texSampler2DHandle, 0); //GL_TEXTURE0);
                glDrawElements(GL_TRIANGLES, obj3D.numIndices, GL_UNSIGNED_SHORT, obj3D.indices);
                
                glDisableVertexAttribArray(vertexHandle);
                glDisableVertexAttribArray(normalHandle);
                glDisableVertexAttribArray(textureCoordHandle);
            }
         
        }
        
        
        SampleApplicationUtils::checkGlError("FrameMarkerss renderFrameQCAR");
    }
    
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    
    QCAR::Renderer::getInstance().end();
    [self presentFramebuffer];
    
}

//------------------------------------------------------------------------------
#pragma mark - OpenGL ES management

- (void)initShaders
{
    shaderProgramID = [SampleApplicationShaderUtils createProgramWithVertexShaderFileName:@"Simple.vertsh"
                                                                   fragmentShaderFileName:@"Simple.fragsh"];
    
    if (0 < shaderProgramID) {
        vertexHandle = glGetAttribLocation(shaderProgramID, "vertexPosition");
        normalHandle = glGetAttribLocation(shaderProgramID, "vertexNormal");
        textureCoordHandle = glGetAttribLocation(shaderProgramID, "vertexTexCoord");
        mvpMatrixHandle = glGetUniformLocation(shaderProgramID, "modelViewProjectionMatrix");
        texSampler2DHandle  = glGetUniformLocation(shaderProgramID,"texSampler2D");
    }
    else {
        NSLog(@"Could not initialise augmentation shader");
    }
}


- (void)createFramebuffer
{
    if (context) {
        // Create default framebuffer object
        glGenFramebuffers(1, &defaultFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
        
        // Create colour renderbuffer and allocate backing store
        glGenRenderbuffers(1, &colorRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
        
        // Allocate the renderbuffer's storage (shared with the drawable object)
        [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
        GLint framebufferWidth;
        GLint framebufferHeight;
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &framebufferWidth);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &framebufferHeight);
        
        // Create the depth render buffer and allocate storage
        glGenRenderbuffers(1, &depthRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, framebufferWidth, framebufferHeight);
        
        // Attach colour and depth render buffers to the frame buffer
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
        
        // Leave the colour render buffer bound so future rendering operations will act on it
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    }
}


- (void)deleteFramebuffer
{
    if (context) {
        [EAGLContext setCurrentContext:context];
        
        if (defaultFramebuffer) {
            glDeleteFramebuffers(1, &defaultFramebuffer);
            defaultFramebuffer = 0;
        }
        
        if (colorRenderbuffer) {
            glDeleteRenderbuffers(1, &colorRenderbuffer);
            colorRenderbuffer = 0;
        }
        
        if (depthRenderbuffer) {
            glDeleteRenderbuffers(1, &depthRenderbuffer);
            depthRenderbuffer = 0;
        }
    }
}


- (void)setFramebuffer
{
    // The EAGLContext must be set for each thread that wishes to use it.  Set
    // it the first time this method is called (on the render thread)
    if (context != [EAGLContext currentContext]) {
        [EAGLContext setCurrentContext:context];
    }
    
    if (!defaultFramebuffer) {
        // Perform on the main thread to ensure safe memory allocation for the
        // shared buffer.  Block until the operation is complete to prevent
        // simultaneous access to the OpenGL context
        [self performSelectorOnMainThread:@selector(createFramebuffer) withObject:self waitUntilDone:YES];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
}


- (BOOL)presentFramebuffer
{
    // setFramebuffer must have been called before presentFramebuffer, therefore
    // we know the context is valid and has been set for this (render) thread
    
    // Bind the colour render buffer and present it
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    
    return [context presentRenderbuffer:GL_RENDERBUFFER];
}

-(void)setVC:(UIViewController*)vc_object {
    self.vc = vc_object;
}

-(void)correctTurn {
    FrameMarkersViewController* fvc = self.vc;
    [fvc handleSuccessPick];
}

-(void)wrongTurn {
    FrameMarkersViewController* fvc = self.vc;
    [fvc handleFailPick];
}



@end