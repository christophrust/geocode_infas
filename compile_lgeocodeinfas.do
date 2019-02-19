clear mata
** ********************************************************************
** ********************************************************************
** Additional Mata Functions
** ********************************************************************


mata

function infas_geocode_request( string url , real addressreturn , real MaxHitReturn ) {

	// printf("test")
	if (addressreturn ==0) {
		results_len = 9
		}
	else {
		results_len = 13
	}
	
	/* request and read response of infas, see also PAGSCoder Installation Guide */
	fh = _fopen(url , "r")
	if (fh >= 0 ) {
		file = ""
		while ((line=fget(fh))!=J(0,0,"")) {
			//printf(line)
			file = file+line
			}
		fclose(fh)
		// printf(file)
		/* parse output */
		if (regexm(file, "<status><code>NO_HIT</code>") | regexm(file, "Unknown geocoder query")) {
			ret_code = "1"
			n_hits = "0"
			result = J(1, results_len, "")
			
		} else if (regexm(file, "<status><code>ERROR</code>")) {
			ret_code = "2"
			n_hits = ""
			result = J(1, results_len, "")
			
		} else if (regexm(file, "<status><code>SINGLE_HIT</code>")) {
			ret_code = "0"
			n_hits = "1"
			// printf("SINGLE_HIT")
			if (regexm(file , "<addresses>.*</addresses>")) {
				addresses = regexs(0)
				
				/* retrieve all required values */
				
				//printf("check")
				result = parse_vals(addresses , addressreturn)
				//printf("check1")
			}
			
		} else if (regexm(file, "<status><code>MULTI_HIT</code>")) {
			ret_code = "0"
			// printf("MULTI_HIT\n")
			if (regexm(file , "(<resultCount>)([0-9]+)(</resultCount>)")) {
				n_hits = regexs(2)
				//n_hits 
				// printf("Number of Results: ")
				n_hits_numeric = strtoreal(n_hits)
				
				results = J(n_hits_numeric , results_len, "")
				if (regexm(file , "<addresses>.*</addresses>")) {
					addresses = regexs(0)
					addresses = regexr(addresses ,"<addresses>" , "SEP0")
					nMaxHit = 0
					//nMaxHit 
					while (regexm(addresses , "</address><address>")) {
						nMaxHit = nMaxHit +1
						addresses = regexr(addresses ,"</address><address>"  , "</address>SEP" +strofreal(nMaxHit) +  "<address>" )
					}
					nMaxHit = nMaxHit +1
					addresses = regexr(addresses ,"</addresses>" , "SEP"+strofreal(nMaxHit)+"<")
					//addresses
					//"check"
					for (i=1 ; i<=nMaxHit;i++) {
						pattern = "(SEP" + strofreal(i-1) + "<address>)(.+)(</address>SEP" + strofreal(i)+ "<)"
						if (regexm(addresses , pattern)) {
							addr_chunk = regexs(2)
							
							// "\n----------------------"+ strofreal(i) +"----------------------------"
							// addr_chunk
							// addressreturn
							// parse_vals(addr_chunk , addressreturn)
							results[i,.] = parse_vals(addr_chunk , addressreturn)
						}
						else {
							printf("XML structure not valid"+ strofreal(i))
						}
					}
					
					/* make sure, it is sorted wrt to hit probability */
					results  = sort(results , -7)
					//results
					if (MaxHitReturn>0) {
						result = results[range(1,min((MaxHitReturn,n_hits_numeric)),1),.]
					}
					else {
						result = results[range(1,nMaxHit,1),.]
					}
					//result
				}
			}
			else {
				printf("returned XML-Structure does not meet its description")
			}
		}
		//result
	
		// printf(file)
	} // file was opened successfully
	else {
		// printf("request was not successfull")
		n_hits = ""
		result = J(1, results_len, "")		
		ret_code = "3"
	}
	// printf("test")
	nRetHits = rows(result)
	//nRetHits 
	ret_code = J(nRetHits , 1 , ret_code)
	n_hits = J(nRetHits , 1 , n_hits)
	return_all = (result , ret_code, n_hits)
	//return_all 
	//printf("test")
	return(return_all)
}





