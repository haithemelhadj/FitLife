/* La protection des profils doit précéder le déploiement de ce module. */
do $$
begin
  if to_regclass('public.profiles') is null then
    raise exception 'Le module partagé profiles est requis.';
  end if;
  if has_column_privilege('authenticated', 'public.profiles', 'role', 'UPDATE')
     or has_column_privilege('authenticated', 'public.profiles', 'actif', 'UPDATE')
     or has_column_privilege('authenticated', 'public.profiles', 'role', 'INSERT')
     or has_column_privilege('authenticated', 'public.profiles', 'actif', 'INSERT')
     or has_column_privilege('anon', 'public.profiles', 'role', 'UPDATE')
     or has_column_privilege('anon', 'public.profiles', 'actif', 'UPDATE')
     or has_column_privilege('anon', 'public.profiles', 'role', 'INSERT')
     or has_column_privilege('anon', 'public.profiles', 'actif', 'INSERT') then
    raise exception 'Protégez role et actif dans profiles avant cette migration.';
  end if;
end $$;

create extension if not exists btree_gist;
create schema espace_prive;
revoke all on schema espace_prive from public;
grant usage on schema espace_prive to authenticated;

create type public.type_espace as enum ('SALLE','CLUB_SPORTIF','STADE','TERRAIN','PARC','CENTRE_SPORTIF','PISCINE','AUTRE');
create type public.statut_espace as enum ('ACTIF','INACTIF','EN_MAINTENANCE');
create type public.etat_equipement as enum ('BON','ENDOMMAGE','EN_MAINTENANCE','HORS_SERVICE');
create type public.jour_semaine as enum ('LUNDI','MARDI','MERCREDI','JEUDI','VENDREDI','SAMEDI','DIMANCHE');
create type public.type_offre as enum ('ABONNEMENT','PACK','SEANCE');
create type public.statut_offre as enum ('ACTIVE','INACTIVE','EXPIREE');
create type public.statut_abonnement as enum ('ACTIF','EXPIRE','SUSPENDU','ANNULE');

create table public.espace_sportif (
  id_espace bigint generated always as identity primary key,
  nom text not null check (nom = btrim(nom) and nom <> ''),
  description text,
  type public.type_espace not null,
  adresse text not null check (adresse = btrim(adresse) and adresse <> ''),
  latitude double precision check (latitude between -90 and 90),
  longitude double precision check (longitude between -180 and 180),
  telephone text,
  email text,
  site_web text,
  statut public.statut_espace not null default 'INACTIF',
  id_gestionnaire uuid not null default auth.uid() references public.profiles(id) on delete restrict,
  check ((latitude is null) = (longitude is null))
);

create table public.equipement (
  id_equipement bigint generated always as identity primary key,
  nom text not null check (nom = btrim(nom) and nom <> ''),
  description text,
  quantite integer not null check (quantite >= 0),
  etat public.etat_equipement not null,
  id_espace bigint not null references public.espace_sportif(id_espace) on delete restrict
);

create table public.disponibilite_espace (
  id_disponibilite bigint generated always as identity primary key,
  jour public.jour_semaine not null,
  heure_ouverture time not null,
  heure_fermeture time not null,
  id_espace bigint not null references public.espace_sportif(id_espace) on delete restrict,
  check (heure_ouverture < heure_fermeture),
  check (extract(second from heure_ouverture) = 0 and extract(second from heure_fermeture) = 0),
  exclude using gist (
    id_espace with =, jour with =,
    (int4range(extract(epoch from heure_ouverture)::integer,
               extract(epoch from heure_fermeture)::integer, '[)')) with &&
  )
);

create table public.offre (
  id_offre bigint generated always as identity primary key,
  nom text not null check (nom = btrim(nom) and nom <> ''),
  description text,
  type public.type_offre not null,
  prix numeric(12,3) not null check (prix >= 0 and prix <> 'NaN'::numeric),
  duree integer not null check (duree > 0),
  date_debut date not null check (isfinite(date_debut)),
  date_fin date check (isfinite(date_fin)),
  statut public.statut_offre not null default 'INACTIVE',
  id_espace bigint not null references public.espace_sportif(id_espace) on delete restrict,
  check (date_fin is null or date_fin >= date_debut),
  check (type <> 'SEANCE' or duree = 1)
);

