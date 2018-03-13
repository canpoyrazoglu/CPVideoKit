//
//  CPVideoExportOptions.h
//  CPVideoKit
//
//  Created by Can Poyrazoğlu on 17.11.2017.
//  Copyright © 2017 Can Poyrazoglu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AVFoundation/AVFoundation.h>

@interface CPVideoExportOptions : NSObject

/** Maximum size, in pixels, for export. Actual size may be smaller due to input video size and aspect ratio. This is the upper limit for the video. If the video is smaller, it will not be upscaled.
 @note
 If any of width or height for this property is zero, maximum size will be ignored and the result video will have the raw size after cropping (if any).
 */
@property CGSize maximumSize;

/** Area for cropping, normalized against the width and height of the video. For example, to cover the full video frame, this may be the unit rectangle (x = 0, y = 0, width = 1, height = 1). To crop only the left half of the video, this property should be set to (x = 0, y = 0, width = 0.5, height = 1) and so on.
 @note
 This parameter will be omitted if the rectangle doesn't contain a positive width and height.  */
@property CGRect normalizedCropArea;

/** File type to export the video. Default is @c AVFileTypeQuickTimeMovie. */
@property AVFileType fileType;
 
/** Should the video be optimized for streaming by writing metadata required to start playback in front of the file. Default is @c YES. */
@property BOOL shouldOptimizeForNetworkUse;

/** Quality preset for exporting the video. Default is @c AVAssetExportPresetHighestQuality on versions prior to iOS 11. On iPhone 7 and later devices running iOS 11 and above which supports HEVC, the default is @c AVAssetExportPresetHEVCHighestQuality. */
@property NSString *exportPresetQuality;

@end
