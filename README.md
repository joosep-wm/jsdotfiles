# jsdotfiles

Personal dotfiles for **Joosep**. One repo, two homes:

- **macOS workstation** (iTerm2 + zellij + IntelliJ + vim)
- **Remote Linux servers** (Ubuntu etc.) where the same shell should feel identical

Everything is written to be **portable**: macOS-only paths (Homebrew, `nvm` via brew,
`Python.framework`, JetBrains) are guarded with existence/OS checks, so the exact same
files run unchanged on a fresh Ubuntu box — the Mac bits simply no-op.

---

## Layout

```
jsdotfiles/
├── install.sh                 # symlinks everything into $HOME (idempotent, backs up)
├── shell/
│   ├── zshrc                  -> ~/.zshrc        (oh-my-zsh + p10k, graceful fallback)
│   ├── zprofile               -> ~/.zprofile     (Homebrew/Linuxbrew, PATH bootstrap)
│   ├── bashrc                 -> ~/.bashrc       (minimal bash fallback for remote)
│   ├── aliases.zsh            -> ~/.aliases.zsh
│   ├── env.zsh                -> ~/.env.zsh      (nvm, gcloud — multi-location)
│   ├── path.zsh               -> ~/.path.zsh     (only adds dirs that exist)
│   ├── fzf.zsh / fzf.bash     -> ~/.fzf.*
│   └── secrets.zsh.example    -> copy to ~/.secrets.zsh   (gitignored, never committed)
├── git/gitconfig              -> ~/.gitconfig
├── vim/vimrc                  -> ~/.vimrc        (readline-style insert/cmdline editing)
├── tmux/tmux.conf             -> ~/.tmux.conf
├── zellij/config.kdl          -> ~/.config/zellij/config.kdl
├── p10k/p10k.zsh              -> ~/.p10k.zsh
└── macos/DefaultKeyBinding.dict -> ~/Library/KeyBindings/...  (macOS only)
```

---

## Install on a new machine

```bash
git clone <your-repo-url> ~/dev/jsdotfiles
cd ~/dev/jsdotfiles
./install.sh --omz       # symlink dotfiles AND install oh-my-zsh + p10k + plugins
exec zsh -l
```

- `./install.sh` — just symlinks (anything already there is moved to `*.backup.<timestamp>`).
- `./install.sh --omz` — also installs oh-my-zsh, powerlevel10k, and the three custom
  plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`, `you-should-use`).

Re-running is safe — existing symlinks are refreshed, real files are backed up once.

---

## Remote Linux server setup (Ubuntu etc.)

On a server you usually want it fast and minimal. The shell **degrades gracefully**: if
oh-my-zsh isn't installed, `zshrc` falls back to a simple built-in prompt, so step 1 alone
already gives you a working, sane shell.

```bash
# 1. Prerequisites (Ubuntu/Debian)
sudo apt update && sudo apt install -y zsh git curl vim fzf

# 2. Clone and link
git clone <your-repo-url> ~/dev/jsdotfiles
cd ~/dev/jsdotfiles
./install.sh                      # minimal: just symlinks + fallback prompt
#   …or for the full prompt experience:
./install.sh --omz                # adds oh-my-zsh + powerlevel10k + plugins

# 3. Make zsh your login shell (optional but recommended)
chsh -s "$(command -v zsh)"       # log out / back in to take effect
#   If you can't chsh (no sudo / locked shell), add to ~/.bash_profile instead:
#     [ -x "$(command -v zsh)" ] && exec zsh -l

