#!/bin/bash
#
# HOME nem sempre chega definido quando disparado via autostart do Plasma
# 6 (unidade systemd gerada por app-*@autostart.service) -- cai pra
# consulta no /etc/passwd nesse caso, igual ao fallback do til (~) do bash.
: "${HOME:=$(getent passwd "$(id -un)" | cut -d: -f6)}"
#
# debianaula-fix-paths.sh — Runs once, at the first login of whatever user
# Calamares creates during install. Fixes up any leftover file under $HOME
# that still hardcodes the live-build username's path (/home/<old user>),
# in case something slipped past build-iso.sh's own scan for this (see the
# "Espelhando a home do usuário live inteira" step). Safe to run more than
# once and safe on a live session or a user matching the live username --
# it just does nothing in those cases.
#
# ~/.debianaula-live-user (written into /etc/skel at build time, install
# mode only) holds the live-build username; if it's missing or matches the
# current user, there's nothing to fix.

MARKER_DONE="$HOME/.config/.debianaula-paths-fixed"
[[ -f "$MARKER_DONE" ]] && exit 0

OLD_USER_FILE="$HOME/.debianaula-live-user"
if [[ -f "$OLD_USER_FILE" ]]; then
    OLD_USER="$(cat "$OLD_USER_FILE")"
    CURRENT_USER="$(whoami)"
    if [[ -n "$OLD_USER" && "$OLD_USER" != "$CURRENT_USER" ]]; then
        # -I: skip binary files (sed on those could corrupt caches/dbs
        # instead of just fixing text config).
        grep -rlZI "/home/$OLD_USER" "$HOME" \
            --exclude-dir=.cache --exclude-dir=nvim --exclude-dir=node_modules \
            2>/dev/null \
            | xargs -0 -r sed -i "s#/home/$OLD_USER#$HOME#g"
    fi
fi

# O lançador "Instalar Debian" fica na área de trabalho da ISO live (é o
# ponto de entrada da instalação), mas o Calamares remove o pacote
# calamares-settings-debian no fim da instalação -- e com ele o
# /usr/bin/calamares-install-debian que este .desktop chama. No sistema já
# instalado o ícone sobraria apontando para um comando inexistente. Como o
# home do usuário live é preservado na instalação, é aqui que dá para
# limpar: se o alvo do Exec sumiu, o atalho não serve mais para nada.
LAUNCHER="$HOME/Desktop/calamares-install-debian.desktop"
if [[ -f "$LAUNCHER" ]] && ! command -v calamares-install-debian >/dev/null 2>&1; then
    rm -f "$LAUNCHER"
fi

mkdir -p "$(dirname "$MARKER_DONE")"
touch "$MARKER_DONE"
