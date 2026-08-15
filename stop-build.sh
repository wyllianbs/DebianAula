#!/bin/bash
#
# stop-build.sh — Botão de emergência para build-iso.sh.
#
# Rode isto em OUTRO terminal a qualquer momento para interromper um
# build travado de forma imediata e segura, sem depender de Ctrl+C
# chegar ao processo certo (o que pode falhar se seu 'sudo' usa
# 'use_pty', já que aí os processos filhos ficam numa sessão/pty
# separada da do terminal original e não recebem o SIGINT dele).
#
# O que este script faz, nesta ordem:
#   1. Mata qualquer processo cuja raiz (/proc/<pid>/root) seja o
#      'squashfs-root' deste diretório — ou seja, tudo rodando DENTRO
#      do chroot (apt, mksquashfs, a sessão Xephyr/Plasma, etc).
#   2. Mata o Xephyr do build, se ainda estiver de pé.
#   3. Desmonta (com -lf) proc/sys/dev/dev-pts/dev-shm/run dentro de
#      squashfs-root — as montagens isoladas criadas pelo build-iso.sh
#      (nunca as reais do host, então não há nada arriscado a desmontar
#      aqui: veja o comentário sobre isolamento em build-iso.sh).
#
# Uso:
#   bash stop-build.sh
#
# Depois de rodar, é seguro chamar 'bash build-iso.sh' de novo — ele
# reaproveita squashfs-root/iso de onde parou (a menos que você opte por
# reconstruir do zero quando perguntado).

set -uo pipefail

WORKDIR="$(pwd)"
SQUASHFS_ROOT="$WORKDIR/squashfs-root"

echo ">>> stop-build.sh: procurando processos dentro de '$SQUASHFS_ROOT'..."

if [[ -d "$SQUASHFS_ROOT" ]]; then
    REAL_ROOT="$(readlink -f "$SQUASHFS_ROOT")"
    FOUND=0
    for pid_dir in /proc/[0-9]*; do
        pid="${pid_dir#/proc/}"
        proc_root="$(sudo readlink -f "$pid_dir/root" 2>/dev/null || true)"
        if [[ -n "$proc_root" && "$proc_root" == "$REAL_ROOT" ]]; then
            cmd="$(sudo tr '\0' ' ' < "$pid_dir/cmdline" 2>/dev/null || true)"
            echo "    Matando PID $pid ($cmd)"
            sudo kill -9 "$pid" 2>/dev/null || true
            FOUND=1
        fi
    done
    [[ "$FOUND" -eq 0 ]] && echo "    Nenhum processo rodando dentro do chroot."
else
    echo "    '$SQUASHFS_ROOT' não existe, nada para matar."
fi

echo ">>> Matando Xephyr do build (se houver)..."
pkill -f "Xephyr :2" 2>/dev/null || true

echo ">>> Desmontando montagens isoladas do build..."
for m in dev/shm dev/pts dev run sys proc; do
    sudo umount -lf "$SQUASHFS_ROOT/$m" 2>/dev/null || true
done

echo ">>> Pronto. É seguro rodar 'bash build-iso.sh' de novo quando quiser."
