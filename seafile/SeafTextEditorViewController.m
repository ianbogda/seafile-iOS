//
//  SeafTextEditorViewController.m
//  seafile
//
//  Created by Wang Wei on 4/9/13.
//  Copyright (c) 2013 Seafile Ltd.  All rights reserved.
//

#import "SeafTextEditorViewController.h"
#import "SeafAppDelegate.h"
#import "EGOTextView.h"

#import "UIViewController+Extend.h"
#import "ExtentedString.h"
#import "Utils.h"
#import "Debug.h"

#define TOP_VIEW_HEIGHT 33

enum TOOL_ITEM {
    ITEM_REDO = 0,
    ITEM_UNDO,
    ITEM_JUSTIFY,
    ITEM_RIGHT,
    ITEM_CENTER,
    ITEM_LEFT,
    ITEM_OUDENT,
    ITEM_INDENT,
    ITEM_OL,
    ITEM_UL,
    ITEM_UNDERLINE,
    ITEM_STRIKE,
    ITEM_ITALIC,
    ITEM_BOLD,
    ITEM_MAX,
};

@interface SeafTextEditorViewController ()<EGOTextViewDelegate>
@property (nonatomic, retain) NSTimer *timer;
@property BOOL currentBoldStatus;
@property BOOL currentItalicStatus;
@property BOOL currentUnderlineStatus;
@property UIBarButtonItem *ep;
@property UIBarButtonItem *cancelItem;
@property UIBarButtonItem *saveItem;
@property NSMutableArray *litems;
@property (strong, nonatomic) IBOutlet UIView *topview;

@property id<QLPreviewItem, PreViewDelegate> sfile;
@property int flags;

@property(nonatomic,retain) EGOTextView *egoTextView;

@end

@implementation SeafTextEditorViewController
@synthesize timer;
@synthesize currentBoldStatus;
@synthesize currentItalicStatus;
@synthesize currentUnderlineStatus;
@synthesize sfile;
@synthesize flags;

- (id)initWithFile:(id<QLPreviewItem, PreViewDelegate>)file
{
    self = [self initWithAutoNibName];
    self.sfile = file;
    return self;
}

- (BOOL)IsSeaf
{
    return [sfile.mime isEqualToString:@"text/x-seafile"];
}

- (BOOL)IsMarkdown
{
    return [sfile.mime isEqualToString:@"text/x-markdown"];
}

- (UIWebView *)webView
{
    return (UIWebView *)self.view;
}
- (void)bold2
{
    [self.webView stringByEvaluatingJavaScriptFromString:@"document.execCommand(\"Bold\")"];
}

- (void)italic2
{
    [self.webView stringByEvaluatingJavaScriptFromString:@"document.execCommand(\"Italic\")"];
}

- (void)underline2
{
    [self.webView stringByEvaluatingJavaScriptFromString:@"document.execCommand(\"Underline\")"];
}

- (void)btClicked:(NSString *)tag
{
    [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"btClicked(\"%@\")", tag]];
    if (IsIpad() && [self IsSeaf]) {
        NSString *str = [self.webView stringByEvaluatingJavaScriptFromString:@"getBtState()"];
        [self handleUrl:str];
    }
}

- (void)edit_preview
{
    if ([self.ep.title isEqualToString:NSLocalizedString(@"Preview", nil)]) {
        self.ep.title = NSLocalizedString(@"Edit", nil);
        self.egoTextView.hidden = YES;
        for (UIBarButtonItem *item in self.navigationItem.rightBarButtonItems)
            item.enabled = NO;
        NSString *js = [NSString stringWithFormat:@"setContent(\"%@\");", [self.egoTextView.text stringEscapedForJavasacript]];
        [self.webView stringByEvaluatingJavaScriptFromString:js];
    } else {
        self.ep.title = NSLocalizedString(@"Preview", nil);
        self.egoTextView.hidden = NO;
        [self.egoTextView becomeFirstResponder];
        for (UIBarButtonItem *item in self.navigationItem.rightBarButtonItems) {
            item.enabled = YES;
        }
    }
}
- (void)pound
{
    [self btClicked:@"pound"];
}
- (void)asterisk
{
    [self btClicked:@"star"];
}
- (void)equal
{
    [self btClicked:@"equal"];
}
- (void)bold
{
    [self btClicked:@"bold"];
}
- (void)italic
{
    [self btClicked:@"italic"];
}
- (void)insertLink
{
    [self btClicked:@"link"];
}
- (void)quote
{
    [self btClicked:@"quote"];
}
- (void)code
{
    [self btClicked:@"code"];
}
- (void)image
{
    [self btClicked:@"image"];
}
- (void)ol
{
    [self btClicked:@"olist"];
}
- (void)ul
{
    [self btClicked:@"ulist"];
}
- (void)heading
{
    [self btClicked:@"heading"];
}
- (void)hor
{
    [self btClicked:@"hr"];
}
- (void)undo
{
    [self btClicked:@"undo"];
}
- (void)redo
{
    [self btClicked:@"redo"];
}
- (void)help
{
    [self btClicked:@"help"];
}

