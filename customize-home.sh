#!/bin/bash
#
# customize-home.sh — Customizações do usuário live que precisam de
# comandos de verdade (clone de repo, npm, dpkg), não só cópia de arquivo
# (isso é o que /etc/skel + customize-skel.sh já cobrem).
#
# Roda DENTRO do chroot, como o usuário live (via `su - $LIVE_USER -c "bash
# -s"`, alimentado por stdin pelo build-iso.sh) — por isso usa $HOME/~ em
# vez de caminho fixo.
#
# Para alterar: edite este arquivo, não o build-iso.sh.

set -uo pipefail   # sem -e: um passo de customização falhar não deve abortar o build

# Bilíngue (pt/en): segue o $LANG_MODE herdado do build-iso.sh; se não vier
# definido, detecta pelo $LANG/$LANGUAGE do host, com fallback padrão en_US.
if [[ -z "${LANG_MODE:-}" ]]; then
    LANG_PROBE="${LANG:-${LANGUAGE:-en}}"
    if [[ "$LANG_PROBE" == pt* ]]; then LANG_MODE="pt"; else LANG_MODE="en"; fi
fi

msg() {
    if [[ "$LANG_MODE" == "pt" ]]; then printf '%s\n' "$1"; else printf '%s\n' "$2"; fi
}

cd "$HOME" || exit 1

msg ">>> [customize-home] Desabilitando KWallet..." ">>> [customize-home] Disabling KWallet..."
mkdir -p ~/.config
cat > ~/.config/kwalletrc << 'EOF'
[Wallet]
Enabled=false
EOF

# conky (start.sh, settings.lua, conky_lua_scripts.lua, autostart) agora
# vem de skel/.conky/ e skel/.config/autostart/ — é estático, não precisa
# de comando/clone/download, então mora no skel como Dolphin/Konsole/Kate.

msg ">>> [customize-home] npm install global (prompt-sync, readline-sync, http-server)..." ">>> [customize-home] npm global install (prompt-sync, readline-sync, http-server)..."
# Global (não em $HOME) para não sujar a Área de trabalho com node_modules/
# package.json — o folder view do Plasma mostra o conteúdo de $HOME.
sudo npm i -g prompt-sync readline-sync http-server

msg ">>> [customize-home] LazyVim..." ">>> [customize-home] LazyVim..."
rm -rf ~/LazyVim-Setup
git clone https://github.com/wyllianbs/LazyVim-Setup.git ~/LazyVim-Setup \
    && (
        cd ~/LazyVim-Setup || exit 1
        chmod +x install.sh
        # --install força a cópia da config do LazyVim pro ~/.config/nvim.
        # Sem isso, o auto-detect do install.sh vê que 'nvim' já existe
        # (instalamos via apt antes) e cai em modo --update, que NÃO toca
        # na config — resultado: nvim sem LazyVim nenhum configurado.
        #
        # install.sh é 100% interativo, mas todo prompt aceita Enter em
        # branco como padrão (prefixo /opt, instala tudo, continua).
        # customize-home.sh precisa ser automático (roda antes do Xephyr),
        # então alimentamos linhas em branco de verdade em vez de EOF —
        # EOF direto (</dev/null) faz o script abortar com erro.
        yes "" | ./install.sh --install
    )

if command -v nvim >/dev/null; then
    nvim --headless "+Lazy! sync" +qa
    nvim --headless "+MasonUpdate" +qa
    nvim --headless "+TSUpdate" +qa
else
    msg ">>> [customize-home] AVISO: 'nvim' não encontrado no PATH — pulando sync do LazyVim/Mason/Treesitter." ">>> [customize-home] WARNING: 'nvim' not found on PATH — skipping LazyVim/Mason/Treesitter sync."
fi

msg ">>> [customize-home] kate-quickrun..." ">>> [customize-home] kate-quickrun..."
KQ_URL=$(curl -fsSL https://api.github.com/repos/wyllianbs/kate-quickrun/releases/latest \
    | grep '"browser_download_url"' | grep '\.deb"' | head -1 | cut -d'"' -f4)
if [[ -n "$KQ_URL" ]]; then
    wget -c -O ~/kate-quickrun.deb "$KQ_URL"
    sudo dpkg -i ~/kate-quickrun.deb || sudo apt-get install -f -y
else
    msg ">>> [customize-home] AVISO: não encontrei o .deb do kate-quickrun na release mais recente — pulando." ">>> [customize-home] WARNING: could not find the kate-quickrun .deb in the latest release — skipping."
fi

msg ">>> [customize-home] Limpando arquivos temporários..." ">>> [customize-home] Cleaning up temporary files..."
rm -rf ~/kate-quickrun.deb ~/LazyVim-Setup

msg ">>> [customize-home] Concluído." ">>> [customize-home] Done."
