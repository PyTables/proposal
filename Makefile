all:
    pdflatex pytables_proposal.tex
    bibtex pytables_proposal.aux
    pdflatex pytables_proposal.tex
    pdflatex pytables_proposal.tex

clean:
    rm -rf *.aux *.out *.log pytables_proposal.pdf 

