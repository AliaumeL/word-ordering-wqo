# We use pandoc/latex as a base
# it is an alpine distribution too
FROM pandoc/latex

# Install the texlive packages needed
# for the build
# - knowledge
# - currfile
# - tikz-cd
# - tikz
# we reinstall biber so that it is
# using the same version as the
# biblatex package in the texlive distribution
RUN tlmgr update --self
RUN tlmgr update --all
RUN tlmgr install     \
          knowledge   \
          geometry    \
          xpatch      \
          currfile    \
          tikz-cd     \
          stmaryrd    \
          amsfonts    \
          amsmath     \
          thmtools    \
          standalone  \
          booktabs    \
          varwidth    \
          tokcycle    \
          hyperref    \
          cleveref    \
          was         \
          tikzmark    \
          svn-prov    \
          gincltex    \
          l3packages  \
          microtype
RUN tlmgr update biber biblatex
# Because latex does not update fonts apparently?
# https://www.tug.org/texlive/doc/updmap.html
# https://tex.stackexchange.com/questions/10706/pdftex-error-font-expansion-auto-expansion-is-only-possible-with-scalable
RUN updmap

# we add to pandoc/latex
# the following binary packages
# - make
# - git
# - zip
# - tar (gnutar)
RUN apk add --no-cache \
    make               \
    git                \
    zip                \
    tar
