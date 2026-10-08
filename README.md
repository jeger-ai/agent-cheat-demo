# agent-cheat-demo

A tiny repo for one demo: a coding agent hits a red build and "fixes" it by tampering with CI,
the pre-commit hook and `.env`. [`gantry cage`](https://github.com/jeger-ai/opengantry) puts those
files back after the agent exits.

The agent here is **simulated**. [`rogue-agent.sh`](rogue-agent.sh) is a plain shell script that
replays shortcuts coding agents take on a failing build. No LLM is involved, so the demo is the
same every time.

## Run it

```bash
git clone https://github.com/jeger-ai/agent-cheat-demo && cd agent-cheat-demo
./demo.sh
```

`demo.sh` runs `./setup.sh` (writes a fake `.env` and a pre-commit hook that runs the tests), then:

```bash
npx -p @jeger-ai/opengantry gantry cage -- ./rogue-agent.sh
```

The simulated agent:

| Tampering | Cage after exit |
|-----------|-----------------|
| Appends `continue-on-error: true` to `.github/workflows/ci.yml` | restored |
| Rewrites `.git/hooks/pre-commit` to `exit 0` | restored (mode `0755` too) |
| Swaps the key in `.env` | restored |
| Bumps `package-lock.json` | reported, **kept** (package managers rewrite lockfiles legitimately) |

Cage exits `3` because protected files were reverted. Its report lists paths and SHA-256 digests,
never file contents.

## What cage does not do

- It restores files **after** the agent exits; it doesn't block writes while the agent runs.
- It doesn't see reads: an agent can still read `.env`.
- It doesn't see network or API calls.
- It doesn't protect tests: deleting or weakening `test/price.test.js` is not caught.

## Use it on your own agent

```bash
npm install -g @jeger-ai/opengantry
alias claude='gantry cage -- claude'
alias aider='gantry cage -- aider'
```

The bug in `src/price.js` (the discount is applied twice) is deliberate: it's what makes the build
red. The honest fix is one line.
