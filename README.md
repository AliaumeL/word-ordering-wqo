# Well-quasi-orderings on word languages

> Do you sometimes wish usual word orderings such as the prefix ordering on
words were well-quasi-orders? Say no more: here is a classification of
languages where your dreams come true. 

This repository contains the code and data for the paper "Well-quasi-orderings
on word languages", which is a joint work that originated from the [Autobóz
2024 workshop].

## How to build

You will need a working [LaTeX] installation to build the paper. The paper is
written in [LaTeX] and uses [BibTeX] for the bibliography. Furthermore,
a [Makefile] is provided to automate the build process. To build the paper,
you can run the following command:

```bash
make wqo-on-words.pdf
```

This will generate the file `wqo-on-words.pdf` in the current directory.

If you want to publish to [the arXiv] you can generate a self-contained
version of the paper by running the following command:[^arxiv]

```bash
make arxiv.tar.gz
```

[^arxiv]: This uses the [tar] command, which should be available on most Unix-like systems.

## How to contribute

The paper is written in [LaTeX] and the source files are located in the `src`
directory. Custom macros and environments are located in the `lib` directory.
Bibliography entries are all located in the single file `papers.bib`.

This paper uses the [knowledge] package which uses the file `knowledges.kl` to
store the knowledge base. We refer to the official documentation of the
[knowledge] package on the CTAN for more information.

The metadata of the paper (authors, title, abstract, doi ...) are stored in a
separate `paper-meta.yaml` file, with the hope that it will be useful for
future automation.

## Credits

The paper is a joint work by the following authors (in no particular order)
Aliaume Lopez, Corto Mascle, Lia Schütze, Vincent Michielini, Nathan Lhote,
Roland Guttenberg, and Omid Yaghoubi. Furthermore, the authors would like to
thank all the participants of the [Autobóz 2024 workshop] for their feedback
and discussions.

[Autobóz 2024 workshop]: https://autoboz.org/2024
[LaTeX]: https://www.latex-project.org/
[BibTeX]: http://www.bibtex.org/
[Makefile]: https://www.gnu.org/software/make/
[the arXiv]: https://arxiv.org/
[tar]: https://www.gnu.org/software/tar/
[knowledge]: https://ctan.org/pkg/knowledge
[CTAN]: https://ctan.org/
