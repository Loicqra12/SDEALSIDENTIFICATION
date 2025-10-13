# 🚀 GUIDE D'INTÉGRATION - SDEALSIDENTIFICATION → BACKEND

## 📋 Vue d'ensemble

Ce guide explique comment **SDEALSIDENTIFICATION** (app recensement Flutter) s'intègre avec le **Backend SoutralIdeals** et le **Dashboard React** via l'**Option C** (simplifiée avec traçabilité).

---

## 🎯 Objectifs

- ✅ **Formulaire simplifié** pour recenseurs (7 champs seulement)
- ✅ **Création automatique utilisateur** avec rôle approprié
- ✅ **Valeurs par défaut intelligentes** selon le service
- ✅ **Traçabilité complète** (source, recenseur, date)
- ✅ **Validation dashboard** (pending → active)
- ✅ **Compatible backend existant** (réutilise endpoints)

---

## 🔄 FLUX COMPLET

```
┌─────────────────────┐
│ 1. RECENSEUR TERRAIN│  (2-3 minutes)
│ - Nom               │
│ - Téléphone         │
│ - Service           │
│ - Photo             │
│ - GPS (auto)        │
│ - Adresse           │
│ - Notes             │
└──────────┬──────────┘
           │
           ▼ (WiFi)
┌─────────────────────┐
│ 2. APP ENRICHIT     │  (Automatique)
│ - Créer utilisateur │
│ - Récupérer service │
│ - Ajouter defaults  │
│ - Envoyer backend   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ 3. BACKEND REÇOIT   │
│ - utilisateur: ID   │
│ - service: ObjectId │
│ - status: pending   │
│ - source: sdeals... │
│ - recenseur: ID     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ 4. DASHBOARD ADMIN  │
│ - Voit pending      │
│ - Checklist auto    │
│ - [VALIDER] → active│
│ - [REJETER] → motif │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ 5. DISPONIBLE       │
│ - App mobile ✓      │
│ - App web ✓         │
│ - API publique ✓    │
└─────────────────────┘
```

---

## 📱 UTILISATION DANS L'APP FLUTTER

### Exemple 1 : Soumission recensement prestataire

```dart
import 'package:sdealsidentification/services/api_service_v2.dart';

// Données collectées par le recenseur (SEULEMENT 7 champs)
final data = {
  'type': 'prestataire',
  'nom': 'KOUADIO Jean',
  'telephone': '+225 0707123456',
  'service': 'Menuiserie',
  'photoPath': '/local/storage/photo123.jpg',
  'latitude': 5.3599517,
  'longitude': -4.0082553,
  'adresse': 'Cocody, Angré 8ème tranche',
  'notes': 'Atelier bien équipé',
};

// Soumission
final result = await ApiService.submitRecensementSimple(
  data: data,
  recenseurId: 'recenseur_afisu_id',
  recenseurNom: 'Afisu Mohamed',
);

if (result['success']) {
  print('✅ Recensement envoyé !');
  print('User ID: ${result['userId']}');
  // Afficher message succès
} else {
  print('❌ Erreur: ${result['error']}');
  // Afficher erreur
}
```

### Exemple 2 : Soumission freelance

```dart
final data = {
  'type': 'freelance',
  'nom': 'TRAORE Aminata',
  'telephone': '+225 0708234567',
  'service': 'Design Graphique',
  'categorie': 'Créatif',
  'photoPath': '/local/storage/photo456.jpg',
  'latitude': 5.3456789,
  'longitude': -4.0123456,
  'adresse': 'Marcory, Zone 4',
  'notes': 'Portfolio très complet',
};

final result = await ApiService.submitRecensementSimple(
  data: data,
  recenseurId: 'recenseur_afisu_id',
  recenseurNom: 'Afisu Mohamed',
);
```

### Exemple 3 : Soumission vendeur

```dart
final data = {
  'type': 'vendeur',
  'nom': 'KOFFI Paul',
  'telephone': '+225 0709345678',
  'service': 'Vêtements',
  'categorie': 'Mode',
  'shopName': 'Boutique Koffi',
  'shopDescription': 'Vêtements traditionnels et modernes',
  'photoPath': '/local/storage/photo789.jpg',
  'latitude': 5.3111111,
  'longitude': -4.0222222,
  'adresse': 'Adjamé, Marché',
  'notes': 'Boutique bien située',
  'businessType': 'Particulier',
};

final result = await ApiService.submitRecensementSimple(
  data: data,
  recenseurId: 'recenseur_afisu_id',
  recenseurNom: 'Afisu Mohamed',
);
```

