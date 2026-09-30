// Prints the system Now Playing info as one JSON line. Loaded by /usr/bin/perl (Apple-signed, so it keeps
// MediaRemote access that macOS 15.4+ denies to third-party binaries). Built by build.sh into libmediaremote.dylib.
#import <Foundation/Foundation.h>
#import <dlfcn.h>
typedef void (^InfoBlock)(NSDictionary *);
typedef void (^BoolBlock)(BOOL);
void macremote_nowplaying(void *interp, void *cv) {
  @autoreleasepool {
    void *h = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW);
    if (!h) { puts("{\"error\":\"dlopen\"}"); return; }
    void (*getInfo)(dispatch_queue_t, InfoBlock) = dlsym(h, "MRMediaRemoteGetNowPlayingInfo");
    void (*getPlaying)(dispatch_queue_t, BoolBlock) = dlsym(h, "MRMediaRemoteGetNowPlayingApplicationIsPlaying");
    if (!getInfo) { puts("{\"error\":\"nosym\"}"); return; }
    __block NSDictionary *info = nil; __block int playing = -1;
    dispatch_semaphore_t s = dispatch_semaphore_create(0), s2 = dispatch_semaphore_create(0);
    getInfo(dispatch_get_global_queue(0,0), ^(NSDictionary *d){ info = d; dispatch_semaphore_signal(s); });
    if (getPlaying) getPlaying(dispatch_get_global_queue(0,0), ^(BOOL p){ playing = p; dispatch_semaphore_signal(s2); }); else dispatch_semaphore_signal(s2);
    if (dispatch_semaphore_wait(s, dispatch_time(DISPATCH_TIME_NOW, 3*NSEC_PER_SEC))) { puts("{\"error\":\"timeout\"}"); return; }
    dispatch_semaphore_wait(s2, dispatch_time(DISPATCH_TIME_NOW, 1*NSEC_PER_SEC));
    NSMutableDictionary *out = [NSMutableDictionary dictionary];
    for (NSString *k in info) {
      id v = info[k];
      if ([v isKindOfClass:NSData.class]) v = [@"data:" stringByAppendingString:[(NSData*)v base64EncodedStringWithOptions:0]];
      else if ([v isKindOfClass:NSDate.class]) v = @([(NSDate*)v timeIntervalSince1970]);
      else if (![v isKindOfClass:NSString.class] && ![v isKindOfClass:NSNumber.class]) v = [v description];
      out[k] = v;
    }
    out[@"_playing"] = @(playing);
    NSData *j = [NSJSONSerialization dataWithJSONObject:out options:0 error:nil];
    fwrite(j.bytes, 1, j.length, stdout); fputc('\n', stdout); fflush(stdout);
  }
}
