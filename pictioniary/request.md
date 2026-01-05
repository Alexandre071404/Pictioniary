# Documentation des Requêtes API - Piction.ia.ry

**Base URL :** `https://pictioniary.wevox.cloud/api`

---

## Authentification

La plupart des endpoints nécessitent un **JWT (JSON Web Token)** obtenu via le login.

**Header requis :**
```
Authorization: Bearer {votre_jwt_token}
Content-Type: application/json
Accept: application/json
```

---

## 1. Authentification & Gestion des Joueurs

### 1.1 Créer un joueur

**Méthode :** `POST`  
**URL :** `/players`  
**Authentification :** Aucune

**Headers :**
```
Content-Type: application/json
```

**Body :**
```json
{
  "name": "alice",
  "password": "S3cret!pass"
}
```

**Exemple de réponse :**
```json
{
  "id": 123,
  "name": "alice",
  "created_at": "2025-12-01T10:00:00.000000Z"
}
```

---

### 1.2 Se connecter (Login)

**Méthode :** `POST`  
**URL :** `/login`  
**Authentification :** Aucune

**Headers :**
```
Content-Type: application/json
```

**Body :**
```json
{
  "name": "alice",
  "password": "S3cret!pass"
}
```

**Exemple de réponse :**
```json
{
  "jwt": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**⚠️ Important :** Conservez le `jwt` pour toutes les requêtes suivantes.

---

### 1.3 Obtenir mes informations

**Méthode :** `GET`  
**URL :** `/me`  
**Authentification :** Requise (Bearer JWT)

**Headers :**
```
Authorization: Bearer {votre_jwt_token}
Content-Type: application/json
Accept: application/json
```

**Exemple de réponse :**
```json
{
  "id": 123,
  "name": "alice",
  "created_at": "2025-12-01T10:00:00.000000Z"
}
```

---

### 1.4 Obtenir un joueur par ID

**Méthode :** `GET`  
**URL :** `/players/{playerId}`  
**Authentification :** Requise (Bearer JWT)

**Paramètres d'URL :**
- `playerId` : ID du joueur

**Headers :**
```
Authorization: Bearer {votre_jwt_token}
Content-Type: application/json
Accept: application/json
```

**Exemple :**
```
GET /players/123
```

---

## 2. Sessions de Jeu

### 2.1 Créer une session

**Méthode :** `POST`  
**URL :** `/game_sessions`  
**Authentification :** Requise (Bearer JWT)

**Headers :**
```
Authorization: Bearer {votre_jwt_token}
Content-Type: application/json
Accept: application/json
```

**Body :** Vide (pas de body requis)

**Exemple de réponse :**
```json
{
  "id": 2455,
  "status": "lobby",
  "created_at": "2025-12-01T10:00:00.000000Z"
}
```

**⚠️ Important :** Conservez l'`id` de la session pour les requêtes suivantes.

---

### 2.2 Rejoindre une session

**Méthode :** `POST`  
**URL :** `/game_sessions/{gameSessionId}/join`  
**Authentification :** Requise (Bearer JWT)

**Paramètres d'URL :**
- `gameSessionId` : ID de la session de jeu

**Headers :**
```
Authorization: Bearer {votre_jwt_token}
Content-Type: application/json
Accept: application/json
```

**Body :**
```json
{
  "color": "red"
}
```

**Valeurs possibles pour `color` :**
- `"red"` : Équipe rouge
- `"blue"` : Équipe bleue

**Exemple :**
```
POST /game_sessions/2455/join
```

---

### 2.3 Quitter une session

**Méthode :** `GET`  
**URL :** `/game_sessions/{gameSessionId}/leave`  
**Authentification :** Requise (Bearer JWT)

**Paramètres d'URL :**
- `gameSessionId` : ID de la session de jeu

**Headers :**
```
Authorization: Bearer {votre_jwt_token}
Content-Type: application/json
Accept: application/json
```

**Exemple :**
```
GET /game_sessions/2455/leave
```

---

### 2.4 Obtenir les détails d'une session

**Méthode :** `GET`  
**URL :** `/game_sessions/{gameSessionId}`  
**Authentification :** Requise (Bearer JWT)

**Paramètres d'URL :**
- `gameSessionId` : ID de la session de jeu

**Headers :**
```
Authorization: Bearer {votre_jwt_token}
Content-Type: application/json
Accept: application/json
```

**Exemple de réponse :**
```json
{
  "id": 2455,
  "status": "lobby",
  "red_team": [123, 456],
  "blue_team": [789, 101],
  "created_at": "2025-12-01T10:00:00.000000Z"
}
```

---

### 2.5 Obtenir le statut d'une session

**Méthode :** `GET`  
**URL :** `/game_sessions/{gameSessionId}/status`  
**Authentification :** Requise (Bearer JWT)

**Paramètres d'URL :**
- `gameSessionId` : ID de la session de jeu

**Headers :**
```
Authorization: Bearer {votre_jwt_token}
Content-Type: application/json
Accept: application/json
```

**Exemple de réponse :**
```json
{
  "status": "drawing"
}
```

**Valeurs possibles pour `status` :**
- `"lobby"` : En attente de joueurs
- `"challenge"` : Phase de création des challenges
- `"drawing"` : Phase de dessin
- `"guessing"` : Phase de devinette
- `"finished"` : Partie terminée

---

### 2.6 Démarrer une session

**Méthode :** `POST`  
**URL :** `/game_sessions/{gameSessionId}/start`  
**Authentification :** Requise (Bearer JWT)

**Paramètres d'URL :**
- `gameSessionId` : ID de la session de jeu

**Headers :**
```
Authorization: Bearer {votre_jwt_token}
Content-Type: application/json
Accept: application/json
```

**Body :** Vide (pas de body requis)

**Description :** Passe la session de `"lobby"` à `"challenge"` et lance la phase de jeu dans 3 minutes.

**Exemple :**
```
POST /game_sessions/2455/start
```

---

## 3. Challenges

### 3.1 Envoyer un challenge

**Méthode :** `POST`  
**URL :** `/game_sessions/{gameSessionId}/challenges`  
**Authentification :** Requise (Bearer JWT)

**Paramètres d'URL :**
- `gameSessionId` : ID de la session de jeu

**Headers :**
```
Authorization: Bearer {votre_jwt_token}
Content-Type: application/json
Accept: application/json
```

**Body :**
```json
{
  "first_word": "une",
  "second_word": "poule",
  "third_word": "sur",
  "fourth_word": "un",
  "fifth_word": "mur",
  "forbidden_words": ["volaille", "brique", "poulet"]
}
```

**Description :** Envoie un challenge au format "Un/Une [objet] sur/dans un/une [lieu]".  
Quand tous les joueurs ont envoyé 3 challenges, le statut passe à `"drawing"`.

**Exemple de réponse :**
```json
{
  "id": 5287,
  "game_session_id": 2455,
  "first_word": "une",
  "second_word": "poule",
  "third_word": "sur",
  "fourth_word": "un",
  "fifth_word": "mur",
  "forbidden_words": "[\"volaille\",\"brique\",\"poulet\"]",
  "created_at": "2025-12-01T10:38:31.000000Z"
}
```

---

### 3.2 Obtenir mes challenges à dessiner

**Méthode :** `GET`  
**URL :** `/game_sessions/{gameSessionId}/myChallenges`  
**Authentification :** Requise (Bearer JWT)

**Paramètres d'URL :**
- `gameSessionId` : ID de la session de jeu

**Headers :**
```
Authorization: Bearer {votre_jwt_token}
Content-Type: application/json
Accept: application/json
```

**Description :** Récupère les challenges assignés pour dessin (mode `"drawing"`).

**Exemple de réponse :**
```json
[
  {
    "id": 5287,
    "game_session_id": 2455,
    "first_word": "une",
    "second_word": "lampe",
    "third_word": "dans",
    "fourth_word": "une",
    "fifth_word": "étagère",
    "forbidden_words": "[\"éclairage\",\"ampoule\",\"fil\"]",
    "image_path": null,
    "previous_images": null,
    "prompt": null,
    "created_at": "2025-12-01T10:38:31.000000Z"
  }
]
```

---

### 3.3 Générer une image pour un challenge

**Méthode :** `POST`  
**URL :** `/game_sessions/{gameSessionId}/challenges/{challengeId}/draw`  
**Authentification :** Requise (Bearer JWT)

**Paramètres d'URL :**
- `gameSessionId` : ID de la session de jeu
- `challengeId` : ID du challenge

**Headers :**
```
Authorization: Bearer {votre_jwt_token}
Content-Type: application/json
Accept: application/json
```

**Body :**
```json
{
  "prompt": "Un objet lumineux posé sur une surface horizontale en bois"
}
```

**Description :** Soumet un prompt pour générer une image (via StableDiffusion). Le prompt ne doit **pas** contenir les mots du challenge ni les mots interdits.

**Exemple de réponse :**
```json
{
  "id": 5287,
  "game_session_id": 2455,
  "first_word": "une",
  "second_word": "lampe",
  "third_word": "dans",
  "fourth_word": "une",
  "fifth_word": "étagère",
  "forbidden_words": "[\"éclairage\",\"ampoule\",\"fil\"]",
  "image_path": "/storage/challenges/5287/image.png",
  "previous_images": "[\"/storage/challenges/5287/image.png\"]",
  "prompt": "Un objet lumineux posé sur une surface horizontale en bois",
  "updated_at": "2025-12-01T10:38:33.000000Z"
}
```

**⚠️ Note :** Pour régénérer une image, appelez à nouveau cet endpoint avec un nouveau prompt. Chaque régénération coûte **-10 points**.

---

### 3.4 Obtenir mes challenges à deviner

**Méthode :** `GET`  
**URL :** `/game_sessions/{gameSessionId}/myChallengesToGuess`  
**Authentification :** Requise (Bearer JWT)

**Paramètres d'URL :**
- `gameSessionId` : ID de la session de jeu

**Headers :**
```
Authorization: Bearer {votre_jwt_token}
Content-Type: application/json
Accept: application/json
```

**Description :** Récupère la liste des challenges à deviner (mode `"guessing"`). Ces challenges ont déjà une image générée.

**Exemple de réponse :**
```json
[
  {
    "id": 5287,
    "game_session_id": 2455,
    "first_word": "une",
    "second_word": "lampe",
    "third_word": "dans",
    "fourth_word": "une",
    "fifth_word": "étagère",
    "forbidden_words": "[\"éclairage\",\"ampoule\",\"fil\"]",
    "image_path": "/storage/challenges/5287/image.png",
    "previous_images": "[\"/storage/challenges/5287/image.png\"]",
    "prompt": "Un objet lumineux posé sur une surface horizontale en bois",
    "proposals": null,
    "is_resolved": null,
    "created_at": "2025-12-01T10:38:31.000000Z"
  }
]
```

**⚠️ Note :** Pour accéder à l'image, utilisez l'URL complète :  
`https://pictioniary.wevox.cloud/storage/challenges/{challengeId}/image.png`

