#!/usr/bin/env bash

SNOMED_DIR=data/snomed/
ML_USERNAME=admin
ML_PASSWORD=admin
ML_HOST=localhost
ML_PORT=8700

ML_PERMISSIONS="rest-writer,update,rest-reader,read"
SNOMED_GRAPH="http://dvievr.health.dha.mil/semantics/snomed"

mlcp import -input_file_path $SNOMED_DIR -input_file_type rdf -input_file_pattern ".*\.nt" \
    -output_graph $SNOMED_GRAPH -output_permissions $ML_PERMISSIONS \
    -host $ML_HOST -port $ML_PORT -username $ML_USERNAME -password $ML_PASSWORD
