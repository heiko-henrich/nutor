;; dragging.nu
;;
;; implements mecahanism to change the value of numbers by dragging them with the mouse
;; makes heavy use of NSDecimalNumber
;; (I also changed the parser in a way that it parses decimalNumbers instead of floats ...
;; but this should be optional)
;; the dragging works in 2 ways:
;; up and down increases/decreases the value
;; left increases the magnitude of the addend
;; right decreases the magnitude of the result
;; the precision stays always the same, according to the decimal points of the original number.
;; this still needs some callibration but
;; with some practise you can change numbers pretty precise
;; beware of 1.100, this gets parsed as 1.1, so precision will be at 0.1
;; number dragging has to be turned on in order to work.

(load "math")

(class NSDecimalNumber 
 (- floorAtDecimalPlace: place is
    (self decimalNumberByRoundingAccordingToBehavior: 
          (NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:1 
                                                                 scale:place
                                                      raiseOnExactness:NO 
                                                       raiseOnOverflow:NO 
                                                      raiseOnUnderflow:NO 
                                                   raiseOnDivideByZero:NO)))
 (- decimalPlacesWithMax: maxPlaces is
    (if (or (<= maxPlaces 0)
            (eq 0 (self decimalNumberBySubtracting: (self floorAtDecimalPlace: 0))))
        (then 0)
        (else (+ 1 ((self decimalNumberByMultiplyingByPowerOf10:1) decimalPlacesWithMax: (- maxPlaces 1)))))
 ))


(class NSNumber
 
 (- floorAtDecimalPlace: place is
    (set decimalFactor (** 10 place))
    (/ (floor (* self decimalFactor)) decimalFactor))
 
 (- stringValueWithDecimalPlaces: places is
    (if (null? $formatter)
        (set $formatter (NSNumberFormatter alloc <- init)))
    ($formatter set:(numberStyle: 1
                    roundingMode: 1 
                decimalSeparator: "."
                notANumberSymbol: "0" 
          positiveInfinitySymbol: "0"
          negativeInfinitySymbol: "0"
           usesGroupingSeparator: NO
           minimumFractionDigits: places
           maximumFractionDigits: places))
    ($formatter stringFromNumber: self))
)

^(63.65 stringValueWithDecimalPlaces: 3|? => "63.650")


(class NuCodeEditor
 
 (- mouseDown: event is
    (set @lastMouseDownLocation 
         (self characterIndexForInsertionAtPoint: (set @lastMouseDownPoint 
                                                       (self convertPoint: event.locationInWindow fromView: nil))))
    (set @firstMouseDownPoint @lastMouseDownPoint)
    (if (and self.numberDraggingEnabled
             (set @dragging-parser (self.sourceStorage.parseJob.rootParser parserAt: @lastMouseDownLocation))
             (eq @dragging-parser.type "number"))
        (then (set @dragging 't)
              (set @dragging-base-value (@dragging-parser.cell.car decimalNumber))
              (set @dragging-location @dragging-parser.location)
              (self.sourceStorage.undoManager beginUndoGrouping)
              ~(self beginEditing))
        (else (super mouseDown: event))))
 
 (set MOUSE-SCALE-Y 0.08)
 (set MOUSE-SCALE-X -0.02)
 
 (- mouseDragged: event is 
    (set mouseLocation (self characterIndexForInsertionAtPoint: (self convertPoint: event.locationInWindow fromView: nil)))
    
    (set draggingPoint (self convertPoint: event.locationInWindow fromView: nil))
    
    (if @dragging
        (set @base-decimal-places (@dragging-base-value  decimalPlacesWithMax:7))
        (set growth  (* MOUSE-SCALE-X (-  draggingPoint.first @firstMouseDownPoint.first)))
        (set x-addend ((* (-  @firstMouseDownPoint.second  draggingPoint.second -15) 
                          MOUSE-SCALE-Y 
                          (if (> growth 0)
                              (then (** 10 growth))
                              (else 1))
                          (** 10 (- @base-decimal-places))) floorAtDecimalPlace: @base-decimal-places))
        (set exponent (if (< growth -1)
                          (then (+ growth 1))
                          (else 0)))
        
        (set new-number (@dragging-base-value decimalNumberByMultiplyingBy:  (** 2 exponent <- decimalNumber) 
                                           <- decimalNumberByAdding:  x-addend.decimalNumber
                                           <- floorAtDecimalPlace: @base-decimal-places))
        ~(self setMessage: (list 
                               x-addend
                               @dragging-base-value
                               new-number).stringValue)
        
        (self replaceCharactersInRange: @dragging-parser.range withString: (new-number stringValueWithDecimalPlaces: @base-decimal-places))
        
        (set @dragging-parser (self.sourceStorage.parseJob.rootParser parserAt: @dragging-location))
    )
 )
 
 (- mouseUp: event is
    (if @dragging
        ~(self endEditing )
        (self.sourceStorage.undoManager endUndoGrouping)
        (set @dragging nil)
        (self didChangeText))   
 ))