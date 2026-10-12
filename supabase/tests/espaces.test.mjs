import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { test } from 'node:test';
import { PGlite } from '@electric-sql/pglite';
import { btree_gist } from '@electric-sql/pglite/contrib/btree_gist';

const uuid = (n) => `00000000-0000-0000-0000-${String(n).padStart(12, '0')}`;

test('Contrat SQL des espaces sportifs dans PostgreSQL isolé', async (t) => {
  const db = new PGlite({ extensions: { btree_gist } });
  t.after(() => db.close());
  await db.exec(await readFile(new URL('./fixtures.sql', import.meta.url), 'utf8'));
  const migration = await readFile(new URL('../migrations/20261011224412_espaces_sportifs.sql', import.meta.url), 'utf8');
  const actor = (id, fn, anonymous = false) => db.transaction(async (tx) => {
    await tx.exec('set local role authenticated');
    await tx.query("select set_config('request.jwt.claims',$1,true)",
      [JSON.stringify({ sub: uuid(id), is_anonymous: anonymous })]);
    return fn(tx);
  });
  const denied = (fn, code = '42501') => assert.rejects(fn, (error) => error.code === code);
  const one = async (tx, sql, params = []) => (await tx.query(sql, params)).rows[0];

  await t.test('La migration refuse les rôles modifiables par le client', async () => {
    await assert.rejects(db.exec(migration), /Protégez role et actif/);
    assert.equal((await one(db, "select to_regclass('public.espace_sportif') as table_name")).table_name, null);
  });

  // La protection partagée est simulée uniquement dans cette base de test.
  await db.exec(`revoke insert,update on public.profiles from authenticated;
    grant insert(id,nom,prenom),update(nom,prenom) on public.profiles to authenticated;`);
  await db.exec(migration);

  await t.test('Les tables, vues et fonctions exposent seulement les droits prévus', async () => {
    const tables = await db.query(`select relname,relrowsecurity from pg_class
      where relnamespace='public'::regnamespace and relname in
      ('espace_sportif','equipement','disponibilite_espace','offre','abonnement')`);
    assert.equal(tables.rows.length,5);
    assert.ok(tables.rows.every((table) => table.relrowsecurity));
    const views = await db.query(`select reloptions from pg_class where relnamespace='public'::regnamespace
      and relname in ('offres_lecture','abonnements_lecture')`);
    assert.ok(views.rows.every((view) => view.reloptions.includes('security_invoker=true')));
    const functions = await db.query(`select p.proname,p.prosecdef,n.nspname,
      has_function_privilege('anon',p.oid,'EXECUTE') as acces_anonyme
      from pg_proc p join pg_namespace n on n.oid=p.pronamespace
      where n.nspname='espace_prive' or (n.nspname='public' and p.proname in
      ('souscrire_offre','changer_statut_abonnement','contexte_espaces','rechercher_espaces'))`);
    assert.ok(functions.rows.every((fn) => !fn.acces_anonyme));
    assert.ok(functions.rows.filter((fn) => fn.nspname==='public').every((fn) => !fn.prosecdef));
  });

  let espace, autreEspace, equipement, offre, abonnement;
  await t.test('Le gestionnaire crée son espace avec des textes normalisés', async () => {
    espace = await actor(1, (tx) => one(tx, `insert into public.espace_sportif(nom,type,adresse,description,statut)
      values (' Salle A ','SALLE',' Tunis ','  ','ACTIF') returning *`));
    assert.equal(espace.id_gestionnaire, uuid(1));
    assert.equal(espace.nom, 'Salle A');
    assert.equal(espace.description, null);
    autreEspace = await actor(2, (tx) => one(tx, `insert into public.espace_sportif(nom,type,adresse)
      values ('Salle B','SALLE','Sousse') returning *`));
  });
  await t.test('Un athlète ne peut pas créer un espace', () => denied(() => actor(3, (tx) =>
    tx.exec("insert into public.espace_sportif(nom,type,adresse) values ('X','SALLE','X')"))));
  await t.test('Un autre gestionnaire ne peut pas modifier cet espace', async () => {
    const result = await actor(2, (tx) => tx.query('update public.espace_sportif set nom=$1 where id_espace=$2 returning id_espace', ['Intrusion', espace.id_espace]));
    assert.equal(result.rows.length, 0);
  });
  await t.test('La propriété ne peut pas être transférée', () => denied(() => actor(1, (tx) =>
    tx.query('update public.espace_sportif set id_gestionnaire=$1 where id_espace=$2', [uuid(2), espace.id_espace]))));
  await t.test('Les rôles et indicateurs actifs restent protégés', async () => {
    await denied(() => actor(3, (tx) => tx.exec("update public.profiles set role='ADMIN' where id=auth.uid()")));
    await denied(() => actor(6, (tx) => tx.exec('update public.profiles set actif=true where id=auth.uid()')));
    await denied(() => actor(9, (tx) => tx.exec("insert into public.profiles(id,role) values(auth.uid(),'ADMIN')")));
  });
  await t.test('Les coordonnées sont complètes et valides', async () => {
    await denied(() => actor(1, (tx) => tx.query('update public.espace_sportif set latitude=91,longitude=10 where id_espace=$1',[espace.id_espace])), '23514');
    await denied(() => actor(1, (tx) => tx.query('update public.espace_sportif set latitude=30 where id_espace=$1',[espace.id_espace])), '23514');
    await denied(() => actor(1, (tx) => tx.query("update public.espace_sportif set latitude='NaN',longitude=10 where id_espace=$1",[espace.id_espace])), '23514');
  });
  await t.test('Le catalogue est limité aux espaces actifs', async () => {
    const result = await actor(3, (tx) => tx.query('select * from public.rechercher_espaces()'));
    assert.deepEqual(result.rows.map((e) => e.id_espace), [espace.id_espace]);
    const mine = await actor(2, (tx) => tx.query('select * from public.rechercher_espaces(p_mes_espaces=>true)'));
    assert.deepEqual(mine.rows.map((e) => e.id_espace), [autreEspace.id_espace]);
  });
  await t.test('La recherche traite les caractères spéciaux comme du texte', async () => {
    assert.equal((await actor(3, (tx) => tx.query("select * from public.rechercher_espaces(p_recherche=>'tun')"))).rows.length, 1);
    assert.equal((await actor(3, (tx) => tx.query("select * from public.rechercher_espaces(p_recherche=>'%')"))).rows.length, 0);
    await denied(() => actor(3, (tx) => tx.exec('select * from public.rechercher_espaces(p_limite=>101)')), '22023');
  });
  await t.test('Les comptes inactifs, anonymes et absents ne lisent rien', async () => {
    for (const id of [6, 9]) assert.equal((await actor(id, (tx) => tx.query('select * from public.espace_sportif'))).rows.length, 0);
    assert.equal((await actor(3, (tx) => tx.query('select * from public.espace_sportif'), true)).rows.length, 0);
    await denied(() => db.transaction(async (tx) => {
      await tx.exec('set local role anon');
      await tx.exec('select * from public.espace_sportif');
    }));
  });
  await t.test('Les équipements restent rattachés à leur espace', async () => {
    equipement = await actor(1, (tx) => one(tx, `insert into public.equipement(nom,quantite,etat,id_espace)
      values ('Haltères',4,'BON',$1) returning *`, [espace.id_espace]));
    await denied(() => actor(2, (tx) => tx.query("insert into public.equipement(nom,quantite,etat,id_espace) values ('X',1,'BON',$1)",[espace.id_espace])));
    await denied(() => actor(1, (tx) => tx.query('update public.equipement set id_espace=$1 where id_equipement=$2',[autreEspace.id_espace,equipement.id_equipement])));
    await denied(() => actor(1, (tx) => tx.query('update public.equipement set quantite=-1 where id_equipement=$1',[equipement.id_equipement])), '23514');
  });
  await t.test('Les horaires acceptent une jonction mais refusent un chevauchement', async () => {
    await actor(1, (tx) => tx.query(`insert into public.disponibilite_espace(id_espace,jour,heure_ouverture,heure_fermeture)
      values ($1,'LUNDI','08:00','12:00'),($1,'LUNDI','12:00','18:00')`,[espace.id_espace]));
    await denied(() => actor(1, (tx) => tx.query(`insert into public.disponibilite_espace(id_espace,jour,heure_ouverture,heure_fermeture)
      values ($1,'LUNDI','11:00','13:00')`,[espace.id_espace])), '23P01');
    await denied(() => actor(1, (tx) => tx.query(`insert into public.disponibilite_espace(id_espace,jour,heure_ouverture,heure_fermeture)
      values ($1,'MARDI','23:00','01:00')`,[espace.id_espace])), '23514');
  });
  await t.test('Une offre respecte les millimes et la durée des séances', async () => {
    offre = await actor(1, (tx) => one(tx, `insert into public.offre(id_espace,nom,type,prix,duree,date_debut,statut)
      values ($1,'Accès','ABONNEMENT',80.125,30,espace_prive.aujourdhui(),'ACTIVE') returning *`, [espace.id_espace]));
    const lecture = await actor(3, (tx) => one(tx,'select * from public.offres_lecture where id_offre=$1',[offre.id_offre]));
    assert.equal(lecture.prix, '80.125');
    await denied(() => actor(1, (tx) => tx.query("update public.offre set type='SEANCE',duree=2 where id_offre=$1",[offre.id_offre])), '23514');
  });
  await t.test('La base calcule les dates, le prix et l’identité de la souscription', async () => {
    abonnement = (await actor(3, (tx) => one(tx,'select public.souscrire_offre($1) as a',[offre.id_offre]))).a;
    assert.equal(abonnement.id_athlete,uuid(3));
    assert.equal(abonnement.montant,'80.125');
    const duree = await one(db,'select date_fin-date_debut as jours from public.abonnement where id_abonnement=$1',[abonnement.id_abonnement]);
    assert.equal(duree.jours,29);
  });
  await t.test('Les doublons et écritures directes sont bloqués', async () => {
    await denied(() => actor(3, (tx) => tx.query('select public.souscrire_offre($1)',[offre.id_offre])), '23P01');
    await denied(() => actor(3, (tx) => tx.query('update public.abonnement set montant=0 where id_abonnement=$1',[abonnement.id_abonnement])));
    await denied(() => actor(3, (tx) => tx.query(`insert into public.abonnement(id_athlete,id_offre,date_debut,date_fin,montant)
      values (auth.uid(),$1,current_date,current_date,0)`,[offre.id_offre])));
  });
  await t.test('Un autre athlète ne lit ni ne modifie cet abonnement', async () => {
    assert.equal((await actor(4, (tx) => tx.query('select * from public.abonnements_lecture'))).rows.length,0);
    await denied(() => actor(4, (tx) => tx.query("select public.changer_statut_abonnement($1,'ANNULE')",[abonnement.id_abonnement])));
  });
  await t.test('Un athlète ne peut pas suspendre son abonnement', () => denied(() => actor(3, (tx) =>
    tx.query("select public.changer_statut_abonnement($1,'SUSPENDU')",[abonnement.id_abonnement])), '22023'));
  await t.test('Seul le gestionnaire concerné peut suspendre sans prolongation', async () => {
    await denied(() => actor(2, (tx) => tx.query("select public.changer_statut_abonnement($1,'SUSPENDU')",[abonnement.id_abonnement])));
    const a = (await actor(1, (tx) => one(tx,"select public.changer_statut_abonnement($1,'SUSPENDU') as a",[abonnement.id_abonnement]))).a;
    assert.equal(a.statut,'SUSPENDU');
    assert.equal(a.date_fin,abonnement.date_fin);
    await actor(1, (tx) => tx.query("select public.changer_statut_abonnement($1,'ACTIF')",[abonnement.id_abonnement]));
  });
  await t.test('Les changements de prix ne modifient pas les contrats existants', async () => {
    await actor(1, (tx) => tx.query('update public.offre set prix=100 where id_offre=$1',[offre.id_offre]));
    const a = await actor(3, (tx) => one(tx,'select * from public.abonnements_lecture where id_abonnement=$1',[abonnement.id_abonnement]));
    assert.equal(a.montant,'80.125');
  });
  await t.test('L’historique reste visible après désactivation, sans ouvrir les autres offres', async () => {
    await actor(1, (tx) => tx.query("update public.espace_sportif set statut='INACTIF' where id_espace=$1",[espace.id_espace]));
    assert.equal((await actor(3, (tx) => tx.query('select * from public.espace_sportif'))).rows.length,1);
    assert.equal((await actor(3, (tx) => tx.query('select * from public.rechercher_espaces()'))).rows.length,0);
    assert.equal((await actor(4, (tx) => tx.query('select * from public.offres_lecture'))).rows.length,0);
    await denied(() => actor(4, (tx) => tx.query('select public.souscrire_offre($1)',[offre.id_offre])), '22023');
    await actor(1, (tx) => tx.query("update public.espace_sportif set statut='ACTIF' where id_espace=$1",[espace.id_espace]));
  });
  await t.test('L’annulation est idempotente et libère une nouvelle souscription', async () => {
    for (let i=0;i<2;i++) {
      const a = (await actor(3, (tx) => one(tx,"select public.changer_statut_abonnement($1,'ANNULE') as a",[abonnement.id_abonnement]))).a;
      assert.equal(a.statut,'ANNULE');
    }
    await denied(() => actor(1, (tx) => tx.query("select public.changer_statut_abonnement($1,'ACTIF')",[abonnement.id_abonnement])), '22023');
    await actor(3, (tx) => tx.query('select public.souscrire_offre($1)',[offre.id_offre]));
  });
  await t.test('La date serveur détermine l’expiration même sans tâche planifiée', async () => {
    const old = await one(db,`insert into public.abonnement(id_athlete,id_offre,date_debut,date_fin,montant)
      values ($1,$2,espace_prive.aujourdhui()-2,espace_prive.aujourdhui()-1,1) returning id_abonnement`,[uuid(4),offre.id_offre]);
    const lecture = await actor(4, (tx) => one(tx,'select * from public.abonnements_lecture where id_abonnement=$1',[old.id_abonnement]));
    assert.equal(lecture.statut,'EXPIRE');
    const transition = (await actor(1, (tx) => one(tx,"select public.changer_statut_abonnement($1,'SUSPENDU') as a",[old.id_abonnement]))).a;
    assert.equal(transition.statut,'EXPIRE');
  });
  await t.test('Les suppressions métier sont interdites et les profils référencés conservés', async () => {
    await denied(() => actor(1, (tx) => tx.query('delete from public.espace_sportif where id_espace=$1',[espace.id_espace])));
    await denied(() => actor(3, (tx) => tx.query('delete from public.abonnement where id_abonnement=$1',[abonnement.id_abonnement])));
    await assert.rejects(() => db.query('delete from public.profiles where id=$1',[uuid(1)]),
      (error) => ['23001','23503'].includes(error.code));
  });
  await t.test('Les administrateurs lisent les contrats, les coachs et nutritionnistes non', async () => {
    assert.ok((await actor(5, (tx) => tx.query('select * from public.abonnements_lecture'))).rows.length > 0);
    for (const id of [7,8]) assert.equal((await actor(id, (tx) => tx.query('select * from public.abonnements_lecture'))).rows.length,0);
  });
});
