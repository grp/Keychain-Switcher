/*
 * Copyright (c) 2012-2013, Grant Paul
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "KSAppDelegate.h"

@implementation KSAppDelegate {
    NSStatusItem *statusItem;
    NSMenuItem *descriptionItem;
    NSMenuItem *enterpriseItem;
    NSMenuItem *companyItem;
    NSMenuItem *noItem;

    SecKeychainRef enterpriseKeychain;
    SecKeychainRef companyKeychain;
}

- (NSString *)enterprisePath {
    NSString *enterpriseKeychainPath = @"~/Dropbox/Other/Keys/Enterprise.keychain";
    enterpriseKeychainPath = [enterpriseKeychainPath stringByExpandingTildeInPath];
    return enterpriseKeychainPath;
}

- (NSString *)companyPath {
    NSString *companyKeychainPath = @"~/Dropbox/Other/Keys/Company.keychain";
    companyKeychainPath = [companyKeychainPath stringByExpandingTildeInPath];
    return companyKeychainPath;
}

- (void)updateForCurrentSelection {
    CFArrayRef searchList = NULL;
    SecKeychainCopySearchList(&searchList);

    BOOL enterprise = NO;
    BOOL company = NO;

    for (CFIndex i = 0; i < CFArrayGetCount(searchList); i++) {
        SecKeychainRef keychain = (SecKeychainRef) CFArrayGetValueAtIndex(searchList, i);

        char *keychainPathCharacters = malloc(MAXPATHLEN);
        UInt32 keychainPathLength = MAXPATHLEN;
        SecKeychainGetPath(keychain, &keychainPathLength, keychainPathCharacters);
        NSString *keychainPath = [NSString stringWithUTF8String:keychainPathCharacters];
        free(keychainPathCharacters);

        if ([keychainPath isEqualToString:[self enterprisePath]]) {
            enterprise = YES;
        } else if ([keychainPath isEqualToString:[self companyPath]]) {
            company = YES;
        }
    }

    CFRelease(searchList);

    if (enterprise) {
        [descriptionItem setTitle:@"Current Keychain: Enterprise"];
    } else if (company) {
        [descriptionItem setTitle:@"Current Keychain: Company"];
    } else {
        [descriptionItem setTitle:@"Current Keychain: None"];
    }

    [statusItem setTitle:(enterprise ? @"◉" : (company ? @"◎" : @"◯"))];

    [enterpriseItem setState:(enterprise ? NSOnState : NSOffState)];
    [companyItem setState:(company ? NSOnState : NSOffState)];
    [noItem setState:(!enterprise && !company)];
}

- (void)removeBothKeychains {
    CFArrayRef searchList = NULL;
    SecKeychainCopySearchList(&searchList);
    CFMutableArrayRef mutableSearchList = CFArrayCreateMutable(NULL, CFArrayGetCount(searchList), &kCFTypeArrayCallBacks);
    
    for (CFIndex i = 0; i < CFArrayGetCount(searchList); i++) {
        SecKeychainRef keychain = (SecKeychainRef) CFArrayGetValueAtIndex(searchList, i);

        char *keychainPathCharacters = malloc(MAXPATHLEN);
        UInt32 keychainPathLength = MAXPATHLEN;
        SecKeychainGetPath(keychain, &keychainPathLength, keychainPathCharacters);
        NSString *keychainPath = [NSString stringWithUTF8String:keychainPathCharacters];
        free(keychainPathCharacters);

        if ([keychainPath isEqualToString:[self enterprisePath]]) {
        } else if ([keychainPath isEqualToString:[self companyPath]]) {
        } else {
            CFArrayAppendValue(mutableSearchList, keychain);
        }
    }

    SecKeychainSetSearchList(mutableSearchList);
    CFRelease(mutableSearchList);
    CFRelease(searchList);
}

- (void)addKeychain:(SecKeychainRef)keychain {
    [self removeBothKeychains];

    CFArrayRef searchList = NULL;
    SecKeychainCopySearchList(&searchList);

    CFMutableArrayRef mutableSearchList = CFArrayCreateMutableCopy(NULL, CFArrayGetCount(searchList), searchList);

    CFArrayAppendValue(mutableSearchList, keychain);
    SecKeychainSetSearchList(mutableSearchList);

    CFRelease(mutableSearchList);
    CFRelease(searchList);
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
    statusItem = [statusBar statusItemWithLength:NSSquareStatusItemLength];
    [statusItem retain];

    [statusItem setToolTip:@"Keychain Switcher"];
    [statusItem setHighlightMode:YES];
    
    [statusItem setTarget:NSApp];
    [statusItem setDoubleAction:@selector(terminate:)];

    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Keychain Switcher"];

    descriptionItem = [[NSMenuItem alloc] initWithTitle:@"Current Keychain: Unknown" action:NULL keyEquivalent:@""];
    [descriptionItem setEnabled:NO];
    [menu addItem:descriptionItem];

    NSMenuItem *separatorItem = [NSMenuItem separatorItem];
    [menu addItem:separatorItem];
    
    enterpriseItem = [menu addItemWithTitle:@"Enterprise" action:@selector(enterpriseFromMenuItem:) keyEquivalent:@""];
    [enterpriseItem setTarget:self];
    [enterpriseItem retain];

    companyItem = [menu addItemWithTitle:@"Company" action:@selector(companyFromMenuItem:) keyEquivalent:@""];
    [companyItem setTarget:self];
    [companyItem retain];

    NSMenuItem *secondSeparatorItem = [NSMenuItem separatorItem];
    [menu addItem:secondSeparatorItem];

    noItem = [menu addItemWithTitle:@"No Keychain" action:@selector(noFromMenuItem:) keyEquivalent:@""];
    [noItem setTarget:self];
    [noItem retain];

    [statusItem setMenu:menu];

    SecKeychainOpen([[self enterprisePath] UTF8String], &enterpriseKeychain);
    SecKeychainOpen([[self companyPath] UTF8String], &companyKeychain);

    [self removeBothKeychains];
    [self updateForCurrentSelection];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [self removeBothKeychains];
}

- (void)noFromMenuItem:(NSMenuItem *)menuItem {
    [self removeBothKeychains];
    [self updateForCurrentSelection];
}

- (void)enterpriseFromMenuItem:(NSMenuItem *)menuItem {
    [self addKeychain:enterpriseKeychain];
    [self updateForCurrentSelection];
}

- (void)companyFromMenuItem:(NSMenuItem *)menuItem {
    [self addKeychain:companyKeychain];
    [self updateForCurrentSelection];
}

@end
