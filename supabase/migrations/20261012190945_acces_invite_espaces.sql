/* Le catalogue invité expose uniquement les espaces actifs et les coordonnées commerciales. */
create function espace_prive.catalogue_invite(
  p_recherche text, p_type public.type_espace, p_apres bigint, p_limite integer, p_id bigint
) returns jsonb language plpgsql stable security definer set search_path = '' as $$
begin
  if p_recherche is null or p_limite is null or p_limite < 1 or p_limite > 100
    or p_apres < 1 or p_id < 1 then
    raise exception 'Paramètres de recherche invalides.' using errcode='22023';
  end if;
  return (
    select coalesce(jsonb_agg(jsonb_build_object(
      'id_espace', e.id_espace, 'nom', e.nom, 'description', e.description,
      'type', e.type, 'adresse', e.adresse, 'latitude', e.latitude, 'longitude', e.longitude,
      'telephone', e.telephone, 'email', e.email, 'site_web', e.site_web, 'statut', e.statut
    ) order by e.id_espace), '[]'::jsonb)
    from (
      select e.id_espace,e.nom,e.description,e.type,e.adresse,e.latitude,e.longitude,
        e.telephone,e.email,e.site_web,e.statut
      from public.espace_sportif e join public.profiles p on p.id=e.id_gestionnaire
      where e.statut='ACTIF' and p.actif is true
        and (p_type is null or e.type=p_type)
        and (p_apres is null or e.id_espace>p_apres)
        and (p_id is null or e.id_espace=p_id)
        and (strpos(lower(e.nom),lower(btrim(p_recherche)))>0
          or strpos(lower(e.adresse),lower(btrim(p_recherche)))>0)
      order by e.id_espace limit p_limite
    ) e
  );
end;
$$;
revoke all on function espace_prive.catalogue_invite(text,public.type_espace,bigint,integer,bigint) from public,anon,authenticated;
grant usage on schema espace_prive to anon;
grant execute on function espace_prive.catalogue_invite(text,public.type_espace,bigint,integer,bigint) to anon,authenticated;

create function public.consulter_espaces_publics(
  p_recherche text default '', p_type public.type_espace default null,
  p_apres bigint default null, p_limite integer default 20, p_id bigint default null
) returns jsonb language sql stable security invoker set search_path = '' as $$
  select espace_prive.catalogue_invite(p_recherche,p_type,p_apres,p_limite,p_id)
$$;
revoke all on function public.consulter_espaces_publics(text,public.type_espace,bigint,integer,bigint) from public,anon,authenticated;
grant execute on function public.consulter_espaces_publics(text,public.type_espace,bigint,integer,bigint) to anon,authenticated;

