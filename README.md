# Nutor
###A Nu Editor

This is an editor for the marvelous Nu programming language.
See Tim Burk's [programming.nu] (http://programming.nu) webseite for more information.

This was not supposed to be a finished work,
more a kind of demo for the NuCodeEditor class, 
a subclass of NSTextView,
but it already works as a good Nu source code editor,
with the support of Apples native NSDocument class (version support)
and extensibility by Nu itself.

There are some additions to the syntax of Nu,
which are just experiments, some more, some less useful.
Press the help button in Nutor.app to see more.
Also there are some examples in the editor directory.
The header files give you some background information.

Some experiments are inspired by live programming,
notabley promoted by Bret Victor (Inventing on principle) and 
Chris Granger (light table).

###The source

####Parser.h/m

At some point I realized, that I couldn't get further with the current Nu parser:
for syntax coloring, debugging etc I needed a more tight connection between the source code and the parsed cells and objects.
So I've written this new parser.
Technically, every item in the source code, be it a list, a symbol or a string, has it's own parser object, an instance of a subclass of NuObjectParser, which connects its location in the code to the list cell, whose car is the parsed object.

Initially not intended, I could implement an incrementally update mechanism: When a part of the source is changed (let's say a new character is typed in) just the affected part of the cell tree is reparsed. 

These two mechanisms made it possible to build an editor  for large source strings, which could immediately react on changes and give the user an immediate feedback.

Parser.h/m should are just depnedent on Nu.m, so they should run on iOS too.
There are plans for an asynchronous remote parser based on this.

Currently the NutorParser replaces as a subclass of NuParser [Nu sharedParser] when included into a project.



####Editor.h/m

The editor doesn't follow the exactly the MVC paradigm.
There are just extensions of the NSTextView and NSTextStorage base classes.
NuSourceStorage is the subclass of NSTextStorage and represents the model layer,
including an undo manager. The original undo manager
of NSTextView didn't like programmatic text changes very well.
And putting the undo manager to the model allows multiple instances of NSTextview 
for one NSTextStorage.

NuCodeEditor inherits from NSTextView and implements a lot of controller functionalities,
like the original NSTextView class too (The view stuff is mostly handled in NSLayoutManager and NSTextContainer).
Most of the nu files extend the functionality fo NuCodeEditor.
See "editor.nu" for the loaded files.

Editor.h/m are dependent on the Parser.h/m and on GCUndoManager,
a NSUndoManager replacement written by Graham Cox.
I've put this in an extra framework, because GCUndoManager is not compiled with ARC.


####Debugger.h/m

Well this is not a Debugger yet, but there are some nasty hacks to implement a step debugger later.
It is used here to get intermediate evaluation results.
See the files in the examples folder.


####Nu.h/m

This is the Nu "rundtime".
It is incoluded here, for two reasons:
1. to compile a standalone executable without dependencies.
2. though I didn't like that, I had to change 2 lines to get this "result inlining" thing working in all circumstances (well almost).
But everything should work fine with the original Nu.h/m which Tim Burks provides in his repository.


####Document.h/m

Here is all the code to get the app working.
Again, all the window controller code is in the
NutorDocument class. 
Also the NutorDocument class got extended in some nu files.
See document.nu.



###What could be done

* auto completion is just dumb.
But it is not trivial to make it better, but there are several possibilities. See completions.nu for more information.
* the UI of the editor could be more consistent
* more conveniance functions ...
* memory management
* finding bugs

###Future Directions

The next step towards a kind of IDE would be a remote parser, which could also work asynchronously in parallel to the editor parser on a client app, which could also run on iOS.
From there I could implement a real debugger with breakpoints etc., which displays information in the editor.
Finally I imagine an IDE, where the source code is not just organized in files, but in smaller chunks like single function or method definitions. These could be ordered by tags, where every chunk could have more than one of them:
One tag for the class, one for the file, one for an informal protocol which is implemented, one for tests, one for a certain functionality and so on.
So these chunks could be grouped together as currently needed and mixed with tests or be just command line kind of "chunks" to try out certain things, which could get easily deleted when they are not needed anymore.
This would more reflect the workflow for coding, at least mine.

