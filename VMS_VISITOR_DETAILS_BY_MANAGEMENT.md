# VmsVisitorDetailsByManagement

Visitor details raised by the **logged-in management user**, for a date range.

File: **`lib/services/VmsVisitorDetailsByManagement.dart`**
Class: **`VmsVisitorDetailsByManagementRepo`**

---

## 1. Endpoint

```
POST https://upegov.in/VistorManagementSystemApis/Api/VmsVisitorDetailsByManagement/VmsVisitorDetailsByManagement
Content-Type: application/json
```

The host comes from `BaseRepo().baseurl` — never hard-code it in the repo.

---

## 2. Request body

```json
{
  "dFromDate": "28/Jul/2026",
  "dToDate":   "28/Jul/2026",
  "iUserId":   "5"
}
```

| Field | Source | Notes |
|-------|--------|-------|
| `dFromDate` | `fromDate` param, defaults to **today** | `dd/MMM/yyyy` via `DateFormat('dd/MMM/yyyy')` — e.g. `28/Jul/2026`. Not ISO. |
| `dToDate` | `toDate` param, defaults to **today** | Same format. |
| `iUserId` | `SharedPreferences` key **`iUserId`** | Saved at login by `login_screen.dart`. Falls back to `"0"` if missing. |

> The month/short-name format is what this backend expects. Sending
> `2026-07-28` returns an empty `Data` array, not an error — so a wrong format
> looks like "no records" rather than a failure.

---

## 3. Response

```json
{
  "Result": "1",
  "Msg": "Success",
  "Data": [
    {
      "sQRCodeVal":  "493893",
      "dDate":       "2026-07-28",
      "dTime":       "15:58:00",
      "iValidHours": "8 Hour(s)",
      "sNote":       "Hello Gust",
      "sUserName":   "Jitender Wadhawan",
      "dRequiredAt": "28/Jul/2026 15:58",
      "sStatus":     "Checked In",
      "sGuestNames": "Amit Sharma, Priya Nair"
    }
  ]
}
```

Note the asymmetry: **`dDate` comes back as `2026-07-28`** (ISO) even though
**`dFromDate` is sent as `28/Jul/2026`**. `dRequiredAt` uses the sent format.

---

## 4. Model

Rows map to the existing **`GuardVisitor`** model
(`lib/models/guard_visitor.dart`) — its 9 fields match this payload exactly,
so no new model was added. `GuardVisitor.fromJson` string-coerces every value
(`'${j['sQRCodeVal'] ?? ''}'`), so numeric-vs-string drift from the backend
won't throw.

| JSON | `GuardVisitor` |
|------|----------------|
| `sQRCodeVal` | `qrCodeVal` |
| `dDate` | `date` |
| `dTime` | `time` |
| `iValidHours` | `validHours` |
| `sNote` | `note` |
| `sUserName` | `userName` |
| `dRequiredAt` | `requiredAt` |
| `sStatus` | `status` |
| `sGuestNames` | `guestNames` |

Shared with `VMSGaurdVisitorRequestList`, `...ListMonth` and
`...ListYesterday` — a field added here must stay compatible with those.

---

## 5. Usage

```dart
// Today (both dates default to DateTime.now())
final rows = await VmsVisitorDetailsByManagementRepo()
    .getVisitorDetails(context);

// Explicit range
final rows = await VmsVisitorDetailsByManagementRepo().getVisitorDetails(
  context,
  fromDate: DateTime(2026, 7, 1),
  toDate:   DateTime(2026, 7, 31),
);
```

Returns `Future<List<GuardVisitor>>`.

---

## 6. Behaviour

- **`showLoader()` / `hideLoader()`** wrap the call, so the global EasyLoading
  spinner shows automatically — the caller does not add its own.
- **`Result != "1"`, or a non-200 status → `[]`** (empty list), *not* an
  exception. A caller cannot distinguish "no visitors today" from "server
  said no" — check the console log if that matters.
- **Network / parse errors `rethrow`** after `hideLoader()`, so the caller
  must wrap in `try/catch` to show an error state. See `_load()` in
  `month_guest_list_screen.dart` for the established pattern.
- Every step prints to console (`----VisitorDetailsByMgmt ...`), including the
  resolved `iUserId`, matching the other repos in `lib/services/`.
