//
//  Document.h
//  NuEditor
//
//  Created by Heiko Henrich on 13.07.13.
//
//

#import <Cocoa/Cocoa.h>
#import "Editor.h"

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*! 
    This is a Demo for NuCodeEditor class
    It's just to show off more or less useful features implemented by now.
    A real editor/IDE for Nu should be different in my opinion.
    NuCodeEditor is just one building block.
    But what's nice anyway is to use the convenient NSDocument features, which go beyond
    XCode, when it comes  to eg. restore or compare previous versions of different files.
 */
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface NutorSplitView : NSSplitView
@property (nonatomic) BOOL secondViewHidden;

- (void)showSecondPane;
- (void) hideSecondPane;

@end


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*!
    The document class.
    There is no WinodControllerClass, so a lot off such stuff is now here.
*/
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface Document : NSDocument <NSTextDelegate, NSSplitViewDelegate>

@property (unsafe_unretained) IBOutlet NuCodeEditor *editor;
@property (unsafe_unretained) IBOutlet NuCodeEditor *codeView;
@property (nonatomic) BOOL backTranslationEnabled;
@property (nonatomic) BOOL assistantEditorEnabled;
@property (nonatomic) BOOL autosaveForRealEnabled;
@property (weak) IBOutlet NutorSplitView *splitView;
@property (weak) IBOutlet NSView *leftSplitView;
@property (weak) IBOutlet NSView *rightSplitView;
@property (unsafe_unretained) IBOutlet NSTextView *messageView;
@property (weak) IBOutlet NSToolbar *toolbar;

- (IBAction)eval:(id)sender;
- (IBAction)reparse:(id)sender;
- (IBAction)toggleAssistantEditor:(id)sender;
- (IBAction)toggleConsole:(id)sender;
- (IBAction)toggleGuide:(id)sender;
- (IBAction)evalFocusParser:(id)sender;
- (IBAction)updateResults:(id)sender;
- (IBAction)toggleWindowOnTop:(id)sender;
- (IBAction)performFindPanelAction:(id)sender;
- (IBAction)toggleOptionsDrawer:(id)sender;
/*! to be overridden */
- (IBAction)undoSegmentedControlAction:(id)sender;
- (void) restoreDefaults;
- (IBAction)customToolbarAction1:(id)sender;
- (IBAction)customToolbarAction2:(id)sender;
- (IBAction)customToolbarAction3:(id)sender;
- (IBAction)customToolbarAction4:(id)sender;
- (IBAction)customToolbarAction5:(id)sender;
- (IBAction)customToolbarAction6:(id)sender;
- (IBAction)customToolbarAction7:(id)sender;
- (IBAction)customToolbarAction8:(id)sender;
@property (weak) IBOutlet NSToolbarItem *customToolbarItem1;
@property (weak) IBOutlet NSToolbarItem *customToolbarItem2;
@property (weak) IBOutlet NSToolbarItem *customToolbarItem3;
@property (weak) IBOutlet NSToolbarItem *customToolbarItem4;
@property (weak) IBOutlet NSToolbarItem *customToolbarItem5;
@property (weak) IBOutlet NSToolbarItem *customToolbarItem6;
@property (weak) IBOutlet NSToolbarItem *customToolbarItem7;
@property (weak) IBOutlet NSToolbarItem *customToolbarItem8;



@end
