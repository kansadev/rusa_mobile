# 📚 RusaTravel API - Guide d'Intégration Complet

> **Guide complet pour les développeurs Flutter (Mobile) et Vue.js (Web)**  
> Version: 1.1.0 | Dernière mise à jour: 22/04/2026

---

## 📋 Table des Matières

1. [🔐 Authentification](#authentification)
2. [👥 Gestion des Utilisateurs](#gestion-des-utilisateurs)
3. [🚌 Transport & Voyages](#transport--voyages)
4. [🎫 Réservations & Paiements](#réservations--paiements)
5. [📊 Dashboards](#dashboards)
6. [🎯 Rôles & Permissions](#rôles--permissions)
7. [📱 Exemples Flutter](#exemples-flutter)
8. [🌐 Exemples Vue.js](#exemples-vuejs)
9. [🛠️ Outils & Debug](#outils--debug)

---

## 🔐 Authentification

### Base URL
```bash
# Développement
https://localhost:7110/api

# Production
https://api.rusatravel.cd/api
```

### 1. Connexion (Login)
```http
POST /Auth/login
Content-Type: application/json

{
  "email": "gerant@rusatravel.cd",
  "password": "Gerant"
}
```

**Réponse réussie:**
```json
{
  "success": true,
  "message": "Connexion réussie",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "refresh_token_here",
    "expiresIn": 3600,
    "user": {
      "id": 3,
      "username": "Gerant",
      "email": "gerant@rusatravel.cd",
      "role": "Gerant",
      "permissions": [
        "Voyage.Create", "Voyage.Read", "Voyage.ReadAll",
        "Reservation.Create", "Reservation.Read", "Reservation.ReadAll",
        "Paiement.Create", "Paiement.Read"
      ]
    }
  }
}
```

### 2. Rafraîchir le Token
```http
POST /Auth/refresh-token
Content-Type: application/json

{
  "refreshToken": "refresh_token_here"
}
```

### 3. Déconnexion
```http
POST /Auth/logout
Authorization: Bearer {token}
```

---

## 👥 Gestion des Utilisateurs

### 1. Lister tous les utilisateurs
```http
GET /Utilisateur/get-all
Authorization: Bearer {token}

Réponse:
{
  "success": true,
  "data": [
    {
      "id": 1,
      "username": "Super-Admin",
      "email": "superadmin@rusatravel.cd",
      "role": "Super-Admin",
      "statut": true,
      "dateCreation": "2026-04-21T10:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "total": 3
  }
}
```

### 2. Créer un utilisateur
```http
POST /Utilisateur/create
Authorization: Bearer {token}
Content-Type: application/json

{
  "username": "nouveau_user",
  "email": "user@example.com",
  "password": "Password123!",
  "nom": "Nom",
  "postnom": "Postnom",
  "telephone": "+243123456789",
  "genre": "Masculin",
  "idRole": 3,
  "idSociete": 1
}
```

### 3. Mettre à jour un utilisateur
```http
PUT /Utilisateur/update/{id}
Authorization: Bearer {token}
Content-Type: application/json

{
  "nom": "Nom modifié",
  "telephone": "+243987654321"
}
```

---

## 🚌 Transport & Voyages

### 1. Lister tous les voyages
```http
GET /Voyage/get-all
Authorization: Bearer {token}

Réponse:
{
  "success": true,
  "data": [
    {
      "id": 1,
      "dateDepart": "2026-04-22T08:00:00Z",
      "dateArrivee": "2026-04-22T12:00:00Z",
      "prix": 50.00,
      "statut": true,
      "bus": {
        "idBus": 1,
        "numeroBus": 101,
        "marque": "Mercedes",
        "nombreSiege": 50
      },
      "destination": {
        "idDestination": 1,
        "villeDepart": "Kinshasa",
        "villeArrivee": "Lubumbashi"
      }
    }
  ]
}
```

### 2. Créer un voyage
```http
POST /Voyage/create
Authorization: Bearer {token}
Content-Type: application/json

{
  "dateDepart": "2026-04-25T08:00:00Z",
  "dateArrivee": "2026-04-25T12:00:00Z",
  "prix": 75.50,
  "idBus": 1,
  "idDestination": 1,
  "statut": true
}
```

### 3. Lister les bus disponibles
```http
GET /Bus/get-all
Authorization: Bearer {token}

Réponse:
{
  "success": true,
  "data": [
    {
      "idBus": 1,
      "numeroBus": 101,
      "marque": "Mercedes",
      "nombreSiege": 50,
      "statut": true,
      "typeBus": {
        "idTypeBus": 1,
        "libelle": "VIP",
        "description": "Bus confortable avec climatisation"
      }
    }
  ]
}
```

---

## 🎫 Réservations & Paiements

### 1. Créer une réservation
```http
POST /Reservation/create
Authorization: Bearer {token}
Content-Type: application/json

{
  "idVoyage": 1,
  "idClient": 1,
  "statutReservation": "Confirmée",
  "statut": true
}
```

### 2. Lister les réservations
```http
GET /Reservation/get-all
Authorization: Bearer {token}

Réponse:
{
  "success": true,
  "data": [
    {
      "idReservation": 1,
      "dateReservation": "2026-04-21T10:30:00Z",
      "statutReservation": "Confirmée",
      "voyage": {
        "id": 1,
        "dateDepart": "2026-04-22T08:00:00Z",
        "prix": 50.00
      },
      "client": {
        "idClient": 1,
        "nom": "Client Nom",
        "email": "client@example.com"
      }
    }
  ]
}
```

### 3. Créer un paiement
```http
POST /Paiement/create
Authorization: Bearer {token}
Content-Type: application/json

{
  "idReservation": 1,
  "montant": 50.00,
  "methodePaiement": "Mobile Money",
  "statut": true
}
```

---

## Dashboards Transport

> **Tous les dashboards ont été adaptés au workflow de transport**  
> Les données sont maintenant basées sur les réservations, paiements et voyages

### Vue d'ensemble des Dashboards

| Dashboard | Rôle | Endpoint | Description |
|-----------|------|----------|-------------|
| **ClientDashboard** | Client | `/ClientDashboard` | Vue client des réservations et paiements |
| **CaissierDashboard** | Caissier | `/CaissierDashboard` | Gestion des paiements quotidiens |
| **FinancierDashboard** | Financier | `/FinancierDashboard` | Vue financière globale |
| **GerantDashboard** | Gerant | `/GerantDashboard` | Gestion par société |
| **Dashboard** | Admin/Gerant | `/Dashboard/{idSociete}` | Dashboard admin par société |

---

### 1. ClientDashboard

**Endpoint principal**
```http
GET /ClientDashboard
Authorization: Bearer {token}
```

**Réponse:**
```json
{
  "clientStatistiques": {
    "nombreTotalReservations": 12,
    "nombreReservationsActives": 8,
    "nombreReservationsPayees": 10,
    "montantTotalPaiements": 1250.50,
    "montantReservationsNonPayees": 150.00,
    "tauxPaiement": 83.3,
    "nombreVoyages": 12,
    "montantMoyenParReservation": 104.21
  },
  "reservationsRecentes": [
    {
      "idReservation": 1,
      "referenceReservation": "RES-000001",
      "dateReservation": "2026-04-21T10:30:00Z",
      "statutReservation": "Confirmée",
      "voyageInfo": "Kinshasa - Lubumbashi",
      "dateVoyage": "2026-04-22T08:00:00Z",
      "prix": 75.00,
      "statutPaiement": "Payé",
      "montantPaye": 75.00,
      "destination": "Lubumbashi"
    }
  ],
  "paiementsRecents": [
    {
      "idPaiement": 1,
      "referencePaiement": "PAY-000001",
      "datePaiement": "2026-04-21T10:35:00Z",
      "montantPaye": 75.00,
      "methodePaiement": "Mobile Money",
      "referenceReservation": "RES-000001",
      "statut": "Validé"
    }
  ],
  "voyagesClient": [
    {
      "idVoyage": 1,
      "referenceVoyage": "VYG-000001",
      "dateDepart": "2026-04-22T08:00:00Z",
      "destination": "Kinshasa - Lubumbashi",
      "prix": 75.00,
      "statutVoyage": "Actif",
      "busInfo": "Mercedes Bus (50 places)"
    }
  ],
  "alertesClient": [
    {
      "idAlerte": 1,
      "typeAlerte": "Paiement en attente",
      "description": "Réservation RES-000002 nécessite paiement",
      "niveauCriticite": "Moyenne",
      "dateAlerte": "2026-04-21T11:00:00Z",
      "referenceReservation": "RES-000002",
      "montantConcerne": 50.00,
      "actionSuggeree": "Effectuer le paiement"
    }
  ],
  "resumeClient": {
    "totalReservations": 12,
    "totalPaiements": 1250.50,
    "totalVoyages": 12,
    "derniereReservation": "2026-04-21T10:30:00Z",
    "dernierPaiement": "2026-04-21T10:35:00Z",
    "prochainVoyage": "2026-04-22T08:00:00Z"
  },
  "dateGeneration": "2026-04-21T12:00:00Z"
}
```

**Endpoints spécifiques**
```http
GET /ClientDashboard/statistiques
GET /ClientDashboard/reservations-recentes
GET /ClientDashboard/paiements-recents
GET /ClientDashboard/voyages-client
GET /ClientDashboard/alertes-client
GET /ClientDashboard/resume-client
```

---

### 2. CaissierDashboard

**Endpoint principal**
```http
GET /CaissierDashboard
Authorization: Bearer {token}
```

**Réponse:**
```json
{
  "statistiquesJournalieres": {
    "revenusJournaliers": 2500.00,
    "nombreTransactions": 25,
    "montantMoyenTransaction": 100.00,
    "montantMinTransaction": 25.00,
    "montantMaxTransaction": 300.00,
    "nombreReservationsConfirmees": 30,
    "nombreReservationsNonPayees": 5,
    "nombreBilletsVendus": 120,
    "tauxRemplissageMoyen": 75.5
  },
  "paiementsEnCours": [
    {
      "idPaiement": 2,
      "referencePaiement": "PAY-000002",
      "dateCreation": "2026-04-21T11:00:00Z",
      "montantAPaye": 50.00,
      "montantPaye": 0.00,
      "statut": "En attente",
      "referenceReservation": "RES-000002",
      "clientNom": "Jean Dupont",
      "voyageInfo": "Kinshasa - Matadi",
      "destination": "Matadi",
      "dateVoyage": "2026-04-23T09:00:00Z"
    }
  ],
  "paiementsRecents": [
    {
      "idPaiement": 1,
      "referencePaiement": "PAY-000001",
      "dateCreation": "2026-04-21T10:35:00Z",
      "montantAPaye": 75.00,
      "montantPaye": 75.00,
      "statut": "Validé",
      "referenceReservation": "RES-000001",
      "clientNom": "Marie Claire",
      "voyageInfo": "Kinshasa - Lubumbashi",
      "destination": "Lubumbashi",
      "dateVoyage": "2026-04-22T08:00:00Z",
      "methodePaiement": "Mobile Money"
    }
  ],
  "recettesJournalieres": [
    {
      "date": "2026-04-21",
      "montant": 2500.00,
      "nombreTransactions": 25,
      "moyenneTransaction": 100.00
    }
  ],
  "alertesCaissier": [
    {
      "idAlerte": 1,
      "typeAlerte": "Paiements en attente",
      "description": "5 paiements en attente de validation",
      "niveauCriticite": "Moyenne",
      "dateAlerte": "2026-04-21T11:30:00Z",
      "nombrePaiementsConcernees": 5,
      "montantTotalConcerne": 250.00,
      "actionSuggeree": "Valider les paiements en attente"
    }
  ],
  "resumeCaisse": {
    "totalRecettes": 2500.00,
    "totalDepenses": 0.00,
    "solde": 2500.00,
    "nombreTransactions": 25,
    "derniereTransaction": "2026-04-21T11:45:00Z",
    "tauxRemplissageMoyen": 75.5
  },
  "dateGeneration": "2026-04-21T12:00:00Z"
}
```

**Endpoints spécifiques**
```http
GET /CaissierDashboard/statistiques-journalieres
GET /CaissierDashboard/paiements-en-cours
GET /CaissierDashboard/paiements-recents
GET /CaissierDashboard/recettes-journalieres
GET /CaissierDashboard/alertes-caissier
GET /CaissierDashboard/resume-caisse
```

---

### 3. FinancierDashboard

**Endpoint principal**
```http
GET /FinancierDashboard
Authorization: Bearer {token}
```

**Réponse:**
```json
{
  "globalStatistiques": {
    "revenusTransportTotal": 15000.00,
    "montantTotalEncaisse": 12000.00,
    "montantReservationsNonPayees": 3000.00,
    "tauxPaiementGlobal": 80.0,
    "nombreTotalTransactions": 150,
    "moyenneTransaction": 100.00,
    "nombreTotalReservations": 180,
    "nombreTotalVoyages": 45,
    "tauxRemplissageMoyen": 72.5
  },
  "societesFinancieres": [
    {
      "idSociete": 1,
      "nomSociete": "RusaTravel Kinshasa",
      "revenusTransport": 8000.00,
      "montantEncaisse": 6500.00,
      "montantReservationsNonPayees": 1500.00,
      "tauxPaiement": 81.25,
      "nombreTransactions": 80,
      "nombreReservations": 95,
      "nombreVoyages": 25,
      "statutFinancier": "Bon",
      "tauxRemplissageMoyen": 75.0
    }
  ],
  "transactionsRecentes": [
    {
      "idTransaction": 1,
      "reference": "PAY-000001",
      "nomClient": "Jean Dupont",
      "nomSociete": "RusaTravel Kinshasa",
      "montant": 75.00,
      "dateTransaction": "2026-04-21T10:35:00Z",
      "typeTransaction": "Paiement Transport",
      "statut": "Validé",
      "referenceReservation": "RES-000001",
      "voyageInfo": "Kinshasa - Lubumbashi",
      "destination": "Lubumbashi",
      "dateVoyage": "2026-04-22T08:00:00Z",
      "methodePaiement": "Mobile Money"
    }
  ],
  "alertesFinancieres": [
    {
      "idAlerte": 1,
      "typeAlerte": "Taux de paiement faible",
      "description": "Taux de paiement critique pour RusaTravel Matadi: 65.0%",
      "niveauCriticite": "Élevée",
      "dateAlerte": "2026-04-21T11:00:00Z",
      "idSociete": 2,
      "nomSociete": "RusaTravel Matadi",
      "montantConcerne": 1500.00,
      "estLue": false,
      "typeAlerteTransport": "Paiement Transport",
      "nombreReservationsConcernees": 25,
      "tauxConcerne": 65.0,
      "actionSuggeree": "Contacter les clients pour le paiement des réservations"
    }
  ],
  "tendances": {
    "revenusTransport": [
      {
        "mois": "2026-04",
        "valeur": 15000.00,
        "variation": 5.2
      }
    ],
    "encaissements": [
      {
        "mois": "2026-04",
        "valeur": 12000.00,
        "variation": 3.8
      }
    ],
    "tauxPaiement": [
      {
        "mois": "2026-04",
        "valeur": 80.0,
        "variation": -2.1
      }
    ],
    "nombreReservations": [
      {
        "mois": "2026-04",
        "valeur": 180,
        "variation": 8.5
      }
    ],
    "nombreVoyages": [
      {
        "mois": "2026-04",
        "valeur": 45,
        "variation": 2.3
      }
    ]
  },
  "dateGeneration": "2026-04-21T12:00:00Z"
}
```

**Endpoints spécifiques**
```http
GET /FinancierDashboard/statistiques-globales
GET /FinancierDashboard/societes-financieres
GET /FinancierDashboard/transactions-recentes
GET /FinancierDashboard/alertes-financieres
GET /FinancierDashboard/tendances-financieres
```

---

### 4. GerantDashboard

**Endpoint principal**
```http
GET /GerantDashboard
Authorization: Bearer {token}
```

**Réponse:**
```json
{
  "societeStatistiques": {
    "nomSociete": "RusaTravel Kinshasa",
    "totalClients": 150,
    "clientsActifs": 120,
    "revenusTransportMois": 8000.00,
    "montantReservationsNonPayees": 1500.00,
    "tauxPaiement": 81.25,
    "variationCAMoisPrecedent": 5.2,
    "totalReservationsMois": 95,
    "reservationsPayeesMois": 78
  },
  "clientsStatistiques": {
    "totalClients": 150,
    "clientsActifs": 120,
    "nouveauxClientsMois": 8,
    "clientsAvecArrieres": 15,
    "pourcentageClientsAvecArrieres": 10.0,
    "repartitionParCategorie": [
      {
        "categorie": "VIP",
        "nombreClients": 30,
        "pourcentage": 20.0
      },
      {
        "categorie": "Standard",
        "nombreClients": 120,
        "pourcentage": 80.0
      }
    ]
  },
  "top5ClientsCA": [
    {
      "rang": 1,
      "idClient": 1,
      "nomClient": "Entreprise ABC",
      "valeur": 1200.00,
      "variationMoisPrecedent": 15.5
    }
  ],
  "top5ClientsArrieres": [
    {
      "rang": 1,
      "idClient": 2,
      "nomClient": "Client XYZ",
      "valeur": 300.00,
      "variationMoisPrecedent": -5.2
    }
  ],
  "alertesSociete": [
    {
      "idAlerte": 1,
      "typeAlerte": "Taux de paiement faible",
      "niveauCriticite": "Moyenne",
      "description": "Taux de paiement de 81.25% - objectif 85%",
      "dateAlerte": "2026-04-21T11:00:00Z",
      "statut": "Non lue",
      "idClient": null,
      "nomClient": null
    }
  ],
  "tendances": {
    "revenusTransport": [
      {
        "mois": "2026-04",
        "valeur": 8000.00,
        "variation": 5.2
      }
    ],
    "tauxPaiement": [
      {
        "mois": "2026-04",
        "valeur": 81.25,
        "variation": -2.1
      }
    ],
    "nombreReservations": [
      {
        "mois": "2026-04",
        "valeur": 95,
        "variation": 8.5
      }
    ]
  },
  "paiementsStatistiques": {
    "paiementsJour": 500.00,
    "paiementsSemaine": 2500.00,
    "paiementsMois": 8000.00,
    "nombrePaiementsJour": 5,
    "nombrePaiementsSemaine": 25,
    "nombrePaiementsMois": 80,
    "moyennePaiementsJournaliers": 266.67
  },
  "dateGeneration": "2026-04-21T12:00:00Z"
}
```

**Endpoints spécifiques**
```http
GET /GerantDashboard/societe-statistiques
GET /GerantDashboard/clients-statistiques
GET /GerantDashboard/top5-clients-ca
GET /GerantDashboard/top5-clients-arrieres
GET /GerantDashboard/alertes-societe
GET /GerantDashboard/tendances
GET /GerantDashboard/paiements-statistiques
```

---

### 5. Dashboard Admin

**Endpoint principal**
```http
GET /Dashboard/{idSociete}
Authorization: Bearer {token}
```

**Réponse:**
```json
{
  "totalAgents": 25,
  "totalClientsActifs": 120,
  "revenusTransportMois": 8000.00,
  "montantReservationsNonPayees": 1500.00,
  "paiementsTransportMois": {
    "moisLabel": "Avril 2026",
    "montant": 8000.00,
    "montantMoisPrecedent": 7600.00,
    "variationPourcentage": 5.26,
    "nombrePaiements": 80,
    "ticketMoyen": 100.00,
    "variationTicketMoyen": 2.5
  },
  "reservationsTransportMois": {
    "moisLabel": "Avril 2026",
    "montantTotalFactures": 10000.00,
    "montantTotalFacturesMoisPrecedent": 9500.00,
    "variationPourcentage": 5.26,
    "nombreFactures": 95,
    "nombreFacturesMoisPrecedent": 88,
    "factureMoyenne": 105.26,
    "factureMoyenneMoisPrecedent": 107.95,
    "variationFactureMoyenne": -2.5,
    "tauxRecouvrementEstime": 80.0
  },
  "repartitionClientsParCategorie": [
    {
      "idCategorie": 1,
      "nomCategorie": "VIP",
      "nombreClients": 30,
      "pourcentage": 25.0
    },
    {
      "idCategorie": 2,
      "nomCategorie": "Standard",
      "nombreClients": 90,
      "pourcentage": 75.0
    }
  ],
  "top5AgentsTransport": [
    {
      "idAgent": 1,
      "matricule": "AGT001",
      "nomComplet": "Jean Pierre",
      "montantCollecte": 1500.00,
      "nombrePaiements": 15
    }
  ]
}
```

---

## 🎯 Rôles & Permissions

### Hiérarchie des rôles
1. **Super-Admin** (Niveau 1) - Accès total
2. **Admin** (Niveau 2) - Gestion complète
3. **Gerant** (Niveau 3) - Gestion opérationnelle
4. **Financier** (Niveau 4) - Gestion financière
5. **Caissier** (Niveau 5) - Paiements
6. **Client** (Niveau 6) - Accès client

### Permissions par rôle

#### Gerant (Niveau 3)
```json
{
  "permissions": [
    "Societe.Read", "Societe.Update",
    "Utilisateur.Create", "Utilisateur.Read", "Utilisateur.Update",
    "Agent.Create", "Agent.Read", "Agent.Update", "Agent.Delete",
    "Client.Create", "Client.Read", "Client.Update", "Client.Delete",
    "Voyage.Create", "Voyage.Read", "Voyage.Update", "Voyage.Delete",
    "Bus.Create", "Bus.Read", "Bus.Update", "Bus.Delete",
    "Reservation.Create", "Reservation.Read", "Reservation.Update", "Reservation.Delete",
    "Paiement.Create", "Paiement.Read",
    "Billet.Create", "Billet.Read", "Billet.Update", "Billet.Delete"
  ]
}
```

---

## 📱 Exemples Flutter

### 1. Service d'Authentification
```dart
// services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = 'https://api.rusatravel.cd/api';
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          // Sauvegarder le token
          await _saveToken(data['data']['token']);
          return data;
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Erreur de connexion');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  Future<Map<String, dynamic>> getVoyages() async {
    final token = await _getToken();
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Voyage/get-all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur de chargement des voyages');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }
}
```

### 2. Widget de liste des voyages
```dart
// widgets/voyage_list_widget.dart
import 'package:flutter/material.dart';
import '../models/voyage.dart';
import '../services/auth_service.dart';

class VoyageListWidget extends StatefulWidget {
  @override
  _VoyageListWidgetState createState() => _VoyageListWidgetState();
}

class _VoyageListWidgetState extends State<VoyageListWidget> {
  final AuthService _authService = AuthService();
  List<Voyage> voyages = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadVoyages();
  }

  Future<void> _loadVoyages() async {
    setState(() => isLoading = true);
    try {
      final response = await _authService.getVoyages();
      if (response['success']) {
        setState(() {
          voyages = (response['data'] as List)
              .map((item) => Voyage.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadVoyages,
      child: ListView.builder(
        itemCount: voyages.length,
        itemBuilder: (context, index) {
          final voyage = voyages[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              title: Text('${voyage.destination.villeDepart} → ${voyage.destination.villeArrivee}'),
              subtitle: Text('Prix: ${voyage.prix} FCFA'),
              trailing: Icon(Icons.directions_bus),
              onTap: () {
                // Navigation vers détails du voyage
                Navigator.pushNamed(
                  context,
                  '/voyage-details',
                  arguments: voyage,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
```

### 3. Modèle Voyage
```dart
// models/voyage.dart
class Voyage {
  final int id;
  final DateTime dateDepart;
  final DateTime dateArrivee;
  final double prix;
  final bool statut;
  final Bus bus;
  final Destination destination;

  Voyage({
    required this.id,
    required this.dateDepart,
    required this.dateArrivee,
    required this.prix,
    required this.statut,
    required this.bus,
    required this.destination,
  });

  factory Voyage.fromJson(Map<String, dynamic> json) {
    return Voyage(
      id: json['id'],
      dateDepart: DateTime.parse(json['dateDepart']),
      dateArrivee: DateTime.parse(json['dateArrivee']),
      prix: json['prix'].toDouble(),
      statut: json['statut'],
      bus: Bus.fromJson(json['bus']),
      destination: Destination.fromJson(json['destination']),
    );
  }
}

class Bus {
  final int idBus;
  final int numeroBus;
  final String marque;
  final int nombreSiege;

  Bus({
    required this.idBus,
    required this.numeroBus,
    required this.marque,
    required this.nombreSiege,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      idBus: json['idBus'],
      numeroBus: json['numeroBus'],
      marque: json['marque'],
      nombreSiege: json['nombreSiege'],
    );
  }
}

class Destination {
  final int idDestination;
  final String villeDepart;
  final String villeArrivee;

  Destination({
    required this.idDestination,
    required this.villeDepart,
    required this.villeArrivee,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      idDestination: json['idDestination'],
      villeDepart: json['villeDepart'],
      villeArrivee: json['villeArrivee'],
    );
  }
}
```

---

## 🌐 Exemples Vue.js

### 1. Service API
```javascript
// services/api.js
import axios from 'axios';

const API_BASE_URL = process.env.NODE_ENV === 'production' 
  ? 'https://api.rusatravel.cd/api' 
  : 'https://localhost:7110/api';

class ApiService {
  constructor() {
    this.api = axios.create({
      baseURL: API_BASE_URL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Intercepteur pour ajouter le token
    this.api.interceptors.request.use(
      (config) => {
        const token = localStorage.getItem('token');
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
      },
      (error) => Promise.reject(error)
    );

    // Intercepteur pour gérer les erreurs 401
    this.api.interceptors.response.use(
      (response) => response,
      (error) => {
        if (error.response?.status === 401) {
          localStorage.removeItem('token');
          window.location.href = '/login';
        }
        return Promise.reject(error);
      }
    );
  }

  // Authentification
  async login(email, password) {
    try {
      const response = await this.api.post('/Auth/login', {
        email,
        password,
      });
      
      if (response.data.success) {
        localStorage.setItem('token', response.data.data.token);
        localStorage.setItem('user', JSON.stringify(response.data.data.user));
        return response.data;
      } else {
        throw new Error(response.data.message);
      }
    } catch (error) {
      throw new Error('Erreur de connexion: ' + error.message);
    }
  }

  // Voyages
  async getVoyages() {
    try {
      const response = await this.api.get('/Voyage/get-all');
      return response.data;
    } catch (error) {
      throw new Error('Erreur de chargement des voyages: ' + error.message);
    }
  }

  async createVoyage(voyageData) {
    try {
      const response = await this.api.post('/Voyage/create', voyageData);
      return response.data;
    } catch (error) {
      throw new Error('Erreur de création du voyage: ' + error.message);
    }
  }

  // Réservations
  async createReservation(reservationData) {
    try {
      const response = await this.api.post('/Reservation/create', reservationData);
      return response.data;
    } catch (error) {
      throw new Error('Erreur de création de réservation: ' + error.message);
    }
  }
}

export default new ApiService();
```

### 2. Store Vuex (State Management)
```javascript
// store/index.js
import Vue from 'vue';
import Vuex from 'vuex';
import ApiService from '../services/api';

Vue.use(Vuex);

export default new Vuex.Store({
  state: {
    user: null,
    token: localStorage.getItem('token') || null,
    voyages: [],
    reservations: [],
    isLoading: false,
  },

  mutations: {
    SET_USER(state, user) {
      state.user = user;
    },
    SET_TOKEN(state, token) {
      state.token = token;
    },
    SET_VOYAGES(state, voyages) {
      state.voyages = voyages;
    },
    SET_LOADING(state, status) {
      state.isLoading = status;
    },
    CLEAR_AUTH(state) {
      state.user = null;
      state.token = null;
      localStorage.removeItem('token');
      localStorage.removeItem('user');
    },
  },

  actions: {
    async login({ commit }, credentials) {
      commit('SET_LOADING', true);
      try {
        const response = await ApiService.login(credentials.email, credentials.password);
        commit('SET_USER', response.data.user);
        commit('SET_TOKEN', response.data.token);
        return response;
      } catch (error) {
        commit('SET_LOADING', false);
        throw error;
      } finally {
        commit('SET_LOADING', false);
      }
    },

    async loadVoyages({ commit }) {
      commit('SET_LOADING', true);
      try {
        const response = await ApiService.getVoyages();
        commit('SET_VOYAGES', response.data);
        return response;
      } catch (error) {
        commit('SET_LOADING', false);
        throw error;
      } finally {
        commit('SET_LOADING', false);
      }
    },

    async createVoyage({ commit }, voyageData) {
      commit('SET_LOADING', true);
      try {
        const response = await ApiService.createVoyage(voyageData);
        return response;
      } catch (error) {
        commit('SET_LOADING', false);
        throw error;
      } finally {
        commit('SET_LOADING', false);
      }
    },

    logout({ commit }) {
      commit('CLEAR_AUTH');
    },
  },

  getters: {
    isAuthenticated: state => !!state.token,
    currentUser: state => state.user,
    allVoyages: state => state.voyages,
    isLoading: state => state.isLoading,
  },
});
```

### 3. Composant Vue.js - Liste des voyages
```vue
<!-- components/VoyageList.vue -->
<template>
  <div class="voyage-list">
    <div class="loading" v-if="isLoading">
      <i class="fas fa-spinner fa-spin"></i> Chargement...
    </div>
    
    <div v-else>
      <div class="filters mb-4">
        <input 
          v-model="searchTerm" 
          type="text" 
          placeholder="Rechercher un voyage..."
          class="form-control"
        >
      </div>

      <div class="voyage-grid">
        <div 
          v-for="voyage in filteredVoyages" 
          :key="voyage.id"
          class="voyage-card"
          @click="selectVoyage(voyage)"
        >
          <div class="voyage-header">
            <h5>{{ voyage.destination.villeDepart }} → {{ voyage.destination.villeArrivee }}</h5>
            <span class="badge badge-success">Disponible</span>
          </div>
          
          <div class="voyage-body">
            <div class="voyage-info">
              <p><i class="fas fa-calendar"></i> {{ formatDate(voyage.dateDepart) }}</p>
              <p><i class="fas fa-clock"></i> {{ formatTime(voyage.dateDepart) }}</p>
              <p><i class="fas fa-bus"></i> {{ voyage.bus.marque }} ({{ voyage.bus.nombreSiege }} places)</p>
            </div>
            
            <div class="voyage-price">
              <span class="price">{{ voyage.prix }} FCFA</span>
              <button class="btn btn-primary" @click.stop="reserveVoyage(voyage)">
                Réserver
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState, mapActions, mapGetters } from 'vuex';

export default {
  name: 'VoyageList',
  data() {
    return {
      searchTerm: '',
    };
  },
  
  computed: {
    ...mapState(['isLoading', 'voyages']),
    ...mapGetters(['allVoyages']),
    
    filteredVoyages() {
      if (!this.searchTerm) return this.voyages;
      
      const search = this.searchTerm.toLowerCase();
      return this.voyages.filter(voyage => 
        voyage.destination.villeDepart.toLowerCase().includes(search) ||
        voyage.destination.villeArrivee.toLowerCase().includes(search) ||
        voyage.bus.marque.toLowerCase().includes(search)
      );
    },
  },
  
  methods: {
    ...mapActions(['loadVoyages', 'createReservation']),
    
    async loadVoyagesData() {
      try {
        await this.loadVoyages();
      } catch (error) {
        this.$toast.error('Erreur de chargement: ' + error.message);
      }
    },
    
    selectVoyage(voyage) {
      this.$emit('voyage-selected', voyage);
    },
    
    async reserveVoyage(voyage) {
      try {
        const reservationData = {
          idVoyage: voyage.id,
          idClient: this.currentUser.idClient,
          statutReservation: 'Confirmée',
          statut: true,
        };
        
        await this.createReservation(reservationData);
        this.$toast.success('Réservation créée avec succès!');
      } catch (error) {
        this.$toast.error('Erreur de réservation: ' + error.message);
      }
    },
    
    formatDate(dateString) {
      return new Date(dateString).toLocaleDateString('fr-FR');
    },
    
    formatTime(dateString) {
      return new Date(dateString).toLocaleTimeString('fr-FR', { 
        hour: '2-digit', 
        minute: '2-digit' 
      });
    },
  },
  
  mounted() {
    this.loadVoyagesData();
  },
};
</script>

<style scoped>
.voyage-list {
  padding: 20px;
}

.voyage-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;
  margin-top: 20px;
}

.voyage-card {
  border: 1px solid #ddd;
  border-radius: 8px;
  padding: 15px;
  cursor: pointer;
  transition: all 0.3s ease;
  background: white;
}

.voyage-card:hover {
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  transform: translateY(-2px);
}

.voyage-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
}

.voyage-body {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.voyage-info p {
  margin: 5px 0;
  font-size: 14px;
}

.voyage-price {
  text-align: right;
}

.price {
  font-size: 18px;
  font-weight: bold;
  color: #007bff;
  display: block;
  margin-bottom: 10px;
}

.loading {
  text-align: center;
  padding: 40px;
  font-size: 18px;
}
</style>
```

---

## 🛠️ Outils & Debug

### 1. Test des endpoints avec curl
```bash
# Test de connexion
curl -X POST https://localhost:7110/api/Auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"gerant@rusatravel.cd","password":"Gerant"}'

# Test avec token
curl -X GET https://localhost:7110/api/Voyage/get-all \
  -H "Authorization: Bearer VOTRE_TOKEN_ICI"
```

### 2. Postman Collection
Une collection Postman complète est disponible dans le projet :
- `RusaTravel_API_Collection.postman_collection.json`

### 3. Gestion des erreurs
```javascript
// Codes d'erreur fréquents
{
  400: "Requête invalide - vérifiez les paramètres",
  401: "Non authentifié - token requis ou invalide",
  403: "Accès refusé - permissions insuffisantes",
  404: "Ressource non trouvée",
  500: "Erreur serveur - contactez l'administrateur"
}
```

### 4. Pagination
```javascript
// Format de réponse paginée
{
  "success": true,
  "data": [...],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "total": 150,
    "totalPages": 8,
    "hasNext": true,
    "hasPrevious": false
  }
}

// Paramètres de requête
GET /Voyage/get-all?page=2&pageSize=10&search=kinshasa
```

---

## 📝 Notes importantes

### Sécurité
- **Toutes les requêtes protégées** nécessitent un header `Authorization: Bearer {token}`
- **Le token expire** après 1 heure, utilisez le refresh token
- **HTTPS obligatoire** en production

### Performance
- **Pagination recommandée** pour les listes importantes
- **Cache côté client** pour les données statiques (destinations, types de bus)
- **Compression gzip** activée côté serveur

### Limites
- **Rate limiting**: 100 requêtes/minute par IP
- **Taille max des fichiers**: 10MB
- **Timeout**: 30 secondes par requête

---

## 🆘 Support & Contact

Pour toute question technique ou problème d'intégration :

- **Email**: support@rusatravel.cd
- **Documentation Swagger**: https://api.rusatravel.cd/swagger
- **Statut de l'API**: https://status.rusatravel.cd

---

**🎯 Bon développement !**

*Ce guide sera mis à jour régulièrement avec les nouvelles fonctionnalités et améliorations de l'API.*
