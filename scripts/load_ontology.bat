echo off

if "%1" == "" goto ERROR
if "%2" == "" goto ERROR
if "%3" == "" goto ERROR

set SKOS_FILE=data\rdf\skos-owl1-dl.rdf
set QUDT_FILE=data\rdf\qudt.rdf
set DVEIVR_DIR=data\rdf\DVEIVR\DVEIVR_2_0

set ML_USERNAME=%1
set ML_PASSWORD=%2
set ML_HOST=%3
set ML_PORT=8700

set ML_PERMISSIONS="rest-writer,update,rest-reader,read"
set SKOS_GRAPH="http://dvievr.health.dha.mil/semantics/skos"
set QUDT_GRAPH="http://dvievr.health.dha.mil/semantics/qudt"
set DVEIVR_GRAPH="http://dvievr.health.dha.mil/semantics/dveivr"

mlcp import -input_file_path %SKOS_FILE% -input_file_type rdf ^
    -output_graph %SKOS_GRAPH% -output_permissions %ML_PERMISSIONS% ^
    -host %ML_HOST% -port %ML_PORT% -username %ML_USERNAME% -password %ML_PASSWORD%

mlcp import -input_file_path %QUDT_FILE% -input_file_type rdf ^
    -output_graph %QUDT_GRAPH% -output_permissions %ML_PERMISSIONS% ^
    -host %ML_HOST% -port %ML_PORT% -username %ML_USERNAME% -password %ML_PASSWORD%

mlcp import -input_file_path %DVEIVR_DIR% -input_file_type rdf -input_file_pattern ".*\.rdf" ^
    -output_graph %SKOS_GRAPH% -output_permissions %ML_PERMISSIONS% ^
    -host %ML_HOST% -port %ML_PORT% -username %ML_USERNAME% -password %ML_PASSWORD%

goto END

:ERROR
if "%1" == "" echo "No Username"
if "%2" == "" echo "No Password"
if "%3" == "" echo "No Host"

echo "Usage: load_rxnorm [username] [password] [marklogic host]"

:END

