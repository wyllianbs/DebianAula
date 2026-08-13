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

cd "$HOME" || exit 1

echo ">>> [customize-home] Desabilitando KWallet..."
mkdir -p ~/.config
cat > ~/.config/kwalletrc << 'EOF'
[Wallet]
Enabled=false
EOF

echo ">>> [customize-home] Configurando conky..."
rm -rf ~/.conky
mkdir -p ~/.conky

cat > ~/.conky/start.sh << 'EOF'
#! /bin/bash

> "$HOME/.conky/conky.log"

sleep 5s &&
pkill conky
conky -c ~/.conky/settings.lua 2> "$HOME/.conky/conky.log" &
EOF
chmod +x ~/.conky/start.sh

mkdir -p ~/.config/autostart
echo '[Desktop Entry]
Exec=bash '"$HOME"'/.conky/start.sh
Name=conky
Type=Application
X-LXQt-Need-Tray=true' > ~/.config/autostart/conky.desktop
chmod +x ~/.config/autostart/conky.desktop

echo 'function conky_format( format, number )
    return string.format( format, conky_parse( number ) )
end' > ~/.conky/conky_lua_scripts.lua

cat > ~/.conky/settings.lua << 'EOF'
conky.config = {
update_interval = 1.5,
total_run_times = 0,
use_xft = true,
font = 'Monospace:size=8',
xftalpha = 1,
text_buffer_size = 1024,
override_utf8_locale = yes,
own_window = true,
own_window_type = 'normal',
own_window_transparent = false,
own_window_hints = 'undecorated,below,sticky,skip_taskbar,skip_pager',
own_window_argb_visual = true,
own_window_argb_value = 145,
own_window_colour = '#3b3b3b',
double_buffer = true,
minimum_width = 300, minimum_height = 0,
maximum_width = 300,
draw_shades = no,
draw_outline =no,
draw_borders =no,
stippled_borders =0,
border_width = 1,
default_color = 'yellow',
alignment = 'top_right',
gap_x = 7,
gap_y = 7,
no_buffers = yes,
uppercase = no,
cpu_avg_samples = 2,
net_avg_samples = 2,
temperature_unit = 'celsius',
short_units = yes,
};

