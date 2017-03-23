/*
 * Copyright © 2016 Intel Corporation. All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "WGImageFilter.h"
#import "WGImageInput.h"
#import "WGImageOutput.h"
#import "GPUImageBeautifyFilter.h"

@implementation WGImageFilter{
  WGImageInput* input;
  WGImageOutput *output;
  GPUImageBeautifyFilter* filter;
  NSMutableArray* callbackQueue;
  NSUInteger imageCount;
}

-(instancetype)init{
  self=[super init];
  callbackQueue=[[NSMutableArray alloc]init];
  input=[[WGImageInput alloc]init];
  output=[[WGImageOutput alloc]initWithImageSize:CGSizeMake(480, 640) resultsInBGRAFormat:YES];
  __weak WGImageFilter* weakSelf=self;
  imageCount=0;
  [output setNewFrameAvailableBlock:^{
    //imageCount++;
    @synchronized (weakSelf) {
      if([callbackQueue count]==0){
        return;
      }
      void (^firstObject)(CVImageBufferRef) =[callbackQueue objectAtIndex:0];
      if(firstObject!=nil){
        [callbackQueue removeObjectAtIndex:0];
        [output lockFramebufferForReading];
        //GLubyte* byte=[output rawBytesForImage];
        CVImageBufferRef imageBuffer=[output pixelBufferForImage];
        //[output unlockFramebufferAfterReading];
        firstObject(imageBuffer);
        [output unlockFramebufferAfterReading];
        //CVBufferRelease(imageBuffer);
        /*
        if(imageCount%100==0){
          // Write image to file
          CIImage* ciImage=[CIImage imageWithCVPixelBuffer:imageBuffer];
          CIContext *temporyContext=[CIContext contextWithOptions:nil];
          CGImageRef videoImage=[temporyContext createCGImage:ciImage fromRect:CGRectMake(0, 0, 640, 480)];
          UIImage *uiImage=[[UIImage alloc]initWithCGImage:videoImage];
          UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil);
        }*/
      }
    }
  }];
  filter=[[GPUImageBeautifyFilter alloc]init];
  //filter.fractionalWidthOfAPixel=0.1;
  [input addTarget:filter];
  [filter addTarget:output];
  return self;
}

-(void)filterImage:(CVImageBufferRef)image onComplete:(void (^)(CVImageBufferRef))callback{
  [input newFrameReady:image];
  @synchronized (self) {
    [callbackQueue addObject:callback];
  }
}


@end
