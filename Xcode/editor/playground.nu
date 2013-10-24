;; playground.nu
;; a helper for trying out NSView classes

(class NuPlaygroundWindowController is NSWindowController
 
 ;; Initialize a console.
 (-  initWithViewClass: viewClass size: (NSRect) size is
     (set view (viewClass alloc <- initWithFrame: size))
     
     (self initWithWindow:((NSPanel alloc) initWithContentRect:view.frame
                                                     styleMask:(+ NSTitledWindowMask 
                                                                  NSClosableWindowMask
                                                                  NSMiniaturizableWindowMask
                                                                  NSResizableWindowMask
                                                                  NSUtilityWindowMask)
                                                       backing:NSBackingStoreBuffered
                                                         defer:NO))
     (let (w (self window))
          (w setContentView: view)
          (w center)
          (w set:      (title:"#{viewClass} Playground" 
                     delegate:view
                       opaque:NO 
            hidesOnDeactivate:NO 
                  frameOrigin: (NSValue valueWithPoint: (list (first ((self window) frame)) 80))
                      minSize:     (NSValue valueWithSize:  '(600 100))))
          (w makeKeyAndOrderFront:self))
     self))


(function playground (viewClass *size)
    (if $playground-window
        ($playground-window contentView <- removeFromSuperview)        
        ($playground-window setContentView: nil)
        ($playground-window close)
        (set $playground-window nil))
    (set size (if *size 
                  (then (append '(0 0) *size))
                  (else '(0 0 600 200))))
    (NuPlaygroundWindowController alloc 
                               <- initWithViewClass: viewClass 
                                               size: size |? => '<invalid Result>
                               <- window |? => '<invalid Result>
                               <- =: '$playground-window |? => '<invalid Result>
                               <- contentView |? => '<invalid Result> ))