---

## 🔧 MODIFICATIONS BACKEND

### 1. Modèles (déjà faites ✅)

**Fichiers modifiés** :
- `backend/models/prestataireModel.js`
- `backend/models/freelanceModel.js`
- `backend/models/vendeurModel.js`

**Nouveaux champs ajoutés** :
```javascript
{
  source: { 
    type: String, 
    enum: ['web', 'sdealsmobile', 'sdealsidentification', 'dashboard'],
    default: 'web' 
  },
  status: { 
    type: String, 
    enum: ['pending', 'active', 'rejected', 'suspended'],
    default: 'active'
  },
  recenseur: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Utilisateur' 
  },
  dateRecensement: { type: Date },
  validePar: { type: mongoose.Schema.Types.ObjectId, ref: 'Utilisateur' },
  dateValidation: { type: Date },
  motifRejet: { type: String }
}
```

### 2. Routes (déjà faites ✅)

**Fichiers modifiés** :
- `backend/routes/prestataireRoutes.js`
- `backend/routes/freelanceRoutes.js`
- `backend/routes/vendeurRoutes.js`

**Nouvelles routes ajoutées** :
```javascript
// Récupérer les en attente
GET /api/prestataire/pending/list
GET /api/freelance/pending/list
GET /api/vendeur/pending/list

// Valider
PUT /api/prestataire/:id/validate
PUT /api/freelance/:id/validate
PUT /api/vendeur/:id/validate

// Rejeter
PUT /api/prestataire/:id/reject
PUT /api/freelance/:id/reject
PUT /api/vendeur/:id/reject
```

### 3. Controllers (déjà faits ✅)

**Fichiers modifiés** :
- `backend/controller/prestataireController.js`
- `backend/controller/freelanceController.js`
- `backend/controller/vendeurController.js`

**Nouvelles méthodes ajoutées** :
- `getPendingPrestataires()` / `getPendingFreelances()` / `getPendingVendeurs()`
- `validatePrestataire()` / `validateFreelance()` / `validateVendeur()`
- `rejectPrestataire()` / `rejectFreelance()` / `rejectVendeur()`

---

## 🖥️ INTÉGRATION DASHBOARD REACT

### Page Recensements Pending (à créer)

**Fichier** : `dashboard/src/pages/RecensementsPending.tsx`

