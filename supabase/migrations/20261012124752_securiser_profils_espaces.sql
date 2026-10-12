/* Les rôles et l'activation restent réservés à l'administration de confiance. */
revoke insert, update, delete, truncate, references, trigger
  on public.profiles from public, anon, authenticated;

/* Les anciens droits par colonne doivent aussi être retirés. */
do $$
declare colonnes text;
begin
  select string_agg(quote_ident(attname), ', ' order by attnum) into colonnes
  from pg_attribute where attrelid='public.profiles'::regclass
    and attnum > 0 and not attisdropped;
  execute format('revoke insert (%s), update (%s), references (%s) on public.profiles from public, anon, authenticated',
                 colonnes, colonnes, colonnes);
end $$;

grant insert (id,nom,prenom,telephone,photo,date_naissance)
  on public.profiles to authenticated;
grant update (nom,prenom,telephone,photo,date_naissance)
  on public.profiles to authenticated;

alter table public.profiles alter column role set default 'ATHLETE';
alter table public.profiles alter column actif set default true;
alter table public.profiles enable row level security;

/* Ces restrictions complètent les politiques partagées sans élargir la lecture. */
create policy profiles_espaces_creation_protegee on public.profiles
  as restrictive for insert to authenticated
  with check (
    id=(select auth.uid()) and role='ATHLETE' and actif is true
    and coalesce(((select auth.jwt())->>'is_anonymous')::boolean,false)=false
  );
create policy profiles_espaces_modification_protegee on public.profiles
  as restrictive for update to authenticated
  using (id=(select auth.uid())) with check (id=(select auth.uid()));
