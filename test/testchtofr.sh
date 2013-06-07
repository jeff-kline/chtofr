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

function bigquery {
    # input base filename is 1
    # error message is 2
    # any last-stage filtering is 3
    mysql --user=$DBUSER -p$DBPW -D$DBDB -e \
	'SELECT ch_prefix,ch_subsystem,channel,ch_attr,frame_type,gps,nchannels,fpath FROM t_map \
   JOIN t_frame_info ON t_map.frame_info_pk=t_frame_info.frame_info_pk \
   JOIN t_frame_type ON t_frame_info.frame_type_pk=t_frame_type.frame_type_pk \
   JOIN t_channel ON t_map.channel_pk = t_channel.channel_pk \
   JOIN t_ch_subsystem ON t_map.ch_subsystem_pk = t_ch_subsystem.ch_subsystem_pk \
   JOIN t_ch_attr ON t_map.ch_attr_pk = t_ch_attr.ch_attr_pk \
   JOIN t_ch_prefix ON t_map.ch_prefix_pk = t_ch_prefix.ch_prefix_pk' |\
   tr '\t' ',' |\
   tail +2 |\
   sort |\
   grep -v PREFIX_LX  > $1_query

   # compare output
   sort $1 | $3 > $1_sort
   set +e
   diff $1_query $1_sort > /dev/null
   if [ $? -gt 0 ]; then
       echo $2
       exit 1
   fi
   set -e
   rm $1_query $1_sort
}

# GLOBAL VARIABLES
BIN=../usr/bin/chtofr
OPT="--database ${DBCFG}"
CACHE=cachef.pkl
INPUT=input_foo

#>>> TEST
# test empty input
cleardb 
rm -f ${INPUT}* && touch $INPUT
$BIN $OPT --input $INPUT
cat $INPUT | $BIN $OPT
rm -f $INPUT
$SUCCESS
#<<< TEST

#>>> TEST
cleardb
# build a duplicate ft-gps key, should be idempotent, silently ignore
# second entry.
#
STEP=10800
rm -f $INPUT
# 100 channels, filename is 100
echo PREFIX_L0,SUBSYS,CHANNEL_PEM_L0,,FT_0,$STEP,100,/qwer/foo/100 >> $INPUT
# 200 channels, filename is 200 
echo PREFIX_L0,SUBSYS,CHANNEL_PEM_L0,,FT_0,$STEP,200,/qwer/foo/200 >> $INPUT
$BIN $OPT --step $STEP --input $INPUT 2> /dev/null
bigquery ${INPUT} "error: the second INSERT operation was not ignored" "head -n1"
rm -f $INPUT
$SUCCESS
#<<< TEST

#>>> TEST
cleardb
# check that whitespace is ignored
STEP=10800
# 100 channels, filename is 100
echo PREFIX_L0,  SUBSYS, CHANNEL_PEM_L0,   , FT_0, $STEP, 100, /qwer/foo/100 > $INPUT
cat $INPUT | sed 's/ //g' > x$INPUT
cat $INPUT | $BIN $OPT --step $STEP 2> /dev/null
bigquery x${INPUT} "error: Whitespace was not ignored" "head -n1"
rm -f x$INPUT $INPUT
$SUCCESS
#<<< TEST

#>>> TEST
# test nonempty input
cleardb
echo PREFIX_LX,SYBSYS,CHANNEL_PEM_LX,attr,FT_X,5,10,/qwer/asdf/sdfg/foo > $INPUT
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
rm -f $INPUT
# test caching
rm -f $CACHE
f=0
g=10800
for j in `seq 1000`; do
    for l in `seq 2`; do
	echo PREFIX_L${l},SUBSYS,CHANNEL_PEM_L${j},ATTR,FT_${f},$(( ${g}*10800 )),${g},/qwer/foo/${g} >> $INPUT
    done;
done;

# first create the cache
$BIN $OPT --input $INPUT --cache $CACHE 
bigquery ${INPUT} "error: first test with cache failed" cat
# next, read from the cache (this should run much faster than the previous cmd)
$BIN $OPT --input $INPUT --cache $CACHE 
bigquery ${INPUT} "error: second test with cache failed; idempotence fail" cat
rm -f ${INPUT} ${CACHE}
$SUCCESS
#<<<TEST

#>>> TEST
cleardb
rm -f ${INPUT}
# build a complicated input file, compare expected output against input
step=23
for j in `seq 7`; do
    for f in `seq 4`; do
	for g in `seq 5`; do
	    for l in `seq 11`; do
		for m in `seq 2`; do 
		    for a in `seq 3`; do
			echo PREFIX_L${l},SUBSYS${m},CHANNEL${j},ATTR${a},FT_${f},$((${g}*${step} )),${g},/qwer/foo/${g} >> $INPUT
		    done;
		done;
	    done;
	done;
    done;
done;

# write to db
$BIN $OPT --input $INPUT --step=${step}
# do the BIG QUERY
bigquery ${INPUT} "error: t_map does not contain all information in ${INPUT}" cat
cat $INPUT | $BIN $OPT --step=${step}
bigquery ${INPUT} "error: failed idempotent test" cat
rm -f ${INPUT}
$SUCCESS
#<<< TEST

rm -f ${DBCFG}
echo
