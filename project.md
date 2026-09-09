# On Go — project state

Where the project actually stands, as distinct from how it is put together.

- **[README.md](README.md)** — what On Go is, and how to run it.
- **[ARCHITECTURE.md](ARCHITECTURE.md)** — how the pieces fit, and the rules
  that keep them apart. Read that before changing anything that crosses
  between the two applications.
- **This file** — what is built, what is deliberately stubbed, what is missing,
  and what is known to be wrong.

Keep it honest. A status document that flatters the project is worse than none,
because the next person plans against it.

---

## In one line

Two Flutter front ends and a shared contract are built and working against
in-memory data. The backend that would connect them is scaffolded but has no
routes, so the two applications cannot yet see each other.

| Part | State |
| --- | --- |
| `/lib` — mobile app (Client + Mechanic) | Working, in-memory |
| `/admin_web` — console (Admin + Moderator) | Working, in-memory |
| `/packages/on_go_shared` — API contract | Complete for what exists |
| `/packages/on_go_design` — design system | Complete, 4 theme families |
| `/server` — backend | Schema + infrastructure only, **no routes** |

---

## What works

### Mobile app — Client

Request help (with photos, location and an urgency that sets the completion
deadline), compare mechanic quotes, accept one, follow the job through to
payment by QR, rate the mechanic, and read service history. A notification bell
covers quote received, job accepted, work started and payment due.

### Mobile app — Mechanic

Browse and quote available jobs, accept emergencies outright, drive a job
through navigation → arrival → work → completion, take payment, and see
earnings and leaderboard standing. A notification bell covers quote accepted,
rating received, payment received, emergency posted and account approved. The
Emergency filter pulses when unviewed emergency jobs are waiting, with a
per-mechanic toggle in Settings.

Registration is a five-step flow that files an account request for moderation.

### Console — Admin

Overview, moderator roster with per-permission control, Add Moderator, Audit
Log, Notifications (escalations), Income and Settings. The Audit Log records
both roster changes and queue decisions, filters by the role that performed the
action, and opens any entry for its full detail including the originating IP
address.

### Console — Moderator

Verification queue, decision history, accounts, profile and settings, gated by
the permissions their admin granted.

### Shared

Eight themes in four light/dark families (Classic, Calm Blue, Ember, Forest),
with Dark Mode, Dynamic Themes (follows the clock) and a continuous Warm
Filter. Both front ends build their own `ThemeData` from the same palettes.

---

## What is deliberately stubbed

These are **not** bugs. Each is a local implementation refusing work that is
not its surface's to do, and each disappears when `configure()` is handed a
real client. See *The seam* in [ARCHITECTURE.md](ARCHITECTURE.md).

| Refuses | Why |
| --- | --- |
| Mobile `LocalVerificationService.decide()` | A phone must not approve its own owner's account |
| Console `LocalRevenueService.reportCompletedPayment()` | Only a completed client payment books revenue |
| Mobile `LocalAppearanceService.publishBackground()` | Branding is set in the console |
| Console `LocalVerificationService.submit()` | Registrations are filed from the app |

The visible consequences, all of which are correct for two disconnected apps:

- A registration filed on a phone stays **Pending** — no moderator can reach
  it. `demo-mechanic` is the local shortcut past that.
- The console's queue, accounts list and revenue ledger start **empty**.
- A background photo published in the console lives **in that browser only**.

---

## What is missing

### The backend — the one thing blocking everything else

`/server` has the parts that are hard to retrofit and none of the part that is
merely laborious:

- **Present:** Postgres schema (3 migrations), least-privilege roles, password
  hashing, token issue/verify, connection pool, structured logging, audit
  logging, error types, secret loading.
- **Absent:** every route. `server/src/routes/` and `server/src/plugins/` are
  empty directories. Nothing in `/server` reads or writes a row yet.

Until routes exist, `packages/on_go_shared` is a contract with two clients and
no server.

### Test coverage

- `/admin_web` — 30 tests (`console_layout_test.dart`, `console_theme_test.dart`)
  covering responsive layout classification and the shared theme registry.
- `/lib` — **none.** The mobile app has no test directory. It previously had
  `test/widget_test.dart` covering the sign-in shortcuts; that was deleted when
  the demo buttons were removed and never replaced.
- `/packages` — no tests of their own; the design system is exercised through
  the console's theme tests.

This is the largest gap after the backend. The stores in `lib/data/` are pure
Dart singletons with no Flutter dependency and would be cheap to cover.

### Persistence

Everything on the mobile side is in memory and dies with the process, except
what `shared_preferences` holds: the selected theme, dark mode, dynamic themes,
the warm filter level, the auth background photo, and the mechanic's emergency
alert toggle.

---

## Known issues

**A brand-coloured "denied" state.** Two places assume the brand colour is red
and use it to mean negative:

- `admin_web/lib/src/widgets/console_widgets.dart` — a withheld permission
  draws its disc in `ConsoleColors.brand`.
- `lib/widgets/change_password_dialog.dart` — error text uses
  `AppColors.primary`.

Under any theme whose brand is not red — Calm Blue, Ember, Forest — a denied
permission reads as granted and an error reads as neutral. One word each
(`brand` → `danger`, `primary` → `error`).

**Moderator activity is recorded twice.** A queue decision writes both a
`ModerationActivity` and an `AuditEntry`. The audit log is what the console now
shows; `ModerationActivity` is still written and still exposed by
`watchActivity()`, but nothing surfaces it. Retiring it is a clean-up, not a
fix.

**`debugSeedRequest`.** `LocalVerificationService` carries a test-only method to
put a request in the queue, because `submit()` is refused from the console and
there is otherwise no way to exercise `decide()` locally. It is not on the API
interface and no screen calls it. It should go when the backend can supply real
requests.

---

## Conventions worth knowing

**One seam per app.** `MobileBackend.instance` and `ConsoleBackend.instance` are
the only places a call leaves an application. Do not reach around them.

**No screen defines a colour.** Read `AppColors` (mobile) or `ConsoleColors`
(console); both resolve from the palette in `on_go_design`. Adding a theme is
one `AppThemeOption` appended to `AppThemes.all` — the pickers build themselves
from that list, and a family needs exactly one light and one dark member.

**Stores are singleton `ChangeNotifier`s.** `Something.instance`, listened to by
screens. Anything persisted follows `ThemeController`'s shape: `load()` before
`runApp`, and a failed read leaves the default rather than blocking startup.

**Subscribe in `initState`, not in `build`.** The console shell swaps
arrangements when the window crosses a breakpoint, which re-inflates the page
body. A `StreamBuilder` built in a `build` that does not re-run will listen
twice to the same stream. `LiveValue` now hands out multi-subscription streams
so this cannot crash, but holding the subscription in state is still correct.

**The pricing rule.** `settledPaymentAmount()` is the single answer to "what did
this job cost", on both sides. History reads the payment record stamped at
payment time, never a quote — an emergency job's accept record carries no real
price, because the amount is agreed in person afterwards.

---

## If you are picking this up

1. Read [ARCHITECTURE.md](ARCHITECTURE.md), particularly *The seam* and
   *Adding an operation*.
2. Run both applications (see [README.md](README.md)). Sign in on the app as
   `client` and `demo-mechanic`; sign in on the console as `admin` and create
   the first moderator.
3. The highest-value work, in order: **routes in `/server`**, then **tests for
   `lib/data/`**, then the two known-issue one-liners above.
