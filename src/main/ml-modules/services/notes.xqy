xquery version "1.0-ml";

module namespace resource = "http://marklogic.com/rest-api/resource/notes";

import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

declare function get($context as map:map, $params  as map:map) as document-node()*
{
  let $search-text := (map:get($params, "q"), "")[1]
  let $format := (map:get($params, "format"), "json")[1]
  let $options := <options xmlns="http://marklogic.com/appservices/search">
    <searchable-expression xmlns:med="http://marklogic.com/dha/example">
      //med:soap-text
    </searchable-expression>
    <additional-query>
      <cts:collection-query xmlns:cts="http://marklogic.com/cts">
        <cts:uri>encounter</cts:uri>
      </cts:collection-query>
    </additional-query>
    <return-query>true</return-query>
  </options>
  let $search-results := search:search((map:get($params, "q"), "")[1], $options)
  return
    if ($format eq "xml")
    then
      document {
        $search-results
      }
    else
      document {
        object-node {
        "total": fn:string($search-results/@total),
        "start": fn:string($search-results/@start),
        "pageLength": fn:string($search-results/@page-length),
        "results":
        array-node {
          for $result in $search-results//search:result
          return
            object-node {
              "uri": fn:string($result/@uri),
              "score": fn:string($result/@score),
              "confidence": fn:string($result/@confidence),
              "fitness": fn:string($result/@fitness),
              "matches":
                for $match in $result//search:match
                return
                  fn:replace(fn:replace(xdmp:quote($match), "search:highlight", "em"), "search:match", "div")
            }
          }
        }
      }
};
