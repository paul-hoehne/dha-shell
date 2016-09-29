xquery version "1.0-ml";

import module namespace trgr = 'http://marklogic.com/xdmp/triggers' at '/MarkLogic/triggers.xqy';
import module namespace xlat = 'http://dveivr.dha.health.mil/ext/lib/value-translators.xqy' at "/ext/lib/value-translators.xqy";
import module namespace decl = 'http://dveivr.dha.health.mil/ext/declarations' at '/ext/declarations.xqy';
import module namespace hous = 'http://dveivr.dha.health.mil/ext/lib/housekeeping.xqy' at '/ext/lib/housekeeping.xqy';

declare namespace env = "http://dveivr.dha.health.mil/xml/envelope";
declare namespace enc = "http://dveivr.dha.health.mil/xml/encounter";
declare namespace pat = "http://dveivr.dha.health.mil/xml/patient";

declare variable $trgr:uri as xs:string external;
declare variable $default-permissions := (xdmp:permission("rest-reader", "read"),
    xdmp:permission("rest-writer", "update"));

declare function local:conditional-element($name as xs:string, $value) {
    if ($value and fn:not(fn:normalize-space(fn:string($value)) eq ""))
    then element { $name } {
            fn:normalize-space(fn:string($value))
        }
    else ()
};


declare function local:enriched-data($original) {
    (
        local:conditional-element("enc:encounterId",              $original/encounter_id),
        local:conditional-element("enc:patientId",                $original/patient_id),
        <enc:provider>{
            local:conditional-element("enc:providerId",           $original/provider_id),
            local:conditional-element("enc:providerFirstName",    $original/PROVIDER_FIRST_NAME),
            local:conditional-element("enc:providerLastName",     $original/PROVIDER_LAST_NAME)
        }</enc:provider>,
        local:conditional-element("enc:sta6a",                    $original/sta6a),
        local:conditional-element("enc:encounterDatetime",        $original/ENCOUNTER_DATETIME),
        local:conditional-element("enc:neurologicalCommentText",  $original/neurological_comment_text),
        local:conditional-element("enc:diagnosisSummaryCommentText", $original/diagnosis_summary_comment_text),
        local:conditional-element("enc:encounterType",            $original/ENCOUNTER_TYPE),
        local:conditional-element("enc:sourceName",               $original/SOURCE_NAME),
        local:conditional-element("enc:maritalStatus",            $original/MARITALSTATUS),
        local:conditional-element("enc:serviceBranch",            $original/SERVICEBRANCH),
        local:conditional-element("enc:serviceStatus",            $original/SERVICE_STATUS),

        local:conditional-element("enc:occupation",               $original/occupation),
        local:conditional-element("enc:job_description",          $original/job_description),
        local:conditional-element("enc:rank",                     $original/RANK),
        local:conditional-element("enc:category",                 $original/CATEGORY),
        local:conditional-element("enc:chiefComplaintText",       $original/chief_complaint_text),
        local:conditional-element("enc:procedureSummaryCommentText", $original/procedure_summary_comment_text),
        local:conditional-element("enc:unit",                     $original/UNIT),
        local:conditional-element("enc:historyOfPresentIllnessText", $original/HISTORY_OF_PRESENT_ILLNESS_TEXT),
        local:conditional-element("enc:primaryClinicStopDescription", $original/primaryclinicstopdesc),
        local:conditional-element("enc:primaryClinicStop",        $original/primaryclinicstop),
        local:conditional-element("enc:livingArrangementText",    $original/LIVING_ARRANGEMENT_TEXT)
    )
};

declare function local:create-new-record($uri, $enriched, $original) {
    let $encounter-base := <enc:encounter>{$enriched}</enc:encounter>
    let $patient-document := cts:search(fn:collection("type/patient"),
            cts:element-value-query(xs:QName("pat:patientId"), $encounter-base/enc:patientId))[1]
    let $patient-uri := fn:document-uri($patient-document)
    let $_ := xdmp:log("found patient document: " || fn:base-uri($patient-document))
    let $encounter-document :=
        <env:envelope>
            <env:metadata>
                <env:import-date>{fn:current-dateTime()}</env:import-date>
            </env:metadata>
            <env:original>{$original}</env:original>
            {$encounter-base}
            <pat:patient>
                {
                    if($patient-document)
                    then
                        $patient-document//pat:patient/element()
                    else
                        ()
                }
            </pat:patient>
            <enc:histories></enc:histories>
            <enc:visitData></enc:visitData>
            <enc:diagnoses></enc:diagnoses>
            <enc:procedures></enc:procedures>
            <enc:otherDiagnoses></enc:otherDiagnoses>
        </env:envelope>
    return
        (
            xdmp:document-insert($uri, $encounter-document, $default-permissions,
                    ("final", "type/encounter", "encounter", $enriched/enc:patientId/text())),
            xdmp:spawn-function(function() {
                xdmp:node-insert-child(fn:doc($patient-uri)//enc:encounters, fn:doc($uri)//enc:encounter)
            }, <options xmlns="xdmp:eval">
                <transaction-mode>update-auto-commit</transaction-mode>
            </options>)
        )
};

declare function local:update-existing-record($uri, $enriched, $original) {
    let $encounter-document := fn:doc($uri)
    let $patient-document := cts:search(fn:collection("type/patient"),
            cts:element-value-query(xs:QName("pat:patientId"), $enriched/enc:patientId))[1]
    let $encounter :=  <enc:encounter>{$enriched}</enc:encounter>
    return
        (
            xdmp:node-replace($encounter-document/env:envelope/env:original, <env:original>{$original}</env:original>),
            xdmp:node-replace($encounter-document/env:envelope/env:encounter, $encounter),
            xdmp:node-replace($patient-document/env:envelope/enc:encounters/enc:encounter[enc:encounterId = $encounter/enc:encounterId],
                $encounter)
        )
};

let $original := fn:doc($trgr:uri)/element()
let $filename := "/encounters/" || $original/encounter_id/text() || ".xml"
let $enriched := local:enriched-data($original)
return
    if (fn:exists(fn:doc($filename)))
    then
        local:update-existing-record($filename, $enriched, $original)
    else
        local:create-new-record($filename, $enriched, $original)