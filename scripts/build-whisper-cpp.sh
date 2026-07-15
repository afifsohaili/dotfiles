#!/bin/bash
set -euo pipefail

# Build whisper.cpp with Metal support and download large-v3 model
# Run this on a new machine to set up transcription tools

WHISPER_DIR="$HOME/.local/lib/whisper.cpp"
MODEL_DIR="$HOME/.cache/whisper/models"
MODEL_NAME="ggml-large-v3.bin"

echo "=== Building whisper.cpp ==="

# Clean up old build if it exists
if [ -d "$WHISPER_DIR" ]; then
    echo "Removing existing build at $WHISPER_DIR"
    rm -rf "$WHISPER_DIR"
fi

# Clone fresh
git clone https://github.com/ggerganov/whisper.cpp.git "$WHISPER_DIR"

# Build with Metal
cmake -S "$WHISPER_DIR" -B "$WHISPER_DIR/build" -DGGML_METAL=ON -DCMAKE_BUILD_TYPE=Release
cmake --build "$WHISPER_DIR/build" -j$(sysctl -n hw.ncpu)

# Symlink binary to PATH
ln -sf "$WHISPER_DIR/build/bin/whisper-cli" "$HOME/.local/bin/whisper-cli"

echo "=== Downloading model ==="
mkdir -p "$MODEL_DIR"

bash "$WHISPER_DIR/models/download-ggml-model.sh" large-v3

# Move model to cache
if [ -f "$WHISPER_DIR/models/$MODEL_NAME" ]; then
    mv "$WHISPER_DIR/models/$MODEL_NAME" "$MODEL_DIR/"
    echo "Model saved to $MODEL_DIR/$MODEL_NAME"
else
    echo "Error: Model download failed" >&2
    exit 1
fi

echo "=== Done ==="
echo "whisper-cli is now available at: $HOME/.local/bin/whisper-cli"
echo "Model is at: $MODEL_DIR/$MODEL_NAME"
