xquery version "1.0-ml";

(:~
: User: phoehne
: Date: 8/17/16
: Time: 7:25 PM
: To change this template use File | Settings | File Templates.
:)

module namespace patient = "http://vision.dha.mil/lib/patient.xqy";

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

declare function patient:transform($uri) {
    let $user-document := fn:doc($uri)

    (: Extract the patient data :)
    let $patient-id := $user-document/patient/patientId/text()
    let $first-name := $user-document/patient/firstName/text()
    let $last-name := $user-document/patient/lastName/text()
    let $middle-name := $user-document/patient/middleName/text()
    let $full-name := fn:normalize-space($first-name || " " || $middle-name || " " || $last-name)
    let $permissions := xdmp:document-get-permissions($uri)
    let $collections := xdmp:document-get-collections($uri)

    let $gender := if ($user-document/patient/gender/text() = ("m", "M", "male", "Male", "MALE"))
    then "male"
    else if ($user-document/patient/gender/text() = ("f", "F", "female", "Female", "FEMALE", "fem", "FEM"))
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
                    for $element in $user-document/root/element()
                    where fn:string($element) ne "NULL" and fn:string($element) ne ""
                    return $element
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
        if ($user-document)
            then xdmp:document-insert($uri, $new-doc, $permissions, $collections)
            else xdmp:log("Uanble to find: " || $uri)
};