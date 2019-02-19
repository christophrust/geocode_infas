# geocode_infas

A stata utility as a frontend to the geocoder of infoware now sold by infas360. The geocoder must be installed locally in order to make this utility work.

# License

GPL-3/GPL-2

# Make this utility work:

    git clone https://github.com/christophrust/geocode_infas.git

then in stata-console, type

    do compile_lgeocodeinfas.do
    adopath ++ .
    mata mata mlib index

happy geocoding:

    import delimited using restaurants_nuernberg.csv , clear delimiter(";") encoding("utf-8") stringcols(_all)
    keep if addrcity !="" & addrstreet!="" & addrpostcode!="" & addrhousenumber !=""
    geocode_infas , street(addrstreet) strnum(addrhousenumber) plz(addrpostcode) city(addrcity) nclient(1) addressreturn servaddr("PAGSCoder") port(8090) encoding(utf8)


in order to work with the above example, the geocoder must receive requests at

http://127.0.0.1:8090/PAGSCoder/.

# Parallel requests

The tool is designed to manage multiple requests in parallel. One, therefore, has to deploy the geocoder multiple times and name the web applications as follows:

- PAGSCoder, PAGSCoder1, PAGSCoder2,...

such that they are available at

http://127.0.0.1:8090/PAGSCoder/, http://127.0.0.1:8090/PAGSCoder1/, http://127.0.0.1:8090/PAGSCoder2/, ...

In order to make parallel requests, invoke the geocoder from within stata by specifying the nclient() option

    geocode_infas , street(addrstreet) strnum(addrhousenumber) plz(addrpostcode) city(addrcity) nclient(10) addressreturn servaddr("PAGSCoder") port(8090) encoding(utf8)

where 10 sessions will be used in parallel for geocoding.


# Contact

In case, something doesn't work, contact me at christoph.rust [at] ur.de.