//
//  ViewController.h
//  HelloMotionDetect_iOS
//
//  Copyright (c) 2015 Aumentia. All rights reserved.
//
//  Written by Pablo GM <info@aumentia.com>, September 2015
//

#import "ViewController.h"

///////////////
#define VSLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

#define VSAlert(fmt, ...)  { UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Result" message:[NSString stringWithFormat:fmt, ##__VA_ARGS__]  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil]; [alert show]; }
///////////////


@interface ViewController ()
{
    vsMotion                    *_aumMotion;
    CaptureSessionManager       *_captureManager;
    UIView                      *_cameraView;
}
@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated
{
    UIImage *myLogo         = [UIImage imageNamed:@"aumentia®.png"];
    UIImageView *myLogoView = [[UIImageView alloc] initWithImage:myLogo];
    [myLogoView setFrame:CGRectMake(0, 0, 150, 61)];
    [self.view addSubview:myLogoView];
    [self.view bringSubviewToFront:myLogoView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self initCapture];
    
    [self addMotionDetect];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self removeCapture];
    
    [self removeMotionDetect];
}


#pragma mark - AumMotion Life Cycle

- (void)addMotionDetect
{
    if ( !_aumMotion )
    {
        // Init
        _aumMotion = [[vsMotion alloc] initWithKey:@"749c6205e9c035d3850b509aa94d1bb5d8d89b4a" setDebug:YES];
        
        // Set delegate
        [_aumMotion setVsMotionDelegate:self];
        
        // Add motion filter
        [_aumMotion initMotionDetectionWithThreshold:3 enableDebugLog:NO];
        
        [_aumMotion setInactivePeriod:[NSNumber numberWithInt:LOWDELAY]];
        
        // Add ROIs
        CGRect ROI1 = CGRectMake(5, 5, 20, 20);
        [_aumMotion addButtonWithRect:ROI1];
        
        CGRect ROI2 = CGRectMake(80, 80, 15, 15);
        [_aumMotion addButtonWithRect:ROI2];
        
        // Draw ROIs
        [self addRectToView:ROI1];
        [self addRectToView:ROI2];
    }
}

- (void)removeMotionDetect
{
    if ( _aumMotion )
    {
        [_aumMotion removeMotionDetection];
        
        [_aumMotion clearButtons];
        
        _aumMotion.vsMotionDelegate = nil;
        _aumMotion                   = nil;
    }
}


#pragma mark - Camera management

- (void)initCapture
{
    // init capture manager
    _captureManager = [[CaptureSessionManager alloc] init];
    
    // set delegate
    _captureManager.delegate = self;
    
    // set video streaming quality
    _captureManager.captureSession.sessionPreset = AVCaptureSessionPresetPhoto; 
    
    [_captureManager setOutPutSetting:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]]; //kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
    
    [_captureManager addVideoInput:AVCaptureDevicePositionFront]; //AVCaptureDevicePositionFront / AVCaptureDevicePositionBack
    [_captureManager addVideoOutput];
    [_captureManager addVideoPreviewLayer];
    
    CGRect layerRect = self.view.bounds;
    
    [[_captureManager previewLayer] setOpaque: 0];
    [[_captureManager previewLayer] setBounds:layerRect ];
    [[_captureManager previewLayer] setPosition:CGPointMake( CGRectGetMidX(layerRect), CGRectGetMidY(layerRect) ) ];
    
    // create a view, on which we attach the AV Preview layer
    _cameraView = [[UIView alloc] initWithFrame:self.view.bounds];
    [[_cameraView layer] addSublayer:[_captureManager previewLayer]];
    
    // add the view we just created as a subview to the View Controller's view
    [self.view addSubview: _cameraView];
    
    // start !
    [self performSelectorInBackground:@selector(start_captureManager) withObject:nil];
    
}

- (void)removeCapture
{
    [_captureManager.captureSession stopRunning];
    [_cameraView removeFromSuperview];
    _captureManager     = nil;
    _cameraView         = nil;
}

- (void)start_captureManager
{
    @autoreleasepool
    {
        [[_captureManager captureSession] startRunning];
    }
}

- (void)processNewCameraFrameRGB:(CVImageBufferRef)cameraFrame
{
    [_aumMotion processRGBFrame:cameraFrame saveImageToPhotoAlbum:NO];
}

- (void)processNewCameraFrameYUV:(CVImageBufferRef)cameraFrame
{
    [_aumMotion processYUVFrame:cameraFrame saveImageToPhotoAlbum:NO];
}


#pragma mark - Delegates

- (void)buttonClicked:(NSNumber *)buttonId
{
    VSLog("Clicked button %d", buttonId.intValue);
}

- (void)buttonsActive:(BOOL)isActive
{
    if ( !isActive )
    {
        VSLog("Buttons disabled");
    }
}


#pragma mark - Utils

- (void)addRectToView:(CGRect)rect
{
    CGSize result = [[UIScreen mainScreen] bounds].size;
    
    CGRect _rect = CGRectMake(rect.origin.x / 100.0f * result.width,
                              rect.origin.y / 100.0f * result.height,
                              rect.size.width / 100.0f * result.width,
                              rect.size.height / 100.0f * result.height);
    
    // Add frame capturer
    UIView* frameView = [[UIView alloc] initWithFrame:_rect];
    frameView.backgroundColor = [UIColor clearColor];
    frameView.layer.borderColor = [self colorWithHexString:@"009ee0"].CGColor;
    frameView.layer.borderWidth = 3.0f;
    [self.view addSubview:frameView];
}

-(UIColor*)colorWithHexString:(NSString*)hex
{
    NSString *cString = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // String should be 6 or 8 characters
    if ([cString length] < 6) return [UIColor grayColor];
    
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
    
    if ([cString length] != 6) return  [UIColor grayColor];
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:1.0f];
}


#pragma mark - Memory Management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
