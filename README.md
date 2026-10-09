# claude-plugins

Michele's Claude Code plugin marketplace. It lists third-party plugins, each pinned to a release that was reviewed before it reached any machine.

Added once on claude.ai (Customize → Plugins → Add marketplace → `michele-mogul/claude-plugins`). Plugins installed from it are saved to the account, and every Claude Code signed in with that account (Raspberry Pi, Windows PC, Mac) downloads them at startup as `<name>@synced`.

## Plugins

| Plugin | Upstream | Pinned | What it adds |
|---|---|---|---|
| `ponytail` | [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) | v5.1.0 `9cc65d0`, fetched from upstream by commit | 6 skills, 3 hooks (SessionStart, SubagentStart, UserPromptSubmit). ~430 tokens per session |
| `ecc` | [affaan-m/ECC](https://github.com/affaan-m/ECC) | v2.2.3 `c05b2d6`, trimmed copy in `plugins/ecc` | 68 agents, 387 skills and commands, no hooks, no MCP servers. ~31k tokens per session |

Official plugins come from the Anthropic directory on claude.ai, not from here: `claude-md-management`, `hookify`, `security-guidance`, `context7`.

Ponytail's hooks need Node.js on `PATH`. Without it they fail and only its skills work.

## Why ECC is a trimmed copy

A review of ECC v2.2.3's hooks (standard profile) found:

- tool inputs and outputs logged to `~/.local/share/ecc-homunculus/` with a redaction that misses Plex and Telegram tokens, quoted API keys and private keys;
- a headless `claude -p` run on the last 25 turns, whose summary is stored and injected into the next session, also in the `minimal` profile;
- every Bash command logged to `~/.claude/bash-commands.log`, never rotated;
- GateGuard refusing the first Bash command of a session and the first edit of each file, and a plain retry passing;
- the `chrome-devtools` MCP server started with `npx -y` at every session.

Turning the hooks off with `ECC_HOOKS_ENABLED=false` still starts 8–12 no-op Node processes per tool call, on every machine separately. So `sync-ecc.sh` copies only `agents/`, `skills/`, `commands/`, `scripts/` (some skills call them) and `LICENSE`, and drops `hooks`, `mcpServers`, `lspServers` and `userConfig` from `plugin.json`. ECC is MIT licensed; its license is kept in `plugins/ecc/LICENSE`.

## Updating

Nothing changes on the machines until this repo changes.

**Ponytail** (pinned by commit):
1. Compare: `gh api repos/DietrichGebert/ponytail/compare/<old sha>...<new sha>`.
2. Read every change under `hooks/`: hooks run as the local user.
3. Update `ref` and `sha` in `.claude-plugin/marketplace.json`.

**ECC** (trimmed copy):
1. `./sync-ecc.sh <tag>` rebuilds `plugins/ecc` from that release and writes `plugins/ecc/UPSTREAM`.
2. Review `git diff`, mainly `scripts/` and any new skill that runs commands.
3. Update the version in the `ecc` entry description.

Then run `claude plugin validate .`, commit and push. claude.ai picks up the new version, and a running Claude Code session asks for `/reload-plugins`.
