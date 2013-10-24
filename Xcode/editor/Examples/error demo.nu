;; error demo.nu
;;
;; a small demo that shows how errors
;; get shown on different windows
;; when an exception occurs, the topmost calling list from every window
;; gets underlined
;; there are tooltips and an errormessage shown above.
;; this document loads "error demo class.nu" by it self, when evaluated.
;; press reparse and thisDocumenthan eval all, to see it again

(set thisDocument (document))
(set thisEditor (editor))
(set classDocument (thisDocument loadFromHere: "error demo class.nu"))
(set frame classDocument.editor.window.frame )
(classDocument.editor.window setFrame: (list frame.first
                                             frame.second
                                             400 600)
                              display:YES
                              animate:YES)

(set frame classDocument.editor.window.frame )
(thisEditor.window setFrame:  (list (+ frame.first frame.third)
                                    (+ frame.second)
                                    600
                                    frame.fourth )
                    display: YES
                    animate: YES)
~(thisEditor.window makeKeyAndOrderFront: nil)
(classDocument eval: nil)

(set silly Silly.alloc.init)
(silly produceError: 5)