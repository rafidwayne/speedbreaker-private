#!/bin/bash
# Makes a PRIVATE copy of the SpeedBreaker repo, adds the Shadow Distance patch and the one-click
# build workflow, uploads your default.xex to the copy as a private release asset, and starts the build.
# Your original repository is only read, never changed.
#
# Needs: git and the GitHub CLI (https://cli.github.com), logged in:  gh auth login
# usage: ./setup-private-copy.sh /path/to/default.xex [new-repo-name] [source-repo]
# Put this script next to the 0001-*.patch and 0002-*.patch files.
set -euo pipefail
XEX="${1:?usage: $0 /path/to/default.xex [new-repo-name] [source-repo]}"
NAME="${2:-speedbreaker-private}"
SRC="${3:-rafidwayne/speedbreaker}"
HERE="$(cd "$(dirname "$0")" && pwd)"
[ -f "$XEX" ] || { echo "No such file: $XEX" >&2; exit 2; }
echo "aebdf3c14d1e4e4ed2c130d94bc1a0e97bd6d5bf39bdfdef33c3909c9cc4ba4c  $XEX" | sha256sum -c - \
  || { echo "That is not the supported USA (NTSC-U) default.xex." >&2; exit 2; }
ls "$HERE"/000*.patch >/dev/null

USER_LOGIN="$(gh api user --jq .login)"
REPO="$USER_LOGIN/$NAME"
gh repo create "$REPO" --private --description "Private build copy of SpeedBreaker (no game files in git)"

WORK="$(mktemp -d)"
git clone "https://github.com/$SRC.git" "$WORK/repo"
cd "$WORK/repo"
git checkout -q -b main-private
git -c user.name="$USER_LOGIN" -c user.email="$USER_LOGIN@users.noreply.github.com" am "$HERE"/000*.patch
git remote add private "https://github.com/$REPO.git"
git push private main-private:main

# default.xex goes to a release of the PRIVATE repository, never into git.
gh release create xex --repo "$REPO" --title "xex" --notes "Private input for the build. Do not make this repository public." "$XEX#default.xex"

gh workflow run build-all.yml --repo "$REPO" --ref main
echo
echo "Started. Watch it at: https://github.com/$REPO/actions"
echo "When it finishes (a few hours), download the SpeedBreaker-Windows artifact from the run page."
