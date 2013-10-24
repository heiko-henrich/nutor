;; panel.nu
;; 
;; offers an convenient method to display an arbitrary view in a panel window
;; the macro works as follows:
;; (panel symbol viewclass *size)
;; an instance of view-class gets bound to symbol, opionally you can offer a size
;; example:
;; (panel text NSTextView 600 800)
;; the expression returns the view.
;; the window title is set to the symbol.stringValue
;; if the macro gets called again with the same macro, it replaces the 
;; previously instantiated view.

(class NuPanelWindowController is NSWindowController
 
 ;; Initialize a console.
 (-  initWithViewClass: viewClass size: (NSRect) size title: title is
     (set view (viewClass alloc <- initWithFrame: size))
     
     (self initWithWindow:((NSPanel alloc) initWithContentRect:view.frame
                                                     styleMask:(+ NSTitledWindowMask NSClosableWindowMask NSMiniaturizableWindowMask NSResizableWindowMask NSUtilityWindowMask)
                                                       backing:NSBackingStoreBuffered
                                                         defer:NO))
     (let (w (self window))
          (w setContentView: view)
          (w center)
          (w set:   (title: title
                    opaque: NO 
                  delegate: view 
         hidesOnDeactivate: NO 
               frameOrigin: (NSValue valueWithPoint: (list (first ((self window) frame)) 80))
                   minSize: (NSValue valueWithSize:  '(200 100))))
     )
     self))


(if (null? $panel-view-controllers)
    (set $panel-view-controllers (dict)))

(macro panel (symbol viewClass *size)
       `(progn (if (and (defined ,symbol)
                        ,symbol
                        (,symbol isKindOfClass: ,viewClass)
                        (set vc ($panel-view-controllers ',symbol)))
                   (let (w (vc window))
                        (w contentView <- removeFromSuperview)        
                        (w setContentView: nil)
                        (w close))
                   ($panel-view-controllers removeObjectForKey: ',symbol))
               (let (view-controller (NuPanelWindowController alloc 
                                                           <- initWithViewClass: ,viewClass
                                                                           size: ',(if *size 
                                                                                       (then (append '(0 0) *size))
                                                                                       (else '(0 0 600 200))) 
                                                                          title: (',symbol stringValue)))
                    
                    ($panel-view-controllers ',symbol view-controller)
                    (global ,symbol (view-controller window 
                                                  <- contentView )))
        )
)

(load "beautifier")
(load "nubile")

^?((macrox (panel text NSTextView)) nubile) => <<+STRING
                                                  (progn 
                                                 _   (if (and (defined text) text 
                                                 _            (text isKindOfClass: NSTextView) 
                                                 _            (set vc ($panel-view-controllers (quote text)))) 
                                                 _       (let (w (vc window)) 
                                                 _            ((w contentView) removeFromSuperview) 
                                                 _            (w setContentView: nil) 
                                                 _            (w close)) 
                                                 _       ($panel-view-controllers removeObjectForKey: 
                                                 _                                (quote text))) 
                                                 _   (let (view-controller ((NuPanelWindowController alloc) initWithViewClass: NSTextView 
                                                 _                                                                       size: 
                                                 _                                                          (quote (0 0 600 200)) 
                                                 _                                                                      title: 
                                                 _                                                          ((quote text) stringValue))) 
                                                 _        ($panel-view-controllers (quote text) view-controller) 
                                                 _        (global text 
                                                 _                ((view-controller window) contentView))))STRING

