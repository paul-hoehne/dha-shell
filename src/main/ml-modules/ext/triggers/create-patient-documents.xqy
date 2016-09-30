xquery version "1.0-ml";

import module namespace trgr = 'http://marklogic.com/xdmp/triggers' at '/MarkLogic/triggers.xqy';
import module namespace xlat = 'http://dveivr.dha.health.mil/ext/lib/value-translators.xqy' at "/ext/lib/value-translators.xqy";
import module namespace decl = 'http://dveivr.dha.health.mil/ext/declarations' at '/ext/declarations.xqy';
import module namespace hous = 'http://dveivr.dha.health.mil/ext/lib/housekeeping.xqy' at '/ext/lib/housekeeping.xqy';

declare namespace env = "http://dveivr.dha.health.mil/xml/envelope";
declare namespace pat = "http://dveivr.dha.health.mil/xml/patient";
declare namespace enc = "http://dveivr.dha.health.mil/xml/encounter";
declare namespace trp="http://dveivr.dha.health.mil/ext/transforms/patient-triples.xqy";


declare variable $trgr:uri as xs:string external;
declare variable $default-permissions := (xdmp:permission("rest-reader", "read"),
    xdmp:permission("rest-writer", "update"));


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

declare function local:enriched-data($original) {
    (
        local:conditional-element("pat:patientId", $original/patient_id),
        local:conditional-element("pat:edipn", $original/edipn),
        local:conditional-element("pat:firstName", $original/first_name),
        local:conditional-element("pat:middleName", $original/middle_name),
        local:conditional-element("pat:lastName", $original/last_name),
        local:conditional-element("pat:suffix", $original/suffix),
        local:conditional-element("pat:birthDate", $original/birth_date),
        local:conditional-element("pat:deathDate", $original/death_date),
        local:conditional-element("pat:created", $original/created),
        local:conditional-element("pat:updated", $original/updated),
        local:conditional-element("pat:gender", xlat:xlat-gender($original/GENDER/text())),
        local:conditional-element("pat:ethnicity", $original/ETHNICITY),
        local:conditional-element("pat:race", $original/RACE),
        local:conditional-element("pat:birthDate", $original/oef_oif_ind),
        local:conditional-element("pat:deathDate", $original/lastserviceseparationdate)

    )
};

declare function local:create-new-record($uri, $enriched, $original) {
    let $patient-document := <env:envelope>
        <env:metadata>
            <env:import-date>{fn:current-dateTime()}</env:import-date>
            {(
                local:conditional-element("env:last-updated", $original/patient/updated),
                local:conditional-element("env:created", $original/patient/created)
            )}
        </env:metadata>
        <env:original>{$original}</env:original>
        <pat:patient>{$enriched}</pat:patient>
        <enc:encounters>
        </enc:encounters>
    </env:envelope>
    return
    (xdmp:document-insert($uri, $patient-document, $default-permissions,
            ("final", "type/patient", "patient", fn:string($patient-document//pat:patientId/text()))))
};

declare function local:update-existing-record($uri, $enriched, $original) {
    let $patient-document := fn:doc($uri)
    let $enriched-data := <pat:patient>{$enriched}</pat:patient>
    return
        (
            xdmp:node-replace($patient-document/env:envelope/pat:patient, $enriched-data),
            xdmp:node-replace($patient-document/env:envelope/env:original/element(), $original)
        )
};

(:
private Date updated;
private Date created;
:)

let $original := fn:doc($trgr:uri)/element()
let $filename := "/patients/" || $original/patient_id/text() || ".xml"
let $enriched := local:enriched-data($original)
return
    if (fn:exists(fn:doc($filename)))
    then
        local:update-existing-record($filename, $enriched, $original)
    else
        (local:create-new-record($filename, $enriched, $original),
            xdmp:spawn-function(function() {
                xdmp:invoke("/ext/transforms/patient-triples.xqy", (xs:QName("trp:document-uri"), $filename))
            }, <options xmlns="xdmp:eval"><transaction-mode>update-auto-commit</transaction-mode></options>))


