#!/bin/sh
set -e
SUCCESS="/bin/echo -n +"

# the database and required tables must exist and be accessable with
# user/pass 
t_init=../etc/chtofr/t_init.sql

DBCFG=testdb.json
DBUSER=tester
DBPW=tester
DBDB=tester
echo '{"db": {"type": "mysql", "user":"tester", "passwd":"tester", 
      "host":"localhost", "db":"tester"}}' | \
    python -m json.tool > $DBCFG

function cleardb {
    mysql --user=${DBUSER} -p${DBPW} -e "DROP DATABASE IF EXISTS ${DBDB}; CREATE DATABASE ${DBDB}"
    mysql --user=${DBUSER} -p${DBPW} -D${DBDB} < ${t_init}
}

BIN=../usr/bin/chtofr.py
OPT="--database ${DBCFG}"

#>>> TEST
# test empty input
cleardb 
INPUT=foo
rm -f $INPUT && touch $INPUT
$BIN $OPT --input $INPUT
cat $INPUT | $BIN $OPT
rm -f $INPUT
$SUCCESS
#<<< TEST

#>>> TEST
# test nonempty input
cleardb
echo PREFIX_LX CHANNEL_PEM_LX FT_X 5 10 /qwer/asdf/sdfg/foo >> $INPUT
$BIN $OPT --input $INPUT --step=5
# test idempotence
$BIN $OPT --input $INPUT --step=5

# test bad gps time as input 
set +e
$BIN $OPT --input $INPUT --step=7 2> /dev/null 
if [ $? -eq 0 ]; then 
    echo Step size should have caused a failure, it did not!
    exit 1; 
fi
set -e
rm -f $INPUT
$SUCCESS
#<<< TEST

#>>> TEST
cleardb
# build a complicated input file, compare expected output against input
for j in `seq 7`; do
    for f in `seq 4`; do
	for g in `seq 5`; do
	    for l in `seq 11`; do
		echo PREFIX_L${l} CHANNEL_PEM_L${j} FT_${f} $(( ${g}*10800 )) ${g} /qwer/foo/${g} >>\
                     $INPUT
	    done;
	done;
    done;
done;

# write to db
$BIN $OPT --input $INPUT

# do the BIG QUERY
mysql --user=$DBUSER -p$DBPW -D$DBDB -e \
  'SELECT ch_prefix,channel,frame_type,gps,nchannels,fpath FROM t_map \
   JOIN t_frame_info ON t_map.frame_info_pk=t_frame_info.frame_info_pk \
   JOIN t_frame_type ON t_frame_info.frame_type_pk=t_frame_type.frame_type_pk \
   JOIN t_channel ON t_map.channel_pk = t_channel.channel_pk \
   JOIN t_ch_prefix ON t_map.ch_prefix_pk = t_ch_prefix.ch_prefix_pk' |\
   tr '\t' ' ' |\
   tail +2 |\
   sort |\
   grep -v PREFIX_LX > ${INPUT}0

# compare output
sort ${INPUT} > ${INPUT}1
set +e
diff ${INPUT}0 ${INPUT}1 > /dev/null
if [ $? -gt 0 ]; then
    echo error: t_map does not contain all information in ${INPUT}
    exit 1
fi
set -e
cat $INPUT | $BIN $OPT

rm -f ${INPUT}{,0,1}
$SUCCESS
#<<< TEST

#>>> TEST
# build a large input file
cleardb
for k in `seq 2`; do
    for j in `seq 500`; do
	echo PREFIX_L${k} CHANNEL_PEM_L${j} FT_0 10800 500000 /qwer/foo/baz >> $INPUT
    done
done
# write to db
$BIN $OPT --input $INPUT

# do the BIG QUERY
mysql --user=$DBUSER -p$DBPW -D$DBDB -e \
  'SELECT ch_prefix,channel,frame_type,gps,nchannels,fpath FROM t_map \
   JOIN t_frame_info ON t_map.frame_info_pk=t_frame_info.frame_info_pk \
   JOIN t_frame_type ON t_frame_info.frame_type_pk=t_frame_type.frame_type_pk \
   JOIN t_channel ON t_map.channel_pk = t_channel.channel_pk \
   JOIN t_ch_prefix ON t_map.ch_prefix_pk = t_ch_prefix.ch_prefix_pk' |\
   tr '\t' ' ' |\
   tail +2 |\
   sort |\
   grep -v PREFIX_LX > ${INPUT}0

sort ${INPUT} > ${INPUT}1
set +e
diff ${INPUT}0 ${INPUT}1 > /dev/null
if [ $? -gt 0 ]; then
    echo error: t_map does not contain all information in ${INPUT}
    exit 1
fi
set -e
cat $INPUT | $BIN $OPT
rm -f ${INPUT}{,0,1}
$SUCCESS
#<<< TEST

rm -f ${DBCFG}
echo
