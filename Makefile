.PHONY: clean setup-lipics delete-lipics tests

PAPER=wqo-on-words
SRC=src/*.tex             \
	lib/*.tex             \
	papers.bib            \
	knowledges.kl         \
	ensps-colorscheme.sty \
	plainurl.bst		  

FIGURES=fig/subword-embedding-standalone.tex \
		fig/infix-embedding-standalone.tex   \
		fig/prefix-embedding-standalone.tex  \
		fig/antichain-branch-standalone.tex  \
		fig/prefix-core-and-branches-standalone.tex
#		fig/infix-encoding-standalone.tex

TEMPLATES=templates/plain/article.tex \
	  templates/filters/git-meta.lua    \
	  templates/lipics/lipics.tex 


# Default target: create the pdf file
%.pdf: %.tex $(SRC) $(FIGURES)
	latexmk -pdf -pdflatex="pdflatex -interaction=nonstopmode" $<


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


## VARIOUS STYLES
# Create a lipics document for submission
$(PAPER).lipics.tex: $(SRC) $(TEMPLATES) ./paper-meta.yaml
	pandoc --template=templates/lipics/lipics.tex \
		     --lua-filter=templates/filters/git-meta.lua \
		     --metadata-file=./paper-meta.yaml   \
		     --wrap=none \
		     -o $(PAPER).lipics.tex \
		     $(PAPER).md

# Create `plain` document for arxiv and drafts.
$(PAPER).tex: $(PAPER).md ./paper-meta.yaml $(TEMPLATES)
	pandoc --template=templates/plain/article.tex \
		     --lua-filter=templates/filters/git-meta.lua \
		     --metadata-file=./paper-meta.yaml   \
		     --wrap=none \
		     -o $(PAPER).tex \
		     $(PAPER).md

## ARXIV EXPORTS ##

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
			     fig/*.tex 	           \
           LICENSE

# Test the arxiv export 
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


### LIPICS EXPORT ###
setup-lipics:
	stow --dir templates --target . lipics

delete-lipics:
	stow --delete --dir templates --target . lipics

$(PAPER).lipics.tar.gz: $(PAPER).lipics.pdf
	latexpand -o $(PAPER).lipics.flat.tex  \
		        --empty-comments             \
						$(PAPER).lipics.tex

	@rm -rf lipics-arxiv
	@mkdir  lipics-arxiv
	@cp $(PAPER).lipics.flat.tex            lipics-arxiv/main.tex
	@cp ensps-colorscheme.sty               lipics-arxiv/
	@cp templates/lipics/cc-by.pdf          lipics-arxiv/
	@cp templates/lipics/lipics-v2021.cls   lipics-arxiv/
	@cp templates/lipics/orcid.pdf				  lipics-arxiv/
	@cp templates/lipics/lipics-logo-bw.pdf lipics-arxiv/
	@cp papers.bib lipics-arxiv/
	@cp knowledges.kl lipics-arxiv/
	@cp -r lib lipics-arxiv/lib
	@cp -r fig lipics-arxiv/fig
	@cp LICENSE lipics-arxiv/

	tar -czf $(PAPER).lipics.tar.gz \
					 lipics-arxiv

tests:
	pytest src/word-embeddings-figure.py \
		   --junitxml=junit/test-results.xml \
		   --cov=word-embeddings-figure \
		   --cov-report=xml \
		   --cov-report=html

clean: 
	latexmk -C
	rm -f $(PAPER).arxiv.tex $(PAPER).arxiv.tar.gz $(PAPER).arxiv.pdf
