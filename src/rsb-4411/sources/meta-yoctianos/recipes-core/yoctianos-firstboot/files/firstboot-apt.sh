#!/bin/sh

export UPDATE=false

# This script must be run as root user.
if [ "$(whoami)" != "root" ]; then
    echo "ERROR: This script must be run as root user. Aborting."
    exit 1
fi

if [ -f /etc/.yoctianos ] && grep -q 'install="true"' /etc/.yoctianos; then
    echo "Error: You can not execute it. Aborting."
    exit 1
fi

echo
echo "=== YoctianOS Setup: APT ==="

set_public_flag() {
    if [ -f "$YOCTIANOS_FILE" ]; then
        sed -i 's/public="false"/public="true"/' "$YOCTIANOS_FILE"
    fi
}

# Helper to trim whitespace
_trim() {
    echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Determine architecture for web repos only (optional)
WEB_ARCH=""
if command -v dpkg >/dev/null 2>&1; then
    WEB_ARCH="$(dpkg --print-architecture 2>/dev/null || true)"
fi

YOCTIAN_LIST="/etc/apt/sources.list.d/yoctianos.list"
TMP_LIST="$(mktemp /tmp/yoctian_repolist.XXXXXX)" || TMP_LIST=""
ADDED=0

# Ensure TMP_LIST is removed on exit if it exists
_cleanup_tmp() {
    [ -n "$TMP_LIST" ] && [ -f "$TMP_LIST" ] && rm -f "$TMP_LIST"
}
trap _cleanup_tmp EXIT HUP INT TERM

echo
printf "Adding Mirror and/or Local APT repositories, it's recommended. Add repos now? [Y/n]: "
read -r ADDREPOS
ADDREPOS="$(_trim "$ADDREPOS")"
if [ -z "$ADDREPOS" ] || echo "$ADDREPOS" | grep -iq '^y'; then
    echo
    echo "Enter repo URLs. You can add local LAN repos (HTTP or file) and public web repos (HTTP/HTTPS)."
    echo "One URL per prompt; comma-separated URLs allowed on a single line. Press Enter on an empty line to finish."
    LOCAL_TRUST_SET=0
    LOCAL_TRUST="yes"

    while true; do
        printf "Repo URL (leave empty to finish): "
        read -r INPUT
        INPUT="$(_trim "$INPUT")"
        [ -z "$INPUT" ] && break

        if [ "$LOCAL_TRUST_SET" -eq 0 ]; then
            printf "Mark local LAN/file repos as trusted (skip GPG verification)? [Y/n]: "
            read -r ans
            ans="$(_trim "$ans")"
            if [ -z "$ans" ] || echo "$ans" | grep -iq '^y'; then
                LOCAL_TRUST="yes"
            else
                LOCAL_TRUST="no"
            fi
            LOCAL_TRUST_SET=1
        fi

        OLDIFS="$IFS"
        IFS=','
        for u in $INPUT; do
            u="$(_trim "$u")"
            [ -z "$u" ] && continue

            case "$u" in
                http://*|https://*|file://*) url="$u" ;;
                *) url="http://$u" ;;
            esac

            is_local=0
            case "$url" in
                file://*) is_local=1 ;;
                http://*|https://*)
                    host="$(echo "$url" | sed -E 's#^[a-z]+://##' | cut -d/ -f1)"
                    if echo "$host" | grep -Eq '^10\.|^192\.168\.|^172\.(1[6-9]|2[0-9]|3[0-1])\.' || echo "$host" | grep -Eq '\.local$'; then
                        is_local=1
                    fi
                    ;;
            esac

            # Build deb line:
            if [ "$is_local" -eq 1 ]; then
                if [ "$LOCAL_TRUST" = "yes" ]; then
                    printf "deb [trusted=yes] %s ./\n" "$url" >> "$TMP_LIST"
                else
                    printf "deb %s ./\n" "$url" >> "$TMP_LIST"
                fi
            else
                if [ -n "$WEB_ARCH" ]; then
                    printf "deb [arch=%s] %s ./\n" "$WEB_ARCH" "$url" >> "$TMP_LIST"
                else
                    printf "deb %s ./\n" "$url" >> "$TMP_LIST"
                fi
            fi

            ADDED=1
        done
        IFS="$OLDIFS"
    done

    if [ "$ADDED" -eq 1 ] && [ -n "$TMP_LIST" ]; then
        mkdir -p "$(dirname "$YOCTIAN_LIST")"
        if [ -f "$YOCTIAN_LIST" ]; then
            awk '!seen[$0]++' "$YOCTIAN_LIST" "$TMP_LIST" > "${TMP_LIST}.uniq" || true
            mv "${TMP_LIST}.uniq" "$YOCTIAN_LIST"
        else
            mv "$TMP_LIST" "$YOCTIAN_LIST"
            TMP_LIST=""
        fi
        chmod 0644 "$YOCTIAN_LIST"
        echo "Added repos to $YOCTIAN_LIST"
        export UPDATE=true
    else
        [ -n "$TMP_LIST" ] && rm -f "$TMP_LIST"
        echo "No repos added."
    fi
else
    [ -n "$TMP_LIST" ] && rm -f "$TMP_LIST"
    echo "Skipping Mirror and/or Local APT repo configuration."
fi

#echo
#printf "Adding the default online APT repository. Add the repo now? [Y/n]: "
#read -r PUBLICREPO
#if [ -z "$PUBLICREPO" ] || echo "$PUBLICREPO" | grep -iq '^y'; then
#    curl -L https://deb.rpmdeb.com/YoctianOS/DEV/RSB-4411/public/pub.gpg.key | sudo apt-key add -
#    echo "deb https://deb.rpmdeb.com/YoctianOS/DEV/RSB-4411/public/ stable main" > /etc/apt/sources.list.d/dev-rsb-4411-public.list
#    set_public_flag
#    export UPDATE=true
#else
#    echo "Skipping default online APT repo configuration."
#fi

if [ -z "$UPDATE" ] || echo "$UPDATE" | grep -iq 'true'; then
    echo "Update all APT repesitories..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update || true
    fi
fi

echo "APT setup complete!"