create table public.abonnement (
  id_abonnement bigint generated always as identity primary key,
  id_athlete uuid not null references public.profiles(id) on delete restrict,
  id_offre bigint not null references public.offre(id_offre) on delete restrict,
  date_debut date not null check (isfinite(date_debut)),
  date_fin date not null check (isfinite(date_fin) and date_fin >= date_debut),
  montant numeric(12,3) not null check (montant >= 0 and montant <> 'NaN'::numeric),
  statut public.statut_abonnement not null default 'ACTIF',
  exclude using gist (
    id_athlete with =, id_offre with =,
    (daterange(date_debut, date_fin, '[]')) with &&
  ) where (statut in ('ACTIF','SUSPENDU'))
);

create index espace_gestionnaire_idx on public.espace_sportif(id_gestionnaire);
create index espace_catalogue_idx on public.espace_sportif(statut,type,id_espace);
create index equipement_espace_etat_idx on public.equipement(id_espace,etat);
create index offre_espace_statut_idx on public.offre(id_espace,statut);
create index abonnement_athlete_idx on public.abonnement(id_athlete,id_abonnement);
create index abonnement_offre_statut_idx on public.abonnement(id_offre,statut);

/* Ce lien conserve les séances sans espace et protège les espaces référencés. */
alter table public.seance add constraint seance_espace_sportif_fkey
  foreign key (id_espace_sportif) references public.espace_sportif(id_espace) on delete restrict;
create index seance_espace_date_idx on public.seance(id_espace_sportif,date);

create function espace_prive.aujourdhui() returns date
language sql stable set search_path = '' as $$
  select (current_timestamp at time zone 'Africa/Tunis')::date
$$;

create function espace_prive.role_actif() returns text
language sql stable security invoker set search_path = '' as $$
  select p.role::text from public.profiles p
  where p.id = auth.uid() and p.actif is true
    and coalesce((auth.jwt()->>'is_anonymous')::boolean, false) = false
$$;

/* Ces lectures internes évitent les cycles entre les politiques des trois tables. */
create function espace_prive.gere(p_espace bigint) returns boolean
language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null and (
    espace_prive.role_actif() = 'ADMIN' or
    (espace_prive.role_actif() = 'GESTIONNAIRE_ESPACE' and exists (
      select 1 from public.espace_sportif e
      where e.id_espace = p_espace and e.id_gestionnaire = auth.uid()
    ))
  )
$$;

create function espace_prive.catalogue(p_espace bigint) returns boolean
language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null and espace_prive.role_actif() is not null and exists (
    select 1 from public.espace_sportif e join public.profiles p on p.id=e.id_gestionnaire
    where e.id_espace=p_espace and e.statut='ACTIF' and p.actif is true
  )
$$;

create function espace_prive.lit_espace(p_espace bigint) returns boolean
language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null and espace_prive.role_actif() is not null and (
    espace_prive.gere(p_espace) or espace_prive.catalogue(p_espace) or exists (
      select 1 from public.abonnement a join public.offre o on o.id_offre=a.id_offre
      where a.id_athlete=auth.uid() and espace_prive.role_actif()='ATHLETE' and o.id_espace=p_espace
    )
  )
$$;

create function espace_prive.lit_offre(p_offre bigint) returns boolean
language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null and espace_prive.role_actif() is not null and exists (
    select 1 from public.offre o where o.id_offre=p_offre and (
      espace_prive.gere(o.id_espace) or
      (espace_prive.catalogue(o.id_espace) and o.statut='ACTIVE'
       and o.date_debut <= espace_prive.aujourdhui()
       and (o.date_fin is null or o.date_fin >= espace_prive.aujourdhui())) or
      exists (select 1 from public.abonnement a where a.id_offre=o.id_offre
              and a.id_athlete=auth.uid() and espace_prive.role_actif()='ATHLETE')
    )
  )
