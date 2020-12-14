#import "LoopbackController.h"
#import "YTFS_Filesystem.h"
#import "YTVideo.h"
#import <MacFUSE/MacFUSE.h>

@implementation YTFS_Controller

- (void)mountFailed:(NSNotification *)notification {
  NSDictionary* userInfo = [notification userInfo];
  NSError* error = [userInfo objectForKey:kGMUserFileSystemErrorKey];
  NSLog(@"kGMUserFileSystem Error: %@, userInfo=%@", error, [error userInfo]);
  //NSRunAlertPanel(@"Mount Failed", [error localizedDescription], nil, nil, nil);
  
  NSAlert *alert = [[NSAlert alloc] init];
  [alert setMessageText:@"Mount Failed"];
  [alert setInformativeText:@"Mount Failed"];
  [alert addButtonWithTitle:@"OK"];
  [alert setAlertStyle:NSAlertStyleWarning];

  [alert runModal];
  
  [[NSApplication sharedApplication] terminate:nil];
}

- (void)didMount:(NSNotification *)notification {
  NSDictionary* userInfo = [notification userInfo];
  NSString* mountPath = [userInfo objectForKey:kGMUserFileSystemMountPathKey];
  NSString* parentPath = [mountPath stringByDeletingLastPathComponent];
  [[NSWorkspace sharedWorkspace] selectFile:mountPath
                   inFileViewerRootedAtPath:parentPath];
}

- (void)didUnmount:(NSNotification*)notification {
  [[NSApplication sharedApplication] terminate:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  // Pump up our url cache.
  NSURLCache* cache = [NSURLCache sharedURLCache];
  [cache setDiskCapacity:(1024 * 1024 * 500)];
  [cache setMemoryCapacity:(1024 * 1024 * 40)];
  
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(mountFailed:)
                 name:kGMUserFileSystemMountFailed object:nil];
  [center addObserver:self selector:@selector(didMount:)
                 name:kGMUserFileSystemDidMount object:nil];
  [center addObserver:self selector:@selector(didUnmount:)
                 name:kGMUserFileSystemDidUnmount object:nil];
  
  NSString* mountPath = @"/Volumes/YTFS";
  fs_delegate_ =
    [[YTFS_Filesystem alloc] initWithVideos:[YTVideo fetchTopRatedVideos]];
  fs_ = [[GMUserFileSystem alloc] initWithDelegate:fs_delegate_ isThreadSafe:YES];

  NSMutableArray* options = [NSMutableArray array];
  NSString* volArg =
    [NSString stringWithFormat:@"volicon=%@",
     [[NSBundle mainBundle] pathForResource:@"YTFS" ofType:@"icns"]];
  [options addObject:volArg];
  [options addObject:@"volname=YTFS"];
  [options addObject:@"rdonly"];
  [fs_ mountAtPath:mountPath withOptions:options];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [fs_ unmount];
  [fs_ release];
  [fs_delegate_ release];
  return NSTerminateNow;
}

@end
