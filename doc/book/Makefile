all:
	pdflatex cpu.tex
	pdflatex cpu.tex

clean:
	rm -f cpu.aux
	rm -f cpu.log
	rm -f cpu.pdf
	rm -f cpu.pdf

view: all
	sudo fbgs -r 300 cpu.pdf
