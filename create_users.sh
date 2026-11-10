#!/usr/bin/env bash
# Create or update local accounts from two lists.
#
# Usage:   sudo ./create_accounts.sh <sudoers-file> <users-file>
# Example: sudo ./create_accounts.sh sudoers.txt users.txt
#
# Each file has one account per line:  username::password
# Blank lines and lines starting with # are ignored.
set -Eeuo pipefail

die() { echo "Error: $*" >&2; exit 1; }

(( EUID == 0 )) || die "run as root: sudo $0 <sudoers-file> <users-file>"
(( $# == 2 ))   || die "usage: $0 <sudoers-file> <users-file>"
getent group sudo >/dev/null || die "the 'sudo' group does not exist on this system"

sudoers_file=$1
users_file=$2
for f in "$sudoers_file" "$users_file"; do
    [[ -f $f ]] || die "file not found: $f"
done

created=0 updated=0 sudo_count=0 standard_count=0
declare -A seen=()

# Validate every line in both files before changing anything.
validate() {
    local file=$1 line user pass n=0
    while IFS= read -r line || [[ -n $line ]]; do
        ((n += 1))
        line=${line%$'\r'}
        [[ -z $line || $line == \#* ]] && continue
        [[ $line == *::* ]] || die "$file:$n: expected username::password"
        user=${line%%::*}
        pass=${line#*::}
        [[ $user =~ ^[a-z_][a-z0-9_-]*\$?$ && ${#user} -le 32 ]] \
            || die "$file:$n: invalid username '$user'"
        [[ -n $pass ]] || die "$file:$n: empty password for '$user'"
        [[ -z ${seen[$user]:-} ]] || die "$file:$n: '$user' already listed in ${seen[$user]}"
        seen[$user]="$file:$n"
    done < "$file"
}

# Create/update each account, then add to or remove from the sudo group.
apply() {
    local file=$1 want_sudo=$2 line user pass
    while IFS= read -r line || [[ -n $line ]]; do
        line=${line%$'\r'}
        [[ -z $line || $line == \#* ]] && continue
        user=${line%%::*}
        pass=${line#*::}

        if id -- "$user" >/dev/null 2>&1; then
            ((updated += 1))
        else
            useradd --create-home --shell /bin/bash -- "$user"
            ((created += 1))
        fi

        printf '%s:%s\n' "$user" "$pass" | chpasswd

        if [[ $want_sudo == yes ]]; then
            usermod -aG sudo -- "$user"
            ((sudo_count += 1))
        else
            gpasswd -d "$user" sudo >/dev/null 2>&1 || true
            ((standard_count += 1))
        fi
    done < "$file"
}

validate "$sudoers_file"
validate "$users_file"

apply "$sudoers_file" yes
apply "$users_file"   no

# The lists contain plaintext passwords; keep them readable by root only.
chmod 600 -- "$sudoers_file" "$users_file"

cat <<EOF
Account setup complete.
  Created:  $created
  Updated:  $updated
  Sudo:     $sudo_count
  Standard: $standard_count
EOF