- (void)strike
{
    [self btClicked:@"strike"];
}
- (void)underline
{
    [self btClicked:@"underline"];
}
- (void)indent
{
    [self btClicked:@"indent"];
}
- (void)outdent
{
    [self btClicked:@"outdent"];
}
- (void)left
{
    [self btClicked:@"left"];
}
- (void)center
{
    [self btClicked:@"center"];
}
- (void)right
{
    [self btClicked:@"right"];
}
- (void)justify
{
    [self btClicked:@"justify"];
}
- (void)removeLink
{
    [self btClicked:@"unlink"];
}

- (void)replaceSelectedWith:(NSString *)dft before:(NSString *)before after:(NSString *)after
{
    NSRange r = self.egoTextView.selectedRange;
    NSString *selected = dft;
    if (r.length > 0)
        selected = [[self.egoTextView.attributedString attributedSubstringFromRange:r] string];
    NSString *news = [NSString stringWithFormat:@"%@%@%@", before, selected, after];
    Debug("r=%d, %d, %@, %@", r.location, r.length, selected, news);
    [self.egoTextView replaceNSRange:r withText:news];
    NSRange selectR = (NSRange) {r.location + before.length, selected.length};
    self.egoTextView.selectedRange = selectR;
}
- (void)insertString:(NSString *)s
{
    NSRange r = self.egoTextView.selectedRange;
    [self.egoTextView replaceNSRange:self.egoTextView.selectedRange withText:s];
    self.egoTextView.selectedRange = (NSRange) {r.location + 1, 0};;
}
- (IBAction)olM:(id)sender {
    [self replaceSelectedWith:@"List item" before:@"\n 1. " after:@""];
}
- (IBAction)ulM:(id)sender {
    [self replaceSelectedWith:@"List item" before:@"\n - " after:@""];
}
- (IBAction)codeM:(id)sender {
    [self replaceSelectedWith:@"enter code here" before:@"`" after:@"`"];
}
- (IBAction)quoteM:(id)sender {
    [self replaceSelectedWith:@"Blockquote" before:@"\n> " after:@""];
}
- (IBAction)insertLinkM:(id)sender {
    [self replaceSelectedWith:@"link" before:@"[" after:@"](http://example.com/)"];
}
- (IBAction)italicM:(id)sender {
    [self replaceSelectedWith:@"emphasized text" before:@"*" after:@"*"];
}
- (IBAction)boldM:(id)sender {
    [self replaceSelectedWith:@"strong text" before:@"**" after:@"**"];
}
- (IBAction)equalM:(id)sender {
    [self insertString:@"="];
}
- (IBAction)asteriskM:(id)sender {
    [self insertString:@"*"];
}
- (IBAction)poundM:(id)sender {
    [self insertString:@"#"];
}

- (UIBarButtonItem *)getBarItem:(NSString *)imageName action:(SEL)action active:(int)active
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0,0,20,20);
    UIImage *img = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", imageName]];
    UIImage *img2 = [UIImage imageNamed:[NSString stringWithFormat:@"%@2.png", imageName]];
    [btn setImage:img forState:UIControlStateNormal];
    [btn setImage:img2 forState:UIControlStateSelected];
    btn.showsTouchWhenHighlighted = YES;

    if(active)
        btn.selected = YES;
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:btn];
    return item;
}

- (UIBarButtonItem *)getTextBarItem:(NSString *)title action:(SEL)action active:(int)active
{
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStyleBordered target:self action:action];
    return item;
}

- (void)addItem:(NSMutableArray *)items image:(NSString *)imageName action:(SEL)action
{
    UIBarButtonItem *item = [self getBarItem:imageName action:action active:0];
    [items addObject:item];
    [items addObject:[self getSpaceBarItem:16.0]];
}

