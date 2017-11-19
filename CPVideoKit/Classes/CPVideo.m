//
//  CPVideo.m
//  CPVideoKit
//
//  Created by Can Poyrazoğlu on 17.11.2017.
//  Copyright © 2017 Can Poyrazoglu. All rights reserved.
//

#import "CPVideo.h"

static BOOL diagnostics;

@implementation CPVideo{
    AVAsset *asset;
    CPVideoExportOptions *exportOptions;
    NSURL *exportURL;
    CPVideoExportProgressHandler progressHandler;
    CPVideoCompletionHandler completionHandler;
}

+(void)enableDiagnostics{
    diagnostics = YES;
}

+(void)disableDiagnostics{
    diagnostics = NO;
}

-(instancetype)initWithAsset:(AVAsset *)asset{
    self = [super init];
    self->asset = asset;
    return self;
}

-(void)exportVideoAtURL:(NSURL*)url withOptions:(CPVideoExportOptions*)options progress:(CPVideoExportProgressHandler)progress completion:(CPVideoCompletionHandler)completion{
    NSAssert(url.isFileURL, @"Video URL must be a file URL.");
    NSAssert(options, @"Export options must be set.");
    exportURL = url;
    exportOptions = options;
    progressHandler = progress;
    completionHandler = completion;
    [self exportVideo];
}

-(CGRect)sanitizedCropAreaWithRect:(CGRect)inputRect{
    double x, y, width, height;
    x = inputRect.origin.x;
    y = inputRect.origin.y;
    width = inputRect.size.width;
    height = inputRect.size.height;
    if(x < 0.00001 && x > -0.00001){
        x = 0;
    }
    if(y < 0.00001 && y > -0.00001){
        y = 0;
    }
    if(width < 1.00001 && width > 0.99999){
        width = 1;
    }
    if(height < 1.00001 && height > 0.99999){
        height = 1;
    }
    return CGRectMake(x, y, width, height);
}

