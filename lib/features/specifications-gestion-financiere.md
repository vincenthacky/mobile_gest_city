# Spécifications Techniques - Module Gestion Financière

**Version:** 1.0  
**Date:** 03 Novembre 2025  
**Statut:** Final

---

## Table des Matières

1. [Vue d'ensemble](#vue-densemble)
2. [Architecture de navigation](#architecture-de-navigation)
3. [Page 1: Wallet](#page-1-wallet)
4. [Page 2: Ventilation des paiements](#page-2-ventilation-des-paiements)
5. [Page 3: Mes cotisations mensuelles](#page-3-mes-cotisations-mensuelles)
6. [Fonctionnalités transversales](#fonctionnalités-transversales)
7. [Modèles de données](#modèles-de-données)
8. [Règles métier](#règles-métier)
9. [Permissions et rôles](#permissions-et-rôles)

---

## Vue d'ensemble

Le module **Gestion Financière** permet de gérer le système de cotisations mensuelles d'une association/groupe. Il gère trois problématiques principales :

1. **Suivi du solde global** (Wallet)
2. **Attribution correcte des paiements aux mois correspondants** (Ventilation)
3. **Gestion des cotisations individuelles** (Mes cotisations)

### Concepts clés

- **Cotisation mensuelle** : Paiement obligatoire mensuel par membre
- **Ventilation** : Attribution d'un paiement au mois auquel il correspond réellement (différent du mois de réception si paiement en retard)
- **Préfinancement** : Avance d'argent par un membre pour un projet
- **Montant participatif** : Contribution volontaire supplémentaire

---

## Architecture de navigation

```
📊 GESTION FINANCIÈRE
│
├─ 💰 Wallet (Page par défaut)
│   │
│   ├─ Card Wallet principal
│   ├─ Card Mois en cours
│   └─ Liste des transactions
│       └─ [Clic] → Page détail transaction
│
├─ 📋 Ventilation des paiements
│   │
│   ├─ Sélecteur de période (1-6 / 7-12)
│   ├─ Tableau de ventilation
│   │   └─ [Bouton "Voir plus..."] → Génération PDF
│   └─ Bilan mensuel
│
└─ 💳 Mes cotisations mensuelles
    │
    ├─ Card récapitulatif
    ├─ Bouton "Payer" (conditionnel)
    │   └─ [Clic] → Modal de paiement
    └─ Liste de mes paiements
        └─ [Clic] → Page détail paiement
```

---

## Page 1: Wallet

### 1.1 Card Wallet Principal

**Position:** Haut de page

**Contenu:**

```
┌────────────────────────────────────────────────────┐
│  💰 WALLET                                         │
│                                                    │
│  Montant actuel         1 250,00 €                │
│  Montant entré         +5 400,00 €                │
│  Montant sorti         -4 150,00 €                │
└────────────────────────────────────────────────────┘
```

**Données affichées:**

| Champ | Description | Calcul |
|-------|-------------|--------|
| Montant actuel | Solde disponible actuel | Total entrées - Total sorties |
| Montant entré | Total des recettes cumulées | Somme de tous les crédits |
| Montant sorti | Total des dépenses cumulées | Somme de tous les débits |

**Design:**
- Card avec fond légèrement différencié
- Typographie: Montant actuel en plus grand (32px), autres montants en 24px
- Couleur: Montant actuel en vert si positif, rouge si négatif
- Icône 💰 à gauche du titre

---

### 1.2 Card Mois en Cours

**Position:** Directement sous le Card Wallet principal

**Contenu:**

```
┌────────────────────────────────────────────────────┐
│  📅 NOVEMBRE 2025                                  │
│                                                    │
│  Cotisation réelle              1 200,00 €        │
│  Rattrapage de retard            +150,00 €        │
│  Montant encaissé               1 350,00 €        │
│  Montant ventilé                1 200,00 €        │
│  ─────────────────────────────────────────         │
│  Charges récurrentes             -250,00 €        │
│  • Gardiennage                                     │
│  Dépenses exceptionnelles        -500,00 €        │
│  • Financement Projet X                            │
└────────────────────────────────────────────────────┘
```

**Données affichées:**

| Champ | Description |
|-------|-------------|
| Cotisation réelle | Montant des cotisations appartenant au mois en cours (même si payées en retard) |
| Rattrapage de retard | Paiements de retard des mois précédents reçus ce mois |
| Montant encaissé | Total reçu durant le mois (tous types confondus) |
| Montant ventilé | Montant des cotisations reçues durant le mois |
| Charges récurrentes | Dépenses mensuelles fixes avec détail |
| Dépenses exceptionnelles | Dépenses ponctuelles avec détail |

**Design:**
- Card avec bordure subtile
- Séparateur horizontal entre recettes et dépenses
- Liste à puces pour détails des charges/dépenses (max 3 lignes, "..." si plus)
- Couleurs: vert pour montants positifs, rouge pour négatifs

---

### 1.3 Liste des Transactions

**Position:** Sous les deux cards

**En-tête:**
```
Transactions récentes
[Filtre: Tout ▼] [Période: Ce mois ▼]
```

**Structure d'une ligne - CRÉDIT (entrée):**

```
┌────────────────────────────────────────────────────┐
│ ↗️ Marie DUPONT                        +50,00 €    │
│    Cotisation mensuelle • 15 Nov 2025              │
└────────────────────────────────────────────────────┘
```

**Structure d'une ligne - DÉBIT (sortie):**

```
┌────────────────────────────────────────────────────┐
│ ↙️ Financement Projet Alpha           -500,00 €    │
│    Dépense exceptionnelle • 10 Nov 2025            │
└────────────────────────────────────────────────────┘
```

**Données affichées par transaction:**

**Pour les CRÉDITS:**
- Nom de la personne
- Montant (en vert, préfixe +)
- Type de transaction:
  - Cotisation mensuelle
  - Montant participatif
  - Préfinancement
- Date

**Pour les DÉBITS:**
- Raison de la dépense
- Montant (en rouge, préfixe -)
- Type de transaction:
  - Financement de projet
  - Remboursement de préfinancement
  - Charge récurrente
- Date

**Fonctionnalités:**
- Pagination: 10 transactions par page
- Tri par défaut: Plus récent en premier
- Filtres disponibles:
  - Type: Tout / Crédits / Débits
  - Période: Ce mois / Mois dernier / 3 derniers mois / Personnalisé
- Clic sur une ligne → Ouverture page détail transaction

**Design:**
- Alternance de fond (blanc/gris très léger) entre les lignes
- Icône ↗️ pour crédits, ↙️ pour débits
- Hover: légère élévation de la ligne
- Responsive: sur mobile, affichage vertical compact

---

### 1.4 Page Détail Transaction

**Déclenchement:** Clic sur une transaction dans la liste

**URL:** `/gestion-financiere/transactions/{id}`

**Contenu - Exemple CRÉDIT:**

```
┌────────────────────────────────────────────────────┐
│  ← Retour                                          │
│                                                    │
│  TRANSACTION #12345                                │
│                                                    │
│  Type               Crédit                         │
│  Montant            +50,00 €                       │
│  Date de réception  15 Novembre 2025, 14:23       │
│                                                    │
│  ─────────────────────────────────────────         │
│                                                    │
│  Payeur             Marie DUPONT                   │
│  Catégorie          Cotisation mensuelle           │
│  Mois ventilé       Novembre 2025                  │
│  Mode de paiement   Mobile Money                   │
│  Statut             Validé ✅                      │
│  Validé par         Admin KONAN (15/11/2025)      │
│                                                    │
│  Justificatif       [📄 Voir le reçu]             │
│                                                    │
│  Notes                                             │
│  Paiement effectué via Orange Money                │
└────────────────────────────────────────────────────┘
```

**Contenu - Exemple DÉBIT:**

```
┌────────────────────────────────────────────────────┐
│  ← Retour                                          │
│                                                    │
│  TRANSACTION #12346                                │
│                                                    │
│  Type               Débit                          │
│  Montant            -500,00 €                      │
│  Date               10 Novembre 2025, 10:15        │
│                                                    │
│  ─────────────────────────────────────────         │
│                                                    │
│  Raison             Financement Projet Alpha       │
│  Catégorie          Dépense exceptionnelle         │
│  Bénéficiaire       Association XYZ                │
│  Autorisé par       Admin KONAN                    │
│                                                    │
│  Pièces jointes     [📄 Facture.pdf]              │
│                     [📄 Devis.pdf]                 │
│                                                    │
│  Notes                                             │
│  Paiement pour location de matériel                │
└────────────────────────────────────────────────────┘
```

**Actions possibles (selon permissions):**
- [Bouton] Modifier (admin uniquement)
- [Bouton] Supprimer (admin uniquement, avec confirmation)
- [Bouton] Télécharger justificatif

---

## Page 2: Ventilation des paiements

### 2.1 Objectif

Afficher un tableau permettant de visualiser rapidement quels membres ont payé leur cotisation pour chaque mois, en distinguant le mois de réception du mois auquel appartient réellement le paiement.

### 2.2 Sélecteur de Période

**Position:** Haut de page

**Design inspiré de la capture:**

```
┌────────────────────────────────────────────────────┐
│  Ventilation    Épisodes                           │
│                                                    │
│  [1-6]  [31-60]  [61-68]                          │
└────────────────────────────────────────────────────┘
```

**Adaptation au contexte:**

```
┌────────────────────────────────────────────────────┐
│  Ventilation des cotisations                       │
│                                                    │
│  [ 1-6 ]  [ 7-12 ]                                │
│  Jan-Juin  Juil-Déc                                │
└────────────────────────────────────────────────────┘
```

**Comportement:**
- **Par défaut:** Affiche la période contenant le mois en cours
  - Exemple: Si on est en Novembre → période [7-12] active
- **État actif:** Bouton avec fond rose (comme l'élément 7 sur la capture)
- **État inactif:** Bouton avec fond gris foncé
- **Clic:** Change la période affichée dans le tableau

---

### 2.3 Tableau de Ventilation

**Structure:**

```
┌──────────────┬─────┬─────┬─────┬─────┬─────┬─────┐
│   Membre     │ Juil│ Août│ Sep │ Oct │ Nov │ Déc │
├──────────────┼─────┼─────┼─────┼─────┼─────┼─────┤
│ Marie DUPONT │  ✅  │  ✅  │  ❌  │  ✅  │  ✅  │  🔒  │
│ Paul MARTIN  │  ✅  │  ✅  │  ✅  │  ✅  │  ❌  │  🔒  │
│ Jean KOUASSI │  ❌  │  ✅  │  ✅  │  ✅  │  ✅  │  🔒  │
│ Sophie BROU  │  ✅  │  ❌  │  ✅  │  ❌  │  ✅  │  🔒  │
│ Thomas YAO   │  ✅  │  ✅  │  ✅  │  ✅  │  ✅  │  🔒  │
└──────────────┴─────┴─────┴─────┴─────┴─────┴─────┘

                    [ Voir plus... ]
```

**Légende des icônes:**
- ✅ : Cotisation payée pour ce mois
- ❌ : Cotisation non payée pour ce mois
- 🔒 : Mois futur (verrouillé)

**Spécifications:**

| Élément | Description |
|---------|-------------|
| Affichage | 5 premières lignes uniquement |
| Tri | Alphabétique par nom de famille |
| Colonnes | 6 mois de la période sélectionnée |
| En-tête colonne | Abréviation du mois (3 premières lettres) |
| En-tête ligne | Nom Prénom du membre |

**Logique de remplissage:**
- Un membre a payé sa cotisation de Septembre → ✅ dans la colonne "Sep"
- Même s'il a payé en retard (ex: le 15 octobre), la ✅ apparaît en Septembre
- Les mois futurs affichent 🔒

**Comportement responsive:**
- Desktop: Tableau complet
- Tablet: Scroll horizontal
- Mobile: Affichage carte par carte (une personne par carte)

---

### 2.4 Bouton "Voir plus..."

**Position:** Centré sous le tableau

**Comportement:**
- Clic → Génération d'un fichier PDF
- PDF contient:
  - La liste complète de tous les membres (pas seulement 5)
  - Le tableau avec les 6 mois de la période sélectionnée
  - Un header avec le nom de l'association, la date de génération
  - Un footer avec numéro de page

**Spécifications du PDF:**
- Format: A4 paysage
- Police: Arial ou équivalent
- Taille police: 10pt pour le tableau
- Nom du fichier: `ventilation-cotisations-[periode]-[date].pdf`
  - Exemple: `ventilation-cotisations-juil-dec-2025-03-11-2025.pdf`

**Implémentation technique:**
- Bibliothèque suggérée: jsPDF + autoTable (JavaScript)
- ou ReportLab (Python backend)
- Génération côté backend recommandée pour de grosses listes

---

### 2.5 Bilan Mensuel

**Position:** Sous le tableau de ventilation

**Titre:** "Bilan mensuel"

**Structure:**

```
┌────────────┬──────────────────┬─────────────────────┐
│   Mois     │ Montant réel     │ Montant ventilé     │
│            │ payé             │ reçu                │
├────────────┼──────────────────┼─────────────────────┤
│ Juillet    │ 1 200,00 €       │ 1 150,00 €          │
│ Août       │ 1 180,00 €       │ 1 250,00 €          │
│ Septembre  │ 1 150,00 €       │ 1 200,00 €          │
│ Octobre    │ 1 200,00 €       │ 1 180,00 €          │
│ Novembre   │ 1 250,00 €       │ 1 350,00 €          │
│ Décembre   │     -            │     -               │
├────────────┼──────────────────┼─────────────────────┤
│ TOTAL      │ 5 980,00 €       │ 6 130,00 €          │
└────────────┴──────────────────┴─────────────────────┘
```

**Définitions:**

| Colonne | Description | Exemple |
|---------|-------------|---------|
| Montant réel payé | Somme des cotisations qui **appartiennent** à ce mois, peu importe quand elles ont été payées | Si 24 membres sur 25 ont payé leur cotisation de Juillet (même en retard) : 24 × 50€ = 1 200€ |
| Montant ventilé reçu | Somme de tout l'argent **reçu** durant ce mois (cotisations + rattrapages + participations) | Juillet : reçu 23 cotisations de juillet + 1 cotisation de juin en retard = 1 200€ |

**Affichage:**
- Affiche les 6 mois de la période sélectionnée
- Mois futurs: affichent "-"
- Ligne TOTAL: somme des montants (hors mois futurs)
- Responsive: scroll horizontal sur mobile

---

## Page 3: Mes cotisations mensuelles

### 3.1 Card Récapitulatif

**Position:** Haut de page

**Contenu:**

```
┌────────────────────────────────────────────────────┐
│  💳 COTISATIONS MENSUELLES                         │
│                                                    │
│  Montant par personne       50,00 €               │
│  Jour limite                5 de chaque mois       │
│                                                    │
│  ─────────────────────────────────────────         │
│                                                    │
│  Ce mois-ci                                        │
│  1 200,00 € / 1 500,00 €                          │
│                                                    │
│  ▰▰▰▰▰▰▰▰▰▰▰▰▱▱▱▱▱▱▱▱  80%                         │
│                                                    │
│  24 membres sur 30 ont payé                        │
└────────────────────────────────────────────────────┘
```

**Données affichées:**

| Champ | Description |
|-------|-------------|
| Montant par personne | Montant fixe de la cotisation mensuelle |
| Jour limite | Échéance mensuelle (ex: le 5 de chaque mois) |
| Collecté / Attendu | Montant collecté ce mois / Montant total attendu |
| Barre de progression | Visualisation du pourcentage collecté |
| Compteur | Nombre de membres ayant payé / Total de membres |

**Design:**
- Barre de progression:
  - Couleur verte si ≥ 80%
  - Couleur orange si 50-79%
  - Couleur rouge si < 50%

---

### 3.2 Bouton "Payer votre cotisation"

**Positionnement suggéré:** Directement sous le card récapitulatif, centré

**Logique d'affichage:**

```
SI utilisateur.cotisationMoisEnCours == Non payée ALORS
    Afficher bouton: "⚠️ Payer votre cotisation"
    Couleur: Orange/Rouge
    État: Actif
SINON
    Afficher bouton: "✅ Cotisation payée"
    Couleur: Gris
    État: Désactivé
FIN SI
```

**Comportement:**
- **Si non payé:** Clic → Ouvre le modal de paiement (voir section 3.4)
- **Si déjà payé:** Bouton désactivé, pas d'action

**Message additionnel (optionnel):**
- Si non payé et date dépassée: "Attention : Vous avez X jour(s) de retard"

---

### 3.3 Liste de Mes Paiements

**Position:** Sous le bouton de paiement

**En-tête:** "Historique de mes paiements"

**Structure d'une ligne:**

```
┌────────────────────────────────────────────────────┐
│ ✅ Octobre 2025                      50,00 €       │
│    Payé le 03/10/2025 • Mobile Money               │
└────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────┐
│ ⚠️ Septembre 2025                    50,00 €       │
│    Payé le 18/10/2025 (15 jours de retard)         │
│    Mobile Money • Validé                           │
└────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────┐
│ ⏳ Novembre 2025                     50,00 €       │
│    Paiement en attente de validation                │
│    Envoyé le 02/11/2025                            │
└────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────┐
│ ❌ Août 2025                        NON PAYÉ       │
│    Date limite dépassée                            │
└────────────────────────────────────────────────────┘
```

**Icônes et états:**

| Icône | État | Description |
|-------|------|-------------|
| ✅ | Payé à temps | Paiement validé avant la date limite |
| ⚠️ | Payé en retard | Paiement validé après la date limite |
| ⏳ | En attente | Paiement envoyé, en attente de validation admin |
| ❌ | Non payé | Aucun paiement pour ce mois |

**Données affichées:**
- Mois concerné
- Montant
- Date de paiement (si payé)
- Mode de paiement (Mobile Money / Main à main)
- Statut de validation
- Retard éventuel (nombre de jours)

**Fonctionnalités:**
- Tri: Plus récent en premier (par défaut)
- Affichage: Tous les mois (pas de pagination, liste complète)
- Clic sur une ligne → Page détail du paiement

**Comportement:**
- Affiche TOUS les paiements (validés, en attente, non payés)
- Pas de filtrage par défaut (retards inclus dans la liste)

---

### 3.4 Modal de Paiement

**Déclenchement:** Clic sur le bouton "Payer votre cotisation"

#### Étape 1: Choix du mode de paiement

```
┌────────────────────────────────────────────────────┐
│  × Fermer                                          │
│                                                    │
│  Comment souhaitez-vous payer ?                    │
│                                                    │
│  ┌──────────────────────────────────────────────┐ │
│  │  🤝 Main à main                              │ │
│  │  Paiement en espèces avec QR code           │ │
│  └──────────────────────────────────────────────┘ │
│                                                    │
│  ┌──────────────────────────────────────────────┐ │
│  │  📱 Mobile Money                             │ │
│  │  Paiement mobile (Orange, MTN, Moov...)     │ │
│  └──────────────────────────────────────────────┘ │
│                                                    │
│                        [Annuler]                   │
└────────────────────────────────────────────────────┘
```

---

#### Étape 2a: Si "Main à main" sélectionné

```
┌────────────────────────────────────────────────────┐
│  ← Retour                                × Fermer  │
│                                                    │
│  Paiement Main à main                              │
│                                                    │
│  Montant: 50,00 €                                 │
│  Mois: Novembre 2025                               │
│                                                    │
│  Présentez ce QR code au trésorier :              │
│                                                    │
│  ┌──────────────────────────────────────────────┐ │
│  │                                              │ │
│  │           [QR CODE ICI]                      │ │
│  │                                              │ │
│  │     Code: PAY-NOV2025-USER123                │ │
│  │                                              │ │
│  └──────────────────────────────────────────────┘ │
│                                                    │
│  Le trésorier scannera ce code pour valider       │
│  votre paiement.                                   │
│                                                    │
│                        [Fermer]                    │
└────────────────────────────────────────────────────┘
```

**Contenu du QR code:**
```json
{
  "type": "cotisation_mensuelle",
  "user_id": "123",
  "mois": "2025-11",
  "montant": 50.00,
  "code": "PAY-NOV2025-USER123",
  "timestamp": "2025-11-03T14:30:00Z"
}
```

---

#### Étape 2b: Si "Mobile Money" sélectionné

```
┌────────────────────────────────────────────────────┐
│  ← Retour                                × Fermer  │
│                                                    │
│  Paiement Mobile Money                             │
│                                                    │
│  Choisissez votre option :                         │
│                                                    │
│  ┌──────────────────────────────────────────────┐ │
│  │  💳 Payer via la plateforme                  │ │
│  │  Paiement direct et sécurisé                 │ │
│  │                                              │ │
│  │  ⚠️ Fonctionnalité en cours de développement│ │
│  │  Bientôt disponible                          │ │
│  └──────────────────────────────────────────────┘ │
│                                                    │
│  ┌──────────────────────────────────────────────┐ │
│  │  📤 Prouver un paiement                      │ │
│  │  J'ai déjà payé, j'envoie la preuve         │ │
│  └──────────────────────────────────────────────┘ │
│                                                    │
│                        [Annuler]                   │
└────────────────────────────────────────────────────┘
```

**État du bouton "Payer via la plateforme":**
- Désactivé (grisé)
- Tooltip au survol: "Cette fonctionnalité nécessite une intégration API de paiement"

---

#### Étape 3: Si "Prouver un paiement" sélectionné

```
┌────────────────────────────────────────────────────┐
│  ← Retour                                × Fermer  │
│                                                    │
│  Prouver un paiement                               │
│                                                    │
│  Mois concerné          Novembre 2025             │
│  Montant à justifier    50,00 €                   │
│                                                    │
│  ─────────────────────────────────────────         │
│                                                    │
│  Justificatif de paiement *                        │
│                                                    │
│  ┌──────────────────────────────────────────────┐ │
│  │                                              │ │
│  │     📁 Glisser-déposer votre fichier         │ │
│  │            ou cliquer ici                     │ │
│  │                                              │ │
│  │  Formats acceptés: JPG, PNG, PDF             │ │
│  │  Taille max: 5 Mo                            │ │
│  │                                              │ │
│  └──────────────────────────────────────────────┘ │
│                                                    │
│  Note (optionnelle)                                │
│  ┌──────────────────────────────────────────────┐ │
│  │                                              │ │
│  └──────────────────────────────────────────────┘ │
│                                                    │
│            [Annuler]        [Envoyer]             │
└────────────────────────────────────────────────────┘
```

**Validation du formulaire:**
- Champ "Justificatif" : OBLIGATOIRE
- Champ "Note" : OPTIONNEL
- Types de fichiers acceptés: .jpg, .jpeg, .png, .pdf
- Taille maximale: 5 Mo

**Après envoi:**
```
┌────────────────────────────────────────────────────┐
│                      ✅                            │
│                                                    │
│  Paiement envoyé avec succès !                     │
│                                                    │
│  Votre justificatif est en cours de vérification   │
│  par un administrateur.                            │
│                                                    │
│  Vous recevrez une notification une fois validé.   │
│                                                    │
│                        [OK]                        │
└────────────────────────────────────────────────────┘
```

**Traitement backend:**
1. Créer une transaction avec statut "EN_ATTENTE_VALIDATION"
2. Stocker le fichier justificatif
3. Envoyer notification aux admins
4. Mettre à jour le statut du paiement dans la liste de l'utilisateur

---

### 3.5 Page Détail d'un Paiement

**Déclenchement:** Clic sur une ligne dans "Liste de mes paiements"

**URL:** `/gestion-financiere/mes-cotisations/{id}`

**Contenu:**

```
┌────────────────────────────────────────────────────┐
│  ← Retour à mes cotisations                        │
│                                                    │
│  COTISATION - NOVEMBRE 2025                        │
│                                                    │
│  Statut              ⏳ En attente de validation   │
│  Montant             50,00 €                       │
│  Date d'envoi        02 Novembre 2025, 15:45       │
│                                                    │
│  ─────────────────────────────────────────         │
│                                                    │
│  Mode de paiement    Mobile Money                  │
│  Opérateur           Orange Money                  │
│  Référence           OM-20251102-XXXX              │
│                                                    │
│  Justificatif        [📄 recu-paiement.jpg]       │
│                      [Télécharger] [Voir]          │
│                                                    │
│  Note                                              │
│  Paiement effectué depuis mon compte Orange        │
│                                                    │
│  ─────────────────────────────────────────         │
│                                                    │
│  ⏳ Votre paiement sera vérifié sous 24-48h        │
└────────────────────────────────────────────────────┘
```

**Variante - Paiement validé:**
```
│  Statut              ✅ Validé                     │
│  Validé par          Admin KONAN                   │
│  Date de validation  03 Novembre 2025, 09:30       │
```

**Variante - Paiement rejeté:**
```
│  Statut              ❌ Rejeté                     │
│  Rejeté par          Admin KONAN                   │
│  Date de rejet       03 Novembre 2025, 09:30       │
│  Raison              Justificatif illisible         │
│                                                    │
│  [Renvoyer un justificatif]                        │
```

---

## Fonctionnalités transversales

### 4.1 Notifications

**Événements déclenchant une notification:**

| Événement | Destinataire | Message |
|-----------|--------------|---------|
| Nouveau paiement soumis | Admins | "Marie DUPONT a envoyé un justificatif de paiement pour Novembre 2025" |
| Paiement validé | Utilisateur | "Votre cotisation de Novembre 2025 a été validée ✅" |
| Paiement rejeté | Utilisateur | "Votre cotisation de Novembre 2025 a été rejetée. Raison: [...]" |
| Rappel échéance proche | Utilisateur | "Rappel: Votre cotisation de Novembre est due le 05/11" (3 jours avant) |
| Échéance dépassée | Utilisateur | "Attention: Votre cotisation de Novembre est en retard" (1 jour après) |

---

### 4.2 Filtres et Recherche

**Page Wallet - Liste des transactions:**
- Filtre par type: Crédit / Débit / Tout
- Filtre par période: Mois en cours / Mois dernier / 3 derniers mois / Personnalisé
- Recherche par nom de personne (pour les crédits)

**Page Ventilation:**
- Pas de filtre (affichage par période fixe)

**Page Mes cotisations:**
- Pas de filtre (affichage de tous les paiements de l'utilisateur)

---

### 4.3 Export de données

**Formats disponibles:**

| Page | Format | Contenu |
|------|--------|---------|
| Wallet | CSV | Liste complète des transactions |
| Ventilation | PDF | Tableau complet de ventilation |
| Bilan mensuel | Excel | Tableau du bilan avec formules |

**Accès:**
- Bouton "Exporter" en haut de chaque page concernée
- Dropdown pour choisir le format

---

## Modèles de données

### 5.1 Transaction

```javascript
{
  id: "string",
  type: "CREDIT" | "DEBIT",
  montant: number,
  date: datetime,
  
  // Pour CREDIT
  payeur_id: "string",
  payeur_nom: "string",
  categorie_credit: "COTISATION" | "PARTICIPATIF" | "PREFINANCEMENT",
  mois_ventile: "YYYY-MM", // Mois auquel appartient réellement le paiement
  mode_paiement: "MOBILE_MONEY" | "MAIN_A_MAIN",
  
  // Pour DEBIT
  raison: "string",
  categorie_debit: "PROJET" | "REMBOURSEMENT" | "CHARGE_RECURRENTE",
  beneficiaire: "string",
  autorise_par: "string",
  
  // Commun
  statut: "EN_ATTENTE" | "VALIDE" | "REJETE",
  valide_par: "string",
  date_validation: datetime,
  justificatif_url: "string",
  notes: "string",
  created_at: datetime,
  updated_at: datetime
}
```

---

### 5.2 Cotisation

```javascript
{
  id: "string",
  user_id: "string",
  mois: "YYYY-MM",
  montant_attendu: number,
  montant_paye: number,
  date_limite: date,
  date_paiement: datetime,
  jours_retard: number,
  statut: "NON_PAYE" | "EN_ATTENTE" | "VALIDE" | "REJETE",
  mode_paiement: "MOBILE_MONEY" | "MAIN_A_MAIN",
  transaction_id: "string", // Référence à la transaction
  justificatif_url: "string",
  raison_rejet: "string",
  created_at: datetime,
  updated_at: datetime
}
```

---

### 5.3 Paramètres Globaux

```javascript
{
  id: "string",
  montant_cotisation: number, // 50.00
  jour_limite: number, // 5
  nombre_membres_actifs: number, // 30
  charges_recurrentes: [
    {
      libelle: "Gardiennage",
      montant: 250.00,
      frequence: "MENSUEL"
    }
  ],
  created_at: datetime,
  updated_at: datetime
}
```

---

## Règles métier

### 6.1 Ventilation des paiements

**Règle principale:** Un paiement reçu le mois M peut appartenir (être ventilé) au mois M, M-1, M-2, etc.

**Exemple:**
- Paul paie sa cotisation de Septembre le 15 Octobre
- Transaction créée le 15/10 avec `mois_ventile = "2025-09"`
- Dans le tableau de ventilation: ✅ apparaît en Septembre
- Dans "Montant ventilé reçu" d'Octobre: le montant est comptabilisé
- Dans "Montant réel payé" de Septembre: le montant est comptabilisé

---

### 6.2 Calcul du retard

```
SI date_paiement > date_limite ALORS
    jours_retard = JOURS_ENTRE(date_limite, date_paiement)
SINON
    jours_retard = 0
FIN SI
```

**Pénalité (optionnel, à définir):**
- Aucune pénalité pour l'instant
- Possibilité d'ajouter une pénalité fixe ou proportionnelle

---

### 6.3 Validation des paiements

**Workflow:**

1. **Utilisateur envoie un justificatif**
   - Statut: EN_ATTENTE
   - Notification envoyée aux admins

2. **Admin consulte le justificatif**
   - Accès via interface admin (hors scope de ce document)
   
3. **Admin valide ou rejette**
   - Si validé: Statut → VALIDE, notification à l'utilisateur
   - Si rejeté: Statut → REJETE, saisie d'une raison, notification à l'utilisateur

4. **Si rejeté: Utilisateur peut renvoyer**
   - Nouveau justificatif → Statut redevient EN_ATTENTE

---

### 6.4 Gestion des mois futurs

**Règle:** On ne peut pas payer une cotisation pour un mois futur.

**Exemple:** On est le 3 Novembre
- Utilisateur peut payer: Novembre (mois en cours)
- Utilisateur peut payer: Octobre, Septembre, ... (retards)
- Utilisateur NE PEUT PAS payer: Décembre (mois futur)

**Interface:**
- Dans le tableau de ventilation: mois futurs affichent 🔒
- Bouton "Payer" n'apparaît que si cotisation du mois en cours non payée

---

## Permissions et rôles

### 7.1 Rôles

| Rôle | Description |
|------|-------------|
| Membre | Utilisateur standard, peut voir ses propres cotisations |
| Trésorier | Peut gérer les transactions, valider les paiements |
| Admin | Accès complet, peut modifier les paramètres |

---

### 7.2 Permissions par page

**Page Wallet:**

| Action | Membre | Trésorier | Admin |
|--------|--------|-----------|-------|
| Voir le wallet | ❌ | ✅ | ✅ |
| Voir les transactions | ❌ | ✅ | ✅ |
| Ajouter une transaction | ❌ | ✅ | ✅ |
| Modifier une transaction | ❌ | ❌ | ✅ |
| Supprimer une transaction | ❌ | ❌ | ✅ |

**Page Ventilation:**

| Action | Membre | Trésorier | Admin |
|--------|--------|-----------|-------|
| Voir la ventilation | ❌ | ✅ | ✅ |
| Exporter le PDF | ❌ | ✅ | ✅ |
| Modifier une ventilation | ❌ | ❌ | ✅ |

**Page Mes cotisations:**

| Action | Membre | Trésorier | Admin |
|--------|--------|-----------|-------|
| Voir ses propres cotisations | ✅ | ✅ | ✅ |
| Payer sa cotisation | ✅ | ✅ | ✅ |
| Voir les cotisations des autres | ❌ | ✅ | ✅ |
| Valider un paiement | ❌ | ✅ | ✅ |

---

## Annexes

### A. Calculs récapitulatifs

**Montant actuel du Wallet:**
```
Montant actuel = SUM(transactions.montant WHERE type = CREDIT)
                 - SUM(transactions.montant WHERE type = DEBIT)
```

**Montant entré:**
```
Montant entré = SUM(transactions.montant WHERE type = CREDIT)
```

**Montant sorti:**
```
Montant sorti = SUM(transactions.montant WHERE type = DEBIT)
```

**Cotisation réelle (mois en cours):**
```
Cotisation réelle = SUM(cotisations.montant_paye 
                        WHERE mois = mois_en_cours 
                        AND statut = VALIDE)
```

**Montant ventilé reçu (mois en cours):**
```
Montant ventilé reçu = SUM(transactions.montant 
                           WHERE type = CREDIT 
                           AND MONTH(date) = mois_en_cours
                           AND categorie_credit = COTISATION)
```

**Pourcentage de collecte (card "Mes cotisations"):**
```
Pourcentage = (Montant collecté / Montant attendu) × 100
Montant attendu = nombre_membres_actifs × montant_cotisation
```

---

### B. Messages d'erreur

| Situation | Message |
|-----------|---------|
| Fichier trop volumineux | "Le fichier ne doit pas dépasser 5 Mo" |
| Format de fichier invalide | "Format non accepté. Utilisez JPG, PNG ou PDF" |
| Aucun fichier sélectionné | "Veuillez sélectionner un justificatif" |
| Erreur réseau | "Erreur de connexion. Veuillez réessayer" |
| Cotisation déjà payée | "Vous avez déjà payé votre cotisation pour ce mois" |

---

### C. Améliorations futures

**Phase 2 (après MVP):**
- Intégration API de paiement mobile (Orange Money, MTN, Moov)
- Système de pénalités pour retards
- Rappels automatiques par SMS/Email
- Dashboard statistiques avancées
- Export en Excel avec graphiques
- Historique des modifications (audit trail)

**Phase 3:**
- Application mobile native
- Paiement récurrent automatique
- Prévisions budgétaires
- Intégration comptabilité (ERP)

---

## Glossaire

| Terme | Définition |
|-------|------------|
| Ventilation | Attribution d'un paiement au mois auquel il correspond réellement, distinct du mois de réception |
| Cotisation réelle | Montant des cotisations appartenant à un mois donné, peu importe quand elles ont été payées |
| Montant ventilé reçu | Montant total encaissé durant un mois, sans distinction du mois d'appartenance |
| Préfinancement | Avance d'argent par un membre pour financer un projet |
| Charge récurrente | Dépense fixe mensuelle (ex: gardiennage, location) |
| Dépense exceptionnelle | Dépense ponctuelle liée à un événement ou projet |

---

**FIN DU DOCUMENT**

*Ce document constitue la spécification complète du module Gestion Financière. Toute modification doit faire l'objet d'une mise à jour versionnée de ce document.*