- (void)updateSeafToolbar:(int)flag
{
    if (flag == flags)
        return;
    flags = flag;
    for (int i = 0; i < ITEM_MAX; ++i) {
        UIBarButtonItem *item = [self.navigationItem.rightBarButtonItems objectAtIndex:2*i];
        UIButton *btn = (UIButton *)item.customView;
        btn.selected = (flag & (1 << i)) != 0;
    }
}

- (void)initSeafToolbar
{
    NSMutableArray *items = [[NSMutableArray alloc] init];
    [self addItem:items image:@"bt-redo" action:@selector(redo)];
    [self addItem:items image:@"bt-undo" action:@selector(undo)];
    [self addItem:items image:@"bt-justify" action:@selector(justify)];
    [self addItem:items image:@"bt-right" action:@selector(right)];
    [self addItem:items image:@"bt-center" action:@selector(center)];
    [self addItem:items image:@"bt-left" action:@selector(left)];
    [self addItem:items image:@"bt-outdent" action:@selector(outdent)];
    [self addItem:items image:@"bt-indent" action:@selector(indent)];
    [self addItem:items image:@"bt-ol" action:@selector(ol)];
    [self addItem:items image:@"bt-ul" action:@selector(ul)];
    [self addItem:items image:@"bt-underline" action:@selector(underline)];
    [self addItem:items image:@"bt-strikethrough" action:@selector(strike)];
    [self addItem:items image:@"bt-italic" action:@selector(italic)];
    [self addItem:items image:@"bt-bold" action:@selector(bold)];
    self.navigationItem.rightBarButtonItems = items;
}

- (void)checkBtState:(id)sender
{
    if (IsIpad() && [self IsSeaf]) {
        NSString *str = [self.webView stringByEvaluatingJavaScriptFromString:@"getBtState()"];
        [self handleUrl:str];
    }
}

- (void)checkSelection:(id)sender
{
    if ([self IsSeaf]) {
        if (!IsIpad()) {
            BOOL boldEnabled = [[self.webView stringByEvaluatingJavaScriptFromString:@"document.queryCommandState('Bold')"] boolValue];
            BOOL italicEnabled = [[self.webView stringByEvaluatingJavaScriptFromString:@"document.queryCommandState('Italic')"] boolValue];
            BOOL underlineEnabled = [[self.webView stringByEvaluatingJavaScriptFromString:@"document.queryCommandState('Underline')"] boolValue];

            NSMutableArray *items = [[NSMutableArray alloc] init];

            UIBarButtonItem *bold = [[UIBarButtonItem alloc] initWithTitle:(boldEnabled) ? @"[B]" : @" B " style:UIBarButtonItemStyleBordered target:self action:@selector(bold2)];
            UIBarButtonItem *italic = [[UIBarButtonItem alloc] initWithTitle:(italicEnabled) ? @"[I]" : @" I " style:UIBarButtonItemStyleBordered target:self action:@selector(italic2)];
            UIBarButtonItem *underline = [[UIBarButtonItem alloc] initWithTitle:(underlineEnabled) ? @"[U]" : @" U " style:UIBarButtonItemStyleBordered target:self action:@selector(underline2)];

            [items addObject:underline];
            [items addObject:italic];
            [items addObject:bold];
            self.navigationItem.rightBarButtonItems = items;

            if (currentBoldStatus != boldEnabled || currentItalicStatus != italicEnabled || currentUnderlineStatus != underlineEnabled || sender == self) {
                currentBoldStatus = boldEnabled;
                currentItalicStatus = italicEnabled;
                currentUnderlineStatus = underlineEnabled;
            }
        } else {
            [self initSeafToolbar];
        }
    } else {
        self.navigationItem.rightBarButtonItems = nil;
    }
}

- (void)dismissCurrentView
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancel
{
    [self dismissCurrentView];
}

- (void)save
{
    NSString *content;
    if (![self IsSeaf]) {
        content = self.egoTextView.text;
    } else {
        content = [self.webView stringByEvaluatingJavaScriptFromString:@"getContent()"];
    }
    [sfile saveContent:content];
    SeafAppDelegate *appdelegate = (SeafAppDelegate *)[[UIApplication sharedApplication] delegate];
    [self.detailViewController refreshView];
    [appdelegate.fileVC refreshView];
    [appdelegate.starredVC refreshView];
    [self dismissCurrentView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    // Do any additional setup after loading the view from its nib.
    self.flags = -1;
    self.navigationItem.rightBarButtonItems = nil;
    self.navigationController.navigationBar.tintColor = BAR_COLOR;

    EGOTextView *view = [[EGOTextView alloc] initWithFrame:self.view.bounds];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.frame = self.view.frame;
    view.delegate = self;
    [self.view addSubview:view];
    self.egoTextView = view;
    [view becomeFirstResponder];
    self.cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    self.saveItem = [self getTextBarItem:NSLocalizedString(@"Save", nil) action:@selector(save) active:0];
    [self start];
}
- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

# pragma - UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString *js = [NSString stringWithFormat:@"setContent(\"%@\");", [sfile.content stringEscapedForJavasacript]];
    [self.webView stringByEvaluatingJavaScriptFromString:js];
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
}

