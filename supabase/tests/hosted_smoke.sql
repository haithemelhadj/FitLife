begin;
set local lock_timeout = '5s';
set local statement_timeout = '30s';

/* Toutes les identités et données créées ici sont annulées en fin de test. */
do $$
declare
  gestionnaire uuid := gen_random_uuid();
  autre_gestionnaire uuid := gen_random_uuid();
  athlete uuid := gen_random_uuid();
  autre_athlete uuid := gen_random_uuid();
  espace bigint;
  offre bigint;
  id_abonnement_test bigint;
  resultat jsonb;
  nombre integer;
begin
  insert into auth.users(id,raw_user_meta_data)
    values (gestionnaire,'{}'),(autre_gestionnaire,'{}'),(athlete,'{}'),(autre_athlete,'{}');
  update public.profiles set role='GESTIONNAIRE_ESPACE'
    where id in (gestionnaire,autre_gestionnaire);
  if not exists(select 1 from public.profiles where id=athlete and role='ATHLETE' and actif is true) then
    raise exception 'La création du profil par Auth a échoué.';
  end if;

  perform set_config('request.jwt.claims',jsonb_build_object('sub',gestionnaire,'role','authenticated','is_anonymous',false)::text,true);
  execute 'set local role authenticated';
  insert into public.espace_sportif(nom,type,adresse,statut)
    values ('Vérification transactionnelle','SALLE','Tunis','ACTIF') returning id_espace into espace;
  insert into public.disponibilite_espace(id_espace,jour,heure_ouverture,heure_fermeture)
    values(espace,'LUNDI','08:00','12:00');
  begin
    insert into public.disponibilite_espace(id_espace,jour,heure_ouverture,heure_fermeture)
      values(espace,'LUNDI','11:00','13:00');
    raise exception 'Le chevauchement des horaires doit être refusé.';
  exception when exclusion_violation then null;
  end;
  insert into public.offre(id_espace,nom,type,prix,duree,date_debut,statut)
    values(espace,'Offre de vérification','ABONNEMENT',80.125,30,espace_prive.aujourdhui(),'ACTIVE')
    returning id_offre into offre;

  perform set_config('request.jwt.claims',jsonb_build_object('sub',autre_gestionnaire,'role','authenticated','is_anonymous',false)::text,true);
  update public.espace_sportif set nom='Interdit' where id_espace=espace;
  get diagnostics nombre = row_count;
  if nombre <> 0 then raise exception 'La séparation des gestionnaires a échoué.'; end if;

  perform set_config('request.jwt.claims',jsonb_build_object('sub',athlete,'role','authenticated','is_anonymous',false)::text,true);
  begin
    update public.profiles set role='ADMIN' where id=athlete;
    raise exception 'La modification du rôle doit être refusée.';
  exception when insufficient_privilege then null;
  end;
  begin
    update public.profiles set actif=false where id=athlete;
    raise exception 'La modification de l’activation doit être refusée.';
  exception when insufficient_privilege then null;
  end;
  update public.profiles set nom='Athlète de vérification' where id=athlete;
  get diagnostics nombre = row_count;
  if nombre <> 1 then raise exception 'La modification ordinaire du profil doit rester possible.'; end if;

  resultat := public.souscrire_offre(offre);
  id_abonnement_test := (resultat->>'id_abonnement')::bigint;
  if resultat->>'montant' <> '80.125' or (resultat->>'id_athlete')::uuid <> athlete
     or (resultat->>'date_fin')::date-(resultat->>'date_debut')::date <> 29 then
    raise exception 'Le contrat de souscription est incorrect.';
  end if;
  begin
    perform public.souscrire_offre(offre);
    raise exception 'Une souscription concurrente ou répétée doit être refusée.';
  exception when exclusion_violation then null;
  end;
  begin
    update public.abonnement set montant=0 where id_abonnement=id_abonnement_test;
    raise exception 'Le montant doit être immuable.';
  exception when insufficient_privilege then null;
  end;

  perform set_config('request.jwt.claims',jsonb_build_object('sub',autre_athlete,'role','authenticated','is_anonymous',false)::text,true);
  select count(*) into nombre from public.abonnement where id_abonnement=id_abonnement_test;
  if nombre <> 0 then raise exception 'Un autre athlète ne doit pas voir cet abonnement.'; end if;
  begin
    perform public.changer_statut_abonnement(id_abonnement_test,'ANNULE');
    raise exception 'Un autre athlète ne doit pas annuler cet abonnement.';
  exception when insufficient_privilege then null;
  end;

  perform set_config('request.jwt.claims',jsonb_build_object('sub',gestionnaire,'role','authenticated','is_anonymous',false)::text,true);
  resultat := public.changer_statut_abonnement(id_abonnement_test,'SUSPENDU');
  if resultat->>'statut' <> 'SUSPENDU' then raise exception 'La suspension a échoué.'; end if;
  resultat := public.changer_statut_abonnement(id_abonnement_test,'ACTIF');
  if resultat->>'statut' <> 'ACTIF' then raise exception 'La réactivation a échoué.'; end if;

  perform set_config('request.jwt.claims',jsonb_build_object('sub',athlete,'role','authenticated','is_anonymous',false)::text,true);
  resultat := public.changer_statut_abonnement(id_abonnement_test,'ANNULE');
  if resultat->>'statut' <> 'ANNULE' then raise exception 'L’annulation a échoué.'; end if;
  execute 'reset role';
end $$;

rollback;
select 'Contrôles transactionnels réussis. Aucune donnée de test conservée.' as resultat;
