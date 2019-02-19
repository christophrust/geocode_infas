# geocode_infas

A stata utility as a frontend to the geocoder of infoware now sold by infas360. The geocoder must be installed locally in order to make this utility work.

# License

GPL-3/GPL-2

# Make this utility work:

    git clone https://github.com/christophrust/geocode_infas

then in stata-console, type

    do compile_geocodeinfas.do
    adopath ++ .
    mata mata mlib index

happy geocoding:

    import delimited using restaurants_nuernberg.csv , clear delimiter(";") encoding("utf-8") stringcols(_all)
    keep if addrcity !="" & addrstreet!="" & addrpostcode!="" & addrhousenumber !=""
    geocode_infas , street(addrstreet) strnum(addrhousenumber) plz(addrpostcode) city(addrcity) nclient(1) addressreturn servaddr("PAGSCoder") port(8090) encoding(utf8)


in order to work, the geocoder must receive requests at

http://127.0.0.1:8090/PAGSCoder/.


# Contact

In case, something doesn't work, contact me at christoph.rust@ur.de.