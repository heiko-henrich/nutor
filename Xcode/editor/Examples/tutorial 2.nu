;; ARROW AND DOT SYNTAX
;;----------------------

;; the <- symbol is now a reader macro, which 
;; pushes everything before from the start of the list into a new list in the car
;; see yourself: (press eval all first)

(do () (a b: 2 <- c 
               <- d: 3))
   
   -? => (do () (((a b: 2) c) d: 3))

(do ()
    ("hallo ihr?" componentsSeparatedByString: " "
               <- map:    (do (l) (+ l " - "))
               <- reduce: (do (l) (+ l length)) from: 0
               <- list))
   
   -? => (do ()
             (((("hallo ihr?" componentsSeparatedByString: " ") map:
                                                                (do (l) (+ l " - "))) reduce:
                                                                                      (do (l) (+ l length))
                                                                                        from:
                                                                                      0) list))

;; this syntax makes message sending chains much more readable,
;; Lisp has a strong prefix syntax, but with introducing the smalltalk like postfix message sending syntax
;; things get sometimes confusing.
;; so though not very lispy, I think this could be a good thing


;; so is the dot-syntax, well known from obejctive c 2.0:
;; The nutor parser concatenates to items together into a list
;; in a "left associative" way:

?(do() (puts a.b.c.d)) => (do () (puts (((a b) c) d)))

;; and again, I think this is much more readable, if used wisely.


;; btw: the ? reader macro shows Nu expressions as result,
;; which could be evaluated to the original value
;; that's why
?'(a.b.c d.e.f) => (list (list (list 'a 'b) 'c) (list (list 'd 'e) 'f))
;; looks a bit strange as first, so the do-block examples are easier to understand
;; but look at following:

(dict      a: (+ 2 3)
           b: 5
     astring:"string"
      aRegex: /asdfjk/mix
  aCharacter: '\uffff'
     aSymbol: 'symbol
 alongSymbol: '<tutorial 2.nu> 
anotherSymbol: 2.symbolValue
    anObject: ((NSObject alloc) init)
     anArray: (array 1 2 3 4 5)
       aList: '(a b c d d.e.f))
   
   -? => (dict aRegex: /asdfjk/ixm
              astring: "string"
                aList: (list 'a 'b 'c 'd (list (list 'd 'e) 'f))
           aCharacter: 65535
        anotherSymbol: '<__NSCFNumber:2c7>
              anArray: (array 1 2 3 4 5 )
             anObject: <NSObject:7fb69a861a20>
              aSymbol: 'symbol
          alongSymbol: '<tutorial 2.nu>
                    a: 5
                    b: 5 )



