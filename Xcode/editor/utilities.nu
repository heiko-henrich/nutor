;; utilities.nu

;; some useful functions and categories 
;; not related to this project

;; takes a predicate function fun as first argument
;; (fun x) where x is the car of the body lists should return true or false ('() or 0)
;; and accordingly the cdr is evaluated.
;; example in editor.nu
(macro casex (fun *body)
       `(cond ,@( *body map: 
                        (do (x)  
                            ((if (eq (x car) 'else)
                                 (then  `(else ,@(x cdr)))
                                 (else  `( (,fun ,(x car))  ,@(x cdr))))))))) 

;; flags 
(function flags (*bits)
    (*bits map: {x| (<< 1 x)} 
        <- reduce: { x y | (+ x y)} from: 0))

(function getFlags (number)
    (function bitcollect (n bit) 
        (if (== n 0) 
            (then 
                (NSMutableArray alloc <- init <- retain))
            (else 
                (set s (bitcollect (>> n 1) (+ bit 1)))
                (if (& n 1) (s << bit))
                s)))
    ((bitcollect number 0) list))

;; puts a Value on the console and returns it 
;; used for debugging expressions
(function p (x)
    (puts x)
    x)

;; shorthad for a substringFrom:ring form start to, but not including end
(class NSString 
 (- substringFrom: start to: end is
    (self substringWithRange: (list start (- end start))))
 (- symbol is (NuSymbolTable sharedSymbolTable <- symbolWithString: self)) 
)

(function flip-direction (direction)
    (case direction
          ('right 'left)
          ('left  'right)))

;; useful methods for use with ranges
(class NuCell 
 (- loc is (self first)) 
 (- len is (self second))
 (- end is (apply + self))
 (- changedBy: delta direction: direction is
    (case direction
          ('right (list self.loc (+ self.len delta)))
          ('left  (list (- self.loc delta) (+ self.len delta))))))

(class NSObject
 (- =: symbol is
    ((list 'set symbol self) evalWithContext: (context).parent:.parent:)
 ) 
)

(global pi (NuMath pi))

(macro singleton (name instance)
       `(+ ,name is 
           (if (or (not (defined __inst))
                   (null? __inst))
               (global __inst ,instance))
           __inst))


