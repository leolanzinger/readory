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

#import "FrameMarkersEAGLView.h"
#import "Texture.h"
#import "SampleApplicationUtils.h"
#import "SampleApplicationShaderUtils.h"

#import "FrameMarkersViewController.h"

#import "Turn.h"
#import "ObjParser.h"

#import "hint_0.h"
#import "hint_1.h"
#import "hint_2.h"
#import "hint_3.h"
#import "hint_4.h"
#import "hint_5.h"
#import "hint_6.h"
#import "hint_7.h"
#import "hint_8.h"
#import "hint_9.h"

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
        
        objects3D_misspelling = [[NSMutableArray alloc] initWithCapacity:20];
        objects3D_translation = [[NSMutableArray alloc] initWithCapacity:20];
        objects3D_association = [[NSMutableArray alloc] initWithCapacity:20];
        objects3D_synonym = [[NSMutableArray alloc] initWithCapacity:20];
        
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
    
    //[objects3D addObject:obj3D];
}

- (void) setup3dObjects
{
    // import the game shared instance
    self.game = [[GameWrapper alloc] init];
    
    // init the turn object
    self.turnWrapper = [[TurnWrapper alloc] init];
    
    
    // load the object parser
    /*
    ObjParser* objParser = [[ObjParser alloc] init];
    // load programmatically obj files
    NSString *url = [self.game getFirstMod];
    VuforiaObject3D *parsedObj = [[VuforiaObject3D alloc]init];
    parsedObj = [objParser loadObject:url];
    parsedObj.texture = augmentationTexture[1];
    
    [objects3D addObject:parsedObj];*/
    
    // build the array of objects we want drawn and their texture
    // in this example we have 4 textures and 4 objects - Q, C, A, R
    
    /*[self add3DObjectWith:NUM_Q_OBJECT_VERTEX ofVertices:QobjectVertices normals:QobjectNormals texcoords:QobjectTexCoords
                     with:NUM_Q_OBJECT_INDEX ofIndices:QobjectIndices usingTextureIndex:0];
    
    [self add3DObjectWith:NUM_C_OBJECT_VERTEX ofVertices:CobjectVertices normals:CobjectNormals texcoords:CobjectTexCoords
                     with:NUM_C_OBJECT_INDEX ofIndices:CobjectIndices usingTextureIndex:1];*/
    
    [self loadHints];
    
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

                // get the model id based on the marker
                int model_id = [self.game getModelFromMark:marker.getMarkerId()];

                int turn_i = [self.game getCurrentTurnIn];
                
                if (turn_i == 0) {
                    obj3D = [objects3D_misspelling objectAtIndex:model_id];
                }
                else if (turn_i == 1) {
                    obj3D = [objects3D_translation objectAtIndex:model_id];
                }
                else if (turn_i == 2) {
                    obj3D = [objects3D_association objectAtIndex:model_id];
                }
                else if (turn_i == 3) {
                    obj3D = [objects3D_synonym objectAtIndex:model_id];
                }
                
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

-(void)loadHints {
    
    int texture_index = 1;
    
    // load hints for model 0
    
    // add misspelling object
    VuforiaObject3D *obj_0_misspelling = [[VuforiaObject3D alloc]init];
    obj_0_misspelling.numVertices = marker_0_misspelling.numVertices;
    obj_0_misspelling.vertices = marker_0_misspelling.vertices;
    obj_0_misspelling.normals = marker_0_misspelling.normals;
    obj_0_misspelling.texCoords = marker_0_misspelling.texCoords;
    obj_0_misspelling.numIndices = marker_0_misspelling.numIndices;
    obj_0_misspelling.indices = marker_0_misspelling.indices;
    obj_0_misspelling.texture = augmentationTexture[texture_index];
    [objects3D_misspelling addObject:obj_0_misspelling];
    
    // add translation object
    VuforiaObject3D *obj_0_translation = [[VuforiaObject3D alloc]init];
    obj_0_translation.numVertices = marker_0_translation.numVertices;
    obj_0_translation.vertices = marker_0_translation.vertices;
    obj_0_translation.normals = marker_0_translation.normals;
    obj_0_translation.texCoords = marker_0_translation.texCoords;
    obj_0_translation.numIndices = marker_0_translation.numIndices;
    obj_0_translation.indices = marker_0_translation.indices;
    obj_0_translation.texture = augmentationTexture[texture_index];
    [objects3D_translation addObject:obj_0_translation];
    
    // add misspelling object
    VuforiaObject3D *obj_0_association = [[VuforiaObject3D alloc]init];
    obj_0_association.numVertices = marker_0_association.numVertices;
    obj_0_association.vertices = marker_0_association.vertices;
    obj_0_association.normals = marker_0_association.normals;
    obj_0_association.texCoords = marker_0_association.texCoords;
    obj_0_association.numIndices = marker_0_association.numIndices;
    obj_0_association.indices = marker_0_association.indices;
    obj_0_association.texture = augmentationTexture[texture_index];
    [objects3D_association addObject:obj_0_association];
    
    // add misspelling object
    VuforiaObject3D *obj_0_synonym = [[VuforiaObject3D alloc]init];
    obj_0_synonym.numVertices = marker_0_synonym.numVertices;
    obj_0_synonym.vertices = marker_0_synonym.vertices;
    obj_0_synonym.normals = marker_0_synonym.normals;
    obj_0_synonym.texCoords = marker_0_synonym.texCoords;
    obj_0_synonym.numIndices = marker_0_synonym.numIndices;
    obj_0_synonym.indices = marker_0_synonym.indices;
    obj_0_synonym.texture = augmentationTexture[texture_index];
    [objects3D_synonym addObject:obj_0_synonym];
    
    // load hints for model 1
    
    // add misspelling object
    VuforiaObject3D *obj_1_misspelling = [[VuforiaObject3D alloc]init];
    obj_1_misspelling.numVertices = marker_1_misspellingObject.numVertices;
    obj_1_misspelling.vertices = marker_1_misspellingObject.vertices;
    obj_1_misspelling.normals = marker_1_misspellingObject.normals;
    obj_1_misspelling.texCoords = marker_1_misspellingObject.texCoords;
    obj_1_misspelling.numIndices = marker_1_misspellingObject.numIndices;
    obj_1_misspelling.indices = marker_1_misspellingObject.indices;
    obj_1_misspelling.texture = augmentationTexture[texture_index];
    [objects3D_misspelling addObject:obj_1_misspelling];
    
    // add translation object
    VuforiaObject3D *obj_1_translation = [[VuforiaObject3D alloc]init];
    obj_1_translation.numVertices = marker_1_translationObject.numVertices;
    obj_1_translation.vertices = marker_1_translationObject.vertices;
    obj_1_translation.normals = marker_1_translationObject.normals;
    obj_1_translation.texCoords = marker_1_translationObject.texCoords;
    obj_1_translation.numIndices = marker_1_translationObject.numIndices;
    obj_1_translation.indices = marker_1_translationObject.indices;
    obj_1_translation.texture = augmentationTexture[texture_index];
    [objects3D_translation addObject:obj_1_translation];
    
    // add misspelling object
    VuforiaObject3D *obj_1_association = [[VuforiaObject3D alloc]init];
    obj_1_association.numVertices = marker_1_associationObject.numVertices;
    obj_1_association.vertices = marker_1_associationObject.vertices;
    obj_1_association.normals = marker_1_associationObject.normals;
    obj_1_association.texCoords = marker_1_associationObject.texCoords;
    obj_1_association.numIndices = marker_1_associationObject.numIndices;
    obj_1_association.indices = marker_1_associationObject.indices;
    obj_1_association.texture = augmentationTexture[texture_index];
    [objects3D_association addObject:obj_1_association];
    
    // add misspelling object
    VuforiaObject3D *obj_1_synonym = [[VuforiaObject3D alloc]init];
    obj_1_synonym.numVertices = marker_1_synonymObject.numVertices;
    obj_1_synonym.vertices = marker_1_synonymObject.vertices;
    obj_1_synonym.normals = marker_1_synonymObject.normals;
    obj_1_synonym.texCoords = marker_1_synonymObject.texCoords;
    obj_1_synonym.numIndices = marker_1_synonymObject.numIndices;
    obj_1_synonym.indices = marker_1_synonymObject.indices;
    obj_1_synonym.texture = augmentationTexture[texture_index];
    [objects3D_synonym addObject:obj_1_synonym];
    
    // load hints for model 2
    
    // add misspelling object
    VuforiaObject3D *obj_2_misspelling = [[VuforiaObject3D alloc]init];
    obj_2_misspelling.numVertices = marker_2_misspellingObject.numVertices;
    obj_2_misspelling.vertices = marker_2_misspellingObject.vertices;
    obj_2_misspelling.normals = marker_2_misspellingObject.normals;
    obj_2_misspelling.texCoords = marker_2_misspellingObject.texCoords;
    obj_2_misspelling.numIndices = marker_2_misspellingObject.numIndices;
    obj_2_misspelling.indices = marker_2_misspellingObject.indices;
    obj_2_misspelling.texture = augmentationTexture[texture_index];
    [objects3D_misspelling addObject:obj_2_misspelling];
    
    // add translation object
    VuforiaObject3D *obj_2_translation = [[VuforiaObject3D alloc]init];
    obj_2_translation.numVertices = marker_2_translationObject.numVertices;
    obj_2_translation.vertices = marker_2_translationObject.vertices;
    obj_2_translation.normals = marker_2_translationObject.normals;
    obj_2_translation.texCoords = marker_2_translationObject.texCoords;
    obj_2_translation.numIndices = marker_2_translationObject.numIndices;
    obj_2_translation.indices = marker_2_translationObject.indices;
    obj_2_translation.texture = augmentationTexture[texture_index];
    [objects3D_translation addObject:obj_2_translation];
    
    // add misspelling object
    VuforiaObject3D *obj_2_association = [[VuforiaObject3D alloc]init];
    obj_2_association.numVertices = marker_2_associationObject.numVertices;
    obj_2_association.vertices = marker_2_associationObject.vertices;
    obj_2_association.normals = marker_2_associationObject.normals;
    obj_2_association.texCoords = marker_2_associationObject.texCoords;
    obj_2_association.numIndices = marker_2_associationObject.numIndices;
    obj_2_association.indices = marker_2_associationObject.indices;
    obj_2_association.texture = augmentationTexture[texture_index];
    [objects3D_association addObject:obj_2_association];
    
    // add misspelling object
    VuforiaObject3D *obj_2_synonym = [[VuforiaObject3D alloc]init];
    obj_2_synonym.numVertices = marker_2_synonymObject.numVertices;
    obj_2_synonym.vertices = marker_2_synonymObject.vertices;
    obj_2_synonym.normals = marker_2_synonymObject.normals;
    obj_2_synonym.texCoords = marker_2_synonymObject.texCoords;
    obj_2_synonym.numIndices = marker_2_synonymObject.numIndices;
    obj_2_synonym.indices = marker_2_synonymObject.indices;
    obj_2_synonym.texture = augmentationTexture[texture_index];
    [objects3D_synonym addObject:obj_2_synonym];
    
    // load hints for model 3
    
    // add misspelling object
    VuforiaObject3D *obj_3_misspelling = [[VuforiaObject3D alloc]init];
    obj_3_misspelling.numVertices = marker_3_misspellingObject.numVertices;
    obj_3_misspelling.vertices = marker_3_misspellingObject.vertices;
    obj_3_misspelling.normals = marker_3_misspellingObject.normals;
    obj_3_misspelling.texCoords = marker_3_misspellingObject.texCoords;
    obj_3_misspelling.numIndices = marker_3_misspellingObject.numIndices;
    obj_3_misspelling.indices = marker_3_misspellingObject.indices;
    obj_3_misspelling.texture = augmentationTexture[texture_index];
    [objects3D_misspelling addObject:obj_3_misspelling];
    
    // add translation object
    VuforiaObject3D *obj_3_translation = [[VuforiaObject3D alloc]init];
    obj_3_translation.numVertices = marker_3_translationObject.numVertices;
    obj_3_translation.vertices = marker_3_translationObject.vertices;
    obj_3_translation.normals = marker_3_translationObject.normals;
    obj_3_translation.texCoords = marker_3_translationObject.texCoords;
    obj_3_translation.numIndices = marker_3_translationObject.numIndices;
    obj_3_translation.indices = marker_3_translationObject.indices;
    obj_3_translation.texture = augmentationTexture[texture_index];
    [objects3D_translation addObject:obj_3_translation];
    
    // add misspelling object
    VuforiaObject3D *obj_3_association = [[VuforiaObject3D alloc]init];
    obj_3_association.numVertices = marker_3_associationObject.numVertices;
    obj_3_association.vertices = marker_3_associationObject.vertices;
    obj_3_association.normals = marker_3_associationObject.normals;
    obj_3_association.texCoords = marker_3_associationObject.texCoords;
    obj_3_association.numIndices = marker_3_associationObject.numIndices;
    obj_3_association.indices = marker_3_associationObject.indices;
    obj_3_association.texture = augmentationTexture[texture_index];
    [objects3D_association addObject:obj_3_association];
    
    // add misspelling object
    VuforiaObject3D *obj_3_synonym = [[VuforiaObject3D alloc]init];
    obj_3_synonym.numVertices = marker_3_synonymObject.numVertices;
    obj_3_synonym.vertices = marker_3_synonymObject.vertices;
    obj_3_synonym.normals = marker_3_synonymObject.normals;
    obj_3_synonym.texCoords = marker_3_synonymObject.texCoords;
    obj_3_synonym.numIndices = marker_3_synonymObject.numIndices;
    obj_3_synonym.indices = marker_3_synonymObject.indices;
    obj_3_synonym.texture = augmentationTexture[texture_index];
    [objects3D_synonym addObject:obj_3_synonym];
    
    // load hints for model 4
    
    // add misspelling object
    VuforiaObject3D *obj_4_misspelling = [[VuforiaObject3D alloc]init];
    obj_4_misspelling.numVertices = marker_4_misspellingObject.numVertices;
    obj_4_misspelling.vertices = marker_4_misspellingObject.vertices;
    obj_4_misspelling.normals = marker_4_misspellingObject.normals;
    obj_4_misspelling.texCoords = marker_4_misspellingObject.texCoords;
    obj_4_misspelling.numIndices = marker_4_misspellingObject.numIndices;
    obj_4_misspelling.indices = marker_4_misspellingObject.indices;
    obj_4_misspelling.texture = augmentationTexture[texture_index];
    [objects3D_misspelling addObject:obj_4_misspelling];
    
    // add translation object
    VuforiaObject3D *obj_4_translation = [[VuforiaObject3D alloc]init];
    obj_4_translation.numVertices = marker_4_translationObject.numVertices;
    obj_4_translation.vertices = marker_4_translationObject.vertices;
    obj_4_translation.normals = marker_4_translationObject.normals;
    obj_4_translation.texCoords = marker_4_translationObject.texCoords;
    obj_4_translation.numIndices = marker_4_translationObject.numIndices;
    obj_4_translation.indices = marker_4_translationObject.indices;
    obj_4_translation.texture = augmentationTexture[texture_index];
    [objects3D_translation addObject:obj_4_translation];
    
    // add misspelling object
    VuforiaObject3D *obj_4_association = [[VuforiaObject3D alloc]init];
    obj_4_association.numVertices = marker_4_associationObject.numVertices;
    obj_4_association.vertices = marker_4_associationObject.vertices;
    obj_4_association.normals = marker_4_associationObject.normals;
    obj_4_association.texCoords = marker_4_associationObject.texCoords;
    obj_4_association.numIndices = marker_4_associationObject.numIndices;
    obj_4_association.indices = marker_4_associationObject.indices;
    obj_4_association.texture = augmentationTexture[texture_index];
    [objects3D_association addObject:obj_4_association];
    
    // add misspelling object
    VuforiaObject3D *obj_4_synonym = [[VuforiaObject3D alloc]init];
    obj_4_synonym.numVertices = marker_4_synonymObject.numVertices;
    obj_4_synonym.vertices = marker_4_synonymObject.vertices;
    obj_4_synonym.normals = marker_4_synonymObject.normals;
    obj_4_synonym.texCoords = marker_4_synonymObject.texCoords;
    obj_4_synonym.numIndices = marker_4_synonymObject.numIndices;
    obj_4_synonym.indices = marker_4_synonymObject.indices;
    obj_4_synonym.texture = augmentationTexture[texture_index];
    [objects3D_synonym addObject:obj_4_synonym];
    
    // load hints for model 5
    
    // add misspelling object
    VuforiaObject3D *obj_5_misspelling = [[VuforiaObject3D alloc]init];
    obj_5_misspelling.numVertices = marker_5_misspellingObject.numVertices;
    obj_5_misspelling.vertices = marker_5_misspellingObject.vertices;
    obj_5_misspelling.normals = marker_5_misspellingObject.normals;
    obj_5_misspelling.texCoords = marker_5_misspellingObject.texCoords;
    obj_5_misspelling.numIndices = marker_5_misspellingObject.numIndices;
    obj_5_misspelling.indices = marker_5_misspellingObject.indices;
    obj_5_misspelling.texture = augmentationTexture[texture_index];
    [objects3D_misspelling addObject:obj_5_misspelling];
    
    // add translation object
    VuforiaObject3D *obj_5_translation = [[VuforiaObject3D alloc]init];
    obj_5_translation.numVertices = marker_5_translationObject.numVertices;
    obj_5_translation.vertices = marker_5_translationObject.vertices;
    obj_5_translation.normals = marker_5_translationObject.normals;
    obj_5_translation.texCoords = marker_5_translationObject.texCoords;
    obj_5_translation.numIndices = marker_5_translationObject.numIndices;
    obj_5_translation.indices = marker_5_translationObject.indices;
    obj_5_translation.texture = augmentationTexture[texture_index];
    [objects3D_translation addObject:obj_5_translation];
    
    // add misspelling object
    VuforiaObject3D *obj_5_association = [[VuforiaObject3D alloc]init];
    obj_5_association.numVertices = marker_5_associationObject.numVertices;
    obj_5_association.vertices = marker_5_associationObject.vertices;
    obj_5_association.normals = marker_5_associationObject.normals;
    obj_5_association.texCoords = marker_5_associationObject.texCoords;
    obj_5_association.numIndices = marker_5_associationObject.numIndices;
    obj_5_association.indices = marker_5_associationObject.indices;
    obj_5_association.texture = augmentationTexture[texture_index];
    [objects3D_association addObject:obj_5_association];
    
    // add misspelling object
    VuforiaObject3D *obj_5_synonym = [[VuforiaObject3D alloc]init];
    obj_5_synonym.numVertices = marker_5_synonymObject.numVertices;
    obj_5_synonym.vertices = marker_5_synonymObject.vertices;
    obj_5_synonym.normals = marker_5_synonymObject.normals;
    obj_5_synonym.texCoords = marker_5_synonymObject.texCoords;
    obj_5_synonym.numIndices = marker_5_synonymObject.numIndices;
    obj_5_synonym.indices = marker_5_synonymObject.indices;
    obj_5_synonym.texture = augmentationTexture[texture_index];
    [objects3D_synonym addObject:obj_5_synonym];
    
    // load hints for model 6
    
    // add misspelling object
    VuforiaObject3D *obj_6_misspelling = [[VuforiaObject3D alloc]init];
    obj_6_misspelling.numVertices = marker_6_misspellingObject.numVertices;
    obj_6_misspelling.vertices = marker_6_misspellingObject.vertices;
    obj_6_misspelling.normals = marker_6_misspellingObject.normals;
    obj_6_misspelling.texCoords = marker_6_misspellingObject.texCoords;
    obj_6_misspelling.numIndices = marker_6_misspellingObject.numIndices;
    obj_6_misspelling.indices = marker_6_misspellingObject.indices;
    obj_6_misspelling.texture = augmentationTexture[texture_index];
    [objects3D_misspelling addObject:obj_6_misspelling];
    
    // add translation object
    VuforiaObject3D *obj_6_translation = [[VuforiaObject3D alloc]init];
    obj_6_translation.numVertices = marker_6_translationObject.numVertices;
    obj_6_translation.vertices = marker_6_translationObject.vertices;
    obj_6_translation.normals = marker_6_translationObject.normals;
    obj_6_translation.texCoords = marker_6_translationObject.texCoords;
    obj_6_translation.numIndices = marker_6_translationObject.numIndices;
    obj_6_translation.indices = marker_6_translationObject.indices;
    obj_6_translation.texture = augmentationTexture[texture_index];
    [objects3D_translation addObject:obj_6_translation];
    
    // add misspelling object
    VuforiaObject3D *obj_6_association = [[VuforiaObject3D alloc]init];
    obj_6_association.numVertices = marker_6_associationObject.numVertices;
    obj_6_association.vertices = marker_6_associationObject.vertices;
    obj_6_association.normals = marker_6_associationObject.normals;
    obj_6_association.texCoords = marker_6_associationObject.texCoords;
    obj_6_association.numIndices = marker_6_associationObject.numIndices;
    obj_6_association.indices = marker_6_associationObject.indices;
    obj_6_association.texture = augmentationTexture[texture_index];
    [objects3D_association addObject:obj_6_association];
    
    // add misspelling object
    VuforiaObject3D *obj_6_synonym = [[VuforiaObject3D alloc]init];
    obj_6_synonym.numVertices = marker_6_synonymObject.numVertices;
    obj_6_synonym.vertices = marker_6_synonymObject.vertices;
    obj_6_synonym.normals = marker_6_synonymObject.normals;
    obj_6_synonym.texCoords = marker_6_synonymObject.texCoords;
    obj_6_synonym.numIndices = marker_6_synonymObject.numIndices;
    obj_6_synonym.indices = marker_6_synonymObject.indices;
    obj_6_synonym.texture = augmentationTexture[texture_index];
    [objects3D_synonym addObject:obj_6_synonym];
    
    // load hints for model 7
    
    // add misspelling object
    VuforiaObject3D *obj_7_misspelling = [[VuforiaObject3D alloc]init];
    obj_7_misspelling.numVertices = marker_7_misspellingObject.numVertices;
    obj_7_misspelling.vertices = marker_7_misspellingObject.vertices;
    obj_7_misspelling.normals = marker_7_misspellingObject.normals;
    obj_7_misspelling.texCoords = marker_7_misspellingObject.texCoords;
    obj_7_misspelling.numIndices = marker_7_misspellingObject.numIndices;
    obj_7_misspelling.indices = marker_7_misspellingObject.indices;
    obj_7_misspelling.texture = augmentationTexture[texture_index];
    [objects3D_misspelling addObject:obj_7_misspelling];
    
    // add translation object
    VuforiaObject3D *obj_7_translation = [[VuforiaObject3D alloc]init];
    obj_7_translation.numVertices = marker_7_translationObject.numVertices;
    obj_7_translation.vertices = marker_7_translationObject.vertices;
    obj_7_translation.normals = marker_7_translationObject.normals;
    obj_7_translation.texCoords = marker_7_translationObject.texCoords;
    obj_7_translation.numIndices = marker_7_translationObject.numIndices;
    obj_7_translation.indices = marker_7_translationObject.indices;
    obj_7_translation.texture = augmentationTexture[texture_index];
    [objects3D_translation addObject:obj_7_translation];
    
    // add misspelling object
    VuforiaObject3D *obj_7_association = [[VuforiaObject3D alloc]init];
    obj_7_association.numVertices = marker_7_associationObject.numVertices;
    obj_7_association.vertices = marker_7_associationObject.vertices;
    obj_7_association.normals = marker_7_associationObject.normals;
    obj_7_association.texCoords = marker_7_associationObject.texCoords;
    obj_7_association.numIndices = marker_7_associationObject.numIndices;
    obj_7_association.indices = marker_7_associationObject.indices;
    obj_7_association.texture = augmentationTexture[texture_index];
    [objects3D_association addObject:obj_7_association];
    
    // add misspelling object
    VuforiaObject3D *obj_7_synonym = [[VuforiaObject3D alloc]init];
    obj_7_synonym.numVertices = marker_7_synonymObject.numVertices;
    obj_7_synonym.vertices = marker_7_synonymObject.vertices;
    obj_7_synonym.normals = marker_7_synonymObject.normals;
    obj_7_synonym.texCoords = marker_7_synonymObject.texCoords;
    obj_7_synonym.numIndices = marker_7_synonymObject.numIndices;
    obj_7_synonym.indices = marker_7_synonymObject.indices;
    obj_7_synonym.texture = augmentationTexture[texture_index];
    [objects3D_synonym addObject:obj_7_synonym];
    
    // load hints for model 8
    
    // add misspelling object
    VuforiaObject3D *obj_8_misspelling = [[VuforiaObject3D alloc]init];
    obj_8_misspelling.numVertices = marker_8_misspellingObject.numVertices;
    obj_8_misspelling.vertices = marker_8_misspellingObject.vertices;
    obj_8_misspelling.normals = marker_8_misspellingObject.normals;
    obj_8_misspelling.texCoords = marker_8_misspellingObject.texCoords;
    obj_8_misspelling.numIndices = marker_8_misspellingObject.numIndices;
    obj_8_misspelling.indices = marker_8_misspellingObject.indices;
    obj_8_misspelling.texture = augmentationTexture[texture_index];
    [objects3D_misspelling addObject:obj_8_misspelling];
    
    // add translation object
    VuforiaObject3D *obj_8_translation = [[VuforiaObject3D alloc]init];
    obj_8_translation.numVertices = marker_8_translationObject.numVertices;
    obj_8_translation.vertices = marker_8_translationObject.vertices;
    obj_8_translation.normals = marker_8_translationObject.normals;
    obj_8_translation.texCoords = marker_8_translationObject.texCoords;
    obj_8_translation.numIndices = marker_8_translationObject.numIndices;
    obj_8_translation.indices = marker_8_translationObject.indices;
    obj_8_translation.texture = augmentationTexture[texture_index];
    [objects3D_translation addObject:obj_8_translation];
    
    // add misspelling object
    VuforiaObject3D *obj_8_association = [[VuforiaObject3D alloc]init];
    obj_8_association.numVertices = marker_8_associationObject.numVertices;
    obj_8_association.vertices = marker_8_associationObject.vertices;
    obj_8_association.normals = marker_8_associationObject.normals;
    obj_8_association.texCoords = marker_8_associationObject.texCoords;
    obj_8_association.numIndices = marker_8_associationObject.numIndices;
    obj_8_association.indices = marker_8_associationObject.indices;
    obj_8_association.texture = augmentationTexture[texture_index];
    [objects3D_association addObject:obj_8_association];
    
    // add misspelling object
    VuforiaObject3D *obj_8_synonym = [[VuforiaObject3D alloc]init];
    obj_8_synonym.numVertices = marker_8_synonymObject.numVertices;
    obj_8_synonym.vertices = marker_8_synonymObject.vertices;
    obj_8_synonym.normals = marker_8_synonymObject.normals;
    obj_8_synonym.texCoords = marker_8_synonymObject.texCoords;
    obj_8_synonym.numIndices = marker_8_synonymObject.numIndices;
    obj_8_synonym.indices = marker_8_synonymObject.indices;
    obj_8_synonym.texture = augmentationTexture[texture_index];
    [objects3D_synonym addObject:obj_8_synonym];
    
    // load hints for model 9
    
    // add misspelling object
    VuforiaObject3D *obj_9_misspelling = [[VuforiaObject3D alloc]init];
    obj_9_misspelling.numVertices = marker_9_misspellingObject.numVertices;
    obj_9_misspelling.vertices = marker_9_misspellingObject.vertices;
    obj_9_misspelling.normals = marker_9_misspellingObject.normals;
    obj_9_misspelling.texCoords = marker_9_misspellingObject.texCoords;
    obj_9_misspelling.numIndices = marker_9_misspellingObject.numIndices;
    obj_9_misspelling.indices = marker_9_misspellingObject.indices;
    obj_9_misspelling.texture = augmentationTexture[texture_index];
    [objects3D_misspelling addObject:obj_9_misspelling];
    
    // add translation object
    VuforiaObject3D *obj_9_translation = [[VuforiaObject3D alloc]init];
    obj_9_translation.numVertices = marker_9_translationObject.numVertices;
    obj_9_translation.vertices = marker_9_translationObject.vertices;
    obj_9_translation.normals = marker_9_translationObject.normals;
    obj_9_translation.texCoords = marker_9_translationObject.texCoords;
    obj_9_translation.numIndices = marker_9_translationObject.numIndices;
    obj_9_translation.indices = marker_9_translationObject.indices;
    obj_9_translation.texture = augmentationTexture[texture_index];
    [objects3D_translation addObject:obj_9_translation];
    
    // add misspelling object
    VuforiaObject3D *obj_9_association = [[VuforiaObject3D alloc]init];
    obj_9_association.numVertices = marker_9_associationObject.numVertices;
    obj_9_association.vertices = marker_9_associationObject.vertices;
    obj_9_association.normals = marker_9_associationObject.normals;
    obj_9_association.texCoords = marker_9_associationObject.texCoords;
    obj_9_association.numIndices = marker_9_associationObject.numIndices;
    obj_9_association.indices = marker_9_associationObject.indices;
    obj_9_association.texture = augmentationTexture[texture_index];
    [objects3D_association addObject:obj_9_association];
    
    // add misspelling object
    VuforiaObject3D *obj_9_synonym = [[VuforiaObject3D alloc]init];
    obj_9_synonym.numVertices = marker_9_synonymObject.numVertices;
    obj_9_synonym.vertices = marker_9_synonymObject.vertices;
    obj_9_synonym.normals = marker_9_synonymObject.normals;
    obj_9_synonym.texCoords = marker_9_synonymObject.texCoords;
    obj_9_synonym.numIndices = marker_9_synonymObject.numIndices;
    obj_9_synonym.indices = marker_9_synonymObject.indices;
    obj_9_synonym.texture = augmentationTexture[texture_index];
    [objects3D_synonym addObject:obj_9_synonym];
}



@end