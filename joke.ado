*! version 0.2 	<Nov 13, 2017> 		Andres Castaneda
*! version 0.1 	<Mar 13, 2014> 		Andres Castaneda
/*===========================================================================
project:       Joke of the Day
Author:        Andres Castaneda 
Dependencies:  The World Bank
---------------------------------------------------------------------------
Creation Date:       March 12, 2014 
Modification Date:   November 14, 2017
Do-file version:    01
References:          
Output:             display joke
===========================================================================*/

/*===============================================================================================
0: Program set up
===============================================================================================*/
version 14.2

program define joke
syntax  [anything(name=lang)] , [topic(string) ]


/*===============================================================================================
1: get joke
===============================================================================================*/

*------------------------------------1.1: set program ------------------------------------

tempfile jokefile temp1
tempname fh 

*------------------------------------1.2: download the data ------------------------------------
qui {
	preserve
	if ("`lang'" == "") local lang "en" 
	local lang = lower("`lang'")
	
	if (regexm("`lang'", "en")) {
		
		local homepage "http://www.short-funny.com/"
		local crlf "`=char(10)'`=char(13)'"
		
		local topics funniest-jokes-2 new-jokes one-liners hilarious-jokes  ///
		pirate-jokes kids-jokes fun-facts marriage-wife-husband-jokes     ///
		redneck-jokes clean-jokes yo-mama-jokes funny-riddles-answers     ///
		dad-jokes funny-quotes best-puns little-johnny-jokes              ///
		cute-jokes best-knock-jokes blonde-jokes funny-sayings            ///
		funny-pick-up-lines bad-jokes cross-the-road-jokes geek-jokes shower-thoughts
		
		local n       `: word count `topics''
		local page    `: word `=round(runiform(0.5,`n'))' of `topics'' 
		local webpage "`homepage'`page'"
		
		tempname html1 html2
		scalar `html1' = fileread("`webpage'.php")
		
		disp `html1'
		disp  "`webpage'.php"
		// find max number of parts in selected topic
		local maxprt ""
		local c = 30
		while ("`maxprt'" == "" & `c' > 0) {
			if regexm(`html1', "[Pp]art `c'") local maxprt `c'
			local --c
		}
		
		// choose random part
		tempname htmljoke htmljoke2
		if ("`maxprt'" != "")  {			
			local part = round(runiform(0.5, `maxprt'))
			if (`part' == 1) local hpart ""
			else             local hpart "-`part'"
			local webpage: subinstr local webpage "-2" "", all // for funniest-jokes-2
			scalar `htmljoke' = fileread("`webpage'`hpart'.php")
		}
		else scalar `htmljoke' = `html1'
		
		// appropriate replacements in order to read the text correctly
		if ("`lrep'" == "") local lrep "LlLl"
		if ("`rrep'" == "") local rrep "RrRr"
		if ("`dblq'" == "") local dblq "DQDQ"
		
		scalar `htmljoke' = subinstr(`htmljoke', uchar(96), "`lrep'",.)  // replace `
		scalar `htmljoke' = subinstr(`htmljoke', uchar(39), "`rrep'",.)  // replace '
		scalar `htmljoke' = subinstr(`htmljoke', uchar(34), "`dblq'",.)  // replace ""
		
		scalar `htmljoke' = subinstr(`htmljoke', "`=uchar(10)'", "c10",.)
		scalar `htmljoke' = subinstr(`htmljoke', "`=uchar(13)'", "c13",.)
		scalar `htmljoke' = subinstr(`htmljoke', `"<hr class=`dblq'linie`dblq'>"', "~",.)
		
		// create local to be parsed
		local cleanj = `htmljoke'
		tokenize `"`cleanj'"', parse(`"~"')
		
		// variable with jokes. One per line. 
		drop _all 
		set obs 500
		tempvar jokes
		gen `jokes' = "" 	
		local c = 3
		local l = 0
		while (`"``c''"' != "") {
			local ++l
			replace `jokes' = `"``c''"' in `l'
			local c = `c' + 2
		}
		
		// treatment of variable with jokes
		replace `jokes' = stritrim(strtrim(`jokes'))
		replace `jokes' = regexs(2) if regexm(`jokes', `"(<div.*</div>)(.*)"')
		drop if regexm(`jokes', "<div|href\=|<[/]?body>|<[/]html>")
		
		drop if `jokes' == ""
		
		replace `jokes' = subinstr(`jokes', "&quot;", `"""', .)
		replace `jokes' = subinstr(`jokes', "&nbsp;", `""', .)
		replace `jokes' = subinstr(`jokes', "&#", `"\`=uchar("', .)  //  "'"'
		replace `jokes' = subinstr(`jokes', ";", `")'"', .)
		replace `jokes' = subinstr(`jokes', uchar(9), " ", .)
		
		local jk = `jokes'[`=round(runiform(0.5, _N))']
		tempname joke
		scalar `joke' = `"`jk'"'
		
		* scalar `joke' = subinstr(`joke', "&#", `"\`=uchar("', .)                    //  "'"'
		scalar `joke' = ustrregexra(`joke', "<br>[ ]?<br>", "`crlf'" , 1)             //  
		scalar `joke' = ustrregexra(`joke', "(<br>[ \-]?<br>|c10c13)", "`crlf'" , 1)  //  
		scalar `joke' = ustrregexra(`joke', "(c13c10)", " " , 1)                      //  
		scalar `joke' = ustrregexra(`joke', "(c10|c13)", " " , 1)                     //  
		scalar `joke' = ustrregexra(`joke', "<br>", "" , 1)                           //  
		scalar `joke' = ustrregexrf(`joke', "^[0-9]+", "")                            //  
		
		scalar `joke' = subinstr(`joke', "`lrep'", uchar(96),.)  // replace `
		scalar `joke' = subinstr(`joke', "`rrep'", uchar(39),.)  // replace '
		scalar `joke' = subinstr(`joke', "`dblq'", uchar(34),.)  // replace ""
		
		
		
		scalar `joke' = "`crlf'" + ustrtrim(`joke') + "`crlf'"
		noi disp as result stritrim(`joke') _n
		
	
		/* 
		disp `"{browse "`webpage'`hpart'.php"}"' _n ///
		`"{stata "copy `webpage'`hpart'.php joke.txt, replace": to stata}"'
		*/
	}
	
	else if (regexm("`lang'", "sp"))  {
		copy "http://www.chistes.com/ChisteAlAzar.asp?n=3" `jokefile', replace
		* filter left and right quotes 
		filefilter `chiste' `temp1', from("\LQ") to("LLLQ") replace
		filefilter `temp1' `chiste', from("\RQ") to("RRRQ") replace
		
		file open `fh' using `chiste', read
		file read `fh' line
		
		
		*------------------------------------1.3: clean lines ------------------------------------
		local current 0
		while r(eof)==0 {
			
			if regexm(`"`line'"',`"<div class="chiste">"')     local current 1
			if (`current' == 1) {
				local line: subinstr local line `"<div class="chiste">"' "", all
				local line: subinstr local line `"</div>"' "", all
				local line: subinstr local line "<BR>" "", all
				local line: subinstr local line "LLLQ" "`", all 	// '" put Left quote back
				local line: subinstr local line "RRRQ" "'", all		// put right quote back
				
				* display when joke is found
				if !regexm(`"`line'"',`"<div class="opciones">"') {
					local l = length(`"`line'"')
					
					* trim on the 80th column for long lines
					while (`l' > 80) {
						local d = substr(`"`line'"', 1, 80)
						if regexm(`"`d'"',"[a-zA-Z\.]$") local dash "-"
						else local dash ""
						noi disp in g `"`d'`dash'"'
						local line = substr(`"`line'"', 81, .)
						local l = length(`"`line'"')
					}
					if (`l' <= 80) noi disp in green `"`line'"'
				}
			}	//  end of (`current' == 1) condition
			
			if (regexm(`"`line'"',`"<div class="opciones">"') & (`current' == 1))  {
				file close `fh'
				exit
			}
			
			file read `fh' line
		} //  end of while r(eof) == 0
	}
	
	else {
		noi disp in red "You must specify a joke either in {ul:En}glish or {ul:S}panish"
		error
	}
	
	
	
} //  end of qui

end

exit
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

Notes:
1.
2.
3.


Version Control:

version 0.1 	<Mar 13, 2014> 		Andres Castaneda


drop _all
set obs 500000

tempfile file
tempname myfile
* copy "https://www.ajokeaday.com/jokes/random" `file', replace
copy "view-source:https://www.ajokeaday.com/jokes/random" `file', replace

gen line = .
gen selection = .
gen strL code = ""

file open `myfile' using "`file'"  , read 
file read `myfile' line
local i = 1
qui while r(eof)==0 {
	replace line = `i' in `i'
	replace code = `"`macval(line)'"' in `i'
	file read `myfile' line
	local i = `i' + 1
}

cap drop ident 
gen ident = . 
replace ident = 1 if regexm(code, `"^[ \t]+data-description="')
sum line if ident == 1
replace ident = 2 if regexm(code, `"^[ \t]+data-share-description="') & line >= r(mean)
sum line if ident != .

replace ident = 1 if inrange(line, r(min), `=r(max)-1') 
cap drop newline
gen newline = code if ident == 1
list newline if newline != ""
replace newline = subinstr(newline, `"data-description=""', "", .)
replace newline = subinstr(newline, `"`=char(9)'"', "", .)
replace newline = ltrim(newline)
replace newline = subinstr(newline, `"&quot;"',`"""', .)
replace newline = subinstr(newline, `"&#39;"',"`=char(39)'", .)


compress
list newline if newline != ""
levelsof line if newline != "", local(lines)

local crlf "`=char(10)'`=char(13)'" 
scalar s_joke = ""
foreach line of local lines {
	local ltext: disp newline[`line'] 
	scalar s_joke = s_joke + `"`crlf'`ltext'"'
} 

disp s_joke



noi disp as result ltrim(rtrim(itrim(`joke')))