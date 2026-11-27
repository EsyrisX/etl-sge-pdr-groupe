CREATE TABLE referentiel_produit (
    code_produit    VARCHAR(12) PRIMARY KEY,
    libelle         VARCHAR(80) NOT NULL,
    rayon           VARCHAR(40) NOT NULL,
    prix_reference  NUMERIC(8,2) NOT NULL,
    fournisseur     VARCHAR(60),
    taux_tva        NUMERIC(4,1) NOT NULL
);

INSERT INTO referentiel_produit VALUES
('PRD-0011', 'Baguette tradition', 'Boulangerie', 1.20, 'Moulins d''Alsace', 5.5),
('PRD-0012', 'Pain de campagne', 'Boulangerie', 3.40, 'Moulins d''Alsace', 5.5),
('PRD-0021', 'Lait demi-écrémé 1L', 'Crèmerie', 1.05, 'Laiterie du Ried', 5.5),
('PRD-0022', 'Beurre doux 250g', 'Crèmerie', 2.75, 'Laiterie du Ried', 5.5),
('PRD-0023', 'Yaourt nature x4', 'Crèmerie', 1.90, 'Laiterie du Ried', 5.5),
('PRD-0031', 'Pommes Gala 1kg', 'Fruits et légumes', 2.60, 'Vergers de Sélestat', 5.5),
('PRD-0032', 'Bananes 1kg', 'Fruits et légumes', 1.95, 'Import Primeurs SA', 5.5),
('PRD-0033', 'Tomates grappe 1kg', 'Fruits et légumes', 3.20, 'Vergers de Sélestat', 5.5),
('PRD-0041', 'Poulet fermier', 'Boucherie', 9.80, 'Volailles de Kochersberg', 5.5),
('PRD-0042', 'Steak haché 2x125g', 'Boucherie', 4.50, 'Boucherie Centrale Est', 5.5),
('PRD-0051', 'Riz basmati 1kg', 'Épicerie', 3.10, 'Grossiste Rhin Sud', 5.5),
('PRD-0052', 'Pâtes penne 500g', 'Épicerie', 1.15, 'Grossiste Rhin Sud', 5.5),
('PRD-0053', 'Huile d''olive 75cl', 'Épicerie', 7.40, 'Grossiste Rhin Sud', 5.5),
('PRD-0061', 'Eau minérale 6x1,5L', 'Boissons', 2.30, 'Sources Vosgiennes', 5.5),
('PRD-0062', 'Jus d''orange 1L', 'Boissons', 1.85, 'Sources Vosgiennes', 5.5),
('PRD-0071', 'Lessive liquide 2L', 'Entretien', 8.90, 'Chimie Ménagère Est', 20.0),
('PRD-0072', 'Papier toilette x12', 'Entretien', 5.60, 'Chimie Ménagère Est', 20.0);
