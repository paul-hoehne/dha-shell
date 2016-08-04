xquery version '1.0-ml';

import module namespace trgr = 'http://marklogic.com/xdmp/triggers' at '/MarkLogic/triggers.xqy';

declare namespace med="http://marklogic.com/dha/example";
declare namespace meta="http://marklogic.com/dha/metadata";
declare namespace env="http://marklogic.com/dha/envelope";

declare variable $trgr:uri as xs:string external;

declare variable $prefix := "http://marklogic.com/example/ontology#";
declare variable $rdf-prefix := "http://www.w3.org/1999/02/22-rdf-syntax-ns#";

(:    Some example triple predicates  :)
declare variable $pred-location-id     := sem:iri($prefix     || "location-id");
declare variable $pred-rdf-type        := sem:iri($rdf-prefix || "type");
declare variable $location-type        := sem:iri($prefix     || "location");

(:
    Grab the document
:)
let $location-document := fn:doc($trgr:uri)

(: Extract the patient data :)
let $location-id := $location-document/root/ID/text()

(: This is really common, fixing a date so it's in ISO standard format :)
let $created-date := fn:replace($location-document/root/CREATED/text(), " ", "T")
let $updated-date := fn:replace($location-document/root/UPDATED/text(), " ", "T")

(:    Wrap this in an envelope    :)
let $new-doc := element env:location {
    element meta:meta {
        element meta:date-ingested { current-dateTime() },
        element meta:created-date { $created-date },
        element meta:updated-date { $updated-date }
    },
    element env:data {
        element med:location {
            element med:id { $location-id },
            (: This is just a copy of the original data - might be removed in the future. :)
            element med:original-data {
                $location-document/root/element()
            }
        }
    },
    element env:triples {
        sem:triple(sem:iri($trgr:uri), $pred-location-id, xs:int($location-id)),
        sem:triple(sem:iri($trgr:uri), $pred-rdf-type,    $location-type)
    }
}
return
    (
        xdmp:document-insert($trgr:uri, $new-doc, xdmp:document-get-permissions($trgr:uri),
                xdmp:document-get-collections($trgr:uri))
    )