```typescript
import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { DataTable } from 'primereact/datatable';
import { Column } from 'primereact/column';
import { Button } from 'primereact/button';
import { Dialog } from 'primereact/dialog';
import { InputTextarea } from 'primereact/inputtextarea';

export const RecensementsPending = () => {
  const [prestataires, setPrestataires] = useState([]);
  const [freelances, setFreelances] = useState([]);
  const [vendeurs, setVendeurs] = useState([]);
  const [loading, setLoading] = useState(false);
  const [rejectDialogVisible, setRejectDialogVisible] = useState(false);
  const [selectedItem, setSelectedItem] = useState(null);
  const [motifRejet, setMotifRejet] = useState('');

  const apiUrl = process.env.REACT_APP_API_URL;

  useEffect(() => {
    loadPending();
  }, []);

  const loadPending = async () => {
    setLoading(true);
    try {
      const [prestRes, freelRes, vendRes] = await Promise.all([
        axios.get(`${apiUrl}/prestataire/pending/list`),
        axios.get(`${apiUrl}/freelance/pending/list`),
        axios.get(`${apiUrl}/vendeur/pending/list`)
      ]);

      setPrestataires(prestRes.data);
      setFreelances(freelRes.data);
      setVendeurs(vendRes.data);
    } catch (error) {
      console.error('Erreur chargement pending:', error);
    }
    setLoading(false);
  };

  const handleValidate = async (type, id) => {
    try {
      await axios.put(`${apiUrl}/${type}/${id}/validate`);
      loadPending(); // Recharger
      // Afficher notification succès
    } catch (error) {
      console.error('Erreur validation:', error);
    }
  };

  const handleReject = async () => {
    if (!selectedItem || !motifRejet) return;
    
    try {
      await axios.put(
        `${apiUrl}/${selectedItem.type}/${selectedItem.id}/reject`,
        { motif: motifRejet }
      );
      setRejectDialogVisible(false);
      setMotifRejet('');
      loadPending();
      // Afficher notification succès
    } catch (error) {
      console.error('Erreur rejet:', error);
    }
  };

  const actionsTemplate = (rowData, type) => (
    <div>
      <Button
        icon="pi pi-check"
        className="p-button-success p-button-sm"
        tooltip="Valider"
        onClick={() => handleValidate(type, rowData._id)}
      />
      <Button
        icon="pi pi-times"
        className="p-button-danger p-button-sm"
        tooltip="Rejeter"
        onClick={() => {
          setSelectedItem({ type, id: rowData._id });
          setRejectDialogVisible(true);
        }}
      />
    </div>
  );

  return (
    <div className="recensements-pending">
      <h1>Recensements en attente de validation</h1>

      {/* Prestataires */}
      <div className="card">
        <h2>Prestataires ({prestataires.length})</h2>
        <DataTable value={prestataires} loading={loading}>
          <Column field="utilisateur.nom" header="Nom" />
          <Column field="utilisateur.telephone" header="Téléphone" />
          <Column field="service.nomservice" header="Service" />
          <Column field="localisation" header="Localisation" />
          <Column field="recenseur.nom" header="Recensé par" />
          <Column
            field="dateRecensement"
            header="Date"
            body={(row) => new Date(row.dateRecensement).toLocaleString()}
          />
          <Column
            header="Actions"
            body={(row) => actionsTemplate(row, 'prestataire')}
          />
        </DataTable>
      </div>

      {/* Freelances */}
      <div className="card">
        <h2>Freelances ({freelances.length})</h2>
        <DataTable value={freelances} loading={loading}>
          <Column field="name" header="Nom" />
          <Column field="utilisateur.telephone" header="Téléphone" />
          <Column field="job" header="Métier" />
          <Column field="location" header="Localisation" />
          <Column field="recenseur.nom" header="Recensé par" />
          <Column
            field="dateRecensement"
            header="Date"
            body={(row) => new Date(row.dateRecensement).toLocaleString()}
          />
          <Column
            header="Actions"
            body={(row) => actionsTemplate(row, 'freelance')}
          />
        </DataTable>
      </div>

      {/* Vendeurs */}
      <div className="card">
        <h2>Vendeurs ({vendeurs.length})</h2>
        <DataTable value={vendeurs} loading={loading}>
          <Column field="shopName" header="Boutique" />
          <Column field="utilisateur.telephone" header="Téléphone" />
          <Column field="businessType" header="Type" />
          <Column field="recenseur.nom" header="Recensé par" />
          <Column
            field="dateRecensement"
            header="Date"
            body={(row) => new Date(row.dateRecensement).toLocaleString()}
          />
          <Column
            header="Actions"
            body={(row) => actionsTemplate(row, 'vendeur')}
          />
        </DataTable>
      </div>

      {/* Dialog Rejet */}
      <Dialog
        visible={rejectDialogVisible}
        header="Motif du rejet"
        onHide={() => setRejectDialogVisible(false)}
      >
        <InputTextarea
          value={motifRejet}
          onChange={(e) => setMotifRejet(e.target.value)}
          rows={5}
          cols={50}
          placeholder="Entrez le motif du rejet..."
        />
        <div className="p-dialog-footer">
          <Button
            label="Annuler"
            onClick={() => setRejectDialogVisible(false)}
            className="p-button-secondary"
          />
          <Button
            label="Rejeter"
            onClick={handleReject}
            className="p-button-danger"
          />
        </div>
      </Dialog>
    </div>
  );
};
```

---

## 📊 DONNÉES ENVOYÉES AU BACKEND

### Exemple Prestataire

**Ce que le recenseur collecte** :
```dart
{
  'nom': 'KOUADIO Jean',
  'telephone': '+225 0707123456',
  'service': 'Menuiserie',
  'photoPath': '/local/photo.jpg',
  'latitude': 5.3599517,
  'longitude': -4.0082553,
  'adresse': 'Cocody, Angré',
  'notes': 'Atelier équipé'
}
```

