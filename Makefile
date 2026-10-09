CVBASIC = cvbasic
ASM = gasm80
BAS = game.bas
ASM_OUT = game.asm
ROM = Assembloids.rom

PROLOGUE ?= .

$(ROM): $(BAS) $(PROLOGUE)/cvbasic_prologue.asm $(PROLOGUE)/cvbasic_epilogue.asm
	$(CVBASIC) --msx $(BAS) $(ASM_OUT)
	$(ASM) $(ASM_OUT) -o $(ROM)

.PHONY: clean
clean:
	rm -f $(ASM_OUT) $(ROM)

.PHONY: distclean
distclean: clean
	rm -f cvbasic_prologue.asm cvbasic_epilogue.asm
