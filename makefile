
# Allow to use a different pandoc binary, e.g. when testing.
PANDOC ?= pandoc
# Allow to adjust the diff command if necessary
DIFF = diff

FILTER_FILE_THIRDPARTY=thirdparty/fonts-and-alignment.lua

SPECIMEN_SASS = specimen.sass
SPECIMEN_CSS = specimen.css
SPECIMEN_HTML = specimen.html
SPECIMEN_PDF = specimen.pdf

all: specimens tests/expected.native tests/expected_small.native test

#
# Generate specimen documents
#
.PHONY: specimens
specimens: specimens/${SPECIMEN_CSS} specimens/${SPECIMEN_HTML} specimens/specimen_small.pdf specimens/${SPECIMEN_PDF}

specimens/specimen.css: specimens/${SPECIMEN_SASS}
	sass --no-source-map specimens/${SPECIMEN_SASS} specimens/${SPECIMEN_CSS}

specimens/specimen.html: $(FILTER_FILE_THIRDPARTY) tests/input.md
	$(PANDOC) --lua-filter=div-shortcuts.lua --lua-filter=$< --to=html5 --standalone \
		--metadata=ulem_styles \
		--css=${SPECIMEN_CSS} --output=$@ tests/input.md

specimens/specimen.pdf: $(FILTER_FILE_THIRDPARTY) tests/input.md
	$(PANDOC) --lua-filter=div-shortcuts.lua --lua-filter=$< --to=latex --standalone --pdf-engine=lualatex \
		--metadata=ulem_styles \
		--output=$@ tests/input.md

specimens/specimen_small.pdf: $(FILTER_FILE_THIRDPARTY) tests/input_small.md
	$(PANDOC) --lua-filter=div-shortcuts.lua --lua-filter=$< --to=latex --standalone --pdf-engine=lualatex \
		--metadata=ulem_styles \
		--output=$@ tests/input_small.md

tests/expected.native: $(FILTER_FILE_THIRDPARTY) tests/input.md
	$(PANDOC) --lua-filter=div-shortcuts.lua --lua-filter=$< --to=native --output=$@ \
		--metadata=ulem_styles \
		tests/input.md

tests/expected_small.native: $(FILTER_FILE_THIRDPARTY) tests/input_small.md
	$(PANDOC) --lua-filter=div-shortcuts.lua --lua-filter=$< --to=native --output=$@ \
		--metadata=ulem_styles \
		tests/input_small.md



test:
	@echo ""
	cd tests && ./test0.sh
	@echo "Finished test0 (basic DIV)"
	@echo ""
	cd tests && ./test2.sh
	@echo "Finished test2 (SPAN)"
	@echo ""
	cd tests && ./test3.sh
	@echo "Finished test3 (Integration DIV and SPAN)"
	@echo ""
	cd tests && ./test1.sh
	@echo "Finished test1 (long test for DIV and some for SPAN)"
