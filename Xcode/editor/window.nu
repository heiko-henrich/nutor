;; window.nu


(class NSWindow
 
 (- defaultWindowFrame is '(933 645 762 487))
 
 (- stretched is
    (>= ?(* 1.08 self.frame.fourth) => '<invalid Result>
        self.screen.frame.fourth -? => '<invalid Result>))
 
 (- stretch is
    (if (not self.stretched)
        (set @rememberedFrame self.frame))
    (self setFrame:  (list self.frame.first
                           0
                           self.frame.third
                           self.maxSize.second )
           display: YES
           animate: YES))
 
 (- unstretch is
    (if self.stretched
        (if (and (or (not (defined @rememberedFrame))
                     (null? @rememberedFrame)))
            (set @rememberedFrame self.defaultWindowFrame))
        (self setFrame: (list self.frame.first
                              @rememberedFrame.second
                              self.frame.third
                              @rememberedFrame.fourth)
               display: YES
               animate: YES)))
 
 (- toggleStretch: sender is (if self.stretched 
                                 (then self.unstretch)
                                 (else self.stretch))))