void main_infas_geocode( string var_street , string var_strnum , string var_city , string var_plz , real addressreturn , string servDir , string port) {
	data = st_sdata(. , (var_street , var_strnum , var_city , var_plz ))
	n_obs = rows(data)
	res = J(n_obs,9,.)
	qual = J(n_obs,1,"")
	ags = J(n_obs,1,"")
	idx = st_addvar("double",("xWGS84","yWGS84","xGK3","yGK3","xUTM32" ,"yUTM32" , "hit_prob", "ret_code","n_hits"))
	idx = st_addvar("str4",("quality"))
	idx = st_addvar("str27",("AGS"))
	
	if (addressreturn==0) {
		retCodeIdx = 10
	}
	else {
		retCodeIdx = 14
		addr = J(n_obs , 4 , "")
	}
	
	val = setbreakintr(0)
	lastval = -1
	lastvalp = -1
	for (i=1 ; i<=n_obs ; i++) {
		// i
		street = strrtrim(data[i,1])
		strnum = data[i,2]
		city   = strrtrim(data[i,3])
		plz    = data[i,4]
		
		/* umlaute and space replace to html */
		// "test1"
		street = UmlautToHtml(street)
		strnum = UmlautToHtml(strnum)
		// "test2"
		city = UmlautToHtml(city)
		// "test3"

	
		server = "http://127.0.0.1:" + port + "/" + servDir + "/"
		baseaddr = "servlet/SrvGeocoder?RTVDIR=xml&RTVMODE=0&RTVRESTRICTIONHIT=32&RTVSTR="
		url = server + baseaddr + street + "&RTVHNR=" + strnum + "&RTVPLZ=" + plz + "&RTVORT=" + city
		// url
		result = infas_geocode_request(url , addressreturn , 1 )

		nHitIdx = retCodeIdx +1
		//retCodeIdx
		//(1,2,3,4,5,6,8,retCodeIdx , nHitIdx)
		// result
		res[i,.] = strtoreal(result[(1,2,3,4,5,6,8,retCodeIdx , nHitIdx)])
		 //res[i,.]
		qual[i,] = result[9]
		ags[i,] = result[7]
		//qual[i,]
		if (addressreturn==1) {
			addr[i,.] = result[(10,11,12,13)]
			//addr[i,.]
		}
		// "test5"
		progress = floor(i/n_obs*(80-23))
		progressp = floor(i/n_obs*10)
		if (progress > lastval) {
			if (progressp > lastvalp) {						
				msg = strofreal(progressp*10) +"%%"
				printf(msg)
				displayflush()
				lastvalp = progressp
			}
			else {
				printf("-")
				displayflush()
			}
			lastval = progress
		}
		// "loopend"
	}
	if(breakkey()) {
		if (addressreturn==1){
			// result = ( xWGS84  , yWGS84 , xGK3  , yGK3  , xUTM32  , yUTM32  , hitprobability  , quality , foundCity , foundPLZ , foundStreet , foundHousenumber)
			/* determine length of each string */
			maxLenCty = max( (strlen(addr[.,1])\1))
			maxLenStr = max( (strlen(addr[.,3])\1))
			maxLenHN = max( (strlen(addr[.,4])\1))
			idx = st_addvar( "str"+strofreal(maxLenCty) , ("City_match"))
			idx = st_addvar( "str5" , ("PLZ_match"))
			idx = st_addvar( "str"+strofreal(maxLenStr) , ("Street_match"))
			idx = st_addvar( "str"+strofreal(maxLenHN) , ("Housenumber_match"))
			st_sstore(.,("City_match","PLZ_match","Street_match" ,"Housenumber_match"),addr)
		}

		st_store(.,("xWGS84","yWGS84","xGK3","yGK3","xUTM32" ,"yUTM32", "hit_prob", "ret_code", "n_hits"),res)
		st_sstore(.,("quality"),qual)
		st_sstore(.,("AGS"),ags)
		
		(void) setbreakintr(val)
		exit
	}

	if (addressreturn==1){
		// result = ( xWGS84  , yWGS84 , xGK3  , yGK3  , xUTM32  , yUTM32  , hitprobability  , quality , foundCity , foundPLZ , foundStreet , foundHousenumber)
		/* determine length of each string */
		maxLenCty = max( (strlen(addr[.,1])\1))
		// maxLenCty 
		maxLenStr = max( (strlen(addr[.,3])\1))
		//maxLenStr
		maxLenHN = max( (strlen(addr[.,4])\1))
		// maxLenHN
		idx = st_addvar( "str"+strofreal(maxLenCty) , ("City_match"))
		idx = st_addvar( "str5" , ("PLZ_match"))
		idx = st_addvar( "str"+strofreal(maxLenStr) , ("Street_match"))
		idx = st_addvar( "str"+strofreal(maxLenHN) , ("Housenumber_match"))
		st_sstore(.,("City_match","PLZ_match","Street_match" ,"Housenumber_match"),addr)
		
	}

	st_store(.,("xWGS84","yWGS84","xGK3","yGK3","xUTM32" ,"yUTM32" , "hit_prob", "ret_code", "n_hits"),res)
	st_sstore(.,("quality"),qual)
	st_sstore(.,("AGS"),ags)
	
	(void) setbreakintr(val)
}


