# Tomasulo Preparation Notes

## What Exists Now

Phase 16 provides a standalone scoreboard/readiness model with:

- per-thread busy bits and producer tags
- reservation-station-like entries
- source ready bits
- matching-tag broadcast wakeup
- entry-capacity stalls

## What Still Does Not Exist

The project does not yet implement:

- out-of-order functional-unit issue
- common-data-bus arbitration among multiple completing units
- physical-register allocation or a renaming free list
- reorder-buffer allocation, retirement, or recovery
- load/store ordering or a load/store queue
- speculative commit or precise exceptions

## Why The Separation Matters

Readiness and commit are different problems. A younger instruction can become
ready before an older one without being allowed to update architectural state
first. The Phase 16 model exposes readiness behavior while keeping the proven
CPU paths unchanged. A later Tomasulo-style experiment can build on these
structures deliberately.

## Memory Hook

A delayed load can eventually be modeled as a producer that broadcasts only
after the cache or memory response arrives. Consumers then remain not-ready
until the load's tag broadcasts. Phase 16 leaves this as a documented extension
rather than adding an incomplete load/store queue.
