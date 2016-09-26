xquery version "1.0-ml";

(:~
: User: phoehne
: Date: 9/12/16
: Time: 2:26 PM
: To change this template use File | Settings | File Templates.
:)

module namespace xlat = "http://dveivr.dha.health.mil/ext/lib/value-translators.xqy";

declare function xlat:xlat-gender($gender-raw as xs:string) as xs:string {
    if ($gender-raw = ("F", "Female", "f", "female"))
    then
        "Female"
    else if($gender-raw = ("M", "Male", "m", "male"))
    then
        "Male"
    else
        "Unknown"
};

declare function xlat:xlat-service-branch($branch-raw as xs:string) as xs:string {
    if (fn:upper-case(fn:normalize-space($branch-raw)) = ("USMC", "MARINE", "MARINES"))
    then
        "Marine Corps"
    else if(fn:upper-case(fn:normalize-space($branch-raw)) = ("ARMY"))
    then
        "Army"
    else if(fn:upper-case(fn:normalize-space($branch-raw)) = ("AIR FORCE", "USAF"))
        then
            "Air Force"
        else if(fn:upper-case(fn:normalize-space($branch-raw)) = ("NAVY", "USN"))
            then
                "Navy"
            else if(fn:upper-case(fn:normalize-space($branch-raw)) = ("COAST GUARD", "USCG"))
                then
                    "Coast Guard"
                else
                    "Unknwon"
};

declare function xlat:xlat-service-status($status as xs:string) as xs:string {
    if (fn:upper-case($status) = ("N/A"))
    then
        "N/A"
    else if(fn:upper-case($status) = ("ACTIVE"))
    then
        "Active"
    else if(fn:upper-case($status) = ("INACTIVE"))
        then
            "Inactive"
        else
            "Unknown/Other"
};


declare function xlat:xlat-indicator($raw-value) as xs:boolean {
    if (fn:upper-case(fn:normalize-space($raw-value)) eq ("T", "TRUE", "Y", "YES", "X", "1"))
    then
        fn:true()
    else
        fn:false()
};

(:
Need the code values.
:)
declare function xlat:xlat-standard-encounter($status as xs:string) as xs:string {
    $status
};

(:
Need the code values.
:)
declare function xlat:xlat-marital-status($status as xs:string) as xs:string {
    $status
};