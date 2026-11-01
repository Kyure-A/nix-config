#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <ImageIO/ImageIO.h>
#include <unistd.h>
#include <string.h>

// A native window for the existing local harness. Authentication stays in
// process memory and WebKit's cookie store; it is never passed to argv or logs.
@interface DSHApp : NSObject <NSApplicationDelegate, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate, NSURLSessionTaskDelegate>
@property (strong) NSWindow *window;
@property (strong) WKWebView *webView;
@property (strong) NSTextField *status;
@property (strong) NSButton *retry;
@property BOOL connecting;
@end

static BOOL LocalURL(NSURL *url) {
    return [url.scheme isEqualToString:@"http"] && [url.host isEqualToString:@"127.0.0.1"] && url.port.integerValue == 3080;
}

static int Launchctl(NSArray<NSString *> *arguments) {
    NSTask *task = [NSTask new];
    task.executableURL = [NSURL fileURLWithPath:@"/bin/launchctl"];
    task.arguments = arguments;
    task.standardOutput = [NSFileHandle fileHandleWithNullDevice];
    task.standardError = [NSFileHandle fileHandleWithNullDevice];
    if (![task launchAndReturnError:nil]) return -1;
    [task waitUntilExit];
    return task.terminationStatus;
}

static NSURL *BootstrapURLFromPath(NSString *path) {
    NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath:path];
    if (!file) return nil;
    @try {
        unsigned long long cursor = [file seekToEndOfFile];
        NSData *suffix = [NSData data];
        NSRegularExpression *pattern = [NSRegularExpression regularExpressionWithPattern:@"^dsh web: (http://127\\.0\\.0\\.1:3080/\\?token=[A-Za-z0-9_-]+)(?:\\s|$)" options:NSRegularExpressionAnchorsMatchLines error:nil];
        while (cursor > 0) {
            unsigned long long start = cursor > 65536 ? cursor - 65536 : 0;
            [file seekToFileOffset:start];
            NSMutableData *chunk = [[file readDataOfLength:(NSUInteger)(cursor - start)] mutableCopy];
            [chunk appendData:suffix];
            // Latin-1 preserves ASCII startup lines even when a UTF-8 log
            // character straddles a chunk. Memory stays below two chunks.
            NSString *text = [[NSString alloc] initWithData:chunk encoding:NSISOLatin1StringEncoding];
            NSRange newline = [text rangeOfString:@"\n"];
            NSUInteger beginning = start == 0 ? 0 : (newline.location == NSNotFound ? text.length : NSMaxRange(newline));
            NSTextCheckingResult *match = [[pattern matchesInString:text options:0 range:NSMakeRange(beginning, text.length - beginning)] lastObject];
            if (match) {
                NSURL *url = [NSURL URLWithString:[text substringWithRange:[match rangeAtIndex:1]]];
                [file closeFile]; return url;
            }
            // Carry only the first incomplete line into the preceding chunk.
            // A genuine startup line is short; discard oversized log records.
            suffix = newline.location != NSNotFound && NSMaxRange(newline) <= 4096 ? [chunk subdataWithRange:NSMakeRange(0, NSMaxRange(newline))] : [NSData data];
            cursor = start;
        }
        [file closeFile]; return nil;
    } @catch (__unused NSException *exception) {
        [file closeFile]; return nil;
    }
}

static NSURL *BootstrapURL(void) {
    return BootstrapURLFromPath([NSHomeDirectory() stringByAppendingPathComponent:@".local/state/dsh/web.log"]);
}

