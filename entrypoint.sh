#!/bin/bash

# Start acng with a custom config file / logs folder and tail
# those logs so they show in the docker logs.
# Also handle signals so that the container exits cleanly
# when stopped with 'docker stop'

interrupted=0
pid=""
tailpid=""
status=""

function run()
(
    echo "From: ${PWD}" 1>&2
    echo "Run:${*}" 1>&2
    exec "${@}"
)

function alive()
{
    local p
    for p in "${@}"
    do
        [[ -n "${p}" && -d "/proc/${p}" ]] && echo "${p}"
    done
}

function cleanup()
{
    local waitfirst=0
    for sig in -INT -TERM -KILL
    do
        local pids=$(alive "${p}" "${tailpid}")
        [[ -z "${pid}" ]] && break

        if (( waitfirst ))
        then
            sleep 0.5
        fi
        pids=$(alive "${pid}" "${tailpid}")
        if [[ -n "${pids}" ]]
        then
            kill "${sig}" ${pids} > /dev/null 2>&1 || /bin/true
        fi
        waitfirst=1
    done
}

function cleanup_trap()
{
    interrupted=1
    cleanup
}

function run-acng()
{
    local executable=$(command -v apt-cacher-ng)

    ( 
        cd /etc/apt-cacher-ng/backends
        shopt -s nullglob
        for f in backends_*
        do
            ln -sf backends/"${f}" /etc/apt-cacher-ng/"${f}"
        done
    )

    if [[ "${VERBOSE}" == "1" ]]
    then
        echo "Defaults:"
        sed -n -e '/^(#|$)/ d' -e '/./ { s/^/    /; p }' < "/acng/acng-defaults.conf"
        echo
        echo "Configuration:"
        sed -n -e '/^(#|$)/ d' -e '/./ { s/^/    /; p }' < "/acng/acng.conf"
        echo
        echo "Backends.."
        ls -al /etc/apt-cacher-ng/backend*
        echo
        echo "Continuing.."
    fi

    trap cleanup_trap INT TERM HUP

    set -m # enable job control

    # ACNG seems hard-coded to log to files, not stdout, but we want the logs
    # to go to the docker logs, via stdout.
    # So we start the service and then tail the logs
    tail -f "/acng/log"/*.* &
    tailpid=$!

    "${executable}" -c /etc/apt-cacher-ng "${EXTRA_ARGS[@]}" &
    pid=$!

    wait %2
    status=$?

    if (( interrupted ))
    then
        echo "Interrupted or killed"
        exit 0
    fi

    cleanup

    echo "${0} exiting with status ${status}"

    if [[ "${status}" == 143 ]]
    then
        exit 0
    else
        exit ${status}
    fi
}

function main()
{
    case "${1}" in
        /bin/bash|bash)
            exec /bin/bash "${@:2}"
            ;;
        *)
            run-acng "${@}"
            ;;
    esac
}

main "${@}"