-(void)exportVideo{
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoCompositionWithPropertiesOfAsset:asset];
    AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    CGSize size = videoTrack.naturalSize;
    if(diagnostics){
        NSLog(@"Exporting video to %@...", exportURL.absoluteString);
        NSLog(@"%@", exportOptions);
        NSLog(@"Video track natural size: %dx%d", (int)videoTrack.naturalSize.width, (int)videoTrack.naturalSize.height);
        
    }
    CGAffineTransform matrix = CGAffineTransformIdentity;
    if(!CGAffineTransformIsIdentity(asset.preferredTransform)){
        if(diagnostics){
            NSLog(@"Asset has preferred transform.");
        }
        matrix = CGAffineTransformConcat(matrix, asset.preferredTransform);
    }
    if(!CGAffineTransformIsIdentity(videoTrack.preferredTransform)){
        if(diagnostics){
            NSLog(@"Video track has preferred transform.");
        }
        matrix = CGAffineTransformConcat(matrix, videoTrack.preferredTransform);
    }
    size = CGSizeApplyAffineTransform(size, matrix);
    if(exportOptions.normalizedCropArea.size.width && exportOptions.normalizedCropArea.size.height){
        CGRect cropArea = exportOptions.normalizedCropArea;
        cropArea = [self sanitizedCropAreaWithRect:cropArea];
        size = CGSizeMake(size.width * cropArea.size.width, size.height * cropArea.size.height);
        NSAssert(cropArea.origin.x >= 0, @"Crop area's left margin must be within the video frame.");
        NSAssert(cropArea.origin.y >= 0, @"Crop area's top margin must be within the video frame.");
        NSAssert(cropArea.origin.x + cropArea.size.width <= 1.00001, @"Crop area's right margin must be within the video frame.");
        NSAssert(cropArea.origin.y + cropArea.size.height <= 1.00001, @"Crop area's bottom margin must be within the video frame.");
        CGAffineTransform transform = CGAffineTransformIdentity;
        
        float scaleX = cropArea.size.width;
        float scaleY = cropArea.size.height;
        double rotation = atan2(matrix.b, matrix.d);
        CGPoint signum = CGPointMake(1, 1);
        if(fabs(rotation - M_PI_2) < 0.001){
            signum.x = -1;
        }
    
        transform = CGAffineTransformTranslate(transform, signum.x * -cropArea.origin.x * size.width / scaleX, signum.y * -cropArea.origin.y * size.height / scaleY);
        matrix = CGAffineTransformConcat(matrix, transform);
    }
    
    CGSize exportSize = CGSizeApplyAffineTransform(size, matrix);;
    exportSize = CGSizeMake((int)fabs(size.width), (int)fabs(size.height));
    if(diagnostics){
        NSLog(@"Transformed export size: %dx%d", (int)exportSize.width, (int)exportSize.height);
    }
    float scale = 1.0;
    if(exportOptions.maximumSize.width && exportOptions.maximumSize.height){
        float width = MIN(exportOptions.maximumSize.width, exportSize.width);
        float height = MIN(exportOptions.maximumSize.height, exportSize.height);
        scale = MIN(scale, width / exportSize.width);
        scale = MIN(scale, height / exportSize.height);
        CGAffineTransform scaleTransform = CGAffineTransformMakeScale(scale, scale);
        matrix = CGAffineTransformConcat(matrix, scaleTransform);
    }
    exportSize = CGSizeMake(exportSize.width * scale, exportSize.height * scale);
    //lock the export size to a multiple of 4 to avoid green banding at right and bottom
    double widthMod4 = fmod(exportSize.width, 4);
    if(widthMod4){
        if(widthMod4 > 2){
            exportSize.width += widthMod4;
        }else{
            exportSize.width -= widthMod4;
        }
    }
    double heightMod4 = fmod(exportSize.height, 4);
    if(heightMod4){
        if(heightMod4 > 2){
            exportSize.height += heightMod4;
        }else{
            exportSize.height -= heightMod4;
        }
    }
    NSAssert(exportSize.width && exportSize.height, @"Exported video size must be positive after applying transformations.");
    if(diagnostics){
        NSLog(@"Scaled export size: %dx%d", (int)exportSize.width, (int)exportSize.height);
    }
    videoComposition.renderSize = exportSize;
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    AVMutableVideoCompositionLayerInstruction *transformInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    instruction.timeRange = videoTrack.timeRange;
    [transformInstruction setTransform:matrix atTime:kCMTimeZero];
    instruction.layerInstructions = @[ transformInstruction ];
    videoComposition.instructions = @[ instruction ];
    [[NSFileManager defaultManager] removeItemAtURL:exportURL error:nil];
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:exportOptions.exportPresetQuality];
    exportSession.outputURL = exportURL;
    exportSession.outputFileType = exportOptions.fileType;
    exportSession.videoComposition = videoComposition;
    exportSession.shouldOptimizeForNetworkUse = exportOptions.shouldOptimizeForNetworkUse;
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if(exportSession.status == AVAssetExportSessionStatusCompleted){
            AVURLAsset *newAsset = [AVURLAsset assetWithURL:exportURL];
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(newAsset, nil);
            });
        }else if(exportSession.status == AVAssetExportSessionStatusFailed || exportSession.status == AVAssetExportSessionStatusCancelled){
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nil, exportSession.error);
            });
        }
    }];
    if(progressHandler){
        [self handleExportProgressUpdate:exportSession];
    }
}

-(void)handleExportProgressUpdate:(AVAssetExportSession*)exportSession{
    progressHandler(exportSession.progress);
    if(exportSession.progress < 0.999){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self handleExportProgressUpdate:exportSession];
        });
    }
}

+(CGRect)normalizedVideoFrame:(CGRect)videoFrame relativeToCropRectangle:(CGRect)cropFrame{
    CGRect relativeVideoFrame = [self videoFrame:videoFrame relativeToCropRectangle:cropFrame];
    CGRect normalizedFrame = [self normalizedRect:relativeVideoFrame againstVideoViewSize:videoFrame.size];
    return normalizedFrame;
}

+(CGRect)videoFrame:(CGRect)videoFrame relativeToCropRectangle:(CGRect)cropFrame{
    CGRect absoluteUnion = CGRectUnion(videoFrame, cropFrame);
    CGRect absoluteIntersection = CGRectIntersection(videoFrame, cropFrame);
    CGRect result = CGRectMake(
                               -(absoluteUnion.origin.x - cropFrame.origin.x),
                               -(absoluteUnion.origin.y - cropFrame.origin.y),
                               absoluteIntersection.size.width,
                               absoluteIntersection.size.height
                               );
    return result;
}


+(CGRect)normalizedRect:(CGRect)inputRect againstVideoViewSize:(CGSize)videoViewSize{
    return CGRectMake(inputRect.origin.x / videoViewSize.width,
                      inputRect.origin.y / videoViewSize.height,
                      inputRect.size.width / videoViewSize.width,
                      inputRect.size.height / videoViewSize.height);
}

@end
