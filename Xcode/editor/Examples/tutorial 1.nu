;; result display and evaluation reader macros
;;--------------------------------------------


;; there are some changes to Nu, which are a bit strange
;; and maybe don't make sense at first sight.
;; here some examples:

;; first let's introduce the probing reader macro: ? 
;; so insert a '?' in front of following expression 

(+ 2 3)

;; now it should look like: 
;;  ?(+ 2 3) => '<invalid Result>

;; now press the eval all button
;; and you see:

?(+ 2 3) => '<invalid Result>

;; if you delete the question mark the result (started with '=>') disappears. strange.
;; that's not what you expect form source code.
;; there are 2 variants of this:

(+ 2 3) -? => '<invalid Result>

;; and  

(+ 2 3 |? => '<invalid Result>)

;; which will make more sense later on.

;; another useful "reader macro" is the '~'
;; you can make the parser ignore the folowing item, like:

?(+ 2 3 ~(* 4 5)) => '<invalid Result>

;; this is great to "comment out" parts of your code, like logging espressions
;; whole methods or classes, but also just a variable or so.


;; as you have seen, with "eval all" you can evaluate the whole document.
;; the result of this evaluation is printed onto the console (press "console" to open and close)
;; and in the assistant editor (press "assistant")
;; you've certainly noticed the yellow highlighted parens
;; this is usually the list, the cursor currently lives in.
;; I call them focus for now.
;; when you press CMD-E or "eval focus" this list gets evaluated
;; however in the top context, as if ths expression would stand for itself
;; try it with:

(set a 2)
(set b 3)
?(function crap ()
     (set a 4)
     (set b 5)
     ?(+ a b) => '<invalid Result>) => '<invalid Result>

;; first press eval all, then evaluate just ?(+ a b) with CMD-E
;; if you want the ?-magic to happen, the yellow mark must include the '?' in the yellow marks.

;; speaking of this, you can move the yellow marks aka focus with CMD-ALT-UP and CMD-ALT-DOWN

;; There are more ways to evaluate things
;; the % reader macro evaluates an expression as you type and inserts the result in the current source code.

?(function wonder (a b)
     (* a b %(+ 2 3))) => '<invalid Result>

;; press the "back tranlation" button, now the assistant editor opens and shows what the Nu parser does with this code
;; there isn't any (+ 2 3) any more, just 5.
;; also the probing macro shows you the block returned by the function evaluation.
;; This might be useful for calculate constants at "parse time" or maybe for a new kind of macro stuff.

;; close to this but  a lot different the '^'- or as I call it live evaluation macro
;; try to insert new values in the following expression:
;; as you can see, the result gets shown immediately.

^?(+ 2 3) => 5

;; this just works, when "live evaluation" is turned on
;; in fyct every time something changes in this file (that means every key stroke you do)
;; all theses ^-expressions get evaluated. 
;; so be warned, you shouldn't compute pi with a billion decimal places this way.

;; another example to demonstrate this:

^?(((editor) sourceStorage) length) => 0  ;; the length of this file

(set count 0)
^?(set count (+ count 1)) => '<invalid Result> 

;; this counts up everytime its evaluated.
;; this does not seem to make any sense, but look at this:

(class NSString 
 (- separateLinesWith: separator is
    
    (self componentsSeparatedByString: separator             |? => '<invalid Result>
          
       <- map: (do (line) line.uppercaseString)              |? => '<invalid Result>
          
       <- map: (do (line) (line stringByPaddingToLength: 21 
                                             withString: "-" 
                                        startingAtIndex: 0)) |? => '<invalid Result>
       <- map: (do(line)
                  (+ "|" line "|\n"))                        |? => '<invalid Result>
       <- reduce: (do (acc line)
                      (+ acc line))               
            from: "HEADER\n"                                 |? => '<invalid Result> )))

^?("This is silly,   |you know? |or what do you |think?" separateLinesWith: " |") => '<invalid Result>

;; if you haven't done it, you should press "eval all" now
;; so you can test your method. while still writing
;; since the Nutor parser parses incrementally, 
;; you can change the code of an already evaluated and "saved" method
;; try to change the "HEADER" string or other components of the above method
;; unfortunately this behaviour is not always reliable, because
;; there are situations, the whole parse tree has internally to be reparsed
;; if you press "reparse", you will see, that the changes to the method don't have any effect anymore.

;; if you have osx 10.9 installed, you can try the sprite kit demo,
;; there you can also see the effects and benefits of number dragging and the color editor.

