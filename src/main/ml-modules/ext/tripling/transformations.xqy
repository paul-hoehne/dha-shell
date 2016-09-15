xquery version "1.0-ml";

module namespace xf = 'http://dveivr.dha.health.mil/ext/tripling/transformations.xqy';

declare variable $namespaces := map:new((map:entry("env", "http://dveivr.dha.health.mil/xml/envelope")));

declare function xf:passthrough($value) {
    $value
};

declare function xf:simple-mapping($value, $map) {
    map:get($map, $value)
};

declare function xf:invoke-transform($xpath, $document, $function-namespace, $function-name, $arguments) {
    let $eval-string := "xquery version '1.0-ml'; " ||
        "declare namespace ns = '" || $function-namespace ||"'; " ||
        "declare namespace xf = 'http://dveivr.dha.health.mil/ext/tripling/transformations.xqy'; " ||
        "declare variable $xf:document as external element(); " ||
        "declare variable $xf:xpath as external xs:string; " ||
        "xdmp:apply(xdmp:function(xs:QName('ns:" || $function-name || "', $xpath, $document)"
    return
        xdmp:eval($eval-string, (xs:QName("xf:document"), $document, xs:QName("xf:xpath"), $xpath))
};

(:
    For simple value maps, this builds a map of the input values and their translated value.  For example,
    if the value mapping is something like:

    Input            Output
    Female           Female
    F                Female
    2                Female
    1                Male
    M                Male
    Male             Male

    this builds a map with (Female => Female, F => Female, etc.)
:)
declare function xf:build-simple-value-map($transformation-iri) {
    let $query := 'prefix def:   <http://dveivr.dha.health.mil/transformations/2016/8/definitions#>
        prefix inst:  <http://dveivr.dha.health.mil/transformations/2016/8/instances#>
        prefix rdfs:  <http://www.w3.org/2000/01/rdf-schema/>
            prefix rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

        select ?transform ?input ?output ?subjUri
        where {
            ?transformIri def:transformations ?transform.
            ?transform def:inputValue ?input.
            ?transform rdf:type def:SimpleValueMapping.
            optional { ?transform def:outputType ?outputType }.
            optional { ?transform def:outputValue ?output }.
            optional { ?transform def:subjectUri ?subjUri }.
        }'
    let $result := map:new()
    let $_ := for $row in sem:sparql($query, map:new(map:entry("transformIri", $transformation-iri)))
        return (
            map:put($result, map:get($row, "input"), (map:get($row, "output"), map:get($row, "subjUri"))[1]),
            map:put($result, "outputType", (map:get($row, "outputType"), "string")[1]))
    return
        $result
};

