;; editor.nu
;;
;; the main file for all extensions to NuCodeEditor
;; NuCodeEditor should work without it.
;;
;; editor.nu         overrides the callback methods from NSResponder and NuCodeEditor.m
;;                   and calls other modules accordingly
;; utitlities.nu     has some helper methods and sxtensions to standard classes 
;;                   that don't fit anywhere else
;; expressions.nu    holds class extensions for -asNuExpression method
;;      
;; focus.nu          deals with the highlighted parens called "focus parser"
;;                   here are methods for finding smart places for parens and moving them around
;; color.nu          implements a kind of color editor, that pops up, everytime (NSColor ...) is mentioned in the source code
;;
;; completion.nu     deals with auto completion
;;
;; linesplitting.nu  implements an algorithm for splitting lines, used for displaying results in the source code 
;;
;; dragging.nu       implements mecahanism to change the value of numbers by dragging them with the mouse
;;
;; defaults.nu       loads default values for example syntax colors



(global nil '()) ;; somehow nil was missing ...

(load "utilities")
(load "expressions")
(load "focus")
(load "color")
(load "completion")
(load "dragging")
(load "linesplitting")
(load "conversions")

;; a global function, that returns the current active editor
(global editor (do ()
                   (NSDocumentController sharedDocumentController 
                                      <- currentDocument 
                                      <- editor)))

;; class extensions for the NuCodeEditor
;; in this file you find mainly methods that override (or better replace)
;; the methods of NSResponder, which are responsible for handling keyboard events
(class NuCodeEditor
 
 ;; it's difficult to have a class spread between objective c and Nu.
 ;; init calls the setup method which calls this one
 (- setupWithNu is 
    (set @completionTimer nil)
    (set @smartParenInfo nil)
    (set @changeFocusParser YES)
    (set @focusParser nil)
    (set @depth 0)
    (set @dragging nil)
    (set @colorEditingStarted nil)
    (if (self respondsToSelector: "restoreDefaults")
        (self restoreDefaults)))
 
 ;; when delete backward is pressed
 ;; and the cursor is in the indent before the code,
 ;; all the indent gets deleted.
 ;; pressed after the inserteion of a paren pair, 
 ;; all two parens get deleted.
 (- deleteBackward: sender is
    
    (set selection self.selectedRange)
    (cond ((and @hotParen
                (eq self.selectedRange.loc
                    (case (set direction @hotParen)
                          ('left  @focusParser.end)
                          ('right @focusParser.withOffset))))   (set selection (list @focusParser.location 0))
                                                                (self removeHotParenAndCounterPart)
                                                                (if (eq direction 'right)
                                                                    (then (self setSelectedRange: selection))))
          
          ((< 0 selection.len)    (super deleteBackward: sender)) 
          
          (else (set line ((self sourceStorage) lineInfoForLocation:(selection loc)))
                (if (<= line.start: 
                        selection.loc
                        line.code:) 
                    (then (self.sourceStorage.undoManager beginUndoGrouping)
                          (self.sourceStorage replaceCharactersInRange: (list (set deleteStart (max (- line.start: 1) 0)) 
                                                                              (if (< line.code: 
                                                                                     line.end:) 
                                                                                  (then (max (- line.code: deleteStart) 0))
                                                                                  (else (max (- line.end:  deleteStart) 0)))) 
                                                            withString: (if (or (<= (line start:) 2) 
                                                                                (NuObjectParser.endOfAtomCharacters characterIsMember: 
                                                                                                                    (self.string characterAtIndex: (- line.start: 2)))) 
                                                                            (then "") 
                                                                            (else " "))) 
                          (self.sourceStorage.undoManager endUndoGrouping)
                          (self didChangeText))
                    (else (super deleteBackward: sender)
                          (self startCompletionTimer))))))
 
 ;; deleteForward pressed in the indent beofre the code starts in the line or before a newline
 ;; deletes all the indent
 (- deleteForward: sender is
    
    (set selection self.selectedRange)
    (cond 
        
        ((< 0 selection.len) (super deleteForward: sender)) 
        
        (else (set line (self.sourceStorage lineInfoForLocation:(+ 1 (selection loc))))
              (if (<= (line start:) 
                      (+ 1 (selection loc))
                      (line code:)) 
                  (then (self.sourceStorage.undoManager beginUndoGrouping)
                        (self.sourceStorage replaceCharactersInRange: (list (set deleteStart (max (- (line start:) 1) 0)) 
                                                                            (if (< (line code:) 
                                                                                   (line end:)) 
                                                                                (then (max (- (line code:) deleteStart) 0)) 
                                                                                (else (max (- (line end:) deleteStart) 0)))) 
                                                          withString: (if (or (<= (line start:) 2) 
                                                                              ((NuObjectParser endOfAtomCharacters) 
                                                                                  characterIsMember: ((self string) characterAtIndex: (- (line start:) 2))))
                                                                          (then "") 
                                                                          (else " "))) 
                        (self.sourceStorage.undoManager endUndoGrouping)
                        (self didChangeText))
                  (else (super deleteForward: sender))))))
 
 ;; move 
 (- moveRight: sender is
    
    (set selection (self selectedRange))
    (if (< 0 (selection len))
        (then (super moveRight: sender))
        (else (set line ((self sourceStorage) lineInfoForLocation: (+ 1 (selection loc))))
              (if (<= (line start:) 
                      (+ 1 (selection loc))
                      (line code:)) 
                  (then (self setSelectedRange: (list (line code:) 0)))
                  (else (super moveRight: sender))))))
 
 (- moveLeft: sender is
    
    (set selection (self selectedRange))
    (if (< 0 (selection len))
        (then (super moveLeft: sender))
        (else 
            (set line ((self sourceStorage) lineInfoForLocation: (- (selection loc) 1)))
            (if (< (line start:) 
                   (- (selection loc) 1)
                   (line code:)) 
                (then (self setSelectedRange: (list (max (- (line start:) 1) 0) 0)))
                (else (super moveLeft: sender))))))
 
 (- cancel: send is
    
    (if @hotParen
        (then (self removeHotParen))))     
 
 
 
 (set alt   NSAlternateKeyMask)
 (set ctrl  NSControlKeyMask)
 (set cmd   NSCommandKeyMask)
 
 (set right-arrow "\uf703")
 (set left-arrow  "\uf702")
 (set up-arrow    "\uf701")
 (set down-arrow  "\uf700")
 (set delete-key  "\uf728")
 
 (set backspace-key  "\x7f")
 (set deleteChar-key  "\uf73e")
 
 (set key list)
 
 
 (- keyDown: event is
    
    ~(puts "mod #{(getFlags event.modifierFlags)} char #{event.charactersIgnoringModifiers.escapedStringRepresentation}/#{~(event.charactersIgnoringModifiers characterAtIndex:0)} code #{event.keyCode}")
    (if (casex (do (trigger) 
                   (and (eq trigger.car  event.charactersIgnoringModifiers) 
                        (eq  (apply + trigger.cdr) 
                             (& event.modifierFlags 
                                (+ alt ctrl cmd)))))
               
               ((key "#" ctrl)               (self insertText: (+ "#" "{" "}"))
                                             (self moveLeft: self )
                                             NO)
               
               ((key "<" ctrl)               (self insertText: "<>")
                                             (self moveLeft: self )
                                             NO)
               
               ((key "-" ctrl)               (self insertText: "<- ")
                                             NO)
               
               ((key "2" ctrl)               (self changeTextInRange:self.selectedRange 
                                                   replacementString: "\"")
                                             NO)
               
               ((key "8" ctrl)               (if self.smartParensEnabled
                                                 (then (self changeTextInRange:self.selectedRange 
                                                             replacementString: "("))
                                                 (else (self tryInsertingSmartParensFor: "(" 
                                                                                     at: self.selectedRange.loc)))
                                             NO)
               ((key "9" ctrl)               (if self.smartParensEnabled
                                                 (then (self changeTextInRange:self.selectedRange 
                                                             replacementString: ")"))
                                                 (else (self tryInsertingSmartParensFor: ")" 
                                                                                     at: self.selectedRange.loc)))
                                             NO)
               
               ((key "d" cmd)                (self setSelectedRange: @focusParser.range)
                                             NO)
               
               ((key "s" ctrl)                (self convertStringIn: @focusParser) NO)
               
               ((key right-arrow cmd)        (self setSelectedRange: (list @focusParser.end 0))
                                             NO)
               ((key left-arrow cmd)         (self setSelectedRange: (list @focusParser.withOffset 0))
                                             NO)
               ((key right-arrow alt cmd)    (if @hotParen
                                                 (then (self moveHotParen: 'right))
                                                 (else (self changeHotParenTo: 'right))
                                                 
                                                 NO))
               ((key left-arrow alt cmd)     (if @hotParen
                                                 (then (self moveHotParen: 'left))
                                                 (else (self changeHotParenTo: 'left)))
                                             NO)
               ((key down-arrow alt cmd)     (self setFocusParserFor: self.selectedRange depth: (+ @depth 1))
                                             NO)
               ((key up-arrow alt cmd)       (self setFocusParserFor: self.selectedRange depth: (- @depth 1))
                                             NO)
               ((key "-" alt cmd)            (if @hotParen
                                                 (then (self changeHotParenTo:  (flip-direction @hotParen)))
                                                 (else (self changeHotParenTo: 'right))))
               ((key backspace-key alt cmd)     (if @focusParser
                                                    (self removeParensOf: @focusParser)))
               
               (else             YES))
        (then (if (eq event.keyCode 10)
                  (then (self insertText: "^"))
                  (else (super keyDown: event))))))
 
 
 (- setMessageForLocation: location is
    
    ~(puts "message for: #{location}")
    (if (and (>= location 0)
             (< location (apply + self.sourceStorage.range ))
             (set message (self.sourceStorage attribute: "NSToolTip" atIndex: location effectiveRange: nil)))
        (then (self setMessage: message))
        (else (self setMessage: "")))
 )
 
 (- mouseMoved: event is
    ~(puts (list (set point event.locationInWindow)
                 (set converted (self convertPoint: point fromView: nil))
                 (self characterIndexForInsertionAtPoint: converted)))
    (set mouseLocation (self characterIndexForInsertionAtPoint: (self convertPoint: event.locationInWindow fromView: nil)))
    (self setMessageForLocation: mouseLocation)
    (super mouseMoved: event)
 )
 
 
 (- processChangesInRange: range
                   string: string is
    
    (if (self.replaceTabs)
        (then (set string (string stringByReplacingOccurrencesOfString:"\t" 
                                                            withString:(NuSourceStorage spaces:self.tabLength)))))
    
    (if (and self.smartParensEnabled
             (eq string "\""))
        (self insertText: "\"\"")
        (self moveLeft: self)
        (return nil))
    
    ;; to avoid headaches for < and long Symbols:
    (if (and self.smartParensEnabled
             (eq string "<")
             (NuObjectParser.nonWhiteSpaces characterIsMember:(self.sourceStorage.parseJob characterAt: range.loc)))
        (self insertText: "< ")
        (self moveLeft: self)
        (return nil))
    
    (if (eq string.length 1) 
        (then (set thisChar (string characterAtIndex:0))
              (set nextChar (if (>= range.loc self.sourceStorage.length)
                                (then nil)   
                                (else (self.sourceStorage.string characterAtIndex: range.loc))))
              (if (and (not (NuObjectParser.endOfAtomCharacters characterIsMember:thisChar))
                       (or  (not nextChar)
                            (NuObjectParser.endOfAtomCharacters characterIsMember:nextChar)))
                  (then (self startCompletionTimer)))))
    
    (cond ((and self.smartParensEnabled
                (self tryInsertingSmartParensFor: string at: range.loc)) 
              nil)
          
          (else string)))
 
 
 ;; does all the curosr related highlighting stuff
 (- cursorRelatedColoringFor: parser is
    (if (and parser
             (ne parser parser.root))
        (self removeBackgroundColors)
        (if self.focusShadingEnabled
            (then (self shadeFocusFor:parser)))
        (if self.depthColoringEnabled
            (then (self colorDescendantsOf: (if self.focusShadingEnabled
                                                (then parser)  
                                                (else parser.root)))))
        (if self.uncolorIndentationEnabled
            (then (self whiteIndentationFor: (if (and self.depthColoringEnabled
                                                      self.focusShadingEnabled)  
                                                 (then parser)  
                                                 (else parser.root)))))
        (if self.parensHighlightingEnabled
            (then (self highlightParensFor:parser hotParen: @hotParen)))))
 
 (- cursorRelatedColoring is (self cursorRelatedColoringFor:@focusParser))
 
 
 ;; gets called after the selection has changed 
 (- selectionDidChangeTo: charRange is 
    
    ~(puts "selection #{charRange} -- #{@hotParen}")
    (if (eq charRange.len 0)
        (then (set @focusLocation charRange.loc)
              (self setMessageForLocation: (- @focusLocation 1))
              ~(puts "changeFocus #{@changeFocusParser}")
              (if @changeFocusParser 
                  (then (self setFocusParserFor: charRange)))))
    (self scrollRangeToVisible:charRange)
 )
 
)
