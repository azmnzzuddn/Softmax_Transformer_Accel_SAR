# Project Name
PROJ ?= SDPA
TARGET ?=

# Directories
RTL_DIR = ./src/rtl
TB_DIR = ./src/tb
BUILD_DIR = ./.verilator

# Source Files
RTL_SRCS = $(wildcard $(RTL_DIR)/*.v) $(wildcard $(RTL_DIR)/*.sv) $(wildcard $(RTL_DIR)/external/*.v)
TB_SRCS = $(wildcard $(TB_DIR)/*.v) $(wildcard $(TB_DIR)/*.sv)
CPP_TESTBENCH = $(wildcard $(TB_DIR)/*.cpp)

# Verilator settings
VERILATOR_FLAGS = --Mdir $(BUILD_DIR) --timing --timescale 1ns/1ps -I$(RTL_DIR) -I$(RTL_DIR)/external
WAIVER_FILE = verilator_waivers.vlt
LINT_FLAGS = $(VERILATOR_FLAGS) --lint-only -Wall $(WAIVER_FILE)
BUILD_FLAGS = $(VERILATOR_FLAGS) --cc --trace --binary -j 0
# BUILD_FLAGS += --coverage
# BUILD_FLAGS += --debug -V


# Default Rule
all: run

files:
	@echo "Verilog sources: $(RTL_SRCS) $(TB_SRCS)"

lint:
	@echo "\n----- Linting Verilog files -----\n"
ifdef TARGET
	verilator $(LINT_FLAGS) $(RTL_DIR)/$(TARGET) $(TB_DIR)/$(TARGET)_tb --top $(notdir $(TARGET))_tb
else
	verilator $(LINT_FLAGS) $(RTL_SRCS) $(TB_SRCS) --top $(PROJ)_tb
endif
	@echo "----- Successfull linting -----\n"

compile: lint
	@mkdir -p $(BUILD_DIR)
	@echo "\n----- Compiling Verilog files -----\n"
ifdef TARGET
	verilator $(BUILD_FLAGS) $(TB_DIR)/$(TARGET)_tb --top $(notdir $(TARGET))_tb
else
	verilator $(BUILD_FLAGS) $(TB_DIR)/$(PROJ)_tb --top $(PROJ)_tb
endif
	@echo "----- Successfull compiling -----\n"

# Implement a skip compilation mechanism if no change is detected
run: compile
	@echo "\n----- Running simulation -----\n"
ifdef TARGET
	$(BUILD_DIR)/V$(notdir $(TARGET))_tb
else
	$(BUILD_DIR)/V$(PROJ)_tb
endif
	@echo "----- Successfull simulation -----\n"

waveform:
	@echo "Opening waveform..."
	gtkwave .verilator/waveform.vcd &

generate-waiver:
	@echo "\n----- Generating waiver file -----\n"
	@echo "This will create a new waiver file with current warnings."
	@echo "You need to manually uncomment the lines you want to waive."
ifdef TARGET
	verilator $(VERILATOR_FLAGS) --lint-only -Wall --waiver-output $(WAIVER_FILE).new $(RTL_DIR)/$(TARGET) $(TB_DIR)/$(TARGET)_tb --top $(notdir $(TARGET))_tb || true
else
	verilator $(VERILATOR_FLAGS) --lint-only -Wall --waiver-output $(WAIVER_FILE).new $(RTL_SRCS) $(TB_SRCS) --top $(PROJ)_tb || true
endif
	@echo "\n----- Waiver file generated as $(WAIVER_FILE).new -----"
	@echo "To use the waivers:"
	@echo "1. Review the generated file: $(WAIVER_FILE).new"
	@echo "2. Uncomment (remove //) the waiver lines you want to apply"
	@echo "3. Replace the old waiver file: mv $(WAIVER_FILE).new $(WAIVER_FILE)"
	@echo "4. Run 'make lint' to verify waivers work"

clean:
	@echo "Cleaning up..."
	rm -rf $(BUILD_DIR) *.vcd coverage.dat

.PHONY: all lint compile run waveform clean generate-waiver
