#!/usr/bin/env bash
# Publish Test File Dimmer to the VS Code Marketplace and Open VSX in one shot.
#
# Usage:
#   scripts/publish.sh                # publish the current package.json version
#   scripts/publish.sh patch          # bump patch (0.1.0 -> 0.1.1) then publish
#   scripts/publish.sh minor          # bump minor (0.1.0 -> 0.2.0) then publish
#   scripts/publish.sh major          # bump major (0.1.0 -> 1.0.0) then publish
#   scripts/publish.sh 1.2.3          # set explicit version then publish
#
# Required environment variables:
#   VSCE_PAT  - Personal Access Token for the VS Code Marketplace publisher
#   OVSX_PAT  - Access token for the Open VSX namespace
#
# Optional flags:
#   --skip-vsce   skip publishing to the VS Code Marketplace
#   --skip-ovsx   skip publishing to Open VSX
#   --skip-tag    skip creating/pushing the git tag
#   --skip-push   skip pushing the commit/tag to origin
#   --dry-run     package only; do not publish, bump, tag, or push

set -euo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

bump=""
skip_vsce=false
skip_ovsx=false
skip_tag=false
skip_push=false
dry_run=false

for arg in "$@"; do
  case "$arg" in
    --skip-vsce) skip_vsce=true ;;
    --skip-ovsx) skip_ovsx=true ;;
    --skip-tag)  skip_tag=true ;;
    --skip-push) skip_push=true ;;
    --dry-run)   dry_run=true ;;
    patch|minor|major) bump="$arg" ;;
    [0-9]*.[0-9]*.[0-9]*) bump="$arg" ;;
    -h|--help)
      sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

log()  { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m!!  %s\033[0m\n' "$*" >&2; }
die()  { printf '\033[1;31mxx  %s\033[0m\n' "$*" >&2; exit 1; }

# --- Preconditions -----------------------------------------------------------

if [[ ! -f package.json ]]; then
  die "package.json not found; run this from the repo root."
fi

if ! $dry_run; then
  if ! $skip_vsce && [[ -z "${VSCE_PAT:-}" ]]; then
    die "VSCE_PAT is not set. Export it or pass --skip-vsce."
  fi
  if ! $skip_ovsx && [[ -z "${OVSX_PAT:-}" ]]; then
    die "OVSX_PAT is not set. Export it or pass --skip-ovsx."
  fi
fi

if [[ -n "$(git status --porcelain)" ]]; then
  die "Working tree is dirty. Commit or stash changes first."
fi

branch="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$branch" != "main" ]]; then
  warn "You are on branch '$branch', not 'main'."
  read -r -p "Continue anyway? [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]] || die "Aborted."
fi

# --- Version bump ------------------------------------------------------------

if [[ -n "$bump" ]]; then
  log "Bumping version: $bump"
  # `npm version` updates package.json + package-lock.json and creates a commit+tag.
  # We want our own tag message format, so use --no-git-tag-version and commit manually.
  new_version="$(npm version --no-git-tag-version "$bump" | tail -n1)"
  new_version="${new_version#v}"
  log "New version: $new_version"

  if $dry_run; then
    log "Dry run: reverting version bump."
    git checkout -- package.json package-lock.json
  else
    git add package.json package-lock.json
    git commit -m "Release v$new_version"
  fi
else
  new_version="$(node -p "require('./package.json').version")"
  log "Publishing existing version: $new_version"
fi

tag="v$new_version"

# --- Package -----------------------------------------------------------------

log "Packaging .vsix"
rm -f ./*.vsix
npx --no-install vsce package --out "test-file-dimmer-$new_version.vsix"
vsix="test-file-dimmer-$new_version.vsix"

if $dry_run; then
  log "Dry run complete. Package: $vsix"
  exit 0
fi

# --- Publish -----------------------------------------------------------------

if ! $skip_vsce; then
  log "Publishing to VS Code Marketplace"
  npx --no-install vsce publish --packagePath "$vsix" --pat "$VSCE_PAT"
else
  warn "Skipping VS Code Marketplace publish (--skip-vsce)"
fi

if ! $skip_ovsx; then
  log "Publishing to Open VSX"
  npx --no-install ovsx publish "$vsix" --pat "$OVSX_PAT"
else
  warn "Skipping Open VSX publish (--skip-ovsx)"
fi

# --- Tag + push --------------------------------------------------------------

if ! $skip_tag; then
  if git rev-parse "$tag" >/dev/null 2>&1; then
    warn "Tag $tag already exists; not recreating."
  else
    log "Creating tag $tag"
    git tag -a "$tag" -m "Release $tag"
  fi
fi

if ! $skip_push; then
  log "Pushing main and tags to origin"
  git push origin "$branch"
  git push origin "$tag" 2>/dev/null || true
else
  warn "Skipping git push (--skip-push)"
fi

log "Done. Published $tag to:"
echo "  - https://marketplace.visualstudio.com/items?itemName=$(node -p "require('./package.json').publisher").test-file-dimmer"
echo "  - https://open-vsx.org/extension/$(node -p "require('./package.json').publisher")/test-file-dimmer"
