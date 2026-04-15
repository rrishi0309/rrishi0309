# Chronos

**Real-time date and time awareness for Claude.**

Chronos is a lightweight Claude skill that gives Claude reliable access to the
current date, time, weekday, Unix timestamp, and timezone by wrapping the
operating system's `date(1)` command. Because Claude has no built-in wall
clock — its training data has a cutoff, and session-injected dates are not
always present or correct — Chronos ensures Claude answers time-sensitive
questions ("what day is it?", "how many days until…?", "what time is it in
Tokyo?") from an authoritative source instead of guessing.

---

## Table of contents

- [Why this exists](#why-this-exists)
- [Features](#features)
- [How it works](#how-it-works)
- [Installation](#installation)
- [Usage](#usage)
- [Output reference](#output-reference)
- [`date` cheatsheet](#date-cheatsheet)
- [Project layout](#project-layout)
- [Requirements](#requirements)
- [Security and privacy](#security-and-privacy)
- [FAQ](#faq)
- [Contributing](#contributing)
- [License](#license)

---

## Why this exists

Claude's knowledge has a training cutoff. Even when a harness injects a
"current date" into the system prompt, Claude frequently needs the *real* now
for requests such as:

- Answering the literal question: "What is today's date?" / "What day is it?"
- Computing durations relative to the present: "How many days until launch?",
  "How old is this record as of today?"
- Stamping filenames, log lines, release notes, or commit messages.
- Converting between timezones on demand.
- Deciding whether a deadline has already passed.

Relying on a guess — or on a date the model half-remembers from training —
produces wrong answers delivered with high confidence. Chronos eliminates
that failure mode by having Claude run a single, deterministic shell command
and use its output directly.

---

## Features

- **Zero dependencies.** Uses only `bash` and the standard Unix `date`
  command. No network calls, no API keys, no package installs.
- **Structured output.** One `key=value` per line — easy for Claude to parse
  and easy for a human to eyeball.
- **Multiple formats in a single call.** Local ISO-8601, human-readable
  local, UTC ISO-8601, human-readable UTC, weekday, Unix timestamp, timezone
  abbreviation, and numeric UTC offset are all returned together.
- **Timezone overrides.** Accepts any IANA zone (`America/Los_Angeles`,
  `Asia/Kolkata`, `Europe/London`, `UTC`, …) as a CLI argument.
- **Progressive disclosure.** `SKILL.md` stays small so the system prompt
  footprint is minimal; Claude only reaches for the helper when a request
  actually needs the current time.
- **Safe to run anywhere.** Read-only, idempotent, side-effect-free, and
  auditable in a few dozen lines of shell.

---

## How it works

Claude skills are discovered via a `SKILL.md` file containing YAML
frontmatter. The frontmatter declares the skill's name and a description
telling Claude *when* to use it. When the conversation matches that trigger
— for example, a user asks "what's today's date?" — Claude loads the skill
body and follows its instructions.

For Chronos, those instructions are simple: run
`scripts/get_datetime.sh` via the Bash tool and use the output to answer.
The helper itself is a thin wrapper around `date(1)`. It runs in a few
milliseconds, prints a deterministic block of fields, and exits.

```
user ──▶ Claude ──▶ (matches "datetime" skill trigger)
                      │
                      ▼
              bash scripts/get_datetime.sh
                      │
                      ▼
              key=value output block
                      │
                      ▼
              Claude uses values in its reply
```

---

## Installation

Chronos can be installed three ways, depending on where you want it
available.

### Option A — clone the standalone repo

```bash
git clone https://github.com/rrishi0309/current_datetime_claude_skill.git
cd current_datetime_claude_skill
chmod +x scripts/get_datetime.sh
```

Point your Claude Code project at this directory, or copy its contents into
an existing project's `skills/datetime/` folder.

### Option B — drop into an existing project

From the root of the project where you want the skill available:

```bash
mkdir -p skills/datetime/scripts
cp /path/to/chronos/SKILL.md               skills/datetime/SKILL.md
cp /path/to/chronos/scripts/get_datetime.sh skills/datetime/scripts/
chmod +x skills/datetime/scripts/get_datetime.sh
```

### Option C — user-level install

To make Chronos available in every Claude Code session on your machine,
place it under your user-scope skills directory:

```bash
mkdir -p ~/.claude/skills/datetime/scripts
cp SKILL.md                ~/.claude/skills/datetime/SKILL.md
cp scripts/get_datetime.sh ~/.claude/skills/datetime/scripts/
chmod +x ~/.claude/skills/datetime/scripts/get_datetime.sh
```

No further configuration is required — Claude discovers the skill the next
time it starts a session in that scope.

---

## Usage

### Automatic invocation (intended)

Once installed, Claude invokes Chronos on its own whenever the conversation
needs a real timestamp. You do not have to call it by name. Phrase the
request naturally:

- "What day of the week is it?"
- "How many days until July 4?"
- "Timestamp a log line for right now."
- "What time is it in Berlin?"
- "Is the Q2 deadline still in the future?"

### Manual invocation

You can also run the helper directly from your shell for testing or
scripting purposes:

```bash
bash scripts/get_datetime.sh
```

Example output:

```
local_iso=2026-04-15T15:25:18-0700
local_human=2026-04-15 15:25:18 PDT
utc_iso=2026-04-15T22:25:18Z
utc_human=2026-04-15 22:25:18 UTC
weekday=Wednesday
unix_timestamp=1776291918
timezone_name=PDT
timezone_offset=-0700
```

### Timezone override

Pass an IANA zone name as the first argument to render the `local_*` fields
in that zone. The `utc_*` fields stay constant.

```bash
bash scripts/get_datetime.sh Asia/Kolkata
bash scripts/get_datetime.sh Europe/London
bash scripts/get_datetime.sh UTC
```

---

## Output reference

Every invocation prints the same eight fields, in the same order, one per
line:

| Field             | Description                                | Example                      |
| ----------------- | ------------------------------------------ | ---------------------------- |
| `local_iso`       | ISO-8601 timestamp with numeric offset     | `2026-04-15T15:25:18-0700`   |
| `local_human`     | Human-readable local time                  | `2026-04-15 15:25:18 PDT`    |
| `utc_iso`         | ISO-8601 timestamp in UTC (`Z` suffix)     | `2026-04-15T22:25:18Z`       |
| `utc_human`       | Human-readable UTC time                    | `2026-04-15 22:25:18 UTC`    |
| `weekday`         | Full English weekday name                  | `Wednesday`                  |
| `unix_timestamp`  | Seconds since the Unix epoch               | `1776291918`                 |
| `timezone_name`   | Short timezone abbreviation                | `PDT`                        |
| `timezone_offset` | UTC offset in `±HHMM`                      | `-0700`                      |

The output format is considered part of Chronos's public contract. New
fields may be added at the end in future versions, but existing keys will
not be renamed or reordered.

---

## `date` cheatsheet

If you only need one specific field and do not want the full helper output,
Claude (or you) can call `date(1)` directly:

| Need                   | Command                             |
| ---------------------- | ----------------------------------- |
| Today's date (YYYY-MM-DD) | `date +%F`                       |
| Local time (HH:MM:SS)  | `date +%T`                          |
| ISO-8601 local         | `date "+%Y-%m-%dT%H:%M:%S%z"`       |
| ISO-8601 UTC           | `date -u "+%Y-%m-%dT%H:%M:%SZ"`     |
| Unix timestamp         | `date +%s`                          |
| Day of the week        | `date +%A`                          |
| Time in another zone   | `TZ=Asia/Tokyo date`                |

---

## Project layout

As a standalone repository:

```
current_datetime_claude_skill/
├── README.md                this file
├── SKILL.md                 skill manifest Claude loads
└── scripts/
    └── get_datetime.sh      the helper script
```

When vendored into a larger project, the conventional location is
`skills/datetime/` at the target project's root:

```
your-project/
└── skills/
    └── datetime/
        ├── SKILL.md
        └── scripts/
            └── get_datetime.sh
```

---

## Requirements

- **Bash** 3.2 or newer. The script uses only portable constructs.
- **`date`** command. Both BSD (`date` on macOS) and GNU (`date` on most
  Linux distributions) implementations are supported; the format strings
  used are common to both.
- A Claude Code–compatible environment that can read `SKILL.md` and execute
  shell commands via the Bash tool.

No internet connection, package manager, external service, or elevated
privileges are required.

---

## Security and privacy

Chronos is intentionally minimal and transparent:

- **No network traffic.** The helper reads the local system clock only.
- **No filesystem writes.** It prints to standard output and exits.
- **No secrets or environment inspection.** The only environment variable it
  touches is `TZ`, and only when you pass a zone argument explicitly.
- **Fully auditable.** The entire implementation is a few dozen lines of
  shell with no dependencies to vet.

Caveat: if the underlying system clock is wrong — as can happen in
sandboxes, CI containers, or time-travel tests — Chronos will faithfully
report the wrong time. It has no way to independently verify the host
clock.

---

## FAQ

**Does Claude really need a skill for this? Can't it just run `date`?**
It can, but without a skill describing *when* to reach for a live clock,
Claude sometimes falls back on an assumed date from its context instead. A
named skill with an explicit trigger description makes the decision
deterministic and discoverable.

**Why `key=value` lines instead of JSON?**
`key=value` is trivially readable, needs no parser, and stays useful even
when Claude only glances at the output. JSON adds parsing overhead for zero
benefit at this payload size.

**Will this work on Windows?**
Yes, when run from Git Bash, WSL, or any POSIX-compatible shell. A native
PowerShell port is straightforward if needed.

**Can I use the helper outside Claude Code?**
Yes. `scripts/get_datetime.sh` is a standalone utility and can be invoked
from any script, CI job, or terminal that wants a consistent, machine-
readable timestamp block.

**How do I change the set of fields returned?**
Edit `scripts/get_datetime.sh` and add new `key=value` lines to the
heredoc. Prefer appending new keys to renaming existing ones so downstream
consumers remain compatible.

---

## Contributing

Issues and pull requests are welcome. When extending Chronos, please keep:

- **Zero runtime dependencies.** Shell and `date(1)` only.
- **Stable, backwards-compatible output.** Append new keys rather than
  renaming existing ones.
- **POSIX-shell-clean code** where practical, so the script runs on both
  BSD and GNU userlands.
- **Documentation in lockstep with behavior.** Updates to the script should
  come with corresponding updates to `SKILL.md` and this README.

---

## License

Released under the MIT License.
