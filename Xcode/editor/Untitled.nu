(class NSString 
 (- separateLinesWith: separator is 
    
    (self componentsSeparatedByString: separator   
       <- map: (do (line) line.uppercaseString)              
       <- map: (do (line) (line stringByPaddingToLength: 21 withString: "-" startingAtIndex: 0)) 
       <- map: (do (line) (+ "|" line "|\n"))                        
       <- reduce: (do (acc line) (+ acc line)) from: "HEADER\n" )))

((class NSString 
  (- separateLinesWith: separator is 
     
     (((((self componentsSeparatedByString: separator) map: (do (line) (line uppercaseString))) 
           map: 
           (do (line) (line stringByPaddingToLength: 21 withString: "-" startingAtIndex: 0)))
          map:
          (do (line) (+ "|" line "|\n"))) reduce: (do (acc line) (+ acc line)) from: "HEADER\n"))))

(reduce (map (map (map self 
                       (do (line) 
                           line.uppercaseString)) 
                  (do (line) 
                      (line stringByPaddingToLength: 21 withString: "-" startingAtIndex: 0))) 
             (do (line) 
                 (+ "|" line "|\n"))) 
        (do (acc line) 
            (+ acc line)) 
        "HEADER\n" )