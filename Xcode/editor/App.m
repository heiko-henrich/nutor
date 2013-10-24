//
//  NutorAppDelegate.m
//  Nu
//
//  Created by Heiko Henrich on 13.07.13.
//
//

#import "App.h"
#import "Parser.h"

@implementation NutorAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NuInit();
    [[[NuSymbolTable sharedSymbolTable] symbolWithString:@"parse"] setValue:[[Nu_alt_parse_operator alloc] init]];
    NuParser *parser = [Nu sharedParser];
    [[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInt: 50]
                                              forKey: @"NSInitialToolTipDelay"];
    [[NSDocumentController sharedDocumentController] setAutosavingDelay:10.0];
    
    [parser parseEval:@"(load \"nu\")"];
    [parser setValue:@(NSNotFound) forKey:@"NSNotFound"];
    [parser parseEval:@"(load \"nubile\")"];
    [parser parseEval:@"(load \"document\")"];
    [parser parseEval:@"(load \"editor\")"];
    
    //[NSApp activateIgnoringOtherApps:YES];
    //[[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    //[[NSDocumentController sharedDocumentController] newDocument:self];
}


@end