static void WriteIcon(NSString *path) {
    NSMutableData *icon = [NSMutableData dataWithBytes:"icns\0\0\0\0" length:8];
    NSArray<NSString *> *types = @[@"ic08", @"ic09", @"ic10"];
    for (NSUInteger index = 0; index < 3; index++) {
        size_t size = 256UL << index;
        CGColorSpaceRef colors = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(NULL, size, size, 8, size * 4, colors, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
        CGColorSpaceRelease(colors);
        CGContextScaleCTM(context, size / 256.0, size / 256.0);
        CGPathRef background = CGPathCreateWithRoundedRect(CGRectMake(12, 12, 232, 232), 52, 52, NULL);
        CGContextSetRGBFillColor(context, 0.09, 0.16, 0.29, 1);
        CGContextAddPath(context, background); CGContextFillPath(context); CGPathRelease(background);
        CGContextSetRGBStrokeColor(context, 0.38, 0.80, 0.95, 1);
        CGContextSetLineWidth(context, 19); CGContextSetLineCap(context, kCGLineCapRound); CGContextSetLineJoin(context, kCGLineJoinRound);
        CGContextMoveToPoint(context, 64, 166); CGContextAddLineToPoint(context, 108, 128); CGContextAddLineToPoint(context, 64, 90); CGContextStrokePath(context);
        CGContextSetRGBStrokeColor(context, 0.94, 0.97, 1, 1);
        CGContextMoveToPoint(context, 140, 90); CGContextAddLineToPoint(context, 190, 90); CGContextStrokePath(context);
        CGImageRef image = CGBitmapContextCreateImage(context);
        NSMutableData *png = [NSMutableData data];
        CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)png, CFSTR("public.png"), 1, NULL);
        CGImageDestinationAddImage(destination, image, NULL); CGImageDestinationFinalize(destination);
        CFRelease(destination); CGImageRelease(image); CGContextRelease(context);
        [icon appendData:[types[index] dataUsingEncoding:NSASCIIStringEncoding]];
        uint32_t length = CFSwapInt32HostToBig((uint32_t)png.length + 8); [icon appendBytes:&length length:4]; [icon appendData:png];
    }
    uint32_t length = CFSwapInt32HostToBig((uint32_t)icon.length);
    [icon replaceBytesInRange:NSMakeRange(4, 4) withBytes:&length];
    [icon writeToFile:path atomically:YES];
}

