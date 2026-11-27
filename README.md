# Supermarchés Grand Est — chaîne mensuelle des ventes

Consolide chaque mois les ventes des quatre magasins (Strasbourg,
Mulhouse, Nancy, Metz), les enrichit du référentiel produits et les
charge dans l'entrepôt PostgreSQL. La chaîne est lancée une fois par
mois, à la réception des fichiers des magasins.

## Entrées

- Dans `data/landing/`, un fichier de ventes par magasin et par mois :
  `ventes_MAG-XXX-01_AAAA-MM.csv`. Séparateur « ; », décimale « , ».
- Metz est encodé en ISO-8859-1, les trois autres magasins en UTF-8.
- Le référentiel produits est lu dans la base, table
  `referentiel_produit`.

## Sorties

- table `entrepot_vente` : une ligne par vente ; le triplet
  `code_magasin`, `id_ticket`, `code_produit` est unique (`uk_vente`) ;
- table `journal_rejet` : les lignes refusées par la base, avec leur
  motif et la ligne d'origine ;
- table `journal_execution` : les compteurs et la durée de chaque
  exécution, avec le mois traité ;
- `data/staging/ventes_consolidees_AAAA-MM.csv` : fichier consolidé
  intermédiaire, régénéré à chaque exécution ;
- `data/rejets/` : les lignes écartées par le nettoyage de la reprise ;
- `data/entrepot/` : les exports JSON et les synthèses par rayon.

## Organisation du projet

```
data/
├── landing/     fichiers reçus, jamais modifiés
├── staging/     intermédiaires, jetables
├── rejets/      lignes écartées, avec leur motif
└── entrepot/    fichiers livrés
pipelines/
├── ventes/          extraction, nettoyage et chargements des ventes
├── referentiels/    mise à jour du référentiel produits
├── restitution/     agrégation par rayon, exports
└── supervision/     journal d'exécution
workflows/       05d_chaine_mensuelle : la chaîne orchestrée
datasets/        jeux de données des tests unitaires
infra/           base PostgreSQL (Docker)
docs/            documentation, modèle d'environnement
```

Les chemins passent par des variables du projet : `INPUTS_DIR`
(landing), `STAGING_DIR`, `REJETS_DIR` et `OUTPUTS_DIR` (entrepot).

## Prérequis

- Apache Hop 2.19 et Java 17 ;
- Docker Desktop ;
- Git, pour suivre les modifications.

## Installation

1. Démarrer la base : dans `infra/`, `docker compose up -d`.
2. Copier `docs/env-dev.json.exemple` **hors du projet**, sous le nom
   `env-dev.json`, et y renseigner les vraies valeurs.
3. Dans Hop, ajouter le projet (dossier du projet), puis créer
   l'environnement `sge-corrige-j6-dev` qui pointe vers ce fichier.
4. Vérifier : tester la connexion `sge_postgres`, puis lancer la
   chaîne. On doit obtenir 37 983 lignes dans `entrepot_vente` :

        docker exec -it sge-postgres psql -U hop -d supermarches -c "SELECT count(*) FROM entrepot_vente;"

## Lancer la chaîne

Depuis le dossier d'installation de Hop, dans PowerShell :

    .\hop-run.bat -e sge-corrige-j6-dev -r local -f '${PROJECT_HOME}/workflows/05d_chaine_mensuelle.hwf' -p MOIS=2026-01 -l BASIC

Code de sortie : 0 en cas de succès, 1 en cas d'échec. Il se lit dans
`$LASTEXITCODE`.

Paramètre `MOIS` : le mois à traiter, au format `AAAA-MM`. Valeur par
défaut : `2026-01`. Les apostrophes autour de `${PROJECT_HOME}` sont
nécessaires : sans elles, PowerShell remplace la variable avant que Hop
ne la reçoive.

La chaîne vérifie la présence des quatre fichiers du mois et
l'accessibilité de la base, puis lance `02c_extraction_enrichie` et
`04a2_chargement_rejouable`. Elle s'arrête en échec si une condition
manque, et le journal désigne le fichier absent.

## Décisions de traitement

- Chargement par *Insert / Update* sur la clé `uk_vente` : une relance
  ne produit ni doublon ni erreur.
- Prix à 0 ou au-delà de 500 € rejetés au nettoyage de la reprise ;
  quantités négatives conservées, car ce sont des retours de
  marchandise ; doublons exacts supprimés.
- `04d_chargement_complement` est exclu de la chaîne : il n'est pas
  rejouable, chaque relance réécrit ses rejets dans `journal_rejet`.
- Les traitements ponctuels (`03b`, `03c`, `04b`, `04c`, `04d`,
  `04e`) se lancent à la main, quand le besoin se présente.

Le détail de chaque décision est sur les notes des canevas.

## Contrôles

- `entrepot_vente` : 37 983 lignes à l'état de référence.
- `journal_execution` : une ligne par pipeline et par exécution, avec
  ses compteurs ; une relance sans nouveau fichier donne U=0.
- `journal_rejet` : 12 lignes, avec leur motif.
- Test unitaire de `03b_nettoyage_reprise`, sur
  `ventes_test_nettoyage.csv` : 5 lignes nettoyées et 5 lignes
  rejetées. À relancer après toute modification du nettoyage.

## Intégration Primeurs du Rhin (ajout PDR)

Intègre les ventes des 3 magasins PDR (Colmar, Sélestat, Obernai) dans
`entrepot_vente`, sans toucher aux ventes existantes. Lancement :

    .\hop-run.bat -e sge-reference-dev -r local -f '${PROJECT_HOME}/workflows/06_integration_pdr.hwf' -p MOIS=2026-01 -l BASIC

Le workflow vérifie les 3 fichiers et la base, puis lance
`06a_referentiel_pdr` (ajout des produits PDR au référentiel) et
`06b_ventes_pdr` (lecture, dédoublonnage, chargement).

Hypothèses :

- doublons exacts de Colmar (210 lignes) écartés dans `data/rejets/` ;
- magasins renommés `MAG-COL-01`, `MAG-SEL-01`, `MAG-OBE-01` ;
- 11 articles sans correspondance : code provisoire `PRD-A-XXXX`,
  TVA 5,5 %, à valider par les achats.

Chiffres attendus : 11 984 ventes PDR chargées (56 856,35 €), 49 967
lignes au total dans `entrepot_vente` (274 420,90 €), 30 produits.

## Vérification des chiffres attendus

Ventes et CA par magasin :

    docker exec -it sge-postgres psql -U hop -d supermarches -c "SELECT code_magasin, count(*), sum(montant_ttc) FROM entrepot_vente GROUP BY 1 ORDER BY 1;"

Total PDR (attendu : 11 984 lignes, 56 856,35 €) :

    docker exec -it sge-postgres psql -U hop -d supermarches -c "SELECT count(*), sum(montant_ttc) FROM entrepot_vente WHERE code_magasin IN ('MAG-COL-01','MAG-SEL-01','MAG-OBE-01');"

Total entrepôt (attendu : 49 967 lignes, 274 420,90 €) :

    docker exec -it sge-postgres psql -U hop -d supermarches -c "SELECT count(*), sum(montant_ttc) FROM entrepot_vente;"

Référentiel (attendu : 30 produits) :

    docker exec -it sge-postgres psql -U hop -d supermarches -c "SELECT count(*) FROM referentiel_produit;"