---

### 3.5 Répondre à un challenge

**Méthode :** `POST`  
**URL :** `/game_sessions/{gameSessionId}/challenges/{challengeId}/answer`  
**Authentification :** Requise (Bearer JWT)

**Paramètres d'URL :**
- `gameSessionId` : ID de la session de jeu
- `challengeId` : ID du challenge

**Headers :**
```
Authorization: Bearer {votre_jwt_token}
Content-Type: application/json
Accept: application/json
```

**Body :**
```json
{
  "answer": "Une lampe dans une étagère",
  "is_resolved": false
}
```

**Description :** Envoie une réponse pour deviner le challenge. Peut être appelé plusieurs fois.  
Le backend vérifie si la réponse est correcte et retourne `is_resolved: true` si c'est le cas.

**Exemple de réponse :**
```json
{
  "id": 5287,
  "game_session_id": 2455,
  "proposals": ["Une lampe dans une étagère"],
  "is_resolved": true,
  "updated_at": "2025-12-01T10:45:00.000000Z"
}
```

**⚠️ Note :** 
- **-1 point** par mauvaise réponse
- **+25 points** par mot du challenge trouvé
- Quand le challenge est résolu, on inverse les rôles

---

### 3.6 Lister tous les challenges d'une session

**Méthode :** `GET`  
**URL :** `/game_sessions/{gameSessionId}/challenges`  
**Authentification :** Requise (Bearer JWT)

