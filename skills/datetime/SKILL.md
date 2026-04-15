---
name: datetime
description: Use this skill whenever the user asks for the current date, time, day of the week, timezone, Unix timestamp, or anything that requires knowing "now" (e.g. "what day is it", "what time is it", "how many days until X", "is it still Monday"). Claude does not have built-in access to the wall clock, so this skill fetches the real current date/time by running the system `date` command.
---

# datetime

Claude has no built-in knowledge of the current date or time — its training
data has a cutoff, and any date it "remembers" is either stale or injected by
the harness. Whenever the user's request depends on the real "now", use this
skill to fetch the authoritative value from the operating system.

## When to use

Trigger this skill for any request like:

- "What is today's date?" / "What day of the week is it?"
- "What time is it?" / "What's the current time in UTC?"
- "How many days until <event>?" / "How old is <something> as of today?"
- "Give me a timestamp for the filename/log entry."
- Any calculation that needs the current date/time as an input.

Do **not** guess or rely on a date mentioned earlier in the conversation
unless the user explicitly asked you to use that date.

## How to use

Run the helper script with the Bash tool. It prints a small, structured block
with the local time, UTC time, Unix timestamp, weekday, and timezone:

```bash
bash skills/datetime/scripts/get_datetime.sh
```

If you only need one specific field, you can call `date` directly instead of
the helper:

| Need | Command |
| --- | --- |
| Local date + time | `date "+%Y-%m-%d %H:%M:%S %Z"` |
| UTC date + time | `date -u "+%Y-%m-%d %H:%M:%S UTC"` |
| ISO 8601 (local) | `date "+%Y-%m-%dT%H:%M:%S%z"` |
| Unix timestamp | `date +%s` |
| Day of the week | `date "+%A"` |
| Today's date only | `date "+%Y-%m-%d"` |

## After fetching

1. Read the command output and use it directly in your answer.
2. For "days until" / "days since" questions, do the arithmetic yourself from
   the fetched date — do not ask the user to confirm what today is.
3. If the user specifies a timezone that differs from the system's, convert
   using `TZ=<zone> date ...`, for example:
   ```bash
   TZ=America/Los_Angeles date "+%Y-%m-%d %H:%M:%S %Z"
   TZ=Asia/Kolkata       date "+%Y-%m-%d %H:%M:%S %Z"
   ```

## Notes

- The helper script is a thin wrapper around `date`; it does not call the
  network and has no side effects, so it is safe to run at any time.
- If `bash` or `date` is unavailable (extremely rare), fall back to whatever
  datetime facility the environment exposes and tell the user what source you
  used.
