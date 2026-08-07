# 50-fonts.sh — installs the AnnotationMono font.

FONT_VERSION=v0.4
FONT_URL="https://github.com/qwerasd205/AnnotationMono/releases/download/${FONT_VERSION}/AnnotationMono_${FONT_VERSION}.zip"
FONT_DIR=/usr/local/share/fonts/TTF

setup_fonts() {
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "$tmp_dir"' RETURN

    info "Downloading AnnotationMono ${FONT_VERSION}"
    curl -fsSL "$FONT_URL" -o "$tmp_dir/font.zip"
    unzip -q "$tmp_dir/font.zip" -d "$tmp_dir"

    sudo mkdir -p "$FONT_DIR"
    sudo mv "$tmp_dir"/dist/ttf/*.ttf "$FONT_DIR"
    sudo fc-cache -fv

    ok "Fonts installed"
}
