-- ============================================================================
-- SCRIPT SQL SUPABASE : MODULE GESTION 4 - NUTRITION & SUIVI
-- À exécuter dans le "SQL Editor" de votre tableau de bord Supabase.
-- ============================================================================

-- 1. ENUMS
DO $$ BEGIN
    CREATE TYPE objectif_nutrition AS ENUM ('PERTE_POIDS', 'PRISE_MASSE', 'MAINTIEN', 'PERFORMANCE');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE statut_consultation AS ENUM ('DEMANDEE', 'CONFIRMEE', 'TERMINEE', 'ANNULEE');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE statut_programme_nutrition AS ENUM ('ACTIF', 'TERMINE', 'SUSPENDU', 'ANNULE');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE type_repas AS ENUM ('PETIT_DEJEUNER', 'DEJEUNER', 'DINER', 'COLLATION');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- 2. TABLE : DOSSIER NUTRITIONNEL (1 athlète = 1 dossier)
CREATE TABLE IF NOT EXISTS dossier_nutritionnel (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_athlete UUID NOT NULL,
    objectif VARCHAR(50) NOT NULL DEFAULT 'PERTE_POIDS',
    poids_initial NUMERIC(5,2) NOT NULL,
    poids_actuel NUMERIC(5,2) NOT NULL,
    poids_cible NUMERIC(5,2) NOT NULL,
    taille_cm NUMERIC(5,2),
    remarques TEXT,
    date_creation TIMESTAMPTZ DEFAULT NOW(),
    date_mise_a_jour TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_athlete_dossier UNIQUE (id_athlete)
);

-- 3. TABLE : CONSULTATION (Athlète 1..N - Consultation - N..1 Nutritionniste)
CREATE TABLE IF NOT EXISTS consultation_nutrition (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_athlete UUID NOT NULL,
    id_nutritionniste UUID NOT NULL,
    date_consultation DATE NOT NULL,
    heure_consultation VARCHAR(10) NOT NULL,
    motif TEXT NOT NULL,
    compte_rendu TEXT,
    statut VARCHAR(50) NOT NULL DEFAULT 'DEMANDEE',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. TABLE : PROGRAMME NUTRITIONNEL (Dossier 1..N - Programmes)
CREATE TABLE IF NOT EXISTS programme_nutritionnel (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_dossier UUID NOT NULL REFERENCES dossier_nutritionnel(id) ON DELETE CASCADE,
    id_nutritionniste UUID,
    titre VARCHAR(150) NOT NULL,
    description TEXT,
    calories_cible INT NOT NULL,
    proteines_cible_g NUMERIC(6,2) NOT NULL,
    glucides_cible_g NUMERIC(6,2) NOT NULL,
    lipides_cible_g NUMERIC(6,2) NOT NULL,
    statut VARCHAR(50) NOT NULL DEFAULT 'ACTIF',
    budget_montant NUMERIC(8,2) DEFAULT 0,
    budget_devise VARCHAR(5) DEFAULT 'EUR',
    date_debut DATE NOT NULL,
    date_fin DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. TABLE : REPAS (Programme 1..N - Repas)
CREATE TABLE IF NOT EXISTS repas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_programme UUID NOT NULL REFERENCES programme_nutritionnel(id) ON DELETE CASCADE,
    nom VARCHAR(120) NOT NULL,
    type VARCHAR(50) NOT NULL,
    heure_recommandee VARCHAR(10),
    calories INT NOT NULL DEFAULT 0,
    proteines_g NUMERIC(6,2) DEFAULT 0,
    glucides_g NUMERIC(6,2) DEFAULT 0,
    lipides_g NUMERIC(6,2) DEFAULT 0,
    aliments_json JSONB DEFAULT '[]'::jsonb,
    ordre INT DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour les recherches rapides
CREATE INDEX IF NOT EXISTS idx_dossier_athlete ON dossier_nutritionnel(id_athlete);
CREATE INDEX IF NOT EXISTS idx_consult_athlete ON consultation_nutrition(id_athlete);
CREATE INDEX IF NOT EXISTS idx_consult_nutri ON consultation_nutrition(id_nutritionniste);
CREATE INDEX IF NOT EXISTS idx_programme_dossier ON programme_nutritionnel(id_dossier);
CREATE INDEX IF NOT EXISTS idx_repas_programme ON repas(id_programme);
