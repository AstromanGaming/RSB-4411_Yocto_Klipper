#!/bin/sh

YOCTIAN_FILE="/etc/.yoctianos"
YOCTIAN_LIST="/etc/apt/sources.list.d/yoctianos.list"
BACKUP_DIR="/var/backups/yoctianos"
TMP_DIR="$(mktemp -d /tmp/yoctianos-apt.XXXXXX)"
TMP_OLD="$TMP_DIR/yoctianos.list.old"
TMP_NEW="$TMP_DIR/yoctianos.list.new"
TMP_CLEAN="$TMP_DIR/yoctianos.list.clean"
EDITOR="${EDITOR:-vi}"

get_public_status() {
    if [ ! -f "$YOCTIAN_FILE" ]; then
        echo "false"
        return
    fi

    case "$(grep -o 'public="[^"]*"' "$YOCTIAN_FILE" | cut -d'"' -f2)" in
        true)  echo "true" ;;
        false) echo "false" ;;
        *)     echo "false" ;; # default fallback
    esac
}

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT HUP INT TERM

die() {
    echo "ERROR: $*" >&2
    cleanup
    exit 1
}

# Must be root user
if [ "$(whoami)" != "root" ]; then
    die "This script must be run as root user."
fi

if [ -f /etc/.yoctianos ] && grep -q 'install="false"' /etc/.yoctianos; then
    die "Error: You can not execute it. Aborting."
fi

# Helper trim
_trim() {
    printf "%s" "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Basic URL validation (very permissive)
is_valid_url() {
    case "$1" in
        http://*|https://*|file://*|*.*|localhost) return 0 ;;
        *) return 1 ;;
    esac
}

# Prepare backup dir
mkdir -p "$BACKUP_DIR"

# Read existing list (if any)
if [ -f "$YOCTIAN_LIST" ]; then
    cp -- "$YOCTIAN_LIST" "$TMP_OLD"
else
    : > "$TMP_OLD"
fi

echo
echo "=== YoctianOS Setup: APT ==="
if [ -s "$TMP_OLD" ]; then
    echo "Existing YoctianOS repositories:"
    echo "----------------------------------------"
    nl -ba "$TMP_OLD"
    echo "----------------------------------------"
else
    echo "(No existing YoctianOS repo file found)"
fi

printf "Choose action  [e=edit file  a=add repo  r=remove line  u=update only  q=quit] (default a): "
read -r ACTION
ACTION="$(_trim "$ACTION")"
[ -z "$ACTION" ] && ACTION="a"