- (BOOL)handleUrl:(NSString *)urlStr
{
    //Decode the url string
    if (!urlStr || urlStr.length < 1) {
        [self updateSeafToolbar:0];
        return NO;
    }
    urlStr = [urlStr stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSError *jsonError;
    //parse JSON input in the URL
    NSDictionary *callInfo = [NSJSONSerialization
                              JSONObjectWithData:[urlStr dataUsingEncoding:NSUTF8StringEncoding]
                              options:kNilOptions
                              error:&jsonError];
    //check if there was error in parsing JSON input
    if (jsonError != nil) {
        Debug("Error parsing JSON for the url %@", urlStr);
        return NO;
    }

    //Get function name. It is a required input
    NSString *functionName = [callInfo objectForKey:@"functionname"];
    if (functionName == nil) {
        Debug("Missing function name");
        return NO;
    }
    NSArray *argsArray = [callInfo objectForKey:@"args"];
    int flag = 0;
    for (NSString *s in argsArray) {
        if ([@"bold" isEqualToString:s])
            flag |= 1 << ITEM_BOLD;
        else if ([@"italic" isEqualToString:s])
            flag |= 1 << ITEM_ITALIC;
        else if ([@"strikethrough" isEqualToString:s])
            flag |= 1 << ITEM_STRIKE;
        else if ([@"underline" isEqualToString:s])
            flag |= 1 << ITEM_UNDERLINE;
        else if ([@"insertunorderedlist" isEqualToString:s])
            flag |= 1 << ITEM_UL;
        else if ([@"insertorderedlist" isEqualToString:s])
            flag |= 1 << ITEM_OL;
        else if ([@"justifyleft" isEqualToString:s])
            flag |= 1 << ITEM_LEFT;
        else if ([@"justifycenter" isEqualToString:s])
            flag |= 1 << ITEM_CENTER;
        else if ([@"justifyright" isEqualToString:s])
            flag |= 1 << ITEM_RIGHT;
        else if ([@"justifyfull" isEqualToString:s])
            flag |= 1 << ITEM_JUSTIFY;
    }
    [self updateSeafToolbar:flag];
    return NO;
}
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *urlStr = request.URL.absoluteString;
    NSString *protocolPrefix = @"js2ios://";
    if ([[urlStr lowercaseString] hasPrefix:protocolPrefix]) {
        urlStr = [urlStr substringFromIndex:protocolPrefix.length];
        return [self handleUrl:urlStr];
    } else if ([urlStr.lowercaseString hasPrefix:@"file://"])
        return YES;
    return NO;
}

- (void)start
{
    if (![self IsSeaf]) {
        [self prepareRawText];
    } else {
        [self prepareSeaf];
    }
}

- (void)prepareRawText
{
    self.egoTextView.hidden = NO;
    self.egoTextView.text = sfile.content;
    self.litems = [[NSMutableArray alloc] init];
    [self.litems addObject:self.saveItem];
    if ([self IsMarkdown]) {
        self.ep = [self getTextBarItem:NSLocalizedString(@"Preview", nil) action:@selector(edit_preview) active:0];
        [self.litems addObject:self.ep];
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:self.sfile.previewItemURL cachePolicy: NSURLRequestUseProtocolCachePolicy timeoutInterval: 1];
        [self.webView loadRequest:request];
    }
    self.navigationItem.rightBarButtonItem = self.cancelItem;
    self.navigationItem.leftBarButtonItems = self.litems;
    [self.egoTextView becomeFirstResponder];
}

