xquery version "1.0-ml";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace env="http://dveivr.dha.health.mil/xml/envelope";

let $patient-id := "117306"

(:These 2 lines are only needed if parsing and querying from memory :)
(:let $triples := sem:rdf-parse($rdf, "rdfxml"):)
(:let $store := sem:in-memory-store($triples):) 

let $store := sem:store((), cts:collection-query("http://rdf.dveivr.dha.health.mil/patient/" || $patient-id))
let $bind := map:entry("patient", $patient-id)

let $sparql := '
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX dcterms: <http://purl.org/dc/terms/>
PREFIX provider: <http://rdf.dveivr.dha.health.mil/provider/>
PREFIX core: <http://model.dveivr.dha.health.mil/DVEIVR_core#>
PREFIX referral: <http://rdf.dveivr.dha.health.mil/referral/>
PREFIX encounter: <http://rdf.dveivr.dha.health.mil/encounter/>
PREFIX patient: <http://rdf.dveivr.dha.health.mil/patient/>
PREFIX gender: <http://rdf.dveivr.dha.health.mil/gender/>
PREFIX ethnicity: <http://rdf.dveivr.dha.health.mil/ethnicity/>
PREFIX branch: <http://rdf.dveivr.dha.health.mil/branch/>

SELECT DISTINCT ?ps ?pp ?po ?es ?ep ?eo WHERE {
  {?ps rdf:type core:Patient ; core:personIdentifier $patient ; ?pp ?po . }
  UNION
  {?es rdf:type core:Encounter ; core:patientInEncounter ?ps ; ?ep ?eo . }
}'

let $results := sem:sparql($sparql, $bind, (), $store)
return sem:query-results-serialize($results, "json")