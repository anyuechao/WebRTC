/*
 * Copyright © 2017 Intel Corporation. All Rights Reserved.
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
#import "StreamView.h"

@implementation StreamView{
  UILabel* statsLabel;
  BOOL isStatsLabelVisiable;
}

-(instancetype)initWithFrame:(CGRect)frame{

  if(self=[super initWithFrame:frame]){
    self.backgroundColor=[UIColor whiteColor];

    _remoteVideoView = [[RTCEAGLVideoView alloc]init];
    _localVideoView=[[RTCEAGLVideoView alloc] init];
    _quitBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _act=[[UIActivityIndicatorView  alloc] init];
    [_act startAnimating];
    statsLabel=[[UILabel alloc]init];
    isStatsLabelVisiable=NO;

    [_quitBtn addTarget:self action:@selector(onQuitBtnDown:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_remoteVideoView];
//    [self addSubview:_localVideoView];
    [self addSubview:_quitBtn];
    [self addSubview:_act];
  }
  return self;
}

-(void)layoutSubviews{

  screenSize =  [UIScreen mainScreen].bounds;

  // local view
  CGRect localVideoViewFrame=CGRectZero;
  localVideoViewFrame.origin.x = 0;
  localVideoViewFrame.origin.y = 0;
  localVideoViewFrame.size.width = screenSize.size.width / 4.0;
  localVideoViewFrame.size.height = screenSize.size.height / 4.0;
  _localVideoView.frame=localVideoViewFrame;
  _localVideoView.layer.borderColor = [UIColor yellowColor].CGColor;
  _localVideoView.layer.borderWidth = 2.0f;

  // remote view
  CGRect remoteVideoViewFrame=CGRectZero;
  remoteVideoViewFrame.origin.x = screenSize.size.width / 4.0;
  remoteVideoViewFrame.origin.y = 0;
  remoteVideoViewFrame.size.width = screenSize.size.width * 3.0 / 4.0-4.0;  // -4.0 for border
  remoteVideoViewFrame.size.height = screenSize.size.height-4.0;
  _remoteVideoView.frame=remoteVideoViewFrame;
  _remoteVideoView.layer.borderColor = [UIColor whiteColor].CGColor;
  _remoteVideoView.layer.borderWidth = 2.0f;

  // quitBtn
  [_quitBtn setTitle:@"Stop" forState:UIControlStateNormal];
  _quitBtn.frame = CGRectMake(0, screenSize.size.height / 2.0, screenSize.size.width / 4.0, screenSize.size.height / 8.0);
  _quitBtn.layer.backgroundColor = GetColorFromHex(0xefff6666).CGColor;

  // indicater
  float actSize = screenSize.size.width / 10.0;
  _act.frame = CGRectMake(screenSize.size.width * 5.0 / 8.0 - actSize, screenSize.size.height / 2.0 - actSize, 2 * actSize, 2 * actSize);
  _act.activityIndicatorViewStyle=UIActivityIndicatorViewStyleWhiteLarge;
  //  self.act.color = [UIColor redColor];
  _act.hidesWhenStopped = YES;

  // Stats label
  CGRect statsLabelFrame=CGRectMake(screenSize.size.width-140, 0, 140, 100);
  statsLabel.frame=statsLabelFrame;
  statsLabel.backgroundColor=[[UIColor whiteColor] colorWithAlphaComponent:0.2f];
  statsLabel.textColor=[UIColor blackColor];
  statsLabel.font=[statsLabel.font fontWithSize:12];
  statsLabel.lineBreakMode=NSLineBreakByWordWrapping;
  statsLabel.numberOfLines=0;
}

-(void)setStats:(NSString *)stats{
  if([stats length]==0&&isStatsLabelVisiable){
    [statsLabel removeFromSuperview];
  } else if([stats length]!=0&&!isStatsLabelVisiable){
    [self addSubview:statsLabel];
  }
  statsLabel.text=stats;
}


- (void) onQuitBtnDown: (id) sender {
  [_delegate quitBtnDidTouchedDown:self];
}

@end
