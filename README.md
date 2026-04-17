# Test File Dimmer

Dim test files in the VS Code Explorer (and add a small badge) so your **actual**
source files visually pop when you keep tests side-by-side with the code they
cover.

Designed for codebases that colocate tests (for example a `foo.py` next to a
`foo_test.py`). Works out of the box with Python, JavaScript/TypeScript, Go,
Ruby, Rust, Java, Kotlin, C#, PHP, Swift, and C/C++ naming conventions.

## Features

- Applies a muted foreground color to test files in the Explorer.
- Shows a small `T` badge (configurable or hideable) next to each test file.
- Fully configurable glob patterns — match whatever naming convention your team uses.
- Exclude patterns so you can unstyle specific subdirectories.
- Contributed theme color so you can pick any color you like via
  `workbench.colorCustomizations`.
- Toggle command in the Command Palette to turn the effect on/off without
  editing settings.

## Default patterns

The defaults only match **suffix-style** test filenames — that is, patterns
where the test marker appears after the base name (`foo_test.py`, `foo.test.ts`,
`FooTest.java`). Files like `test_foo.py` or files that merely live in a
`tests/` directory are **not** dimmed by default, since those conventions also
catch non-test helpers. Add them to `testFileDimmer.patterns` if you want them.

| Language     | Patterns                                                         |
|--------------|------------------------------------------------------------------|
| Python       | `**/*_test.py`                                                   |
| JS/TS        | `**/*.test.{js,jsx,ts,tsx,mjs,cjs}`, `**/*.spec.{...}`           |
| Go           | `**/*_test.go`                                                   |
| Ruby         | `**/*_spec.rb`, `**/*_test.rb`                                   |
| Java         | `**/*Test.java`, `**/*Tests.java`                                |
| Kotlin       | `**/*Test.kt`, `**/*Tests.kt`                                    |
| C#           | `**/*Test.cs`, `**/*Tests.cs`                                    |
| PHP          | `**/*Test.php`                                                   |
| Swift        | `**/*Tests.swift`                                                |
| Groovy       | `**/*Spec.groovy`                                                |
| C/C++        | `**/*_test.{c,cc,cpp,cxx,h,hpp}`, `**/*_tests.{...}`             |

Override the full list via `testFileDimmer.patterns` in your settings. Common
additions you might want:

```json
{
  "testFileDimmer.patterns": [
    "**/*_test.py",
    "**/test_*.py",
    "**/__tests__/**/*.{js,jsx,ts,tsx}",
    "**/spec/**/*.rb",
    "**/tests/**/*.rs",
    "**/src/test/**/*.{java,kt,scala}"
  ]
}
```

## Settings

| Setting                               | Type        | Default | Description                                                                 |
|---------------------------------------|-------------|---------|-----------------------------------------------------------------------------|
| `testFileDimmer.enabled`              | `boolean`   | `true`  | Enable or disable all decorations.                                          |
| `testFileDimmer.patterns`             | `string[]`  | (above) | Glob patterns that identify test files.                                     |
| `testFileDimmer.excludePatterns`      | `string[]`  | `[]`    | Glob patterns to exclude, even if they match `patterns`.                    |
| `testFileDimmer.badge`                | `string`    | `"T"`   | Badge text (max 2 chars). Empty string hides the badge.                     |
| `testFileDimmer.tooltip`              | `string`    | `"Test file"` | Tooltip text on hover.                                                |
| `testFileDimmer.propagateToFolders`   | `boolean`   | `false` | Also decorate the parent folder.                                            |

## Customizing the color

The extension contributes a theme color called `testFileDimmer.foreground`.
To change it, add an override to your settings:

```json
{
  "workbench.colorCustomizations": {
    "testFileDimmer.foreground": "#5a9bd4"
  }
}
```

You can also scope it to specific themes:

```json
{
  "workbench.colorCustomizations": {
    "[Default Dark Modern]": {
      "testFileDimmer.foreground": "#6b6b6b"
    },
    "[Default Light Modern]": {
      "testFileDimmer.foreground": "#a0a0a0"
    }
  }
}
```

## Commands

- **Test File Dimmer: Toggle Decorations** — flip `testFileDimmer.enabled`.
- **Test File Dimmer: Refresh Decorations** — force the Explorer to redraw
  (useful after editing patterns or swapping branches).

## Development

```bash
npm install
npm run compile
# Then press F5 in VS Code to open an Extension Development Host.
```

To produce a `.vsix` you can install locally:

```bash
npm run package
```

You can install the resulting `.vsix` into VS Code or Cursor via
*Extensions: Install from VSIX...* in the Command Palette.

## Releasing

The extension is published to two marketplaces so both VS Code and
VS Code-derived editors (Cursor, VSCodium, etc.) can discover it:

- **VS Code Marketplace** (<https://marketplace.visualstudio.com>) — used by
  VS Code itself.
- **Open VSX** (<https://open-vsx.org>) — used by Cursor, VSCodium, Gitpod,
  and most other forks.

### One-time setup

1. Create a publisher on the VS Code Marketplace at
   <https://marketplace.visualstudio.com/manage>. The publisher ID must match
   the `publisher` field in `package.json`.
2. Generate a VS Code Marketplace PAT at <https://dev.azure.com/>
   (Organization: *All accessible organizations*, Scope: *Marketplace → Manage*).
3. Claim the matching namespace on <https://open-vsx.org> and generate an
   access token at <https://open-vsx.org/user-settings/tokens>.
4. Export both tokens in your shell (consider adding these to a password
   manager rather than your shell rc file):

   ```bash
   export VSCE_PAT=<vs-code-marketplace-token>
   export OVSX_PAT=<open-vsx-token>
   ```

### Shipping a release

```bash
# Publish the current version in package.json
npm run release

# Or bump the version first
npm run release:patch   # 0.1.0 -> 0.1.1
npm run release:minor   # 0.1.0 -> 0.2.0
npm run release:major   # 0.1.0 -> 1.0.0

# Dry run: package only, no publishing or git changes
npm run release:dry
```

The release script (`scripts/publish.sh`):

1. Verifies the working tree is clean and you're on `main`.
2. Optionally bumps the version and commits the bump as `Release vX.Y.Z`.
3. Builds a single `.vsix`.
4. Publishes that `.vsix` to both marketplaces.
5. Creates and pushes a `vX.Y.Z` git tag.

Flags for partial runs: `--skip-vsce`, `--skip-ovsx`, `--skip-tag`,
`--skip-push`, `--dry-run`.

Remember to update `CHANGELOG.md` before shipping a new version.

## Known limitations

- VS Code's `FileDecoration` API only accepts `ThemeColor` references, not raw
  hex codes. That's why color customization goes through
  `workbench.colorCustomizations` instead of a plain settings string.
- Badges are capped at 2 characters by VS Code itself.

## License

MIT — see [LICENSE](./LICENSE).
