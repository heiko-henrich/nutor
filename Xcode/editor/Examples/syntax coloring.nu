;; syntax coloring.nu
;;
;; with context color editor enabled point to a color expression and change the color with the color panel
;; see the changes with liveEvaluation enabled

((editor) set: (contextEditorsEnabled: YES 
                liveEvaluationEnabled: YES))

^((editor).sourceStorage setSyntaxColorDictionary:
                         (dict number: (NSColor colorWithCalibratedRed: 0 green: 1 blue: 0 alpha: 1)
                               symbol: (NSColor colorWithCalibratedRed: 0.33 green: 0.5 blue: 0.2 alpha: 1)
                               object: (NSColor colorWithCalibratedRed: 0.5 green: 0.2 blue: 0.6 alpha: 1)
                            character: (NSColor colorWithCalibratedRed: 1 green: 0 blue: 0 alpha: 1)
                               string: (NSColor colorWithCalibratedRed: 0.8 green: 0 blue: 0 alpha: 1)
                             operator: (NSColor colorWithCalibratedRed: 0 green: 0 blue: 1 alpha: 1)
                                label: (NSColor colorWithCalibratedRed: 0.6 green: 0.4 blue: 0.2 alpha: 1)
                                macro: (NSColor colorWithCalibratedRed: 1 green: 0.5 blue: 0 alpha: 1)
                                regex: (NSColor colorWithCalibratedRed: 0.9 green: 0.06 blue: 0.8 alpha: 1) )
 )

;; see the colors in action:

(list 12345.67890
      'symbol '<a long symbol>
      NSObject
      'c' 'h' 'a' 'r' '\uffff' 
      "string" <<-STRING
                  string
                  STRING 
      defined list dict function # operators
      /a regular expression/
)
   -? => '<invalid Result>

;;this is the default value
~((editor).sourceStorage setSyntaxColorDictionary:(dict number: (NSColor colorWithCalibratedRed: 0 green: 1 blue: 0 alpha: 1)
                                                        symbol: (NSColor colorWithCalibratedRed: 0.33 green: 0.5 blue: 0.2 alpha: 1)
                                                        object: (NSColor colorWithCalibratedRed: 0.5 green: 0.2 blue: 0.6 alpha: 1)
                                                     character: (NSColor colorWithCalibratedRed: 1 green: 0 blue: 0 alpha: 1)
                                                        string: (NSColor colorWithCalibratedRed: 0.8 green: 0 blue: 0 alpha: 1)
                                                      operator: (NSColor colorWithCalibratedRed: 0 green: 0 blue: 1 alpha: 1)
                                                         label: (NSColor colorWithCalibratedRed: 0.6 green: 0.4 blue: 0.2 alpha: 1)
                                                         macro: (NSColor colorWithCalibratedRed: 1 green: 0.5 blue: 0 alpha: 1)
                                                         regex: (NSColor colorWithCalibratedRed: 0.9 green: 0.06 blue: 0.8 alpha: 1) ))


^((editor).sourceStorage syntaxColorDictionary |? => (dict number: (NSColor colorWithCalibratedRed: 0 green: 1 blue: 0 alpha: 1)
                                                           object: (NSColor colorWithCalibratedRed: 0.5 green: 0.2 blue: 0.6 alpha: 1)
                                                           symbol: (NSColor colorWithCalibratedRed: 0.33 green: 0.5 blue: 0.2 alpha: 1)
                                                        character: (NSColor colorWithCalibratedRed: 1 green: 0 blue: 0 alpha: 1)
                                                           string: (NSColor colorWithCalibratedRed: 0.8 green: 0 blue: 0 alpha: 1)
                                                         operator: (NSColor colorWithCalibratedRed: 0 green: 0 blue: 1 alpha: 1)
                                                            label: (NSColor colorWithCalibratedRed: 0.6 green: 0.4 blue: 0.2 alpha: 1)
                                                            macro: (NSColor colorWithCalibratedRed: 1 green: 0.5 blue: 0 alpha: 1)
                                                            regex: (NSColor colorWithCalibratedRed: 0.9 green: 0.06 blue: 0.8 alpha: 1) ))