/* ******************************************** */
/* Multihit */
void main_infas_geocode_multiple( string var_id ,  string var_street , string var_strnum , string var_city , string var_plz , real addressreturn , string servDir, string port) {
	data = st_sdata(. , (var_street , var_strnum , var_city , var_plz ))
	orig_id = st_data(.,(var_id))
	n_obs = rows(data)
	res = J(0,9,.)
	qual = J(0,1,"")
	new_id = J(0,1,.)
	ags = J(0,1,"")
	
	if (addressreturn==0) {
		retCodeIdx = 10
	}
	else {
		retCodeIdx = 14
		addr = J(0 , 4 , "")
	}
	
	val = setbreakintr(0)
	lastval = -1
	lastvalp = -1
	for (i=1 ; i<=n_obs ; i++) {
	// i
		
		street = strrtrim(data[i,1])
		strnum = strrtrim(data[i,2])
		city   = strrtrim(data[i,3])
		plz    = data[i,4]
		id = orig_id[i,1]
		
		/* umlaute and space replace to html */
		street = UmlautToHtml(street)
		strnum = UmlautToHtml(strnum)
		city = UmlautToHtml(city)
	
		server = "http://127.0.0.1:" + port + "/" + servDir + "/"
		baseaddr = "servlet/SrvGeocoder?RTVDIR=xml&RTVMODE=0&RTVRESTRICTIONHIT=32&RTVSTR="
		url = server + baseaddr + street + "&RTVHNR=" + strnum + "&RTVPLZ=" + plz + "&RTVORT=" + city
		// url
		result = infas_geocode_request(url , addressreturn , 10 )
		// result
		
		new_id = (new_id \ J(rows(result) , 1 , id) )
		
		nHitIdx = retCodeIdx +1
		
		
		/** Result containing geocode and hit_probability and returncode and n_hit */
		/** Result containing geocode and hit_probability and returncode and n_hit */
		res = (res \ strtoreal(result[.,(1,2,3,4,5,6,8,retCodeIdx , nHitIdx)]))
		// res
		/** QUAL **************************************************************/
		qual = (qual \ result[.,9] )
		// qual
		/** AGS ***************************************************************/
		ags = (ags \ result[., 7] )
		// ags
		
		/** MATCHED ADRESS ****************************************************/
		if (addressreturn==1) {
			addr = (addr \ result[.,(10,11,12,13)] )
			//addr[i,.]
		}
		//if (i<100 & i>2) res[(i-2 ,i-1,i),.]	

		
		progress = floor(i/n_obs*(80-23))
		progressp = floor(i/n_obs*10)
		if (progress > lastval) {
			if (progressp > lastvalp) {						
				msg = strofreal(progressp*10) +"%%"
				printf(msg)
				displayflush()
				lastvalp = progressp
				}
			else {
				printf("-")
				displayflush()
				}
			lastval = progress
			}
	}
	if(breakkey()) {
		idx = st_dropvar(.)
		idx = st_addvar("double",(var_id,"xWGS84","yWGS84","xGK3","yGK3","xUTM32" ,"yUTM32", "hit_prob", "ret_code","n_hits"))
		idx = st_addvar("str4",("quality"))	
		idx = st_addobs(rows(new_id))
		idx = st_addvar("str27",("AGS"))
		if (addressreturn==1){
			// result = ( xWGS84  , yWGS84 , xGK3  , yGK3  , xUTM32  , yUTM32  , hitprobability  , quality , foundCity , foundPLZ , foundStreet , foundHousenumber)
			/* determine length of each string */
			maxLenCty = max( (strlen(addr[.,1])\1))
			maxLenStr = max( (strlen(addr[.,3])\1))
			maxLenHN = max( (strlen(addr[.,4])\1))
			idx = st_addvar( "str"+strofreal(maxLenCty) , ("City_match"))
			idx = st_addvar( "str5" , ("PLZ_match"))
			idx = st_addvar( "str"+strofreal(maxLenStr) , ("Street_match"))
			idx = st_addvar( "str"+strofreal(maxLenHN) , ("Housenumber_match"))
			idx = st_sstore(.,("City_match","PLZ_match","Street_match" ,"Housenumber_match"),addr)
		}
	
		idx = st_store(.,(var_id,"xWGS84","yWGS84","xGK3","yGK3","xUTM32" ,"yUTM32" , "hit_prob", "ret_code", "n_hits"), (new_id , res))
		idx = st_sstore(.,("quality"),qual)
		idx = st_sstore(.,("AGS"),ags)
		
		(void) setbreakintr(val)
		exit
	}
	idx = st_dropvar(.)
	idx = st_addvar("double",(var_id,"xWGS84","yWGS84","xGK3","yGK3","xUTM32" ,"yUTM32" , "hit_prob", "ret_code","n_hits"))
	idx = st_addvar("str4",("quality"))
	idx = st_addvar("str27",("AGS"))
	idx = st_addobs(rows(new_id))
	// rows(new_id)
	if (addressreturn==1){
		
		// result = ( xWGS84  , yWGS84 , xGK3  , yGK3  , xUTM32  , yUTM32  , hitprobability  , quality , foundCity , foundPLZ , foundStreet , foundHousenumber)
		/* determine length of each string */
		maxLenCty = max( (strlen(addr[.,1])\1))
		// maxLenCty 
		maxLenStr = max( (strlen(addr[.,3])\1))
		//maxLenStr
		maxLenHN = max( (strlen(addr[.,4])\1))
		// maxLenHN
		idx = st_addvar( "str"+strofreal(maxLenCty) , ("City_match"))
		idx = st_addvar( "str5" , ("PLZ_match"))
		idx = st_addvar( "str"+strofreal(maxLenStr) , ("Street_match"))
		idx = st_addvar( "str"+strofreal(maxLenHN) , ("Housenumber_match"))
		idx = st_sstore(.,("City_match","PLZ_match","Street_match" ,"Housenumber_match"),addr)
		
	}
	
	
	idx = st_store(.,(var_id,"xWGS84","yWGS84","xGK3","yGK3","xUTM32" ,"yUTM32", "hit_prob", "ret_code", "n_hits"),(new_id , res))
	idx = st_sstore(.,("quality"),qual)
	idx = st_sstore(.,("AGS"),ags)
	
	(void) setbreakintr(val)
}


