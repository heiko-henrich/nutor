;; focus.nu
;;
;; the goal is to type in as less parens as possible and 
;; (to unburden the parsing) to have always a matching paren at hand.
;; there are several possibilities:
;; - smart parens add a matching second paren at the end or beginning of a list 
;;   or after the first or last item in a list.
;;   there are several possibilities to revert such an addittion:
;;   escape removes just the additional paren (marked red)
;;   backspace deletes the two new parens
;;   and then there is still undo ...
;; - then there is the possibility to move a so called hot paren (which is marked red)
;;   in order to extend or shorten a list by including neighbouring items.
;;   the hot paren is always coupled with the focusparser,
;;   which is the list parser where currently the insertion point is. 
;;   this focus parser can alos be extended to the enclosing list ...

(load "beautifier")
(load "nubile")

;; extensions to the NuListParser class for managing smart parens
(class NuListParser
 
 ;; finds the first childparser of the given line
 (- firstChildInLine:line is
    (set current self.lastChild)
    (set firstChildInLine nil)
    (while current
           (cond ((> current.line line)     (set current current.previous))
                 ((eq current.endLine line) (set firstChildInLine current)
                                            (set current current.previous))
                 (else                      (set current nil))))
    firstChildInLine)
 
 ;; finds the last childparser of the given line
 (- lastChildInLine: line is
    
    (set current self.lastChild)
    (set lastChildInLine nil)
    (while current
           (cond ((> current.line line)  (set current current.previous))
                 ((eq current.line line) (set lastChildInLine current)
                                         (set current nil))
                 (else                   (set current nil))))
    lastChildInLine)
 
 ;; returns the most convenient location of an corrosponding left hand paren (or what ever)
 ;; for a possibly to be inserted paren at location
 ;; returns NSNotFound if there is a string going on
 ;; the returned location will be the start of the first item 
 ;; of the current list in the current line
 (- smartLeftParenForParenAt: location is
    
    (set child (self childContaining: location))
    (cond ((child isKindOfClass: (NuListParser class)) 
              (child smartLeftParenForParenAt: location))
          
          ((or (child isKindOfClass: (NuStringParser class))
               (child isKindOfClass: (NuRegexParser class))
               ~(self.root.job commentAtLocation: location)
               ~(self ignoredParserAt: location)) 
              nil)
          
          (else (set line (self.root.job.lineInfo lineAt: location))
                (if (eq line self.line)
                    (then self.withOffset)
                    (else (if (set firstChildInLine (self firstChildInLine:line))
                              (then (min firstChildInLine.location location))
                              (else location)))))))
 
 ;; returns the most convenient location of an corrosponding right hand paren (or what ever)
 ;; for a possibly to be inserted paren at location
 ;; returns nil if there is a string going on
 ;; the returned location will be the first the endd of the lastChild item 
 ;; of the current list in the current line
 (- smartRightParenForParenAt: location is
    
    (set child (self childContaining: location))
    (cond ((child isKindOfClass: (NuListParser class)) 
              (child smartRightParenForParenAt: location))
          
          ((or (child isKindOfClass: (NuStringParser class))
               (child isKindOfClass: (NuRegexParser class))
               ~(self.root.job commentAtLocation: location)
               ~(self ignoredParserAt: location)) 
              nil)
          
          (else (set line (self.root.job.lineInfo lineAt: location))
                (if (eq line self.endLine)
                    (then (if self.lastChild
                              (then (if (self.lastChild isKindOfClass: (NuEndOfListParser class))
                                        (then self.lastChild.location)
                                        (else self.lastChild.end)))
                              (else location)))
                    (else (if (set lastChildInLine (self lastChildInLine:line))
                              (then (max lastChildInLine.end location))
                              (else location)))))))
 
 ;; if you'd move a parent to the left by delta (+ or -) places, 
 ;; this method proposes the correct location 
 (- proposedLeftParenLocationForChangeBy: delta is
    
    (if (set parser (cond ((< delta 0)  (set cursor self)
                                        (while (and (set cursor cursor.previous)
                                                    (> 0 (set delta (+ delta 1))))
                                               (puts "cursor #{cursor.description} delta #{delta}"))
                                        cursor)
                          
                          ((> delta 0)  (self childNr: delta))
                          
                          (else nil)))
        (then parser.location)
        (else nil)))
 
 
 ;; if you'd move a parent to the right  by delta places, 
 ;; this method proposes the correct location 
 (- proposedRightParenLocationForChangeBy: delta is
    
    (set parser (cond ((< delta 0)  (set cursor self.lastChild)
                                    (while (and (set cursor cursor.previous)
                                                (>= 0 (set delta (+ delta 1)))))
                                    cursor)
                      
                      ((> delta 0)  (self.parent childNr: (+ self.positionInList delta)))
                      
                      (else nil)))
    (if parser
        (then (if (parser isKindOfClass: (NuEndOfFileParser class))
                  (then parser.previous.end)
                  (else parser.end)))
        (else self.withOffset)))
 
 ;; returns the range of the 'right or the 'left paren of the current list
 (- parenRange: direction is
    
    (case direction
          ('right self.rightParenRange)
          ('left  self.leftParenRange)
          (else   nil)))
 
 
 ;; if the actual range of a paren is too short to color make something up
 (- fakeParenRange: direction is
    
    ~(puts "fakeparenrange for #{self} -- #{direction} ")
    (if (eq ((set range (self parenRange: direction)) len) 0)
        (then (range changedBy: 1 direction: (flip-direction direction)))
        (else range))))


;; extensions to NuParseJob for smart parens
(class NuParseJob
 
 ;; convenience method for finding 'right and 'left hand smart paren 
 (- smartParen: direction forParenAt: location is
    (case direction
          ('left  (self.rootParser smartLeftParenForParenAt: location))
          ('right (self.rootParser smartRightParenForParenAt:location)))))


(class NuCodeEditor 
 
 ;; puts parens, brackets etc. around an area in the source and returns the new generated parser
 (- newItemWithLeftParen: leftParen at: leftLocation rightParen: rightParen at: rightLocation is 
    
    (set range  (list leftLocation (- rightLocation leftLocation)))
    (set stringToReplace (self.sourceStorage.string substringWithRange: range))
    (set stringToInsert (+ leftParen stringToReplace rightParen))
    (self beginEditing)
    (self.sourceStorage replaceCharactersInRange: range withString: stringToInsert)
    (set parser (self.sourceStorage.parseJob.rootParser parserAt: range.loc))
    (if (ne parser.location
            range.loc)
        ;; this means, it looks like there is no new parser created
        ;; and the returned parser is secondomething else
        (set parser nil))
    (self endEditing)
    parser)
 
 
 
 ;; moves  a 'right or 'left paren of a given parser by delta items, 
 ;; whereby delta > 0 means to the right.
 ;; returns the maybe new created parser
 (- moveParen: paren of: parser by: delta is
    ~(puts "moveParen: #{paren} of #{parser.description } by: #{delta}")
    (if (and parser
             (parser isKindOfClass: NuListParser.class)
             (set parenRange (case paren
                                   ('right (set newLocation (parser proposedRightParenLocationForChangeBy: delta))
                                           (if (not (null? newLocation))
                                               (then parser.rightParenRange)
                                               (else nil)))
                                   ('left  (set newLocation (parser proposedLeftParenLocationForChangeBy:  delta))
                                           (if (not (null? newLocation))
                                               (then  parser.leftParenRange) 
                                               (else nil))))))
        (then (set parenString (self.sourceStorage.string substringWithRange: parenRange))
              (set parenEnd (apply + parenRange))
              (if (cond ((< parenRange.loc 
                            newLocation)     (set restString (self.sourceStorage.string substringWithRange: (list parenEnd
                                                                                                                  (- newLocation parenEnd))))
                                             (set replacedRange (list parenRange.loc
                                                                      (- newLocation parenRange.loc)))
                                             (set stringToInsert (+ restString parenString))
                                             (set movedTo 'right)
                                             YES)
                        
                        ((< newLocation
                            parenRange.loc)  (set restString (self.sourceStorage.string substringWithRange: (list newLocation
                                                                                                                  (- parenRange.loc newLocation))))
                                             (set replacedRange (list newLocation
                                                                      (- parenEnd newLocation)))
                                             (set stringToInsert (+ parenString restString))
                                             (set movedTo 'left)
                                             YES)
                        
                        (else                NO))
                  
                  (then 
                      ~(puts "--#{restString}--#{replacedRange}--#{stringToInsert}--#{movedTo}")
                      (self.sourceStorage replaceCharactersInRange: replacedRange withString: stringToInsert)
                      
                      
                      (self.sourceStorage.parseJob.rootParser parserAt: 
                                                              (case paren
                                                                    ('right parser.location)
                                                                    ('left (case movedTo
                                                                                 ('right (+ parser.location 
                                                                                            restString.length))
                                                                                 ('left  newLocation))))))
                  (else parser)))
        (else parser)))
 
 
 ;; removes the parens of a list
 (- removeParensOf: parser is
    (self changeTextInRange: parser.range 
          replacementString:  (self.sourceStorage.string substringFrom: parser.leftParenRange.end 
                                                                    to: parser.rightParenRange.loc)))
 
 ;; deletes the current hot paren (marked red)
 (- removeHotParen is
    (if @hotParen
        (then (self beginEditing)
              (self replaceCharactersInRange: (@focusParser parenRange: @hotParen) withString:"")
              (set @hotParen nil)
              (self endEditing))))
 
 ;; deletes the current paren pair of the focus parser list
 (- removeHotParenAndCounterPart is
    (if @hotParen 
        (set @hotParen nil)
        (self removeParensOf: @focusParser)))
 
 ;; self explaining
 (function matchingParen (paren)
     (case paren
           ("("  '(right ")"))
           (")"  '(left  "("))
           ("["  '(right "]"))
           ("]"  '(left  "["))
           ("{"  '(right "}"))
           ("}"  '(left  "{"))
           (else nil)))
 
 
 ;; inserts a paren at location plus a matching counter part into the source
 (- tryInsertingSmartParensFor: parenString 
                            at: location is
    
    (if (set counterPart (matchingParen parenString))
        (then (set counterLoc (self.sourceStorage.parseJob smartParen: counterPart.first 
                                                           forParenAt: location))
              (unless (null? counterLoc)
                      (then (set parser (case (set @hotParen counterPart.first) 
                                              ('right (self newItemWithLeftParen: parenString
                                                                              at: location 
                                                                      rightParen: counterPart.second 
                                                                              at: counterLoc))
                                              ('left  (self newItemWithLeftParen: counterPart.second
                                                                              at: counterLoc
                                                                      rightParen: parenString 
                                                                              at: location)))) 
                            (if parser
                                (then 
                                    (self replaceFocusParserWith: parser)
                                    
                                    (self setSelectedRange: (list (case counterPart.first
                                                                        ('left  @focusParser.end)
                                                                        ('right @focusParser.withOffset))
                                                                  0)))
                                ;; just a workaround if there is no new parser created
                                (else (self moveLeft: self)))
                            
                            YES)
                      (else (self changeHotParenTo: nil)
                            NO)))
        (else (self changeHotParenTo: nil)
              NO)))
 
 
 
 ;; moves the red marked "hot paren" to the 'left or to the 'right
 (- moveHotParen: direction is
    
    (if (and @hotParen
             (hotParenParser? @focusParser)) 
        (then (set selection self.selectedRange)
              (self beginEditing)
              (set parser (self moveParen: @hotParen
                                       of: @focusParser
                                       by: (case direction
                                                 ('right 1)
                                                 ('left -1))))
              (self endEditing)
              (set @focusParser parser)
              (if (eq @hotParen 'right)
                  ;; looks weired, but works
                  (then (set newSelection selection))
                  (else (set newSelection self.selectedRange)))
              (self setSelectedRangeKeepingFocusParser: (list (cond  ((> newSelection.loc parser.end)         parser.end)
                                                                     ((< newSelection.loc parser.withOffset) parser.withOffset)
                                                                     (else                                          newSelection.loc))
                                                              0))
              
              (self cursorRelatedColoringFor:@focusParser)
        )))
 
 ;; changes the current hot paren to 'left, 'right or nil
 (- changeHotParenTo: paren is
    ~(puts "hotparen change #{@hotParen} to #{paren}")
    (cond (not (hotParenParser? @focusParser))
          (set @hotParen nil))
    (if  (and (ne @hotParen paren)
              (ne 0 (@focusParser parenRange: paren <- loc)))
         (set @hotParen paren)
         (self cursorRelatedColoringFor: @focusParser)))
 
 ;; setting the selected range changes the focus parser 
 ;; this method  circumvents this behaviour
 (- setSelectedRangeKeepingFocusParser: charRange is
    (set @changeFocusParser NO)
    (self setSelectedRange: charRange)
    (set @changeFocusParser YES))
 
 ;; self explaining
 (- setFocusParserFor: charRange is
    
    (self setFocusParserFor: charRange depth: 0))
 
 ;; sets the focus parser for an range and gives the possibility, to selct a deeper level,
 ;; which is remembered by @depth
 (- setFocusParserFor: charRange depth: depth is
    
    ~(puts "focus range: #{charRange} --- #{depth}")
    (set parserStack (self.sourceStorage.parseJob.rootParser parserStackAt:(max (- charRange.loc 1) 0)))
    (set i (max 0 depth)) 
    (while (and (< i parserStack.count)
                (not ((parserStack i) isKindOfClass:(NuListParser class)))) 
           (set i (+ i 1)))
    (if (and (set parser (parserStack i))
             (ne parser @focusParser))
        (then (set @depth i)
              (self replaceFocusParserWith: parser))))
 
 ;; replaces the focus parser
 (- replaceFocusParserWith: parser is
    
    (if (and parser
             (ne @focusParser parser))
        (set @focusParser parser)
        (unless (hotParenParser? parser)
                (set @hotParen nil))
        (self cursorRelatedColoringFor:@focusParser)
        ~(puts "focusparser changed to #{parser.description}")
        (self handleContextEditorFor: @focusParser)
    ))
 
 ;; becaus the editor also marks dot lists and strings
 ;; we need to find out, which parser has actually parens
 (function hotParenParser? (parser)
     ([NuListParser.class
       NuArrayParser.class
       NuBlockParser.class] find: { class | (eq parser.class class) }))
 
 ;; defines the color of the hot paren
 (+ hotParenHighlight is
    
    (dict NSBackgroundColor: (NSColor redColor)))
 
 ;; highlights the parens of parser and if given a 'left or 'right one as hot.
 (- highlightParensFor:parser hotParen:hotParen is
    
    ~(puts "highlighting #{hotParen}---#{parser.description}")
    (if parser
        (self.layoutManager setTemporaryAttributes: (if (eq hotParen 'left) 
                                                        (then NuCodeEditor.hotParenHighlight)
                                                        (else NuCodeEditor.parensHighlight))
                                 forCharacterRange: (parser fakeParenRange: 'left))   
        
        (self.layoutManager setTemporaryAttributes: (if (eq hotParen 'right) 
                                                        (then NuCodeEditor.hotParenHighlight)
                                                        (else NuCodeEditor.parensHighlight))
                                 forCharacterRange: (parser fakeParenRange: 'right))))
 
 
)





