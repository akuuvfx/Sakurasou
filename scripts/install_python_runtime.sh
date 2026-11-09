#!/bin/sh
# Copie le runtime Python (stdlib + modules) et le paquet yt-dlp dans l'app.
# Inspiré de tfourj/Palladium (GPL-3.0) et beeware/Python-Apple-support.
set -e

export CODE_SIGNING_ALLOWED=NO
export EXPANDED_CODE_SIGN_IDENTITY=""

# Script d'aide fourni par Python-Apple-support (install_python)
SOURCE_UTILS="$PROJECT_DIR/Frameworks/Python.xcframework/build/utils.sh"
PATCHED_UTILS="$TARGET_TEMP_DIR/python-apple-support-utils.sh"
mkdir -p "$TARGET_TEMP_DIR"

# On neutralise la signature (IPA non signée, signée ensuite par AltStore/Sideloadly)
python3 - "$SOURCE_UTILS" "$PATCHED_UTILS" <<'PY'
import sys, re
src, dst = sys.argv[1:3]
text = open(src, encoding="utf-8").read()
text = re.sub(r'(?m)^(\s*)/usr/bin/codesign .*$', r'\1echo "codesign ignoré"', text)
open(dst, "w", encoding="utf-8").write(text)
PY

# shellcheck disable=SC1090
. "$PATCHED_UTILS"

# Installe stdlib + extensions Python dans l'app ; "python-packages" = dossier de paquets pip
install_python Frameworks/Python.xcframework python-packages

# Copie yt-dlp (pur Python) téléchargé par la CI
PKG_DIR="$CODESIGNING_FOLDER_PATH/python-packages"
mkdir -p "$PKG_DIR"
if [ -d "$PROJECT_DIR/Frameworks/yt-dlp-packages" ]; then
  rsync -au "$PROJECT_DIR/Frameworks/yt-dlp-packages/" "$PKG_DIR/"
fi
echo "Runtime Python installé."
