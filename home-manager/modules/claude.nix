{
  lib,
  pkgs,
  osConfig,
  ...
}:
{
  programs.claude-code.enable = true;

  # Companion to plan mode: keeps its read-only enforcement but defers the
  # plan-drafting behaviour so the session stays conversational.
  programs.claude-code.commands.discuss = ''
    ---
    description: Discussion mode — in plan mode, defer planning until asked
    ---

    Discussion mode: treat plan mode as read-only conversation. Explore the
    codebase and answer questions conversationally. Defer drafting a plan, and do
    not call ExitPlanMode or steer towards plan approval, until I explicitly ask
    for a plan. If plan mode is not active, remind me to enable it (shift+tab)
    before continuing.
  '';

  # Global context loaded into every Claude Code session (~/.claude/CLAUDE.md).
  # Plain markdown; escape ''${ as '''${ and '' as ''' if you add code samples.
  programs.claude-code.context = ''
    # Global instructions

    - Be concise and direct — skip preamble and flattery. Applies to chat, Jira comments, and PR descriptions.
    - Always use ASD-STE100 Simplified Technical English (STE).
    - State each fact once. Don't restate context or explain the same thing two ways.
    - Length must be earned by complexity or risk, not padding. When unsure, cut.
    - Make minimal changes. If something can be written better, bring it up but don't implement it immediately.
    - Don't force the reader to skim with a large wall of text. Present easily digestible responses so that a natural question and answer format can be acheived.

    ## Code comments

    Add a comment only when one of these applies:
    - a VERY BRIEF summary of a non-obvious unit (1-2 lines max), or
    - a workaround, constraint, or gotcha the code itself cannot make obvious.

    Never add comments that:
    - narrate the change ("replaces X", "used to", "same as the old…", "moved from") — git history owns that;
    - restate what the adjacent code visibly does;
    - describe other systems or consumers (which pipeline/job/alert/field uses this) — those rot;
    - justify the change to a reviewer — that belongs in the PR body or commit message;
    - explain or defend the design ("so that…", "this way we get…", "without needing X") —
      the code's shape is the decision; rationale lives in the PR body or commit message.

    Default is zero comments. Before writing one, name which allowed category it is
    (brief summary of a non-obvious unit / workaround-constraint-gotcha); if you can't
    name it, don't write it. Truth is not sufficient — a comment must be necessary:
    if deleting it loses nothing a cold reader needs to safely change the code, delete it.

    Litmus test: would this comment still be true and useful to someone reading the
    file in a year, having never seen the diff? If not, don't write it. When in
    doubt, no comment — deleting is better than letting one go stale.

    ## PR descriptions

    Write for exactly two readers: the reviewer deciding whether to approve, and
    the operator executing the merge. Include only what the diff cannot say:
    - one or two sentences of what and why — the problem and the end state;
    - effects the reviewer can't infer from the diff (per-environment plan
      summaries, behaviour changes, data effects);
    - out-of-band validation the reviewer can't see from CI: sandbox
      allocate/deallocate runs (config + run links), manual or load tests;
    - operational content: ordered pre/post-merge steps with exact commands,
      known risks with their canary and rollback;
    - links: ticket, dependent PRs, docs.

    Never include:
    - the development journey ("initially we…", "after discussion this was
      changed to…") — describe what the PR *is*, not how it got there;
    - a file-by-file tour of the diff — reviewers read the diff;
    - green-CI / unit-tests-pass status the checks UI already shows, or
      boilerplate section headers with nothing under them;
    - selling ("significantly improves", "robust", "clean").

    Length is earned by risk, not effort: routine change → a few self-contained
    sentences. Risky or multi-step change → short what/why + links, with the full
    runbook (ordered steps, timings, rollback) living in Confluence, linked from
    the PR.

    ## Epistemics
    - Label platform-capability claims by evidence class: [tested this session],
      [doc + URL fetched this session], [inferred], [training memory]. Never
      deliver [inferred] in the same register as [tested].
    - "X is impossible / the only way is Y" requires, in the same message, a
      current-doc citation or a concrete runtime test that would falsify it.
      Otherwise phrase it as a hypothesis.
    - An unverified caveat is a to-do, not a disclaimer: resolve it before
      building on the claim, or state "the following builds on unverified
      assumption X".
    - For fast-moving platforms (Foundry, Claude API, GitHub), fetch the current
      doc before answering capability questions, even when confident. Source
      precedence: runtime test > current docs > API specs > Q&A/blogs > memory.
    - Scope claims exactly: "Sonnet 5.x" ≠ "Claude"; "the UI accepts it" ≠ "the
      runtime supports it"; "not documented" ≠ "not supported".
    - When corrected, also hunt down sibling claims sharing the broken premise —
      don't just patch the one that got caught.
  '';

  # Merge notification hooks (turn finished / waiting for input) into
  # ~/.claude/settings.json without letting nix own the file (so interactive
  # /model, /fast, etc. still persist).
  home.activation.claudeNotifyHooks =
    let
      notifyScript = pkgs.writeShellScript "hm-claude-notify" (
        ''
          input=$(cat)
          sid=$(${pkgs.jq}/bin/jq -r .session_id <<<"$input")
          cwd=$(${pkgs.jq}/bin/jq -r .cwd <<<"$input")
          msg=$(${pkgs.jq}/bin/jq -r '.message // "Needs your attention"' <<<"$input")
          # Session name via the live-session registry (undocumented internals);
          # fall back to the project directory name.
          name=$(${pkgs.jq}/bin/jq -rs --arg sid "$sid" \
            '[.[] | select(.sessionId == $sid) | .name] | first // empty' \
            "$HOME"/.claude/sessions/*.json 2>/dev/null)
          title="Claude Code - ''${name:-''${cwd##*/}}"
        ''
        + (
          if pkgs.stdenv.hostPlatform.isDarwin then
            ''
              # env vars sidestep AppleScript string escaping
              MSG="$msg" TITLE="$title" /usr/bin/osascript -e \
                'display notification (system attribute "MSG") with title (system attribute "TITLE") sound name "Glass"'

              # Mark the session's space in the bar; space.sh un-marks it on
              # focus. The nearest ancestor owning a yabai window is the
              # session's terminal window.
              command -v yabai >/dev/null && command -v sketchybar >/dev/null || exit 0
              windows=$(yabai -m query --windows)
              pid=$$ space=""
              while [ "$pid" -gt 1 ] 2>/dev/null; do
                space=$(${pkgs.jq}/bin/jq -r --argjson pid "$pid" \
                  '[.[] | select(.pid == $pid) | .space] | first // empty' <<<"$windows")
                [ -z "$space" ] || break
                pid=$(ps -o ppid= -p "$pid" | tr -d ' ')
              done
              focused=$(yabai -m query --spaces --space | ${pkgs.jq}/bin/jq -r .index)
              if [ -n "$space" ] && [ "$space" != "$focused" ]; then
                sketchybar --set "space.$space" icon.color=${osConfig.palette.ORANGE} 2>/dev/null || true
              fi
            ''
          else
            ''
              ${pkgs.libnotify}/bin/notify-send "$title" "$msg"
              ${pkgs.libcanberra-gtk3}/bin/canberra-gtk-play -f ${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/complete.oga
            ''
        )
      );
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ]
      # bash
      ''
        settings="$HOME/.claude/settings.json"
        ${pkgs.coreutils}/bin/mkdir -p "$HOME/.claude"
        [ -s "$settings" ] || echo '{}' > "$settings"

        cmd=${notifyScript}
        new=$(${pkgs.jq}/bin/jq --arg cmd "$cmd" '
          .hooks.Stop |= [ { hooks: [ { type: "command", command: $cmd } ] } ]
          | .hooks.Notification |= [ { hooks: [ { type: "command", command: $cmd } ] } ]
        ' "$settings" 2>/dev/null) || {
          echo "claude-code: settings.json is not valid JSON, skipping hook patch" >&2
          new=""
        }

        if [ -n "$new" ] && [ "$new" != "$(${pkgs.coreutils}/bin/cat "$settings")" ]; then
          printf '%s\n' "$new" > "$settings"
        fi
      '';

  # Statusline showing Claude's cwd + git branch, patched into settings.json
  # the same way as the notify hooks above.
  home.activation.claudeStatusLine =
    let
      statusLineScript = pkgs.writeShellScript "hm-claude-statusline" ''
        input=$(cat)
        dir=$(${pkgs.jq}/bin/jq -r '.workspace.current_dir // .cwd' <<<"$input")
        branch=$(${pkgs.git}/bin/git -C "$dir" branch --show-current 2>/dev/null)
        case "$dir" in
          "$HOME") dir="~" ;;
          "$HOME"/*) dir="~''${dir#"$HOME"}" ;;
        esac
        if [ -n "$branch" ]; then
          printf '%s ⎇ %s\n' "$dir" "$branch"
        else
          printf '%s\n' "$dir"
        fi
      '';
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ]
      # bash
      ''
        settings="$HOME/.claude/settings.json"
        ${pkgs.coreutils}/bin/mkdir -p "$HOME/.claude"
        [ -s "$settings" ] || echo '{}' > "$settings"

        cmd=${statusLineScript}
        new=$(${pkgs.jq}/bin/jq --arg cmd "$cmd" '
          .statusLine = { type: "command", command: $cmd }
        ' "$settings" 2>/dev/null) || {
          echo "claude-code: settings.json is not valid JSON, skipping statusline patch" >&2
          new=""
        }

        if [ -n "$new" ] && [ "$new" != "$(${pkgs.coreutils}/bin/cat "$settings")" ]; then
          printf '%s\n' "$new" > "$settings"
        fi
      '';
}
