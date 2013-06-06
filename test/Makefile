TESTS=testsql.sh testchtofr.sh testchtofrscan.sh
PYTHON=python

all: $(TESTS)
	echo "Done"

$(TESTS):
	./$@

clean:
	rm -f *~ *.pyc 

.PHONY: $(TESTS) all
