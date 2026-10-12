# Sports spaces foundation

This implements the agreed data contract for `EspaceSportif`, `Equipement`, `DisponibiliteEspace`, `Offre` and `Abonnement`. Step 3 adds the space list, details and create/edit form. Equipment, opening-hour, offer and subscription screens remain later slices.

Models preserve French business identifiers. Repositories receive a `SupabaseClient`, use named columns and never submit immutable ownership fields on updates. Subscription mutations use RPCs instead of direct table writes. Money uses integer millimes in Dart and exact decimal strings over the API. Use `offres_lecture` and `abonnements_lecture` when reading prices and effective statuses.

`ContexteEspace` supplies the server's business date and active role. Treat its access helpers as UI guidance; database permissions remain authoritative. `DateCivile` represents a date without conversion through the device timezone. All business dates come from Africa/Tunis on the server.

`DisponibiliteChecker` is a pure advisory check. The caller must supply complete opening hours, equipment requirements and blocking sessions for the requested space/date. Only PLANIFIEE and COMPLETE sessions should become `CreneauOccupe` values. Do not exclude a session unless the caller has established that the current user can edit it. Unknown equipment requirements must not be replaced silently by an empty list.

## Example

```dart
final repository = EspaceSportifRepository(Supabase.instance.client);
final contexte = await repository.getContexte();
if (contexte.accessible) {
  final espaces = await repository.rechercher(limite: 20);
}
```

The named route `/espaces-sportifs` is registered in `main.dart` and available through the shared drawer. The screens retain StatefulWidget state and injected repositories. No router/state framework migration or map API was introduced.

## Step 3 UI

Active signed-in users can browse the catalogue, search by name/address, filter by type, load further pages and read space details. Managers can switch to `Mes espaces`, create spaces, edit their own records and deactivate them. Administrators can browse all manageable spaces and edit existing records; creation remains manager-only, matching deployed permissions. Deactivation sends only a status patch and preserves historical records.

The form validates required name/address, explicit type, email, HTTP/HTTPS URL, finite coordinate ranges and paired coordinates. New spaces default to INACTIF. Select ACTIF to publish them. Errors preserve form input, saving disables repeated submission, and the role is rechecked before writes. List/detail screens refresh on authentication changes and discard stale responses. Supabase remains authoritative for all access checks.

## Manual Android check

1. Run the app on an Android emulator and open the drawer, then `Espaces sportifs`.
2. Without a session, expect the sign-in-required state. The shared authentication UI is still missing; no duplicate login screen is added here. The existing `main.dart` supports `DEV_EMAIL` and `DEV_PASSWORD` launch defines for a development account. Keep credentials out of tracked files and use development accounts only.
3. With an active GESTIONNAIRE_ESPACE account, create an inactive space and verify it appears under `Mes espaces`. Edit its name and status, then confirm the details refresh.
4. With an active ATHLETE account, verify active-space discovery and details, with no create/edit/deactivate controls. A second manager must not see editing controls for the first manager's space.
5. Deactivate the space as its owner. Confirm the deactivation dialog, inactive status and removal from the athlete catalogue. The manager should still find it under `Mes espaces`.

Privileged roles must already be assigned through trusted shared administration. Do not enable self-role editing to make these checks pass.

## Verification

Run from the project root:

```text
flutter analyze --no-pub lib/features/espace_sportif test/espace_sportif
flutter test --no-pub
npm ci --prefix supabase/tests
npm test --prefix supabase/tests
```

Flutter dependencies must already have been resolved. SQL tests use a temporary in-memory PostgreSQL runtime and never connect to the live Supabase project. See `supabase/README.md` for migration prerequisites and test limitations.

Step 3 validation: 38 Flutter tests passed, including 15 new widget scenarios and a status-only repository request test. Full-project analysis reported no issues and the Android debug APK build passed. Widget tests inject a fake repository; repository tests inspect requests against a local HTTP server. These do not replace signed-in hosted API testing. No new database migration is needed for this slice.