function UmlautToUrl(string StrWUml) {
	StrWoUml = StrWUml
	while (regexm( StrWoUml , " ")) {
		StrWoUml  = regexr( StrWoUml , " " , "+")
	}
	while (regexm(StrWoUml  , "ß")) {
		StrWoUml  = regexr( StrWoUml  , "ß" , "C3%9F")
	}
	while (regexm(StrWoUml  , "Ä")) {
		StrWoUml  = regexr( StrWoUml  , "Ä" , "%C3%84")
	}
	while (regexm(StrWoUml  , "ä")) {
		StrWoUml  = regexr( StrWoUml  , "ä" , "%C3%A4")
	}
	while (regexm(StrWoUml  , "Ö")) {
		StrWoUml  = regexr( StrWoUml  , "Ö" , "+%C3%96")
	}
	while (regexm(StrWoUml  , "ö")) {
		StrWoUml  = regexr( StrWoUml  , "ö" , "%C3%B6")
	}
	while (regexm(StrWoUml  , "Ü")) {
		StrWoUml  = regexr( StrWoUml  , "Ü" , "+%C3%9C")
	}
	while (regexm(StrWoUml  , "ü")) {
		StrWoUml  = regexr( StrWoUml  , "ü" , "%C3%BC")
	}
	return(StrWoUml)
}


