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
#import "ConferenceStreamViewController.h"
#import "HorizontalSegue.h"
//#import "FileVideoFrameGenerator.h"

@interface ConferenceStreamViewController () <StreamViewDelegate, RTCRemoteMixedStreamObserver>


@property(strong, nonatomic) RTCRemoteStream* remoteStream;
@property(strong, nonatomic) RTCConferenceClient* conferenceClient;


@end

@implementation ConferenceStreamViewController{
  NSTimer* getStatsTimer;
  RTCAVFoundationVideoSource* _source;
}

- (void)showMsg: (NSString *)msg
{
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:msg preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
  [alertController addAction:okAction];
  [self presentViewController:alertController animated:YES completion:nil];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor clearColor];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNotification:) name:nil object:nil];
  [self doPublish];
}


-(void)loadView {
  [super loadView];
  
  _streamView=[[StreamView alloc]init];
  _streamView.delegate=self;
  
  self.view= _streamView;
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  [getStatsTimer invalidate];
  getStatsTimer = nil;
  _conferenceClient = nil;
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self.view removeFromSuperview];
}

- (void)enableFrameFilter{
  //WGImageFilter* filter=[[WGImageFilter alloc]init];
  // _source is an RTCAVFoundationVideoSource instance. This function can be enabled only when RTCLocalCameraStream is created with RTCAVFoundationVideoSource.
  //[_source setFilter:filter];
  NSLog(@"Enable filter.");
}

- (void)quitConference{
  dispatch_async(dispatch_get_main_queue(), ^{
    self.localStream = nil;
    [self performSegueWithIdentifier:@"Back" sender:self];
  });
}

- (void) quitBtnDidTouchedDown:(StreamView *)view {
  [self.conferenceClient leaveWithOnSuccess:^{
    [self quitConference];
  } onFailure:^(NSError* err){
    [self quitConference];
    NSLog(@"Failed to leave. %@",err);
  }];
}

-(void)onNotification:(NSNotification *)notification{
  //  NSLog(@"On notification.");
  if([notification.name isEqualToString:@"OnStreamAdded"]){
    NSDictionary* userInfo=notification.userInfo;
    RTCRemoteStream* stream =userInfo[@"stream"];
    NSLog(@"New stream add from %@",[stream getRemoteUserId]);
    [self onRemoteStreamAdded:stream];
  }
}

-(void)onRemoteStreamAdded:(RTCRemoteStream*)remoteStream{
  NSLog(@"On remote stream added.");
}

