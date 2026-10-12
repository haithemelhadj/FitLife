# Login and application access

The app opens a French login page with user, administrator and guest choices. User login uses an existing Supabase Auth email and password. Administrator login uses the name `admin`, mapped to the user-approved account `haithemelhadj42@gmail.com`, with that account's Supabase Auth password. No password is stored in the source. Server-protected profile role and active status are checked after login and when Auth changes.

The account was created privately by the user and assigned the active ADMIN role through a trusted database operation. This is operational account setup, not a migration or a self-service role assignment. The app does not accept privileged user metadata as authorization.

Authenticated users enter the application home and can use existing routes. Guests enter a home with sports-space catalogue access only. Guest mode signs out the local session before proceeding. Protected routes require an active user; Dashboard additionally requires ADMIN. Dashboard is a button on the home screen and in the admin drawer. Its statistics RPC independently rejects non-admin and inactive accounts. Admins can inspect and edit existing spaces; creating a space remains manager-only under the approved data contract.

Guest browsing uses `consulter_espaces_publics`, which returns only active spaces with active managers. It omits manager IDs and all profile/subscription data. No direct guest SELECT or write grants are added to the feature tables. The public wrapper is a security invoker; the fixed read-only projection is in the unexposed private schema. Guest list/detail screens expose no management controls.

Guest-publication migration status: awaiting explicit approval of the exposed catalogue fields. The login page and admin dashboard are implemented; the public catalogue endpoint is not yet deployed. Do not apply the pending migration until publication approval is recorded. The admin statistics migration is applied separately as 20261012191738_dashboard_admin_espaces.

## Manual checks

1. Restart the app in Android Studio. The login page appears unless a valid saved session is restored.
2. Select Administrateur, enter `admin` and the password set privately in Supabase. Verify the Dashboard button appears. Open it to inspect space totals and manage existing spaces.
3. Sign out. Sign in through Utilisateur with an existing active Auth account. Verify Dashboard is absent for non-admin roles. Direct dashboard navigation must also be refused.
4. Choose Continuer comme invité. After public-catalogue deployment, verify active-space browsing, search and details, with no edit/create/deactivate buttons and no access to other modules.
5. Use a wrong password or an inactive account. Verify the login stays visible with an error and no dashboard access.

Signup and password recovery are not included in this login request. Existing users must be provisioned through the shared account-management workflow. Guest browsing needs internet access; it is not the earlier proposed offline demo.

## Verification

51 Flutter tests passed; full-project analysis reported no issues; Android debug APK build passed. The local PostgreSQL suite passed 30 checks plus the enclosing test, including guest projection, read-only enforcement and admin-only statistics. Local tests use injected Auth repositories and an isolated database; the real password login must be verified by the user because the password was set privately. No test password or fixed admin password is embedded in the app.
