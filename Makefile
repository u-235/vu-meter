
### Source files and search directory
CSRC    :=  src/ind.c
ASRC    =

### Project name (also used for output file name)
ifeq ($(MAKECMDGOALS), mirror)
BUILD	= mirror
DEFS	= MIRROR
else
ifeq ($(MAKECMDGOALS), array)
BUILD	= array
DEFS	= ARRAY
else
BUILD = classic
DEFS	= CLASSIC
endif
endif

### Target device
DEVICE  = atmega8

### Optimization level (0, 1, 2, 3, 4 or s)
OPTIMIZE = s

### C Standard level (c89, gnu89, c99 or gnu99)
CSTD = gnu99

### Include dirs, library dirs and definitions
LIBS	=
LIBDIRS	=
INCDIRS	=
DEFS	+= F_CPU=1000000UL
ADEFS	= $(DEFS)

### Warning contorls
WARNINGS = #all #extra

### Output directory
OUTDIR = out
BUILDDIR = $(BUILD)
OBJDIR = $(OUTDIR)/$(BUILDDIR)/obj
BINDIR = $(OUTDIR)/$(BUILDDIR)/bin

### Output file format (ihex, bin or both) and debugger type
OUTPUT	= ihex
DEBUG	= dwarf-2


### Programs to build porject
CC      = avr-gcc
OBJCOPY = avr-objcopy
OBJDUMP = avr-objdump
SIZE    = avr-size
NM      = avr-nm


# Define all object files
COBJ      := $(CSRC:.c=.o)
AOBJ      := $(ASRC:.S=.o)
COBJ      := $(addprefix $(OBJDIR)/,$(COBJ))
AOBJ      := $(addprefix $(OBJDIR)/,$(AOBJ))
BINNAME   := $(BINDIR)/$(BUILD)_$(DEVICE)


# Flags for C files
CFLAGS += -std=$(CSTD)
CFLAGS += -g$(DEBUG)
CFLAGS += -mmcu=$(DEVICE)
CFLAGS += -O$(OPTIMIZE) -mcall-prologues
CFLAGS += $(addprefix -W,$(WARNINGS))
CFLAGS += $(addprefix -I,$(INCDIRS))
CFLAGS += $(addprefix -D,$(DEFS))
CFLAGS += -Wp,-MD,-MP,-MT,$@,-MF,$@.d


# Assembler flags
ASFLAGS += $(addprefix -D,$(ADEFS)) -Wa,-gstabs,-g$(DEBUG)
ALL_ASFLAGS = -mmcu=$(DEVICE) -I. -x assembler-with-cpp $(ASFLAGS)


# Linker flags
LDFLAGS += -Wl,-Map,$(BINNAME).map


mirror: all
array: all

# Default target.
all: mkdir version build size

ifeq ($(OUTPUT),ihex)
build: elf hex lst sym
hex: $(BINNAME).hex
else
ifeq ($(OUTPUT),binary)
build: elf bin lst sym
bin: $(BINNAME).bin
else
ifeq ($(OUTPUT),both)
build: elf hex bin lst sym
hex: $(BINNAME).hex
bin: $(BINNAME).bin
else
$(error "Invalid format: $(OUTPUT)")
endif
endif
endif

mkdir: $(SRC_DIRS)
	$(shell mkdir -p $(OBJDIR)/src/)
	$(shell mkdir -p $(BINDIR))

elf: $(BINNAME).elf
lst: $(BINNAME).lst
sym: $(BINNAME).sym


# Display compiler version information.
version :
	@$(CC) --version

# Create final output file (.hex or .bin) from ELF output file.
%.hex: %.elf
	@echo
	$(OBJCOPY) -O ihex $< $@

%.bin: %.elf
	@echo
	$(OBJCOPY) -O binary $< $@

# Create extended listing file from ELF output file.
%.lst: %.elf
	@echo
	$(OBJDUMP) -h -S -C $< > $@

# Create a symbol table from ELF output file.
%.sym: %.elf
	@echo
	$(NM) -n $< > $@

# Display size of file.
size:
	@echo
	$(SIZE) -C --mcu=$(DEVICE) $(BINNAME).elf


# Link: create ELF output file from object files.
%.elf:  $(AOBJ) $(COBJ)
	@echo
	@echo Linking...
	$(CC) $(CFLAGS) $(AOBJ) $(COBJ) --output $@

# Compile: create object files from C source files. ARM or Thumb(-2)
$(COBJ) : $(OBJDIR)/%.o : %.c
	@echo
	@echo $< :
	$(CC) -c $(CFLAGS) $< -o $@

# Assemble: create object files from assembler source files. ARM or Thumb(-2)
$(AOBJ) : $(OBJDIR)/%.o : %.S
	@echo
	@echo $< :
	$(CC) -c $(ALL_ASFLAGS) $< -o $@


# Target: clean project.
clean:
	@echo
	rm -f -r $(OUTDIR)/*

# Include the dependency files.
include $(wildcard $(OBJDIR)/*.d)

