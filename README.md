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

To produce a `.vsix` you can install locally or publish:

```bash
npm install -g @vscode/vsce
vsce package
```

To publish to the Marketplace, see VS Code's official publishing guide:
<https://code.visualstudio.com/api/working-with-extensions/publishing-extension>.

You will need to:

1. Create a publisher at <https://marketplace.visualstudio.com/manage> and
   confirm the ID matches `publisher` in `package.json`.
2. Run `vsce login <publisher>` with a Personal Access Token that has the
   Marketplace "Manage" scope.
3. Run `vsce publish`.

## Known limitations

- VS Code's `FileDecoration` API only accepts `ThemeColor` references, not raw
  hex codes. That's why color customization goes through
  `workbench.colorCustomizations` instead of a plain settings string.
- Badges are capped at 2 characters by VS Code itself.

## License

MIT — see [LICENSE](./LICENSE).
