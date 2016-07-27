xquery version '1.0-ml';

import module namespace trgr = 'http://marklogic.com/xdmp/triggers' at '/MarkLogic/triggers.xqy';

declare namespace med="http://marklogic.com/dha/example";
declare namespace meta="http://marklogic.com/dha/metadata";
declare namespace env="http://marklogic.com/dha/envelope";
declare namespace cts="http://marklogic.com/cts";


declare variable $trgr:uri as xs:string external;

(:    Some example triple predicates  :)
declare variable $pred-patient-id := sem:iri("http://marklogic.com/dha/schema#patient-id");
declare variable $pred-patient-alt-id := sem:iri("http://marklogic.com/dha/schema#alternate-id");
declare variable $pred-ethnicity-code := sem:iri("http://marklogic.com/dha/schema#ethnicity-id");
declare variable $pred-ethnicity-text := sem:iri("http://marklogic.com/dha/schema#ethnicity");
declare variable $pred-marital-status-id := sem:iri("http://marklogic.com/dha/schema#marital-status-id");
declare variable $pred-marital-status := sem:iri("http://marklogic.com/dha/schema#marital-status");

(:
    Grab the document
:)
let $user-document := fn:doc($trgr:uri)

(: Extract the patient data :)
let $user-id := $user-document/root/PATIENT_ID/text()
let $patient-icn := $user-document/root/PAGIETN_ICN/text()
let $first-name := $user-document/root/FIRST_NAME/text()
let $last-name := $user-document/root/LAST_NAME/text()
let $middle-name := $user-document/root/MIDDLE_NAME/text()

(: This is really common, fixing a date so it's in ISO standard format :)
let $created-date := fn:replace($user-document/root/CREATED/text(), " ", "T")
let $updated-date := fn:replace($user-document/root/UPDATED/text(), " ", "T")

(: Also very common, translating code to 'text' :)
let $ethnicity-id := $user-document/root/STD_ETHNICITY_ID/text()
let $ethnicity-id := if (fn:matches($ethnicity-id, "^\d+$")) then $ethnicity-id else "9"
(: Switch statements are different in XQuery, normally you use if/then/else :)
let $ethnicity := if ($ethnicity-id eq "1")
    then "Caucassian"
    else if ($ethnicity-id eq "2")
    then "African American"
    else if ($ethnicity-id eq "3")
    then "Hispanic (non-white)"
    else if ($ethnicity-id eq "4")
    then "Asian American"
    else "Unknown"

let $marital-status-id := $user-document/root/STD_MARTIAL_STATUS_ID/text()
let $marital-status-id := if (fn:matches($marital-status-id, "^\d+$")) then $marital-status-id else "9"
let $martial-status := if ($marital-status-id eq "1")
    then "Single"
    else if ($marital-status-id eq "2")
    then "Married"
    else if ($marital-status-id eq "3")
    then "Widowed"
    else "Other"

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
            element med:id { $user-id },
            element med:icn { $patient-icn },
            element med:name {
                element med:first-name { $first-name },
                element med:last-name { $last-name },
                (: example of including an element conditionally :)
                if ($middle-name) then element med:middle-name { $middle-name } else (),
                element med:full-name {
                    fn:normalize-space($first-name || " " || $middle-name || " " || $last-name)
                }
            },
            (: Add an attribute for the code but keep the text in the body :)
            element med:ethnicity {
                attribute code { $ethnicity-id },
                $ethnicity
            },
            element med:marital-status {
                attribute code { $marital-status-id },
                $martial-status
            },
            (: This is just a copy of the original data - might be removed in the future. :)
            element med:original-data {
                $user-document/root/element()
            }
        }
    },
    element env:triples {
        sem:triple(sem:iri($trgr:uri), $pred-patient-id, $user-id),
        sem:triple(sem:iri($trgr:uri), $pred-patient-alt-id, $patient-icn),
        sem:triple(sem:iri($trgr:uri), $pred-ethnicity-code, $ethnicity-id),
        sem:triple(sem:iri($trgr:uri), $pred-ethnicity-text, $ethnicity),
        sem:triple(sem:iri($trgr:uri), $pred-marital-status-id, $marital-status-id),
        sem:triple(sem:iri($trgr:uri), $pred-marital-status, $martial-status)

    }
}
return
    (
        xdmp:document-insert($trgr:uri, $new-doc, xdmp:document-get-permissions($trgr:uri),
            xdmp:document-get-collections($trgr:uri))
    )
