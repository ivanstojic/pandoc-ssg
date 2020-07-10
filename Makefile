BASE_URL=

# There are no configurable options below this line, only the code of the generator itself.

ABS_MAKEFILE=$(abspath $(lastword $(MAKEFILE_LIST)))
OUTPUT_DIR=$(dir $(ABS_MAKEFILE))_output
PANDOC=$(abspath _pandoc)

SUBDIRS=$(sort $(shell find . -maxdepth 1 -type d -iname '[a-zA-Z0-9]*'))
SUBDIRS_OUT=$(patsubst %, $(OUTPUT_DIR)/%, $(SUBDIRS))

SUBBLURBS=$(sort $(shell find . -type f -iname '*.blurb'))

ARTICLES=$(sort $(notdir $(shell find . -maxdepth 1 -type f -iname '[a-zA-Z0-9]*.md')))
ARTICLES_OUT=$(patsubst %.md, $(OUTPUT_DIR)/%.html, $(ARTICLES))

RESOURCES=$(sort $(notdir $(shell find . -maxdepth 1 -type f -iname '[a-zA-Z0-9]*' -not -name 'Makefile' -not -iname '*.md')))
RESOURCES_OUT=$(patsubst %, $(OUTPUT_DIR)/%, $(RESOURCES))

.PHONY: _build _clean $(SUBDIRS)
_default: _build
	@:

_build: $(SUBDIRS) $(RESOURCES_OUT) $(ARTICLES_OUT)

_clean:
	rm -rf $(OUTPUT_DIR)/*

_serve:
	python3 -m http.server --directory _output 8000

# Each markdown file is processed by Pandoc
$(OUTPUT_DIR)/index.html: index.md $(SUBBLURBS)
	@mkdir -p "$(@D)"
	find . -iname '*.blurb' | sort -r | xargs cat > $(OUTPUT_DIR)/_blurbs.md
	pandoc "index.md" $(OUTPUT_DIR)/_blurbs.md --data-dir="$(PANDOC)" --highlight-style=tango --standalone --to=html5 --output="$(OUTPUT_DIR)/index.html"

$(OUTPUT_DIR)/%.html: %.md
	@mkdir -p "$(@D)"
	pandoc "$<" --data-dir="$(PANDOC)" --highlight-style=tango --standalone --to=html5 --output="$@"
	pandoc "$<" --data-dir="$(PANDOC)" --highlight-style=tango --standalone --to=html5 --output="$@.blurb" --template=blurb -M URI=$(BASE_URL)/$*.html

$(SUBDIRS):
	@make -f $(ABS_MAKEFILE) -C $@ PANDOC=$(PANDOC) OUTPUT_DIR=$(OUTPUT_DIR)/$@ BASE_URL=$(BASE_URL)/$@

# Catch-all: this is either a file that we just copy, or a directory into which we recurse
$(OUTPUT_DIR)/%: %
	@mkdir -p $(@D)
	cp $< $@

