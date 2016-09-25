xquery version "1.0-ml";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace env="http://dveivr.dha.health.mil/xml/envelope";
declare namespace trp="http://dveivr.dha.health.mil/ext/transforms/patient-triples.xqy";

declare variable $named-graphs-enabled as xs:boolean := fn:true();
declare variable $my-iri-prefix as xs:anyURI := xs:anyURI("http://rdf.dveivr.dha.health.mil/patient/");
declare variable $trp:document-uri as xs:string external;

declare function local:set-collections($doc-uri as xs:string, $existing-collections as xs:string*, $named-graphs as xs:string*) as empty-sequence() {
    if ($named-graphs-enabled eq fn:true()) then
        let $non-graph-collections := functx:value-except($existing-collections, $named-graphs)
        let $final-collections := ($non-graph-collections, $named-graphs)
        return
            xdmp:document-set-collections($doc-uri, $final-collections)
    else
        ()
};

let $patient-doc := fn:doc($trp:document-uri)
let $_ := xdmp:log("Processing: " || $trp:document-uri)
let $xslt := "/ext/transforms/patient-rdfxml.xsl" (:this should be stored in the modules DB with its document node preserved:)
let $xslt-params := map:entry("iri-prefix", $my-iri-prefix)

let $transform := 
    try {
        xdmp:xslt-invoke($xslt, $patient-doc, $xslt-params)/rdf:RDF (: xslt-params is optional, a default of same value is supplied in the XSLT :)
    } catch($e) {
        xdmp:log($e, "error")
    }

return
    if ($transform instance of element(rdf:RDF)) then
        try {
            let $doc-uri := xdmp:node-uri($patient-doc)
            let $named-graphs := for $about in $transform/rdf:Description return fn:normalize-space($about/@rdf:about)
            let $existing-collections := xdmp:document-get-collections($doc-uri)
            let $triples := <sem:triples>{sem:rdf-parse($transform, ("rdfxml"))}</sem:triples>
            let $_ := xdmp:log("Generated triple count for document " || $doc-uri || " == " || fn:count($triples/sem:triple), "debug")
            return
                if (fn:exists($patient-doc/env:envelope/sem:triples)) then
                    (
                        xdmp:node-replace($patient-doc/env:envelope/sem:triples, $triples), 
                        local:set-collections($doc-uri, $existing-collections, $named-graphs)
                    )
                else
                    (
                        xdmp:node-insert-child($patient-doc/env:envelope, $triples),
                        local:set-collections($doc-uri, $existing-collections, $named-graphs)
                    )
        } catch($e) {
            xdmp:log("sem:triple parsing failed for document " || xdmp:node-uri($patient-doc), "warning")
        }
    else
        xdmp:log("sem:triple creation for document " || xdmp:node-uri($patient-doc) || " could not not proceed due to XSLT transformation exception", "warning")