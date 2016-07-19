xquery version '1.0-ml';

import module namespace trgr = 'http://marklogic.com/xdmp/triggers' at '/MarkLogic/triggers.xqy';

declare namespace med="http://marklogic.com/dha/example";
declare namespace diag="http://marklogic.com/dha/fake-icd";

declare namespace meta="http://marklogic.com/dha/metadata";
declare namespace env="http://marklogic.com/dha/envelope";
declare namespace cts="http://marklogic.com/cts";

declare variable $pred-visiting-patient := sem:iri("http://marklogic.com/dha/schema#visiting-patient-id");
declare variable $pred-has-idc-code := sem:iri("http://marklogic.com/dha/schema#idc-code");
declare variable $pred-fiscal-year := sem:iri("http://marklogic.com/dha/schema#fiscal-year");


declare variable $trgr:uri as xs:string external;


let $visit-document := fn:doc($trgr:uri)
let $person := cts:search(fn:collection("patients"), cts:element-value-query(xs:QName("med:id"),
        $visit-document/med:visit/med:patient-id/text()))
let $visit-date := xs:dateTime($visit-document/med:visit/med:visit-timestamp)
let $fiscal-year := if (fn:month-from-dateTime($visit-date) gt 9)
    then fn:year-from-dateTime($visit-date) + 1
    else fn:year-from-dateTime($visit-date)

let $idc-code := $visit-document/med:visit/diag:diag/diag:code
let $new-doc := <env:visit>
    <meta:meta>
        <meta:date-ingested>{current-dateTime()}</meta:date-ingested>
    </meta:meta>
    <env:data>
        { $visit-document/node() }
    </env:data>
    <env:triples>
        {
            (sem:triple(sem:iri($trgr:uri), $pred-visiting-patient, fn:document-uri($person)),
             sem:triple(sem:iri($trgr:uri), $pred-has-idc-code,     $idc-code),
             sem:triple(sem:iri($trgr:uri), $pred-fiscal-year,      $fiscal-year))

        }
    </env:triples>
</env:visit>

return
    (
        xdmp:document-insert($trgr:uri, $new-doc, xdmp:document-get-permissions($trgr:uri),
                xdmp:document-get-collections($trgr:uri))
    )