case "$ACTION" in
    q|Q)
        echo "Aborting. No changes made."
        exit 0
        ;;
    u|U)
        echo "Running apt-get update..."
        if command -v apt-get >/dev/null 2>&1; then
            apt-get update || true
        fi
        echo "Update complete."
        exit 0
        ;;
    e|E)
        cp -- "$TMP_OLD" "$TMP_NEW"
        echo "Opening $EDITOR to edit repository list..."
        $EDITOR "$TMP_NEW"
        ;;
    r|R)
        if [ ! -s "$TMP_OLD" ]; then
            echo "No lines to remove."
            exit 0
        fi
        echo "Enter line numbers to remove (comma separated), or empty to cancel:"
        read -r LINES
        LINES="$(_trim "$LINES")"
        if [ -z "$LINES" ]; then
            echo "Cancel remove."
            exit 0
        fi
        awk -v rm="$LINES" 'BEGIN{
            split(rm, a, ",");
            for(i in a) r[a[i]]=1
        }
        { if (!r[NR]) print $0 }' "$TMP_OLD" > "$TMP_NEW"
        ;;
    a|A|*)
        echo "Enter repo URLs to add. One per line. Comma allowed on a line. Empty line to finish."
        printf "Mark local LAN/file repos as trusted by default? [Y/n]: "
        read -r TRUST_ANS
        TRUST_ANS="$(_trim "$TRUST_ANS")"
        if [ -z "$TRUST_ANS" ] || echo "$TRUST_ANS" | grep -iq '^y'; then
            DEFAULT_TRUST="yes"
        else
            DEFAULT_TRUST="no"
        fi

        cp -- "$TMP_OLD" "$TMP_NEW"

        while true; do
            printf "Repo URL (empty to finish): "
            read -r INPUT
            INPUT="$(_trim "$INPUT")"
            [ -z "$INPUT" ] && break

            OLDIFS="$IFS"; IFS=','; for u in $INPUT; do
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
                        host="$(printf "%s" "$url" | sed -E 's#^[a-z]+://##' | cut -d/ -f1)"
                        if printf "%s" "$host" | grep -Eq '^10\.|^192\.168\.|^172\.(1[6-9]|2[0-9]|3[0-1])\.' || printf "%s" "$host" | grep -Eq '\.local$' || printf "%s" "$host" | grep -Eq '^localhost$'; then
                            is_local=1
                        fi
                        ;;
                esac

                TRUST="no"
                if [ "$is_local" -eq 1 ]; then
                    if [ "$DEFAULT_TRUST" = "yes" ]; then
                        TRUST="yes"
                    else
                        printf "Mark this local repo as trusted (skip GPG)? [y/N]: "
                        read -r t
                        t="$(_trim "$t")"
                        if echo "$t" | grep -iq '^y'; then TRUST="yes"; fi
                    fi
                fi

                if ! is_valid_url "$url"; then
                    echo "Skipping invalid URL: $url"
                    continue
                fi

                if [ "$is_local" -eq 1 ]; then
                    if [ "$TRUST" = "yes" ]; then
                        printf "deb [trusted=yes] %s ./\n" "$url" >> "$TMP_NEW"
                    else
                        printf "deb %s ./\n" "$url" >> "$TMP_NEW"
                    fi
                else
                    if command -v dpkg >/dev/null 2>&1; then
                        arch="$(dpkg --print-architecture 2>/dev/null || true)"
                    else
                        arch=""
                    fi
                    if [ -n "$arch" ]; then
                        printf "deb [arch=%s] %s ./\n" "$arch" "$url" >> "$TMP_NEW"
                    else
                        printf "deb %s ./\n" "$url" >> "$TMP_NEW"
                    fi
                fi
            done; IFS="$OLDIFS"
        done

	#PUBLIC_STATUS="$(get_public_status)"

        #if [ "$PUBLIC_STATUS" = "false" ]; then
	#	printf "Adding the default online APT repository. Add the repo now? [Y/n]: "
	#	read -r PUBLICREPO
	#	PUBLICREPO="$(_trim "$PUBLICREPO")"
	#	if [ -z "$PUBLICREPO" ] || echo "$PUBLICREPO" | grep -iq '^y'; then
	#  	  curl -L https://deb.rpmdeb.com/YoctianOS/DEV/RSB-4411/public/pub.gpg.key | sudo apt-key add -
  	#	  echo "deb https://deb.rpmdeb.com/YoctianOS/DEV/RSB-4411/public/ stable main" > /etc/apt/sources.list.d/dev-rsb-4411-public.list
	#	else
   	#	  echo "Skipping default online APT repo configuration."
        #        fi
	#fi
        ;;
esac

# Normalize: remove empty lines, trim, dedupe while preserving order
awk 'NF{gsub(/^[ \t]+|[ \t]+$/,""); print}' "$TMP_NEW" 2>/dev/null | awk '!seen[$0]++' > "$TMP_CLEAN" || die "Failed to normalize new list"

if [ ! -s "$TMP_CLEAN" ]; then
    echo "Resulting repository list is empty. Aborting without changes."
    cleanup
    exit 1
fi

# Backup existing file with timestamp
ts="$(date +%Y%m%dT%H%M%S)"
if [ -f "$YOCTIAN_LIST" ]; then
    cp -- "$YOCTIAN_LIST" "$BACKUP_DIR/yoctianos.list.$ts.bak"
fi

# Atomic write
mkdir -p "$(dirname "$YOCTIAN_LIST")"
mv "$TMP_CLEAN" "$TMP_NEW"
chmod 0644 "$TMP_NEW"
mv -f "$TMP_NEW" "$YOCTIAN_LIST"

echo
echo "Final YoctianOS repository list:"
echo "----------------------------------------"
nl -ba "$YOCTIAN_LIST"
echo "----------------------------------------"

echo "APT setup complete!"
cleanup
exit 0
