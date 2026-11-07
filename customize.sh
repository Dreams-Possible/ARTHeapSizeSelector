#!/system/bin/sh

stop_key_reader() {
    kill "$key_reader" 2>/dev/null || true
    wait "$key_reader" 2>/dev/null || true
    rm -f "$key_pipe"
}

start_key_reader() {
    key_pipe="$TMPDIR/art-heap-keys.$$"
    mkfifo "$key_pipe" || return 1

    # 最多监听 25 秒。用 $! 记录后台进程，选完后可以立即停止。
    timeout 25 /system/bin/getevent -l > "$key_pipe" 2>/dev/null &
    key_reader=$!
    trap stop_key_reader EXIT
    trap 'exit 1' HUP INT TERM
}

select_heap() {
    set -- "$heap_size" 1536 2048 512 768
    confirm=0

    while read -r device type key action; do
        case "$type $key $action" in
            'EV_KEY KEY_VOLUMEUP DOWN')
                # 把当前档位移到队尾，第一项就是新的候选值。
                set -- "$@" "$1"
                shift
                confirm=0
                ui_print "当前选择 $1 MiB"
                ;;
            'EV_KEY KEY_VOLUMEDOWN DOWN')
                if [ "$1" -lt 1536 ] || [ "$confirm" -eq 2 ]; then
                    heap_size=$1
                    return 0
                fi
                if [ "$confirm" -eq 0 ]; then
                    confirm=1
                    ui_print "$1 MiB 可能导致 ART 启动失败。松开后再按一次音量减确认。"
                fi
                ;;
            'EV_KEY KEY_VOLUMEDOWN UP')
                # 高档位必须松手再按，长按不会当成第二次确认。
                if [ "$confirm" -eq 1 ]; then
                    confirm=2
                fi
                ;;
        esac
    done
    return 1
}

install_heap() {
    heap_size=1024
    ui_print "音量加：循环切换档位。"
    ui_print "音量减：确认当前档位。"
    ui_print "档位 512 / 768 / 1024 / 1536 / 2048 MiB"
    ui_print "25 秒内未确认会使用默认档位 $heap_size MiB。"
    ui_print "如果选错，可以重新安装模块并再次选择。"

    if ! start_key_reader || ! select_heap < "$key_pipe"; then
        ui_print "未收到确认，使用默认 $heap_size MiB。"
    fi

    printf 'dalvik.vm.heapsize=%sm\n' "$heap_size" > "$MODPATH/system.prop" || return 1
    ui_print "已选择 $heap_size MiB，重启生效。"
}

# 清理钩子只在本次安装菜单的子 Shell 内生效。
( install_heap ) || abort "无法写入 system.prop。"