# 4. New shell
exec zsh -l
```

**Powerlevel10k fonts:** the fancy prompt needs a Nerd Font *in your terminal*, which is a
**local** setting — install [MesloLGS NF](https://github.com/romkatv/powerlevel10k#manual-font-installation)
in iTerm2/your terminal on your laptop; the server doesn't need fonts. If a server prompt
looks garbled, run `p10k configure` and pick the ASCII/“no special characters” option, or
just skip `--omz` there.

**Secrets on servers:** don't copy your laptop's `~/.secrets.zsh` wholesale. Put only the
tokens that box needs into its own `~/.secrets.zsh` (the installer seeds a blank one from
the template, `chmod 600`).

---

## Secrets

Real keys live in `~/.secrets.zsh`, which is **gitignored and never committed**. Only
`shell/secrets.zsh.example` (variable names, blank values) is tracked.

```bash
cp shell/secrets.zsh.example ~/.secrets.zsh
chmod 600 ~/.secrets.zsh
vim ~/.secrets.zsh        # fill in values
```

---

## Keyboard / line-editing consistency

The goal: the **same line-editing muscle memory** in the shell, Vim, macOS GUI apps, and
IntelliJ. The shared vocabulary is the **emacs/readline chords** (`^A ^E ^B ^F ^W ^U ^K ^Y …`),
because macOS speaks them natively and the shell defaults to them. Core set:

| Chord | Action            | Chord | Action               |
|-------|-------------------|-------|----------------------|
| `^A`  | start of line     | `^W`  | delete word back     |
| `^E`  | end of line       | `^U`  | delete to line start |
| `^B`/`^F` | back/fwd char | `^K`  | kill to end of line  |
| `^P`/`^N` | prev/next line | `^Y` | yank (paste killed)  |

Word-by-word movement stays on **Option/Alt + ←/→** everywhere.

What this repo configures, and the few **manual GUI settings** that can't be a dotfile:

| Surface | Handled by | Action needed |
|---|---|---|
| **zsh / readline** | default emacs mode | nothing — already works |
| **Vim (insert + `:` cmdline)** | `vim/vimrc` | nothing — symlinked. Normal mode keeps Vim motions on purpose |
| **macOS native apps** (Notes, Mail, Safari) | `macos/DefaultKeyBinding.dict` | adds `^W`/`^U`; built-ins give the rest. **Relaunch apps** |
| **iTerm2** | — (manual) | Settings → Profiles → Keys → **Right Option Key = `Esc+`** (keep Left = `Normal` for typing `é` etc.). This is what makes Alt/Option bindings reach zellij/shell |
| **IntelliJ** | — (manual) | Settings → Keymap → **“macOS System Defaults”** (maps `^A/^E/^K/…` to caret actions; the plain “macOS” keymap steals `^E` for Recent Files) |

### Why iTerm2 needs `Esc+`
In a terminal, “Alt+key” is sent as an ESC-prefixed byte sequence (`Esc` then the key).
macOS Option defaults to typing special characters instead, so Alt bindings never fire.
Setting **Right Option = `Esc+`** makes that one key send the ESC-prefixed form (so zellij's
`Alt` bindings and readline `Alt+b`/`Alt+f` work), while **Left Option = `Normal`** keeps
the special-character layer for typing accented characters.

> Note: iTerm2 ships explicit `⌥←`/`⌥→` mappings (send `Esc b`/`Esc f`), which is why word-jump
> and a couple of zellij `Alt` shortcuts work even before you change anything.

### zellij
`zellij/config.kdl` is the **unlock-first** layout: locked by default, `Ctrl+g` toggles
normal mode. A curated set of `Alt` bindings (move focus, new pane, resize, `Alt+f` floating)
is kept live in *both* modes via the `shared_among "normal" "locked"` block, so they work
without unlocking. Those `Alt` bindings only reach zellij once iTerm2's Right Option is `Esc+`
(see above).

---

## Updating

Edit files in this repo (they're the symlink targets, so changes are live), then:

```bash
cd ~/dev/jsdotfiles
git add -A && git commit -m "tweak X" && git push
```

On another machine: `git pull` — symlinks already point here, so changes apply on next shell.
If you added a *new* tracked dotfile, run `./install.sh` again to link it.
