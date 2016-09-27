#!/usr/bin/env bash

RXNORM_DIR=data/rxnorm/
ML_USERNAME=admin
ML_PASSWORD=admin
ML_HOST=localhost
ML_PORT=8700

ML_PERMISSIONS="rest-writer,update,rest-reader,read"
RXNORM_GRAPH="http://dvievr.health.dha.mil/semantics/rxnorm"

mlcp import -input_file_path $RXNORM_DIR -input_file_type rdf -input_file_pattern ".*\.nt" \
    -output_graph $RXNORM_GRAPH -output_permissions $ML_PERMISSIONS \
    -host $ML_HOST -port $ML_PORT -username $ML_USERNAME -password $ML_PASSWORD
