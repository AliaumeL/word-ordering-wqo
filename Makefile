.PHONY: clean

PAPER=wqo-on-words
SRC=src/*.tex             \
	lib/*.tex             \
	papers.bib            \
	knowledges.kl         \
	ensps-colorscheme.sty \
	plainurl.bst		  \
	wqo-on-words.tex

FIGURES=fig/subword-embedding-standalone.tex \
		fig/infix-embedding-standalone.tex   \
		fig/prefix-embedding-standalone.tex  \
		fig/antichain-branch-standalone.tex  \
		fig/prefix-core-and-branches-standalone.tex
#		fig/infix-encoding-standalone.tex


# Default target: create the pdf file
$(PAPER).pdf: $(SRC) $(FIGURES)
	latexmk -pdf -pdflatex="pdflatex -interaction=nonstopmode" $(PAPER).tex


# How to create standalone versions of the pictures
fig/%.pdf: fig/%.tex
	@cp $^ $(notdir $^)
	pdflatex $(notdir $^)
	@mv $(notdir $@) $@
	@rm $(notdir $^)


# Specific parameters of the python program yield
# various standalone tikz figures
fig/antichain-branch-standalone.tex: src/word-embeddings-figure.py
	python3 src/word-embeddings-figure.py \
			--output=standalone \
			--antichain=true    \
			--size=4 > $@

fig/subword-embedding-standalone.tex: src/word-embeddings-figure.py
	python3 src/word-embeddings-figure.py \
			--output=standalone \
			--compare-with=infix \
			--size=4 \
			--relation=subword > $@

fig/infix-embedding-standalone.tex: src/word-embeddings-figure.py
	python3 src/word-embeddings-figure.py \
			--output=standalone \
			--compare-with=prefix \
			--size=4 \
			--relation=infix > $@

fig/prefix-embedding-standalone.tex: src/word-embeddings-figure.py
	python3 src/word-embeddings-figure.py \
			--output=standalone \
			--size=4 \
			--relation=prefix > $@

fig/infix-encoding-standalone.tex: src/word-embeddings-figure.py
	python3 src/word-embeddings-figure.py \
			--output=standalone \
			--size=3 \
			--relation=subword \
			--infix-enc=true > $@


# Create a single file tex document for arXiv
$(PAPER).arxiv.tex: $(PAPER).pdf
	latexpand -o $(PAPER).arxiv.tex     \
		  --empty-comments          \
		  --expand-bbl $(PAPER).bbl \
              $(PAPER).tex

# Create an archive with the single file tex document and the license
$(PAPER).arxiv.tar.gz: $(PAPER).arxiv.tex
	tar -czf $(PAPER).arxiv.tar.gz \
             $(PAPER).arxiv.tex    \
			 plainurl.bst          \
			 ensps-colorscheme.sty \
			 fig/*.tex 	  \
             LICENSE

# Use a docker container to compile the arXiv version
$(PAPER).arxiv.pdf: $(PAPER).arxiv.tar.gz
	# create temporary directory
	@mkdir -p /tmp/$(PAPER).arxiv
	# extract archive
	@tar -xzf $(PAPER).arxiv.tar.gz -C /tmp/$(PAPER).arxiv
	# compile in the temporary directory
	cd  /tmp/$(PAPER).arxiv && latexmk -pdf $(PAPER).arxiv.tex
	# extract the pdf 
	@cp /tmp/$(PAPER).arxiv/$(PAPER).arxiv.pdf ./
	# delete the temporary directory
	@rm -rf /tmp/$(PAPER).arxiv/

# If someone really wants to generate the metadata file
src/metadata.tex: paper-meta.yaml templates/plain-metadata.tex
	echo "" | pandoc -t latex \
		   --template=templates/plain-metadata.tex \
		   --lua-filter=templates/git-meta.lua \
		   -o src/metadata.tex \
		   --metadata-file=paper-meta.yaml

tests:
	pytest src/word-embeddings-figure.py \
		   --junitxml=junit/test-results.xml \
		   --cov=word-embeddings-figure \
		   --cov-report=xml \
		   --cov-report=html

clean: 
	latexmk -C
	rm -f $(PAPER).arxiv.tex $(PAPER).arxiv.tar.gz $(PAPER).arxiv.pdf
