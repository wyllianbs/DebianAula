#!/bin/bash
#
# build-iso.sh — Automatiza a customização da ISO live Debian KDE (DebianAula)
#
# Uso:
#   bash build-iso.sh
#
# Requisitos:
#   - Rodar em um terminal com TTY real (não em background/cron) por causa
#     da pausa interativa (su - $LIVE_USER) no meio do script.
#   - Ter X server rodando e DISPLAY configurado (para dolphin/systemsettings).
#   - sudo configurado.
#
set -euo pipefail

WORKDIR="$(pwd)"
CONFIG_DIR="$WORKDIR/config"

# Script bilíngue (pt/en): detecta o idioma pelo $LANG/$LANGUAGE do sistema
# onde o build está rodando. Isso é só para as MENSAGENS do build-iso.sh
# (prompts, progresso) — completamente independente do idioma escolhido
# para a ISO gerada (ISO_LOCALE, perguntado mais abaixo). A sessão
# interativa do Xephyr usa ISO_LOCALE, não isto, pois deve refletir o
# idioma real do sistema final sendo construído.
LANG_PROBE="${LANG:-${LANGUAGE:-en}}"
if [[ "$LANG_PROBE" == pt* ]]; then
    LANG_MODE="pt"
else
    LANG_MODE="en"
fi

# msg "texto em pt" "text in en"  -> imprime com \n
msg() {
    if [[ "$LANG_MODE" == "pt" ]]; then printf '%s\n' "$1"; else printf '%s\n' "$2"; fi
}
# mp "texto em pt" "text in en"  -> imprime sem \n (para usar em read -rp)
mp() {
    if [[ "$LANG_MODE" == "pt" ]]; then printf '%s' "$1"; else printf '%s' "$2"; fi
}

msg ">>> Diretório de trabalho: $WORKDIR" ">>> Working directory: $WORKDIR"

# jq lê os arquivos de dados em config/ (pacotes, idiomas, versão da ISO
# base) usados logo abaixo, antes da etapa [2/8] que instala o resto das
# dependências do host — por isso é instalado aqui, cedo.
command -v jq >/dev/null || { msg ">>> Instalando jq (necessário para ler config/*.json)..." ">>> Installing jq (needed to read config/*.json)..."; sudo apt-get update -qq && sudo apt-get install -y jq; }

BASE_URL=$(jq -r '.debian_base_url' "$CONFIG_DIR/build.json")

read -rp "$(mp "Nome do usuário da ISO live [debian]: " "Live ISO username [debian]: ")" LIVE_USER
LIVE_USER="${LIVE_USER:-debian}"
msg ">>> Usuário: $LIVE_USER" ">>> User: $LIVE_USER"

read -rsp "$(mp "Senha para o usuário '$LIVE_USER' [e=mc2]: " "Password for user '$LIVE_USER' [e=mc2]: ")" LIVE_PASSWORD
echo
LIVE_PASSWORD="${LIVE_PASSWORD:-e=mc2}"

echo
msg "Este ISO será:" "This ISO will be:"
msg "  [1] Somente live (pendrive) — sem instalador, menor" "  [1] Live only (USB drive) — no installer, smaller"
msg "  [2] Live + instalador (Calamares) — dá para instalar no disco" "  [2] Live + installer (Calamares) — can be installed to disk"
read -rp "$(mp "Escolha [1]: " "Choose [1]: ")" ISO_MODE_CHOICE
if [[ "${ISO_MODE_CHOICE:-1}" == "2" ]]; then
    ISO_MODE="install"
else
    ISO_MODE="live"
fi
msg ">>> Modo: $ISO_MODE" ">>> Mode: $ISO_MODE"

# Default depende do modo, pra uma build "live + instalador" nunca ser
# confundida com uma "somente live" já existente no diretório — mas o
# usuário pode sobrescrever com qualquer nome.
if [[ "$ISO_MODE" == "install" ]]; then
    ISO_OUTPUT_DEFAULT="DebianAulaInstall.iso"
else
    ISO_OUTPUT_DEFAULT="DebianAula.iso"
fi
read -rp "$(mp "Nome do arquivo ISO gerado [$ISO_OUTPUT_DEFAULT]: " "Generated ISO filename [$ISO_OUTPUT_DEFAULT]: ")" ISO_OUTPUT
ISO_OUTPUT="${ISO_OUTPUT:-$ISO_OUTPUT_DEFAULT}"
[[ "$ISO_OUTPUT" == *.iso ]] || ISO_OUTPUT="${ISO_OUTPUT}.iso"
msg ">>> Arquivo de saída: $ISO_OUTPUT" ">>> Output file: $ISO_OUTPUT"

echo
msg "Idioma do sistema dentro da ISO gerada (menus, LibreOffice, etc)." "System language inside the generated ISO (menus, LibreOffice, etc)."
msg "Principais opções — digite o código:" "Main options — type the code:"
msg "  en_US — Inglês (padrão)" "  en_US — English (default)"
msg "  pt_BR — Português do Brasil" "  pt_BR — Brazilian Portuguese"
msg "  es_ES — Espanhol" "  es_ES — Spanish"
msg "  fr_FR — Francês" "  fr_FR — French"
msg "  de_DE — Alemão" "  de_DE — German"
msg "  it_IT — Italiano" "  it_IT — Italian"
read -rp "$(mp "Código [en_US]: " "Code [en_US]: ")" ISO_LOCALE_CHOICE
ISO_LOCALE_CHOICE="${ISO_LOCALE_CHOICE:-en_US}"

# LANG_KEY: chave canônica em config/languages.json — aceita os mesmos
# apelidos de sempre (es/es_ES, en/en_US, etc), só resolve pra chave.
case "${ISO_LOCALE_CHOICE,,}" in
    pt_br)    LANG_KEY="pt_BR" ;;
    es_es|es) LANG_KEY="es_ES" ;;
    fr_fr|fr) LANG_KEY="fr_FR" ;;
    de_de|de) LANG_KEY="de_DE" ;;
    it_it|it) LANG_KEY="it_IT" ;;
    en_us|en|*) LANG_KEY="en_US" ;;
esac

# Todo o resto (pacote de idioma, pacote do hunspell — alemão é exceção
# regional, hunspell-de-de —, manpages/task/mythes a preservar da purga
# geral, nome traduzido do ícone do Calamares, rótulo do menu de boot)
# vem de config/languages.json — uma fonte única em vez de vários case
# statements espalhados pelo script.
LANG_JSON="$CONFIG_DIR/languages.json"
ISO_LOCALE=$(jq -r ".\"$LANG_KEY\".locale" "$LANG_JSON")
ISO_LANGUAGE=$(jq -r ".\"$LANG_KEY\".language" "$LANG_JSON")
ISO_LANG_PKG=$(jq -r ".\"$LANG_KEY\".lang_pkg" "$LANG_JSON")
ISO_HUNSPELL_PKG=$(jq -r ".\"$LANG_KEY\".hunspell_pkg" "$LANG_JSON")
ISO_FIREFOX_LOCALE=$(jq -r ".\"$LANG_KEY\".firefox_locale" "$LANG_JSON")
DESKTOP_LANG=$(jq -r ".\"$LANG_KEY\".desktop_lang_code" "$LANG_JSON")
DESKTOP_NAME=$(jq -r ".\"$LANG_KEY\".calamares_name" "$LANG_JSON")
BOOT_ENTRY_LABEL=$(jq -r ".\"$LANG_KEY\".boot_label" "$LANG_JSON")
mapfile -t KEEP_LANG_PKGS < <(jq -r ".\"$LANG_KEY\".keep_from_purge[]" "$LANG_JSON")
msg ">>> Idioma da ISO: $ISO_LOCALE" ">>> ISO language: $ISO_LOCALE"

echo
msg "Layout de teclado do sistema (tela de login, TTY e sessão KDE)." "System keyboard layout (login screen, TTY, and KDE session)."
msg "Principais opções — digite o código:" "Main options — type the code:"
msg "  br — ABNT2 / Português do Brasil (padrão)" "  br — ABNT2 / Brazilian Portuguese (default)"
msg "  us — US Internacional" "  us — US International"
msg "  es — Espanhol" "  es — Spanish"
msg "  fr — Francês" "  fr — French"
msg "  de — Alemão" "  de — German"
msg "  it — Italiano" "  it — Italian"
read -rp "$(mp "Código [br]: " "Code [br]: ")" KEYBOARD_LAYOUT
KEYBOARD_LAYOUT="${KEYBOARD_LAYOUT:-br}"
KEYBOARD_LAYOUT="${KEYBOARD_LAYOUT,,}"
msg ">>> Teclado: $KEYBOARD_LAYOUT" ">>> Keyboard: $KEYBOARD_LAYOUT"

echo
msg "Fuso horário do sistema (formato IANA, ex: America/Sao_Paulo)." "System timezone (IANA format, e.g. America/Sao_Paulo)."
msg "Sugestões: America/Sao_Paulo (padrão), America/New_York, Europe/Lisbon," "Suggestions: America/Sao_Paulo (default), America/New_York, Europe/Lisbon,"
msg "            Europe/Madrid, Europe/Paris, Europe/Berlin, Europe/Rome, UTC" "            Europe/Madrid, Europe/Paris, Europe/Berlin, Europe/Rome, UTC"
read -rp "$(mp "Fuso [America/Sao_Paulo]: " "Timezone [America/Sao_Paulo]: ")" TIMEZONE
TIMEZONE="${TIMEZONE:-America/Sao_Paulo}"
if [[ ! -e "/usr/share/zoneinfo/$TIMEZONE" ]]; then
    msg ">>> AVISO: fuso '$TIMEZONE' não encontrado neste host — usando America/Sao_Paulo." ">>> WARNING: timezone '$TIMEZONE' not found on this host — falling back to America/Sao_Paulo."
    TIMEZONE="America/Sao_Paulo"
