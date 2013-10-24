(load "panel")
(load "WebKit")

(class HelpWebView is WebView)

(class HelpWebView
 (- init is
    (if (set self  super.init))
    self)
 
 (- showMainPage is
    (self.mainFrame loadHTMLString: $helpHTMLString baseURL: nil)))

(set $helpHTMLString 
     (&html 
         (&body style: "font-family: Arial Narrow;"
                (&h2 "Nu Programming Language")
                (&p "Tim Burks Website: " (&a href: "http://www.programming.nu" "programming.nu"))
                (&li  (&a href: "http://www.programming.nu/syntax" "Syntax"))
                (&li  (&a href: "http://www.programming.nu/operators" "Operators"))
                (&li  (&a href: "http://www.programming.nu/types" "Types"))
                (&li  (&a href: "http://www.programming.nu/doc/index.html" "Classes"))
                (&li  (&a href: "https://groups.google.com/forum/#!forum/programming-nu" "Discussion"))
                (&li  (&a href: "https://developer.apple.com/library/mac/navigation/" "Mac Developper Library"))
                (&p "click the '?' button to return here")
                
                (&h2 "Keyboard Shortcuts")
                (&table border: "1" cellspacing:"40%" style:"width: 100%;  vertical-align: top;"
                        (&tbody (&tr (&td style:"width: 130px; "  
                                          "cmd 'D'")
                                     (&td "select current focus"))
                                
                                (&tr (&td "cmd 'E'")
                                     (&td "evaluate focus in parser context" ))
                                
                                (&tr (&td "cmd 'F'")
                                     (&td "search and replace" ))
                                
                                (&tr (&td "cmd 'Z'")
                                     (&td "undo. currently problems with 'color editor'" ))
                                
                                (&tr (&td "cmd right")
                                     (&td "move cursor to the end of the current (focus) list" ))
                                
                                (&tr (&td "cmd left")
                                     (&td "move cursor to the start of the current (focus) list" ))
                                
                                (&tr (&td "cmd shift 'Z'")
                                     (&td "redo. problems with 'color editor'" ))
                                
                                (&tr (&td "alt cmd '-'")
                                     (&td "show or change hot (red colored) paren"))
                                
                                (&tr (&td "alt cmd up")
                                     (&td "extend focus"))
                                
                                (&tr (&td "alt cmd down")
                                     (&td "shrink focus"))
                                
                                (&tr (&td "alt cmd right")
                                     (&td "show or move hot paren to the right"))
                                
                                (&tr (&td "alt cmd left")
                                     (&td "show move hot paren to the left"))
                                
                                (&tr (&td "alt cmd backspace")
                                     (&td "delete parens of focus"))
                                
                                (&tr (&td "ctrl '#'")
                                     (&td (+ "inserts"  "  \# " " { } for string interpolation")))
                                
                                (&tr (&td "ctrl '2'")
                                     (&td "inserts a single \" if smart parens" ))
                                
                                (&tr (&td "ctrl '8'")
                                     (&td "inserts a single ( or smart parens" ))
                                
                                (&tr (&td "ctrl '9'")
                                     (&td "inserts a single ) or smart parens" ))
                                
                                (&tr (&td "ctrl '<'")
                                     (&td "inserts <> to write long symbols" ))
                                
                                (&tr (&td "ctrl '-'")
                                     (&td <<+STRING
                                             inserts a  "<- " for arrow notation STRING ))
                                
                                
                                (&tr (&td "ctrl 's'")
                                     (&td <<+STRING
                                             converts a regular string to a herestring and back. 
                                             Does not work with interpoations yet.STRING ))
                                
                                (&tr (&td "escape")
                                     (&td "reverts insertion of an addittional \"smart\" paren <br> reverts auto completion" ))))
                (&p <<+STRING
                       In order to have fun with automatic indentation, 
                       it is important to use the smart parens feature:
                       For every inserted paren, bracket or quotation mark gets the corresponding counterpart inserted.
                       Use the above mentioned keyboard shortcuts to move the parens. <br>
                       When you want to insert a herestring, press '\"' and than ctrl-s. <br>
                       Use CMD-D to mark a list and cut, copy or paste it. <br>
                       Use the keyboard shortcuts for arrows and long symbels etc. STRING)
                
                (&h3 "Extended Nu Syntax - EXPERIMENTAL")
                (&table border: "1" cellspacing:"40%" style:"width: 100%; vertical-align: top;"
                        (&tbody (&tr (&td style:"width: 90px;" 
                                          (&code "."))
                                     (&td "a dot joins two items to a list, which has the same result as the objc-dot-syntax"))
                                
                                (&tr (&td (&code "<-"))
                                     (&td "creates a new list with everything since the last liststart in the car of this list" ))
                                
                                (&tr (&td (&code "\" -\" +\""))
                                     (&td "string with parsed interpolation" ))
                                
                                (&tr (&td (&code "$\" $-\" $+\""))
                                     (&td "string without parsed interpolation = regular Nu strings" ))
                                
                                (&tr (&td (&code "<<- <<+"))
                                     (&td <<-STRING 
                                             herestring (with parsed interpolation) and indentation: that means everything until the column, 
                                             the identifier starts gets cut off. works great with aout indentation. 
                                             The problem are spaces at the beginning of an indented line:
                                             insert a '_' - this gets ignored but you can insert spaces without auto indentation disturbing.
                                             STRING ))
                                
                                (&tr (&td (&code "$<<- $<<+"))
                                     (&td "herestrings without indentation and parsed interpolation" ))
                                
                                (&tr (&td (&code "< ... >"))
                                     (&td "a long symbol, which can contain whitespaces and all characters<br> used eg. for literal object values" ))
                                
                                (&tr (&td (&code "~"))
                                     (&td "ignores the following item: good to \"comment out\" a nu expression" ))
                                
                                (&tr (&td (&code "?"))
                                     (&td "inserts the result of the evaluation of the following item into the code" ))
                                
                                (&tr (&td (&code "-?"))
                                     (&td "inserts the result of the evaluation of the previous item into the code" ))
                                
                                (&tr (&td (&code "|?"))
                                     (&td "inserts the result of the evaluation of the current list into the code" ))
                                
                                (&tr (&td (&code "=>"))
                                     (&td "the following item is an inserted result and gets ignored" ))
                                
                                (&tr (&td (&code "^"))
                                     (&td "the following item gets evaluated in the destination context after the parsing of a change in the source code." ))
                                
                                (&tr (&td (&code "%"))
                                     (&td "immediately evaluates the folloing item in the parser context and inserts the resutl into the parsed code" ))
                                
                                (&tr (&td (&code "[ ... ]"))
                                     (&td "array literal (not good)" ))
                                
                                (&tr (&td (&code "{ .. | .. }"))
                                     (&td "block with arguments (not good)" ))
                                
                                (&tr (&td (&code "{ .. }"))
                                     (&td "block without arguments (not good)" ))))
                (&h2 "Gui Help")
                (&h3 "Options Drawer")
                (&table border: "1" cellspacing:"40%" style:"width: 100%; vertical-align: top;"
                        (&tbody
                            (&tr (&td  style:"width: 140px;" 
                                       "auto completion")
                                 (&td <<+STRING
                                         very dumb implementation. It just offers the already parsed symbols of the current file,
                                         which is good enoug to save some key strokes.
                                         STRING))
                            
                            (&tr (&td  "smart parens")
                                 (&td <<+STRING
                                         This is a feature I like very much: <br>
                                         I you insert a paren, bracket or brace, the corresponding counter part gets inserted
                                         either at the beginning/end of a line or if the parent list ends before, 
                                         at the beginning or end of the parent list. <br>
                                         You can change the position with the above mentioned alt-cmd keyboard commands.
                                         Warning: Doesn't work well with dot and  arrow syntax.
                                         STRING))
                            
                            (&tr (&td "auto indentation")
                                 (&td "toggles auto indentation"))
                            
                            (&tr (&td  "spaces slider")
                                 (&td <<-STRING 
                                         Auto indentation works pretty dictatorial, (I am german, you know ...)
                                         Basically a multiline list gets indented to the second item (cdar).
                                         The only thing what's not so clear is, what happens, when the second item is
                                         in a new line. Some say, there shouldn't be any indentation,
                                         others want an indentation of 1 or even 2 spaces ...
                                         This option gives the user the possibility to adjust this behaviour.
                                         STRING))
                            
                            (&tr (&td  "strict Nu mode")
                                 (&td <<-STRING 
                                         Tries to emulate the behaviour of the regular Nu parser. 
                                         No dot syntax and liver evaluation anymore ;-(<br>
                                         WARNING: Not as thoroughly tested as the extended Mode.
                                         STRING))
                            
                            (&tr (&td  "back translation")
                                 (&td <<-STRING 
                                         Opens the "assistant editor" and shows a "back translation" of the already parsed code.
                                         It was good for debugging the incremental parsing algorithm and it is good now to
                                         show the working of the new introduced "reader macros".
                                         STRING))
                            
                            (&tr (&td  "Autosave as reagulare save operation")
                                 (&td <<-STRING 
                                         Autosave usually doesn't save a new version of file.
                                         This will adjust autosaving in a way, that everytime 
                                         autosave does the same thing as when you press the save button.
                                         So you get much more "versions to revert to", which could be a
                                         disadvantage too.
                                         You can adjust the autosafing interval in defaults.nu
                                         STRING))
                            
                            (&tr (&td  "syntax highlighting")
                                 (&td "colors for now" 
                                      (&li "green: a normal symbol")
                                      (&li "brown: a label")
                                      (&li "blue:  an operator")
                                      (&li "red: a string")
                                      (&li "violet: a globally bound symbols")
                                      (&li "orange: macros (in the current parser context)")
                                      (&li "light red: characters")
                                      (&li "light green: numbers")
                                      (&li "purple: regular expressions")
                                      (&li "black: comments and everything else")))
                            
                            (&tr (&td  "focus parens highlighting")
                                 (&td "turns on the yellow parens markings = focus" ))
                            
                            (&tr (&td  "error highlighting")
                                 (&td <<-STRING 
                                         syntax  errors as well as evaluation errors (not always reliable) get underlined. 
                                         There are errormessages on mouse over in toolboxes and the message text field
                                         STRING))
                            
                            
                            (&tr (&td  "live evaluation")
                                 (&td <<+STRING
                                         This is cool too:
                                         You work can change the actual evaluated code and instatnly see results.
                                         Two things happen, whein live evaluation is turned on:
                                         STRING
                                      (&li <<-STRING
                                              when eval is pressed, the actual (already incrementally updated and parsed) code gets evaluated.
                                              This has the effect, that every time you change a function or a method,
                                              the actual code (already bound to a function or method name) gets changed
                                              and (where possible) you can see the changes immediately.
                                              STRING )
                                      (&li <<-STRING
                                              after each change of the source (that means after each key stroke)
                                              all "live evaluation items", that are the items that start with a '^' get evaluated.
                                              together with the "probing" tokens (? -? |?) you can test functions or methods "live",
                                              of see the result of your work immediately.
                                              Try to change this text in "guide.nu" with this window open,
                                              then you see, what I mean.
                                              I mean, with html it's not really magic, but changing real cocoa objects this way is cool I think.
                                              Watch the sprite kit demo and try to change some numbers ...
                                              STRING )))
                            
                            (&tr (&td  "number dragging")
                                 (&td <<-STRING 
                                         implements mecahanism to change the value of numbers by dragging them with the mouse
                                         the dragging works in 2 ways:
                                         up and down increases/decreases the value
                                         left increases the magnitude of the addend
                                         right decreases the magnitude of the result
                                         the precision stays always the same, according to the decimal points of the original number.
                                         this still needs some callibration but
                                         with some practise you can change numbers pretty precise
                                         beware of 1.100, this gets parsed as 1.1, so precision will be at 0.1
                                         Again the sprite kit demo is recommended.
                                         STRING))
                            
                            (&tr (&td  "context color editors")
                                 (&td <<-STRING 
                                         [Seems not working right with 10.8.
                                         But try it to get the idea.]
                                         actually just a color editor, that opens, when the cursor is in a list, that evaluates 
                                         (without context) to an NSColor object.
                                         Try it out with Sprite Kit Demo again ...
                                         The idea is, to have editors for different contexts,
                                         like a font editor (easy), an editor for a CGPath,
                                         even an WYSIWIG html or Gui editor, which produce Nu code are possible ...
                                         STRING))
                            
                            (&tr (&td  "focus shader")
                                 (&td <<-STRING 
                                         This shades the source code with different levels of grey.
                                         Not so useful ...
                                         STRING))
                            
                            (&tr (&td  "depth coloring")
                                 (&td <<+STRING
                                         Try it out, together with the color slider.
                                         Then leave it. It's kind of redundant, since auto indentation gives a good feedback
                                         for the different list levels.
                                         STRING))
                            
                            (&tr (&td  "uncolor indent")
                                 (&td "used together with the 2 obove mentioned options.\n"))
                            
                        ))
                
                (&h3 "Toolbar")
                (&table border: "1" cellspacing:"40%" style:"width: 100%; vertical-align: top;"
                        (&tbody (&tr (&td style:"width: 140px;" 
                                          "Options")
                                     (&td <<-STRING 
                                             Sometimes there are bugs or even abiguites in the incremental parsing or auto indent algorithm.
                                             (A classic one is a quote, followed by a space and a quote).
                                             Press reparse to fix it.
                                             
                                             STRING))
                                
                                (&tr (&td  "Save")
                                     (&td "saves the Document\n"))
                                
                                (&tr (&td  "Eval all")
                                     (&td "evaluates the file. it's saved before.\nyou can see the result in the assistant editor and in the message box\n"))
                                
                                (&tr (&td  "Eval focus")
                                     (&td "evaluates the current focus item\nthe result gets printed to the console and is seen in the message box\n"))
                                
                                (&tr (&td "Reparse")
                                     (&td <<-STRING 
                                             Sometimes there are bugs or even abiguites in the incremental parsing or auto indent algorithm.
                                             (A classic one is a quote, followed by a space and a quote).
                                             Press reparse to fix it.
                                             
                                             STRING))
                                
                                (&tr (&td  "Update")
                                     (&td "updates all results to an eventually changed value\n"))
                                
                                (&tr (&td  "Error Messages")
                                     (&td "Displays error messages on mouse over or at the crrent curso loadocation.\nThe Tooltips Apple provides are a mess so, this could help.\n")) 
                                
                                (&tr (&td "Font size")
                                     (&td "well, the font size"))
                                
                                (&tr (&td  "2nd Pane")
                                     (&td <<-STRING 
                                             opens the "assistant" editor.
                                             Actually, you can't work on a second file or source code.
                                             Just used for "back translation" and displaying the result of the last evaluation.
                                             STRING))
                                
                                (&tr (&td  "Help")
                                     (&td "guess what?\n"))
                                
                                (&tr (&td  "Console")
                                     (&td "opens the regular Nu console, working with the extended syntax.\nother conveniences like smart parens or syntax coloring or so don't work (yet?).\n"))
                                
                                (&tr (&td  "On Top")
                                     (&td "puts the current window on level 200!!!\nSo XCode in hasn't any chance to kill the editor window anymore!!!\n"))
                                
                                (&tr (&td  "Customize")
                                     (&td "Customize the toolbar.\nThere are more buttons in the box,\nalso some to customize, you can do it in \"toolbar.nu\"\n"))
                                
                        ))
                (&h3 "Issues and bugs")
                (&table border: "1" cellspacing:"40%" style:"width: 100%; vertical-align: top;"
                        (&tbody (&tr (&td style:"width: 140px;" 
                                          "Insetion Point (cursor)")
                                     (&td <<-STRING 
                                             The result displaying reader macros can affect the position of
                                             insertion point , so that it is displayed a line below.
                                             turn off live evaluation as workaround. <br> <br>
                                             also inserting of parens in strings or comments moves the cursor at the beginning of the file.
                                             Turn of smart parens or use ctrl-8 and ctrl-9 to insert a paren.
                                             STRING)
                                     
                                     (&tr (&td  "live evaluation")
                                          (&td <<-STRING 
                                                  live evaluation is very experimental.
                                                  Crashes and all nasty things are possible anytime.
                                                  also files with bad code can can crash the editor at startup.
                                                  Turn off liveEvaluationEnabled in defaults.nu
                                                  STRING))
                                     
                                     (&tr (&td  "result displaying inline")
                                          (&td <<-STRING 
                                                  this is also just an experiment.
                                                  it's not always guarantied the right result and not always obvious when and why a
                                                  result is displayed or not.
                                                  Also it affects editing and can sometimes corrupt the entire file.
                                                  In that case only "Revert to old version" helps.
                                                  STRING))
                                     
                                     (&tr (&td  "color editor")
                                          (&td <<-STRING 
                                                  can produce exeptions and corrupt the file.
                                                  Seems not working correctly with os < 10.9
                                                  STRING))
                                     
                                     (&tr (&td  "live evaluation")
                                          (&td <<-STRING 
                                                  live evaluation is very experimental.
                                                  Crashes and all nasty things are possible anytime.
                                                  also files with bad code can can crash the editor at startup.
                                                  Turn off liveEvaluationEnabled in defaults.nu
                                                  STRING))
                                     
                                     (&tr (&td  "parsing")
                                          (&td <<-STRING 
                                                  parsing is not alwys correct or as expected,
                                                  espescally with quote-characters, which are ambiguous,
                                                  but also the new experimental features are not always stable.
                                                  Press reparse to reparse the entire file again.
                                                  
                                                  Also the parser is sometiomes "too fast" and misinterprets
                                                  your intention.
                                                  e.g. < is interpreted as a start of a long symbol but you want to insert an arrow.
                                                  STRING))
                                     
                                     (&tr (&td  "auto indent")
                                          (&td "Indentation is not alwys reliable.\nthis comes true e.g. for $<<- herestrings.\n"))
                                     
                                     (&tr (&td  "much more")
                                          (&td "please help: mailto:heiko.henrich@gmail.com\n")))
                                
                                
                        ))))
     baseURL: nil)

(panel helpView HelpWebView 576 563)

