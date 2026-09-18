#!/usr/bin/env bash
# publish-aur.sh — push PKGBUILD + .SRCINFO + desktop file to the AUR.
#
#   scripts/publish-aur.sh [--dry-run] [--no-push]
#
# Does not compile the app. AUR is source; a full makepkg is a local check.
set -euo pipefail

here="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"

PKGNAME="${AUR_PKGNAME:-cline-desktop}"
AUR_HOST="${AUR_HOST:-aur@aur.archlinux.org}"
AUR_FILES=(PKGBUILD .SRCINFO cline-desktop.desktop)

dry_run=0
push=1
while [[ $# -gt 0 ]]; do
	case "$1" in
	--dry-run) dry_run=1 && shift ;;
	--no-push) push=0 && shift ;;
	*) echo "error: unknown argument $1" >&2 && exit 2 ;;
	esac
done

die() {
	echo "error: $*" >&2
	exit 1
}
step() { printf '\n==> %s\n' "$*"; }

command -v makepkg >/dev/null || die "makepkg not found — this needs Arch"
[[ "$(id -u)" -ne 0 ]] || die "run as a normal user: makepkg refuses root"

for f in "${AUR_FILES[@]}"; do
	[[ -f "$here/$f" ]] || die "missing $here/$f"
done

cd "$here"

step "Checking .SRCINFO matches PKGBUILD"
tmp="$(mktemp)"
makepkg --printsrcinfo >"$tmp"
diff -u .SRCINFO "$tmp" || die ".SRCINFO is stale — run: makepkg --printsrcinfo > .SRCINFO"
rm -f "$tmp"

version="$(sed -n 's/^pkgver=//p' PKGBUILD)"
release="$(sed -n 's/^pkgrel=//p' PKGBUILD)"
[[ -n "$version" ]] || die "pkgver missing"

if [[ $dry_run -eq 1 ]]; then
	step "Dry run — would publish $PKGNAME $version-$release"
	exit 0
fi

if [[ $push -eq 0 ]]; then
	step "Not pushing (--no-push)."
	exit 0
fi

step "Pushing to the AUR"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
aur="$work/aur"
git clone -q "ssh://$AUR_HOST/$PKGNAME.git" "$aur" ||
	die "cannot clone $PKGNAME from the AUR — is the key loaded?"
for f in "${AUR_FILES[@]}"; do
	cp "$here/$f" "$aur/"
done
cd "$aur"
git add "${AUR_FILES[@]}"
if git diff --cached --quiet; then
	step "Already published at $version-$release — nothing to do"
	exit 0
fi
git -c user.name="${GIT_AUTHOR_NAME:-Gianluca Mazza}" \
	-c user.email="${GIT_AUTHOR_EMAIL:-info@gianlucamazza.it}" \
	commit -q -m "$PKGNAME $version-$release"
git push -q origin HEAD:master
step "Published $PKGNAME $version-$release to the AUR"
echo "  https://aur.archlinux.org/packages/$PKGNAME"
