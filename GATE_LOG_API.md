# Gate Log — role-split API

The **Gate Log** card (dashboard tile #2) opens one screen that talks to **two
different endpoints**, chosen by the logged-in `iUserType`.

| File | Role |
|------|------|
| `lib/models/gate_entry.dart` | `GateEntry` model + `GateDecision` enum |
| `lib/services/GateEntryRepo.dart` | picks the endpoint, calls it, parses `Data` |
| `lib/screens/gate_log_screen.dart` | one UI, two footers |

---

## 1. The split

`iUserType` and `iUserId` are both read from **SharedPreferences**, saved at
login by `login_screen.dart`.

| `iUserType` | Role | Endpoint | Card footer |
|---|---|---|---|
| `"1"` | **Guard** | `VisitorEntryByGaurd/VisitorEntryByGaurd` | read-only **`sAppRejStatus`** chip |
| anything else (`"2"`, `""`, …) | **Management** | `EntryByGaurd/EntryByGaurd` | **Approve** / **Reject** buttons |

> The default is *management*, not guard. Only the exact string `"1"` counts as
> a guard, so a missing or unexpected `iUserType` never hides management's
> controls by accident.

---

## 2. Request

Identical for both roles — only the URL differs:

```
POST https://upegov.in/VistorManagementSystemApis/Api/<endpoint>
Content-Type: application/json

{ "iUserId": "1" }
```

The host comes from `BaseRepo().baseurl`. `iUserId` falls back to `"0"` when
the pref is missing.

---

## 3. Response

Both endpoints return the same shape:

```json
{
  "Result": "1",
  "Msg": "Success",
  "Data": [
    {
      "sQRCodeVal":    "678249",
      "dDate":         "2026-07-29",
      "dTime":         "09:37:00",
      "iValidHours":   "8 Hour(s)",
      "sNote":         "weCome",
      "sUserName":     "Pramod",
      "dRequiredAt":   "29/Jul/2026 09:37",
      "sStatus":       "Pending",
      "sGuestNames":   "Ali",
      "sAppRejStatus": "Approved"
    }
  ]
}
```

Because the shapes match, **one model and one screen serve both roles** — only
the URL and the card footer change.

---

## 4. Model — `GateEntry`

| JSON | Field | Notes |
|------|-------|-------|
| `sQRCodeVal` | `qrCodeVal` | |
| `dDate` | `date` | ISO, e.g. `2026-07-29` |
| `dTime` | `time` | `09:37:00` |
| `iValidHours` | `validHours` | `"8 Hour(s)"` — already a display string |
| `sNote` | `note` | row hidden when empty |
| `sUserName` | `userName` | shown as **RequestedBy** |
| `dRequiredAt` | `requiredAt` | parsed nowhere yet; kept for completeness |
| `sStatus` | `status` | search only — the footer uses `sAppRejStatus` |
| `sGuestNames` | `guestNames` | comma list → `primaryName` + `plus` |
| `sAppRejStatus` | `decision` | → `GateDecision` |

Every value is string-coerced in `fromJson` (`'${j['sQRCodeVal'] ?? ''}'`), so
a numeric `sQRCodeVal` from the backend won't throw.

### Display helpers

- `primaryName` → `"Ali"` (first of `sGuestNames`)
- `plus` → `1` when `sGuestNames` holds 2 names → renders `Ali  +1`
- `when` → `"Today · 9:37 AM"`, falling back to `Tomorrow` / `Yesterday` /
  `29 Jul 2026`, and to the raw strings if the date won't parse
- `searchText` → guest names + user + note + QR + status

### `GateDecision`

`sAppRejStatus` → `approved` / `rejected` / `pending`, case- and
separator-insensitive (`"Approved"`, `"approved"`, `"REJECTED"` all work).
**Unknown values fall back to `pending`**, so a new server status renders as an
amber chip instead of crashing.

---

## 5. Console output

Every call prints a labelled block, so it is obvious *which* endpoint ran:

```
==================== GATE LOG [MANAGEMENT] ====================
---- iUserType (SharedPreferences) ----> 2
---- iUserId   (SharedPreferences) ----> 1
---- URL  ----> https://upegov.in/.../EntryByGaurd/EntryByGaurd
---- BODY ----> {iUserId: 1}
---- STATUS ----> 200
---- RESPONSE ----> {Result: 1, Msg: Success, Data: [...]}
---- PARSED ROWS ----> 1
=========================================================
```

The guard run is identical but reads `[GUARD]` and hits
`VisitorEntryByGaurd/VisitorEntryByGaurd`.

---

## 6. Behaviour

- `showLoader()` / `hideLoader()` wrap the call — the screen adds no spinner of
  its own beyond the initial load state.
- **`Result != "1"` or a non-200 → `[]`**, not an exception. The screen then
  shows **"No Data"**, so a server "no" and a genuinely empty day look the
  same. The console block distinguishes them.
- Network / parse failures `rethrow`, and the screen shows a **Retry** message
  — deliberately distinct from "No Data" so a dead network isn't mistaken for
  an empty gate log.

---

## 7. Known gap

On the management side, **Approve / Reject only change local state.** There is
no update endpoint wired here yet — tapping a button repaints the card but
sends nothing, and the change is lost on reload. `_setDecision()` in
`gate_log_screen.dart` is the single place to add that call once the endpoint
exists (`VMSGaurdUpdateStatus` is the closest existing analogue).

Tapping the already-selected decision returns the row to **pending**, so a
mis-tap is recoverable.