$$;

create function espace_prive.gere_offre(p_offre bigint) returns boolean
language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null and exists (
    select 1 from public.offre o where o.id_offre=p_offre and espace_prive.gere(o.id_espace)
  )
$$;

alter table public.espace_sportif enable row level security;
alter table public.equipement enable row level security;
alter table public.disponibilite_espace enable row level security;
alter table public.offre enable row level security;
alter table public.abonnement enable row level security;

create policy espace_lecture on public.espace_sportif for select to authenticated using (
  espace_prive.role_actif()='ADMIN' or
  (espace_prive.role_actif()='GESTIONNAIRE_ESPACE' and id_gestionnaire=auth.uid()) or
  espace_prive.lit_espace(id_espace)
);
create policy espace_creation on public.espace_sportif for insert to authenticated with check (
  espace_prive.role_actif()='GESTIONNAIRE_ESPACE' and id_gestionnaire=auth.uid()
);
create policy espace_modification on public.espace_sportif for update to authenticated
  using (espace_prive.gere(id_espace)) with check (espace_prive.gere(id_espace));

create policy equipement_lecture on public.equipement for select to authenticated
  using (espace_prive.gere(id_espace) or espace_prive.catalogue(id_espace));
create policy equipement_creation on public.equipement for insert to authenticated with check (espace_prive.gere(id_espace));
create policy equipement_modification on public.equipement for update to authenticated
  using (espace_prive.gere(id_espace)) with check (espace_prive.gere(id_espace));

create policy disponibilite_lecture on public.disponibilite_espace for select to authenticated
  using (espace_prive.gere(id_espace) or espace_prive.catalogue(id_espace));
create policy disponibilite_creation on public.disponibilite_espace for insert to authenticated with check (espace_prive.gere(id_espace));
create policy disponibilite_modification on public.disponibilite_espace for update to authenticated
  using (espace_prive.gere(id_espace)) with check (espace_prive.gere(id_espace));
create policy disponibilite_suppression on public.disponibilite_espace for delete to authenticated using (espace_prive.gere(id_espace));

create policy offre_lecture on public.offre for select to authenticated
  using (espace_prive.gere(id_espace) or espace_prive.lit_offre(id_offre));
create policy offre_creation on public.offre for insert to authenticated with check (espace_prive.gere(id_espace));
create policy offre_modification on public.offre for update to authenticated
  using (espace_prive.gere(id_espace)) with check (espace_prive.gere(id_espace));

create policy abonnement_lecture on public.abonnement for select to authenticated using (
  espace_prive.role_actif() is not null and (
    (espace_prive.role_actif()='ATHLETE' and id_athlete=auth.uid()) or espace_prive.gere_offre(id_offre)
  )
);

/* Les colonnes de rattachement et les identifiants ne sont jamais modifiables. */
revoke all on public.espace_sportif, public.equipement, public.disponibilite_espace, public.offre, public.abonnement from public, anon, authenticated;
grant select on public.espace_sportif, public.equipement, public.disponibilite_espace, public.offre, public.abonnement to authenticated;
grant insert (nom,description,type,adresse,latitude,longitude,telephone,email,site_web,statut)
  on public.espace_sportif to authenticated;
grant update (nom,description,type,adresse,latitude,longitude,telephone,email,site_web,statut)
  on public.espace_sportif to authenticated;
grant insert (nom,description,quantite,etat,id_espace) on public.equipement to authenticated;
grant update (nom,description,quantite,etat) on public.equipement to authenticated;
grant insert (jour,heure_ouverture,heure_fermeture,id_espace) on public.disponibilite_espace to authenticated;
grant update (jour,heure_ouverture,heure_fermeture) on public.disponibilite_espace to authenticated;
grant delete on public.disponibilite_espace to authenticated;
grant insert (nom,description,type,prix,duree,date_debut,date_fin,statut,id_espace) on public.offre to authenticated;
grant update (nom,description,type,prix,duree,date_debut,date_fin,statut) on public.offre to authenticated;
grant usage on sequence public.espace_sportif_id_espace_seq, public.equipement_id_equipement_seq,
  public.disponibilite_espace_id_disponibilite_seq, public.offre_id_offre_seq to authenticated;

