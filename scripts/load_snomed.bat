if "%1" == "" goto ERROR
if "%2" == "" goto ERROR
if "%3" == "" goto ERROR

SET SNOMED_DIR=data\snomed
set ML_USERNAME=%1
set ML_PASSWORD=%2
set ML_HOST=%3
set ML_PORT=8700

set ML_PERMISSIONS="rest-writer,update,rest-reader,read"
set SNOMED_GRAPH="http://dvievr.health.dha.mil/semantics/snomed"

mlcp import -input_file_path $SNOMED_DIR -input_file_type rdf -input_file_pattern ".*\.nt" ^
    -output_graph $SNOMED_GRAPH -output_permissions $ML_PERMISSIONS ^
    -host $ML_HOST -port $ML_PORT -username $ML_USERNAME -password $ML_PASSWORD

goto END

:ERROR
if "%1" == "" echo "No Username"
if "%2" == "" echo "No Password"
if "%3" == "" echo "No Host"

echo "Usage: load_snomed [username] [password] [marklogic host]"

:END

