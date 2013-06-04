#!/bin/sh

t_init=../etc/ch2fr/t_init.sql
user=tester
password=tester
database=tester
mysql --user=${user} -p${password} -D${database} -e "DROP DATABASE IF EXISTS ${database}"
# mysql --user=${user} -p${password} -D${database} < ${t_init}
