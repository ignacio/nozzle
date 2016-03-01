doc:
	@lua docs/gendoc.lua docs/manual.md docs/manual.html

test:
	@lua unittest/run.lua