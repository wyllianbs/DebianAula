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
# Uso: bash customize-skel.sh <caminho-do-squashfs-root> <live-user> [layout-teclado] [iso-locale]
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
KEYBOARD_LAYOUT="${3:-br}"
ISO_LOCALE="${4:-en_US.UTF-8}"
ISO_LANG_SHORT="${ISO_LOCALE%.UTF-8}"
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
sudo grep -rlZ "ufsc" "$SKEL_DST" 2>/dev/null | sudo xargs -0 -r sed -i "s/ufsc/$LIVE_USER/g" || true

# kxkbrc traz o layout de teclado da sessão KDE (o skel/ foi capturado com
# "br"). Ajusta para o layout escolhido nesta build, se for diferente.
if [[ -f "$SKEL_DST/.config/kxkbrc" ]]; then
    sudo sed -i "s/^LayoutList=.*/LayoutList=$KEYBOARD_LAYOUT/" "$SKEL_DST/.config/kxkbrc"
fi

# user-dirs.locale controla em que idioma o xdg-user-dirs-update nomeia as
# pastas do home (Desktop/Área de Trabalho, Documents/Documentos etc) na
# primeira sessão do usuário. Segue o idioma escolhido para a ISO.
# (skel/.config/user-dirs.conf desliga esse updater — ver comentário lá —,
# então isto é só coerência caso alguém o reative.)
if [[ -f "$SKEL_DST/.config/user-dirs.locale" ]]; then
    echo "$ISO_LANG_SHORT" | sudo tee "$SKEL_DST/.config/user-dirs.locale" > /dev/null
fi

# ~/Desktop precisa EXISTIR, não só estar declarado em user-dirs.dirs:
# quando o diretório não existe, o Qt/KDE ignora XDG_DESKTOP_DIR e cai no
# fallback $HOME — a área de trabalho passa a mostrar o home inteiro
# (Downloads e afins viram ícones) e o KCM "Localizações" exibe /home/<user>.
# Normalmente quem criaria essa pasta é o xdg-user-dirs-update no primeiro
# login, mas ele não roda na sessão Xephyr do build (chamamos
# startplasma-x11 direto, sem passar pelo /etc/X11/Xsession.d/), então a
# pasta nunca nascia. Criada aqui para o resultado não depender disso.
# Downloads entra pelo mesmo motivo: também está declarado em
# user-dirs.dirs e, com o updater desligado, ninguém mais o criaria.
for d in Desktop Downloads; do
    sudo mkdir -p "$SKEL_DST/$d"
    sudo chown root:root "$SKEL_DST/$d"
done

# Thonny (IDE usada nas aulas de Python) também segue o idioma da ISO.
# Best-effort: se o Thonny não tiver tradução para o idioma escolhido, ele
# cai para inglês sozinho.
if [[ -f "$SKEL_DST/.config/Thonny/configuration.ini" ]]; then
    sudo sed -i "s/^language = .*/language = $ISO_LANG_SHORT/" "$SKEL_DST/.config/Thonny/configuration.ini"
fi

msg ">>> /etc/skel atualizado." ">>> /etc/skel updated."
