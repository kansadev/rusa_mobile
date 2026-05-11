# Backend Contract Frontends (Vue.js + Flutter)

Specification de contrat API orientee integration frontend.

Conventions:
- Tous les payloads sont en JSON.
- Dates au format ISO-8601 UTC.
- Les endpoints proteges necessitent `Authorization: Bearer <accessToken>`.
- Les exemples montrent la structure, pas forcement tous les champs.

---

## 1. Authentification

## 1.1 POST `/api/Utilisateur/authentifier`

### Description
Authentifie un utilisateur via email, username ou telephone + mot de passe.

### Request body
| Champ | Type | Requis | Description |
|---|---|---:|---|
| `emailOuTelephone` | string | oui | Email, username par defaut, ou telephone |
| `motDePasse` | string | oui | Mot de passe brut |
| `fcmToken` | string | non | Token push (mobile/web) |
| `deviceType` | string | non | Type device (web/android/ios) |
| `deviceModel` | string | non | Modele/appareil |
| `osVersion` | string | non | Version OS |

### Response 200
| Champ | Type | Description |
|---|---|---|
| `success` | bool | true si login OK |
| `message` | string | Message utilisateur |
| `accessToken` | string | JWT d'acces |
| `refreshToken` | string | Token de renouvellement |
| `tokenType` | string | `Bearer` |
| `expiresIn` | number | Duree en secondes |
| `expiresAt` | string(date) | Expiration UTC |
| `doitChangerMotDePasse` | bool | Flag changement mot de passe |
| `nomRole` | string | Role principal |
| `nomSociete` | string | Nom societe |
| `permissions` | string[] | Permissions agrégées |
| `roles` | object[] | Roles actifs |
| `primaryRole` | object/null | Role principal |
| `utilisateur` | object | Infos utilisateur |
| `agent` | object/null | Infos agent associe |
| `client` | object/null | Infos client associe |

### Objet `utilisateur` (extrait utile front)
| Champ | Type |
|---|---|
| `idUtilisateur` | number |
| `nomComplet` | string |
| `email` | string/null |
| `defaultUsername` | string/null |
| `telephone` | string/null |
| `idSociete` | number/null |
| `idRole` | number/null |
| `idAgent` | number/null |
| `idClient` | number/null |
| `idSite` | number/null |
| `statut` | bool/null |

### Objet `agent` (si utilisateur agent)
| Champ | Type |
|---|---|
| `idAgent` | number |
| `nomComplet` | string/null |
| `idSociete` | number/null |
| `idSite` | number/null |
| `roleAgent` | string/null |
| `fonction` | string/null |

### Erreurs
- `400`: payload invalide.
- `401`: identifiants invalides / compte desactive.
- `404`: informations utilisateur non trouvees apres auth.
- `500`: erreur serveur.

---

## 1.2 POST `/api/Utilisateur/refresh-token`

### Request body
| Champ | Type | Requis |
|---|---|---:|
| `refreshToken` | string | oui |
| `deviceInfo` | string | non |

### Response 200
Meme schema que `authentifier` (nouveaux `accessToken` + `refreshToken`).

### Erreurs
- `400`: refresh token manquant/invalide.
- `401`: refresh token non autorise.
- `500`: erreur serveur.

---

## 1.3 POST `/api/Utilisateur/deconnecter`

### Request body (optionnel selon besoin)
| Champ | Type | Requis | Description |
|---|---|---:|---|
| `supprimerTousLesDevices` | bool | non | Deconnecter tous les devices |
| `idUserDevice` | number | non | Deconnecter un device cible |
| `fcmToken` | string | non | Deconnecter device par token |

### Response 200
Confirmation de deconnexion.

### Erreurs
- `401`: token invalide.
- `404`: utilisateur introuvable.
- `500`: erreur serveur.

---

## 2. Agents / Sites

## 2.1 PUT `/api/Agent/{idAgent}/AffecterAgentSite`
## 2.2 PUT `/api/Agent/{idAgent}/site` (alias)

### Description
Affecte un agent a un site.

### Autorisations
- Roles autorises: `Admin`, `Super-Admin`, `Gerant`.

### Path params
| Param | Type | Requis |
|---|---|---:|
| `idAgent` | number | oui |

### Request body
| Champ | Type | Requis | Contraintes |
|---|---|---:|---|
| `idSite` | number | oui | `> 0` |

### Validations metier backend
- Agent doit exister.
- Site doit exister.
- Site et agent doivent appartenir a la meme societe.
- Controle de perimetre role/societe (non super-admin).

### Response 200
| Champ | Type |
|---|---|
| `message` | string |
| `idAgent` | number |
| `ancienIdSite` | number/null |
| `nouveauIdSite` | number |

### Erreurs
- `400`: donnees invalides ou site hors societe.
- `403`: non autorise.
- `404`: agent ou site introuvable.
- `500`: erreur serveur.

---

## 3. Synchronisation offline (mobile prioritaire)

## 3.1 GET `/api/sync/bootstrap`

