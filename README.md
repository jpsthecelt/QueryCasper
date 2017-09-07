So, this is a swift 3.x experiment to create a command-line utility that will GET-from/PUT-to 
information to Casper, suitable for use in Automation-tools.  
(Currently uses SwiftyJSON & Just libraries).

Initially started out with URLRequest and Alamofire, but both seem problematic in my environment, 
(or I don't fully understand their use in a synchronous scenario), but notwithstanding, I 
finally had success with the library Just (which is patterned after python's requests).
(I should probably study how Just translates requests-style calls to URLRequest ).

jpsinger - incept: 071017, currently: 091017
