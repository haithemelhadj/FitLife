/* Les statistiques du tableau de bord nécessitent un administrateur actif. */
create function public.resume_admin_espaces() returns jsonb
language plpgsql stable security invoker set search_path = '' as $$
begin
  if espace_prive.role_actif() is distinct from 'ADMIN' then
    raise exception 'Accès administrateur requis.' using errcode='42501';
  end if;
  return (select jsonb_build_object('total', count(*),
    'actifs',count(*) filter(where statut='ACTIF'),
    'inactifs',count(*) filter(where statut='INACTIF'),
    'maintenance',count(*) filter(where statut='EN_MAINTENANCE')) from public.espace_sportif);
end;
$$;
revoke all on function public.resume_admin_espaces() from public,anon,authenticated;
grant execute on function public.resume_admin_espaces() to authenticated;
