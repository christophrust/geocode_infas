// change to directory where source files of geocoder are located
cd .

/* load the mlib file */
mata mata mlib index

/* load example data set */
import delimited using restaurants_nuernberg.csv , clear delimiter(";") encoding("utf-8") stringcols(_all)
keep if addrcity !="" & addrstreet!="" & addrpostcode!="" & addrhousenumber !=""


/* run the geocoder */
geocode_infas , street(addrstreet) strnum(addrhousenumber) plz(addrpostcode) city(addrcity) nclient(1) addressreturn servaddr("PAGSCoder") port(8090) encoding("utf-8")
