all:
	pdflatex book.tex
	pdflatex book.tex
	pdflatex book.tex

clean:
	rm -f book.aux
	rm -f book.log
	rm -f book.toc
	rm -f book.pdf
	rm -f book.lof

view: all
	sudo fbgs -r 300 book.pdf
