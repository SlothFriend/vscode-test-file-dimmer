import * as vscode from 'vscode';
import * as path from 'path';
import { minimatch } from 'minimatch';

const CONFIG_SECTION = 'testFileDimmer';
const COLOR_ID = 'testFileDimmer.foreground';

/**
 * FileDecorationProvider that dims test files in the Explorer and adds a badge.
 *
 * VS Code's FileDecoration API only accepts ThemeColor references (not raw hex
 * colors), so we contribute a custom theme color (testFileDimmer.foreground)
 * via package.json. Users can override it through workbench.colorCustomizations.
 */
class TestFileDecorationProvider implements vscode.FileDecorationProvider {
  private readonly _onDidChange = new vscode.EventEmitter<
    vscode.Uri | vscode.Uri[] | undefined
  >();
  readonly onDidChangeFileDecorations = this._onDidChange.event;

  private enabled = true;
  private patterns: string[] = [];
  private excludePatterns: string[] = [];
  private badge = 'T';
  private tooltip = 'Test file';
  private propagate = false;

  constructor() {
    this.refreshConfig();
  }

  /** Re-read settings and fire a global change event so VS Code redraws. */
  refreshConfig(): void {
    const cfg = vscode.workspace.getConfiguration(CONFIG_SECTION);
    this.enabled = cfg.get<boolean>('enabled', true);
    this.patterns = cfg.get<string[]>('patterns', []);
    this.excludePatterns = cfg.get<string[]>('excludePatterns', []);
    this.badge = (cfg.get<string>('badge', 'T') ?? '').slice(0, 2);
    this.tooltip = cfg.get<string>('tooltip', 'Test file');
    this.propagate = cfg.get<boolean>('propagateToFolders', false);
    this._onDidChange.fire(undefined);
  }

  /** Force a full redraw (used by the explicit "Refresh" command). */
  fireChange(): void {
    this._onDidChange.fire(undefined);
  }

  provideFileDecoration(
    uri: vscode.Uri,
    _token: vscode.CancellationToken,
  ): vscode.FileDecoration | undefined {
    if (!this.enabled) {
      return undefined;
    }

    // Only decorate files on disk (scheme === 'file'). Skip untitled, git diffs,
    // output channels, etc. They still render in the Explorer as 'file', but
    // this keeps us safe against surprises.
    if (uri.scheme !== 'file') {
      return undefined;
    }

    const relPath = this.toRelativePath(uri);
    if (!relPath) {
      return undefined;
    }

    // Normalize to forward slashes so glob patterns behave the same on Windows.
    const normalized = relPath.split(path.sep).join('/');

    if (!this.matchesAny(normalized, this.patterns)) {
      return undefined;
    }
    if (this.matchesAny(normalized, this.excludePatterns)) {
      return undefined;
    }

    const decoration: vscode.FileDecoration = {
      color: new vscode.ThemeColor(COLOR_ID),
      tooltip: this.tooltip,
      propagate: this.propagate,
    };

    if (this.badge && this.badge.length > 0) {
      decoration.badge = this.badge;
    }

    return decoration;
  }

  private toRelativePath(uri: vscode.Uri): string | undefined {
    const folder = vscode.workspace.getWorkspaceFolder(uri);
    if (folder) {
      return path.relative(folder.uri.fsPath, uri.fsPath);
    }
    // Fall back to matching just the basename when the file is outside any
    // workspace folder (e.g., a single file opened in a detached window).
    return path.basename(uri.fsPath);
  }

  private matchesAny(relPath: string, patterns: string[]): boolean {
    const basename = relPath.split('/').pop() ?? relPath;
    for (const pattern of patterns) {
      if (!pattern) continue;
      // Match against the full workspace-relative path...
      if (minimatch(relPath, pattern, { dot: true, nocase: false })) {
        return true;
      }
      // ...and also against the basename, so patterns like "*_test.py" work
      // even when the file is nested deep in subfolders.
      if (!pattern.includes('/') && minimatch(basename, pattern, { dot: true })) {
        return true;
      }
    }
    return false;
  }

  dispose(): void {
    this._onDidChange.dispose();
  }
}

export function activate(context: vscode.ExtensionContext): void {
  const provider = new TestFileDecorationProvider();

  context.subscriptions.push(
    vscode.window.registerFileDecorationProvider(provider),
    provider,

    // Re-read settings whenever any of our config keys change.
    vscode.workspace.onDidChangeConfiguration((e) => {
      if (e.affectsConfiguration(CONFIG_SECTION)) {
        provider.refreshConfig();
      }
    }),

    // Toggle command — flips the 'enabled' setting at the user level.
    vscode.commands.registerCommand('testFileDimmer.toggle', async () => {
      const cfg = vscode.workspace.getConfiguration(CONFIG_SECTION);
      const current = cfg.get<boolean>('enabled', true);
      await cfg.update(
        'enabled',
        !current,
        vscode.ConfigurationTarget.Global,
      );
      vscode.window.setStatusBarMessage(
        `Test File Dimmer ${!current ? 'enabled' : 'disabled'}`,
        2000,
      );
    }),

    // Manual refresh — useful if someone changes files on disk outside VS Code.
    vscode.commands.registerCommand('testFileDimmer.refresh', () => {
      provider.fireChange();
    }),
  );
}

export function deactivate(): void {
  // Nothing to clean up — all disposables are registered on the context.
}
