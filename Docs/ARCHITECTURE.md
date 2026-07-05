# Architecture

## Design principles

1. **Read-only first:** collection modules must not modify system state.
2. **Least privilege:** normal user execution is preferred; elevation is requested only where necessary.
3. **Structured data:** functions return PowerShell objects, not only formatted text.
4. **Separation of concerns:** collection, display, reporting, and future repair logic remain separate.
5. **Auditability:** actions and errors are timestamped in local logs.
6. **Evidence integrity:** exported report files receive SHA-256 hashes.
7. **Graceful degradation:** unavailable cmdlets or unsupported hardware should produce a clear status rather than crash the toolkit.

## Module responsibilities

| Module | Responsibility |
|---|---|
| `WETT.Core` | Initialization, logging, safety wrapper, context, learning mode |
| `WETT.System` | OS, hardware, uptime, disk, and graphics inventory |
| `WETT.Network` | Interfaces, addressing, routes, DNS, connectivity, TCP sessions |
| `WETT.Security` | Endpoint security posture and local privilege review |
| `WETT.Reporting` | Aggregation, HTML/JSON output, hashes, report directories |

## Future trust boundaries

Repair commands must never be added to the read-only collection modules. They will live in `WETT.Repair.psm1`, require an explicit admin check and confirmation, and record pre-change and post-change state.
