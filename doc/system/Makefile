all:
	pdflatex sysdesign.tex
	pdflatex sysdesign.tex
	mv sysdesign.pdf sysdesign_sub.pdf
	pdfunite sysdesign_sub.pdf \
	         ../isis/tlc.PDF \
	         ../isis/cpu.PDF \
	         ../isis/pipeline.PDF \
	         ../isis/vga.PDF \
	         sysdesign.pdf

clean:
	rm -f sysdesign.aux
	rm -f sysdesign.log
	rm -f sysdesign_sub.pdf
	rm -f sysdesign.pdf
