#!/usr/bin/env bash
# quick system health report for linux boxes

warn=90
out=""

while getopts "o:w:h" opt; do
    case $opt in
        o) out=$OPTARG ;;
        w) warn=$OPTARG ;;
        *) echo "usage: $0 [-o file] [-w disk warn %]"; exit 1 ;;
    esac
done

have() { command -v "$1" >/dev/null 2>&1; }

header() { printf '\n== %s ==\n' "$1"; }

report() {
    header "system"
    echo "host:    $(hostname)"
    echo "os:      $(grep -m1 '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')"
    echo "kernel:  $(uname -r)"
    echo "uptime:  $(uptime -p 2>/dev/null || uptime)"

    header "cpu / memory"
    echo "cpu:     $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)"
    echo "cores:   $(nproc)"
    echo "load:    $(cut -d' ' -f1-3 /proc/loadavg)"
    free -h | awk 'NR==2 {print "mem:     " $3 " used / " $2}'

    header "disk"
    df -h -x tmpfs -x devtmpfs -x overlay -x squashfs 2>/dev/null | awk -v w="$warn" '
        NR==1 {print; next}
        {p=$5; sub("%","",p); flag=(p+0>=w) ? "  <-- low space" : ""; print $0 flag}'

    header "network"
    if have ip; then
        ip -4 -brief addr show | grep -v '^lo'
        echo "gateway: $(ip route | awk '/default/ {print $3; exit}')"
    fi
    echo "dns:     $(awk '/^nameserver/ {print $2}' /etc/resolv.conf | xargs)"
    if ping -c1 -W2 1.1.1.1 >/dev/null 2>&1; then echo "ping:    ok"; else echo "ping:    FAILED"; fi
    if getent hosts github.com >/dev/null; then echo "resolve: ok"; else echo "resolve: FAILED"; fi

    header "top memory"
    ps -eo pid,comm,%mem,%cpu --sort=-%mem | head -6

    if have systemctl && [ -d /run/systemd/system ]; then
        header "failed services"
        failed=$(systemctl --failed --no-legend --plain | awk '{print $1}')
        echo "${failed:-none}"

        header "recent errors"
        journalctl -p 3 -b -n 10 --no-pager 2>/dev/null || echo "can't read journal (try sudo)"
    fi
}

if [ -n "$out" ]; then
    report | tee "$out"
    echo
    echo "saved to $out"
else
    report
fi
