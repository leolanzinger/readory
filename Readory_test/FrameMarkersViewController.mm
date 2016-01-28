//
//  FrameMarkerViewController.m
//  Readory_test
//
//  Created by Leonardo Lanzinger on 19/01/16.
//  Copyright © 2016 Leonardo Lanzinger. All rights reserved.
//

#import "FrameMarkersViewController.h"
#import "FrameMarkersEAGLView.h"
#import <QCAR/QCAR.h>
#import <QCAR/TrackerManager.h>
#import <QCAR/MarkerTracker.h>
#import <QCAR/Trackable.h>
#import <QCAR/CameraDevice.h>
#import "AppDelegate.h"

@interface FrameMarkersViewController ()

//@property (weak, nonatomic) IBOutlet UIImageView *ARViewPlaceholder;

@end

@implementation FrameMarkersViewController

@synthesize tapGestureRecognizer, vapp, eaglView;

- (CGRect)getCurrentARViewFrame
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGRect viewFrame = screenBounds;
    
    // If this device has a retina display, scale the view bounds
    // for the AR (OpenGL) view
    if (YES == vapp.isRetinaDisplay) {
        viewFrame.size.width *= 2.0;
        viewFrame.size.height *= 2.0;
    }
    return viewFrame;
}


- (void) pauseAR {
    NSError * error = nil;
    if (![vapp pauseAR:&error]) {
        NSLog(@"Error pausing AR:%@", [error description]);
    }
}

- (void) resumeAR {
    NSError * error = nil;
    if(! [vapp resumeAR:&error]) {
        NSLog(@"Error resuming AR:%@", [error description]);
    }
    // on resume, we reset the flash
    QCAR::CameraDevice::getInstance().setFlashTorchMode(false);
    flashEnabled = NO;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)loadView
{
    
    
    continuousAutofocusEnabled = YES;
    flashEnabled = NO;
    frontCameraEnabled = NO;
    
    vapp = [[SampleApplicationSession alloc] initWithDelegate:self];
    
    CGRect viewFrame = [self getCurrentARViewFrame];
    
    
    eaglView = [[FrameMarkersEAGLView alloc] initWithFrame:viewFrame appSession:vapp];
    [self setView:eaglView];
    [eaglView setVC:self];
    
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    appDelegate.glResourceHandler = eaglView;
    
    // a single tap will trigger a single autofocus operation
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(autofocus:)];

    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSuccessSegue:)];
    [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
    [self.view addGestureRecognizer:swipeRight];
    
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleFailSegue:)];
    [swipeLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
    [self.view addGestureRecognizer:swipeLeft];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dismissARViewController)
                                                 name:@"kDismissARViewController"
                                               object:nil];
    
    // we use the iOS notification to pause/resume the AR when the application goes (or come back from) background
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(pauseAR)
     name:UIApplicationWillResignActiveNotification
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(resumeAR)
     name:UIApplicationDidBecomeActiveNotification
     object:nil];
    
    // initialize AR
    [vapp initAR:QCAR::GL_20 orientation:self.interfaceOrientation];
    
    // show loading animation while AR is being initialized
    [self showLoadingAnimation];
    
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [vapp stopAR:nil];
    
    // Be a good OpenGL ES citizen: now that QCAR is paused and the render
    // thread is not executing, inform the root view controller that the
    // EAGLView should finish any OpenGL ES commands
    [self finishOpenGLESCommands];
}

- (void)finishOpenGLESCommands
{
    // Called in response to applicationWillResignActive.  Inform the EAGLView
    [eaglView finishOpenGLESCommands];
}

