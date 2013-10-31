;; document.nu
;;
;; this is the nu extension for the Document class
;; nothing special here


(load "defaults")
(load "console")
(load "guide") 
(load "window")
(load "toolbar")

(set $console ((NuConsoleWindowController alloc) init))

(global document (do ()
                     (NSDocumentController sharedDocumentController 
                                        <- currentDocument )))

(class Document
 (- toggleConsole: sender is
    ($console toggleConsole: self))
 
 (- toggleGuide: sender is
    
    (if helpView.window.isVisible
        (then (helpView showMainPage))
        (else (helpView showMainPage)
              (helpView.window setTitle: "Help")
              (helpView window <- makeKeyAndOrderFront: self))))
 
 (- toggleWindowOnTop: sender is
    
    (if sender.state
        (then (set $oldWindowLevel (editor <- window <- level))
              (editor <- window
                      <- setLevel: 3))
        (else (editor <- window
                      <- setLevel: (if $oldWindowLevel
                                       (then $oldWindowLevel)
                                       (else 0)))))
 )
 
 (- evaluateParser: parser is
    (set job (if self.editor.liveEvaluationEnabled
                 (then self.editor.sourceStorage.parseJob)
                 (else (Nu sharedParser <- parse: self.editor.sourceStorage.string 
                                             for: (set sourceID self.asNuExpression) 
                                           stamp: NSDate.date)
                       (Nu.sharedParser.jobs sourceID))))
    (puts "\n> #{parser.cell.car.nubile}")
    (job prepareForEvaluation)
    (set result (parser evalWithContext: job.context))
    (set result-string (if (send result isKindOfClass: NuCell)
                           (then (+ "\n" (send result nubile)))
                           (else (send result stringValue))))
    (puts "=> #{result-string}")
    ~(self.editor setMessage: result-string)
    (if (send result respondsToSelector: "asNuExpression")
        (self setBackTranslation: NO)
        (self.codeView setString: (send result asNuExpression))
        (self.codeView.sourceStorage splitLinesIn:  self.codeView.sourceStorage.parseJob.rootParser)
        (self.codeView didChangeText))
    (self.editor processChangesInSourceWithEval: NO))
 
 
 (- evalFocusParser: sender is 
    (self evaluateParser: self.editor.focusParser))
 
 (- eval: sender is
    (self evaluateParser: self.editor.sourceStorage.parseJob.rootParser))
 
 (- updateResults: sender is
    (self.editor.sourceStorage.parseJob prepareForEvaluation)
    (self.editor didChangeText))
 
 (- directory is self.fileURL. URLByDeletingLastPathComponent)
 
 (- loadFromHere: filename is
    (Document load: (self.directory URLByAppendingPathComponent: filename))))

