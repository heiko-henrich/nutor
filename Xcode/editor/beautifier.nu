(class NuBeautifier is NSObject
 
 ;; Beautify a string containing Nu source code. The method returns a string containing the beautified code.
 (+ (id) beautify:(id) text is
    (set b ((NuBeautifier alloc) init))
    (b beautify:text))
 
 ;; Beautify a string containing Nu source code. The method returns a string containing the beautified code.
 (- (id) beautify:(id) text is
    (if (not ?$prettySourceStorage => <NuSourceStorage:618000108d30>)
        (set $prettySourceStorage ?((NuSourceStorage alloc) init) => <NuSourceStorage:618000108d30>))
    ($prettySourceStorage replaceCharactersInRange: (list 0 $prettySourceStorage.length) withString: text)
    ($prettySourceStorage processIndentDeltas)
    ($prettySourceStorage string)))
