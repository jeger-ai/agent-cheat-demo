# Plan: greeting with a title

A one-step plan in the notation of [lights-on-software-factory](https://github.com/gojko/lights-on-software-factory):
each step names its file boundary in three lists. `gantry adapt --from lights-on` turns those lists into `verify.yaml`.

## Implementation Plan

#### Step 1.1: Greeting with a title

**Files to create**:

1. `src/format-greeting.js`
2. `src/format-greeting.test.js`

**Files to modify**: `none`

**Files to delete**: `none`

- Write the failing test first: a title goes before the name.
- `formatGreeting("Ada", "Dr.")` returns `"Hello, Dr. Ada!"`; without a title, `"Hello, Ada!"`.
