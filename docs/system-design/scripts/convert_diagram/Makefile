# Makefile for building the optimized file processor

CC = gcc
CFLAGS = -O3 -march=native -flto -funroll-loops -Wall -Wextra -std=c99
LDFLAGS = -pthread
TARGET = file_processor
SOURCE = file_processor.c

# Default target
$(TARGET): $(SOURCE)
	@echo "🔨 Compiling optimized C file processor..."
	$(CC) $(CFLAGS) $(SOURCE) -o $(TARGET) $(LDFLAGS)
	@echo "✅ Build complete: $(TARGET)"

# Install target (optional)
install: $(TARGET)
	@echo "📦 Installing $(TARGET) to /usr/local/bin..."
	sudo cp $(TARGET) /usr/local/bin/
	sudo chmod +x /usr/local/bin/$(TARGET)
	@echo "✅ Installation complete"

# Clean target
clean:
	@echo "🧹 Cleaning build artifacts..."
	rm -f $(TARGET)
	@echo "✅ Clean complete"

# Performance test target
test: $(TARGET)
	@echo "🧪 Running performance test..."
	time ./$(TARGET) ../docs/diagrams ../docs/output/diagrams

.PHONY: install clean test
