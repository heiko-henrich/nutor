;; web view demo
;;
;; press eval, change html and see the changes immediately

((editor) set: (liveEvaluationEnabled: YES))

(load "playground")
(load "WebKit")

(set webview (playground WebView 400 400))

^(set $html
      (&html 
          (&body style: "font-family: Arial;"
                 (&h2 "A Header")
                 (&table     border: "1" 
                        cellspacing:"40%" 
                              style:"width: 100%;  vertical-align: top;"
                             
                             (&tbody (&tr (&td style:"width: 40px; "  
                                               "1")
                                          (&td "first row\n"))
                                     
                                     ?(&tr (&td "2")
                                           (&td "second row with calculation 2 + 3 = #{(+ 2 3)}" )) => "<tr><td>2</td><td>second row with calculation 2 + 3 = 5</td></tr>"
                                     
                                     ?(&tr (&td "3")
                                           (&td <<+STRING
                                                   that's possible too <br> 
                                                   silly.
                                                   STRING )) => <<+STRING
                                                                   <tr><td>3</td><td>that's possible too <br> 
                                                                   silly.
                                                                   </td></tr>STRING
                             ))
                 (&h2 "Nu Programming Language")
                 (&p "Click: " (&a href: "http://www.programming.nu" "programming.nu")))
      ) 
   -? => <<+STRING
            <!DOCTYPE html><html><body style=\"font-family: Arial;\"><h2>A Header</h2><table border=\"1\" cellspacing=\"40%\" style=\"width: 100%;  vertical-align: top;\"><tbody><tr><td style=\"width: 40px; \">1</td><td>first row
            </td></tr><tr><td>2</td><td>second row with calculation 2 + 3 = 5</td></tr><tr><td>3</td><td>that's possible too <br> 
            silly.
            </td></tr></tbody></table><h2>Nu Programming Language</h2><p>Click: <a href=\"http://www.programming.nu\">programming.nu</a></p></body></html>STRING)


^(webview.mainFrame loadHTMLString: $html baseURL: nil)

