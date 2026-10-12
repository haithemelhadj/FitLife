# Sports spaces foundation

This implements the agreed data contract for `EspaceSportif`, `Equipement`, `DisponibiliteEspace`, `Offre` and `Abonnement`. It is the foundation for the later screens, not a completed user interface.

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

No new router, state-management framework, UI screens or third-party map APIs are introduced in this step. The later route remains `/espaces-sportifs`.

## Verification

Run from the project root:

```text
flutter analyze --no-pub lib/features/espace_sportif test/espace_sportif
flutter test --no-pub
npm ci --prefix supabase/tests
npm test --prefix supabase/tests
```

Flutter dependencies must already have been resolved. SQL tests use a temporary in-memory PostgreSQL runtime and never connect to the live Supabase project. See `supabase/README.md` for migration prerequisites and test limitations.
