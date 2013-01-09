//
//  main.m
//  Keychain Switcher
//
//  Created by Grant Paul on 1/7/13.
//  Copyright (c) 2013 Xuzz Productions, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KSAppDelegate.h"

int main(int argc, char *argv[])
{
    NSApplication *app = [NSApplication sharedApplication];
    [app setDelegate:[[KSAppDelegate alloc] init]];

    return NSApplicationMain(argc, (const char **)argv);
}
