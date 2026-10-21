#!/bin/zsh
# Move the `personal` branch (our fork commits) on top of a newer upstream release.
#
#   scripts/update-from-upstream.sh            # newest v2.* tag from upstream
#   scripts/update-from-upstream.sh v2.8       # a specific tag
#   scripts/update-from-upstream.sh dev        # upstream's development branch
#
# The current base is tracked by the `fork-base` tag. git rerere replays
# conflict resolutions we already made, so repeated conflicts resolve themselves.
set -euo pipefail
cd "$(dirname "$0")/.."

git config rerere.enabled true
git config rerere.autoupdate true

if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
  echo "Working tree has uncommitted changes; commit or stash them first."
  exit 1
fi

git fetch upstream --tags --force
target="${1:-$(git tag --list 'v2.*' --sort=-creatordate | head -1)}"
[[ "$target" == "dev" ]] && target="upstream/dev"
git rev-parse --verify --quiet "$target^{commit}" >/dev/null || { echo "Unknown target: $target"; exit 1; }

old_base="$(git rev-parse "fork-base^{commit}")"
new_base="$(git rev-parse "$target^{commit}")"
if [[ "$old_base" == "$new_base" ]]; then
  echo "Already on $target. Nothing to do."
  exit 0
fi

echo "Upstream changes since our base:"
git log --oneline --no-merges fork-base.."$target" | grep -v -i -E "appcast|crowdin|bump " | head -40 || true

git switch personal
backup="backup/$(date +%Y-%m-%d-%H%M)"
git tag "$backup"
echo "Backup tag: $backup"

if ! git rebase --onto "$target" fork-base personal; then
  echo
  echo "Rebase stopped on a conflict (files above). Resolve, then run:"
  echo "  git add <files> && git rebase --continue"
  echo "  git tag -f fork-base $new_base && scripts/install-local.sh"
  echo "To give up and go back:  git rebase --abort && git reset --hard $backup"
  exit 1
fi

git tag -f fork-base "$new_base"
scripts/install-local.sh
