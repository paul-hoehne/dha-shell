xquery version "1.0-ml";

module namespace t = "http://marklogic.com/dha/example/transform-encounter";

declare namespace med="http://marklogic.com/dha/example";
declare namespace meta="http://marklogic.com/dha/metadata";
declare namespace env="http://marklogic.com/dha/envelope";


declare variable $prefix := "http://marklogic.com/example/ontology#";
declare variable $rdf-prefix := "http://www.w3.org/1999/02/22-rdf-syntax-ns#";

(:    Some example triple predicates  :)
declare variable $pred-encounter-id     := sem:iri($prefix     || "encounter-id");
declare variable $pred-provider-id      := sem:iri($prefix     || "provider-id");
declare variable $pred-rdf-type         := sem:iri($rdf-prefix || "type");
declare variable $encounter-type        := sem:iri($prefix     || "encounter");

declare variable $options := ("case-insensitive");

declare variable $injury-reverse-queries := (
    <reverse-query>
        <final-term>{$prefix || "laceration"}</final-term>
        <query>{cts:or-query((cts:word-query("laceration", $options), cts:word-query("cut", $options)))}</query>
    </reverse-query>,
    <reverse-query>
        <final-term>{$prefix || "burn"}</final-term>
        <query>{cts:or-query((cts:word-query("burn", $options), cts:word-query("charred", $options), cts:word-query("scald", $options)))}</query>
    </reverse-query>,
    <reverse-query>
        <final-term>{$prefix || "fracture"}</final-term>
        <query>{cts:or-query((cts:word-query("fracture", $options), cts:word-query("fx", $options), cts:word-query("frac", $options)))}</query>
    </reverse-query>
);

declare variable $proximity-reverse-queries := (
    <reverse-query>
        <final-term>{$prefix || "ankle"}</final-term>
        <query>{cts:or-query((cts:word-query("ankle", $options)))}</query>
    </reverse-query>,
    <reverse-query>
        <final-term>{$prefix || "femur"}</final-term>
        <query>{cts:or-query((cts:word-query("femur", $options)))}</query>
    </reverse-query>,
    <reverse-query>
        <final-term>{$prefix || "foot"}</final-term>
        <query>{cts:or-query((cts:word-query("foot", $options), cts:word-query("heal", $options), cts:word-query("pedal", $options)))}</query>
    </reverse-query>,
    <reverse-query>
        <final-term>{$prefix || "knee"}</final-term>
        <query>{cts:or-query((cts:word-query("knee", $options)))}</query>
    </reverse-query>,
    <reverse-query>
        <final-term>{$prefix || "thibia"}</final-term>
        <query>{cts:or-query((cts:word-query("thibia", $options)))}</query>
    </reverse-query>,
    <reverse-query>
        <final-term>{$prefix || "toes"}</final-term>
        <query>{cts:or-query((cts:word-query("toes", $options)))}</query>
    </reverse-query>,
    <reverse-query>
        <final-term>{$prefix || "legs"}</final-term>
        <query>{cts:or-query((cts:word-query("leg", $options)))}</query>
    </reverse-query>,
    <reverse-query>
        <final-term>{$prefix || "elbow"}</final-term>
        <query>{cts:or-query((cts:word-query("leg", $options)))}</query>
    </reverse-query>,
    <reverse-query>
        <final-term>{$prefix || "fingers"}</final-term>
        <query>{cts:or-query((cts:word-query("fingers", $options), cts:word-query("digits", $options)))}</query>
    </reverse-query>,
    <reverse-query>
        <final-term>{$prefix || "forearm"}</final-term>
        <query>{cts:or-query((cts:word-query("forearm", $options), cts:word-query("ulna", $options), cts:word-query("radius", $options)))}</query>
    </reverse-query>,
    <reverse-query>
        <final-term>{$prefix || "hand"}</final-term>
        <query>{cts:or-query((cts:word-query("hand", $options)))}</query>
    </reverse-query>,
    <reverse-query>
        <final-term>{$prefix || "shoulder"}</final-term>
        <query>{cts:or-query((cts:word-query("shuolder", $options)))}</query>
    </reverse-query>,
    <reverse-query>
        <final-term>{$prefix || "upper-arm"}</final-term>
        <query>{cts:or-query((cts:word-query("upper-arm", $options)))}</query>
    </reverse-query>,
    <reverse-query>
        <final-term>{$prefix || "wrist"}</final-term>
        <query>{cts:or-query((cts:word-query("wrist", $options)))}</query>
    </reverse-query>,
    <reverse-query>
        <final-term>{$prefix || "arm"}</final-term>
        <query>{cts:or-query((cts:word-query("arm", $options), cts:word-query("brachia", $options), cts:word-query("brachial", $options)))}</query>
    </reverse-query>,
    <reverse-query>
        <final-term>{$prefix || "abdomen"}</final-term>
        <query>{cts:or-query((cts:word-query("abdomen", $options), cts:word-query("stomach", $options), cts:word-query("bowel", $options)))}</query>
    </reverse-query>,
    <reverse-query>
        <final-term>{$prefix || "back"}</final-term>
        <query>{cts:or-query((cts:word-query("back", $options)))}</query>
    </reverse-query>,
    <reverse-query>
        <final-term>{$prefix || "pelvis"}</final-term>
        <query>{cts:or-query((cts:word-query("pelvis", $options)))}</query>
    </reverse-query>,
    <reverse-query>
        <final-term>{$prefix || "shoulders"}</final-term>
        <query>{cts:or-query((cts:word-query("shoulders", $options), cts:word-query("clavical", $options)))}</query>
    </reverse-query>,
    <reverse-query>
        <final-term>{$prefix || "chest"}</final-term>
        <query>{cts:or-query((cts:word-query("chest", $options), cts:word-query("ribs"), cts:word-query("sternum"), cts:word-query("costal")))}</query>
    </reverse-query>,
    <reverse-query>
        <final-term>{$prefix || "trunk"}</final-term>
        <query>{cts:or-query((cts:word-query("trunk", $options)))}</query>
    </reverse-query>,
    <reverse-query>
        <final-term>{$prefix || "ear"}</final-term>
        <query>{cts:or-query((cts:word-query("ear", $options)))}</query>
    </reverse-query>,
    <reverse-query>
        <final-term>{$prefix || "eye"}</final-term>
        <query>{cts:or-query((cts:word-query("eye", $options), cts:word-query("orbital", $options)))}</query>
    </reverse-query>,
    <reverse-query>
        <final-term>{$prefix || "mouth"}</final-term>
        <query>{cts:or-query((cts:word-query("mouth", $options)))}</query>
    </reverse-query>,
    <reverse-query>
        <final-term>{$prefix || "neck"}</final-term>
        <query>{cts:or-query((cts:word-query("neck", $options)))}</query>
    </reverse-query>,
    <reverse-query>
        <final-term>{$prefix || "nose"}</final-term>
        <query>{cts:or-query((cts:word-query("nose", $options)))}</query>
    </reverse-query>,
    <reverse-query>
        <final-term>{$prefix || "head"}</final-term>
        <query>{cts:or-query((cts:word-query("head", $options), cts:word-query("cranium", $options)))}</query>
    </reverse-query>
);

