;; a simple auto completion mechanism
;; at the moment symbols used in the current file get completed
;; there is more possible:
;; the best thing would be a kind of type guessing mechanism:
;; it could work like evalWithContext:
;; but instead guessClassWithContext: could guess the class of a possible evaluation
;; but since objc runtime dind't deliver exact class information for methods
;; one would probably end up with somehow reading or processing header files to
;; get the necessary information
;; very interesting, but - a lot of work.
;; or one could use the live evaluation feature:
;; first write a kind of test,
;; then write the function or method you want:
;; during typing the test gets evaluated and gives information about the types of the existing symbols.
;; or a mix of the 2 methods could be possible

(class NuCodeEditor
 
 (- completionsForPartialWordRange:charRange indexOfSelectedItem:indexp is 
    
    (set symbolStrings self.sourceStorage.parseJob.symbolStrings)
    (set source self.sourceStorage.string)
    ~(puts "range #{charRange}")
    (set partial (source substringWithRange: charRange))   
    (set completeList (symbolStrings select: { symbol | (symbol.lowercaseString hasPrefix: partial.lowercaseString)}
                                  <- sortedArrayUsingBlock: {a b| (a caseInsensitiveCompare: b)} )) 
    (if (> completeList.count 1)
        (then completeList)
        (else nil)))
 
 (- rangeForUserCompletion is 
    (set selection self.selectedRange)
    (set source self.sourceStorage.string)
    (set start selection.loc)
    (set end  (apply + selection))
    (if (or (>= end source.length)
            (NuObjectParser.endOfAtomCharacters characterIsMember: (source characterAtIndex: end)))
        ~(puts "  #{start} #{end} #{(source characterAtIndex: start)}")
        (then (while (and (> start 0)
                          (not (NuObjectParser.endOfAtomCharacters characterIsMember: (source characterAtIndex:(- start 1)))))
                     (set start (- start 1))
                     ~(puts "  #{start} #{end} #{(source characterAtIndex: start)}"))
              (list start (- end start )))
        (else (list 0 0))))
 
 (- complete is
    (self.sourceStorage.undoManager beginUndoGrouping)
    (super complete)
    (self.sourceStorage.undoManager endUndoGrouping))
 
 (- doCompletion: timer is
    (self stopCompletionTimer)
    (self complete: self))
 
 (- startCompletionTimer is
    (if self.autoCompletionEnabled
        (then (self stopCompletionTimer)
              (set @completionTimer (NSTimer scheduledTimerWithTimeInterval:0.5 
                                                                     target:self
                                                                   selector:"doCompletion:"
                                                                   userInfo:nil 
                                                                    repeats:NO)))))
 (- stopCompletionTimer is
    (@completionTimer invalidate)
    (set @completionTimer nil))
 
)