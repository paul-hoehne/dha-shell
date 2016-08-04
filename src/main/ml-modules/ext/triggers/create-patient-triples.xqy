xquery version '1.0-ml';

import module namespace trgr = 'http://marklogic.com/xdmp/triggers' at '/MarkLogic/triggers.xqy';

declare namespace med="http://marklogic.com/dha/example";
declare namespace meta="http://marklogic.com/dha/metadata";
declare namespace env="http://marklogic.com/dha/envelope";

declare variable $trgr:uri as xs:string external;

declare variable $prefix := "http://marklogic.com/example/ontology#";
declare variable $rdf-prefix := "http://www.w3.org/1999/02/22-rdf-syntax-ns#";

(:    Some example triple predicates  :)
declare variable $pred-patient-id     := sem:iri($prefix || "patient-id");
declare variable $pred-first-name     := sem:iri($prefix || "first-name");
declare variable $pred-last-name      := sem:iri($prefix || "last-name");
declare variable $pred-middle-name    := sem:iri($prefix || "middle-name");
declare variable $pred-full-name      := sem:iri($prefix || "full-name");

declare variable $pred-rdf-type       := sem:iri($rdf-prefix || "type");
declare variable $patient-type        := sem:iri($prefix || "patient");

(:
    Grab the document
:)
let $user-document := fn:doc($trgr:uri)

(: Extract the patient data :)
let $patient-id := $user-document/root/PATIENT_ID/text()
let $patient-icn := $user-document/root/PAGIETN_ICN/text()
let $first-name := $user-document/root/FIRST_NAME/text()
let $last-name := $user-document/root/LAST_NAME/text()
let $middle-name := $user-document/root/MIDDLE_NAME/text()
let $full-name := fn:normalize-space($first-name || " " || $middle-name || " " || $last-name)

(: This is really common, fixing a date so it's in ISO standard format :)
let $created-date := fn:replace($user-document/root/CREATED/text(), " ", "T")
let $updated-date := fn:replace($user-document/root/UPDATED/text(), " ", "T")

let $source-file := $user-document/root/SOURCE_FILE/text()
let $source-date := fn:replace($user-document/root/SOURCE_DATE/text(), " ", "T")

(:    Wrap this in an envelope    :)
let $new-doc := element env:patient {
    element meta:meta {
        element meta:date-ingested { current-dateTime() },
        element meta:created-date { $created-date },
        element meta:updated-date { $updated-date },
        element meta:source-file { $source-file },
        element meta:source-date { $source-date }
    },
    element env:data {
        element med:patient {
            element med:id { $patient-id },
            element med:icn { $patient-icn },
            element med:name {
                element med:first-name { $first-name },
                element med:last-name { $last-name },
                (: example of including an element conditionally :)
                if ($middle-name) then element med:middle-name { $middle-name } else (),
                element med:full-name { $full-name }
            },
            (: This is just a copy of the original data - might be removed in the future. :)
            element med:original-data {
                $user-document/root/element()
            }
        }
    },
    element env:triples {
        sem:triple(sem:iri($trgr:uri), $pred-patient-id, xs:int($patient-id)),
        sem:triple(sem:iri($trgr:uri), $pred-first-name, xs:string($first-name)),
        if ($middle-name) then sem:triple(sem:iri($trgr:uri), $pred-middle-name, xs:string($middle-name)) else (),
        sem:triple(sem:iri($trgr:uri), $pred-last-name, xs:string($last-name)),
        sem:triple(sem:iri($trgr:uri), $pred-full-name, xs:string($full-name)),
        sem:triple(sem:iri($trgr:uri), $pred-rdf-type, $patient-type)
    }
}
return
    (
        xdmp:document-insert($trgr:uri, $new-doc, xdmp:document-get-permissions($trgr:uri),
            xdmp:document-get-collections($trgr:uri))
    )
