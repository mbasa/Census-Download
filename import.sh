#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)
SQL_DIR=${SCRIPT_DIR}/sql
TXT_DIR=${SCRIPT_DIR}/txt

DB_NAME=estat

psql -f "${SQL_DIR}/create_table.sql" ${DB_NAME}
psql -f "${SQL_DIR}/meshNumToPoly.sql" ${DB_NAME}

echo -e "copying txt files into mesh4 table"

for i in `ls -b ${TXT_DIR}/*.txt`; do
   psql -c "\copy mesh4 from '${i}' delimiter ',' csv" -d ${DB_NAME};
done

echo -e "adding geometry column"

psql -c "alter table mesh4 add column geom geometry(polygon,4326);" -d ${DB_NAME}
psql -c 'update mesh4 set geom = generate_japan_mesh_polygon("MESH_CODE");' -d ${DB_NAME}
psql -c 'create index mesh4_1 on mesh4("MESH_CODE");' -d ${DB_NAME}
psql -c 'create index mesh4_2 on mesh4 using gist(geom);' -d ${DB_NAME}

echo -e "done"
