;; linesplitting.nu
;;
;; inserts or deletes newlines according rules
;; TODO: 
;; -    should work with TextChanges
;; -    more sophisticated rules
;; -    maybe implementation in objective c


(class NuObjectParser
 
 (- proposedNewlineChanges is nil)
 
 (- newlineInsertion is 
    (list "\n" 
          (if self.previous
              (then self.previous.end)
              (else self.withOffset))
          0))
 (- newlineDeletion is
    (list (if (NuObjectParser.endOfAtomCharacters 
                  characterIsMember: (self.root.job characterAt: self.location))
              (then "")
              (else " "))
          (set start (if self.previous
                         (then self.previous.end)
                         (else self.withOffset)))
          (- self.location start))))

(class NuListParser 
 
 (- lineStartingDescendants is 
    
    (self.descendants select: (do (parser)
                                  (parser isFirstParserInLine))))
 
 (- proposedNewlineChanges is
    
    (function multiline-children ()
        (children allValues 
               <- reduce:  {result childinfo| (if (or (childinfo second)
                                                      (< childinfo.first.line childinfo.first.endLine))
                                                  (then (+ result 1))
                                                  (else result))}
                    from: 0 ))
    
    (function max-child-length ()
        (children allValues <- reduce: {max-length childinfo | (if (< childinfo.first.length max-length)
                                                                   (then max-length)
                                                                   (else childinfo.first.length))}
                                 from: 0))
    (function when-necessary ()
        (or (multiline-children)
            (> (max-child-length) 40)
            (> self.count 10)))
    
    (set changes (array))
    (set children (dict))
    
    (set child self.lastChild)
    (while child  
           (changes addObjectsFromArray: (set child-changes (child proposedNewlineChanges)))
           ( children child.positionInList (list child child-changes))
           (set child child.previous))
    
    (set car-symbol (if (and (pair? self.cell)
                             (pair? self.cell.car)) 
                        (then self.cell.car.car)
                        (else nil)))
    (set rules ($newline-rules car-symbol))
    (if rules
        (then (set first-line (eval (rules itemsInFirstLine:)))
              (set next-lines (eval (rules itemsInFollowingLines:)))
              (set vertical (eval (rules vertical:))))
        (else (set first-line 2)
              (set next-lines 1)
              (set vertical (when-necessary))))
    
    (if vertical
        (if (and (set split-parser (children first-line <- first))
                 (not (split-parser isKindOfClass: NuEndOfListParser.class))
                 (not (self isKindOfClass: NuRootParser.class)))
            (changes << split-parser))
        (set index ( + first-line next-lines))
        (while (< index self.count)
               (if (and (set split-parser (children index <- first))
                        (not (split-parser isKindOfClass: NuEndOfListParser.class)))
                   (changes << split-parser ))
               (set index (+ index next-lines))))
    
    
    (if changes.count
        (then changes)
        (else nil)))
 
 (- lineSplittingInsertions is
    (set current-linesplitters (self lineStartingDescendants))
    (set new-linesplitters (self proposedNewlineChanges) )
    (set newlines-to-delete (current-linesplitters select: (do (parser)
                                                               (not (new-linesplitters containsObject:  parser)))))
    (set newlines-to-insert (new-linesplitters select: (do (parser)
                                                           (not (current-linesplitters containsObject:  parser)))))
    (set deletions (newlines-to-delete map: (do (parser)
                                                (parser newlineDeletion))))
    (set insertions (newlines-to-insert map: (do (parser)
                                                 (parser newlineInsertion))))
    (insertions addObjectsFromArray: deletions)
    insertions   
 ))

(class NuSourceStorage
 (- processChanges: changes-array is
    (changes-array sortedArrayUsingBlock: (do (a b)
                                              (cond ((> a.second b.second) -1) 
                                                    ((< a.second b.second) 1)
                                                    (else 0)))
                <- map: (do (change)
                            (self replaceCharactersInRange: (change cdr)
                                                withString: (change car)))))
 
 
 (- splitLinesIn: parser is
    (self processChanges:(parser lineSplittingInsertions))) 
)

(function newlines-for (car-symbol *rules)
    (if (not $newline-rules)
        (set $newline-rules (dict)))
    ($newline-rules car-symbol (NSDictionary dictionaryWithList: *rules)))


(newlines-for 'progn itemsInFirstLine: 1
                itemsInFollowingLines: 1
                             vertical: YES)

(newlines-for 'if itemsInFirstLine: 2
             itemsInFollowingLines: 1
                          vertical: YES)

(newlines-for 'set itemsInFirstLine: 3
              itemsInFollowingLines: 1
                           vertical: NO)

(newlines-for 'dict itemsInFirstLine: 3
               itemsInFollowingLines: 2
                            vertical: '(when-necessary))

(newlines-for 'function itemsInFirstLine: 3
                   itemsInFollowingLines: 1
                                vertical: YES)

(newlines-for 'macro itemsInFirstLine: 3
                itemsInFollowingLines: 1
                             vertical: YES)

(newlines-for 'do itemsInFirstLine: 2
             itemsInFollowingLines: 1
                          vertical: '(or (> self.count 3)
                                         (when-necessary)))


(newlines-for  'list    itemsInFirstLine: 2
                   itemsInFollowingLines: 1
                                vertical: '(or (when-necessary)
                                               (> self.count 9)))

(newlines-for  'array    itemsInFirstLine: 2
                    itemsInFollowingLines: 1
                                 vertical: '(or (when-necessary)
                                                (> self.count 9)))