function UmlautToHtml(string stringwithuml) {
	StrWoUml = stringwithuml
	while (regexm( StrWoUml , " ")) {
		StrWoUml  = regexr( StrWoUml , " " , "+")
	}
	while (regexm(StrWoUml  , "ß")) {
		StrWoUml  = regexr( StrWoUml  , "ß" , "%DF")
	}
	while (regexm(StrWoUml  , "Ä")) {
		StrWoUml  = regexr( StrWoUml  , "Ä" , "%C4")
	}
	while (regexm(StrWoUml  , "ä")) {
		StrWoUml  = regexr( StrWoUml  , "ä" , "%E4")
	}
	while (regexm(StrWoUml  , "Ö")) {
		StrWoUml  = regexr( StrWoUml  , "Ö" , "%D6")
	}
	while (regexm(StrWoUml  , "ö")) {
		StrWoUml  = regexr( StrWoUml  , "ö" , "%F6")
	}
	while (regexm(StrWoUml  , "Ü")) {
		StrWoUml  = regexr( StrWoUml  , "Ü" , "%DC")
	}
	while (regexm(StrWoUml  , "ü")) {
		StrWoUml  = regexr( StrWoUml  , "ü" , "%FC")
	}
	return(StrWoUml)
}

function UmlautToHtmlOld(string stringwithuml) {
	StrWoUml = stringwithuml
	while (regexm( StrWoUml , " ")) {
		StrWoUml  = regexr( StrWoUml , " " , "&ensp")
	}
	while (regexm(StrWoUml  , "ß")) {
		StrWoUml  = regexr( StrWoUml  , "ß" , "&szlig")
	}
	while (regexm(StrWoUml  , "Ä")) {
		StrWoUml  = regexr( StrWoUml  , "Ä" , "&Auml")
	}
	while (regexm(StrWoUml  , "ä")) {
		StrWoUml  = regexr( StrWoUml  , "ä" , "&auml")
	}
	while (regexm(StrWoUml  , "Ö")) {
		StrWoUml  = regexr( StrWoUml  , "Ö" , "&Ouml")
	}
	while (regexm(StrWoUml  , "ö")) {
		StrWoUml  = regexr( StrWoUml  , "ö" , "&ouml")
	}
	while (regexm(StrWoUml  , "Ü")) {
		StrWoUml  = regexr( StrWoUml  , "Ü" , "&Uuml")
	}
	while (regexm(StrWoUml  , "ü")) {
		StrWoUml  = regexr( StrWoUml  , "ü" , "&uuml")
	}
	return(StrWoUml)
}

