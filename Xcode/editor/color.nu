;; a context editor for colors
;; if theirs an expression as focus parser that evaluates without context to a NSColor object,
;; the color panel is started
;; every change replaces the color expression in the source code
;; somehow undo grouping doesn't work properly 
;; should be fixed

(class NuObjectParser
 (- color is 
    (if (and (eq self.class NuListParser)
             self.cell
             self.cell.car
             (pair? self.cell.car)
             (eq self.cell.car.car 'NSColor)
             (try ((set color (self.cell.car evalWithContext: nil)) isKindOfClass: NSColor)
                  (catch (e) )))
        (then color)
        (else nil))))


(class NuCodeEditor
 
 (-  handleContextEditorFor: parser is
     
     (if (and self.contextEditorsEnabled
              (set color (parser color)))
         (then (set cp (NSColorPanel sharedColorPanel))
               (cp set: (delegate: nil
                           target: self
                           action: "editColor:"
                            color: color
                       showsAlpha: YES))
               
               (cp orderFront: nil)
               (set @colorEditingStarted YES)
               (if (not @colorEditingStarted) 
                   (self.sourceStorage.undoManager beginUndoGrouping)))
         (else (if @colorEditingStarted
                   (set @colorEditingStarted NO)
                   (set cp (NSColorPanel sharedColorPanel))
                   (cp setDelegate: nil)
                   (cp close)
                   (self.sourceStorage.undoManager endUndoGrouping)
                   (self didChangeText))))) 
 
 (- editColor: sender is
    
    (if (and @colorEditingStarted 
             (@focusParser color))
        (if (set newColorExpression sender.color.asNuExpression)
            (self beginEditing)
            (self replaceCharactersInRange: @focusParser.range withString: newColorExpression)
            (self endEditing )
            (self setSelectedRange: (list @focusParser.withOffset 0))
            (self cursorRelatedColoringFor:@focusParser)))))


