//
//  ViewController.m
//  CPVideoKit
//
//  Created by Can Poyrazoğlu on 17.11.2017.
//  Copyright © 2017 Can Poyrazoglu. All rights reserved.
//

#import "ViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "CPVideo.h"


@interface ViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *cropArea;
@property (weak, nonatomic) IBOutlet UILabel *aspectRatioLabel;
@property (weak, nonatomic) IBOutlet UIButton *exportButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cropAreaHeightConstraint;
@property (weak, nonatomic) IBOutlet UIView *videoView;
@property (weak, nonatomic) IBOutlet UITextField *maxSizeField;

@end

@implementation ViewController{
    BOOL didPickVideo;
    UIImagePickerController *picker;
    
    AVAsset *asset;
    AVPlayerItem *playerItem;
    AVPlayer *player;
    AVPlayerLayer *playerLayer;
    
    int maxWidth, maxHeight;
    
    AVPlayerViewController *exportedVideoPlayerController;
    
}

- (IBAction)didChangeAspectRatioSliderValue:(UISlider *)sender {
    float cropAreaWidth = self.cropArea.frame.size.width;
    self.cropAreaHeightConstraint.constant = cropAreaWidth * sender.value;
    self.aspectRatioLabel.text = [NSString stringWithFormat:@"Aspect ratio: %.3f", sender.value];
    [self syncPlayerFrame];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if(!didPickVideo){
        picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.mediaTypes = @[(NSString*)kUTTypeMovie, (NSString*)kUTTypeAVIMovie, (NSString*)kUTTypeVideo, (NSString*)kUTTypeMPEG4];
        
        picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
        [self presentViewController:picker animated:YES completion:nil];
    }else{
        [player play];
    }
}
- (IBAction)didTapBackground:(id)sender {
    [self.view endEditing:YES];
    NSString *maxWidthHeightString = [self.maxSizeField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray *parts = [maxWidthHeightString componentsSeparatedByString:@"x"];
    if(parts.count == 2){
        maxWidth = [parts[0] intValue];
        maxHeight = [parts[1] intValue];
        if(!maxWidth || !maxHeight){
            self.maxSizeField.text = @"";
            maxWidth = 0;
            maxHeight = 0;
        }
    }else{
        self.maxSizeField.text = @"";
        maxWidth = 0;
        maxHeight = 0;
    }
}

-(void)syncPlayerFrame{
    playerLayer.frame = self.videoView.frame;
    [playerLayer removeAllAnimations];
}

- (IBAction)didPanVideo:(UIPanGestureRecognizer *)sender {
    static CGPoint startPoint;
    static CGPoint startPlayerOrigin;
    if(sender.state == UIGestureRecognizerStateBegan){
        startPoint = [sender translationInView:self.cropArea];
        startPlayerOrigin = self.videoView.frame.origin;
    }
    CGPoint translation = [sender translationInView:self.cropArea];
    CGPoint totalDiff = CGPointMake(translation.x - startPoint.x, translation.y - startPoint.y);
    CGRect playerFrame = self.videoView.frame;
    playerFrame = CGRectMake(startPlayerOrigin.x + totalDiff.x,
                             startPlayerOrigin.y + totalDiff.y,
                             playerFrame.size.width,
                             playerFrame.size.height);
    self.videoView.frame = playerFrame;
    [self syncPlayerFrame];
    
}

- (IBAction)didPinchVideo:(UIPinchGestureRecognizer *)sender {
    static CGRect startPlayerFrame;
    if(sender.state == UIGestureRecognizerStateBegan){
        startPlayerFrame = self.videoView.frame;
    }
    float zoom = sender.scale;
    CGPoint currentCenter = self.videoView.center;
    CGSize newSize = CGSizeMake(startPlayerFrame.size.width * zoom, startPlayerFrame.size.height * zoom);
    CGRect newRect = CGRectMake(startPlayerFrame.origin.x, startPlayerFrame.origin.y, newSize.width, newSize.height);
    self.videoView.frame = newRect;
    self.videoView.center = currentCenter;
    [self syncPlayerFrame];
}

-(void)playVideoAtURL:(NSURL*)url{
    asset = [AVAsset assetWithURL:url];
    playerItem = [AVPlayerItem playerItemWithAsset:asset];
    player = [AVPlayer playerWithPlayerItem:playerItem];
    playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.masksToBounds = YES;
    playerLayer.opacity = 0.75;
    AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    CGSize size = videoTrack.naturalSize;
    size = CGSizeApplyAffineTransform(size, asset.preferredTransform);
    size = CGSizeApplyAffineTransform(size, videoTrack.preferredTransform);
    size = CGSizeMake(fabs(size.width), fabs(size.height));
    self.videoView.frame = CGRectMake(30, 100, 300, 300 * size.height / size.width);
    playerLayer.frame = self.videoView.bounds;
    [self.view.layer addSublayer:playerLayer];
    [player play];
}

- (IBAction)didTapExportButton:(id)sender {
    [CPVideo enableDiagnostics];
    [player pause];
    self.exportButton.enabled = NO;
    CPVideoExportOptions *exportOptions = [[CPVideoExportOptions alloc] init];
    exportOptions.maximumSize = CGSizeMake(maxWidth, maxHeight); //just some nonstandard size
    exportOptions.normalizedCropArea =[CPVideo normalizedVideoFrame:self.videoView.frame relativeToCropRectangle:self.cropArea.frame];
    NSLog(@"Exporting at maximum size (%d, %d) with crop area (%.3f, %.3f), (%.3f, %.3f)...",
          (int)exportOptions.maximumSize.width,
          (int)exportOptions.maximumSize.height,
          exportOptions.normalizedCropArea.origin.x,
          exportOptions.normalizedCropArea.origin.y,
          exportOptions.normalizedCropArea.size.width,
          exportOptions.normalizedCropArea.size.height);
    CPVideo *video = [[CPVideo alloc] initWithAsset:asset];
    NSURL *tempURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"ExportedVideo.mov"]];
    [video exportVideoAtURL:tempURL withOptions:exportOptions progress:^(float progress) {
        [self.exportButton setTitle:[NSString stringWithFormat:@"Exporting... %d%%", (int)(progress * 100)] forState:UIControlStateDisabled];
    } completion:^(AVURLAsset *output, NSError *error) {
        if(!error){
            self.exportButton.enabled = YES;
            exportedVideoPlayerController = [[AVPlayerViewController alloc] init];
            exportedVideoPlayerController.player = [AVPlayer playerWithURL:output.URL];
            [self presentViewController:exportedVideoPlayerController animated:YES completion:nil];
        }else{
            NSLog(@"Unable to export video: %@", error);
        }
    }];
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
    [self playVideoAtURL:videoURL];
    didPickVideo = YES;
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}


@end
