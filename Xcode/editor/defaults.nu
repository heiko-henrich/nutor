;; defaults.nu
;;
;; adjust the default values as you like.
;; a real preferences pane would be preferable, ...

;; if you'd like to change the syntax coloring do it here:
;; you can try it out in the syntax color demo.
(set $currentSyntaxColorDictionary 
     (dict number: (NSColor colorWithCalibratedRed: 0 green: 1 blue: 0 alpha: 1)
           symbol: (NSColor colorWithCalibratedRed: 0.33 green: 0.5 blue: 0.2 alpha: 1)
           object: (NSColor colorWithCalibratedRed: 0.5 green: 0.2 blue: 0.6 alpha: 1)
        character: (NSColor colorWithCalibratedRed: 1 green: 0 blue: 0 alpha: 1)
           string: (NSColor colorWithCalibratedRed: 0.8 green: 0 blue: 0 alpha: 1)
         operator: (NSColor colorWithCalibratedRed: 0 green: 0 blue: 1 alpha: 1)
            label: (NSColor colorWithCalibratedRed: 0.6 green: 0.4 blue: 0.2 alpha: 1)
            macro: (NSColor colorWithCalibratedRed: 1 green: 0.5 blue: 0 alpha: 1)
            regex: (NSColor colorWithCalibratedRed: 0.9 green: 0.06 blue: 0.8 alpha: 1) ))

;; this is for backup the original syntax coloring
;; just copy and pase it back
~(set $currentSyntaxColorDictionary 
      (dict number: (NSColor colorWithCalibratedRed: 0 green: 1 blue: 0 alpha: 1)
            symbol: (NSColor colorWithCalibratedRed: 0.33 green: 0.5 blue: 0.2 alpha: 1)
            object: (NSColor colorWithCalibratedRed: 0.5 green: 0.2 blue: 0.6 alpha: 1)
         character: (NSColor colorWithCalibratedRed: 1 green: 0 blue: 0 alpha: 1)
            string: (NSColor colorWithCalibratedRed: 0.8 green: 0 blue: 0 alpha: 1)
          operator: (NSColor colorWithCalibratedRed: 0 green: 0 blue: 1 alpha: 1)
             label: (NSColor colorWithCalibratedRed: 0.6 green: 0.4 blue: 0.2 alpha: 1)
             macro: (NSColor colorWithCalibratedRed: 1 green: 0.5 blue: 0 alpha: 1)
             regex: (NSColor colorWithCalibratedRed: 0.9 green: 0.06 blue: 0.8 alpha: 1) ))

(class NuSourceStorage 
 (- restoreDefaults is
    (if $currentSyntaxColorDictionary
        (self set: (syntaxColorDictionary: $currentSyntaxColorDictionary)))
    (self set: (fontSize: 11))
    
 ))

(class NuCodeEditor
 (- restoreDefaults is
    (self set: (numberDraggingEnabled: NO
                liveEvaluationEnabled: YES
                    autoIndentEnabled: YES
                autoCompletionEnabled: YES
            syntaxHighlightingEnabled: YES
            parensHighlightingEnabled: YES 
             errorHighlightingEnabled: YES
                  focusShadingEnabled: NO
                 depthColoringEnabled: NO
                   smartParensEnabled: YES
                contextEditorsEnabled: NO
                  legacyParserEnabled: NO
                           cdarIndent: 3.0
               ))))

(class Document
 (- restoreDefaults is
    (self customizeToolbar)
    (self set: (backTranslationEnabled: NO 
                assistantEditorEnabled: NO
                autosaveForRealEnabled: NO
               ))
    ;; not good, should be an instance variable.
    (NSDocumentController sharedDocumentController
                       <- setAutosavingDelay: 15.0)))





