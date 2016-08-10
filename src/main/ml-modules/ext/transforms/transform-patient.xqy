xquery version '1.0-ml';

module namespace t = "http://marklogic.com/dha/example/transform-patient";

declare namespace  pat="http://model.dveivr.dha.health.mil/DVEIVR_PATIENT";
declare namespace meta="http://model.dveivr.dha.health.mil/DVEIVR_META";
declare namespace  env="http://model.dveivr.dha.health.mil/DVEIVR";

declare variable $rdf-prefix := "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare variable $core-prefix := "http://model.dveivr.dha.health.mil/DVEIVR_CORE.OWL#";

(:    Some example triple predicates  :)
declare variable $pred-first-name     := sem:iri($core-prefix || "personFirstName");
declare variable $pred-last-name      := sem:iri($core-prefix || "personLastName");

declare variable $pred-rdf-type       := sem:iri($rdf-prefix  || "type");
declare variable $patient-type        := sem:iri($core-prefix || "Patient");
declare variable $pred-hasGender      := sem:iri($core-prefix || "hasGender");


declare function t:transform($content as map:map, $context as map:map) as map:map* {
    let $user-document := map:get($content, "value")
    let $uri := map:get($content, "uri")

    (: Extract the patient data :)
    let $patient-id := $user-document/root/patient_id/text()
    let $first-name := $user-document/root/first_name/text()
    let $last-name := $user-document/root/last_name/text()
    let $middle-name := $user-document/root/middle_name/text()
    let $full-name := fn:normalize-space($first-name || " " || $middle-name || " " || $last-name)

    let $gender := if ($user-document/root/GENDER/text() = ("m", "M", "male", "Male", "MALE"))
    then "male"
    else if ($user-document/root/GENDER/text() = ("f", "F", "female", "Female", "FEMALE", "fem", "FEM"))
        then "female"
        else "unknown"

    (:    Wrap this in an envelope    :)
    let $new-doc := element env:patient {
        element meta:meta {
            element meta:date-ingested {fn:current-dateTime()}
        },
        element env:data {
            element pat:patient {
                element pat:id {$patient-id},
                element pat:name {
                    element pat:first-name {$first-name},
                    element pat:last-name {$last-name},
                    (: example of including an element conditionally :)
                    if ($middle-name) then element pat:middle-name {$middle-name} else (),
                    element pat:full-name {$full-name}
                },
                element pat:encounters {},
                (: This is just a copy of the original data - might be removed in the future. :)
                element pat:original-data {
                    $user-document/root/element()
                }
            }
        },
        element env:triples {
            sem:triple(sem:iri($uri), $pred-first-name, xs:string($first-name)),
            sem:triple(sem:iri($uri), $pred-last-name, xs:string($last-name)),
            sem:triple(sem:iri($uri), $pred-rdf-type, $patient-type),
            sem:triple(sem:iri($uri), $pred-hasGender, $gender)
        }
    }
    return
        (map:put($content, "value", $new-doc), $content)
};