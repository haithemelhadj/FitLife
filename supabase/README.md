# Sports spaces database foundation

The migrations create five feature tables, seven enum types, ownership policies, protected subscription operations and exact monetary read views. They were generated with Supabase CLI 2.120.0 and applied to the shared FitLife project on October 12, 2026. Local filenames match the authoritative hosted migration versions. See [verification](VERIFICATION.md).

This repository previously had no migration baseline. The migration intentionally depends on the existing shared `public.profiles` table and Supabase Auth. It is not a complete database bootstrap. Do not reset the shared database or run a blind database push to establish a baseline.

## Migration workflow and shared dependencies

1. The pre-change metadata snapshot is `baseline/public_before_espaces.json`. It contains no application records and is not a replayable bootstrap. These are additive migrations against the existing schema. Preserve shared migration history; a fresh database needs the existing modules and Auth first.
2. The first migration protects `profiles.role` and `profiles.actif` on INSERT and UPDATE. Defaults create ATHLETE profiles with actif true. Trusted administrative operations remain responsible for assigning other roles and disabling accounts.
3. Profile IDs cannot be changed or forged. Ordinary name, phone, photo and birth-date edits remain allowed under existing ownership policies. Existing profile read visibility and the Auth signup trigger are preserved.
4. Keep `espace_prive` outside the exposed Data API schemas. Its explicitly authorized internal functions prevent policy recursion and perform protected subscription writes. Public RPC wrappers are security invokers. All entry points check the current user's protected role and active status; secret/service keys never belong in Flutter.
5. For subsequent changes, generate a new migration with the CLI, test it locally, apply it, and reconcile its filename with the hosted migration history. Do not modify already applied SQL.

The previously unsafe profile write permissions are now protected. Hosted tests created temporary accounts and feature records inside transactions that were rolled back. No test records remain.

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

The pinned PGlite dependency runs PostgreSQL with btree_gist in memory. The fixture mocks Supabase's role/session helpers and creates minimal shared profile and session tables. It first verifies refusal of unsafe role privileges, then applies the actual protection, foundation and optimization migrations under distinct database roles. If process spawning is restricted, use `node --test --test-isolation=none supabase/tests/espaces.test.mjs`.

Tests cover cross-owner access, insert responses under RLS, inactive/anonymous users, immutable ownership, monetary snapshots, duplicates, status transitions, date expiration, opening overlaps and history protection. `tests/hosted_smoke.sql` validates hosted database roles and real Auth helpers inside a rolled-back transaction. Anonymous API denial and private-schema exclusion were verified through PostgREST. Authenticated gateway flows and simultaneous-connection lock behavior remain integration checks; PGlite serializes queries.

## Deferred integration

The existing nullable `seance.id_espace_sportif` now has a foreign key and a covering space/date index. Persistent session equipment requirements and atomic space-occupancy enforcement still belong to the agreed training integration. The Flutter checker is advisory until that integration exists.

Subscriber names are not exposed by a new function in this step. Profile visibility requires the shared privacy review before adding that UI. No migration repairs unrelated existing profile-read permissions.
