

#import <UIKit/UIKit.h>

@interface igViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIView * viewPreview;
@property (weak, nonatomic) IBOutlet UILabel * lblviewPreview;
@property (weak, nonatomic) IBOutlet UILabel * lblStatus;
@property (weak, nonatomic) IBOutlet UIBarButtonItem * bbitemStart;
@property (nonatomic) BOOL isReading;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
- (IBAction)startStopReading:(id)sender;
@end