-(void)doPublish{
  
  [self.conferenceClient publish:self.localStream onSuccess:^() {
    dispatch_async(dispatch_get_main_queue(), ^{
      NSLog(@"publish success!");
    });
  } onFailure:^(NSError* err) {
    NSLog(@"publish failure!");
    [self showMsg:[err localizedFailureReason]];
  }];
  
  RTCConferenceSubscribeOptions *subOption = [[RTCConferenceSubscribeOptions alloc]init];
  int width = INT_MAX;
  int height = INT_MAX;
  NSArray *formats = [appDelegate.mixedStream supportedVideoFormats];
  for (RTCVideoFormat* format in formats) {
    if (format.resolution.width == 1280 && format.resolution.height == 720) {
      width = format.resolution.width;
      height = format.resolution.height;
      break;
    }
    if (format.resolution.width < width && format.resolution.height != 0) {
      width = format.resolution.width;
      height = format.resolution.height;
    }
  }
  subOption.videoQualityLevel = RTCConferenceVideoQualityLevelBestQuality;
  [subOption setResolution:CGSizeMake(width, height)];
  [[AVAudioSession sharedInstance]overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
  [self.conferenceClient subscribe:appDelegate.mixedStream withOptions:subOption onSuccess:^(RTCRemoteStream *remoteStream) {
    
    getStatsTimer=[NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(printStats) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:getStatsTimer forMode:NSDefaultRunLoopMode];
    dispatch_async(dispatch_get_main_queue(), ^{
      _remoteStream=remoteStream;
      NSLog(@"Subscribe stream success.");
      [remoteStream attach:((StreamView *)self.view).remoteVideoView];
      [self.streamView.act stopAnimating];
    });
  } onFailure:^(NSError* err){
    NSLog(@"Subscribe stream failed. %@", [err localizedDescription]);
  }];
}

-(void)printStats{
  [self.conferenceClient getConnectionStatsForStream:appDelegate.mixedStream onSuccess:^(RTCConnectionStats *stats) {
    dispatch_async(dispatch_get_main_queue(), ^{
      NSMutableString* statsString=[NSMutableString stringWithFormat:@"Mixed stream info:\nAvaiable: %lukbps\n",(unsigned long)stats.videoBandwidthStats.availableReceiveBandwidth/1024];
      for(id channel in stats.mediaChannelStats){
        if([channel isKindOfClass:[RTCVideoReceiverStats class]]){
          RTCVideoReceiverStats* videoReceiverStats=channel;
          NSMutableString *channelStats=[NSMutableString stringWithFormat:@"Packets lost: %lu\nResolution: %dx%d\nDelay: %lu\nVideo Codec: %@\n", (unsigned long)videoReceiverStats.packetsLost,(unsigned int)videoReceiverStats.frameResolution.width,(unsigned int)videoReceiverStats.frameResolution.height,  (unsigned long)videoReceiverStats.delay, videoReceiverStats.codecName];
          [statsString appendString:channelStats];
        }
      }
      self.streamView.stats=statsString;
    });
  } onFailure:^(NSError *e) {
    dispatch_async(dispatch_get_main_queue(), ^{
      self.streamView.stats=@"";
    });
  }];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  HorizontalSegue *s = (HorizontalSegue *)segue;
  s.isDismiss = YES;
}

-(void)onVideoLayoutChanged{
  NSLog(@"OnVideoLayoutChanged.");
}

//本地播放流
- (RTCLocalStream *)localStream{
  
  if (!_localStream){
#if TARGET_IPHONE_SIMULATOR
    NSLog(@"Camera is not supported on simulator");
    RTCLocalCameraStreamParameters* parameters=[[RTCLocalCameraStreamParameters alloc]initWithVideoEnabled:NO audioEnabled:YES];
#else
    /* Create LocalCameraStream with parameters */
    RTCLocalCameraStreamParameters* parameters=[[RTCLocalCameraStreamParameters alloc]initWithVideoEnabled:YES audioEnabled:YES];
    NSString* cameraId=nil;
    for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]){
      if (device.position==AVCaptureDevicePositionFront){
        cameraId=[device localizedName];
        NSLog(@"Supported resolution: %@", device.formats);
      }
    }
    NSAssert(cameraId, @"Unable to get the front camera id");
    NSLog(@"Camera ID: %@",cameraId);
    [parameters setCameraId:cameraId];
//    [parameters setResolutionWidth:1280 height:720];
        [parameters setResolutionWidth:640 height:480];
    /* Create LocalCameraStream with capturer instance */
    /*
     NSDictionary *mandatoryConstraints = @{@"minWidth" : @"1920", @"minHeight" : @"1080",@"maxWidth" : @"1920", @"maxHeight" : @"1080", @"maxFrameRate":@"24", @"minFrameRate":@"15"};
     
     RTCMediaConstraints* constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatoryConstraints optionalConstraints:nil];
     //     RTCMediaConstraints* constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:nil];
     RTCAVFoundationVideoSource* source=[[RTCAVFoundationVideoSource alloc] initWithConstraints:constraints];
     source.useBackCamera=YES;
     _source=source;
     */
#endif
    NSError *err=[[NSError alloc]init];
    //    _localStream=[[RTCLocalCameraStream alloc]initWithAudioEnabled:YES VideoSource:source error: &err];
    _localStream=[[RTCLocalCameraStream alloc]initWithParameters:parameters error:&err];
    // Customized video input sample
    /*
     RTCLocalCustomizedStreamParameters* parameters=[[RTCLocalCustomizedStreamParameters alloc]initWithVideoEnabled:YES audioEnabled:YES];
     NSString* path=[[NSBundle mainBundle]pathForResource:@"foreman_cif_short" ofType:@"yuv"];
     FileVideoFrameGenerator* generator=[[FileVideoFrameGenerator alloc]initWithPath:path resolution:CGSizeMake(352, 288) frameRate:30];
     [parameters setVideoFrameGenerator:generator];
     _localStream=[[RTCLocalCustomizedStream alloc]initWithParameters:parameters];*/
#if TARGET_IPHONE_SIMULATOR
    NSLog(@"Stream does not have video track.");
#else
    [_localStream attach:((StreamView *)self.view).localVideoView];
#endif
    
  }
  return _localStream;
  
}

//应用程序的异步类，用于与MCU中的会议通信。
- (RTCConferenceClient *)conferenceClient {
  
  if (!_conferenceClient){
    appDelegate = (AppDelegate*)[[UIApplication sharedApplication]delegate];
    _conferenceClient=[appDelegate conferenceClient];
    
  }
  return _conferenceClient;
}

@end