(:
    For transformations that supply a default value (for example if there is no mapping or no value is provided,
    then this provides those defaults.

    An unmapped value is used where there is an input value but there is no mapping for that value.  For example,
    there are mappings for the numbers 1, 2, 3 but the supplied value is 99.

    A no input value is a value that is used when the input is blank.  For example, there is a mapping from
    1, 2, and 3 but there is no input value supplied.
:)
declare function xf:default-value-map($transformation-iri) {
    let $query := 'prefix def:   <http://dveivr.dha.health.mil/transformations/2016/8/definitions#>
        prefix inst:  <http://dveivr.dha.health.mil/transformations/2016/8/instances#>
        prefix rdfs:  <http://www.w3.org/2000/01/rdf-schema/>
        prefix rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

        select ?transform ?output ?noInput
        where {
            ?transformIri def:transformations ?transform.
            optional { ?transform def:unmappedValue ?output }.
            optional { ?transform def:noInputValue ?noInput }.
        }'
    let $result := map:new()
    let $_ := for $row in sem:sparql($query, map:new(map:entry("transformIri", $transformation-iri)))
    return (
        if (map:get($row, "output")) then map:put($result, "unmapped", map:get($row, "output")) else (),
        if (map:get($row, "noInput")) then map:put($result, "noInput", map:get($row, "noInput")) else ()
    )
    return
        $result
};

(:
    This builds a map that describes a function to invoke.  That function will take the xpath, document,
    and this map to execute a transformation.
:)
declare function xf:build-invocation-map($transformation-iri) {
    let $query := 'prefix def:   <http://dveivr.dha.health.mil/transformations/2016/8/definitions#>
        prefix inst:  <http://dveivr.dha.health.mil/transformations/2016/8/instances#>
        prefix rdfs:  <http://www.w3.org/2000/01/rdf-schema/>
        prefix rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

        select ?transform ?function ?namespace ?url
        where {
            ?transformIri def:transformations ?transform.
            ?transform rdf:type def:InvokeTransformMapping.
            optional { ?transform def:transformModuleFunction ?function }.
            optional { ?transform def:transformModuleNamespace ?namespace }.
            optional { ?transform def:transformModuleUri ?url }.
        }'
    let $row := sem:sparql($query, map:new(map:entry("transformIri", $transformation-iri)))
    return
        map:new((
            if (map:get($row, "function")) then map:entry("functionName", map:get($row, "function")) else (),
            if (map:get($row, "namespace")) then map:entry("namespace", map:get($row, "namespace")) else (),
            if (map:get($row, "url")) then map:entry("url", map:get($row, "url")) else ()))
};

(:
    This builds a map that describes a function to invoke.  That function will take the xpath, document,
    and this map to execute a transformation.
:)
declare function xf:build-passthrough-map($transformation-iri) {
    let $query := 'prefix def:   <http://dveivr.dha.health.mil/transformations/2016/8/definitions#>
        prefix inst:  <http://dveivr.dha.health.mil/transformations/2016/8/instances#>
        prefix rdfs:  <http://www.w3.org/2000/01/rdf-schema/>
        prefix rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

        select ?transform ?outputType
        where {
            ?transformIri def:transformations ?transform.
            ?transform rdf:type def:PassthroughValueMapping.
            optional { ?transform def:outputType ?outputType }.
        }'
    let $row := sem:sparql($query, map:new(map:entry("transformIri", $transformation-iri)))
    return
        if (map:keys($row))
        then map:new((
            map:entry("passthrough", "passthrough"),
            map:entry("outputType", (map:get($row, "outputType"), "string")[1])
        ))
        else map:new()
};

(:
    Lists all the transformations for a given data set.
:)
declare function xf:list-dataset-transforms($collection-uri) {
    let $query := 'prefix def:   <http://dveivr.dha.health.mil/transformations/2016/8/definitions#>
        prefix inst:  <http://dveivr.dha.health.mil/transformations/2016/8/instances#>
        prefix rdfs:  <http://www.w3.org/2000/01/rdf-schema/>
        prefix rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

        select ?transform ?predicate ?xpath ?caseIndependent
        where {
            ?dataset def:collectionUri ?collectionUri.
            ?transform def:associatedDataset ?dataset.
            ?transform def:predicate ?predicate.
            ?transform def:xpath ?xpath.
            optional { ?transform def:caseIndependent ?caseIndependent }
        }'
    let $result := for $row in sem:sparql($query, map:new(map:entry("collectionUri", $collection-uri)))
    return map:new((map:entry('transform-uri', map:get($row, 'transform')),
    map:entry('predicate', map:get($row, 'predicate')),
    map:entry('xpath', map:get($row, 'xpath')),
    map:entry('case', if (map:get($row, 'caseIndependent')) then fn:true() else fn:false())))
    return
        $result
};

(:
    This function creates a list of mappings
:)
declare function xf:list-dataset-mappings($transform-iri) {
    let $query := 'prefix def:   <http://dveivr.dha.health.mil/transformations/2016/8/definitions#>
        prefix inst:  <http://dveivr.dha.health.mil/transformations/2016/8/instances#>
        prefix rdfs:  <http://www.w3.org/2000/01/rdf-schema/>
        prefix rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

        select ?mapping ?type
        where {
            ?transformIri def:transformations ?mapping.
            ?mapping rdf:type ?type.
        }'
    let $result := sem:sparql($query, map:new(map:entry("transformIri", $transform-iri)))
    return
        $result
};

declare function xf:build-function-parameters-map($transformation-iri) {
    let $query := 'prefix def:   <http://dveivr.dha.health.mil/transformations/2016/8/definitions#>
        prefix inst:  <http://dveivr.dha.health.mil/transformations/2016/8/instances#>
        prefix rdfs:  <http://www.w3.org/2000/01/rdf-schema/>
        prefix rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

        select ?transform ?parameter ?name ?value
        where {
            ?transformIri def:transformations ?transform.
            ?transform rdf:type def:InvokeTransformMapping.
            optional { ?transform def:parameters ?parameter }.
            optional { ?parameter def:parameterName ?name }.
            optional { ?parameter def:parameterValue ?value }.
        }'
    let $rows := sem:sparql($query, map:new(map:entry("transformIri", $transformation-iri)))
    let $result := map:new()
    let $_ := for $row in $rows return map:put($result, map:get($row, "name"), map:get($row, "value"))
    return
        $result
};

declare function xf:cast-value($value, $type) {
    if ($type eq "string")
        then fn:string($value)
    else if ($type eq "date")
        then xs:date($value)
    else if ($type eq "dateTime")
        then xs:dateTime($value)
    else if ($type eq "time")
        then xs:time($value)
    else if ($type eq ("int", "integer", "natural", "positive"))
        then xs:integer($value)
    else if ($type eq ("real", "double", "float", "decimal"))
        then xs:double($value)
    else if ($type eq ("uri", "iri"))
        then sem:iri($value)
    else fn:string($value)
};

declare function xf:execute-passthrough-transformation($xpath, $predicate, $doc, $passthrough, $defaults) {
    let $val := xdmp:unpath("$doc"||$xpath, $namespaces)
    let $type := map:get($passthrough, "outputType")
    let $base-uri := sem:iri(fn:base-uri($doc))
    let $graph-uri := sem:iri(fn:tokenize(fn:base-uri($doc), "\.")[1])
    return
        if ($val and fn:normalize-space($val) ne "")
        then sem:triple($base-uri, sem:iri($predicate), xf:cast-value($val, $type), $graph-uri)
        else if (map:get($defaults, "noInput"))
        then sem:triple($base-uri, sem:iri($predicate), xf:cast-value(map:get($defaults, "noInput"), $type), $graph-uri)
        else ()
};

declare function xf:execute-simple-transformation($xpath, $predicate, $doc, $value-map, $defaults) {
    let $val := xdmp:unpath("$doc"||$xpath, $namespaces)
    let $type := map:get($value-map, "outputType")
    let $base-uri := sem:iri(fn:base-uri($doc))
    let $graph-uri := sem:iri(fn:tokenize(fn:base-uri($doc), "\.")[1])
    let $output-raw := if ($val) then (map:get($value-map, $val), map:get($defaults, "unmapped"))[1]
    else map:get($defaults, "noInput")
    return
        if ($output-raw)
        then sem:triple($base-uri, sem:iri($predicate), xf:cast-value($output-raw, $type), $graph-uri)
        else ()
};

declare function xf:execute-function-transformation($xpath, $predicate, $doc, $function-map, $defaults, $parameters) {
    let $function-name := map:get($function-map, "functionName")
    let $function-namespace := map:get($function-map, "namespace")
    let $function-uri := map:get($function-map, "url")
    let $base-uri := sem:iri(fn:base-uri($doc))
    let $graph-uri := sem:iri(fn:tokenize(fn:base-uri($doc), "\.")[1])
    let $_ := if (fn:not($function-name) or fn:not($function-namespace) or fn:not($function-uri))
    then fn:error("ERROR", "Function transformation defintions require a namespace, name, and url: " || fn:string($predicate))
    else ()
    let $function := xdmp:function(fn:QName($function-namespace, $function-name), $function-uri)
    let $raw := xdmp:apply($function, $xpath, $doc, $defaults, $parameters)
    let $_ := if (fn:not($raw)) then fn:error("Error", "Function transformation did not return a value") else ()
    return
        sem:triple($base-uri, sem:iri($predicate), $raw, $graph-uri)
};

declare function xf:execute-transforms($collection-uri, $document) {
    for $transform in xf:list-dataset-transforms("patient")
    let $transform-uri := map:get($transform, "transform-uri")
    let $xpath := map:get($transform, "xpath")
    let $predicate := map:get($transform, "predicate")

    let $function-transform := xf:build-invocation-map($transform-uri)
    let $simple-transform := xf:build-simple-value-map($transform-uri)
    let $passthrough-transform := xf:build-passthrough-map($transform-uri)
    let $default-maps := xf:default-value-map($transform-uri)
    let $parameters := xf:build-function-parameters-map($transform-uri)

    return
        if (map:keys($function-transform))
        then xf:execute-function-transformation($xpath, $predicate, $document, $function-transform, $default-maps, $parameters)
        else if (map:keys($simple-transform))
        then xf:execute-simple-transformation($xpath, $predicate, $document, $simple-transform, $default-maps)
        else if (map:keys($passthrough-transform))
            then xf:execute-passthrough-transformation($xpath, $predicate, $document, $passthrough-transform, $default-maps)
            else fn:error(xs:QName("Error"), "Invalid transformation mapping for " || fn:string($transform-uri))
};