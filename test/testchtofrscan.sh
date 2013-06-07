#!/bin/sh
set -e
SUCCESS="/bin/echo -n +"

BIN=../usr/bin/chtofrscan
OPT=""
CACHE=cachescan.pkl

#>>> TEST
# test empty input
$BIN $OPT
$SUCCESS
#<<< TEST


#>>> TEST
TEST_DIR=__test__
rm -rf $TEST_DIR
# test simple directory 
for j in `seq 0 7`; do
    for k in `seq 0 10`; do
	for f in `seq 0 1`; do 
	    TMPDIR=${TEST_DIR}/ft${f}/d${j}
	    LFN=H-FT${f}-$(( (11 * j + k) * 11 ))-11.gwf
	    mkdir -p $TMPDIR
	    touch ${TMPDIR}/$LFN
	done;
    done;
done;
# force a skipped gps time (240)
rm ${TEST_DIR}/ft1/d2/H-FT1-2*

# everything is seen
F0=`$BIN $TEST_DIR $OPT --frchannels-binary= --step=60 --cache=$CACHE | wc -l | sed 's/ //'`
if [ $F0 != 155 ]; then echo error: F0 != 155; exit 1; fi

# cache files; everything skipped
F1=`$BIN $TEST_DIR $OPT --frchannels-binary= --step=60 --cache=$CACHE | wc -l | sed 's/ //'`
if [ $F1 != 0 ]; then echo error: F1 != 0; exit 1; fi

# some files should be seen.  avoid race conditions for fs with 1s
# granularity (mac)
sleep 1
touch ${TEST_DIR}/ft1/d2
F2=`$BIN $TEST_DIR $OPT --frchannels-binary= --step=60 --cache=$CACHE | wc -l | sed 's/ //'`
if [ $F2 != 5 ]; then echo error: F2 != 5; exit 1; fi

$SUCCESS
rm -rf ${TEST_DIR} ${CACHE}
#<<< TEST

echo