fi
msg ">>> Fuso horário: $TIMEZONE" ">>> Timezone: $TIMEZONE"

# ============================================================ #
# 0. VERIFICAÇÃO DE VERSÃO E ATUALIZAÇÃO COMPLETA (opcional)
# ============================================================ #
#
# Por padrão (config/build.json: "debian_iso_version": "latest"), o script
# reaproveita o ISO/squashfs-root já baixados/extraídos (mais rápido, só
# atualiza pacotes por cima) e checa se há uma versão mais nova. Definir
# uma versão fixa nesse arquivo (ex: "13.6.0") pula essa checagem remota
# inteira e sempre builda contra aquela ISO base específica.
DEBIAN_ISO_VERSION=$(jq -r '.debian_iso_version' "$CONFIG_DIR/build.json")

if [[ "$DEBIAN_ISO_VERSION" == "latest" ]]; then
    LOCAL_ISO=$(ls debian-live-*-amd64-kde.iso 2>/dev/null | sort -V | tail -n1 || true)

    msg ">>> Verificando se há uma versão mais recente do ISO..." ">>> Checking for a newer ISO version..."
    REMOTE_ISO=$(
        curl -fsSL --max-time 10 --retry 2 --retry-delay 2 "$BASE_URL/" 2>/dev/null |
        grep -oE 'debian-live-[0-9]+(\.[0-9]+)+-amd64-kde\.iso' |
        sort -V |
        tail -n1
    ) || true

    if [[ -z "$REMOTE_ISO" ]]; then
        msg "    Não foi possível verificar a versão remota agora (sem rede?)." "    Could not check the remote version right now (no network?)."
    elif [[ -z "$LOCAL_ISO" ]]; then
        msg "    Nenhuma ISO local encontrada. Versão mais recente disponível: $REMOTE_ISO" "    No local ISO found. Latest version available: $REMOTE_ISO"
    elif [[ "$REMOTE_ISO" != "$LOCAL_ISO" ]]; then
        msg "    >>> Nova versão disponível! Local: $LOCAL_ISO  |  Remota: $REMOTE_ISO" "    >>> New version available! Local: $LOCAL_ISO  |  Remote: $REMOTE_ISO"
    else
        msg "    ISO local já é a versão mais recente ($LOCAL_ISO)." "    Local ISO is already the latest version ($LOCAL_ISO)."
    fi
else
    PINNED_ISO="debian-live-${DEBIAN_ISO_VERSION}-amd64-kde.iso"
    LOCAL_ISO=""
    [[ -e "$PINNED_ISO" ]] && LOCAL_ISO="$PINNED_ISO"
    REMOTE_ISO="$PINNED_ISO"
    msg ">>> Versão da ISO base fixada em config/build.json: $DEBIAN_ISO_VERSION" ">>> Base ISO version pinned in config/build.json: $DEBIAN_ISO_VERSION"
    if [[ -n "$LOCAL_ISO" ]]; then
        msg "    Já presente localmente: $LOCAL_ISO" "    Already present locally: $LOCAL_ISO"
    else
        msg "    Ainda não baixada, será obtida na próxima etapa." "    Not downloaded yet, will be fetched in the next step."
    fi
fi

# Detecta se 'iso'/'squashfs-root' (se existirem) foram construídos num modo
# ISO_MODE diferente do escolhido agora (ex: eram "live-only" e agora é
# "install"). Reaproveitar entre modos diferentes não quebra o build — os
# pacotes do Calamares/instalador são instalados/purgados a cada execução —
# mas o purge do modo "live" não remove as dependências do instalador
# (grub-efi-amd64-bin, parted, etc.), então trocar para "live" reaproveitando
# um 'squashfs-root' que já foi "install" pode deixar a ISO com pacotes
# residuais (maior do que deveria).
MODE_MARKER="$WORKDIR/.debianaula-last-mode"
PREV_ISO_MODE=""
[[ -f "$MODE_MARKER" ]] && PREV_ISO_MODE="$(cat "$MODE_MARKER" 2>/dev/null || true)"
MODE_MISMATCH=""
if [[ -n "$PREV_ISO_MODE" && "$PREV_ISO_MODE" != "$ISO_MODE" && ( -d "squashfs-root" || -d "iso" ) ]]; then
    MODE_MISMATCH="1"
fi

FULL_UPDATE=""
if [[ -n "$MODE_MISMATCH" ]]; then
    echo
    msg "!!! AVISO: 'iso'/'squashfs-root' foram construídos no modo '$PREV_ISO_MODE', mas agora você escolheu '$ISO_MODE'." "!!! WARNING: 'iso'/'squashfs-root' were built in '$PREV_ISO_MODE' mode, but you chose '$ISO_MODE' this time."
    msg "    Reaproveitar assim não quebra o build, mas pode deixar pacotes do instalador residuais na ISO (maior do que precisa)." "    Reusing them like this won't break the build, but may leave leftover installer packages in the ISO (larger than it needs to be)."
    read -rp "$(mp "Apagar tudo e reconstruir do zero neste modo? [S/n]: " "Delete everything and rebuild from scratch in this mode? [Y/n]: ")" FULL_UPDATE
    FULL_UPDATE="${FULL_UPDATE:-s}"
elif [[ -d "squashfs-root" || -d "iso" ]]; then
    if [[ -n "$REMOTE_ISO" && -n "$LOCAL_ISO" && "$REMOTE_ISO" != "$LOCAL_ISO" ]]; then
        read -rp "$(mp "Há uma ISO base mais nova. Apagar tudo e reconstruir do zero? [s/N]: " "A newer base ISO is available. Delete everything and rebuild from scratch? [y/N]: ")" FULL_UPDATE
    else
        read -rp "$(mp "ISO base já é a mais recente. Ainda assim, apagar tudo e reconstruir do zero (perde as customizações já feitas)? [s/N]: " "Base ISO is already the latest. Still delete everything and rebuild from scratch (loses customizations already made)? [y/N]: ")" FULL_UPDATE
    fi
fi
FULL_UPDATE="${FULL_UPDATE,,}"

