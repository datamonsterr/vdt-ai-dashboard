# AI Monitor Documentation System

This system converts Mermaid diagrams from the system design document into PNG images and updates the markdown to use those images instead of Mermaid code blocks.

## Structure

```
ai-monitor/
├── docs/
│   ├── system_design.md          # Main system design document
│   ├── diagrams/                 # Mermaid source files (.mmd)
│   │   ├── class_diagram.mmd
│   │   ├── uc1_1_flow.mmd
│   │   ├── uc1_1_sequence.mmd
│   │   └── ... (29 total diagrams)
│   └── output/
│       └── diagrams/             # Generated PNG images
├── scripts/
│   ├── convert_diagrams.sh       # Convert .mmd to PNG
│   └── update_markdown.sh        # Replace Mermaid blocks with images
├── Makefile                      # Build automation
└── README.md                     # This file
```

## Quick Start

1. **Setup dependencies** (first time only):
   ```bash
   make setup
   ```

2. **Generate all diagrams and update documentation**:
   ```bash
   make docs
   ```

3. **View available commands**:
   ```bash
   make help
   ```

## Available Commands

- `make setup` - Install required dependencies (mermaid-cli, puppeteer-chrome)
- `make clean` - Remove generated PNG files
- `make clean-all` - Remove all generated files and directories
- `make diagrams` - Convert all Mermaid diagrams to PNG images
- `make update-markdown` - Update system design markdown to use PNG images
- `make docs` - Generate complete documentation with images
- `make check-deps` - Check if required dependencies are installed
- `make list-diagrams` - List all Mermaid diagram files
- `make list-images` - List all generated PNG images
- `make stats` - Show project statistics

## How It Works

1. **Diagram Extraction**: 29 Mermaid diagrams were extracted from the original system design document and saved as individual `.mmd` files in `docs/diagrams/`

2. **Image Generation**: The `convert_diagrams.sh` script uses `mmdc` (Mermaid CLI) with Puppeteer Chrome to render each `.mmd` file as a PNG image with dark theme and transparent background

3. **Markdown Update**: The `update_markdown.sh` script replaces all Mermaid code blocks in the system design document with image references to the generated PNG files

4. **Automation**: The Makefile orchestrates the entire process and provides convenient commands

## Dependencies

- **Node.js and npm** - For Mermaid CLI
- **@mermaid-js/mermaid-cli** - Converts Mermaid to images
- **puppeteer** - Chrome headless shell for rendering
- **Python 3** - For advanced text processing
- **Bash** - For shell scripts

## Generated Files

The system generates:
- **29 PNG images** in `docs/output/diagrams/`
- **Updated system_design.md** with image references
- **Backup file** `system_design.md.backup` before updates

## Diagram Types

The system includes diagrams for:
- **Class Diagram** - Overall system architecture
- **Use Case Flow Diagrams** - Process flows for each use case
- **Sequence Diagrams** - Interaction sequences for each use case

### Use Cases Covered:
- UC-1.1: Manage Project (CRUD)
- UC-1.2: Manage Project Access Control  
- UC-1.3: Propose Alert Rule
- UC-2.1: Push Monitoring Event
- UC-2.2: Process & Aggregate Event
- UC-1 through UC-9: Comprehensive use case specifications

## Notes

- The original system design document is backed up before any modifications
- All images use dark theme with transparent background for better presentation
- The system handles Chrome/Puppeteer installation automatically
- Individual diagram files allow for easy maintenance and updates
