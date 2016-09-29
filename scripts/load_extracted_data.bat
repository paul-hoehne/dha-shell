echo off

if "%1" == "" goto ERROR
if "%2" == "" goto ERROR
if "%3" == "" goto ERROR


set BASE_DIRECTORY=data/sample/TRAN
set ML_USERNAME=%1
set ML_PASSWORD=%2
set ML_HOST=%3
set ML_PORT=8700


mlcp import -host %ML_HOST% -port %ML_PORT% -username %ML_USERNAME% -password %ML_PASSWORD% ^
  -aggregate_record_element PATIENT ^
  -input_file_path "%BASE_DIRECTORY%/Patient.xml" ^
  -input_file_type aggregates ^
  -output_uri_prefix "/patient/raw/" ^
  -output_uri_suffix ".xml" ^
  -output_collections "patient-raw"  ^
  -uri_id patient_id

mlcp import -host %ML_HOST% -port %ML_PORT% -username %ML_USERNAME% -password %ML_PASSWORD% ^
  -aggregate_record_element VISIT_DATA ^
  -input_file_path "%BASE_DIRECTORY%/Visit_Data.xml" ^
  -input_file_type aggregates ^
  -output_uri_prefix '/visit-data/raw/' ^
  -output_uri_suffix '.xml' ^
  -output_collections "visit-data-raw"

mlcp import -host %ML_HOST% -port %ML_PORT% -username %ML_USERNAME% -password %ML_PASSWORD% ^
  -aggregate_record_element Diagnosis ^
  -input_file_path "%BASE_DIRECTORY%/Diagnosis.xml" ^
  -input_file_type aggregates ^
  -output_uri_prefix '/diagnosis/raw/' ^
  -output_uri_suffix '.xml' ^
  -output_collections "diagnosis-raw"

mlcp import -host %ML_HOST% -port %ML_PORT% -username %ML_USERNAME% -password %ML_PASSWORD% ^
  -aggregate_record_element HISTORY ^
  -input_file_path "%BASE_DIRECTORY%/History.xml" ^
  -input_file_type aggregates ^
  -output_uri_prefix '/history/raw' ^
  -output_uri_suffix '.xml' ^
  -output_collections 'history-raw'

mlcp import -host %ML_HOST% -port %ML_PORT% -username %ML_USERNAME% -password %ML_PASSWORD% ^
  -aggregate_record_element DIAGNOSIS ^
  -input_file_path "%BASE_DIRECTORY%/Other_Diagnosis.xml" ^
  -input_file_type aggregates ^
  -output_uri_prefix '/other-diagnosis/raw/' ^
  -output_uri_suffix '.xml' ^
  -output_collections 'other-diagnosis-raw'

mlcp import -host %ML_HOST% -port %ML_PORT% -username %ML_USERNAME% -password %ML_PASSWORD% ^
  -aggregate_record_element Procedure ^
  -input_file_path "%BASE_DIRECTORY%/Procedures.xml" ^
  -input_file_type aggregates ^
  -output_uri_prefix '/procedures/raw/' ^
  -output_uri_suffix '.xml' ^
  -output_collections 'procedure-raw'

mlcp import -host %ML_HOST% -port %ML_PORT% -username %ML_USERNAME% -password %ML_PASSWORD% ^
  -aggregate_record_element ENCOUNTER ^
  -input_file_path "%BASE_DIRECTORY%/Encounter.xml" ^
  -input_file_type aggregates ^
  -output_uri_prefix "/encounter/raw/" ^
  -output_uri_suffix ".xml" ^
  -output_collections "encounter-raw" ^
  -uri_id encounter_id

:ERROR
if "%1" == "" echo "No Username"
if "%2" == "" echo "No Password"
if "%3" == "" echo "No Host"

echo "Usage: load_rxnorm [username] [password] [marklogic host]"

:END

