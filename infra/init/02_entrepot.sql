-- Entrepôt de ventes et journal des rejets
-- Supermarchés Grand Est

CREATE TABLE entrepot_vente (
    id_vente        BIGSERIAL PRIMARY KEY,
    code_magasin    VARCHAR(20)  NOT NULL,
    id_ticket       VARCHAR(20)  NOT NULL,
    code_produit    VARCHAR(12)  NOT NULL,
    date_vente      DATE         NOT NULL,
    heure_vente     TIME,
    rayon           VARCHAR(40),
    fournisseur     VARCHAR(60),
    quantite        INTEGER      NOT NULL,
    prix_unitaire   NUMERIC(10,2) NOT NULL,
    montant_ttc     NUMERIC(12,2) NOT NULL,
    taux_tva        NUMERIC(4,1),
    montant_ht      NUMERIC(12,2),
    montant_tva     NUMERIC(12,2),
    mode_paiement   VARCHAR(20),
    date_chargement TIMESTAMP    NOT NULL DEFAULT now(),
    CONSTRAINT uk_vente UNIQUE (code_magasin, id_ticket, code_produit)
);

CREATE INDEX idx_vente_date   ON entrepot_vente (date_vente);
CREATE INDEX idx_vente_magasin ON entrepot_vente (code_magasin);

CREATE TABLE journal_rejet (
    -- Les colonnes sont volontairement larges et sans contrainte :
    -- le journal doit accepter ce que la table cible a refusé.
    id_rejet        BIGSERIAL PRIMARY KEY,
    date_rejet      TIMESTAMP    NOT NULL DEFAULT now(),
    pipeline        TEXT,
    code_magasin    TEXT,
    id_ticket       TEXT,
    code_produit    TEXT,
    motif           TEXT,
    ligne_source    TEXT
);