/* La souscription verrouille l'offre et conserve son prix et sa durée. */
create function espace_prive.souscrire(p_offre bigint) returns public.abonnement
language plpgsql security definer set search_path = '' as $$
declare o public.offre; a public.abonnement; d date := espace_prive.aujourdhui();
begin
  if auth.uid() is null or espace_prive.role_actif() is distinct from 'ATHLETE' then
    raise exception 'Un profil athlète actif est requis.' using errcode='42501';
  end if;
  select * into o from public.offre where id_offre=p_offre for update;
  if not found or o.statut <> 'ACTIVE' or o.date_debut > d or o.date_fin < d
     or not espace_prive.catalogue(o.id_espace) then
    raise exception 'Offre indisponible.' using errcode='22023';
  end if;
  perform 1 from public.espace_sportif where id_espace=o.id_espace for share;
  if not espace_prive.catalogue(o.id_espace) then
    raise exception 'Espace indisponible.' using errcode='22023';
  end if;
  insert into public.abonnement(id_athlete,id_offre,date_debut,date_fin,montant)
  values (auth.uid(),o.id_offre,d,d+o.duree-1,o.prix) returning * into a;
  return a;
end $$;

create function espace_prive.changer_abonnement(p_abonnement bigint, p_statut public.statut_abonnement)
returns public.abonnement language plpgsql security definer set search_path = '' as $$
declare a public.abonnement; r text := espace_prive.role_actif(); gestion boolean;
begin
  if auth.uid() is null or r is null then
    raise exception 'Un profil actif est requis.' using errcode='42501';
  end if;
  select * into a from public.abonnement where id_abonnement=p_abonnement for update;
  gestion := espace_prive.gere_offre(a.id_offre);
  if a.id_abonnement is null or not (coalesce(gestion,false) or (r='ATHLETE' and a.id_athlete=auth.uid())) then
    raise exception 'Abonnement inaccessible.' using errcode='42501';
  end if;
  if a.statut in ('ACTIF','SUSPENDU') and a.date_fin < espace_prive.aujourdhui() then
    update public.abonnement set statut='EXPIRE' where id_abonnement=p_abonnement returning * into a;
    return a;
  end if;
  if a.statut='ANNULE' and p_statut='ANNULE' then return a; end if;
  if p_statut is null or not (
    (a.statut in ('ACTIF','SUSPENDU') and p_statut='ANNULE') or
    (gestion and ((a.statut='ACTIF' and p_statut='SUSPENDU') or (a.statut='SUSPENDU' and p_statut='ACTIF')))
  ) then
    raise exception 'Transition non autorisée.' using errcode='22023';
  end if;
  update public.abonnement set statut=p_statut where id_abonnement=p_abonnement returning * into a;
  return a;
end $$;

create function public.souscrire_offre(p_offre bigint) returns jsonb
language plpgsql security invoker set search_path = '' as $$
declare a public.abonnement;
begin
  a := espace_prive.souscrire(p_offre);
  return to_jsonb(a) || jsonb_build_object('montant',a.montant::text);
end $$;
create function public.changer_statut_abonnement(p_abonnement bigint, p_statut public.statut_abonnement)
returns jsonb language plpgsql security invoker set search_path = '' as $$
declare a public.abonnement;
begin
  a := espace_prive.changer_abonnement(p_abonnement,p_statut);
  return to_jsonb(a) || jsonb_build_object('montant',a.montant::text);
end $$;

create function public.contexte_espaces() returns jsonb
language sql stable security invoker set search_path = '' as $$
  select jsonb_build_object('id_utilisateur',auth.uid(),'role',espace_prive.role_actif(),'date',espace_prive.aujourdhui())
$$;

