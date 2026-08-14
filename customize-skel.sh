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

# Bilíngue (pt/en): segue o $LANG_MODE herdado do build-iso.sh; se não
# vier definido (script chamado sozinho), detecta pelo $LANG/$LANGUAGE do
# host, com fallback padrão para en_US.
if [[ -z "${LANG_MODE:-}" ]]; then
    LANG_PROBE="${LANG:-${LANGUAGE:-en}}"
    if [[ "$LANG_PROBE" == pt* ]]; then LANG_MODE="pt"; else LANG_MODE="en"; fi
fi

msg() {
    if [[ "$LANG_MODE" == "pt" ]]; then printf '%s\n' "$1"; else printf '%s\n' "$2"; fi
}

SQUASHFS_ROOT="${1:?$(msg "Uso: customize-skel.sh <squashfs-root> <live-user>" "Usage: customize-skel.sh <squashfs-root> <live-user>")}"
LIVE_USER="${2:?$(msg "Uso: customize-skel.sh <squashfs-root> <live-user>" "Usage: customize-skel.sh <squashfs-root> <live-user>")}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKEL_SRC="$SCRIPT_DIR/skel"
SKEL_DST="$SQUASHFS_ROOT/etc/skel"

if [[ ! -d "$SKEL_SRC" ]]; then
    msg ">>> customize-skel.sh: diretório '$SKEL_SRC' não existe, nada a copiar." ">>> customize-skel.sh: directory '$SKEL_SRC' does not exist, nothing to copy."
    exit 0
fi

msg ">>> Aplicando customizações de $SKEL_SRC em $SKEL_DST ..." ">>> Applying customizations from $SKEL_SRC to $SKEL_DST ..."
sudo mkdir -p "$SKEL_DST"
sudo cp -a "$SKEL_SRC"/. "$SKEL_DST"/
sudo chown -R root:root "$SKEL_DST"

# Os arquivos em skel/ foram capturados com o usuário "ufsc" (usado durante
# o desenvolvimento). Troca para o usuário live escolhido nesta build, em
# qualquer arquivo de texto que referencie /home/ufsc (ex: user-places.xbel).
sudo grep -rlZ "ufsc" "$SKEL_DST" 2>/dev/null | sudo xargs -0 -r sed -i "s/ufsc/$LIVE_USER/g"

msg ">>> /etc/skel atualizado." ">>> /etc/skel updated."
