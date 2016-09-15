xquery version "1.0-ml";

(:~
: User: phoehne
: Date: 9/15/16
: Time: 11:46 AM
: To change this template use File | Settings | File Templates.
:)

module namespace tf = 'http://dveivr.dha.health.mil/ext/tripling/transformation-functions.xqy';

declare function tf:return-default-class($xpath, $doc, $defaults, $parameters) {
    sem:iri(map:get($parameters, "class"))
};