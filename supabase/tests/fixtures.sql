/* Ce schéma minimal est réservé à la base de test isolée. */
create role anon nologin;
create role authenticated nologin;
create schema auth;
grant usage on schema auth,public to authenticated,anon;
create function auth.jwt() returns jsonb language sql stable as $$
  select coalesce(nullif(current_setting('request.jwt.claims',true),''),'{}')::jsonb
$$;
create function auth.uid() returns uuid language sql stable as $$
  select (auth.jwt()->>'sub')::uuid
$$;
create type public.role_utilisateur as enum ('ATHLETE','COACH','NUTRITIONNISTE','GESTIONNAIRE_ESPACE','ADMIN');
create table public.profiles (
  id uuid primary key,
  nom text,
  prenom text,
  role public.role_utilisateur not null default 'ATHLETE',
  actif boolean default true
);
alter table public.profiles enable row level security;
create policy lecture on public.profiles for select to authenticated using (true);
create policy creation on public.profiles for insert to authenticated with check (id=auth.uid());
create policy modification on public.profiles for update to authenticated using (id=auth.uid()) with check (id=auth.uid());
grant select,insert,update on public.profiles to authenticated;
insert into public.profiles (id,nom,role,actif) values
('00000000-0000-0000-0000-000000000001','Gestionnaire A','GESTIONNAIRE_ESPACE',true),
('00000000-0000-0000-0000-000000000002','Gestionnaire B','GESTIONNAIRE_ESPACE',true),
('00000000-0000-0000-0000-000000000003','Athlète A','ATHLETE',true),
('00000000-0000-0000-0000-000000000004','Athlète B','ATHLETE',true),
('00000000-0000-0000-0000-000000000005','Administrateur','ADMIN',true),
('00000000-0000-0000-0000-000000000006','Compte inactif','ATHLETE',false),
('00000000-0000-0000-0000-000000000007','Coach','COACH',true),
('00000000-0000-0000-0000-000000000008','Nutritionniste','NUTRITIONNISTE',true);
