/* Évalue les informations de session une seule fois par requête. */
alter policy espace_lecture on public.espace_sportif using (
  (select espace_prive.role_actif())='ADMIN' or
  ((select espace_prive.role_actif())='GESTIONNAIRE_ESPACE' and id_gestionnaire=(select auth.uid())) or
  espace_prive.lit_espace(id_espace)
);
alter policy espace_creation on public.espace_sportif with check (
  (select espace_prive.role_actif())='GESTIONNAIRE_ESPACE' and id_gestionnaire=(select auth.uid())
);
alter policy abonnement_lecture on public.abonnement using (
  (select espace_prive.role_actif()) is not null and (
    ((select espace_prive.role_actif())='ATHLETE' and id_athlete=(select auth.uid())) or espace_prive.gere_offre(id_offre)
  )
);