/* Les montants sont transmis en texte pour conserver les millimes dans le client. */
create view public.offres_lecture with (security_invoker=true) as
select id_offre,nom,description,type,prix::text as prix,duree,date_debut,date_fin,
  case when date_fin < espace_prive.aujourdhui() then 'EXPIREE'::public.statut_offre else statut end as statut,
  id_espace from public.offre;
create view public.abonnements_lecture with (security_invoker=true) as
select id_abonnement,id_athlete,id_offre,date_debut,date_fin,montant::text as montant,
  case when statut in ('ACTIF','SUSPENDU') and date_fin < espace_prive.aujourdhui()
    then 'EXPIRE'::public.statut_abonnement else statut end as statut from public.abonnement;
revoke all on public.offres_lecture,public.abonnements_lecture from public,anon,authenticated;
grant select on public.offres_lecture,public.abonnements_lecture to authenticated;

revoke all on all functions in schema espace_prive from public,anon,authenticated;
grant execute on function espace_prive.aujourdhui(),espace_prive.role_actif(),espace_prive.gere(bigint),
  espace_prive.catalogue(bigint),espace_prive.lit_espace(bigint),espace_prive.lit_offre(bigint),
  espace_prive.gere_offre(bigint),espace_prive.souscrire(bigint),
  espace_prive.changer_abonnement(bigint,public.statut_abonnement) to authenticated;
revoke all on function public.souscrire_offre(bigint),public.changer_statut_abonnement(bigint,public.statut_abonnement),public.contexte_espaces() from public,anon,authenticated;
grant execute on function public.souscrire_offre(bigint),public.changer_statut_abonnement(bigint,public.statut_abonnement),public.contexte_espaces() to authenticated;

create function public.rechercher_espaces(
  p_recherche text default '', p_type public.type_espace default null,
  p_apres bigint default null, p_limite integer default 20,
  p_mes_espaces boolean default false
) returns setof public.espace_sportif
language plpgsql stable security invoker set search_path = '' as $$
begin
  if p_limite is null or p_limite < 1 or p_limite > 100 or p_apres < 1
     or p_recherche is null or p_mes_espaces is null then
    raise exception 'Paramètres de recherche invalides.' using errcode='22023';
  end if;
  return query select e.* from public.espace_sportif e
  where (case when p_mes_espaces then espace_prive.gere(e.id_espace)
         else espace_prive.catalogue(e.id_espace) end)
    and (p_type is null or e.type=p_type)
    and (p_apres is null or e.id_espace > p_apres)
    and (strpos(lower(e.nom),lower(btrim(p_recherche))) > 0
         or strpos(lower(e.adresse),lower(btrim(p_recherche))) > 0)
  order by e.id_espace limit p_limite;
end $$;
revoke all on function public.rechercher_espaces(text,public.type_espace,bigint,integer,boolean) from public,anon,authenticated;
grant execute on function public.rechercher_espaces(text,public.type_espace,bigint,integer,boolean) to authenticated;

/* Les textes facultatifs vides sont enregistrés comme des valeurs absentes. */
create function espace_prive.normaliser_textes() returns trigger
language plpgsql security invoker set search_path = '' as $$
declare cle text; donnees jsonb := to_jsonb(new);
begin
  foreach cle in array array['nom','adresse','description','telephone','email','site_web'] loop
    if donnees ? cle then
      donnees := jsonb_set(donnees,array[cle],coalesce(to_jsonb(nullif(btrim(donnees->>cle),'')),'null'::jsonb));
    end if;
  end loop;
  new := jsonb_populate_record(new,donnees);
  return new;
end $$;
revoke all on function espace_prive.normaliser_textes() from public,anon,authenticated;
create trigger espace_normalisation before insert or update on public.espace_sportif
for each row execute function espace_prive.normaliser_textes();
create trigger equipement_normalisation before insert or update on public.equipement
for each row execute function espace_prive.normaliser_textes();
create trigger offre_normalisation before insert or update on public.offre
for each row execute function espace_prive.normaliser_textes();