lua_load = '~/.conky/conky_lua_scripts.lua'
conky.text = [[
${if_match "${exec cat /etc/issue | grep "Debian" | cut -d' ' -f1}" == "Debian"}#
${font Hack\ Nerd\ Font:Monospace:size=50}${color #d70a53}${color yellow}${voffset 0}${alignr}${font Michroma:bold:size=8}${exec lsb_release -d | cut -f2} [${exec lsb_release -c | cut -f2}]${font Play:Monospace:size=8}
${endif}#
${if_match "${exec cat /etc/issue | grep "Ubuntu" | cut -d' ' -f1}" == "Ubuntu"}#
${font Hack\ Nerd\ Font:Monospace:size=50}${voffset 0}${alignr}${font Michroma:bold:size=8}${exec lsb_release -d | cut -f2} [${exec lsb_release -c | cut -f2}]${font Play:Monospace:size=8}
${endif}#
${if_match "${exec cat /etc/issue | grep "Fedora" | cut -d' ' -f1}" == "Fedora"}#
${font Hack\ Nerd\ Font:Monospace:size=50}󰣛${voffset 0}${alignr}${font Michroma:bold:size=8}${exec lsb_release -d | cut -f2} [${exec lsb_release -c | cut -f2}]${font Play:Monospace:size=8}
${endif}#
$alignr ${time %d de %B de %Y} $alignr ${time %H:%M:%S}
${hr 1}
${font Hack\ Nerd\ Font:Monospace:size=15}󰍹 ${font Play:Monospace:bold:size=8}SYSTEM${font Play:Monospace:size=8}
SO $alignr $nodename $alignr [$kernel $alignr $machine]
Uptime $alignr $uptime
${hr 1}
${font Hack\ Nerd\ Font:Monospace:size=15} ${font Play:Monospace:bold:size=8}RESOURCES${font Play:Monospace:size=8}${offset 107}%
 CPU    $alignr${cpu cpu0} $alignr${color darkgray}${cpubar cpu0 11,100}${color yellow}
 RAM $alignr$mem/$memmax $alignr $memperc ${color darkgray}${membar 11,100}${color yellow}
 /$alignr${fs_used /root}/${fs_size /root}$alignr ${fs_used_perc /root} ${color darkgray}${fs_bar 11,100 /root}${color yellow}
 /data ${alignr}${exec df | head -7 | tail -1  | awk '{printf "%6.2f",$3/1024/1024}'}${alignr} / ${alignr}${exec df | head -7 | tail -1  | awk '{printf "%6.2f",$2/1024/1024}'} ${alignr} ${fs_used_perc /root} ${color darkgray}${fs_bar 11,100 /root}${color yellow}
${if_existing /sys/class/power_supply/BAT0/status}#
 ${voffset 5}${font Hack\ Nerd\ Font:Monospace:size=11}󱐌 ${font Play:Monospace:size=8}Battery $alignr ${battery_percent} ${color darkgray}${battery_bar 11,100}${color yellow}
${endif}#
${hr 1}
${font Hack\ Nerd\ Font:Monospace:size=15} ${font Play:Monospace:bold:size=8}PROCESS${font Play:Monospace:size=8} ${alignr}PID   ${alignr} ${alignr}  MEM ${alignr} ${alignr}  CPU
${top name 1} ${alignr} ${top pid 1} ${alignr}${alignr} ${top mem 1} ${alignr}${alignr} ${top cpu 1}
${top name 2} ${alignr} ${top pid 2} ${alignr}${alignr} ${top mem 2} ${alignr}${alignr} ${top cpu 2}
${top name 3} ${alignr} ${top pid 3} ${alignr}${alignr} ${top mem 3} ${alignr}${alignr} ${top cpu 3}
${top name 4} ${alignr} ${top pid 4} ${alignr}${alignr} ${top mem 4} ${alignr}${alignr} ${top cpu 4}
${top name 5} ${alignr} ${top pid 5} ${alignr}${alignr} ${top mem 5} ${alignr}${alignr} ${top cpu 5}
${top name 6} ${alignr} ${top pid 6} ${alignr}${alignr} ${top mem 6} ${alignr}${alignr} ${top cpu 6}
${top name 7} ${alignr} ${top pid 7} ${alignr}${alignr} ${top mem 7} ${alignr}${alignr} ${top cpu 7}
${top name 8} ${alignr} ${top pid 8} ${alignr}${alignr} ${top mem 8} ${alignr}${alignr} ${top cpu 8}
${top name 9} ${alignr} ${top pid 9} ${alignr}${alignr} ${top mem 9} ${alignr}${alignr} ${top cpu 9}
${top name 10} ${alignr} ${top pid 10} ${alignr}${alignr} ${top mem 10} ${alignr}${alignr} ${top cpu 10}
${hr 1}
${font Hack\ Nerd\ Font:Monospace:size=15}󰩠 ${font Play:Monospace:bold:size=8}NETWORK${font Play:Monospace:size=8}
${if_existing /sys/class/net/wlp4s0/operstate up}#
 ESSID $alignr ${execi 1 nmcli -t -f name connection show --active}
 ${font Hack\ Nerd\ Font:Monospace:size=11}󰱓 ${font Play:Monospace:size=8}Local IP $alignr ${addr wlp4s0}
 ${font Hack\ Nerd\ Font:Monospace:size=11} ${font Play:Monospace:size=8}Public IP ${alignr}${execi 3600 curl  ipinfo.io/ip}
Signal $alignr ${execi 3 nmcli -t -f ACTIVE,SIGNAL dev wifi | grep sim | awk -F: '{print $2}'}% ${color darkgray}${execibar 1 11,100 nmcli -t -f ACTIVE,SIGNAL dev wifi | grep sim | awk -F: '{print $2}'}${color yellow}
 Bitrate $alignr ${execi 3 nmcli -t -f ACTIVE,RATE dev wifi | grep sim | awk -F: '{print $2}'}
 ${font Hack\ Nerd\ Font:Monospace:size=11} ${font Play:Monospace:size=8} Up $alignr ${upspeed wlp4s0}/s $alignr [${totalup wlp4s0}]
${upspeedgraph wlp4s0 35,295 b1b1b1 FF972E}
 ${font Hack\ Nerd\ Font:Monospace:size=11} ${font Play:Monospace:size=8}Down $alignr ${downspeed wlp4s0}/s $alignr [${totaldown wlp4s0}]
${downspeedgraph wlp4s0 35,295 b1b1b1 FF972E}
${else}#
${if_existing /sys/class/net/ens3/operstate up}#
 ${font Hack\ Nerd\ Font:Monospace:size=11}󰱓 ${font Play:Monospace:size=8}IP Local $alignr ${addr ens3}
${font Hack\ Nerd\ Font:Monospace:size=11} ${font Play:Monospace:size=8}Public IP ${alignr}${execi 3600 curl  ipinfo.io/ip}${voffset 5}
 ${font Hack\ Nerd\ Font:Monospace:size=11} ${font Play:Monospace:size=8}Up $alignr ${upspeed ens3} $alignr (${totalup ens3})
${upspeedgraph ens3 35,299 b1b1b1 FF972E}
 ${font Hack\ Nerd\ Font:Monospace:size=11} ${font Play:Monospace:size=8}Down $alignr ${downspeed ens3} $alignr (${totaldown ens3})
${downspeedgraph ens3 35,299 b1b1b1 FF972E}
${endif}#
${endif}#
${hr 1}
${font Hack\ Nerd\ Font:Monospace:size=15}󰴽 ${font Play:Monospace:bold:size=8}CONNECTIONS${font Play:Monospace:size=8} ${alignr} Port
${tcp_portmon 1 65535 rhost 0} ${alignr} ${tcp_portmon 1 65535 lport 0}
${tcp_portmon 1 65535 rhost 1} ${alignr} ${tcp_portmon 1 65535 lport 1}
${tcp_portmon 1 65535 rhost 2} ${alignr} ${tcp_portmon 1 65535 lport 2}
${tcp_portmon 1 65535 rhost 3} ${alignr} ${tcp_portmon 1 65535 lport 3}
${tcp_portmon 1 65535 rhost 4} ${alignr} ${tcp_portmon 1 65535 lport 4}
${tcp_portmon 1 65535 rhost 5} ${alignr} ${tcp_portmon 1 65535 lport 5}
${tcp_portmon 1 65535 rhost 6} ${alignr} ${tcp_portmon 1 65535 lport 6}
${tcp_portmon 1 65535 rhost 7} ${alignr} ${tcp_portmon 1 65535 lport 7}
${tcp_portmon 1 65535 rhost 8} ${alignr} ${tcp_portmon 1 65535 lport 8}
${tcp_portmon 1 65535 rhost 9} ${alignr} ${tcp_portmon 1 65535 lport 9}
${hr 1}]]
EOF

echo ">>> [customize-home] npm install global (prompt-sync, readline-sync, http-server)..."
# Global (não em $HOME) para não sujar a Área de trabalho com node_modules/
# package.json — o folder view do Plasma mostra o conteúdo de $HOME.
sudo npm i -g prompt-sync readline-sync http-server

echo ">>> [customize-home] LazyVim..."
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
    echo ">>> [customize-home] AVISO: 'nvim' não encontrado no PATH — pulando sync do LazyVim/Mason/Treesitter."
fi

echo ">>> [customize-home] kate-quickrun..."
KQ_URL=$(curl -fsSL https://api.github.com/repos/wyllianbs/kate-quickrun/releases/latest \
    | grep '"browser_download_url"' | grep '\.deb"' | head -1 | cut -d'"' -f4)
if [[ -n "$KQ_URL" ]]; then
    wget -c -O ~/kate-quickrun.deb "$KQ_URL"
    sudo dpkg -i ~/kate-quickrun.deb || sudo apt-get install -f -y
else
    echo ">>> [customize-home] AVISO: não encontrei o .deb do kate-quickrun na release mais recente — pulando."
fi

echo ">>> [customize-home] Limpando arquivos temporários..."
rm -rf ~/kate-quickrun.deb ~/LazyVim-Setup

echo ">>> [customize-home] Concluído."