### Response 200
| Champ | Type | Description |
|---|---|---|
| `watermark` | string | Reference delta future |
| `clients` | array | Peut etre vide au bootstrap |
| `arrears` | array | Peut etre vide au bootstrap |
| `reservationWorkflowV2` | object | Hints API workflow reservation |

---

## 3.2 GET `/api/sync/clients`

### Query params
| Param | Type | Requis | Description |
|---|---|---:|---|
| `cursor` | string | non | Pagination cursor opaque |
| `pageSize` | number | non | 1..5000 (defaut 1000) |
| `snapshot` | string | non | Cohérence session |
| `since` | string | non | Watermark delta |

### Response 200
| Champ | Type |
|---|---|
| `snapshot` | string |
| `items` | `ClientSyncDto[]` |
| `nextCursor` | string/null |
| `hasMore` | bool |
| `nextSince` | string/null |

### `ClientSyncDto`
| Champ | Type |
|---|---|
| `idClient` | number |
| `nomClient` | string |
| `adresseClient` | string |
| `telephone` | string/null |
| `emailClient` | string/null |
| `genreClient` | string/null |
| `idSociete` | number |
| `idCategorieClient` | number/null |
| `isActif` | bool |
| `statut` | bool |
| `isDeleted` | bool |
| `updatedAt` | string(date) |

---

## 3.3 GET `/api/sync/arrears`

### Query params
| Param | Type | Requis |
|---|---|---:|
| `cursor` | string | non |
| `pageSize` | number | non |
| `snapshot` | string | non |
| `since` | string | non |
| `onlyOutstanding` | bool | non |

### Response 200
| Champ | Type |
|---|---|
| `snapshot` | string |
| `items` | `ArrearSyncDto[]` |
| `nextCursor` | string/null |
| `hasMore` | bool |
| `nextSince` | string/null |

### `ArrearSyncDto` (contrat actuel backend)
| Champ | Type |
|---|---|
| `idClientFacture` | number |
| `idFacture` | number/null |
| `idClient` | number |
| `numeroFacture` | string/null |
| `dateEmission` | string(date) |
| `mois` | string/null |
| `annees` | number/null |
| `montantTotal` | number |
| `montantPaye` | number |
| `montantDu` | number |
| `libelleUsage` | string/null |
| `estArrierePreExistant` | bool |
| `dateModification` | string(date) |

---

## 3.4 GET `/api/sync/deletions`

### Query params
| Param | Type | Requis |
|---|---|---:|
| `since` | string | oui |
| `snapshot` | string | non |

### Response 200
| Champ | Type |
|---|---|
| `snapshot` | string |
| `deletedClientIds` | number[] |
| `removedClientFactureIds` | number[] |
| `deletedPaymentIds` | number[] |
| `nextSince` | string/null |

---

## 3.5 POST `/api/sync/payments/batch`

### Request body
| Champ | Type | Requis |
|---|---|---:|
| `items` | `PaymentRequestDto[]` | oui |

### `PaymentRequestDto`
| Champ | Type | Requis |
|---|---|---:|
| `clientRequestId` | string | oui |
| `idClient` | number | oui |
| `idClientFacture` | number/null | non |
| `idFacture` | number/null | non |
| `montantPaye` | number | oui |
| `datePaiementUtc` | string(date) | oui |
| `methodePaiement` | string | oui |
| `referenceTransaction` | string/null | non |
| `commentaire` | string/null | non |
| `deviceId` | string/null | non |
| `agentId` | number/null | non |

### Response 200
| Champ | Type |
|---|---|
| `results` | `PaymentResultDto[]` |
| `summary` | `PaymentSummaryDto` |

### `PaymentResultDto`
| Champ | Type |
|---|---|
| `clientRequestId` | string |
| `status` | string (`created`/`duplicate`/`rejected`/`error`) |
| `idPaiement` | number/null |
| `newMontantDu` | number/null |
| `message` | string |
| `errorCode` | string/null |

### `PaymentSummaryDto`
| Champ | Type |
|---|---|
| `total` | number |
| `created` | number |
| `duplicates` | number |
| `rejected` | number |
| `errors` | number |

---

## 4. Codes erreurs standards

| Code | Signification | Action frontend recommandee |
|---:|---|---|
| 400 | Requete invalide/metier | Afficher `message` backend |
| 401 | Non authentifie/token expire | Tenter refresh token puis relogin |
| 403 | Interdit (role/perimetre) | Bloquer action, message metier |
| 404 | Ressource introuvable | Afficher et proposer rafraichir |
| 500 | Erreur serveur | Message generique + retry |

---

## 5. Notes d'integration importantes

- Utiliser `utilisateur.idSite` comme site courant apres login.
- Si present, `agent.idSite` doit etre coherent avec `utilisateur.idSite`.
- En UI admin, proposer reassignment via `PUT /api/Agent/{idAgent}/site`.
- Cote Flutter offline, persister:
  - `accessToken`
  - `refreshToken`
  - `snapshot`
  - `since`
  - `cursor`

