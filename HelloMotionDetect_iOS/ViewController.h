//
//  ViewController.h
//  HelloMotionDetect_iOS
//
//  Copyright (c) 2015 Aumentia. All rights reserved.
//
//  Written by Pablo GM <info@aumentia.com>, September 2015
//

#import <UIKit/UIKit.h>
#import <VS/VS.h>
#import "CaptureSessionManager.h"

@interface ViewController : UIViewController<vsMotionProtocol, CameraCaptureDelegate>


@end

