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

@implementation StreamView

-(instancetype)initWithFrame:(CGRect)frame{

  if(self=[super initWithFrame:frame]){
    self.backgroundColor=[UIColor whiteColor];
    _remoteVideoView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectZero];;
    _localVideoView=[[RTCEAGLVideoView alloc] initWithFrame:CGRectZero];
    _acceptBtn=[UIButton buttonWithType:UIButtonTypeCustom];
    _denyBtn=[UIButton buttonWithType:UIButtonTypeCustom];
    _localStreamBtn = [[UIButton alloc] init];
    [_acceptBtn addTarget:self action:@selector(onAcceptBtnDown:) forControlEvents:UIControlEventTouchDown];
    [_denyBtn addTarget:self action:@selector(onDenyBtnDown:) forControlEvents:UIControlEventTouchDown];
    [_localStreamBtn addTarget:self action:@selector(onLocalStreamBtnDown:) forControlEvents:UIControlEventTouchDown];
    
    [self addSubview:_remoteVideoView];
    [self addSubview:_localVideoView];
    [self addSubview:_acceptBtn];
    [self addSubview:_denyBtn];
  }
  return self;
}

-(void)layoutSubviews{

  screenSize =  [UIScreen mainScreen].bounds;

  // localVideo
  CGRect localVideoViewFrame=CGRectZero;
  localVideoViewFrame.origin.x = screenSize.size.width / 12.0;
  localVideoViewFrame.origin.y = screenSize.size.height * 2.0 / 3.0;
  localVideoViewFrame.size.width = screenSize.size.width / 3.0;
  localVideoViewFrame.size.height = screenSize.size.height / 4.0;
  _localVideoView.frame=localVideoViewFrame;

  _localVideoView.layer.borderColor = [UIColor yellowColor].CGColor;
  _localVideoView.layer.borderWidth = 2.0;

  // remoteVideo
  CGRect remoteVideoViewFrame=CGRectZero;
  remoteVideoViewFrame.origin.x = 0;
  remoteVideoViewFrame.origin.y = 0;
  remoteVideoViewFrame.size.width = screenSize.size.width;
  remoteVideoViewFrame.size.height = screenSize.size.height;
  _remoteVideoView.frame=remoteVideoViewFrame;
  _remoteVideoView.layer.borderColor = [UIColor whiteColor].CGColor;
  _remoteVideoView.layer.borderWidth = 2.0;


  // acceptBtn
  [_acceptBtn setTitle:@"√" forState:UIControlStateNormal];
  [_acceptBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  _acceptBtn.titleLabel.font = [UIFont systemFontOfSize:30];
  CGRect acceptBtnFrame=CGRectZero;
  acceptBtnFrame.origin.x = screenSize.size.width / 2.0;
  acceptBtnFrame.origin.y = screenSize.size.height * 2.0 / 3.0;
  acceptBtnFrame.size.width = screenSize.size.width / 5;
  acceptBtnFrame.size.height = screenSize.size.width / 5;
  _acceptBtn.frame = acceptBtnFrame;
  _acceptBtn.layer.cornerRadius = screenSize.size.width / 10;
  [_acceptBtn setBackgroundColor:[UIColor greenColor]];

  // denyBtn
  [_denyBtn setTitle:@"X" forState:UIControlStateNormal];
  [_denyBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  _denyBtn.titleLabel.font = [UIFont systemFontOfSize:30];
  CGRect denyBtnFrame=CGRectZero;
  denyBtnFrame.origin.x = screenSize.size.width * 11.0 / 12.0 - screenSize.size.width / 5;
  denyBtnFrame.origin.y = screenSize.size.height * 11.0 / 12.0 - screenSize.size.width / 5;
  denyBtnFrame.size.width = screenSize.size.width / 5;
  denyBtnFrame.size.height = screenSize.size.width / 5;
  _denyBtn.frame=denyBtnFrame;
  _denyBtn.layer.cornerRadius = screenSize.size.width / 10;
  [_denyBtn setBackgroundColor:[UIColor redColor]];


  // localStreamBtn
  [_localStreamBtn setTitle:@"lStream" forState:UIControlStateNormal];
  [_localStreamBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
  CGRect localStreamBtnFrame=CGRectZero;
  localStreamBtnFrame.origin.x = 0;
  localStreamBtnFrame.origin.y = screenSize.size.height / 2.0;
  localStreamBtnFrame.size.width = 100;
  localStreamBtnFrame.size.height = screenSize.size.height / 8.0 ;
  _localStreamBtn.frame=localStreamBtnFrame;

}

-(void)onAcceptBtnDown:(id)sender{
  [_delegate acceptBtnDidTouchedDown:self];
}

-(void)onDenyBtnDown:(id)sender{
  [_delegate denyBtnDidTouchedDown:self];
}

- (void) onLocalStreamBtnDown:(id) sender {
  [_delegate localStreamBtnDidTouchedDown:self];
}

@end