declare function t:soap-text($original) {
    let $soap-text := fn:normalize-space(fn:string($original/root/DIAGNOSIS_SUMMARY_COMMENT_TEXT))
    return if ($soap-text and $soap-text ne "" and $soap-text ne "NULL")
        then
            element med:soap-text { $soap-text }
        else ()
};

declare function t:check-inuries($text-node, $uri) {
    for $each in $injury-reverse-queries
    return
        if (cts:contains($each//query, cts:reverse-query($text-node)))
        then
            sem:triple($uri, sem:iri($prefix || "injury"), sem:iri($each//final-term/text()))
        else ()
};

declare function t:check-proximity($text-node, $uri) {
    for $each in $proximity-reverse-queries
    return
        if (cts:contains($each//query, cts:reverse-query($text-node)))
        then
            sem:triple($uri, sem:iri($prefix || "proximity"), sem:iri($each//final-term/text()))
        else ()
};

declare function t:transform($content as map:map, $context as map:map) as map:map* {
    let $original := map:get($content, "value")
    let $uri := sem:iri(map:get($content, "uri"))
    let $created-date := fn:replace($original/root/CREATED/text(), " ", "T")
    let $updated-date := fn:replace($original/root/UPDATED/text(), " ", "T")
    let $encounter-id := xs:int($original/root/ENCOUNTER_ID)
    let $soap-text := t:soap-text($original)
    let $new-doc := element env:location {
        element meta:meta {
            element meta:date-ingested { fn:current-dateTime() },
            element meta:created-date { $created-date },
            element meta:updated-date { $updated-date }
        },
        element env:data {
            element med:encounter {
                element med:id { $encounter-id },
                $soap-text,
                element med:original-data {
                    $original/root/element()
                }
            }
        },
        element env:triples {
            sem:triple($uri, $pred-encounter-id, xs:int($encounter-id)),
            sem:triple($uri, $pred-rdf-type,            $encounter-type),
            check-inuries($soap-text, $uri),
            check-proximity($soap-text, $uri)
        }
    }
    let $_ := map:put($content, "value", $new-doc)
    return
        $content
};
