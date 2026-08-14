#!/bin/bash
#
# customize-skel.sh — Popula /etc/skel dentro da ISO com as customizações
# de ambiente do usuário (Dolphin, Firefox, Konsole, Kate, painel/systray/
# relógio do Plasma).
#
# Roda no HOST (não precisa de chroot: é só cópia de arquivo), chamado pelo
# build-iso.sh antes do usuário live ser criado — assim o adduser já copia
# tudo isso automaticamente para o home do novo usuário.
#
# Uso: bash customize-skel.sh <caminho-do-squashfs-root> <live-user>
#
# Para alterar a customização: edite os arquivos dentro de skel/ neste
# repositório (não precisa mexer no build-iso.sh).

set -euo pipefail

SQUASHFS_ROOT="${1:?Uso: customize-skel.sh <squashfs-root> <live-user>}"
LIVE_USER="${2:?Uso: customize-skel.sh <squashfs-root> <live-user>}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKEL_SRC="$SCRIPT_DIR/skel"
SKEL_DST="$SQUASHFS_ROOT/etc/skel"

if [[ ! -d "$SKEL_SRC" ]]; then
    echo ">>> customize-skel.sh: diretório '$SKEL_SRC' não existe, nada a copiar."
    exit 0
fi

echo ">>> Aplicando customizações de $SKEL_SRC em $SKEL_DST ..."
sudo mkdir -p "$SKEL_DST"
sudo cp -a "$SKEL_SRC"/. "$SKEL_DST"/
sudo chown -R root:root "$SKEL_DST"

# Os arquivos em skel/ foram capturados com o usuário "ufsc" (usado durante
# o desenvolvimento). Troca para o usuário live escolhido nesta build, em
# qualquer arquivo de texto que referencie /home/ufsc (ex: user-places.xbel).
sudo grep -rlZ "ufsc" "$SKEL_DST" 2>/dev/null | sudo xargs -0 -r sed -i "s/ufsc/$LIVE_USER/g"

echo ">>> /etc/skel atualizado."
