# Login and application access

The app opens a French login page with Utilisateur and Administrateur choices. User login uses an existing Supabase Auth email and password. Administrator login uses the name `admin`, mapped to the user-approved account `haithemelhadj42@gmail.com`, with that account's Supabase Auth password. No password is stored in the source. Server-protected profile role and active status are checked after login and when Auth changes.

The account was created privately by the user and assigned the active ADMIN role through a trusted database operation. This is operational account setup, not a migration or self-service role assignment. The app does not accept privileged user metadata as authorization.

All application routes require an active signed-in user. Dashboard additionally requires ADMIN and appears as a button on the home screen and in the admin drawer. Its statistics RPC independently rejects non-admin and inactive accounts. Admins can inspect and edit existing spaces; creating a space remains manager-only under the approved data contract.

Guest access was removed at the user's request. The guest button, session state, navigation branch, public repository and undeployed public catalogue migration were removed. No anonymous catalogue endpoint was deployed and no temporary guest accounts were created. The applied admin statistics migration remains `20261012191738_dashboard_admin_espaces`.

## Manual checks

1. Restart the app in Android Studio. The login page appears unless a valid saved session is restored.
2. Select Administrateur, enter `admin` and the password set privately in Supabase. Verify the Dashboard button appears. Open it to inspect space totals and manage existing spaces.
3. Sign out. Sign in through Utilisateur with an existing active Auth account. Verify Dashboard is absent for non-admin roles. Direct dashboard navigation must also be refused.
4. Verify there is no guest option and that opening application routes without a session is refused.
5. Use a wrong password or an inactive account. Verify the login stays visible with an error and no dashboard access.

Signup and password recovery remain shared account-management work. Existing users must be provisioned through that workflow.

## Verification

After guest removal, 50 Flutter tests passed and full-project analysis reported no issues. The isolated PostgreSQL suite passed 29 checks plus the enclosing test, including anonymous access denial and admin-only statistics. Local tests use injected Auth repositories and an isolated database; real password login must be verified by the user because the password was set privately.
