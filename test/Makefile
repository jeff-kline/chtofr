TESTS=testsql.sh testchtofr.sh
PYTHON=python

all: $(TESTS)
	echo "Done"

$(TESTS):
	./$@

clean:
	rm -f *~ *.pyc 

.PHONY: $(TESTS) all
