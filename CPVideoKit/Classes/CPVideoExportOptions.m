//
//  CPVideoExportOptions.m
//  CPVideoKit
//
//  Created by Can Poyrazoğlu on 17.11.2017.
//  Copyright © 2017 Can Poyrazoglu. All rights reserved.
//

@import ImageIO;

#import "CPVideoExportOptions.h"

@implementation CPVideoExportOptions

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.fileType = AVFileTypeQuickTimeMovie;
        self.shouldOptimizeForNetworkUse = YES;
        if(@available(iOS 11, *)){
            NSArray<NSString *> *supportedImageDestinationTypes = CFBridgingRelease(
                                                           CGImageDestinationCopyTypeIdentifiers());
            BOOL supportsHEVC = [supportedImageDestinationTypes containsObject:AVFileTypeHEIC];
            if(supportsHEVC){
                self.exportPresetQuality = AVAssetExportPresetHEVCHighestQuality;
            }else{
                self.exportPresetQuality = AVAssetExportPresetHighestQuality;
            }
        }else{
            self.exportPresetQuality = AVAssetExportPresetHighestQuality;
        }
       
    }
    return self;
}

-(NSString *)description{
    NSMutableString *str = @"Export Options:\n".mutableCopy;
    if(self.maximumSize.width && self.maximumSize.height){
        [str appendFormat:@"Maximum size: %dx%d\n", (int)self.maximumSize.width, (int)self.maximumSize.height];
    }
    if(self.normalizedCropArea.size.width && self.normalizedCropArea.size.height){
         [str appendFormat:@"Crop area: (%.3f, %.3f), (%.3f, %.3f))\n",
          self.normalizedCropArea.origin.x,
          self.normalizedCropArea.origin.y,
          self.normalizedCropArea.size.width,
          self.normalizedCropArea.size.height
          ];
    }
    [str appendFormat:@"File type UTI: %@\n", self.fileType];
    [str appendFormat:@"Should optimize for streaming: %@\n", self.shouldOptimizeForNetworkUse ? @"yes" : @"no"];
    [str appendFormat:@"Export quality preset: %@\n", self.exportPresetQuality];
    
    return str.copy;
}

@end
