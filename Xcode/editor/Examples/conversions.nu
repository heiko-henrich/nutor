;; conversions.nu
;;
;; just the conversions of regular strings in herestrings (and back)is implemented here.
;; a lot of refactoring stuff could be implemented here.

(class NuCodeEditor 
 
 (- replaceParser: parser withString: stringToInsert is 
    
    (set range  parser.range)
    (set stringToReplace (self.sourceStorage.string substringWithRange: range))
    (self beginEditing)
    (self.sourceStorage replaceCharactersInRange: range withString: stringToInsert)
    (set parser (self.sourceStorage.parseJob.rootParser parserAt: range.loc))
    (if (ne parser.location
            range.loc)
        ;; this means, it looks like there is no new parser created
        ;; and the returned parser is secondomething else
        (set parser nil))
    (self endEditing)
    parser)
 
 (- convertStringIn: parser is
    (if (and (parser.type isEqualTo: "string")
             (try (parser.cell.car isKindOfClass: NSString)
                  (catch (e) NO)))
        (puts parser.class)
        (self replaceParser: parser 
                 withString:(if (or (parser isKindOfClass: NuInterpolatingHeredocParser)
                                    (parser isKindOfClass: NuHeredocParser))
                                (then parser.cell.car.escapedStringRepresentation)
                                (else parser.cell.car.herestringRepresentation)
                            ))))
)