@implementation DSHApp
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    (void)notification;
    NSMenu *menu = [NSMenu new];
    NSMenuItem *appItem = [NSMenuItem new]; [menu addItem:appItem];
    NSMenu *appMenu = [NSMenu new]; appItem.submenu = appMenu;
    [appMenu addItemWithTitle:@"About DSH" action:@selector(orderFrontStandardAboutPanel:) keyEquivalent:@""];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Hide DSH" action:@selector(hide:) keyEquivalent:@"h"];
    [appMenu addItemWithTitle:@"Quit DSH" action:@selector(terminate:) keyEquivalent:@"q"];
    NSMenuItem *editItem = [[NSMenuItem alloc] initWithTitle:@"Edit" action:nil keyEquivalent:@""]; [menu addItem:editItem]; editItem.submenu = [[NSMenu alloc] initWithTitle:@"Edit"];
    for (NSArray *command in @[@[@"Undo", @"undo:", @"z"], @[@"Cut", @"cut:", @"x"], @[@"Copy", @"copy:", @"c"], @[@"Paste", @"paste:", @"v"], @[@"Select All", @"selectAll:", @"a"]]) {
        [editItem.submenu addItemWithTitle:command[0] action:NSSelectorFromString(command[1]) keyEquivalent:command[2]];
    }
    NSMenuItem *windowItem = [[NSMenuItem alloc] initWithTitle:@"Window" action:nil keyEquivalent:@""]; [menu addItem:windowItem]; windowItem.submenu = [[NSMenu alloc] initWithTitle:@"Window"];
    NSMenuItem *reload = [windowItem.submenu addItemWithTitle:@"Reload" action:@selector(reload:) keyEquivalent:@"r"]; reload.target = self;
    [windowItem.submenu addItemWithTitle:@"Minimize" action:@selector(performMiniaturize:) keyEquivalent:@"m"];
    [windowItem.submenu addItemWithTitle:@"Close Window" action:@selector(performClose:) keyEquivalent:@"w"];
    NSApp.mainMenu = menu; NSApp.windowsMenu = windowItem.submenu;
    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 1320, 880) styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable backing:NSBackingStoreBuffered defer:NO];
    self.window.title = @"DSH"; self.window.minSize = NSMakeSize(900, 620); self.window.releasedWhenClosed = NO;
    [self.window center]; [self.window setFrameAutosaveName:@"DSHMainWindow"];
    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
    configuration.websiteDataStore = [WKWebsiteDataStore defaultDataStore];
    self.webView = [[WKWebView alloc] initWithFrame:self.window.contentView.bounds configuration:configuration];
    self.webView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.webView.navigationDelegate = self; self.webView.UIDelegate = self;
    [self.window.contentView addSubview:self.webView];
    self.status = [NSTextField labelWithString:@"Starting DSH…"];
    self.status.font = [NSFont systemFontOfSize:18 weight:NSFontWeightMedium]; self.status.alignment = NSTextAlignmentCenter;
    self.status.frame = NSMakeRect(100, 425, 1120, 28); self.status.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin | NSViewMaxYMargin;
    [self.window.contentView addSubview:self.status];
    self.retry = [NSButton buttonWithTitle:@"Retry" target:self action:@selector(reload:)];
    self.retry.frame = NSMakeRect(610, 365, 100, 32); self.retry.autoresizingMask = NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin; self.retry.hidden = YES;
    [self.window.contentView addSubview:self.retry];
    [self.window makeKeyAndOrderFront:nil]; [NSApp activateIgnoringOtherApps:YES];
    [self connect];
}
- (BOOL)applicationShouldHandleReopen:(NSApplication *)application hasVisibleWindows:(BOOL)visible {
    (void)application; (void)visible; [self.window makeKeyAndOrderFront:nil]; return YES;
}
- (void)reload:(id)sender { (void)sender; [self connect]; }
- (void)connect {
    if (self.connecting) return;
    self.connecting = YES; self.status.stringValue = @"Connecting to DSH…"; self.status.hidden = NO; self.retry.hidden = YES;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSString *domain = [NSString stringWithFormat:@"gui/%u", getuid()];
        NSString *service = [domain stringByAppendingString:@"/org.nix-community.home.dsh-web"];
        if (Launchctl(@[@"print", service]) != 0) Launchctl(@[@"bootstrap", domain, [NSHomeDirectory() stringByAppendingPathComponent:@"Library/LaunchAgents/org.nix-community.home.dsh-web.plist"]]);
        Launchctl(@[@"kickstart", service]);
        NSURL *ready = nil;
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        configuration.HTTPShouldSetCookies = NO; configuration.URLCache = nil; configuration.timeoutIntervalForRequest = 2;
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
        NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:45];
        while ([deadline timeIntervalSinceNow] > 0) {
            NSURL *url = BootstrapURL();
            if (url) {
                dispatch_semaphore_t done = dispatch_semaphore_create(0); __block BOOL valid = NO;
                NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    (void)data; NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
                    valid = !error && http.statusCode == 303 && [[http valueForHTTPHeaderField:@"Location"] isEqualToString:@"./"];
                    dispatch_semaphore_signal(done);
                }];
                [task resume]; dispatch_semaphore_wait(done, DISPATCH_TIME_FOREVER);
                if (valid) { ready = url; break; }
            }
            [NSThread sleepForTimeInterval:0.3];
        }
        [session invalidateAndCancel];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.connecting = NO;
            if (ready) [self.webView loadRequest:[NSURLRequest requestWithURL:ready]];
            else { self.status.stringValue = @"DSH is unavailable. Check the local service, then retry."; self.retry.hidden = NO; }
        });
    });
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler {
    (void)session; (void)task; (void)response; (void)request; completionHandler(nil);
}
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    (void)webView; (void)navigation; self.status.hidden = YES; self.retry.hidden = YES;
}
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    (void)webView; (void)navigation;
    if (error.code == NSURLErrorCancelled) return;
    self.status.stringValue = @"The connection to DSH was interrupted."; self.status.hidden = NO; self.retry.hidden = NO;
}
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)action decisionHandler:(void (^)(WKNavigationActionPolicy))handler {
    if (action.shouldPerformDownload) { handler(WKNavigationActionPolicyDownload); return; }
    NSURL *url = action.request.URL;
    if (LocalURL(url) || [url.scheme isEqualToString:@"about"] || [url.scheme isEqualToString:@"blob"]) { handler(WKNavigationActionPolicyAllow); return; }
    if (action.targetFrame.isMainFrame || !action.targetFrame) {
        if ([@[@"https", @"http", @"mailto"] containsObject:url.scheme]) [NSWorkspace.sharedWorkspace openURL:url];
        handler(WKNavigationActionPolicyCancel); return;
    }
    (void)webView; handler(WKNavigationActionPolicyCancel);
}
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)response decisionHandler:(void (^)(WKNavigationResponsePolicy))handler {
    NSHTTPURLResponse *http = (NSHTTPURLResponse *)response.response;
    if ([http isKindOfClass:NSHTTPURLResponse.class] && http.statusCode == 401 && response.isForMainFrame) { handler(WKNavigationResponsePolicyCancel); [self connect]; return; }
    (void)webView; handler(response.canShowMIMEType ? WKNavigationResponsePolicyAllow : WKNavigationResponsePolicyDownload);
}
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)action windowFeatures:(WKWindowFeatures *)features {
    (void)configuration; (void)features;
    if (LocalURL(action.request.URL)) [webView loadRequest:action.request];
    else if ([@[@"https", @"http", @"mailto"] containsObject:action.request.URL.scheme]) [NSWorkspace.sharedWorkspace openURL:action.request.URL];
    return nil;
}
- (void)webView:(WKWebView *)webView runOpenPanelWithParameters:(WKOpenPanelParameters *)parameters initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSArray<NSURL *> *))completionHandler {
    (void)webView; (void)frame;
    NSOpenPanel *panel = [NSOpenPanel openPanel]; panel.allowsMultipleSelection = parameters.allowsMultipleSelection; panel.canChooseDirectories = parameters.allowsDirectories;
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) { completionHandler(result == NSModalResponseOK ? panel.URLs : nil); }];
}
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    (void)webView; (void)frame; NSAlert *alert = [NSAlert new]; alert.messageText = @"DSH"; alert.informativeText = message;
    [alert beginSheetModalForWindow:self.window completionHandler:^(__unused NSModalResponse result) { completionHandler(); }];
}
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    (void)webView; (void)frame; NSAlert *alert = [NSAlert new]; alert.messageText = @"DSH"; alert.informativeText = message; [alert addButtonWithTitle:@"OK"]; [alert addButtonWithTitle:@"Cancel"];
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) { completionHandler(result == NSAlertFirstButtonReturn); }];
}
- (void)webView:(WKWebView *)webView navigationAction:(WKNavigationAction *)action didBecomeDownload:(WKDownload *)download { (void)webView; (void)action; download.delegate = self; }
- (void)webView:(WKWebView *)webView navigationResponse:(WKNavigationResponse *)response didBecomeDownload:(WKDownload *)download { (void)webView; (void)response; download.delegate = self; }
- (void)download:(WKDownload *)download decideDestinationUsingResponse:(NSURLResponse *)response suggestedFilename:(NSString *)filename completionHandler:(void (^)(NSURL *))completionHandler {
    (void)download; (void)response; NSSavePanel *panel = [NSSavePanel savePanel]; panel.nameFieldStringValue = filename;
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) { completionHandler(result == NSModalResponseOK ? panel.URL : nil); }];
}
@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc == 3 && strcmp(argv[1], "--write-icon") == 0) { WriteIcon([NSString stringWithUTF8String:argv[2]]); return 0; }
        NSApplication *app = [NSApplication sharedApplication];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
        __attribute__((objc_precise_lifetime)) DSHApp *delegate = [DSHApp new]; app.delegate = delegate; [app run];
    }
    return 0;
}
