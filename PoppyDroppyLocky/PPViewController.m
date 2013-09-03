//
//  PPViewController.m
//  PoppyDroppyLocky
//
//  Created by Joseph Gibson on 8/30/13.
//  Copyright (c) 2013 Joseph. All rights reserved.
//

#import "PPViewController.h"
#import <CoreMedia/CMBufferQueue.h>
#import <AVFoundation/AVFoundation.h>
#import "RosyWriterPreviewView.h"

#define BYTES_PER_PIXEL 4

@implementation PPViewController
{
	CMBufferQueueRef previewBufferQueue;
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
	AVCaptureConnection *videoConnection;
    RosyWriterPreviewView *oglView;
}

- (void)dealloc
{
	if (previewBufferQueue) {
		CFRelease(previewBufferQueue);
		previewBufferQueue = NULL;
	}
}

- (AVCaptureDevice *)videoDeviceWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
        if ([device position] == position)
            return device;
    
    return nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIView *view = self.view;
    [view setBackgroundColor:[UIColor brownColor]];
    
	oglView = [[RosyWriterPreviewView alloc] initWithFrame:CGRectZero];
	// Our interface is always in portrait.
    [view addSubview:oglView];
 	oglView.bounds = CGRectMake(0,0,view.bounds.size.height,view.bounds.size.width);
    oglView.center = CGPointMake(view.bounds.size.height/2.0, view.bounds.size.width/2.0);
    
    
	// Create a shallow queue for buffers going to the display for preview.
	OSStatus err = CMBufferQueueCreate(kCFAllocatorDefault, 1, CMBufferQueueGetCallbacksForUnsortedSampleBuffers(), &previewBufferQueue);
	if (err)
		[self showError:[NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil]];
    
    
    //CALayer *viewLayer = view.layer;
    //CALayer *maskLayer = [CALayer layer];
    //maskLayer.frame = CGRectMake( 0, 0, view.bounds.size.height, view.bounds.size.width );
    //viewLayer.mask = maskLayer;
    //viewLayer.masksToBounds = YES;
    
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    session.sessionPreset = AVCaptureSessionPresetiFrame960x540;
    
    AVCaptureDeviceInput *input = [[AVCaptureDeviceInput alloc] initWithDevice:[self videoDeviceWithPosition:AVCaptureDevicePositionBack] error:nil];
    
    if ([session canAddInput:input])
        [session addInput:input];
    
    if (!input) {
        //handle the error appropriately.
    }
    
    
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    
	[output setAlwaysDiscardsLateVideoFrames:YES];
	[output setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
	dispatch_queue_t videoCaptureQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
	[output setSampleBufferDelegate:self queue:videoCaptureQueue];
    
    
    captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
	//captureVideoPreviewLayer.orientation = AVCaptureVideoOrientationLandscapeLeft;
    //captureVideoPreviewLayer.frame = CGRectMake(0,view.bounds.origin.y,view.bounds.size.height,view.bounds.size.width);
    //[viewLayer addSublayer:captureVideoPreviewLayer];
    
    if ([session canAddOutput:output]) {
        [session addOutput:output];
    }
    
	videoConnection = [output connectionWithMediaType:AVMediaTypeVideo];
    [videoConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
	[session startRunning];

}

- (NSUInteger)supportedInterfaceOrientations
{
    //decide number of origination tob supported by Viewcontroller.
    return (UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight);
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
    if( [[UIDevice currentDevice] orientation] == AVCaptureVideoOrientationLandscapeLeft )
    {
        [videoConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
    }
    else
    {
        [videoConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
    }
}

- (void)processPixelBuffer: (CVImageBufferRef)pixelBuffer
{
	CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
	
	int bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
	int bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
	unsigned char *pixel = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    
	for( int row = 0; row < bufferHeight; row++ ) {
		for( int column = 0; column < bufferWidth; column++ ) {
			pixel[1] = 0;//pixels[(bufferHeight-row-1)*BYTES_PER_PIXEL*bufferWidth + column*BYTES_PER_PIXEL + 1]; // De-green (second pixel in BGRA is green)
			pixel += BYTES_PER_PIXEL;
		}
	}
	
	CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
}

#pragma mark Capture

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
	if ( connection == videoConnection ) {
		
        NSLog(@"Sample Buffer");
		//// Get framerate
		//CMTime timestamp = CMSampleBufferGetPresentationTimeStamp( sampleBuffer );
		//[self calculateFramerateAtTimestamp:timestamp];
        
		//// Get frame dimensions (for onscreen display)
		//if (self.videoDimensions.width == 0 && self.videoDimensions.height == 0)
		//	self.videoDimensions = CMVideoFormatDescriptionGetDimensions( formatDescription );
		
		//// Get buffer type
		//if ( self.videoType == 0 )
		//	self.videoType = CMFormatDescriptionGetMediaSubType( formatDescription );
        
		CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
		// Synchronously process the pixel buffer to de-green it.
		[self processPixelBuffer:pixelBuffer];
        
        
		// Enqueue it for preview.  This is a shallow queue, so if image processing is taking too long,
		// we'll drop this frame for preview (this keeps preview latency low).
		OSStatus err = CMBufferQueueEnqueue(previewBufferQueue, sampleBuffer);
		if ( !err ) {
			dispatch_async(dispatch_get_main_queue(), ^{
				CMSampleBufferRef sbuf = (CMSampleBufferRef)CMBufferQueueDequeueAndRetain(previewBufferQueue);
				if (sbuf) {
					CVImageBufferRef pixBuf = CMSampleBufferGetImageBuffer(sbuf);
					[self pixelBufferReadyForDisplay:pixBuf];
					CFRelease(sbuf);
				}
			});
		}
        
	}
}

- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    NSLog(@"imageFromSampleBuffer: called");
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)pixelBufferReadyForDisplay:(CVPixelBufferRef)pixelBuffer
{
	// Don't make OpenGLES calls while in the background.
	if ( [UIApplication sharedApplication].applicationState != UIApplicationStateBackground )
		[oglView displayPixelBuffer:pixelBuffer];
}

#pragma mark Error Handling

- (void)showError:(NSError *)error
{
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                            message:[error localizedFailureReason]
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    });
}

@end
