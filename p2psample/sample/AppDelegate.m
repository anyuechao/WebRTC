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

#import "AppDelegate.h"
#import "SocketSignalingChannel.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  _infos = [[NSMutableArray alloc]init];
  _connecters = [[NSMutableArray alloc] init];
  [self.window setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"login.jpg"]]];
    // Override point for customization after application launch.
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  [_infos dealloc];
  [_connecters dealloc];
}

- (RTCPeerClient*)peerClient{
  if (_peerClient==nil){
    id<RTCP2PSignalingChannelProtocol> scc=[[SocketSignalingChannel alloc]init];
    RTCPeerClientConfiguration* config=[[RTCPeerClientConfiguration alloc]init];
    NSArray *ice=[[NSArray alloc]initWithObjects:[[RTCIceServer alloc]initWithURLStrings:[[NSArray alloc]initWithObjects:@"stun:example.com", nil]], nil];
    config.ICEServers=ice;
    config.mediaCodec.videoCodec=VideoCodecH264;
    config.candidateNetworkPolicy=RTCCandidateNetworkPolicyAll;
    _peerClient=[[RTCPeerClient alloc]initWithConfiguration:config signalingChannel:scc];
    [_peerClient addObserver:self];
  }
  return _peerClient;
}

-(void)onInvited:(NSString *)remoteUserId{
  [[NSNotificationCenter defaultCenter] postNotificationName:@"OnInvited" object:self userInfo:[NSDictionary dictionaryWithObject:remoteUserId forKey:@"remoteUserId"]];
  NSLog(@"AppDelegate on invited.");
}

-(void)onAccepted:(NSString*)remoteUserId {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"OnAccepted" object:self userInfo:[NSDictionary dictionaryWithObject:remoteUserId forKey:@"remoteUserId"]];
  NSLog(@"AppDelegate on accepted.");
}

-(void)onDenied:(NSString *)remoteUserId {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"OnDenied" object:self userInfo:[NSDictionary dictionaryWithObject:remoteUserId forKey:@"remoteUserId"]];
  NSLog(@"AppDelegate on denied.");
}

-(void)onStreamAdded:(RTCRemoteStream *)stream{
  NSLog(@"AppDelegate on stream added");
  [stream retain];
  [_infos addObject:[NSDictionary dictionaryWithObject:stream forKey:@"stream"]];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"OnStreamAdded" object:self userInfo:[NSDictionary dictionaryWithObject:stream forKey:@"stream"]];
}

-(void)onStreamRemoved:(RTCRemoteStream *)stream{
  [_infos removeObject:[NSDictionary dictionaryWithObject:stream forKey:@"stream"]];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"OnStreamRemoved" object:self userInfo:[NSDictionary dictionaryWithObject:stream forKey:@"stream"]];
  NSLog(@"AppDelegate on stream removed.");
}

-(void)onDisconnected{
  NSLog(@"AppDelegate on server disconnected.");
}

- (void) onChatStarted:(NSString *)remoteUserId {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"OnStarted" object:self userInfo:[NSDictionary dictionaryWithObject:remoteUserId forKey:@"remoteUserId"]];
  NSLog(@"AppDelegate on chat started.");
}

- (void) onChatStopped:(NSString *)remoteUserId {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"OnStopped" object:self userInfo:[NSDictionary dictionaryWithObject:remoteUserId forKey:@"remoteUserId"]];
  NSLog(@"AppDelegate on stopped.");
}

-(void)onDataReceived:(NSString *)remoteUserId message:(NSString *)message{
  NSLog(@"Recieved data from %@, message: %@", remoteUserId, message);
}

@end
