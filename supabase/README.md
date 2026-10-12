# Sports spaces database foundation

The migration creates five feature tables, seven enum types, ownership policies, protected subscription operations and exact monetary read views. The file was created with Supabase CLI 2.120.0. It has not been applied to the shared FitLife project.

This repository previously had no migration baseline. The migration intentionally depends on the existing shared `public.profiles` table and Supabase Auth. It is not a complete database bootstrap. Do not reset the shared database or run a blind database push to establish a baseline.

## Deployment prerequisites

1. Establish the existing database baseline with the team in a development environment. Preserve the existing auth, training, event and nutrition schema and migration history.
2. Have the shared authentication owner protect `profiles.role` and `profiles.actif` on both INSERT and UPDATE. The migration refuses deployment while `anon` or `authenticated` retains write privileges on those columns. Defaults must create ATHLETE profiles with actif true. Trusted administrative operations remain responsible for assigning other roles and disabling accounts.
3. Verify that profile IDs cannot be changed or forged and that the existing profile INSERT policy requires `id = auth.uid()`. Restrict table-level privileges before granting only the permitted profile columns. Merely revoking a column privilege cannot narrow a table-level grant. The migration's privilege precheck is not a substitute for the shared authentication review.
4. Keep `espace_prive` outside the exposed Data API schemas. Its explicitly authorized internal functions prevent policy recursion and perform protected subscription writes. Public RPC wrappers are security invokers. All entry points check the current user's protected role and active status; secret/service keys never belong in Flutter.
5. Apply the feature migration in the development environment, run role tests through Supabase/PostgREST, inspect the Supabase security advisors, and review the resulting schema before shared rollout.

The previously inspected live profile permissions did not satisfy prerequisite 2. They have not been changed by this work. No real accounts or records were created by the tests.

## API contract

| Entry point | Purpose |
| :--- | :--- |
| `contexte_espaces()` | Current user ID, active role or null, and Africa/Tunis business date. |
| `rechercher_espaces(p_recherche, p_type, p_apres, p_limite, p_mes_espaces)` | Literal name/address search, optional type, ID cursor, 1 to 100 rows. Managed records appear only when explicitly requested. |
| `souscrire_offre(p_offre)` | Athlete-only subscription. Computes identity, inclusive dates and a price snapshot on the server. |
| `changer_statut_abonnement(p_abonnement, p_statut)` | Authorized cancellation, manager suspension/reactivation, or effective expiry reconciliation. |
| `offres_lecture` | Offers with decimal-string prices and effective expiration. Uses the caller's RLS. |
| `abonnements_lecture` | Subscriptions with decimal-string amounts and effective expiration. Uses the caller's RLS. |

Client grants exclude identity and ownership updates, direct subscription mutations and destructive business deletes. Opening intervals can be deleted by their manager because they are configuration. PostgreSQL exclusion constraints reject overlapping opening intervals and live subscriptions. The subscription operation locks the selected offer and space while validating and creating the subscription.

Offers and subscription dates remain independent: an offer's final sale date does not truncate purchased access. Durations are explicit day counts. PACK has no visit counter; SEANCE has one-day validity and does not reserve a training session. These limitations are recorded in the approved contract.

## Tests

Node 22 or newer is required. From the repository root:

```text
npm ci --prefix supabase/tests
npm test --prefix supabase/tests
```

The pinned PGlite dependency runs PostgreSQL with btree_gist in memory. The test fixture mocks Supabase's role/session helpers and creates a minimal shared profile schema. It first verifies refusal of unsafe role privileges, then simulates the protected baseline and tests the migration under distinct database roles.

Tests cover cross-owner access, insert responses under RLS, inactive/anonymous users, immutable ownership, monetary snapshots, duplicates, status transitions, date expiration, opening overlaps and history protection. This validates SQL behavior, not the hosted Auth/PostgREST gateway. PGlite serializes queries; simultaneous connections and lock behavior must additionally be exercised against the development PostgreSQL instance before deployment.

## Deferred integration

No training tables are altered here. The nullable foreign key from `seance.id_espace_sportif`, persistent session equipment requirements, and atomic space-occupancy enforcement belong to the agreed training integration. The Flutter checker is advisory until that integration exists.

Subscriber names are not exposed by a new function in this step. Profile visibility requires the shared privacy review before adding that UI. No migration repairs unrelated existing profile-read permissions.