function HtmlToUmlaut(string StrWoUml) {
	StrWUml = StrWoUml
	while (regexm( StrWUml , "&ensp")) {
		StrWUml  = regexr( StrWUml  , "&ensp", " ")
	}
	while (regexm(StrWUml  , "&szlig")) {
		StrWUml  = regexr( StrWUml  , "&szlig" , "ß" )
	}
	while (regexm(StrWUml  , "&Auml" )) {
		StrWUml  = regexr( StrWUml  , "&Auml", "Ä" )
	}
	while (regexm(StrWUml  , "&auml")) {
		StrWUml  = regexr( StrWUml   , "&auml" , "ä" )
	}
	while (regexm(StrWUml  , "&Ouml")) {
		StrWUml  = regexr( StrWUml  , "&Ouml", "Ö" )
	}
	while (regexm(StrWUml  , "&ouml")) {
		StrWUml  = regexr( StrWUml  , "&ouml", "ö" )
	}
	while (regexm(StrWUml  , "&Uuml")) {
		StrWUml  = regexr( StrWUml  , "&Uuml", "Ü" )
	}
	while (regexm(StrWUml  , "&uuml")) {
		StrWUml  = regexr( StrWUml   , "&uuml" , "ü")
	}
	return(StrWUml)
}

function UnicodeToUmlaut(string StrWoUml) {
	StrWUml = StrWoUml
	while (regexm( StrWUml , "&#160;")) {
		StrWUml  = regexr( StrWUml  , "&#160;", " ")
	}
	while (regexm(StrWUml  , "&#xDF;")) {
		StrWUml  = regexr( StrWUml  , "&#xDF;" , "ß" )
	}
	while (regexm(StrWUml  , "&#xC4;" )) {
		StrWUml  = regexr( StrWUml  , "&#xC4;", "Ä" )
	}
	while (regexm(StrWUml  , "&#xE4;")) {
		StrWUml  = regexr( StrWUml   , "&#xE4;" , "ä" )
	}
	while (regexm(StrWUml  , "&#xD6;")) {
		StrWUml  = regexr( StrWUml  , "&#xD6;", "Ö" )
	}
	while (regexm(StrWUml  , "&#xF6;")) {
		StrWUml  = regexr( StrWUml  , "&#xF6;", "ö" )
	}
	while (regexm(StrWUml  , "&#xDC;")) {
		StrWUml  = regexr( StrWUml  , "&#xDC;", "Ü" )
	}
	while (regexm(StrWUml  , "&#xFC;")) {
		StrWUml  = regexr( StrWUml   , "&#xFC;" , "ü")
	}
	return(StrWUml)
}


