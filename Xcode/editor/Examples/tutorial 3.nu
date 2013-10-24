;; HERESTRINGS
;;-------------


;; herestrings are indented now
;; which just looks much nicer
;; the older versions work with an '$' prefix.
;; compare following exampels from generate.nu:

(do (group)
    (if (eq (group car) 'ivar)
        ((group cdr) eachPair:
                     (do (type name)
                         ;; define each getter and setter
                         (result appendString:$<<-END 
- #{type} #{name} {return #{name};}
                                 
- (void) set#{((name stringValue) capitalizeFirstCharacter)}:#{type} _#{name} {
END)
                         (if (or (eq type '(id)) (eq (((type stringValue) stripParens) lastCharacter) 42))
                             (result appendString:$<<-END 
    [_#{name} retain]; 
    [#{name} release]; 
END))
                         (result appendString:$<<-END
    #{name} = _#{name}; 
}
                                 
END)))))

(do (group)
    (if (eq group.car 'ivar)
        (group.cdr eachPair: (do (type name)
                                 ;; define each getter and setter
                                 (result appendString:    <<-END
                                                             - #{type} #{name} {return #{name};}
                                                             
                                                             - (void) set#{name.stringValue.capitalizeFirstCharacter}:#{type} _#{name} {
                                                             END)
                                 (if (or (eq type '(id)) 
                                         (eq type.stringValue.stripParens.lastCharacter 42))
                                     (result appendString:<<-END
                                                            _    [_#{name} retain];
                                                            _    [#{name} release];
                                                             END))
                                 (result appendString:    <<-END
                                                            _    #{name} = _#{name};
                                                             }
                                                             
                                                             END)))))
;; the indentation works out of the box
;; the only thing is, if you want to start a line with spaces 
;; you have to insert a '_' so you can indent the line as you like

;; one more thing with strings:
;; string interpolations, that means the #{} kind of insertions
;; which let you compute things in strings are now parsed at "parse time"
;; so they get translated to a list with an + operator at the beginning:

(do () '<<-END
           - (void) set#{name.stringValue.capitalizeFirstCharacter}:#{type} _#{name} {
           END )
   
   -? => (do ()
             (quote (+ "- (void) set"
                       (progn
                           ((name stringValue) capitalizeFirstCharacter))
                       ":"
                       (progn
                           type)
                       " _"
                       (progn
                           name)
                       " {\n")))


















