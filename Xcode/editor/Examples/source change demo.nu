;; source change demo.nu
;;
;; press eval and change the source code automatically

(set test1 '(123445345345345))
(set test2 '("that's weired"))


(set string1 test1.parser.source)-? => "\"that's weired\""
(set string2 test2.parser.source)-? => "123445345345345"

?((editor) replaceParser: test1.parser withString: string2) => <NuSymbolAndNumberParser:6080004d9130>
?((editor) replaceParser: test2.parser withString: string1) => <NuInterpolationStringParser:60800033edc0>

