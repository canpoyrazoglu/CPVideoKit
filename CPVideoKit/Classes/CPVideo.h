//
//  CPVideo.h
//  CPVideoKit
//
//  Created by Can Poyrazoğlu on 17.11.2017.
//  Copyright © 2017 Can Poyrazoglu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "CPVideoExportOptions.h"

typedef void (^CPVideoCompletionHandler)(AVURLAsset *output, NSError *error);
typedef void (^CPVideoExportProgressHandler)(float progress);

@interface CPVideo : NSObject

+(void)enableDiagnostics;
+(void)disableDiagnostics;

/** Creates a @c CPVideo object with a video to be cropped. */
-(instancetype)initWithAsset:(AVAsset*)asset;

/** Calculates the video's crop area of interest, intersecting with the cropping area, ready to be used for the crop area in video export options.
 @note
 Video frame and the crop area should be in the same coordinate system (e.g. same superview), otherwise the frame may be returned incorrectly.
 @returns
 Crop area of interest, with normalized coordinates and dimensions between 0 and 1, with X,Y = 0 meaning Left/Top of the frame, and Width,Height = 1 meaning full video width or height.
 */
+(CGRect)normalizedVideoFrame:(CGRect)videoFrame relativeToCropRectangle:(CGRect)cropFrame;

/** Exports a video at the destination
 @param url
 A URL pointing to a file. The directory must be writable. If file already exists, it will be overwritten.
 @param options
 Options for exporting the video.
 */
-(void)exportVideoAtURL:(NSURL*)url withOptions:(CPVideoExportOptions*)options progress:(CPVideoExportProgressHandler)progress completion:(CPVideoCompletionHandler)completion;



@end
