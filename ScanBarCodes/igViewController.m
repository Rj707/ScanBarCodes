

#import <AVFoundation/AVFoundation.h>
#import "igViewController.h"

/**** AVCaptureMetadataOutputObjectsDelegate:a protocol, should be adopted by the delegate of Metadat Output object ****/

@interface igViewController () <AVCaptureMetadataOutputObjectsDelegate,UIAlertViewDelegate>
{
    /**** Initializing the objects of AVCapture Session,Device,Device Input and Metadat Output ****/
    AVCaptureSession *_session;
    AVCaptureDevice *_device;
    AVCaptureDeviceInput *_input;
    AVCaptureMetadataOutput *_output;
    AVCaptureVideoPreviewLayer *_prevLayer;

    UIView *_highlightView;
}

-(void)loadBeepSound;

@end

@implementation igViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _isReading = NO;
    
    _highlightView = [[UIView alloc] init];
    //**** resizing ourself when parentview changes its bounds ****//
    _highlightView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
    _highlightView.layer.borderColor = [UIColor blueColor].CGColor;
    _highlightView.layer.borderWidth = 3;
    [self.view addSubview:_highlightView];
}

- (IBAction)startStopReading:(id)sender
{
    if (!_isReading)
    {
        // This is the case where the app should read a QR code when the START button is tapped.
        if ([self startReading])
        {
            /**** If the startReading methods returns YES and the capture session is successfully
             running, then change the start button title and the status message ****/
            [_bbitemStart setTitle:@"Stop"];
            [_lblStatus setText:@"Scanning for Bar Code..."];
        }
    }
    
    else
    {
        // This is the case where the app is currently reading a QR code and it should STOP doing so
        [self stopReading];
        // The bar button item's title should change again.
        [_bbitemStart setTitle:@"Start!"];
    }
    
    // Set to the flag the exact opposite value of the one that currently has.
    _isReading = !_isReading;
}


#pragma mark - Private method implementation

- (BOOL)startReading
{
    _lblviewPreview.hidden = YES;
    NSError * error;
    
    //**** default device of the "Given Media Type" currently available on the system ****//
    //**** for AVMediaTypeVideo, built-in camera is the default device ****//
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //deviceInputWithDevice:Returns an AVCaptureDeviceInput instance that provides "Media Data" from the given device
    _input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&error];
    
    if (!_input)
    {
        // If any error occurs, simply log the description of it and don't continue any more.
        NSLog(@"%@", [error localizedDescription]);
        return NO;
    }
    
    // Initialize the captureSession object.
   _session = [[AVCaptureSession alloc] init];
    
    // Set the input device on the capture session.
    [_session addInput:_input];
    
    // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
    _output = [[AVCaptureMetadataOutput alloc] init];
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [_session addOutput:_output];
    
    /* availableMetadataObjectTypes: receiver's supported "Metadata Object" types */
    _output.metadataObjectTypes = [_output availableMetadataObjectTypes];
    
    /* AVCaptureVideoPreviewLayer: for previewing the visual output of an AVCaptureSession */
    _prevLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [_prevLayer setFrame:_viewPreview.layer.bounds];
    [_viewPreview.layer addSublayer:_prevLayer];
    
    /* starts the flow of data from the "Inputs" to the "Outputs" */
    // Start video capture.
    [_session startRunning];
    
    [self.view bringSubviewToFront:_highlightView];
    return YES;
}


-(void)stopReading
{
    _highlightView.hidden = YES;
    _lblStatus.text = @"Bar Code Reader has been Stopped...!";
    _lblviewPreview.hidden = NO;
    // Stop video capture and make the capture session object nil.
    [_session stopRunning];
    _session = nil;
    
    // Remove the video preview layer from the viewPreview view's layer.
    [_prevLayer removeFromSuperlayer];
}

-(void)loadBeepSound
{
    // Get the path to the beep.mp3 file and convert it to a NSURL object.
    NSString * beepFilePath = [[NSBundle mainBundle] pathForResource:@"beep" ofType:@"mp3"];
    NSURL * beepURL = [NSURL URLWithString:beepFilePath];
    
    NSError * error;
    
    // Initialize the audio player object using the NSURL object previously set.
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:beepURL error:&error];
    if (error)
    {
        // If the audio player cannot be initialized then log a message.
        NSLog(@"Could not play beep file.");
        NSLog(@"%@", [error localizedDescription]);
    }
    else
    {
        // If the audio player was successfully initialized then load it in memory.
        [_audioPlayer prepareToPlay];
    }
}


/* Informs the delegate that the "AVCaptureMetadataOutput" emitted new metadata objects */
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    CGRect highlightViewRect = CGRectZero;
    /* AVMetadataMachineReadableCodeObject: Class defining the features of a detected one-dimensional or two-dimensional barcode */
    AVMetadataMachineReadableCodeObject * barCodeObject;
    NSString * detectionString = nil;
    
    /* barCodeTypesArray: array containing the supported barcode types */
    NSArray * barCodeTypesArray = @[AVMetadataObjectTypeUPCECode, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode39Mod43Code,
            AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeCode128Code,
            AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeQRCode, AVMetadataObjectTypeAztecCode];

    for (AVMetadataObject * newMetaDataObj in metadataObjects)
    {
        for (NSString * type in barCodeTypesArray)
        {
            if ([newMetaDataObj.type isEqualToString:type])
            {
                /* transformedMetadataObjectForMetadataObject: Converts an AVMetadataObject's visual properties to layer coordinates */
                barCodeObject = (AVMetadataMachineReadableCodeObject *)[_prevLayer transformedMetadataObjectForMetadataObject:(AVMetadataMachineReadableCodeObject *)newMetaDataObj];
                
                highlightViewRect = barCodeObject.bounds;
                
                detectionString = [(AVMetadataMachineReadableCodeObject *)newMetaDataObj stringValue];
                break;
            }
        }

        if (detectionString != nil)
        {
            // If the audio player is not nil, then play the sound effect.
            if (_audioPlayer)
            {
                [_audioPlayer play];
            }

            _lblStatus.text = @"Got the Code!  ";
            _lblStatus.text = [_lblStatus.text stringByAppendingString:detectionString];
//            UIAlertView * barAlerView = [[UIAlertView alloc] initWithTitle:detectionString
//                                                              message:@"You Have successfully Read the Barcode."
//                                                             delegate:self
//                                                    cancelButtonTitle:@"OK"
//                                                    otherButtonTitles:nil];
//            
//            [self performSelector:@selector(dismiss:) withObject:barAlerView afterDelay:1.0];
//            [barAlerView show];
            
            break;
        }

    }
    
    _highlightView.frame = highlightViewRect;
       _highlightView.hidden = NO;
}


//-(void)dismiss:(UIAlertView *)alertView
//{
//    [alertView dismissWithClickedButtonIndex:0 animated:YES];
//}

@end