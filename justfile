# Task runner for Test File Dimmer.
#
# Recipes:
#   just                 # show this list
#   just bump LEVEL      # bump version, commit, tag, push. LEVEL=patch|minor|major|X.Y.Z
#   just publish         # build .vsix and publish to VS Code Marketplace + Open VSX
#
# `just publish` requires these env vars:
#   VSCE_PAT   - VS Code Marketplace Personal Access Token
#   OVSX_PAT   - Open VSX access token

set shell := ["bash", "-euo", "pipefail", "-c"]

EXT_NAME := "test-file-dimmer"

default:
    @just --list

# Bump version (patch|minor|major|X.Y.Z), commit, tag, and push.
bump LEVEL:
    #!/usr/bin/env bash
    set -euo pipefail

    log()  { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
    die()  { printf '\033[1;31mxx  %s\033[0m\n' "$*" >&2; exit 1; }

    case "{{LEVEL}}" in
      patch|minor|major) ;;
      [0-9]*.[0-9]*.[0-9]*) ;;
      *) die "LEVEL must be patch|minor|major|X.Y.Z (got '{{LEVEL}}')" ;;
    esac

    [[ -z "$(git status --porcelain)" ]] || die "Working tree is dirty. Commit or stash first."

    branch="$(git rev-parse --abbrev-ref HEAD)"
    [[ "$branch" == "main" ]] || die "Must be on 'main' to bump (on '$branch')."

    log "Bumping version ({{LEVEL}})"
    new_version="$(npm version --no-git-tag-version "{{LEVEL}}" | tail -n1)"
    new_version="${new_version#v}"
    tag="v$new_version"
    log "New version: $new_version"

    if git rev-parse "$tag" >/dev/null 2>&1; then
      die "Tag $tag already exists."
    fi

    git add package.json package-lock.json
    git commit -m "Release $tag"
    git tag -a "$tag" -m "Release $tag"

    log "Pushing $branch and $tag"
    git push origin "$branch"
    git push origin "$tag"

    log "Done. Now run: just publish"

# Publish the current package.json version to VS Code Marketplace + Open VSX.
publish:
    #!/usr/bin/env bash
    set -euo pipefail

    log()  { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
    die()  { printf '\033[1;31mxx  %s\033[0m\n' "$*" >&2; exit 1; }

    [[ -n "${VSCE_PAT:-}" ]] || die "VSCE_PAT is not set."
    [[ -n "${OVSX_PAT:-}" ]] || die "OVSX_PAT is not set."
    [[ -z "$(git status --porcelain)" ]] || die "Working tree is dirty. Commit or stash first."

    version="$(node -p "require('./package.json').version")"
    publisher="$(node -p "require('./package.json').publisher")"
    vsix="{{EXT_NAME}}-${version}.vsix"

    log "Publishing {{EXT_NAME}} v$version as $publisher"

    log "Packaging $vsix"
    rm -f ./*.vsix
    npx --no-install vsce package --out "$vsix"

    log "Publishing to VS Code Marketplace"
    npx --no-install vsce publish --packagePath "$vsix" --pat "$VSCE_PAT"

    log "Publishing to Open VSX"
    npx --no-install ovsx publish "$vsix" --pat "$OVSX_PAT"

    log "Done."
    echo "  - https://marketplace.visualstudio.com/items?itemName=${publisher}.{{EXT_NAME}}"
    echo "  - https://open-vsx.org/extension/${publisher}/{{EXT_NAME}}"

# Build the .vsix locally without publishing.
package:
    #!/usr/bin/env bash
    set -euo pipefail
    version="$(node -p "require('./package.json').version")"
    vsix="{{EXT_NAME}}-${version}.vsix"
    rm -f ./*.vsix
    npx --no-install vsce package --out "$vsix"
    printf '\033[1;34m==> Built %s\033[0m\n' "$vsix"
