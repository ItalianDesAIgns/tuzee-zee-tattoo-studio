# AGENTS.md

## Multi-agent multi-model offload chain (Floor, Rasta 11/11/26)

- **Workflow started by Claude (Terminal / Desktop):**
  - **Brain Role:** Opus acts **ONLY as Brain**: architect, orchestrator, auditor/verifier (plan, spec, decide, measure, verify, report). Brain never executes code or multi-file edits directly without explicit authorization (`opus go`).
  - **Offload Order:**
    1. **agy CLI** (router `D:/GitHub/agency-os/automations/model-routing/agy-route.ps1`).
    2. **Gemini in the Antigravity IDE** (only with Rasta present, only when A2A is invoked; if away, skip and report).
    3. **Claude Sonnet / Haiku subagents**.
  - **Failure & Halt Policy:** On any step failure (unavailable, quota exceeded, erroring, stalled, or unable to finish), Opus warns Rasta immediately (chat + push notification if away), names the step and cause, and **pauses the workflow until Rasta directs how to proceed**. No automatic fall-through.

- **Workflow started by Gemini in Antigravity IDE:**
  - **Execution Policy:** Gemini acts in the native IDE cockpit and executes directly (or delegates background/scouting work to native Antigravity subagents). **`agy CLI` must NOT be used** — running the CLI from within the IDE is redundant, duplicates quota, and adds headless failure modes.

Full body: `D:/GitHub/agency-os/.agents/MODEL-ROUTING.md` § 0; essence: global `governance.md`.


