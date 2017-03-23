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

#import <Foundation/Foundation.h>
#import "WGImageInput.h"

@implementation WGImageInput

- (void)updateTargetsForVideoCameraUsingCacheTextureAtWidth:(int)bufferWidth height:(int)bufferHeight time:(CMTime)currentTime;
{
  // First, update all the framebuffers in the targets
  for (id<GPUImageInput> currentTarget in targets)
  {
    if ([currentTarget enabled])
    {
      NSInteger indexOfObject = [targets indexOfObject:currentTarget];
      NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
      
      if (currentTarget != self.targetToIgnoreForUpdates)
      {
        [currentTarget setInputRotation:0 atIndex:textureIndexOfTarget];
        [currentTarget setInputSize:CGSizeMake(bufferWidth, bufferHeight) atIndex:textureIndexOfTarget];
        
        if ([currentTarget wantsMonochromeInput])
        {
          [currentTarget setCurrentlyReceivingMonochromeInput:YES];
          // TODO: Replace optimization for monochrome output
          [currentTarget setInputFramebuffer:outputFramebuffer atIndex:textureIndexOfTarget];
        }
        else
        {
          [currentTarget setCurrentlyReceivingMonochromeInput:NO];
          [currentTarget setInputFramebuffer:outputFramebuffer atIndex:textureIndexOfTarget];
        }
      }
      else
      {
        [currentTarget setInputRotation:0 atIndex:textureIndexOfTarget];
        [currentTarget setInputFramebuffer:outputFramebuffer atIndex:textureIndexOfTarget];
      }
    }
  }
  
  // Then release our hold on the local framebuffer to send it back to the cache as soon as it's no longer needed
  [outputFramebuffer unlock];
  outputFramebuffer = nil;
  
  // Finally, trigger rendering as needed
  for (id<GPUImageInput> currentTarget in targets)
  {
    if ([currentTarget enabled])
    {
      NSInteger indexOfObject = [targets indexOfObject:currentTarget];
      NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
      
      if (currentTarget != self.targetToIgnoreForUpdates)
      {
        [currentTarget newFrameReadyAtTime:currentTime atIndex:textureIndexOfTarget];
      }
    }
  }
}

-(void)newFrameReady:(CVImageBufferRef)image{
  int bufferWidth = (int) CVPixelBufferGetWidth(image);
  int bufferHeight = (int) CVPixelBufferGetHeight(image);
  CVPixelBufferLockBaseAddress(image, 0);
  
  int bytesPerRow = (int) CVPixelBufferGetBytesPerRow(image);
  outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:CGSizeMake(bytesPerRow / 4, bufferHeight) onlyTexture:YES];
  [outputFramebuffer activateFramebuffer];
  
  glBindTexture(GL_TEXTURE_2D, [outputFramebuffer texture]);
  
  //        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bufferWidth, bufferHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(cameraFrame));
  
  // Using BGRA extension to pull in video frame data directly
  // The use of bytesPerRow / 4 accounts for a display glitch present in preview video frames when using the photo preset on the camera
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bytesPerRow / 4, bufferHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(image));
  
  [self updateTargetsForVideoCameraUsingCacheTextureAtWidth:bytesPerRow / 4 height:bufferHeight time:CMTimeMake(0,0)];
  
  CVPixelBufferUnlockBaseAddress(image, 0);
}

@end