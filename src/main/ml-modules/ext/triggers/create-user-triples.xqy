xquery version '1.0-ml';

import module namespace trgr = 'http://marklogic.com/xdmp/triggers' at '/MarkLogic/triggers.xqy';

declare namespace med="http://marklogic.com/dha/example";
declare namespace meta="http://marklogic.com/dha/metadata";
declare namespace env="http://marklogic.com/dha/envelope";
declare namespace cts="http://marklogic.com/cts";


declare variable $trgr:uri as xs:string external;

declare variable $pred-patient-id := sem:iri("http://marklogic.com/dha/schema#patient-id");

let $user-document := fn:doc($trgr:uri)
let $user-id := $user-document/med:patient/med:id/text()
let $weight-in-lbs := xs:double($user-document/med:patient/med:weight) * 2.2
let $new-doc := element env:patient {
    element meta:meta {
        element meta:date-ingested { current-dateTime() }
    },
    element env:data {
        element med:patient {
            $user-document/med:patient/node(),
            element med:weight {
                attribute units { 'lbs' },
                text { $weight-in-lbs }
            }
        }
    },
    element env:triples {
        sem:triple(sem:iri($trgr:uri), $pred-patient-id, $user-id)
    }
}
return
    (
        xdmp:document-insert($trgr:uri, $new-doc, xdmp:document-get-permissions($trgr:uri),
            xdmp:document-get-collections($trgr:uri))
    )
