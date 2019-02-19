{smcl}
{* * version 1.3  25jan2016}
{viewerjumpto "Syntax" "geocode_infas##syntax"}{...}
{viewerjumpto "Description" "geocode_infas##description"}{...}
{viewerjumpto "Details" "geocode_infas##details"}{...}
{viewerjumpto "Author" "geocode_infas##author"}{...}
{smcl}
{* 25jan2016}{...}
{cmd:help geocode_infas}
{hline}


{title:Title}

{phang}
{bf:geocode_infas} {hline 2} A stata utility for geocoding with the infoware/infas360 geocoder.


{marker syntax}{...}
{title:Syntax}


{p 8 17 2}
{cmdab:geocode_infas}
	{cmd:,} {cmd:street(}{it:varname}{cmd:)} {cmd:strnum(}{it:varname}{cmd:)} {cmd:plz(}{it:varname}{cmd:)} {cmd:city(}{it:varname}{cmd:)} [{cmd:nclient(}{it:#}{cmd:)}
	{cmd:addressreturn} {cmd:multihit} {cmd:servaddr(}{it:string}{cmd:)} {cmd:idvar(}{it:varname}{cmd:)} {cmd:port(}{it:string}{cmd:)} {cmd:encoding(}{it:string}{cmd:)}
	{cmd:nocleanup} {cmd:timeout(}{it:real}{cmd:)}]

{marker options}{...}
{title:Options}

{synoptset 20 tabbed}{...}
{dlgtab:Required options}

{synopt:{opt street()}} Specifies (string-) variable holding street name. {p_end}

{synopt:{opt strnum()}} Specifies (string-) variable holding housenumber. {p_end}

{synopt:{opt plz()}} Specifies (string-) variable holding zip code. {p_end}

{synopt:{opt city()}} Specifies (string-) variable holding city name. {p_end}

{dlgtab:Optional options}

{synopt:{opt nclient()}} Specifies how many parallel processes, each process has to be able to call its own instance of the geocoder, see details below. {p_end}

{synopt:{opt addressreturn}} If specified, the address of the match is also returned. {p_end}

{synopt:{opt multihit}} In case the geocodeder finds multiple entries for one request, they all will be returned if this option is specified. In this case, however, the dataset will become longer and an identifier variable has to be specified, see next option. {p_end}

{synopt:{opt idvar()}} Specifies an identifier variable, required if option {cmd:multihit} is used. {p_end}

{synopt:{opt servaddr()}} Specifies under which subdirectory the geocoder is available. Most likely this will be "PAGSCoder". {p_end}

{synopt:{opt port()}} Specifies the port where the geocoder is available. {p_end}

{synopt:{opt encoding()}} Specifies the encoding used to encode HTML on the local maching. Either this will be "w1252" (for Windows-1252) or "utf8". Try out which one works for you. {p_end}

{synopt:{opt nocleanup}} Useful for debugging only. {p_end}

{synopt:{opt timeout()}} The timeout for server requests. Defaults to 2 seconds. {p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:geocode_infas} provides an interface to the commercially available geocoder by infoware which is sold by infas360 nowadays. The geocoder has to be installed locally, otherwise this utility will not work.
{cmd:geocode_infas} generates the following variables:

{synoptset 15 tabbed}{...}

{synopt:{opt xWGS84,yWGS84}} longitude and latitude (WGS84) of the geocoded address. {p_end}

{synopt:{opt xGK3,yGK3}} Gauss-Krueger coordinates. {p_end}

{synopt:{opt xUTM32,yUTM32}} UTM32 datum. {p_end}

{synopt:{opt hit_prob:}}Probability of correct match. Has no direct interpretation (in a probabilistic sense), but: the higher, the better...{p_end}

{synopt:{opt quality:}}Quality of match. Look up the manual of the geocoder.{p_end}

{synopt:{opt n_hits:}}Number of hits retured by the geocoder.{p_end}

{synopt:{opt AGS:}}Amtlicher gemeindeschlüssel (who knows what this is, may find it useful).{p_end}

If {cmd:addressreturn} was specified, the following variables will also be added:

{synopt:{opt City_match:}}The city name of the matched entry.{p_end}

{synopt:{opt PLZ_match:}}The ZIP code of the matched entry.{p_end}

{synopt:{opt Street_match:}}The street name of the matched entry.{p_end}

{synopt:{opt Housenumber_match:}}The housenumber of the matched entry.{p_end}


{marker details}{...}
{title:Details}

{p 8 8 2}
In order to be able to make parallel requests and speed up geocoding, several instances of the geocoder have to be deployed at the local machine.
To be compatible with this toolchain, the corresponding web applications have to be named in a special way.
This will hopefully become clear with the following example:

{p 8 8 2}
If the {cmd: servaddr()} option is e.g. "PAGSCoder" (which is also the default value), then the web applications must be named "PAGSCoder", "PAGSCoder1","PAGSCoder2",...,"PAGSCoder{n}" in order to make n+1 requests in parallel.


{marker author}{...}
{title:Author}

Christoph Rust 
Email: {browse "mailto:christoph.rust@stud.uni-regensburg.de":christoph.rust@stud.uni-regensburg.de}


