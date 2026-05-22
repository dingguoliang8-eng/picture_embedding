#!/bin/bash

# ???????????conda run??????
# ????: ./service.sh {start|stop|restart|status}

# ===== ???? =====
SERVICE_NAME="picture-embedding"
CONDA_ENV="picture-embedding"
PYTHON_SCRIPT="start_server.py"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/$PYTHON_SCRIPT"
PID_FILE="$SCRIPT_DIR/tmp/${SERVICE_NAME}.pid"
LOG_FILE="$SCRIPT_DIR/logs/nohup.log"

# ===== ???? =====

# ??conda??
get_conda_path() {
    which conda 2>/dev/null || echo ""
}

# ??conda????
check_conda() {
    local conda_path=$(get_conda_path)
    if [ -z "$conda_path" ]; then
        echo "??: ???conda??"
        exit 1
    fi
    echo "??conda??: $conda_path"
}

# ??conda??????
check_conda_env() {
    local env_exists=$(conda env list | grep -w "$CONDA_ENV" | wc -l)
    if [ "$env_exists" -eq 0 ]; then
        echo "??: Conda?? '$CONDA_ENV' ???"
        exit 1
    fi
    echo "??Conda??: $CONDA_ENV"
}

# ?????????????????????
find_service_processes() {
    local main_pid=$1
    local all_pids=""
    local sub_pid=""

    if [ -n "$main_pid" ]; then
        # ???????
        sub_pid=$(ps -o pid --ppid "$main_pid" --no-headers | tr '\n' ' ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [ -n "$sub_pid" ]; then
          # ???????
          all_pids="$main_pid $sub_pid"
          sub_pid=$(ps -o pid --ppid "$sub_pid" --no-headers | tr '\n' ' ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
          all_pids="$all_pids $sub_pid"
        fi
    fi

    # ????PID????????????
    if [ -z "$all_pids" ]; then
        all_pids=$(ps aux | grep "$PYTHON_SCRIPT" | grep -v grep | awk '{print $2}' | tr '\n' ' ')
    fi

    echo "$all_pids"
}

# ????
start_service() {
    echo "???? $SERVICE_NAME ..."

    # ??????????
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        local all_pids=$(find_service_processes "$pid")
        if [ -n "$all_pids" ]; then
            echo "?????? (PIDs: $all_pids)"
            return 0
        else
            echo "?????PID??????..."
            rm -f "$PID_FILE"
        fi
    fi

    # ?????????????
    local existing_pids=$(find_service_processes "")
    if [ -n "$existing_pids" ]; then
        echo "?????????? (PIDs: $existing_pids)???????"
        return 1
    fi

    # ??conda???
    check_conda
    check_conda_env

    # ????
    echo "????: conda run -n $CONDA_ENV python $PYTHON_SCRIPT"
    echo "????: $LOG_FILE"

    # ??nohup?????
    nohup conda run -n $CONDA_ENV python $PYTHON_SCRIPT > "$LOG_FILE" 2>&1 &

    local new_pid=$!
    echo $new_pid > "$PID_FILE"

    # ???????
    sleep 3
    local all_pids=$(find_service_processes "$new_pid")
    if [ -n "$all_pids" ]; then
        echo "? ??????!"
        echo "  ???PID: $new_pid"
        echo "  ????PIDs: $all_pids"
        echo "  PID??: $PID_FILE"
        echo "  ????: $LOG_FILE"
        echo "  ?? 'tail -f $LOG_FILE' ????"
    else
        echo "? ????????????: $LOG_FILE"
        rm -f "$PID_FILE"
        exit 1
    fi
}

# ????
stop_service() {
    echo "???? $SERVICE_NAME ..."

    local main_pid=""
    local all_pids=""

    # ?PID???????PID
    if [ -f "$PID_FILE" ]; then
        main_pid=$(cat "$PID_FILE")
        all_pids=$(find_service_processes "$main_pid")
    fi

    # ?????PID????????????????
    if [ -z "$all_pids" ]; then
        all_pids=$(find_service_processes "")
        if [ -n "$all_pids" ]; then
            echo "??: ???????????????PID???????"
        fi
    fi

    if [ -z "$all_pids" ]; then
        echo "???????????"
        rm -f "$PID_FILE" 2>/dev/null
        return 0
    fi

    echo "??????: $all_pids"

    # ????????TERM????????
    echo "????????..."
    for pid in $all_pids; do
        if ps -p "$pid" > /dev/null 2>&1; then
            kill -TERM "$pid" 2>/dev/null
        fi
    done

    # ??????
    local count=0
    local max_wait=15
    while [ $count -lt $max_wait ]; do
        local remaining_pids=""
        for pid in $all_pids; do
            if ps -p "$pid" > /dev/null 2>&1; then
                remaining_pids="$remaining_pids $pid"
            fi
        done

        if [ -z "$remaining_pids" ]; then
            break
        fi

        echo "??????... ($((max_wait - count))???)"
        sleep 1
        count=$((count + 1))
    done

    # ????????????????????
    local remaining_pids=""
    for pid in $all_pids; do
        if ps -p "$pid" > /dev/null 2>&1; then
            remaining_pids="$remaining_pids $pid"
        fi
    done

    if [ -n "$remaining_pids" ]; then
        echo "??????????????: $remaining_pids"
        for pid in $remaining_pids; do
            kill -KILL "$pid" 2>/dev/null
        done
        sleep 1
    fi

    # ????
    local final_check=""
    for pid in $all_pids; do
        if ps -p "$pid" > /dev/null 2>&1; then
            final_check="$final_check $pid"
        fi
    done

    if [ -z "$final_check" ]; then
        echo "? ???????"
        rm -f "$PID_FILE"
    else
        echo "??: ??????????: $final_check"
        return 1
    fi
}

# ????
restart_service() {
    echo "?? $SERVICE_NAME ..."
    stop_service
    sleep 2
    start_service
}

# ??????
status_service() {
    echo "????: $SERVICE_NAME"

    local main_pid=""
    local all_pids=""

    if [ -f "$PID_FILE" ]; then
        main_pid=$(cat "$PID_FILE")
        all_pids=$(find_service_processes "$main_pid")
    fi

    if [ -z "$all_pids" ]; then
        all_pids=$(find_service_processes "")
        if [ -n "$all_pids" ]; then
            echo "??  ??????PID???????"
            echo "  ???PIDs: $all_pids"
        else
            echo "? ?????"
            # ?????PID??
            if [ -f "$PID_FILE" ]; then
                rm -f "$PID_FILE"
            fi
        fi
        return 0
    fi

    echo "? ??????"
    echo "  ???PID: $main_pid"
    echo "  ????PIDs: $all_pids"
    echo "  PID??: $PID_FILE"
    echo "  ????: $LOG_FILE"

    # ?????
    if command -v pstree >/dev/null 2>&1; then
        echo "  ???:"
        pstree -p $main_pid 2>/dev/null | head -10
    fi

    # ??????
    for pid in $all_pids; do
        if ps -p "$pid" > /dev/null 2>&1; then
            local mem_usage=$(ps -p $pid -o rss= 2>/dev/null | awk '{printf "%.1f MB", $1/1024}')
            local cpu_usage=$(ps -p $pid -o %cpu= 2>/dev/null)
            local start_time=$(ps -p $pid -o lstart= 2>/dev/null)
            echo "  ?? $pid: CPU $cpu_usage%, ?? $mem_usage, ????: $start_time"
        fi
    done
}

# ????
tail_logs() {
    if [ -f "$LOG_FILE" ]; then
        echo "????: $LOG_FILE"
        echo "=== ???? ==="
        tail -20 "$LOG_FILE"
        echo "=== ???? ==="
        echo "?? 'tail -f $LOG_FILE' ??????"
    else
        echo "???????: $LOG_FILE"
    fi
}

# ????????????
force_cleanup() {
    echo "???? $SERVICE_NAME ????..."

    # ??????????????????
    local pids=$(ps aux | grep "$PYTHON_SCRIPT" | grep -v grep | awk '{print $2}')

    if [ -n "$pids" ]; then
        echo "????: $pids"
        kill -KILL $pids 2>/dev/null
        echo "???????"
    else
        echo "???????"
    fi

    # ????
    rm -f "$PID_FILE"
    echo "???PID??"
}

# ??????
usage() {
    echo "????: $0 {start|stop|restart|status|logs|cleanup|help}"
    echo ""
    echo "??:"
    echo "  start    ????"
    echo "  stop     ????????"
    echo "  restart  ????"
    echo "  status   ??????"
    echo "  logs     ??????"
    echo "  cleanup  ?????????????"
    echo "  help     ???????"
    echo ""
    echo "????:"
    echo "  ????: $SERVICE_NAME"
    echo "  Conda??: $CONDA_ENV"
    echo "  Python??: $PYTHON_SCRIPT"
}

# ===== ??? =====

case "$1" in
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    restart)
        restart_service
        ;;
    status)
        status_service
        ;;
    logs)
        tail_logs
        ;;
    cleanup)
        force_cleanup
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        echo "??: ???? '$1'"
        echo ""
        usage
        exit 1
        ;;
esac

exit 0
