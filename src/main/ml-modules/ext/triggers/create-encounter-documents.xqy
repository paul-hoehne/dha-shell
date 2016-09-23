xquery version "1.0-ml";

import module namespace trgr = 'http://marklogic.com/xdmp/triggers' at '/MarkLogic/triggers.xqy';
import module namespace xlat = 'http://dveivr.dha.health.mil/ext/lib/value-translators.xqy' at "/ext/lib/value-translators.xqy";
import module namespace decl = 'http://dveivr.dha.health.mil/ext/declarations' at '/ext/declarations.xqy';
import module namespace hous = 'http://dveivr.dha.health.mil/ext/lib/housekeeping.xqy' at '/ext/lib/housekeeping.xqy';

declare namespace env = "http://dveivr.dha.health.mil/xml/envelope";
declare namespace enc = "http://dveivr.dha.health.mil/xml/encounter";
declare namespace pat = "http://dveivr.dha.health.mil/xml/patient";

declare variable $trgr:uri as xs:string external;

declare function local:conditional-element($name as xs:string, $value) {
    if ($value and fn:not(fn:normalize-space(fn:string($value)) eq ""))
    then element { $name } {
            fn:normalize-space(fn:string($value))
        }
    else ()
};



let $original := fn:doc($trgr:uri)
let $patient-data := cts:search(fn:collection("patient"), cts:element-value-query(xs:QName("pat:patientId"), $original/encounter/patientId))[1]
let $patient-uri := fn:base-uri($patient-data)
let $encounter-base := <enc:encounter> {(
    local:conditional-element("enc:encounterId", $original/encounter/encounterId),
    local:conditional-element("enc:patientId", $original/encounter/patientId),
    local:conditional-element("enc:referralId", $original/encounter/referralId),
    local:conditional-element("enc:providerId", $original/encounter/providerId),
    local:conditional-element("enc:sta6a", $original/encounter/sta6a),
    local:conditional-element("enc:visitDate", $original/encounter/visitDate),
    local:conditional-element("enc:sta6a", $original/encounter/sta6a),
    local:conditional-element("enc:chiefComplaintText", $original/encounter/chiefComplaintText),

    local:conditional-element("enc:tbiIndicator", xlat:xlat-indicator($original/encounter/tbiIndicator)),
    local:conditional-element("enc:tbiReadProblemIndicator", xlat:xlat-indicator($original/encounter/tbiReadProblemIndicator)),
    local:conditional-element("enc:tbiDiplopiaIndicator", xlat:xlat-indicator($original/encounter/tbiDiplopiaIndicator)),
    local:conditional-element("enc:tbiDazzinglIndicator", xlat:xlat-indicator($original/encounter/tbiDazzinglIndicator)),
    local:conditional-element("enc:tbiPhotophobiaIndicator", xlat:xlat-indicator($original/encounter/tbiPhotophobiaIndicator)),
    local:conditional-element("enc:tbiOtherNeurologicalIndicator", xlat:xlat-indicator($original/encounter/tbiOtherNeurologicalIndicator)),
    local:conditional-element("enc:tbiEyeStrainIndicator", xlat:xlat-indicator($original/encounter/tbiEyeStrainIndicator)),
    local:conditional-element("enc:tbiBlurredVisionIndicator", xlat:xlat-indicator($original/encounter/tbiBlurredVisionIndicator)),

    element enc:symptoms {
        if (xlat:xlat-indicator($original/encounter/tbiIndicator)) then <enc:symptom>TBI</enc:symptom> else (),
        if (xlat:xlat-indicator($original/encounter/tbiReadProblemIndicator)) then <enc:symptom>Reding Problem</enc:symptom> else (),
        if (xlat:xlat-indicator($original/encounter/tbiDiplopiaIndicator)) then <enc:symptom>Diplopia</enc:symptom> else (),
        if (xlat:xlat-indicator($original/encounter/tbiDazzinglIndicator)) then <enc:symptom>Dazzling</enc:symptom> else (),
        if (xlat:xlat-indicator($original/encounter/tbiPhotophobiaIndicator)) then <enc:symptom>Photophobia</enc:symptom> else (),
        if (xlat:xlat-indicator($original/encounter/tbiOtherNeurologicalIndicator)) then <enc:symptom>Other Neurological</enc:symptom> else (),
        if (xlat:xlat-indicator($original/encounter/tbiEyeStrainIndicator)) then <enc:symptom>Eye Strain</enc:symptom> else (),
        if (xlat:xlat-indicator($original/encounter/tbiBlurredVisionIndicator)) then <enc:symptom>Blurred Vision</enc:symptom> else ()
    },

    local:conditional-element("enc:currentlyHospitalizedIndicator", xlat:xlat-indicator($original/encounter/currentlyHospitalizedIndicator)),
    local:conditional-element("enc:followup", xlat:xlat-indicator($original/encounter/followup)),
    local:conditional-element("enc:duplicate", xlat:xlat-indicator($original/encounter/duplicate)),

    local:conditional-element("enc:neurologicalCommentText", $original/encounter/neurologicalCommentText),
    local:conditional-element("enc:diagnosisSummaryCommentText", $original/encounter/diagnosisSummaryCommentText),
    local:conditional-element("enc:procedureSummaryCommentText", $original/encounter/procedureSummaryCommentText),
    local:conditional-element("enc:primaryClinicStopDescription", $original/encounter/primaryClinicStopDescription),
    local:conditional-element("enc:primaryClinicStop", $original/encounter/primaryClinicStop),
    local:conditional-element("enc:historyOfPresentIllnessText", $original/encounter/historyOfPresentIllnessText),

    local:conditional-element("enc:standardEncounterType", xlat:xlat-standard-encounter($original/encounter/standardEncounterType)),
    local:conditional-element("enc:standardMaritalStatus", xlat:xlat-marital-status($original/encounter/standardMaritalStatus)),
    local:conditional-element("enc:standardServiceBranch", xlat:xlat-service-branch($original/encounter/standardServiceBranch)),
    local:conditional-element("enc:serviceStatus", xlat:xlat-service-status($original/encounter/serviceStatus)),
    local:conditional-element("enc:standardServiceStatus", $original/encounter/standardServiceStatus),
    local:conditional-element("enc:standardLivingArrangementsType", $original/encounter/standardLivingArrangementsType),

    local:conditional-element("enc:unit", $original/encounter/unit),
    local:conditional-element("enc:occupation", $original/encounter/occupation),
    local:conditional-element("enc:jobDescription", $original/encounter/jobDescription),
    local:conditional-element("enc:militaryStatus", $original/encounter/militaryStatus)
)}
</enc:encounter>
let $encounter-document := <env:envelope>
    <env:metadata>
        <env:import-date>{fn:current-dateTime()}</env:import-date>
    </env:metadata>
    <env:original>{fn:doc($trgr:uri)}</env:original>
    { $encounter-base }
    <pat:patient>
        {
            if($patient-data)
            then
                $patient-data//pat:patient/element()
            else
                ()
        }
    </pat:patient>
</env:envelope>
let $filename := "/encounters/" || $original/encounter/encounterId/text() || ".xml"
return
    (
        xdmp:document-insert($filename, $encounter-document,
                (xdmp:permission("rest-reader", "read"), xdmp:permission("rest-writer", "update")),
                ("final", "type/encounter", "encounter", $original/encounter/patientId/text())),
        xdmp:spawn-function(function() {
            (xdmp:log($encounter-base),
                xdmp:node-insert-child(fn:doc($patient-uri)//enc:encounters, $encounter-base))
            }, <options xmlns="xdmp:eval">
                <transaction-mode>update-auto-commit</transaction-mode>
            </options>)
    )