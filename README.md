# On Go

Roadside mechanic services. The product ships as **two applications**:

| | | |
| --- | --- | --- |
| **Mobile app** | `/lib` | Client + Mechanic — Flutter, Android/iOS |
| **Admin console** | `/admin_web` | Admin + Moderator — Flutter web |

They share no code except `/packages/on_go_shared`, which holds the models and
API contracts they exchange. They will meet at a backend that implements those
contracts; that backend is not built yet.

**Read [ARCHITECTURE.md](ARCHITECTURE.md)** before changing anything that
crosses between them.

## Running

The mobile app, from the repository root:

```bash
flutter run
```

Sign in with `client`, `mechanic`, `demo-client` or `demo-mechanic`, or with an
account registered in that session. Admin and Moderator are not in the app —
they sign in on the console.

The admin console:

```bash
cd admin_web && flutter run -d chrome
```

Sign in as `admin` to create the first moderator account. Moderators then sign
in with the email and password their admin set.

## Layout

```
lib/                      Mobile app (Client + Mechanic)
  data/                     In-memory stores
  screens/                  Client and Mechanic UI
  services/backend/         ← everything that will become a network call
  theme/  widgets/

admin_web/                Admin console website (Admin + Moderator)
  lib/src/app/              Routing and the console shell
  lib/src/backend/          ← everything that will become a network call
  lib/src/features/         Admin, Moderator and shared pages
  lib/src/session/          Who is signed in
  lib/src/theme/  widgets/

packages/on_go_shared/    API contract shared by both — pure Dart
  lib/src/models/           DTOs with toJson/fromJson
  lib/src/api/              Abstract interfaces + the agreed REST routes

packages/on_go_design/    Design system shared by both
  lib/src/                  Palettes, theme registry, tokens, ThemeController

server/                   Backend scaffold. No routes yet.
```

## The rules that keep this working

**Neither application imports the other.** Anything one needs from the other
goes through an interface in `on_go_shared`, reached via
`MobileBackend.instance` or `ConsoleBackend.instance` — never around them.

**Neither application defines a colour.** Both read the palettes in
`on_go_design`, so the two look like one product: the same six themes under the
same names, with the same Dark Mode, Dynamic Themes and Warm Filter. Each app
builds its own `ThemeData` from those palettes, because a phone and a desktop
want different densities — but not different colours.