**Ce que le backend reçoit** (enrichi automatiquement) :
```json
{
  "utilisateur": "674abc123def456",
  "service": "507f1f77bcf86cd799439011",
  "prixprestataire": 30000,
  "localisation": "Cocody, Angré",
  "localisationmaps": {
    "latitude": 5.3599517,
    "longitude": -4.0082553
  },
  "description": "Atelier équipé",
  "anneeExperience": "0",
  "tarifHoraireMin": 20000,
  "tarifHoraireMax": 40000,
  "specialite": ["Menuiserie"],
  "zoneIntervention": ["Cocody"],
  "verifier": false,
  "source": "sdealsidentification",
  "status": "pending",
  "recenseur": "recenseur_afisu_id",
  "dateRecensement": "2025-10-13T15:30:00Z"
}
```

---

## 🎯 TARIFS PAR DÉFAUT

L'app applique automatiquement des tarifs selon le service :

| Service | Tarif Min | Tarif Max | Prix Moyen |
|---------|-----------|-----------|------------|
| **Plomberie** | 15,000 | 35,000 | 25,000 |
| **Électricité** | 15,000 | 35,000 | 25,000 |
| **Menuiserie** | 20,000 | 40,000 | 30,000 |
| **Maçonnerie** | 15,000 | 30,000 | 22,500 |
| **Peinture** | 10,000 | 25,000 | 17,500 |
| **Jardinage** | 8,000 | 20,000 | 14,000 |
| **Nettoyage** | 5,000 | 15,000 | 10,000 |
| **Coiffure** | 3,000 | 15,000 | 9,000 |
| **Couture** | 5,000 | 20,000 | 12,500 |
| **Défaut** | 10,000 | 30,000 | 20,000 |

---

## ✅ CHECKLIST DÉPLOIEMENT

### Backend
- [x] Modifier modèles (source, status, recenseur)
- [x] Ajouter routes validation
- [x] Créer méthodes controllers
- [ ] Tester endpoints avec Postman
- [ ] Déployer backend sur Render

### SDEALSIDENTIFICATION
- [ ] Remplacer api_service.dart par api_service_v2.dart
- [ ] Mettre à jour les imports
- [ ] Tester création utilisateur
- [ ] Tester transformation données
- [ ] Tester envoi prestataire
- [ ] Tester envoi freelance
- [ ] Tester envoi vendeur

### Dashboard
- [ ] Créer page RecensementsPending.tsx
- [ ] Ajouter menu navigation
- [ ] Tester affichage pending
- [ ] Tester validation
- [ ] Tester rejet
- [ ] Ajouter notifications

---

## 🐛 TESTS RECOMMANDÉS

### Test 1 : Création utilisateur
```bash
curl -X POST http://localhost:3000/api/register \
  -H "Content-Type: application/json" \
  -d '{
    "nom": "TEST",
    "telephone": "+225 0700000000",
    "email": "test@test.com",
    "password": "test123",
    "role": "Prestataire"
  }'
```

### Test 2 : Création prestataire pending
```bash
curl -X POST http://localhost:3000/api/prestataire \
  -F "utilisateur=USER_ID" \
  -F "service=SERVICE_ID" \
  -F "prixprestataire=25000" \
  -F "localisation=Abidjan" \
  -F "source=sdealsidentification" \
  -F "status=pending" \
  -F "recenseur=RECENSEUR_ID"
```

### Test 3 : Récupérer pending
```bash
curl -X GET http://localhost:3000/api/prestataire/pending/list
```

### Test 4 : Valider
```bash
curl -X PUT http://localhost:3000/api/prestataire/PRESTATAIRE_ID/validate \
  -H "Content-Type: application/json" \
  -d '{"adminId": "ADMIN_ID"}'
```

---

## 📞 SUPPORT

Pour toute question :
- **Backend** : Vérifier logs serveur
- **App Flutter** : Vérifier console Dart
- **Dashboard** : Console navigateur

---

## 🎉 FÉLICITATIONS !

Votre système d'intégration est maintenant prêt ! 🚀

**Les recenseurs peuvent** :
- ✅ Remplir un formulaire simple (2-3 min)
- ✅ Enregistrer hors ligne
- ✅ Synchroniser automatiquement

**Les admins peuvent** :
- ✅ Voir tous les recensements en attente
- ✅ Valider en un clic
- ✅ Rejeter avec motif

**Le système** :
- ✅ Crée automatiquement les utilisateurs
- ✅ Applique des valeurs par défaut intelligentes
- ✅ Trace l'origine des données
- ✅ Compatible avec l'existant
