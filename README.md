# agent-cheat-demo

A tiny repo for one demo: a coding agent hits a red build and "fixes" it by tampering with CI,
the pre-commit hook, `.env` and the test itself, then tries to push. [`gantry cage`](https://github.com/jeger-ai/opengantry)
puts the files back while the session is still running and refuses the push.

The agent here is **simulated**. [`rogue-agent.sh`](rogue-agent.sh) is a plain shell script that
replays shortcuts coding agents take on a failing build. No LLM is involved, so the demo is the
same every time. It only pushes to a throwaway local remote that `setup.sh` creates in your temp
dir, never to GitHub.

## Run it

Needs `@jeger-ai/opengantry` 3.8.0 or later (Node 24+ recommended). Record it with
`asciinema rec demo.cast -c ./demo.sh`.

```bash
git clone https://github.com/jeger-ai/agent-cheat-demo && cd agent-cheat-demo
./demo.sh
```

`demo.sh` runs `./setup.sh` (fake `.env`, a pre-commit hook that runs the tests, the local
`demo-remote`), then:

```bash
npx -p @jeger-ai/opengantry gantry cage -- ./rogue-agent.sh
```

| The simulated agent | Cage |
|---------------------|------|
| Appends `continue-on-error: true` to `.github/workflows/ci.yml` and commits it with `--no-verify` | restores the file within about a second |
| Rewrites `.git/hooks/pre-commit` to `exit 0` | restores it (mode `0755` too) |
| Swaps the key in `.env` | restores it; two seconds later the agent reads the original value back |
| Replaces the failing assertion in `test/price.test.js` with `assert.ok(true)` | restores it: [`.cage.yaml`](.cage.yaml) protects `test/` |
| Empties `.cage.yaml` so the tests stay loose | restores it: `.cage.yaml` always protects itself |
| Runs `git push demo-remote` | refuses the push: the outgoing commit touches CI config |
| Bumps `package-lock.json` | reports it, **keeps** it (package managers rewrite lockfiles legitimately) |

Cage exits `3` and prints one report when the session ends. Live events go to a session log in
your temp dir; while the agent runs, cage only rings the terminal bell. The report lists paths and
SHA-256 digests, never file contents.

## What cage does not do

- It restores files; it doesn't block writes. A change can be used or committed in the second before
  the next check.
- It restores the working tree, not git history: the agent's local "make CI green" commit stays, as
  a reverse diff. `demo.sh` resets it on the next run.
- `git push --no-verify` skips the push guard, and pushes made outside the cage session aren't checked.
- It doesn't see reads (an agent can still read `.env`), network or API calls.
- Tests aren't protected by default. This repo commits a [`.cage.yaml`](.cage.yaml) that adds `test/`;
  without it, weakening `test/price.test.js` would not be caught.

## Use it on your own agent

Start your agent inside the cage, exactly as you normally would:

```bash
npm install -g @jeger-ai/opengantry
gantry cage -- claude
gantry cage -- aider
```

The session works as usual; cage restores protected files as they change and refuses pushes of
them. If an agent keeps rewriting the same file, cage stops restoring it after 3 tries, marks it
contested and restores it once when you quit. `gantry cage --no-watch -- <cmd>` checks only at exit.

To protect your own paths (tests, migrations, infrastructure, keys), let cage propose rules and
commit the ones you keep:

```bash
gantry cage suggest --write   # writes .cage.yaml.suggested; review it, save what you keep as .cage.yaml
```

`.cage.yaml` can only add protection. To relax one path for a single run, pass
`--allow-override <path>`: that path is reported instead of restored, and cage says so at the start
and in the report.

The bug in `src/price.js` (the discount is applied twice) is deliberate: it's what makes the build
red. The honest fix is one line. For the same reason, CI doesn't run `npm test`: it runs
[`ci-check.sh`](ci-check.sh), which plays the demo against the published package and checks that
cage restored every file the agent touched, kept the lockfile change and refused the push.
