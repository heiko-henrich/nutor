;; toolbar.nu
;;
;; for customizing the toolbar   



(class Document
 
 (- customizeToolbar is 
    (set @minWinFrame nil)
 )
 
 (- customToolbarAction1: sender is 
    (puts "write your own toolbar action")) 
 
 (- customToolbarAction2: sender is 
    (puts "write your own toolbar action"))
 
 (- customToolbarAction3: sender is 
    (puts "write your own toolbar action"))
 
 (- customToolbarAction4: sender is 
    (puts "write your own toolbar action"))
 
 (- customToolbarAction5: sender is 
    (puts "write your own toolbar action"))
 
 (- customToolbarAction6: sender is 
    ((editor).window toggleStretch: self))
 
 (- customToolbarAction7: sender is 
    (puts "write your own toolbar action"))
 
 (- customToolbarAction8: sender is 
    (puts "write your own toolbar action"))
 
)