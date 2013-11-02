;; sprite kit demo
;;
;; this works just with os x 10.9
;; press eval all button
;; try to change the values of the update function
;; enable number dragging in options.
;; warning: doesn't stop even if window is closed.
;; so you have to restart Nutor or remove the scene from the SKView


(load "playground")
(load "SpriteKit")
(load "math")

(class TextNode is SKLabelNode
 (+ with: text position: pos is
    (set l (SKLabelNode labelNodeWithFontNamed:"Chalkduster"))
    (l set: (text: text
         fontSize: 42
         position: pos))
    l))

(class Scene is SKScene
 (- update: (long) time is
    (try 
        (update time)       
        (catch (e)))))


(NuDebugging state)
(set $old-time 1)
;; change the values in this function as you like
;; but be careful, crashes are possible
(def update (time)
     (progn
         
         ;; to allow result updates this is necessary:
         (NuDebugging setState: YES)
         ;; the time value does not make any sense for me:
         time -? => '<invalid Result>
         ;; therefore I used $count just as addChild: simple counter
         $count -? => '<invalid Result>
         (node1 set:  (position:?(list (+ 312 (* 203 (cos (/ $count 24))))
                                       (+ 302 (* 200 (sin (/ $count 17))))) => '<invalid Result>
                          scale: (+ 2.5
                                    (* 0.2 (cos (/ $count 13.5))))
                      zRotation: (/ $count 22)
                          color: (NSColor colorWithCalibratedRed: 0.02032624086373841 green: 0.7846174568965517 blue: 0.0007827801090934172 alpha: 1)
               colorBlendFactor:1
                           text:"Heiko"))
         
         (node2 set:  (position:?(list (+ 218 (* 200 (sin (/ $count 100))))
                                       (+ 300 (* 200 (cos (/ $count 100))))) => '<invalid Result>
                          scale: ?(+ 2.5 (* 0.50 (sin (/ $count 18)))) => '<invalid Result>
                      zRotation:  (/ $count -14.1 )
                          color: (NSColor colorWithCalibratedRed: 0 green: 0.1754863194084133 blue: 1 alpha: 1)
               colorBlendFactor:1
                           text:"Simone"))
         
         (node3 set:  (position:(list (+ 300 (* 85 (sin (/ $count 110))))
                                      (+ 300 (* 200 (cos (/ $count 90)))))
                          scale: (+ 1.2 (* 0.5 (sin (/ $count 50))))
                      zRotation: (* 1.5 (sin (- (/ $count 13))))
                          color: (NSColor colorWithCalibratedRed: 1 green: 0 blue: 0.04004349114976691 alpha: 1)
               colorBlendFactor:1
                           text:"Luisa & Lena"))
         
         ?(set $count (+ $count 1)) => '<invalid Result>
         ;; delete the ~ ifn the following expression and see what happens. (performance sucks!!!)
         ~((editor).sourceStorage processResults)
         ;; alternatively you could press the update button in the toolbar (now you know what it is for ...)    
     ))

(set  $count 0)

(set view (playground SKView 600 600))

(list view
      $playground-window)

(if ?(and (defined scene)
          scene) => '<invalid Result>
    (then (scene removeAllChildren)
          (scene.view presentScene: nil)))
(set scene (Scene alloc <- initWithSize:'(600 600)))

(scene set: (backgroundColor: (NSColor colorWithCalibratedRed: 0 green: 0 blue: 0 alpha: 1)
                   scaleMode: 2))

(set node1 (TextNode with: "HALLO" 
                 position: '(100 100)))
(set node2 (TextNode with: "HALLO" 
                 position: '(100 100)))
(set node3 (TextNode with: "HALLO" 
                 position: '(100 100)))
(scene addChild: node1)
(scene addChild: node2)
(scene addChild: node3)
(view presentScene: scene)

