#!/bin/sh

# when this script exits with success, the required mysql db tables
# exist.

t_init=../etc/chtofr/t_init.sql
user=tester
password=tester
database=tester


mysql --user=${user} -p${password} -e "DROP DATABASE IF EXISTS ${database}; CREATE DATABASE ${database}"
mysql --user=${user} -p${password} -D${database} < ${t_init}

TESTSTR=`mysql --user=${user} -p${password} -D${database} -e "SHOW TABLES" | sort | tr '\n' '#'`
VALSTR="Tables_in_tester#t_ch_prefix#t_channel#t_frame_info#t_frame_type#t_map#"

[ "x${TESTSTR}" == "x${VALSTR}" ] && exit 0 || exit 1

