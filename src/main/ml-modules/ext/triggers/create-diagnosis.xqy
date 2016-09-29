xquery version "1.0-ml";

import module namespace trgr = 'http://marklogic.com/xdmp/triggers' at '/MarkLogic/triggers.xqy';
import module namespace xlat = 'http://dveivr.dha.health.mil/ext/lib/value-translators.xqy' at "/ext/lib/value-translators.xqy";
import module namespace decl = 'http://dveivr.dha.health.mil/ext/declarations' at '/ext/declarations.xqy';
import module namespace hous = 'http://dveivr.dha.health.mil/ext/lib/housekeeping.xqy' at '/ext/lib/housekeeping.xqy';

declare namespace env = "http://dveivr.dha.health.mil/xml/envelope";
declare namespace enc = "http://dveivr.dha.health.mil/xml/encounter";
declare namespace pat = "http://dveivr.dha.health.mil/xml/patient";

declare variable $trgr:uri as xs:string external;


declare function local:conditional-element($name as xs:string, $value) {
    if ($value and fn:not(fn:normalize-space(fn:string($value)) eq ""))
    then element { $name } {
        fn:normalize-space(fn:string($value))
    }
    else ()
};

let $original := fn:doc($trgr:uri)/element()
let $encounter := cts:search(fn:collection("type/encounter"),
        cts:element-value-query(xs:QName("enc:encounterId"), fn:string($original/encounter_id)))[1]
let $temp-uri := fn:base-uri($original)

let $diagnosis := <enc:diagnosis>{
    (
        local:conditional-element("enc:laterality", $original/LATERALITY),
        local:conditional-element("enc:code", $original/CODE),
        local:conditional-element("enc:name", $original/NAME),
        local:conditional-element("enc:commentText", $original/COMMENT_TEXT)
    )
}</enc:diagnosis>
return (
    xdmp:node-insert-child($encounter/env:envelope/enc:diagnoses, $diagnosis),
    xdmp:spawn-function(function() {
        xdmp:document-delete($temp-uri)
    }, <options xmlns="xdmp:eval">
        <transaction-mode>update-auto-commit</transaction-mode>
    </options>)
)



