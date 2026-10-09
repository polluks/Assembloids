CVBASIC = cvbasic
ASM = gasm80
CC ?= cc
BAS = game.bas
ASM_OUT = game.asm
ROM = Assembloids.rom

PLETTER = build/pletter

PROLOGUE ?= .

$(ROM): $(BAS) $(PROLOGUE)/cvbasic_prologue.asm $(PROLOGUE)/cvbasic_epilogue.asm
	$(CVBASIC) --msx $(BAS) $(ASM_OUT)
	$(ASM) $(ASM_OUT) -o $(ROM)

# Build the Pletter compressor (nanochess/Pletter submodule)
$(PLETTER): pletter/pletter.c
	mkdir -p build
	$(CC) -O2 -o $@ $<

.PHONY: pletter
pletter: $(PLETTER)

# Compress a file with Pletter: make compress FILE=path/to/data.bin
# Output: FILE.plet5, decompressible with unpack.asm (see pletter/pletter.txt)
.PHONY: compress
compress: $(PLETTER)
	$(PLETTER) $(FILE)

.PHONY: clean
clean:
	rm -f $(ASM_OUT) $(ROM)

.PHONY: distclean
distclean: clean
	rm -f cvbasic_prologue.asm cvbasic_epilogue.asm
