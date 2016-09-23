xquery version "1.0-ml";

import module namespace trgr = 'http://marklogic.com/xdmp/triggers' at '/MarkLogic/triggers.xqy';
import module namespace xlat = 'http://dveivr.dha.health.mil/ext/lib/value-translators.xqy' at "/ext/lib/value-translators.xqy";
import module namespace decl = 'http://dveivr.dha.health.mil/ext/declarations' at '/ext/declarations.xqy';
import module namespace hous = 'http://dveivr.dha.health.mil/ext/lib/housekeeping.xqy' at '/ext/lib/housekeeping.xqy';

declare namespace env = "http://dveivr.dha.health.mil/xml/envelope";
declare namespace pat = "http://dveivr.dha.health.mil/xml/patient";
declare namespace enc = "http://dveivr.dha.health.mil/xml/encounter";

declare variable $trgr:uri as xs:string external;

declare function local:conditional-element($name as xs:string, $value) {
    if ($value and fn:not(fn:normalize-space(fn:string($value)) eq ""))
    then element { $name } {
        fn:normalize-space(fn:string($value))
    }
    else ()
};

declare function local:patient-category-text($category as xs:string) {
    let $patient-category := cts:search(fn:collection('patient-categories'), cts:element-value-query(xs:QName("Code"), $category))[1]
    return
        if (fn:exists($patient-category))
        then
            (<pat:categoryName>{$patient-category/root/Name/text()}</pat:categoryName>,
            <pat:categoryShortName>{$patient-category/root/Short_Descr/text()}</pat:categoryShortName>)
        else ()

};

let $original := fn:doc($trgr:uri)
let $uri := "/patients/" || $original/patient/patientId/text() || ".xml"
let $patient-base := <pat:patient> {(
    local:conditional-element("pat:patientId", $original/patient/patientId),
    local:conditional-element("pat:edipn", $original/patient/edipn),
    local:conditional-element("pat:firstName", $original/patient/firstName),
    local:conditional-element("pat:middleName", $original/patient/middleName),
    local:conditional-element("pat:lastName", $original/patient/lastName),
    local:conditional-element("pat:suffix", $original/patient/suffix),

    local:conditional-element("pat:gender", xlat:xlat-gender($original/patient/gender/text())),
    local:conditional-element("pat:ethnicity", $original/patient/ethnicity),
    local:conditional-element("pat:race", $original/patient/race),
    local:conditional-element("pat:birthDate", $original/patient/birthDate),
    local:conditional-element("pat:deathDate", $original/patient/deathDate),

    local:conditional-element("pat:serviceBranch", xlat:xlat-service-branch($original/patient/serviceBranch/text())),
    local:conditional-element("pat:unit", $original/patient/unit),
    local:conditional-element("pat:serviceStatus", xlat:xlat-service-status($original/patient/serviceStatus)),
    local:conditional-element("pat:militaryStatus", xlat:xlat-service-status($original/patient/militaryStatus)),
    local:conditional-element("pat:lastServiceSeparationDate", $original/patient/lastServiceSeparationDate),
    local:conditional-element("pat:category", $original/patient/category),
    local:patient-category-text(fn:string($original/patient/category)),

    local:conditional-element("pat:oefOifInd", $original/patient/oefOifInd),
    local:conditional-element("pat:maritalStatus", $original/patient/maritalStatus),
    local:conditional-element("pat:livingArrangements", $original/patient/livingArrangements),
    local:conditional-element("pat:zipPlusFour", $original/patient/zipPlusFour),
    local:conditional-element("pat:enrollmentDate", $original/patient/enrollmentDate),
    local:conditional-element("pat:occupation", $original/patient/occupation),
    local:conditional-element("pat:jobDescription", $original/patient/jobDescription)
)}
</pat:patient>
return
    (
        xdmp:log("updating: " || $uri),
        xdmp:node-replace(fn:doc($uri)//pat:patient, $patient-base),
        xdmp:node-replace(fn:doc($uri)//env:original, <env:original>{fn:doc($trgr:uri)/element()}</env:original>),
        xdmp:node-replace(fn:doc($uri)//env:last-updated/text(), $original/patient/updated/text()),
        for $encounter in cts:search(fn:collection("encounter"), cts:element-value-query(xs:QName("enc:patientId"), $original/patient/patientId/text()))
        return
            xdmp:node-replace($encounter//pat:patient, $patient-base)
    )
