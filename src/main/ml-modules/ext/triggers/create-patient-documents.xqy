xquery version "1.0-ml";

import module namespace trgr = 'http://marklogic.com/xdmp/triggers' at '/MarkLogic/triggers.xqy';
import module namespace decl = 'http://dveivr.dha.health.mil/ext/declarations' at '/ext/declarations.xqy';

declare namespace env = "http://dveivr.dha.health.mil/xml/envelope";
declare namespace pat = "http://dveivr.dha.health.mil/xml/patient";

declare variable $trgr:uri as xs:string external;

declare function local:xlat-gender($gender-raw as xs:string) as xs:string {
    if ($gender-raw = ("F", "Female", "f", "female"))
    then
        "Female"
    else if($gender-raw = ("M", "Male", "m", "male"))
    then
        "Male"
    else
        "Unknown"
};

declare function local:xlat-service-branch($branch-raw as xs:string) as xs:string {
    if (fn:upper-case($branch-raw) = ("USMC", "MARINE", "MARINES"))
    then
        "Marine Corps"
    else if(fn:upper-case($branch-raw) = ("Army"))
    then
        "Army"
    else if(fn:upper-case($branch-raw) = ("AIR FORCE", "USAF"))
    then
        "Air Force"
    else if(fn:upper-case($branch-raw) = ("NAVY", "USN"))
    then
        "Navy"
    else if(fn:upper-case($branch-raw) = ("COAST GUARD", "USCG"))
    then
        "Coast Guard"
    else
        "Unknwon"
};

declare function local:xlat-service-status($status as xs:string) as xs:string {
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

declare function local:conditional-element($name as xs:string, $value) {
    if ($value and fn:not(fn:normalize-space(fn:string($value)) eq ""))
    then element { $name } {
        fn:normalize-space(fn:string($value))
    }
    else ()
};

(:
private Date updated;
private Date created;
:)

let $original := fn:doc($trgr:uri)
let $patient-document := <env:envelope>
    <env:metadata>
        <env:import-date>{fn:current-dateTime()}</env:import-date>
        {(
            local:conditional-element("env:last-updated", $original/patient/updated),
            local:conditional-element("env:created", $original/patient/created)
        )}
    </env:metadata>
    <env:original>{fn:doc($trgr:uri)}</env:original>
    <pat:patient> {(
        local:conditional-element("pat:patientId", $original/patient/patientId),
        local:conditional-element("pat:edipn", $original/patient/edipn),
        local:conditional-element("pat:firstName", $original/patient/firstName),
        local:conditional-element("pat:middleName", $original/patient/middleName),
        local:conditional-element("pat:lastName", $original/patient/lastName),
        local:conditional-element("pat:suffix", $original/patient/suffix),

        local:conditional-element("pat:gender", local:xlat-gender($original/patient/gender/text())),
        local:conditional-element("pat:ethnicity", $original/patient/ethnicity),
        local:conditional-element("pat:race", $original/patient/race),
        local:conditional-element("pat:birthDate", $original/patient/birthDate),
        local:conditional-element("pat:deathDate", $original/patient/deathDate),

        local:conditional-element("pat:serviceBranch", local:xlat-service-branch($original/patient/serviceBranch/text())),
        local:conditional-element("pat:unit", $original/patient/unit),
        local:conditional-element("pat:serviceStatus", local:xlat-service-status($original/patient/serviceStatus)),
        local:conditional-element("pat:militaryStatus", local:xlat-service-status($original/patient/militaryStatus)),
        local:conditional-element("pat:lastServiceSeparationDate", $original/patient/lastServiceSeparationDate),
        local:conditional-element("pat:category", $original/patient/category),

        local:conditional-element("pat:oefOifInd", $original/patient/oefOifInd),
        local:conditional-element("pat:maritalStatus", $original/patient/maritalStatus),
        local:conditional-element("pat:livingArrangements", $original/patient/livingArrangements),
        local:conditional-element("pat:zipPlusFour", $original/patient/zipPlusFour),
        local:conditional-element("pat:enrollmentDate", $original/patient/enrollmentDate),
        local:conditional-element("pat:occupation", $original/patient/occupation),
        local:conditional-element("pat:jobDescription", $original/patient/jobDescription)
    )}
    </pat:patient>
    <pat:encouners>
    </pat:encouners>
</env:envelope>
let $filename := "/patients/" || $original/patient/patientId/text() || ".xml"
return
    xdmp:document-insert($filename, $patient-document, (xdmp:permission("rest-reader", "read"), xdmp:permission("rest-writer", "update")),
        "patient")