- (void)freeOpenGLESResources
{
    // Called in response to applicationDidEnterBackground.  Inform the EAGLView
    [eaglView freeOpenGLESResources];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Initialize the application trackers
- (bool) doInitTrackers {
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    
    
    // Marker Tracker...
    QCAR::Tracker* trackerBase = trackerManager.initTracker(QCAR::MarkerTracker::getClassType());
    if (trackerBase == NULL)
    {
        NSLog(@"Failed to initialize MarkerTracker.");
        return NO;
    }
    // Create the markers required
    QCAR::MarkerTracker* markerTracker = static_cast<QCAR::MarkerTracker*>(trackerBase);
    if (markerTracker == NULL)
    {
        NSLog(@"Failed to get MarkerTracker.");
        return NO;
    }
    
    // Create frame markers: - put them into an xml file
    if (!markerTracker->createFrameMarker(0, "Marker0", QCAR::Vec2F(50,50)) ||
        !markerTracker->createFrameMarker(1, "Marker1", QCAR::Vec2F(50,50)) ||
        !markerTracker->createFrameMarker(2, "Marker2", QCAR::Vec2F(50,50)) ||
        !markerTracker->createFrameMarker(3, "Marker3", QCAR::Vec2F(50,50)) ||
        !markerTracker->createFrameMarker(4, "Marker4", QCAR::Vec2F(50,50)) ||
        !markerTracker->createFrameMarker(5, "Marker5", QCAR::Vec2F(50,50)) ||
        !markerTracker->createFrameMarker(6, "Marker6", QCAR::Vec2F(50,50)) ||
        !markerTracker->createFrameMarker(7, "Marker7", QCAR::Vec2F(50,50)) ||
        !markerTracker->createFrameMarker(8, "Marker8", QCAR::Vec2F(50,50)) ||
        !markerTracker->createFrameMarker(9, "Marker9", QCAR::Vec2F(50,50))  ||
        !markerTracker->createFrameMarker(10, "Marker10", QCAR::Vec2F(50,50)) ||
        !markerTracker->createFrameMarker(11, "Marker11", QCAR::Vec2F(50,50)) ||
        !markerTracker->createFrameMarker(12, "Marker12", QCAR::Vec2F(50,50)) ||
        !markerTracker->createFrameMarker(13, "Marker13", QCAR::Vec2F(50,50)) ||
        !markerTracker->createFrameMarker(14, "Marker14", QCAR::Vec2F(50,50)) ||
        !markerTracker->createFrameMarker(15, "Marker15", QCAR::Vec2F(50,50)) ||
        !markerTracker->createFrameMarker(16, "Marker16", QCAR::Vec2F(50,50)) ||
        !markerTracker->createFrameMarker(17, "Marker17", QCAR::Vec2F(50,50)) ||
        !markerTracker->createFrameMarker(18, "Marker18", QCAR::Vec2F(50,50)) ||
        !markerTracker->createFrameMarker(19, "Marker19", QCAR::Vec2F(50,50)))
    {
        NSLog(@"Failed to create frame markers.");
        return NO;
    }
    return YES;
}

// load the data associated to the trackers
- (bool) doLoadTrackersData {
    return YES;
}

// start the application trackers
- (bool) doStartTrackers {
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::Tracker* tracker = trackerManager.getTracker(QCAR::MarkerTracker::getClassType());
    if(tracker == 0) {
        return NO;
    }
    tracker->start();
    return YES;
}

#pragma mark - loading animation

- (void) showLoadingAnimation {
    CGRect indicatorBounds;
    CGRect mainBounds = [[UIScreen mainScreen] bounds];
    int smallerBoundsSize = MIN(mainBounds.size.width, mainBounds.size.height);
    int largerBoundsSize = MAX(mainBounds.size.width, mainBounds.size.height);
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown ) {
        indicatorBounds = CGRectMake(smallerBoundsSize / 2 - 12,
                                     largerBoundsSize / 2 - 12, 24, 24);
    }
    else {
        indicatorBounds = CGRectMake(largerBoundsSize / 2 - 12,
                                     smallerBoundsSize / 2 - 12, 24, 24);
    }
    
    UIActivityIndicatorView *loadingIndicator = [[UIActivityIndicatorView alloc]
                                                 initWithFrame:indicatorBounds];
    
    loadingIndicator.tag  = 1;
    loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [eaglView addSubview:loadingIndicator];
    [loadingIndicator startAnimating];
}

- (void) hideLoadingAnimation {
    UIActivityIndicatorView *loadingIndicator = (UIActivityIndicatorView *)[eaglView viewWithTag:1];
    [loadingIndicator removeFromSuperview];
}

// callback called when the initailization of the AR is done
- (void) onInitARDone:(NSError *)initError {
    UIActivityIndicatorView *loadingIndicator = (UIActivityIndicatorView *)[eaglView viewWithTag:1];
    [loadingIndicator removeFromSuperview];
    
    if (initError == nil) {
        NSError * error = nil;
        [vapp startAR:QCAR::CameraDevice::CAMERA_BACK error:&error];
        
        // by default, we try to set the continuous auto focus mode
        continuousAutofocusEnabled = QCAR::CameraDevice::getInstance().setFocusMode(QCAR::CameraDevice::FOCUS_MODE_CONTINUOUSAUTO);
        
    } else {
        NSLog(@"Error initializing AR:%@", [initError description]);
        dispatch_async( dispatch_get_main_queue(), ^{
            
            /*UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:[initError localizedDescription]
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];*/
        });
    }
}

- (void)dismissARViewController
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController popToRootViewControllerAnimated:NO];
}

// update from the QCAR loop
- (void) onQCARUpdate: (QCAR::State *) state {
}

// stop your trackerts
- (bool) doStopTrackers {
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::Tracker* tracker = trackerManager.getTracker(QCAR::MarkerTracker::getClassType());
    if(tracker != 0) {
        tracker->stop();
    }
    return YES;
}

// unload the data associated to your trackers
- (bool) doUnloadTrackersData {
    return YES;
}

// deinitialize your trackers
- (bool) doDeinitTrackers {
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    trackerManager.deinitTracker(QCAR::MarkerTracker::getClassType());
    return YES;
}

- (void)autofocus:(UITapGestureRecognizer *)sender
{
    [self performSelector:@selector(cameraPerformAutoFocus) withObject:nil afterDelay:.4];
}

- (void)cameraPerformAutoFocus
{
    QCAR::CameraDevice::getInstance().setFocusMode(QCAR::CameraDevice::FOCUS_MODE_TRIGGERAUTO);
}

-(void)handleSuccessSegue:(UISwipeGestureRecognizer*)gesture
{
    [self performSegueWithIdentifier:@"nextTurnSuccessSegue" sender:self];
}

-(void)handleFailSegue:(UISwipeGestureRecognizer*)gesture
{
    [self performSegueWithIdentifier:@"nextTurnFailSegue" sender:self];
}

-(void)handleSuccessPick {
    [self performSegueWithIdentifier:@"nextTurnSuccessSegue" sender:self];
}

-(void)handleFailPick {
    [self performSegueWithIdentifier:@"nextTurnFailSegue" sender:self];
}


@end
