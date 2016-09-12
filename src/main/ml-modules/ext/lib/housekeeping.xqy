xquery version "1.0-ml";

(:~
: User: phoehne
: Date: 9/12/16
: Time: 3:46 PM
: To change this template use File | Settings | File Templates.
:)

module namespace hk = "http://dveivr.dha.health.mil/ext/lib/housekeeping.xqy";

declare function hk:cleanup-document($document-uri) {
    xdmp:document-delete($document-uri)
};