- (void)prepareSeaf
{
    self.litems = [[NSMutableArray alloc] init];
    [self.litems addObject:self.saveItem];
    [self.litems addObject: [self getSpaceBarItem:30.0]];
    [self.litems addObject:self.cancelItem];
    self.navigationItem.leftBarButtonItems = self.litems;

    self.egoTextView.hidden = YES;;
    NSString *path;
    if (IsIpad()) {
        path = [[NSBundle mainBundle] pathForResource:@"edit_file_seaf2" ofType:@"html"];
        timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(checkBtState:) userInfo:nil repeats:YES];
    } else {
        path = [[NSBundle mainBundle] pathForResource:@"edit_file_seaf" ofType:@"html"];
        timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(checkSelection:) userInfo:nil repeats:YES];
    }
    [self checkSelection:nil];

    NSURL *url = [NSURL fileURLWithPath:path];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy: NSURLRequestUseProtocolCachePolicy timeoutInterval: 30];
    [(UIWebView *)self.view loadRequest: request];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return IsIpad() || (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(BOOL)shouldAutorotate
{
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscapeRight| UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.execCommand(resizeTO(%f,%f))", self.webView.frame.size.width, self.webView.frame.size.height]];
}

#pragma mark EGOTextViewDelegate

- (BOOL)egoTextViewShouldBeginEditing:(EGOTextView *)textView {
    return YES;
}

- (BOOL)egoTextViewShouldEndEditing:(EGOTextView *)textView {
    return YES;
}

- (void)egoTextViewDidBeginEditing:(EGOTextView *)textView {
    [self.egoTextView setSelectedRange:NSMakeRange(0,0)];
}

- (void)egoTextViewDidEndEditing:(EGOTextView *)textView {
}

- (void)egoTextViewDidChange:(EGOTextView *)textView {
}

- (void)egoTextView:(EGOTextView*)textView didSelectURL:(NSURL *)URL {
}

- (void)removeBar {
    // Locate non-UIWindow.
    UIWindow *keyboardWindow = nil;
    for (UIWindow *testWindow in [[UIApplication sharedApplication] windows]) {
        if (![[testWindow class] isEqual:[UIWindow class]]) {
            keyboardWindow = testWindow;
            break;
        }
    }

    // Locate UIWebFormView.
    for (UIView *possibleFormView in [keyboardWindow subviews]) {
        // iOS 5 sticks the UIWebFormView inside a UIPeripheralHostView.
        if ([[possibleFormView description] rangeOfString:@"UIPeripheralHostView"].location != NSNotFound) {
            for (UIView *subviewWhichIsPossibleFormView in [possibleFormView subviews]) {
                if ([[subviewWhichIsPossibleFormView description] rangeOfString:@"UIWebFormAccessory"].location != NSNotFound) {
                    [subviewWhichIsPossibleFormView removeFromSuperview];
                }
            }
        }
    }
}

- (void)keyboardWillShow:(NSNotification *)notification {
    if ([self IsSeaf]) {
        [self performSelector:@selector(removeBar) withObject:nil afterDelay:0];
        return;
    }

    NSDictionary* info = [notification userInfo];
    CGSize keyBoardSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    float keyH = MIN(keyBoardSize.height, keyBoardSize.width);

    if (![self IsMarkdown]) {
        self.egoTextView.frame = CGRectMake(self.egoTextView.frame.origin.x, self.egoTextView.frame.origin.y, self.egoTextView.frame.size.width, self.view.bounds.size.height - keyH );
        return;
    } else
        self.egoTextView.frame = CGRectMake(self.egoTextView.frame.origin.x, self.egoTextView.frame.origin.y, self.egoTextView.frame.size.width, self.view.bounds.size.height - keyH - TOP_VIEW_HEIGHT );

    self.topview.frame = CGRectMake(0, self.egoTextView.frame.origin.y+ self.egoTextView.frame.size.height, self.egoTextView.frame.size.width, TOP_VIEW_HEIGHT);
    float unit = self.view.bounds.size.width / self.topview.subviews.count;
    for (int i = 0; i < self.topview.subviews.count; ++i) {
        UIView *bt = self.topview.subviews[i];
        float centerX = unit *i + unit/2;
        bt.frame = CGRectMake(centerX - bt.frame.size.width/2, bt.frame.origin.y, bt.frame.size.width, bt.frame.size.height);

    }
    [self.view addSubview:self.topview];
    [self.view bringSubviewToFront:self.topview];
}

- (void)keyboardWillHide:(NSNotification *)notification{
    if ([self IsSeaf]) return;
    self.egoTextView.frame = CGRectMake(self.egoTextView.frame.origin.x, self.egoTextView.frame.origin.y, self.egoTextView.frame.size.width, self.view.bounds.size.height);
    [self.egoTextView becomeFirstResponder];
    [self.topview removeFromSuperview];
}

@end
