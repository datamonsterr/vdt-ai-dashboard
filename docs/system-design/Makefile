# Makefile for AI Monitor Documentation

# Variables
SCRIPT_DIR := scripts
DOCS_DIR := docs
DIAGRAMS_DIR := $(DOCS_DIR)/diagrams
OUTPUT_DIR := $(DOCS_DIR)/output/diagrams

# Default target
.DEFAULT_GOAL := help

# Help target
.PHONY: help
help: ## Show this help message
	@echo "AI Monitor Documentation Build System"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Setup targets
.PHONY: setup
setup: ## Install required dependencies and build C processor
	@echo "Installing Mermaid CLI..."
	npm install -g @mermaid-js/mermaid-cli
	@echo "Installing Puppeteer Chrome..."
	npx puppeteer browsers install chrome-headless-shell
	@echo "Building C-accelerated processor..."
	@cd $(SCRIPT_DIR)/convert_diagram && make -s || echo "Warning: Failed to build C processor, shell optimization will be used instead"
	@echo ""
	@echo "For PDF generation, you'll also need:"
	@echo "  - Ubuntu/Debian: sudo apt-get install pandoc texlive-xetex"
	@echo "  - macOS: brew install pandoc basictex"
	@echo "  - Or install from: https://pandoc.org/installing.html"
	@echo "Setup complete!"

.PHONY: build-processor
build-processor: ## Build the C-accelerated diagram processor
	@echo "Building C-accelerated processor..."
	@cd $(SCRIPT_DIR)/convert_diagram && make
	@echo "C processor build complete!"

# Clean targets
.PHONY: clean
clean: ## Remove generated PNG files
	@echo "Cleaning generated diagrams..."
	rm -rf $(OUTPUT_DIR)/*.png
	@echo "Clean complete!"

.PHONY: clean-all
clean-all: clean ## Remove all generated files and directories
	@echo "Removing output directory..."
	rm -rf $(DOCS_DIR)/output
	@echo "Cleaning C processor build artifacts..."
	@cd $(SCRIPT_DIR)/convert_diagram && make clean 2>/dev/null || true
	@echo "Clean all complete!"

# Conversion targets
.PHONY: diagrams
diagrams: ## Convert all Mermaid diagrams to PNG images using C-accelerated processor
	@echo "Converting Mermaid diagrams with C-accelerated processor..."
	@$(SCRIPT_DIR)/convert_diagram/convert_diagram.sh --use-c-processor

.PHONY: diagrams-fast
diagrams-fast: ## Convert diagrams using shell-optimized version (fallback)
	@echo "Converting Mermaid diagrams with shell optimization..."
	@$(SCRIPT_DIR)/convert_diagram/convert_diagram.sh

.PHONY: diagrams-concurrent
diagrams-concurrent: ## Convert diagrams with custom job count (e.g., make diagrams-concurrent JOBS=8)
	@echo "Converting Mermaid diagrams with $(or $(JOBS),4) concurrent jobs..."
	@$(SCRIPT_DIR)/convert_diagram/convert_diagram.sh $(or $(JOBS),4) --use-c-processor

.PHONY: pdf
pdf: ## Generate PDF from system design markdown
	@echo "Generating PDF from system design document..."
	@mkdir -p $(DOCS_DIR)/output
	@cd $(DOCS_DIR) && pandoc system_design.md -o output/system_design.pdf \
		--toc \
		--number-sections \
		-V geometry:margin=1in \
		-V fontsize=11pt \
		-V documentclass=article \
		2>/dev/null || echo "Warning: Some images may not be included in PDF"
	@if [ -f $(DOCS_DIR)/output/system_design.pdf ]; then \
		echo "✓ PDF generated: $(DOCS_DIR)/output/system_design.pdf"; \
	else \
		echo "✗ Failed to generate PDF"; \
	fi

.PHONY: docs
docs: diagrams pdf ## Generate complete documentation with images and PDF

# Development targets
.PHONY: check-deps
check-deps: ## Check if required dependencies are installed
	@echo "Checking dependencies..."
	@command -v mmdc >/dev/null 2>&1 || { echo "mermaid-cli (mmdc) is not installed. Run 'make setup' first."; exit 1; }
	@command -v node >/dev/null 2>&1 || { echo "Node.js is not installed."; exit 1; }
	@command -v npm >/dev/null 2>&1 || { echo "npm is not installed."; exit 1; }
	@command -v gcc >/dev/null 2>&1 || { echo "GCC is not installed. Install build-essential."; exit 1; }
	@echo "All dependencies are installed!"

.PHONY: benchmark
benchmark: ## Run performance benchmark comparing all conversion methods
	@echo "Running performance benchmark..."
	@cd $(SCRIPT_DIR)/convert_diagram && ./benchmark.sh

.PHONY: list-diagrams
list-diagrams: ## List all Mermaid diagram files
	@echo "Available Mermaid diagrams:"
	@find $(DIAGRAMS_DIR) -name "*.mmd" -type f | sort

.PHONY: list-images
list-images: ## List all generated PNG images
	@echo "Generated PNG images:"
	@find $(OUTPUT_DIR) -name "*.png" -type f 2>/dev/null | sort || echo "No PNG images found"

# Watch mode (requires inotify-tools)
.PHONY: watch
watch: ## Watch for changes in .mmd files and auto-convert (requires inotify-tools)
	@command -v inotifywait >/dev/null 2>&1 || { echo "inotify-tools is not installed. Install with: sudo apt-get install inotify-tools"; exit 1; }
	@echo "Watching for changes in $(DIAGRAMS_DIR)..."
	@while inotifywait -e modify,create,delete $(DIAGRAMS_DIR)/*.mmd; do \
		echo "Change detected, converting diagrams..."; \
		$(SCRIPT_DIR)/convert_diagrams.sh; \
	done

# Create directory structure
.PHONY: init
init: ## Initialize project directory structure
	@echo "Creating directory structure..."
	@mkdir -p $(DIAGRAMS_DIR)
	@mkdir -p $(OUTPUT_DIR)
	@mkdir -p $(SCRIPT_DIR)
	@echo "Directory structure created!"

# Validation targets
.PHONY: validate
validate: ## Validate all Mermaid diagram syntax
	@echo "Validating Mermaid diagrams..."
	@for file in $(DIAGRAMS_DIR)/*.mmd; do \
		if [ -f "$$file" ]; then \
			echo "Validating $$file..."; \
			mmdc -i "$$file" --dry-run || exit 1; \
		fi; \
	done
	@echo "All diagrams are valid!"

# Statistics
.PHONY: stats
stats: ## Show project statistics
	@echo "=== AI Monitor Documentation Statistics ==="
	@echo "Mermaid files: $$(find $(DIAGRAMS_DIR) -name '*.mmd' | wc -l)"
	@echo "PNG images: $$(find $(OUTPUT_DIR) -name '*.png' 2>/dev/null | wc -l)"
	@echo "Total documentation files: $$(find $(DOCS_DIR) -name '*.md' | wc -l)"
	@echo "Script files: $$(find $(SCRIPT_DIR) -name '*.sh' | wc -l)"
