//
//  Editor.h
//  Nu
//
//  Created by Heiko Henrich on 06.06.13.
//
//

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*!
    This is the base class for the editor and should work together with the Parser files.
    It introduces sublcasses to NSTextstorage and NSTextView
    adjusted for the needs of a Nu Code Editor.
    the main functionalities are:
    - a proper undo mechanism, which works with programmatical text changes
    - syntax highlighting
    - auto indentation
    - error highlighting
    - various code coloring experiments
    - insertions of evaluation results into the code
    other functionalities are implemented as class extensions of NuCode Editor in seperate Nu files.
    (see editor.nu)
    these extenisons include:
    - a basic autocompletion mechanism (completion.nu)
    - dealing with parentheses to ease editing (focus.nu)
    - a color editor, a demo for the possibilities of context sensitive special editors
 
    The NuCodeEditor class is the main class and just a NSTextView that can be used (with limitations), 
    where NSTextView is used.
    It can be used as a custom class in Interfacebuilder,
    just drag in a NSTextView and set NuCodeEditor as cusotm class.
    Everything else (including NuSourceStorage, Parser etc.) will be setup automatically.
 
    The functionality of the editor is split between 
    NuCodeEditor, NuCodeStorage, NuParseJob and the various NuObjectParser subclasses,
    as different levels of abstraction.
    I somehow mixed up the MVC-pattern. But Apple wasn't clear with that by itself.
    I didn't implement a special Controller class, since I think, 
    NSTextView serves as a controller by itself, and has it's own model and view side classes.
    I put everything related to an actual view or user input in NuCodeEditor,
    Everything more related to the model layer in NuCodeStorage.
    It is put that way (though not tested yet), 
    that more than one NuCodeEditor can use a single NuCodeStorage  class.
    In contrast to Apple I put the undo manager into the NuCodeStorage, where I think 
    an undo manager belongs.
    The original undo manager of NSTextView does not work with programmatic changes.
    NSUndoManager was also kind of picky and complaining without reason,
    so after a lot of trouble, I ended up with in reimplementation of NSUndomanager by Graham Cox:
    (https://github.com/seanm/gcundomanager)
    Every programmatic and user input related change gets now caught
    by replaceCharactersInRange:(NSRange)range withString:(NSString *)string.
    So undo should work fine most of the time.
    If there are a lot of changes which should be coalesced (like in color.nu)
    don't forget to  begin and end undo grouping.
 
    What's not done yet:
    -   a separation between the "editor parser" and an "evaluation parser":
        the editor parser should just be responsible for syntax highlighting,
        indentation and all view related stuff.
        the evaluation parses the edited changes simultaeously,
        without bothering indentation, but doing all the evaluation and debugging stuff.
        since Parser.h/m should run on IOS, this parser could be remote.
    -   a kind of plugin interface, something which makes it easy to write extensions
        and adjustments in Nu.
    -   an interface for a kind of context editor, something color.nu does:
        these editors pop up, when the cursor is in a cell that evaluates to a certain obect (like NSColor in color.nu)
        So one could implement code generating editors for eg. CGPaths, HTML code,
        NSFonts (that's easy), gradients, even user interfaces Menus are possible.
    -   the editor is just a part of an IDE.
        I imagine an IDE, where large text files aren't the main building blocks of Programs,
        but small junks of code, like one method or function.
        These chunks could be organized by tags and stored in a database.
        one single chunk could have different tags, like one for the class, one for a certain implemented functionality,
        and one for a method, that's implemented differently in different classes.
        It's easy to put multiple NuCodeEditors in a NSTableView with the possibility to 
        enclose or disclose them. (I've done this in a previous prototype).
        This, in connection with different tabs (each for one tag) and a smalltalk like class browser
        could be an alternative way to organize source code.
        But: That's a lot of work.
*/
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#import <Cocoa/Cocoa.h>
#import "GCUndoManager.h"
#import "Parser.h"

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*! The built in Undomanager in NSTextview ins't really open for programmatic changes
    Besides that, I thought, that the Undomanager has to be on the model side/level of the component,
    that means integrated in the textstorage */
@interface TextStorageUndoManager : GCUndoManager

@property (nonatomic) double groupingTime;
- (void)groupByIdleTime;
- (void) groupForSure;
@end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*! This is a subclass of NSTextstorage for Nu source code
    It has its own undo manager,
    is responsible for parsing and updating the code 
    processes automatic indentation if desired,
    and does syntax coloring and error highlighting,
    so basically everything, what can be done, when the test storage is
    used with multiple views (what should be possible)*/
@interface NuSourceStorage : NSTextStorage

/*! if not set by the user, parsejob is setup automatically, which is recommended */
@property (strong) NuParseJob *parseJob;
@property ( nonatomic, readonly)NSDictionary *defaultAttributes;
@property (strong, nonatomic)NSFont *defaultFont;
@property (nonatomic) CGFloat fontSize;
@property (strong, nonatomic) TextStorageUndoManager *undoManager;


/*! could be extended or replaced with your own colors */
@property NSDictionary *syntaxColorDictionary;

@property NSMutableOrderedSet *resultParserSetToUpdate;
@property NSMutableArray *currentEvaluationErrors;

/*! does not work properly */
//- (id) initWithCoder:(NSCoder *)aDecoder;

/*! designated initializer */
//- (id)initWithString:(NSString *)str attributes:(NSDictionary *)attrs;
//- (id) initWithString:(NSString *)str;

/*! use just this one  for now*/
- (id)init;

/*! to be overridden by  Nu to setup defaults */
- (void) restoreDefaults;

//- (id) initWithParseJob: (NuParseJob *) parseJob;

- (NSRange) range;

/*! Does syntax highlighting, if ehighlightErrors == YES,
    then errors get highlighted too */
- (void) processSyntaxHighlightingWithErrors: (BOOL) highlightErrors;
- (void) removeSyntaxHighlighting;
- (void) removeErrorMarks;

/*! implemented in linesplitting.nu */
- (void) splitLinesIn: (NuObjectParser *) parser;

/*! Reads the indent chages made in the parse job and inserts and deletes spaces where necessary */
- (void) processIndentDeltas;


- (void) updateResult: (NSNotification *) notification;
- (void)processResults;

/*! returns a dictionary with information about the current line */
- (NSDictionary *) lineInfoForLine: (NSInteger) line;


/*! returns a dictionary with information about the current line where location is in */
- (NSDictionary *) lineInfoForLocation: (NSInteger) location;

/*! this method should be used for all programmatic changes 
    it's (contrasting to the superclass) connected with an undo manager,
    and updates the code tree automatically, which results in information for syntax highlighting 
    errors, indentation and much more. 
    The code is not parsed as a whole,instead there are just the changed parts updated in the code tree.
    This has two advantages:
    - It's fast, so even huge files can be highlighted, analyzed and indented instantanously.
    - And it allows for changing executing code live (see "bret victor inventing on principle").
      But since we are dealing with real Objective C-Objects not JavaScript, be warned, it's dangerous!
    Btw. according to documentation changes should be surrounded by beginEditing and endEditing */
- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string;

/*! the readonly string of the current source */
- (NSString *)string;

@end


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*! This is the main component of the editor, the subclass of NSTextview
    The class acts as controller too, since the boundaries between view and controller 
    in NSTextview aren't clear anywa. If you take a closer look, NSLayoutmanager in conjunction with
    NSTextcontainer acts as the view, and the NSTextview class has more a controller like functionality, I think.
    Anyway. 
    NuCodeEditor is does all the cursor related stuff,
    there are some experiments with coloring.
    This class waits to be extended with Nu, which I started in the 3 files editor.nu, smarparens.nu and complete.nu.
    Espescally all the NSRespondermethods like to be overridden!
    You can connect every property with bindings from interface builder.
    The view itself can be used as a component in IB.*/
@interface NuCodeEditor : NSTextView 

/*! this NSTextview sublcass can just work together with this subclass of NSTextstorage */
@property (nonatomic) NuSourceStorage *sourceStorage;

/*! of set YES all tabs will be converted to spaces when inserted 
    needed for proper aut indent. Default = YES.*/
@property (nonatomic) BOOL replaceTabs;

/*! The length fo th tab replacement */
@property (nonatomic) NSInteger tabLength;

/*! if set YES, the source code gets automatically indented. default = YES*/
@property (nonatomic) BOOL autoIndentEnabled;

/*! turns syntax highlighting on. default YES */
@property (nonatomic) BOOL syntaxHighlightingEnabled;

/*! turns hoghlighting of the current parens on. default YES */
@property (nonatomic) BOOL parensHighlightingEnabled;

/*! turns the highlighting (in fact underlining) of possible errors on */
@property (nonatomic) BOOL errorHighlightingEnabled;

/*! if YES the current edited list stays white and all lists in deeper levels get more and more gray */
@property (nonatomic) BOOL focusShadingEnabled;

/*! colors all levels in the code with different background colors. default NO */
@property (nonatomic) BOOL depthColoringEnabled;
@property (nonatomic) CGFloat levelColorSaturation;
@property (nonatomic) NSInteger levelColorSteps;
@property (nonatomic) NSInteger levelColorOffset;
@property (nonatomic) BOOL uncolorIndentationEnabled;

/*! implemented in completion.nu */
@property (nonatomic) BOOL autoCompletionEnabled;

/*! implemented in smartparens.nu */
@property (nonatomic) BOOL smartParensEnabled;

@property (nonatomic) BOOL numberDraggingEnabled;
@property (nonatomic) BOOL contextEditorsEnabled;

/*! the standard indentation, when the second item of a list is in a new line 
    for sliders a float, gets rounded of course. */
@property (nonatomic) CGFloat cdarIndent;

/*! variable font size. can be used by a slider */
@property (nonatomic) CGFloat fontSize;

/*! the list parser where the insertion mark is.
    coloring  is done accordingly.
    can be changed programmatically */
@property (nonatomic) NuListParser *currentListParser;

/*! if YES, the source gets parsed with the strict Nu parsing rules 
    if (by default) No, you get some extensions like dot notation indentable herestrings
    message chains. look into the parser.*/
@property (nonatomic) BOOL legacyParserEnabled;

/*! if YES, the parsed code in root gets evaluated, when eval is pressed
    other wise, the source is parsed seperately and then evaluated
    Live Evaluation means, that changes in code have an immediate effect
    without having it to reevaluate again.
    But - it's dangerous. */
@property (nonatomic) BOOL liveEvaluationEnabled;

/*! message for displaying context related infomration like errors on mouse over etc. 
    could be boud to a NSTextField or so */
@property (nonatomic) NSMutableString *message;

/*! for programmatical setup this should work */
+ newWithFrame:(NSRect)frameRect sourceStorage: (NuSourceStorage *) sourceStorage;

/*! designated initializer, needs layoutmanager, texcontainer and textstorage to be created */
- (id)initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer *)container;

/*! used by IB, sets up its own NuSourceStorage */
- (id)initWithCoder:(NSCoder *)aDecoder;


/*! processes all highlighting and indentation stuff after a text change */
- (void)didChangeText;

/*! should surround changes in text storage */
- (void) beginEditing;
- (void) endEditing;

/*! interface for programmatic text changes 
    for convenience. beginEditing and endEditing get called automatcally */
- (void) changeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)string;


- (IBAction)undo:(id)sender;
- (IBAction)redo:(id)sender;


/*! to be overridden by editor.nu
    can return a possibly changed string 
    gets called before the text gets changed. */
- (NSString *) processChangesInRange: (NSRange) affectedCharRange string: (NSString *)string ;

/*! to be overridden by editor.nu
    can return a possibly changed location
    gets called before the change */
- (NSRange) selectionShouldChange: (NSRange)charRange;

/*! gets called after the change */
- (void) selectionDidChangeTo: (NSRange) range;


@end
