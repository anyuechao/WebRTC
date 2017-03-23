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

#import <AVFoundation/AVFoundation.h>
#import <Woogeen/Woogeen.h>
#import "StreamViewController.h"
#import "StreamView.h"

@interface StreamViewController () <StreamViewDelegate>

@property(nonatomic, retain) RTCLocalCameraStream* localStream;
@property(nonatomic, retain) RTCPeerClient* peerClient;

@end

@implementation StreamViewController

- (void)showMsg: (NSString *)msg
{
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
  [alert show];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNotification:) name:nil object:nil];

  while ([appDelegate.infos count] > 0) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"OnStreamAdded" object:appDelegate userInfo:appDelegate.infos[[appDelegate.infos count] - 1]];
    [appDelegate.infos removeLastObject];
  }

  NSLog(@"Stream view did load.");
  _peerClient=[appDelegate peerClient];
  _isChatting = NO;

#if TARGET_IPHONE_SIMULATOR
  NSLog(@"Camera is not supported on simulator.");
  RTCLocalCameraStreamParameters* parameters=[[RTCLocalCameraStreamParameters alloc]initWithVideoEnabled:NO audioEnabled:YES];
  _localStream=[[RTCLocalCameraStream alloc]initWithParameters:parameters];
#else
  [self attachLocal];
#endif

  NSNotificationCenter* nc=[NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(routeChange:) name:AVAudioSessionRouteChangeNotification object:nil];

}

-(void)routeChange:(NSNotification*)notification{
  [[AVAudioSession sharedInstance]overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
}

- (void) viewDidDisappear:(BOOL)animated {
  NSLog(@"disappearing");
  [super viewDidDisappear:animated];
  _localStream = nil;
}

-(void)viewDidAppear:(BOOL)animated{
  [super viewDidAppear:animated];
  if (!_isCaller) {
    _status.text = [[NSString alloc] initWithFormat:@"%@ invites you, please reply...", appDelegate.remoteUserId];
  } else {
    _status.text = @"Waiting for remote user...";
  }

  _status.textAlignment = NSTextAlignmentCenter;
  _status.textColor = [UIColor whiteColor];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

-(void)loadView{
  [super loadView];

  appDelegate = (AppDelegate*)[[UIApplication sharedApplication]delegate];
  _streamView=[[StreamView alloc]init];
  _streamView.delegate=self;
  _status = [[UILabel alloc]init];
  _status.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height / 30.0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height / 30.0);
  [_streamView addSubview:_status];
  self.view=_streamView;

}


-(void)acceptBtnDidTouchedDown:(StreamView *)view{
  [_peerClient accept:appDelegate.remoteUserId onSuccess:^{
    NSLog(@"Accept success.");
    _isChatting=YES;
  }onFailure:^(NSError *err) {
    NSLog(@"Accept failed.");
  }];
}



- (void)denyBtnDidTouchedDown:(StreamView *)view {
  if (_isChatting||_isCaller) {
    [_peerClient stop:appDelegate.remoteUserId onSuccess:^{
      NSLog(@"Send stop success.");
    }onFailure:^(NSError *err){
      NSLog(@"Stop failed. %@", [err localizedDescription]);
    }];
  } else {
    NSLog(@"Deny invitation.");
    [_peerClient deny:appDelegate.remoteUserId onSuccess:^{
      dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier: @"Back" sender: self];
      });
    } onFailure:nil];
  }
}

- (void) onDenied:(NSString *)remoteUserId {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self performSegueWithIdentifier: @"Back" sender: self];
  });
}

-(void)onAccepted:(NSString *)remoteUserId {
}

- (void) onStarted:(NSString *) remoteUserId{
  _isChatting = YES;
  dispatch_async(dispatch_get_main_queue(), ^{
    [_peerClient publish:_localStream to:appDelegate.remoteUserId onSuccess:nil onFailure:^(NSError *err) {
      NSLog(@"%@", [err localizedFailureReason]);
    }];
    _status.text = @"Now chatting...";
  });
}

- (void) onStopped:(NSString *)remoteUserId {
  _isChatting = NO;
  dispatch_async(dispatch_get_main_queue(), ^{
    [self performSegueWithIdentifier: @"Back" sender: self];
  });
}

- (void) attachLocal {
  if(_localStream==nil){
    RTCLocalCameraStreamParameters* parameters=[[RTCLocalCameraStreamParameters alloc]initWithVideoEnabled:YES audioEnabled:YES];
    [parameters setResolutionWidth:352 height:288];
    NSString* cameraId=nil;
    for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]){
      if (device.position==AVCaptureDevicePositionBack){
        cameraId=[device uniqueID];
      }
    }
    NSAssert(cameraId, @"Unable to get the front camera id");
    NSLog(@"Camera ID: %@",cameraId);
    [parameters setCameraId:cameraId];
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      NSError* streamError;
      _localStream=[[RTCLocalCameraStream alloc]initWithParameters:parameters error:&streamError];
      if(streamError!=nil){
        NSLog(@"Create stream failed. %@",[streamError localizedDescription]);
      }else{
        [_localStream attach:_streamView.localVideoView];
      }
      NSLog(@"attach");
    });
  }
}

-(void)onNotification:(NSNotification *)notification{
  if([notification.name isEqualToString:@"OnStreamAdded"]){
    NSDictionary* userInfo = notification.userInfo;
    RTCRemoteStream* stream = userInfo[@"stream"];
    [self onRemoteStreamAdded:stream];
  } else if ([notification.name isEqualToString:@"OnAccepted"]) {
    NSDictionary* userInfo = notification.userInfo;
    NSString *remoteUserId = userInfo[@"remoteUserId"];
    [self onAccepted:remoteUserId];
  } else if ([notification.name isEqualToString:@"OnDenied"]) {
    NSDictionary* userInfo = notification.userInfo;
    NSString *remoteUserId = userInfo[@"remoteUserId"];
    [self onDenied:remoteUserId];
  } else if ([notification.name isEqualToString:@"OnStarted"]) {
    NSDictionary* userInfo = notification.userInfo;
    NSString *remoteUserId = userInfo[@"remoteUserId"];
    [self onStarted:remoteUserId];
  } else if ([notification.name isEqualToString:@"OnStopped"]) {
    NSDictionary* userInfo = notification.userInfo;
    NSString *remoteUserId = userInfo[@"remoteUserId"];
    [self onStopped:remoteUserId];
  }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  HorizontalSegue *s = (HorizontalSegue *)segue;
  s.isDismiss = YES;
  s.isLandscapeOrientation = NO;
}

-(void)onRemoteStreamAdded:(RTCRemoteStream*)remoteStream{
  if([remoteStream isKindOfClass:[RTCRemoteScreenStream class]]){
    NSLog(@"Screen stream added.");
  }
  else if ([remoteStream isKindOfClass:[RTCRemoteCameraStream class]]){
    NSLog(@"Camera stream added.");
  }
  [remoteStream attach:_streamView.remoteVideoView];
}

-(void)onRemoteStreamRemoved:(RTCRemoteStream*)remoteStream{
}

@end
