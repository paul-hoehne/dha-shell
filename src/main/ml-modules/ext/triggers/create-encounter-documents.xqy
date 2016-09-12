xquery version "1.0-ml";

import module namespace trgr = 'http://marklogic.com/xdmp/triggers' at '/MarkLogic/triggers.xqy';
import module namespace decl = 'http://dveivr.dha.health.mil/ext/declarations' at '/ext/declarations.xqy';

declare namespace env = "http://dveivr.dha.health.mil/xml/envelope";
declare namespace enc = "http://dveivr.dha.health.mil/xml/encounter";

declare variable $trgr:uri as xs:string external;


declare function local:conditional-element($name as xs:string, $value) {
    if ($value and fn:not(fn:normalize-space(fn:string($value)) eq ""))
    then element { $name } {
            fn:normalize-space(fn:string($value))
        }
    else ()
};


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
    <enc:encounter> {(

    )}
    </enc:encounter>
    <enc:patient>
    </enc:patient>
</env:envelope>
let $filename := "/encounters/" || $original/encounter/encounterId/text() || ".xml"
return
    xdmp:document-insert($filename, $patient-document, (xdmp:permission("rest-reader", "read"), xdmp:permission("rest-writer", "update")),
        "encounter")