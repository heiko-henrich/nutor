;; expressions.nu
;; implements -asNuExpression for different classes
;; asNuExpression results in a string, that, when parsed and evaluated results in the value 
;; equalTo: self

(class NSColor 
 (- asNuExpression is
    (try 
        "(NSColor colorWithCalibratedRed: #{self.redComponent} green: #{self.greenComponent} blue: #{self.blueComponent} alpha: #{self.alphaComponent})"
        (cache e
               ;; there were errors here, so jus in case
               "(NSColor colorWithCalibratedRed: 1 green: #1 blue: 1 alpha: 0)"))))

(class NuBlock
 (- asNuExpression is
    ((cons 'do (cons (send self parameters) 
                     (send self body))) 
        stringValue)))

(class NuMacro_1
 (- asNuExpression is 
    ((cons 'macro (cons (send self name) 
                        (cons (send self parameters) 
                              (send self body)))) 
        stringValue)))

(class LineInfo
 (- rangeOfLine: line is
    (set start (self location: line))
    (set end (self endOf: line))
    (if (and (<= start end self.string.length))
        (then (list start
                    (- end start)))
        (else nil))))

(class NSURL 
 (- asNuExpression is
    (if self.isFileURL
        (then "(NSURL fileURLWithPathComponents: #{self.pathComponents.asNuExpression})")
        (else "(NSURL URLWithString: \"#{self.absoluteString}\")"))))

(class NSString
 (- lines is 
    (set line 0)
    (set lines (array))
    (while (set range (self.lineInfo rangeOfLine: line))
           (lines << (self substringWithRange: range))
           (set line (+ line 1)))
    lines)
 
 (- herestringRepresentation is
    (set label "STRING")
    (set number 0)
    (while (< (self rangeOfString: label <- first) self.length)
           (set label (+ label number))
           (set number (+ number 1)))
    (+ "<<+" label
       (self.lines reduce: (do (acc line)
                               (let (esc line.escapedStringRepresentation)
                                    (+ acc "\n" 
                                       (if (eq (esc characterAtIndex: 1) ' ') "_")
                                       (esc substringWithRange: (list 1 (- esc.length 2))))))
                     from: "")
       label))
 
 (- asNuExpression is
    (if (or (< self.length 25)
            (>= ((self rangeOfCharacterFromSet:(NSCharacterSet newlineCharacterSet)) first)
                self.length))
        (then (self escapedStringRepresentation))
        (else (self herestringRepresentation)))))

(class NSRegularExpression
 (- asNuExpression is
    (+ "/" self.pattern "/" 
       (if (& self.options %(<< 1 0 |? => 1)) "i")
       (if (& self.options %(<< 1 3 |? => 8)) "s")
       (if (& self.options %(<< 1 1 |? => 2)) "x")
       (if (& self.options %(<< 1 4 |? => 16)) "m"))))