if [[ "$FULL_UPDATE" == "s" || "$FULL_UPDATE" == "sim" || "$FULL_UPDATE" == "y" || "$FULL_UPDATE" == "yes" ]]; then
    TO_REMOVE=()
    # Só remove a ISO base se ela estiver desatualizada — se já é a mais
    # recente, mantém o arquivo (evita rebaixar ~4GB à toa) e limpa apenas
    # a extração/customização (iso/squashfs-root) para reconstruir do zero.
    if [[ -n "$REMOTE_ISO" && -n "$LOCAL_ISO" && "$REMOTE_ISO" != "$LOCAL_ISO" ]]; then
        for item in debian-live-*-amd64-kde.iso; do
            [[ -e "$item" ]] && TO_REMOVE+=("$item")
        done
    fi
    for item in iso squashfs-root; do
        [[ -e "$item" ]] && TO_REMOVE+=("$item")
    done

    if [[ ${#TO_REMOVE[@]} -eq 0 ]]; then
        msg "    Nada para remover (ainda não há ISO/squashfs-root neste diretório)." "    Nothing to remove (no ISO/squashfs-root in this directory yet)."
    else
        echo
        msg "    Os itens abaixo serão APAGADOS permanentemente de $WORKDIR:" "    The items below will be PERMANENTLY DELETED from $WORKDIR:"
        for item in "${TO_REMOVE[@]}"; do
            sudo du -sh "$item" 2>/dev/null | sed 's/^/      - /' || true
        done
        echo
        read -rp "$(mp "    Confirma a remoção? [s/N]: " "    Confirm removal? [y/N]: ")" CONFIRM_RM
        CONFIRM_RM="${CONFIRM_RM,,}"

        if [[ "$CONFIRM_RM" == "s" || "$CONFIRM_RM" == "sim" || "$CONFIRM_RM" == "y" || "$CONFIRM_RM" == "yes" ]]; then
            for item in "${TO_REMOVE[@]}"; do
                msg "    Removendo $item ..." "    Removing $item ..."
                sudo rm -rf "$item"
            done
            msg "    Removido. Extração e customização serão refeitas do zero." "    Removed. Extraction and customization will be redone from scratch."
        else
            msg "    Atualização completa cancelada — mantendo arquivos existentes." "    Full update cancelled — keeping existing files."
        fi
    fi
fi

echo "$ISO_MODE" > "$MODE_MARKER"

# Checkpoint de progresso: grava, ao final de cada etapa 5/6/7 (as lentas —
# pacotes, LazyVim/kate-quickrun, finalização), o número da última etapa
# concluída. Se o build travar/for interrompido no meio e você rodar
# 'bash build-iso.sh' de novo, pergunta se quer continuar dali em vez de
# refazer 4-7 inteiro (que hoje sempre rodava de novo do zero, mesmo já
# tendo chegado longe -- daí a demora em cada nova tentativa).
PROGRESS_MARKER="$WORKDIR/.debianaula-build-progress"
RESUME_FROM=1
if [[ ! -d squashfs-root ]]; then
    # Sem squashfs-root não há o que continuar (foi removido acima, ou
    # nunca existiu) -- descarta qualquer marcador de progresso antigo.
    rm -f "$PROGRESS_MARKER"
elif [[ -f "$PROGRESS_MARKER" ]]; then
    LAST_STEP="$(cat "$PROGRESS_MARKER" 2>/dev/null || true)"
    if [[ "$LAST_STEP" =~ ^[0-9]+$ && "$LAST_STEP" -ge 1 && "$LAST_STEP" -lt 8 ]]; then
        NEXT_STEP=$((LAST_STEP + 1))
        echo
        msg "    A execução anterior parou logo após concluir a etapa [$LAST_STEP/8]." "    The previous run stopped right after finishing step [$LAST_STEP/8]."
        # Nunca deixa escolher além de $NEXT_STEP: pular à frente do que
        # realmente terminou (ex.: ir direto pro [8] com só o [5] feito)
        # deixaria etapas nunca executadas de fato para trás, gerando uma
        # ISO incompleta. Voltar pra uma etapa anterior (refazer 5 ou 6 de
        # novo, por exemplo) é sempre permitido.
        while true; do
            read -rp "$(mp "    Continuar a partir de qual etapa? [1-$NEXT_STEP, Enter = $NEXT_STEP]: " "    Resume from which step? [1-$NEXT_STEP, Enter = $NEXT_STEP]: ")" RESUME_ANSWER
            [[ -z "$RESUME_ANSWER" ]] && RESUME_ANSWER="$NEXT_STEP"
            if [[ "$RESUME_ANSWER" =~ ^[0-9]+$ && "$RESUME_ANSWER" -ge 1 && "$RESUME_ANSWER" -le "$NEXT_STEP" ]]; then
                RESUME_FROM="$RESUME_ANSWER"
                break
            fi
            msg "    Valor inválido — digite um número de 1 a $NEXT_STEP, ou Enter para $NEXT_STEP." "    Invalid value — enter a number from 1 to $NEXT_STEP, or Enter for $NEXT_STEP."
        done
        if [[ "$RESUME_FROM" -eq 1 ]]; then
            msg "    Refazendo a partir da etapa [1/8]." "    Redoing from step [1/8]."
        else
            msg "    Retomando a partir da etapa [$RESUME_FROM/8]." "    Resuming from step [$RESUME_FROM/8]."
        fi
    fi
fi

# ============================================================ #
# 1. DOWNLOAD DO ISO
# ============================================================ #

msg ">>> [1/8] Localizando ISO KDE mais recente..." ">>> [1/8] Locating the latest KDE ISO..."

if [[ "$DEBIAN_ISO_VERSION" == "latest" ]]; then
    ISO=$(ls debian-live-*-amd64-kde.iso 2>/dev/null | sort -V | tail -n1 || true)
else
    # Versão fixada: procura só o arquivo específico, nunca o "mais
    # recente" via glob (poderia pegar uma versão diferente já baixada).
    ISO=""
    [[ -e "$PINNED_ISO" ]] && ISO="$PINNED_ISO"
fi

if [[ -n "$ISO" ]]; then
    msg "    Usando ISO já presente localmente: $ISO" "    Using ISO already present locally: $ISO"
else
    if [[ "$DEBIAN_ISO_VERSION" == "latest" ]]; then
        # Reaproveita a verificação já feita na etapa 0; só refaz se falhou antes.
        if [[ -z "$REMOTE_ISO" ]]; then
            REMOTE_ISO=$(
                curl -fsSL --retry 3 --retry-delay 3 "$BASE_URL/" |
                grep -oE 'debian-live-[0-9]+(\.[0-9]+)+-amd64-kde\.iso' |
                sort -V |
                tail -n1
            ) || true
        fi
        ISO="$REMOTE_ISO"
    else
        ISO="$PINNED_ISO"
    fi

    if [[ -z "$ISO" ]]; then
        msg "Não foi possível localizar o ISO KDE (falha de rede?). Tente rodar de novo." "Could not locate the KDE ISO (network failure?). Try running again."
        exit 1
    fi

    msg "    ISO encontrado: $ISO" "    ISO found: $ISO"
    msg ">>> Baixando $ISO ..." ">>> Downloading $ISO ..."
    curl -fL --retry 3 --retry-delay 5 -O "$BASE_URL/$ISO"
fi

# ============================================================ #
# 2. DEPENDÊNCIAS NO HOST
# ============================================================ #

msg ">>> [2/8] Instalando dependências no host..." ">>> [2/8] Installing dependencies on the host..."

PKG_HOST=$(jq -r '.host_install[]' "$CONFIG_DIR/packages.json" | tr '\n' ' ')
sudo apt-get update
sudo apt-get install -y $PKG_HOST jq

# ============================================================ #
# 3. EXTRAÇÃO DO ISO E DO SQUASHFS
# ============================================================ #

msg ">>> [3/8] Extraindo ISO..." ">>> [3/8] Extracting ISO..."

if [[ -d iso ]]; then
    msg "    Diretório 'iso' já existe, pulando extração." "    'iso' directory already exists, skipping extraction."
else
    xorriso -osirrox on -indev "$ISO" -extract / iso
    chmod -R +w iso
fi

if [[ -d squashfs-root ]]; then
    msg "    'squashfs-root' já existe, pulando unsquashfs." "    'squashfs-root' already exists, skipping unsquashfs."
else
    mv iso/live/filesystem.squashfs .
    sudo unsquashfs filesystem.squashfs
    rm -f filesystem.squashfs
fi

# Aumenta o espaço do overlay no boot
sed -i 's/\(append.*quiet splash\)\(.*\)--/\1 overlay-size=50%\2--/' iso/isolinux/live.cfg || true

# ============================================================ #
# 4. PREPARA O CHROOT (HOST)
# ============================================================ #

msg ">>> [4/8] Preparando ambiente chroot..." ">>> [4/8] Preparing chroot environment..."

echo "exit 101" | sudo tee squashfs-root/usr/sbin/policy-rc.d > /dev/null
sudo chmod +x squashfs-root/usr/sbin/policy-rc.d

xhost +

# Desmonta em LOOP (não só uma vez) antes de montar -- se uma execução
# anterior morreu sem o 'trap cleanup' rodar (kill -9, reboot forçado,
# crash), pode ter sobrado uma montagem daquela vez. Um 'umount -l' comum
# só tira a camada do TOPO; se este passo montasse por cima sem checar
# antes, um 'umount' individual no fim do build revelaria a montagem
# velha por baixo -- ainda "montada" mesmo depois de "desmontada". No
# caso do /proc isso é grave: significa empacotar o /proc REAL do host
# (processos, memória) inteiro no squashfs, o que pode travar o
# mksquashfs (e a máquina) tentando ler arquivos de /proc que bloqueiam
# por natureza. mountpoint -q soma cada verificação até garantir que não
# sobrou nenhuma camada.
unmount_stack() {
    local path="$1"
    local tries=0
    while mountpoint -q "$path" 2>/dev/null && [[ "$tries" -lt 10 ]]; do
        sudo umount -lf "$path" 2>/dev/null || true
        tries=$((tries + 1))
    done
}
for m in sys/firmware/efi/efivars proc sys run dev/shm dev/pts dev; do
    unmount_stack "squashfs-root/$m"
done

# IMPORTANTE: nunca damos bind-mount no /sys, /dev ou /run REAIS do host
# aqui. Um chroot não isola PID/mount/D-Bus por padrão — um bind-mount
# desses diretórios tornaria a NVRAM UEFI real (squashfs-root/sys/firmware/
# efi/efivars), os discos reais (squashfs-root/dev/sda etc.) e o D-Bus/
# systemd real do host (squashfs-root/run) diretamente alcançáveis de
# dentro do chroot — o suficiente para um pacote como grub-efi/os-prober
# reconfigurar o boot real da máquina. Em vez disso, cada um recebe uma
# montagem isolada e mínima, sem nenhum vínculo com o host.
sudo mount --bind /proc squashfs-root/proc

sudo mount -t sysfs sysfs squashfs-root/sys

sudo mkdir -p squashfs-root/run
sudo mount -t tmpfs -o mode=0755 tmpfs squashfs-root/run

sudo mount -t tmpfs -o mode=0755 tmpfs squashfs-root/dev
sudo mknod -m 666 squashfs-root/dev/null    c 1 3
sudo mknod -m 666 squashfs-root/dev/zero    c 1 5
sudo mknod -m 666 squashfs-root/dev/full    c 1 7
sudo mknod -m 666 squashfs-root/dev/random  c 1 8
sudo mknod -m 666 squashfs-root/dev/urandom c 1 9
sudo mknod -m 666 squashfs-root/dev/tty     c 5 0
sudo mknod -m 600 squashfs-root/dev/console c 5 1
sudo mknod -m 666 squashfs-root/dev/ptmx    c 5 2
sudo mkdir -p squashfs-root/dev/pts
sudo mount -t devpts -o gid=5,mode=620 devpts squashfs-root/dev/pts
sudo mkdir -p squashfs-root/dev/shm
sudo mount -t tmpfs tmpfs squashfs-root/dev/shm

cleanup() {
    local exit_code=$?
    msg ">>> Desmontando binds (cleanup)..." ">>> Unmounting binds (cleanup)..."
    xhost - || true
    for m in sys/firmware/efi/efivars proc sys run dev/shm dev/pts dev; do
        unmount_stack "squashfs-root/$m"
    done

    if [[ "$exit_code" -ne 0 ]]; then
        local last_step=""
        [[ -f "$PROGRESS_MARKER" ]] && last_step="$(cat "$PROGRESS_MARKER" 2>/dev/null || true)"
        echo
        msg "!!! O script foi interrompido (código de saída: $exit_code) antes de terminar." "!!! The script was interrupted (exit code: $exit_code) before finishing."
        msg "!!! O diretório 'squashfs-root' ficou em estado INCOMPLETO — não é uma ISO" "!!! The 'squashfs-root' directory is in an INCOMPLETE state — it's not a"
        if [[ -n "$last_step" ]]; then
            msg "!!! corrompida, apenas um build que parou logo após concluir a etapa [$last_step/8]." "!!! corrupted ISO, just a build that stopped right after finishing step [$last_step/8]."
        else
            msg "!!! corrompida, apenas um build que não chegou até a Etapa 5/8." "!!! corrupted ISO, just a build that didn't reach Step 5/8."
        fi
        msg "!!! Rode 'bash build-iso.sh' de novo — ele vai perguntar se quer continuar" "!!! Run 'bash build-iso.sh' again — it will ask whether to resume from"
        msg "!!! dali em vez de refazer tudo (não precisa apagar squashfs-root/iso)." "!!! there instead of redoing everything (no need to delete squashfs-root/iso)."
        echo
    fi
}
trap cleanup EXIT INT TERM

# Popula /etc/skel com as customizações de usuário (Dolphin, Firefox,
# Konsole, Kate, painel/systray/relógio). Precisa rodar ANTES do adduser
# (etapa 5), para que o novo usuário já nasça com tudo aplicado.
LANG_MODE="$LANG_MODE" bash "$WORKDIR/customize-skel.sh" squashfs-root "$LIVE_USER" "$KEYBOARD_LAYOUT" "$ISO_LOCALE"

# Se o usuário live JÁ existe (build retomado via checkpoint, depois da
# etapa 5 já ter rodado numa tentativa anterior), o home dele só foi
# populado a partir do skel/ UMA VEZ, na criação da conta (adduser, lá na
# etapa 5) -- que fica pulada em builds retomados. Qualquer mudança em
# skel/ feita depois disso só chega em /etc/skel (linha acima, sempre
# reaplicada), nunca no home já criado. Reaplica skel/ direto no home do
# usuário live também, sempre que ele já existir, pra não ficar
# "congelado" numa versão antiga entre uma tentativa retomada e outra.
if sudo chroot squashfs-root getent passwd "$LIVE_USER" >/dev/null 2>&1; then
    msg "    Usuário live já existe (build retomado) — reaplicando skel/ no home dele também..." "    Live user already exists (resumed build) — reapplying skel/ to their home too..."
    sudo cp -a "$WORKDIR/skel"/. "squashfs-root/home/$LIVE_USER"/
    sudo grep -rlZ "ufsc" "squashfs-root/home/$LIVE_USER" 2>/dev/null | sudo xargs -0 -r sed -i "s/ufsc/$LIVE_USER/g" || true
    sudo chown -R "$LIVE_USER:$LIVE_USER" "squashfs-root/home/$LIVE_USER"
fi

# ============================================================ #
# 5. ETAPA ROOT DENTRO DO CHROOT (automática)
# ============================================================ #

if [[ "$RESUME_FROM" -gt 5 ]]; then
    msg ">>> [5/8] Já concluída numa execução anterior — pulando." ">>> [5/8] Already completed in a previous run — skipping."
else
msg ">>> [5/8] Rodando configuração de sistema (root) dentro do chroot..." ">>> [5/8] Running system configuration (root) inside chroot..."

# Se uma execução anterior foi interrompida no meio de um apt install, o dpkg
# pode ter ficado com pacotes "half-configured". Corrige antes de continuar.
sudo chroot squashfs-root dpkg --configure -a 2>/dev/null || true

# Listas de pacotes vêm de config/packages.json — lidas aqui no host (jq
# não precisa existir dentro do chroot) e passadas como strings separadas
# por espaço via env para o chroot abaixo. A purga de manpages/task/
# mythes/myspell de outras línguas já sai filtrada da língua escolhida
# (keep_from_purge, de languages.json); mesma lógica para o hunspell.
PKG_JSON="$CONFIG_DIR/packages.json"
PKG_ALWAYS=$(jq -r '.install.always[]' "$PKG_JSON" | tr '\n' ' ')
PKG_INSTALL_MODE_ONLY=$(jq -r '.install.install_mode_only[]' "$PKG_JSON" | tr '\n' ' ')
PKG_KERNEL_LIQUORIX=$(jq -r '.install.kernel_liquorix[]' "$PKG_JSON" | tr '\n' ' ')
PURGE_ALWAYS=$(jq -r '.purge.always[]' "$PKG_JSON" | tr '\n' ' ')
PURGE_ALWAYS_WILDCARDS=$(jq -r '.purge.always_wildcards[]' "$PKG_JSON" | tr '\n' ' ')
PURGE_LIVE_MODE_ONLY=$(jq -r '.purge.live_mode_only[]' "$PKG_JSON" | tr '\n' ' ')
PURGE_KERNEL_DEFAULT_WILDCARDS=$(jq -r '.purge.kernel_default_wildcards[]' "$PKG_JSON" | tr '\n' ' ')
PURGE_MISC=$(jq -r '.purge.misc[]' "$PKG_JSON" | tr '\n' ' ')

mapfile -t PURGE_OTHER_LANGS_ALL < <(jq -r '.purge.other_language_manpages_task_mythes_myspell[]' "$PKG_JSON")
PURGE_OTHER_LANGS=()
for pkg in "${PURGE_OTHER_LANGS_ALL[@]}"; do
    keep=0
    for k in "${KEEP_LANG_PKGS[@]}"; do [[ "$pkg" == "$k" ]] && keep=1; done
    [[ "$keep" -eq 0 ]] && PURGE_OTHER_LANGS+=("$pkg")
done
PURGE_OTHER_LANGS_STR="${PURGE_OTHER_LANGS[*]:-}"

mapfile -t HUNSPELL_OTHER_ALL < <(jq -r '.purge.hunspell_other_languages[]' "$PKG_JSON")
HUNSPELL_OTHER=()
for pkg in "${HUNSPELL_OTHER_ALL[@]}"; do
    [[ "$pkg" == "hunspell-$ISO_HUNSPELL_PKG" ]] || HUNSPELL_OTHER+=("$pkg")
done
HUNSPELL_OTHER_STR="${HUNSPELL_OTHER[*]:-}"

# Arquivos estáticos de config/ (policies.json do Firefox, sddm.conf,
# sources.list, init script de limpeza do 1G.raw) copiados pro
# squashfs-root/tmp antes do chroot, já que ele não enxerga $CONFIG_DIR
# (raiz de arquivos diferente) — lidos de /tmp de dentro do chroot abaixo.
# Firefox só troca de idioma sozinho de forma confiável quando forçado via
# política: intl.locale.requested manda usar o langpack instalado em vez de
# depender da autodetecção do binário (que na prática falhou pro usuário
# criado pelo Calamares, mesmo com locale e langpack corretos no sistema).
if [[ -n "$ISO_FIREFOX_LOCALE" ]]; then
    jq --arg locale "$ISO_FIREFOX_LOCALE" \
        '.policies.Preferences["intl.locale.requested"] = {"Value": $locale, "Status": "locked"}' \
        "$CONFIG_DIR/firefox-policies.json" | sudo tee squashfs-root/tmp/firefox-policies.json >/dev/null
else
    sudo cp "$CONFIG_DIR/firefox-policies.json" squashfs-root/tmp/firefox-policies.json
fi
sudo cp "$CONFIG_DIR/system/sddm.conf.tmpl" squashfs-root/tmp/sddm.conf
sudo cp "$CONFIG_DIR/system/apt-sources.list.tmpl" squashfs-root/tmp/apt-sources.list
sudo cp "$CONFIG_DIR/system/cleaning.init.tmpl" squashfs-root/tmp/cleaning.init

sudo chroot squashfs-root /usr/bin/env LIVE_USER="$LIVE_USER" LIVE_PASSWORD="$LIVE_PASSWORD" ISO_MODE="$ISO_MODE" LANG_MODE="$LANG_MODE" ISO_LOCALE="$ISO_LOCALE" ISO_LANGUAGE="$ISO_LANGUAGE" ISO_LANG_PKG="$ISO_LANG_PKG" ISO_HUNSPELL_PKG="$ISO_HUNSPELL_PKG" KEYBOARD_LAYOUT="$KEYBOARD_LAYOUT" DESKTOP_LANG="$DESKTOP_LANG" DESKTOP_NAME="$DESKTOP_NAME" PKG_ALWAYS="$PKG_ALWAYS" PKG_INSTALL_MODE_ONLY="$PKG_INSTALL_MODE_ONLY" PKG_KERNEL_LIQUORIX="$PKG_KERNEL_LIQUORIX" PURGE_ALWAYS="$PURGE_ALWAYS" PURGE_ALWAYS_WILDCARDS="$PURGE_ALWAYS_WILDCARDS" PURGE_LIVE_MODE_ONLY="$PURGE_LIVE_MODE_ONLY" PURGE_KERNEL_DEFAULT_WILDCARDS="$PURGE_KERNEL_DEFAULT_WILDCARDS" PURGE_MISC="$PURGE_MISC" PURGE_OTHER_LANGS_STR="$PURGE_OTHER_LANGS_STR" HUNSPELL_OTHER_STR="$HUNSPELL_OTHER_STR" /bin/bash -s <<'CHROOT_ROOT_SETUP'
set -euo pipefail
export HOME=/root
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C.UTF-8
export LANGUAGE=C.UTF-8
unset LANG

msg() {
    if [[ "$LANG_MODE" == "pt" ]]; then printf '%s\n' "$1"; else printf '%s\n' "$2"; fi
}

echo 'nameserver 8.8.8.8' > /etc/resolv.conf
rm -f /etc/network/interfaces
cp /tmp/sddm.conf /etc/sddm.conf
rm -f /tmp/sddm.conf

mkdir -p /var/lib/sddm
cat > /var/lib/sddm/state.conf << EOF
[Last]
User=$LIVE_USER
EOF
chown -R sddm:sddm /var/lib/sddm 2>/dev/null || true

dbus-uuidgen > /var/lib/dbus/machine-id
dpkg-divert --local --rename --add /sbin/initctl
ln -sf /bin/true /sbin/initctl

# Segunda camada de proteção (além do /sys isolado acima): mesmo que os
# pacotes grub-efi-amd64-bin/grub-pc-bin/os-prober sejam instalados (modo
# "install"), seus binários nunca devem rodar de verdade dentro do chroot —
# o bootloader da ISO final é montado à parte, via heredoc mais abaixo.
for bin in /usr/sbin/grub-install /usr/sbin/grub-mkconfig /usr/sbin/update-grub /usr/bin/os-prober; do
    dpkg-divert --local --rename --add "$bin" 2>/dev/null || true
    ln -sf /bin/true "$bin"
done

cp /tmp/apt-sources.list /etc/apt/sources.list
rm -f /tmp/apt-sources.list

apt-get update
apt-get upgrade -y

# Pacotes vêm de config/packages.json, já resolvidos no host (PKG_*/
# PURGE_*, passados via env). "set -f" evita que o bash tente expandir os
# curingas ('aspell*' etc, usados pelo apt-get pro próprio matching
# interno, não pelo shell) como glob de arquivos locais.
set -f
apt-get install -y $PKG_ALWAYS

# Manpages/task-metapackage/mythes/myspell/hunspell de OUTRAS línguas são
# sempre purgados (bloat de documentação, não afeta o idioma da interface),
# EXCETO os da língua escolhida da ISO (já filtrados no host, via
# keep_from_purge em config/languages.json — inglês nunca aparece nessas
# listas, então já fica de fora naturalmente/fallback garantido).
apt-get purge -y $PURGE_ALWAYS $PURGE_ALWAYS_WILDCARDS $PURGE_OTHER_LANGS_STR || true

# Mesma lógica para os hunspell de outras línguas com purge dedicada
# (hunspell-$ISO_HUNSPELL_PKG é reinstalado explicitamente logo abaixo de
# qualquer forma, mas evita a purga-e-reinstala desnecessária aqui).
apt-get purge -y $HUNSPELL_OTHER_STR $PURGE_MISC || true
set +f

apt-get install -y hunspell aspell libreoffice wget

# Pacotes de idioma (corretor ortográfico, hifenização, ajuda do LibreOffice)
# para o idioma escolhido da ISO. Vazio para en_US (já vem em inglês).
# Best-effort: em alguns idiomas nem todo pacote existe no repositório
# (ex: hyphen-<lang> ou libreoffice-help-<lang>), por isso o "|| true".
# hunspell usa ISO_HUNSPELL_PKG (não ISO_LANG_PKG): alemão é hunspell-de-de,
# não hunspell-de como os demais pacotes de idioma.
if [[ -n "$ISO_LANG_PKG" ]]; then
    apt-get install -y \
        "hunspell-$ISO_HUNSPELL_PKG" "aspell-$ISO_LANG_PKG" \
        "libreoffice-l10n-$ISO_LANG_PKG" "libreoffice-help-$ISO_LANG_PKG" \
        "hyphen-$ISO_LANG_PKG" || true
fi

# Instalador (Calamares) — só entra na ISO se o modo "live + instalador" foi
# escolhido no início do script. No modo "somente live" ele é removido.
if [[ "$ISO_MODE" == "install" ]]; then
    set -f
    apt-get install -y $PKG_INSTALL_MODE_ONLY
    set +f

    # calamares-settings-debian não traduz o ícone "Install Debian" para
    # vários idiomas. Best-effort: acha qualquer .desktop com esse Name=
    # fixo e injeta/atualiza a tradução Name[<código>] para a língua da
    # ISO. en_US não precisa (já é o texto padrão). DESKTOP_LANG/
    # DESKTOP_NAME vêm de config/languages.json, resolvidos no host e
    # passados via env (ver invocação do chroot acima).
    if [[ -n "$DESKTOP_LANG" ]]; then
        for f in $(grep -rl '^Name=Install Debian' /usr/share/applications /etc/skel/Desktop 2>/dev/null); do
            if grep -q "^Name\[$DESKTOP_LANG\]=" "$f"; then
                sed -i "s/^Name\[$DESKTOP_LANG\]=.*/Name[$DESKTOP_LANG]=$DESKTOP_NAME/" "$f"
            else
                sed -i "/^Name=Install Debian/a Name[$DESKTOP_LANG]=$DESKTOP_NAME" "$f"
            fi
        done
    fi

    # A instalação reaproveita o próprio usuário live (já dentro do
    # squashfs clonado pelo Calamares) em vez de criar um usuário novo --
    # elimina de vez a classe inteira de bug de "usuário novo herdando
    # caminho/config do usuário antigo" (Dolphin, conky etc.), ao custo de
    # não poder escolher nome de usuário na instalação (senha continua a
    # mesma definida em LIVE_PASSWORD neste build). Pra isso, remove a
    # etapa "users" tanto da sequência 'show' (UI) quanto 'exec' (jobs) do
    # settings.conf -- sem ela, o Calamares nunca tenta criar outra conta,
    # então também não precisa mais do módulo "removeuser".
    if grep -q "^  - users$" /etc/calamares/settings.conf; then
        sed -i '/^  - users$/d' /etc/calamares/settings.conf
    fi
else
    apt-get purge -y $PURGE_LIVE_MODE_ONLY || true
fi

# Blindagem contra autoremove: tudo que está instalado neste ponto (nosso
# app set curado) passa a contar como "instalado manualmente" no dpkg,
# mesmo que tenha entrado como dependência de algum live-task-*/pacote
# base. Sem isso, um "apt-get autoremove" mais tarde — inclusive o que o
# Calamares roda por conta própria, no job "packages", depois de purgar
# live-boot/live-task-* durante uma instalação real — pode levar junto
# pacotes nossos (ex: conky, konsole) que só nunca foram marcados como
# manuais explicitamente. É só metadado do dpkg, não reinstala nem muda
# nada agora; só evita que sumam depois de um autoremove futuro.
apt-mark manual $(dpkg-query -W -f='${Package}\n' | tr '\n' ' ') > /dev/null 2>&1 || true

apt-get upgrade -y
apt-get autoremove -y

apt-get install -y locales
sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i "s/^# *${ISO_LOCALE} UTF-8/${ISO_LOCALE} UTF-8/" /etc/locale.gen
locale-gen

cat > /etc/default/locale << EOF
LANG=$ISO_LOCALE
LANGUAGE=$ISO_LANGUAGE
EOF

# Layout de teclado escolhido pelo usuário (padrão: ABNT2/br) a nível de
# sistema — afeta a tela de login do SDDM e qualquer TTY, não só a sessão
# do KDE (que já pega o layout via kxkbrc no skel, ajustado à parte).
cat > /etc/default/keyboard << EOF
XKBMODEL="pc105"
XKBLAYOUT="$KEYBOARD_LAYOUT"
XKBVARIANT=""
XKBOPTIONS=""

BACKSPACE="guess"
EOF
dpkg-reconfigure -f noninteractive keyboard-configuration 2>/dev/null || true

# Firefox mais recente (repo Mozilla)
apt-get install -y extrepo

# Libera repositórios non-free no extrepo (necessário para o repo do VS Code)
if ! grep -qE '^\s*-\s*non-free\s*$' /etc/extrepo/config.yaml 2>/dev/null; then
    sed -i '/^enabled_policies:/a - non-free' /etc/extrepo/config.yaml
fi

extrepo enable mozilla
apt-get update
apt-get install -y firefox
if [[ -n "$ISO_LANG_PKG" ]]; then
    apt-get install -y "firefox-l10n-$ISO_LANG_PKG" || true
fi

# Extensões padrão via policy (não copiamos o perfil do Firefox pro skel:
# teria histórico, cookies e senhas junto — policies.json instala as
# extensões limpo, direto do addons.mozilla.org, sem carregar dado pessoal).
# Conteúdo vem de config/firefox-policies.json (host), copiado pro /tmp
# do chroot antes desta etapa.
mkdir -p /etc/firefox
cp /tmp/firefox-policies.json /etc/firefox/policies.json

# Este Firefox (instalado direto em /usr/lib/firefox pelo repo Mozilla) lê
# políticas do diretório de distribuição da própria instalação — não confia
# só em /etc/firefox/policies.json. Grava nos dois lugares por garantia.
mkdir -p /usr/lib/firefox/distribution
cp /etc/firefox/policies.json /usr/lib/firefox/distribution/policies.json
rm -f /tmp/firefox-policies.json

apt-get purge -y im-config || true

# Bluetooth desativado por padrão. SYSTEMD_OFFLINE=1 força o systemctl a
# só mexer nos symlinks dentro do chroot, sem tentar falar com o systemd
# real do host (mesmo com /run isolado acima, essa é uma segunda camada).
SYSTEMD_OFFLINE=1 systemctl disable bluetooth.service 2>/dev/null || true
SYSTEMD_OFFLINE=1 systemctl mask bluetooth.service 2>/dev/null || true

# VS Code (repo Microsoft via extrepo)
extrepo enable vscode
apt-get update
apt-get install -y code

# Kernel liquorix
extrepo enable liquorix
apt-get update
set -f
apt-get install -y $PKG_KERNEL_LIQUORIX
apt-get purge -y $PURGE_KERNEL_DEFAULT_WILDCARDS || true
set +f
apt-get autoremove --purge -y
apt-get update

# Desabilita apache, caso tenha sido instalado como dependência
rm -f /etc/init.d/apache*
SYSTEMD_OFFLINE=1 systemctl disable apache2 2>/dev/null || true
update-rc.d apache2 disable 2>/dev/null || true
update-rc.d -f apache remove 2>/dev/null || true
update-rc.d -f apache2 remove 2>/dev/null || true

# Usuário live
if ! id "$LIVE_USER" &>/dev/null; then
    adduser --disabled-password --gecos "" "$LIVE_USER"
    echo "$LIVE_USER:$LIVE_PASSWORD" | chpasswd
fi
usermod -aG sudo "$LIVE_USER"
usermod -aG audio,video,render,plugdev,netdev "$LIVE_USER"

cd "/home/$LIVE_USER"
dd if=/dev/urandom of="/home/$LIVE_USER/1G.raw" bs=1G count=1
chown "$LIVE_USER:$LIVE_USER" "/home/$LIVE_USER/1G.raw"

# Template já vem com $1 literal (arquivo comum, não passa por expansão
# de heredoc) — só o placeholder __LIVE_USER__ é substituído.
sed "s#__LIVE_USER__#$LIVE_USER#g" /tmp/cleaning.init > /etc/init.d/cleaning.sh
rm -f /tmp/cleaning.init
chmod +x /etc/init.d/cleaning.sh
update-rc.d cleaning.sh defaults

echo "$LIVE_USER ALL=(ALL:ALL) NOPASSWD: ALL" | tee "/etc/sudoers.d/$LIVE_USER" > /dev/null
chmod 440 "/etc/sudoers.d/$LIVE_USER"
visudo -cf /etc/sudoers

# Não usamos o comando 'hostname' aqui: chroot não isola o namespace UTS,
# então ele mudaria o hostname do HOST real, não só da imagem.
# Gravar /etc/hostname e /etc/hosts é suficiente — o live-boot aplica isso
# ao iniciar a ISO.
echo "DebianAula" > /etc/hostname
grep -q '127.0.0.1.*DebianAula' /etc/hosts || echo '127.0.0.1 DebianAula' >> /etc/hosts

# Remove a tela de boas-vindas do Plasma
# (rm do .desktop não bastava: o kded_plasma-welcome.so ainda disparava a
# tela no primeiro login independente do lançador existir)
apt-get purge -y plasma-welcome

# Adiciona Konsole, Kate e nvim-qt aos Favoritos do menu (kickoff).
# Editamos o default do próprio applet (em vez de um appletsrc por usuário)
# porque os IDs de containment/applet do painel só existem após o primeiro
# login, o que tornaria um override por usuário frágil.
sed -i 's|<default>preferred://browser,org.kde.kontact.desktop,systemsettings.desktop,org.kde.dolphin.desktop,org.kde.discover.desktop</default>|<default>preferred://browser,org.kde.dolphin.desktop,org.kde.konsole.desktop,org.kde.kate.desktop,nvim-qt.desktop,org.thonny.Thonny.desktop,systemsettings.desktop,org.kde.discover.desktop</default>|' \
    /usr/share/plasma/plasmoids/org.kde.plasma.kickoff/contents/config/main.xml

# Fixa o Konsole como launcher na barra de tarefas (Icons-Only Task Manager)
# do painel padrão. O layout.js do plasma-desktop-data não define nenhum
# "launchers" por padrão (os ícones que aparecem ali são só janelas abertas
# no momento, ex.: o notificador do Discover), então fixamos explicitamente
# só o Konsole — assim o Discover nunca aparece fixado.
PANEL_LAYOUT=/usr/share/plasma/layout-templates/org.kde.plasma.desktop.defaultPanel/contents/layout.js
sed -i 's|panel.addWidget("org.kde.plasma.icontasks")|var taskManager = panel.addWidget("org.kde.plasma.icontasks")\ntaskManager.currentConfigGroup = ["General"]\ntaskManager.writeConfig("launchers", ["applications:org.kde.konsole.desktop"])|' \
    "$PANEL_LAYOUT"

# Relógio digital: mostrar segundos sempre e data no formato longo
# (equivalente ao que se configura manualmente em "Definições do relógio
# digital" > Aparência).
sed -i 's|panel.addWidget("org.kde.plasma.digitalclock")|var clock = panel.addWidget("org.kde.plasma.digitalclock")\nclock.currentConfigGroup = ["Appearance"]\nclock.writeConfig("showSeconds", "Always")\nclock.writeConfig("showDate", true)\nclock.writeConfig("dateFormat", "longDate")|' \
    "$PANEL_LAYOUT"

msg ">>> Etapa root concluída." ">>> Root step completed."
CHROOT_ROOT_SETUP
echo "5" > "$PROGRESS_MARKER"
fi # RESUME_FROM -gt 5

# ============================================================ #
# 6. ETAPA INTERATIVA (usuário live, ambiente gráfico)
# ============================================================ #

if [[ "$RESUME_FROM" -gt 6 ]]; then
    msg ">>> [6/8] Já concluída numa execução anterior — pulando." ">>> [6/8] Already completed in a previous run — skipping."
else
echo
msg ">>> [6/8] Customizando o home de '$LIVE_USER' (automático: conky, LazyVim, kate-quickrun, etc)..." ">>> [6/8] Customizing the home directory of '$LIVE_USER' (automatic: conky, LazyVim, kate-quickrun, etc)..."
sudo cp "$WORKDIR/customize-home.sh" squashfs-root/tmp/customize-home.sh
sudo chmod +x squashfs-root/tmp/customize-home.sh
sudo chroot squashfs-root su - "$LIVE_USER" -c "LANG_MODE=$LANG_MODE bash /tmp/customize-home.sh"
sudo rm -f squashfs-root/tmp/customize-home.sh

echo
msg ">>> Entrando no ambiente do usuário '$LIVE_USER' (interativo)." ">>> Entering '$LIVE_USER' user environment (interactive)."
msg "    - Um X aninhado (Xephyr, display :2) vai abrir numa janela na sua" "    - A nested X server (Xephyr, display :2) will open in a window on"
msg "      tela, isolado da sua sessão Plasma real (:1). Dentro dele sobe a" "      your screen, isolated from your real Plasma session (:1). Inside it"
msg "      sessão completa do Plasma (startplasma-x11: kwin, painel, etc)." "      the full Plasma session comes up (startplasma-x11: kwin, panel, etc)."
msg "    - Faça suas customizações (dolphin, systemsettings, etc) DENTRO" "    - Make your customizations (dolphin, systemsettings, etc) INSIDE"
msg "      dessa janela Xephyr." "      that Xephyr window."
msg "    - Quando terminar, volte pra ESTE terminal (não a janela do Xephyr)" "    - When done, come back to THIS terminal (not the Xephyr window)"
msg "      e digite 'exit' (ou Ctrl+D) aqui para o script continuar. Fechar" "      and type 'exit' (or Ctrl+D) here for the script to continue. Just"
msg "      só a janela do Xephyr, ou deslogar de dentro do Plasma, NÃO é" "      closing the Xephyr window, or logging out from inside Plasma, is"
msg "      suficiente — este terminal fica esperando o 'exit' mesmo assim." "      NOT enough — this terminal keeps waiting for 'exit' regardless."
echo
read -rp "$(mp "Pressione ENTER para abrir o ambiente interativo do $LIVE_USER..." "Press ENTER to open the interactive environment for $LIVE_USER...")" _

command -v Xephyr >/dev/null || { msg "ERRO: Xephyr não instalado. Rode: sudo apt-get install -y xserver-xephyr" "ERROR: Xephyr not installed. Run: sudo apt-get install -y xserver-xephyr"; exit 1; }

# Só reseta a config do painel se ela estiver realmente quebrada (sem o
# Task Manager configurado — sintoma do bug de quando essa etapa rodava
# plasmashell sem kwin). Em builds seguintes, se o painel já está OK,
# preserva tudo (favoritos, systray, etc.) que você configurou à mão.
APPLETSRC="squashfs-root/home/$LIVE_USER/.config/plasma-org.kde.plasma.desktop-appletsrc"
if [[ ! -f "$APPLETSRC" ]] || ! sudo grep -q "org.kde.plasma.icontasks" "$APPLETSRC"; then
    msg "    (painel ausente/incompleto na config do $LIVE_USER — resetando para reconstruir do template padrão)" "    (panel missing/incomplete in $LIVE_USER's config — resetting to rebuild from the default template)"
    sudo rm -rf "$APPLETSRC" \
                "squashfs-root/home/$LIVE_USER/.config/plasmashellrc" \
                "squashfs-root/home/$LIVE_USER/.cache/plasmashell" \
                "squashfs-root/home/$LIVE_USER"/.cache/plasma_theme_*.kcache
fi

Xephyr :2 -screen 1280x800 -resizeable -ac >/tmp/xephyr.log 2>&1 &
XEPHYR_PID=$!
sleep 1

sudo chroot squashfs-root su - "$LIVE_USER" -c "export DISPLAY=:2; export LIBGL_ALWAYS_SOFTWARE=1; nohup startplasma-x11 >/tmp/plasma-session.log 2>&1 & echo \$! > /tmp/plasma-session.pid; bash; kill \$(cat /tmp/plasma-session.pid) 2>/dev/null; rm -f /tmp/plasma-session.pid /tmp/plasma-session.log"

kill "$XEPHYR_PID" 2>/dev/null || true

msg ">>> Ambiente interativo encerrado. Retomando automação..." ">>> Interactive environment closed. Resuming automation..."

# Apps com diálogo de arquivo (Dolphin, VS Code, etc) podem deixar o
# xdg-document-portal montado via FUSE em ~/.cache/doc — precisa desmontar
# antes de qualquer chown/rm, senão a operação falha com "Permissão negada".
sudo umount -l "squashfs-root/home/$LIVE_USER/.cache/doc" 2>/dev/null || true

sudo chroot squashfs-root chown -R "$LIVE_USER:$LIVE_USER" "/home/$LIVE_USER" || true

# Só no modo "install": espelha a home do usuário live inteira (já com
# tudo que o customize-home.sh gerou automaticamente E qualquer ajuste
# manual feito na sessão Xephyr acima) para /etc/skel — assim o usuário
# que o Calamares cria na instalação herda tudo, não só o que já estava
# em skel/ no repositório. Isso NÃO altera o skel/ do repositório (Git);
# é só a cópia dentro desta build (squashfs-root/etc/skel), refeita do
# zero a cada vez. Exclui coisas específicas da sessão live que não fazem
# sentido levar para um usuário novo: o placeholder de espaço em disco
# (1G.raw), o perfil do Firefox (o projeto propositalmente não envia
# perfil pronto — ver policies.json — copiar aqui vazaria histórico/
# cookies/senhas da sessão de build), histórico de shell, caches e lixo
# de sessão, e o user-places.xbel do KDE (gerado pela sessão live com o
# caminho /home/$LIVE_USER deste build gravado dentro -- herdar isso faria
# o Dolphin de outro usuário abrir num /home/<nome-antigo> inexistente; o
# KDE recria esse arquivo sozinho, corretamente, no primeiro login).
if [[ "$ISO_MODE" == "install" ]]; then
    msg "    Espelhando a home do usuário live inteira para /etc/skel (usuário criado na instalação)..." "    Mirroring the whole live user's home into /etc/skel (the user created at install time)..."
    sudo rm -rf squashfs-root/etc/skel
    sudo mkdir -p squashfs-root/etc/skel
    ( cd "squashfs-root/home/$LIVE_USER" && sudo tar \
        --exclude='./1G.raw' \
        --exclude='./.mozilla' \
        --exclude='./.config/mozilla' \
        --exclude='./.cache' \
        --exclude='./.bash_history' \
        --exclude='./.Xauthority' \
        --exclude='./.ICEauthority' \
        --exclude='./.local/share/Trash' \
        --exclude='./.local/share/sddm' \
        --exclude='./.local/share/user-places.xbel' \
        -cf - . | sudo tar -xf - -C ../../etc/skel )
    sudo chown -R root:root squashfs-root/etc/skel

    # Marcador lido por skel/.local/bin/debianaula-fix-paths.sh (rodado via
    # autostart no primeiro login de QUALQUER usuário criado neste sistema
    # -- o do Calamares e também os que vierem a ser criados depois, já
    # que /etc/skel é a fonte do useradd/adduser pra qualquer conta nova):
    # se algum arquivo escapou do espelho acima com /home/$LIVE_USER
    # gravado dentro, o script corrige sozinho no primeiro login, sem
    # depender de a gente prever cada caso em build-iso.sh.
    echo "$LIVE_USER" | sudo tee squashfs-root/etc/skel/.debianaula-live-user >/dev/null
    sudo chown root:root squashfs-root/etc/skel/.debianaula-live-user

    # Rede de segurança: o espelho acima copia QUALQUER arquivo do home da
    # sessão live, e não há como prever de antemão todo app do KDE que
    # grava caminho absoluto num cache/histórico (já pegamos o
    # user-places.xbel do Dolphin dessa forma). Em vez de só descobrir o
    # próximo caso numa instalação real, avisa aqui, cedo, com o(s)
    # arquivo(s) exato(s) -- não falha o build (pode ser inofensivo, ex.
    # histórico "recentemente usado"), só chama atenção pra revisar.
    LEFTOVER_PATH_FILES=$(sudo grep -rlZ "/home/$LIVE_USER" squashfs-root/etc/skel 2>/dev/null | tr '\0' '\n' || true)
    if [[ -n "$LEFTOVER_PATH_FILES" ]]; then
        msg "!!! AVISO: arquivo(s) em /etc/skel ainda referenciam /home/$LIVE_USER" "!!! WARNING: file(s) in /etc/skel still reference /home/$LIVE_USER"
        echo "$LEFTOVER_PATH_FILES" | sed 's/^/!!!   - /'
        msg "!!! (caminho do usuário live deste build). Um usuário criado pelo" "!!! (this build's live username). A user created by Calamares with a"
        msg "!!! Calamares com outro nome pode ter problemas com esse(s)" "!!! different name may have issues with that/those file(s) -- consider"
        msg "!!! arquivo(s) -- considere excluí-lo(s) do espelho acima." "!!! excluding it/them from the mirror above."
    fi
fi
echo "6" > "$PROGRESS_MARKER"
fi # RESUME_FROM -gt 6

# ============================================================ #
# 7. ETAPA ROOT FINAL DENTRO DO CHROOT (automática)
# ============================================================ #

if [[ "$RESUME_FROM" -gt 7 ]]; then
    msg ">>> [7/8] Já concluída numa execução anterior — pulando." ">>> [7/8] Already completed in a previous run — skipping."
else
msg ">>> [7/8] Rodando finalização (root) dentro do chroot..." ">>> [7/8] Running finalization (root) inside chroot..."

sudo cp "$CONFIG_DIR/system/timezone.init.tmpl" squashfs-root/tmp/timezone.init

sudo chroot squashfs-root /usr/bin/env LIVE_USER="$LIVE_USER" LANG_MODE="$LANG_MODE" ISO_LOCALE="$ISO_LOCALE" ISO_LANGUAGE="$ISO_LANGUAGE" TIMEZONE="$TIMEZONE" /bin/bash -s <<'CHROOT_ROOT_FINISH'
set -euo pipefail
BUILD_LANG_MODE="$LANG_MODE"
export DEBIAN_FRONTEND=noninteractive
export LANG="$ISO_LOCALE"
export LANGUAGE="$ISO_LANGUAGE"
export LC_ALL="$ISO_LOCALE"

msg() {
    if [[ "$BUILD_LANG_MODE" == "pt" ]]; then printf '%s\n' "$1"; else printf '%s\n' "$2"; fi
}

# Timezone
rm -rf /etc/localtime
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime

# Template já vem com $1 literal (arquivo comum, não passa por expansão
# de heredoc) — só o placeholder __TIMEZONE__ é substituído.
sed "s#__TIMEZONE__#$TIMEZONE#g" /tmp/timezone.init > /etc/init.d/timezone.sh
rm -f /tmp/timezone.init
chmod +x /etc/init.d/timezone.sh
update-rc.d timezone.sh defaults

apt-get update
apt-get full-upgrade -y
apt-get autoremove -y
apt-get autoclean
apt-get clean

rm -rf /var/cache/apt/archives/*
rm -f /var/lib/dbus/machine-id
rm -f /sbin/initctl
dpkg-divert --rename --remove /sbin/initctl

# Restaura os binários reais do grub/os-prober diverted lá no início — se
# o usuário instalar via Calamares depois, o grub-install/update-grub
# precisam funcionar de verdade no sistema já instalado (rodando fora
# deste chroot, na máquina de destino real).
for bin in /usr/sbin/grub-install /usr/sbin/grub-mkconfig /usr/sbin/update-grub /usr/bin/os-prober; do
    rm -f "$bin"
    dpkg-divert --rename --remove "$bin" 2>/dev/null || true
done

> /etc/resolv.conf
cd /
history -c
rm -f /root/.bash_history

# Remove o "userapp-Firefox-*.desktop" que o KDE gera ao definir o Firefox
# como navegador padrão pela interface na etapa interativa. Esse override
# não tem Icon= (ícone quebrado nos Favoritos) e sobrescreve o
# /usr/share/applications/firefox.desktop de verdade.
rm -f "/home/$LIVE_USER/.local/share/applications/userapp-Firefox-"*.desktop
if [[ -f "/home/$LIVE_USER/.config/mimeapps.list" ]]; then
    sed -i 's/userapp-Firefox-[A-Za-z0-9]*\.desktop/firefox.desktop/g' \
        "/home/$LIVE_USER/.config/mimeapps.list"
fi

msg ">>> Finalização concluída." ">>> Finalization completed."
CHROOT_ROOT_FINISH
echo "7" > "$PROGRESS_MARKER"
fi # RESUME_FROM -gt 7

# ============================================================ #
# 8. DESMONTA, REEMPACOTA E GERA A ISO
# ============================================================ #

msg ">>> [8/8] Desmontando e gerando ISO final..." ">>> [8/8] Unmounting and generating the final ISO..."

xhost -
for m in sys/firmware/efi/efivars proc sys run dev/shm dev/pts dev; do
    unmount_stack "squashfs-root/$m"
done
trap - EXIT INT TERM   # já desmontamos manualmente, remove o trap de cleanup

# Kernel/initrd atuais dentro do squashfs
KVER=$(basename "$(ls squashfs-root/boot/vmlinuz-* | sort -V | tail -n1)" | sed 's/vmlinuz-//')
msg "    Kernel detectado: $KVER" "    Detected kernel: $KVER"

sudo rm -f iso/live/initrd.img iso/live/vmlinuz
sudo cp "squashfs-root/boot/initrd.img-$KVER" iso/live/initrd.img
sudo cp "squashfs-root/boot/vmlinuz-$KVER" iso/live/vmlinuz
sudo chown "$(id -un):$(id -gn)" iso/live/initrd.img iso/live/vmlinuz
sudo chmod 644 iso/live/vmlinuz

# Templates em config/boot/ — variante "install" preserva as entradas
# originais do Debian (Live, fail-safe, Advanced install options,
# Utilities); variante "live" é o menu único minimalista. BOOT_ENTRY_LABEL
# (no idioma da ISO) já foi resolvido no início do script via
# config/languages.json — as entradas originais do Debian ficam em
# inglês de propósito (ver comentário lá).
sudo cp "$CONFIG_DIR/boot/isolinux.cfg.tmpl" iso/isolinux/isolinux.cfg

if [[ "$ISO_MODE" == "install" ]]; then
    # Nossos templates "install" referenciam (include/source), mas não
    # geram, esses arquivos do Debian-Installer clássico -- eles têm que
    # já vir na ISO base. Se uma versão futura parar de trazer algum, o
    # menu de boot fica quebrado silenciosamente (entrada faltando ou
    # source apontando pra nada) só percebido ao testar o boot real.
    # Falha aqui, cedo e com mensagem clara, em vez disso.
    MISSING_BOOT_FILES=()
    for f in \
        iso/boot/grub/install.cfg iso/boot/grub/install_start.cfg \
        iso/isolinux/install.cfg iso/isolinux/utilities.cfg \
        iso/isolinux/stdmenu.cfg
    do
        [[ -f "$f" ]] || MISSING_BOOT_FILES+=("$f")
    done
    if (( ${#MISSING_BOOT_FILES[@]} > 0 )); then
        echo "!!! ERRO: a ISO base não traz os arquivos do menu de instalação" >&2
        echo "!!! clássico que config/boot/*install*.tmpl espera encontrar:" >&2
        printf '!!!   - %s\n' "${MISSING_BOOT_FILES[@]}" >&2
        echo "!!! Revise config/build.json (debian_iso_version) ou os" >&2
        echo "!!! templates em config/boot/ antes de prosseguir." >&2
        echo "!!! ERROR: the base ISO does not ship the classic installer" >&2
        echo "!!! menu files that config/boot/*install*.tmpl expects:" >&2
        printf '!!!   - %s\n' "${MISSING_BOOT_FILES[@]}" >&2
        echo "!!! Review config/build.json (debian_iso_version) or the" >&2
        echo "!!! templates in config/boot/ before continuing." >&2
        exit 1
    fi

    sudo cp "$CONFIG_DIR/boot/grub-install.cfg.tmpl" iso/boot/grub/grub.cfg
    sudo cp "$CONFIG_DIR/boot/live-install.cfg.tmpl" iso/isolinux/live.cfg
    sudo cp "$CONFIG_DIR/boot/menu-install.cfg.tmpl" iso/isolinux/menu.cfg
    sudo sed -i "s#__BOOT_ENTRY_LABEL__#$BOOT_ENTRY_LABEL#" iso/boot/grub/grub.cfg iso/isolinux/live.cfg
else
    # Modo somente live: menu único e minimalista, sem instalador (não faz
    # sentido oferecer o Debian-Installer clássico numa ISO sem espaço/
    # pacotes de instalação — calamares nem entra nesse modo).
    sudo cp "$CONFIG_DIR/boot/grub-live.cfg.tmpl" iso/boot/grub/grub.cfg
    sudo cp "$CONFIG_DIR/boot/live-liveonly.cfg.tmpl" iso/isolinux/live.cfg
    sudo cp "$CONFIG_DIR/boot/menu-liveonly.cfg.tmpl" iso/isolinux/menu.cfg
fi

# Limpeza antes de reempacotar
sudo umount -l "squashfs-root/home/$LIVE_USER/.cache/doc" 2>/dev/null || true
sudo rm -rf "squashfs-root/home/$LIVE_USER/.cache"
# Perfil do Firefox do usuário live: se alguma sessão anterior (teste
# manual no Xephyr, por exemplo) já tiver aberto o Firefox, o perfil fica
# com um cache de idiomas/extensões desatualizado -- travado com o que
# estava instalado/configurado NAQUELE momento (ex: antes do
# firefox-l10n-* ou da política intl.locale.requested existirem). Como a
# instalação agora reaproveita este mesmo usuário live (não cria conta
# nova), esse perfil velho embarcaria em toda instalação e toda ISO live
# gerada a partir daqui. Apaga pra garantir perfil zerado no primeiro uso
# real, sempre -- é assim que a política de idioma e o langpack são
# detectados corretamente.
sudo rm -rf "squashfs-root/home/$LIVE_USER/.mozilla"
# Firefox recentes (>=~130) usam ~/.config/mozilla como perfil real em vez
# de ~/.mozilla, seguindo XDG -- descoberto porque o aviso de "caminho
# residual" (acima) continuava achando /home/$LIVE_USER dentro de
# .config/mozilla/firefox/*/extensions.json mesmo depois de já apagarmos
# ~/.mozilla. Sem isso, o Firefox shipado carrega esse perfil "novo"
# desatualizado (idioma/langpack cacheados de antes da política existir).
sudo rm -rf "squashfs-root/home/$LIVE_USER/.config/mozilla"
sudo rm -rf squashfs-root/tmp/*
sudo rm -rf squashfs-root/tmp/.* 2>/dev/null || true
sudo rm -f squashfs-root/usr/sbin/policy-rc.d

# Trava de segurança: se ainda sobrou alguma montagem (empilhada de uma
# execução anterior que morreu sem limpar, por exemplo), aborta aqui com
# erro claro em vez de deixar o mksquashfs tentar empacotar o /proc/sys/
# dev/run REAIS do host -- o que pode travar o processo (e a máquina,
# fora de VM) tentando ler arquivos de /proc que bloqueiam por natureza.
STILL_MOUNTED=()
for m in sys/firmware/efi/efivars proc sys run dev/shm dev/pts dev; do
    mountpoint -q "squashfs-root/$m" 2>/dev/null && STILL_MOUNTED+=("$m")
done
if (( ${#STILL_MOUNTED[@]} > 0 )); then
    echo "!!! ERRO: squashfs-root ainda tem montagem(ns) ativa(s), mesmo após desmontar em loop:" >&2
    printf '!!!   - %s\n' "${STILL_MOUNTED[@]}" >&2
    echo "!!! Empacotar isso poderia incluir /proc, /sys, /dev ou /run REAIS do host na ISO" >&2
    echo "!!! e travar o mksquashfs. Rode 'bash stop-build.sh' e tente de novo." >&2
    echo "!!! ERROR: squashfs-root still has active mount(s), even after the unmount loop:" >&2
    printf '!!!   - %s\n' "${STILL_MOUNTED[@]}" >&2
    echo "!!! Packaging this could bake the host's REAL /proc, /sys, /dev, or /run into the" >&2
    echo "!!! ISO and hang mksquashfs. Run 'bash stop-build.sh' and try again." >&2
    exit 1
fi

# Limita a metade dos núcleos disponíveis -- xz com todos os núcleos ao
# mesmo tempo pode disputar memória/IO agressivamente e deixar a máquina
# quase sem resposta durante a compressão (mínimo 1, nunca 0 numa VM/host
# de 1 núcleo só).
SQUASHFS_PROCESSORS=$(( $(nproc) / 2 ))
[[ "$SQUASHFS_PROCESSORS" -lt 1 ]] && SQUASHFS_PROCESSORS=1

msg ">>> Gerando squashfs (pode levar vários minutos, usando $SQUASHFS_PROCESSORS núcleo(s))..." ">>> Generating squashfs (can take several minutes, using $SQUASHFS_PROCESSORS core(s))..."
sudo mksquashfs squashfs-root iso/live/filesystem.squashfs -comp xz -processors "$SQUASHFS_PROCESSORS" -noappend

msg ">>> Gerando checksums..." ">>> Generating checksums..."
( cd iso && sudo rm -f md5sum.txt && find . -type f -not -name md5sum.txt -print0 | sudo xargs -0 md5sum | sudo tee md5sum.txt > /dev/null )

msg ">>> Gerando ISO final..." ">>> Generating final ISO..."
xorriso -as mkisofs -R -r -J -joliet-long -l -cache-inodes -iso-level 3 \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin -partition_offset 16 \
    -A "DebianAula" -p "Prof. Wyllian" -publisher "UFSC/INE" \
    -V "DebianAula KDE amd64" \
    -b isolinux/isolinux.bin -c isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
    -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
    -o "$ISO_OUTPUT" iso

rm -f "$PROGRESS_MARKER"

echo
msg ">>> ISO gerada em: $WORKDIR/$ISO_OUTPUT" ">>> ISO generated at: $WORKDIR/$ISO_OUTPUT"
msg ">>> Concluído!" ">>> Done!"