**Paramètres d'URL :**
- `gameSessionId` : ID de la session de jeu

**Headers :**
```
Authorization: Bearer {votre_jwt_token}
Content-Type: application/json
Accept: application/json
```

**Description :** Liste tous les challenges d'une session. **Uniquement disponible en mode `"finished"`**.

**Exemple de réponse :**
```json
[
  {
    "id": 5287,
    "game_session_id": 2455,
    "first_word": "une",
    "second_word": "lampe",
    "third_word": "dans",
    "fourth_word": "une",
    "fifth_word": "étagère",
    "forbidden_words": "[\"éclairage\",\"ampoule\",\"fil\"]",
    "image_path": "/storage/challenges/5287/image.png",
    "prompt": "Un objet lumineux posé sur une surface horizontale en bois",
    "proposals": ["Une lampe dans une étagère"],
    "is_resolved": true,
    "start_time": "2025-12-01T10:40:00.000000Z",
    "end_time": "2025-12-01T10:45:00.000000Z"
  }
]
```

---

## Flux de jeu recommandé

1. **Créer un joueur** : `POST /players`
2. **Se connecter** : `POST /login` → **Conserver le JWT**
3. **Obtenir mes infos** : `GET /me` → **Conserver le playerId**
4. **Créer une session** : `POST /game_sessions` → **Conserver le gameSessionId**
5. **Rejoindre la session** : `POST /game_sessions/{id}/join` (choisir `color: "red"` ou `"blue"`)
6. **Démarrer la session** : `POST /game_sessions/{id}/start`
7. **Envoyer des challenges** : `POST /game_sessions/{id}/challenges` (répéter jusqu'à 3 par joueur)
8. **Phase dessin** :
   - `GET /game_sessions/{id}/myChallenges` → Récupérer les challenges à dessiner
   - `POST /game_sessions/{id}/challenges/{challengeId}/draw` → Générer l'image
9. **Phase devinette** :
   - `GET /game_sessions/{id}/myChallengesToGuess` → Récupérer les challenges à deviner
   - `POST /game_sessions/{id}/challenges/{challengeId}/answer` → Envoyer une réponse
10. **Fin de partie** :
    - `GET /game_sessions/{id}/challenges` → Voir tous les challenges (mode `"finished"`)

---

## Codes de statut HTTP

- `200` : Succès
- `201` : Créé avec succès
- `400` : Requête invalide (Bad Request)
- `401` : Non autorisé (JWT manquant ou invalide)
- `403` : Interdit (accès refusé)
- `404` : Ressource non trouvée
- `500` : Erreur serveur

---

## Notes importantes

- **JWT** : Le token JWT doit être inclus dans toutes les requêtes authentifiées via le header `Authorization: Bearer {token}`
- **Base URL** : Toutes les URLs sont relatives à `https://pictioniary.wevox.cloud/api`
- **Images** : Les chemins d'images (`image_path`) sont relatifs. Pour y accéder, utilisez : `https://pictioniary.wevox.cloud{image_path}`
- **Statut de session** : Vérifiez régulièrement le statut avec `GET /game_sessions/{id}/status` pour savoir dans quelle phase vous êtes
- **Régénération** : Chaque régénération d'image coûte **-10 points**
- **Réponses** : Chaque mauvaise réponse coûte **-1 point**, chaque mot trouvé rapporte **+25 points**