function parse_vals( string addr_chunk , real addressreturn) {
	// printf(match)
	
	/* initialize all values to empty strings */	
	xWGS84 = ""
	yWGS84 = ""
	xGK3 = ""
	yGK3 = ""
	xUTM32 = ""
	yUTM32 = ""
	AGS = ""
	
	foundCity = ""
	foundPLZ = ""
	foundStreet = ""
	foundHousenumber = ""
	
	hitprobability = ""
	quality = ""
	
	
	/* x_WGS84, y_WGS84 */
	if (regexm(addr_chunk , "(<x_WGS84>)([0-9]+\.[0-9]+)(</x_WGS84>)")) {
		xWGS84 = regexs(2)
		// printf(xWGS84)
	}
	if (regexm(addr_chunk , "(<y_WGS84>)([0-9]+\.[0-9]+)(</y_WGS84>)")) {
		yWGS84 = regexs(2)
		// printf(yWGS84)
	}
	
	/* x_GK3, y_GK3 */
	if (regexm(addr_chunk , "(<x_GK3>)([0-9]+\.[0-9]+)(</x_GK3>)")) {
		xGK3 = regexs(2)
	}
	if (regexm(addr_chunk , "(<y_GK3>)([0-9]+\.[0-9]+)(</y_GK3>)")) {
		yGK3 = regexs(2)
	}
	
	/* x_UTM32, y_UTM32 */
	if (regexm(addr_chunk , "(<x_UTM32>)([0-9]+\.[0-9]+)(</x_UTM32>)")) {
		xUTM32 = regexs(2)
	}
	if (regexm(addr_chunk , "(<y_UTM32>)([0-9]+\.[0-9]+)(</y_UTM32>)")) {
		yUTM32 = regexs(2)
	}
	/*  AGS22 */
	if (regexm(addr_chunk , "(<ags27>)([0-9]+)(</ags27>)")) {
		AGS = regexs(2)
	} else if (regexm(addr_chunk , "(<ags22>)([0-9]+)(</ags22>)")) {
		AGS = regexs(2)
		// AGS = regexs(2) + "00000"
	} else if (regexm(addr_chunk , "(<ags20>)([0-9]+)(</ags20>)")) {
		// AGS = regexs(2) + "0000000"
		AGS = regexs(2)
	} else if (regexm(addr_chunk , "(<ags16>)([0-9]+)(</ags16>)")) {
		// AGS = regexs(2) + "00000000000"
		AGS = regexs(2)
	} else if (regexm(addr_chunk , "(<ags13>)([0-9]+)(</ags13>)")) {
		// AGS = regexs(2) + "00000000000000"
		AGS = regexs(2)
	} else if (regexm(addr_chunk , "(<ags11>)([0-9]+)(</ags11>)")) {
		// AGS = regexs(2) + "0000000000000000"
		AGS = regexs(2)
	}else if (regexm(addr_chunk , "(<ags8>)([0-9]+)(</ags8>)")) {
		// AGS = regexs(2) + "0000000000000000000"
		AGS = regexs(2)
	}else if (regexm(addr_chunk , "(<ags5>)([0-9]+)(</ags5>)")) {
		// AGS = regexs(2) + "0000000000000000000000"
		AGS = regexs(2)
	}else if (regexm(addr_chunk , "(<ags3>)([0-9]+)(</ags3>)")) {
		// AGS = regexs(2) + "000000000000000000000000"
		AGS = regexs(2)
	}else if (regexm(addr_chunk , "(<ags2>)([0-9]+)(</ags2>)")) {
		// AGS = regexs(2) + "0000000000000000000000000"
		AGS = regexs(2)
	} else {
		AGS = ""
	}

	/* hitprobability */
	if (regexm(addr_chunk , "(<hitprobability>)([0-9]+)(</hitprobability>)")) {
		hitprobability = regexs(2)
	}
	
	/* quality */
	if (regexm(addr_chunk , "(<quality>)([A-Z]+)(</quality>)")) {
		quality = regexs(2)
	}
	
	/* found adress */
	if (addressreturn==1) {
		if (regexm(addr_chunk , "(<city>)(.*)(</city>)")) {
			//regexs(2)
			foundCity = UnicodeToUmlaut( regexs(2) ) // htmltoUmlaut!!!!!
			//foundCity
		}
		if (regexm(addr_chunk , "(<zipcode>)(.*)(</zipcode>)")) {
			foundPLZ = regexs(2)
		}
		if (regexm(addr_chunk , "(<street>)(.*)(</street>)")) {
			//regexs(2)
			foundStreet = UnicodeToUmlaut(regexs(2))
			//foundStreet
		}
		if (regexm(addr_chunk , "(<housenumber>)([0-9 ]*[a-z]*)(</housenumber>)")) {
			foundHousenumber = regexs(2)
		}
		result = ( xWGS84  , yWGS84 , xGK3  , yGK3  , xUTM32  , yUTM32 , AGS , hitprobability  , quality , foundCity , foundPLZ , foundStreet , foundHousenumber)
	}
	else {
		result = ( xWGS84  , yWGS84 , xGK3  , yGK3  , xUTM32  , yUTM32 ,AGS , hitprobability  , quality)
	}
	//result
	return(result)
}


end

mata 
mata mlib create lgeocodeinfas , replace

mata mlib add lgeocodeinfas infas_geocode_request() main_infas_geocode() main_infas_geocode_multiple() parse_vals() UmlautToUrl() UmlautToHtml() HtmlToUmlaut() UnicodeToUmlaut()

end 
