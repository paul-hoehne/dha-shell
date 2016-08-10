xquery version "1.0-ml";

module namespace t = "http://marklogic.com/dha/example/transform-encounter";


declare namespace  enc="http://model.dveivr.dha.health.mil/DVEIVR_ENCOUNTER";
declare namespace meta="http://model.dveivr.dha.health.mil/DVEIVR_META";
declare namespace  env="http://model.dveivr.dha.health.mil/DVEIVR";
declare namespace  pat="http://model.dveivr.dha.health.mil/DVEIVR_PATIENT";


declare variable $prefix := "http://marklogic.com/example/ontology#";
declare variable $rdf-prefix := "http://www.w3.org/1999/02/22-rdf-syntax-ns#";

(:    Some example triple predicates  :)
declare variable $pred-encounter-id     := sem:iri($prefix     || "encounter-id");
declare variable $pred-provider-id      := sem:iri($prefix     || "provider-id");
declare variable $pred-rdf-type         := sem:iri($rdf-prefix || "type");
declare variable $encounter-type        := sem:iri($prefix     || "encounter");

declare variable $options := ("case-insensitive");


declare function t:transform($content as map:map, $context as map:map) as map:map* {
    let $original := map:get($content, "value")
    let $uri := sem:iri(map:get($content, "uri"))
    let $encounter-id := $original//encounter-id/text()
    let $contents := element enc:encounter {
        element enc:id { $encounter-id },
        element enc:original-data {
            for $element in $original/root/element()
            where fn:string($element) ne "NULL" and fn:string($element) ne ""
            return $element
        }
    }
    let $patient-id := $original//patient_id/text()
    let $_ := xdmp:spawn-function(function() {
        xdmp:node-insert-child(fn:doc("/patients/" || $patient-id || ".xml")//env:data/pat:patient/pat:encounters,
                $contents)
    }, <options xmlns="xdmp:eval"><transaction-mode>update-auto-commit</transaction-mode></options>)
    let $new-doc := element env:location {
        element meta:meta {
            element meta:date-ingested { fn:current-dateTime() }
        },
        element env:data {
            $contents
        },
        element env:triples {
            sem:triple($uri, $pred-encounter-id, xs:int($encounter-id)),
            sem:triple($uri, $pred-rdf-type,            $encounter-type)
        }
    }
    let $_ := map:put($content, "value", $new-doc)
    return
        $content
};
