(let ((skippers (dict)))
     (skippers "macro" 3)
     (skippers "set" 3)
     (skippers "quasiquote" 1)
     (skippers "progn" 1)
     (skippers "quasiquote-splice" 1)
     
     (class NSNull (- (id) multilineStringValue is ""))
     (class NSObject (- (id) multilineStringValue is ""))
     
     (class NuCell
     	(- (id) nubile is
       		((NuBeautifier new) beautify:(self multilineStringValue)))
     	(- (id) multilineStringValue is
       		(set cursor self)
       		(set result (NSMutableString stringWithString:"("))
       		(set count 0)
       		(set labelcount 0)
       		(set item0 (cursor car))
       		(set skipValue (skippers (item0 stringValue)))
       		(if (not skipValue)
          			(set skipValue 2))
       		(while (!= cursor nil)
                (if (> count 0)
                    (then (result appendString:" ")))
                (set count (+ count 1))
                (set item (cursor car))
                (if (send item isKindOfClass:NuCell)
                    (then (if (> count skipValue)
                              (result appendString:"\n"))
                          (result appendString:(send item multilineStringValue)))
                    (else 
                        (if (item isKindOfClass:NuSymbol)
                            (if (item isLabel)
                                (if (> (set labelcount (+ labelcount 1)) 1)
                                    (result appendString:"\n"))))
                        (if (!= item nil)
                            (then (if (send item respondsToSelector:"escapedStringRepresentation")
                                      (then (result appendString:(send item escapedStringRepresentation)))
                                      (else (result appendString:(send item description)))))
                            (else (result appendString:"()")))))
                
                (set cursor (cursor cdr))
                ;; check for dotted pairs 
                (if (and (!= cursor nil) (not (send cursor isKindOfClass:NuCell)))
                    (result appendString:" . ")
                    (if (send cursor respondsToSelector:"escapedStringRepresentation")
                        (then 
                            (result appendString: (cursor escapedStringRepresentation)))
                        (else 
                            (result appendString: (cursor description))))
                    (break)))
         (result appendString:")")
         result))
     
)