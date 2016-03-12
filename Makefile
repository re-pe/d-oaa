DC=dmd

all: doc test

doc: ordered_aa.d
	$(DC) -D -c $<

test: ordered_aa.d
	$(DC) -unittest -g -wi -main -run $<

clean:
	git ls-files --others | xargs -d '\n' rm -f
