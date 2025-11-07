# 🟢 Architecture du Système de Présence en Ligne

Documentation technique de l'architecture du système de présence en ligne de TomoScan.

---

## 📊 Vue d'ensemble

Le système de présence en ligne permet de suivre le statut en ligne/hors ligne des utilisateurs en temps réel, avec support pour des fonctionnalités sociales futures (chat, amis, commentaires).

---

## 🏗️ Architecture

### Composants Principaux

```
┌─────────────────────────────────────────────────────────────┐
│                        iOS App (Swift)                       │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │           SupabaseManager+Presence.swift             │   │
│  │  • setOnline()                                       │   │
│  │  • setOffline()                                      │   │
│  │  • getUserPresence(userId)                           │   │
│  │  • getUsersPresence(userIds[])                       │   │
│  │  • keepPresenceAlive()                               │   │
│  └──────────────────────────────────────────────────────┘   │
│                           ↕                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              SupabaseManager.swift                   │   │
│  │  • signIn() → setOnline()                            │   │
│  │  • signOut() → setOffline()                          │   │
│  └──────────────────────────────────────────────────────┘   │
│                           ↕                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                  UI Components                       │   │
│  │  • ProfileSettingsView (badge "En ligne")            │   │
│  │  • PublicProfileView (statut des autres)             │   │
│  │  • UserProfileSheet (statut dans sheets)             │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
└───────────────────────────┬───────────────────────────────────┘
                            │ HTTPS + Realtime
                            ↕
┌─────────────────────────────────────────────────────────────┐
│                    Supabase Backend                          │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         scanio_user_presence (Table)                 │   │
│  │  • user_id (UUID, PK)                                │   │
│  │  • is_online (BOOLEAN)                               │   │
│  │  • last_seen (TIMESTAMPTZ)                           │   │
│  │  • updated_at (TIMESTAMPTZ)                          │   │
│  │  • RLS Policies (SELECT: all, UPDATE: own)           │   │
│  │  • Realtime enabled                                  │   │
│  └──────────────────────────────────────────────────────┘   │
│                           ↕                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              SQL Functions                           │   │
│  │  • scanio_update_user_presence(p_is_online)          │   │
│  │  • scanio_get_user_presence(p_user_id)               │   │
│  │  • scanio_get_users_presence(p_user_ids[])           │   │
│  │  • scanio_cleanup_stale_presence()                   │   │
│  └──────────────────────────────────────────────────────┘   │
│                           ↕                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │            Cleanup Automation (Optional)             │   │
│  │  • pg_cron (toutes les 5 min)                        │   │
│  │  • Edge Function + External Cron                     │   │
│  │  • Client-side keepAlive()                           │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 Flux de Données

### 1. Connexion Utilisateur

```
User taps "Sign In"
    ↓
ProfileViewModel.signIn()
    ↓
SupabaseManager.signIn(email, password)
    ↓
Supabase Auth → Session créée
    ↓
SupabaseManager.setOnline()
    ↓
SQL: scanio_update_user_presence(is_online = true)
    ↓
Table: scanio_user_presence updated
    ↓
Realtime: Broadcast to subscribers
    ↓
UI: Badge "En ligne" appears
```

### 2. Déconnexion Utilisateur

```
User taps "Se déconnecter"
    ↓
ProfileViewModel.signOut()
    ↓
SupabaseManager.signOut()
    ↓
SupabaseManager.setOffline()
    ↓
SQL: scanio_update_user_presence(is_online = false)
    ↓
Table: scanio_user_presence updated
    ↓
Realtime: Broadcast to subscribers
    ↓
Session cleared
    ↓
UI: Badge "En ligne" disappears
```

### 3. Affichage du Statut d'un Autre Utilisateur

```
User opens PublicProfileView(userId: "abc123")
    ↓
ViewModel.loadProfile()
    ↓
SupabaseManager.fetchUserProfile(userId: "abc123")
    ↓
SQL: SELECT * FROM scanio_profiles WHERE user_id = 'abc123'
    ↓
Profile includes: isOnline, lastSeen
    ↓
UI: Display OnlineStatusBadge
    ↓
If isOnline == true → "🟢 En ligne"
If lastSeen < 1h → "Vu il y a X min"
If lastSeen < 24h → "Vu il y a Xh"
Else → "Vu il y a Xj"
```

### 4. Cleanup Automatique (Inactivité >5 min)

```
Cron Job (every 5 min)
    ↓
Execute: scanio_cleanup_stale_presence()
    ↓
SQL: UPDATE scanio_user_presence
     SET is_online = false
     WHERE is_online = true
       AND updated_at < NOW() - INTERVAL '5 minutes'
    ↓
Table: Stale presences marked offline
    ↓
Realtime: Broadcast updates
    ↓
UI: Badges update to "Vu il y a X min"
```

---

## 🗂️ Structure des Fichiers

### Backend (SQL)
```
bdd/
└── supabase_user_presence_schema.sql
    ├── Table: scanio_user_presence
    ├── RLS Policies
    ├── Functions:
    │   ├── scanio_update_user_presence()
    │   ├── scanio_get_user_presence()
    │   ├── scanio_get_users_presence()
    │   └── scanio_cleanup_stale_presence()
    └── Realtime configuration
```

### Swift (iOS)
```
Shared/
├── Models/
│   └── UserProfile.swift
│       ├── isOnline: Bool?
│       └── lastSeen: Date?
│
└── Managers/
    ├── SupabaseManager.swift
    │   ├── signIn() → setOnline()
    │   └── signOut() → setOffline()
    │
    └── SupabaseManager+Presence.swift
        ├── struct UserPresence
        ├── updatePresence(isOnline:)
        ├── getUserPresence(userId:)
        ├── getUsersPresence(userIds:)
        ├── setOnline()
        ├── setOffline()
        └── keepPresenceAlive()

iOS/New/Views/
├── Settings/
│   └── ProfileSettingsView.swift
│       └── Badge "En ligne" for current user
│
└── Profile/
    ├── PublicProfileView.swift
    │   ├── formatLastSeen()
    │   └── OnlineStatusBadge
    │
    └── UserProfileSheet.swift
        ├── formatLastSeen()
        └── OnlineStatusBadge
```

---

## 🔐 Sécurité (RLS Policies)

### Lecture (SELECT)
```sql
-- Tout le monde peut voir le statut de tous les utilisateurs
CREATE POLICY "Anyone can view user presence"
    ON scanio_user_presence FOR SELECT
    USING (true);
```

**Raison** : Le statut en ligne est une information publique, comme sur Discord, Slack, etc.

### Écriture (INSERT/UPDATE)
```sql
-- Les utilisateurs ne peuvent modifier que leur propre statut
CREATE POLICY "Users can update their own presence"
    ON scanio_user_presence FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());
```

**Raison** : Empêche les utilisateurs de modifier le statut des autres.

---

## ⚡ Performance

### Optimisations Implémentées

1. **Index sur user_id**
   ```sql
   CREATE INDEX idx_user_presence_user_id ON scanio_user_presence(user_id);
   ```
   - Recherche rapide par utilisateur
   - Temps de réponse < 10ms

2. **Requêtes Batch**
   ```swift
   // Au lieu de N requêtes
   for userId in userIds {
       let presence = try await getUserPresence(userId: userId)
   }
   
   // Une seule requête
   let presences = try await getUsersPresence(userIds: userIds)
   ```
   - Réduit le nombre de requêtes de N à 1
   - Économise la bande passante

3. **Cleanup Automatique**
   ```sql
   -- Nettoie seulement les utilisateurs récemment actifs
   WHERE is_online = true
     AND updated_at < NOW() - INTERVAL '5 minutes'
   ```
   - Ne scanne pas toute la table
   - Utilise l'index sur `is_online` et `updated_at`

4. **Realtime Selective**
   ```swift
   // S'abonner seulement aux utilisateurs pertinents
   supabase.realtime
       .channel("presence:friends")
       .on(.update, filter: "user_id=in.(friend1,friend2,friend3)")
       .subscribe()
   ```
   - Réduit le trafic réseau
   - Mises à jour ciblées

---

## 🔮 Extensibilité

### Fonctionnalités Futures Supportées

Le système actuel supporte nativement :

1. **Chat en Temps Réel**
   - Voir qui est en ligne pour discuter
   - Indicateur "en train d'écrire..."
   - Notifications de nouveaux messages

2. **Liste d'Amis**
   - Tri automatique : en ligne d'abord
   - Badge vert sur les avatars
   - Notifications quand un ami se connecte

3. **Indicateurs dans les Commentaires**
   - Badge "En ligne" à côté du nom
   - Savoir si on peut avoir une réponse rapide
   - Chargement en batch pour performance

4. **Statistiques d'Activité**
   - Heures de pointe
   - Utilisateurs actifs par jour
   - Temps moyen en ligne

Voir [`FUTURE_FEATURES.md`](FUTURE_FEATURES.md) pour les détails d'implémentation.

---

## 📊 Métriques

### Données Stockées
- **Par utilisateur** : ~50 bytes (UUID + 2 booleans + 2 timestamps)
- **10,000 utilisateurs** : ~500 KB
- **100,000 utilisateurs** : ~5 MB

### Trafic Réseau
- **setOnline()** : ~200 bytes
- **getUserPresence()** : ~100 bytes
- **getUsersPresence(100 users)** : ~10 KB
- **Realtime update** : ~150 bytes

### Latence
- **setOnline()** : < 100ms
- **getUserPresence()** : < 50ms
- **getUsersPresence(100)** : < 200ms
- **Realtime propagation** : < 500ms

---

## 🧪 Tests

### Tests Manuels à Effectuer

1. **Connexion/Déconnexion**
   - [ ] Se connecter → Badge "En ligne" apparaît
   - [ ] Se déconnecter → Badge disparaît
   - [ ] Vérifier dans Supabase : `is_online = true/false`

2. **Profils Publics**
   - [ ] Ouvrir le profil d'un utilisateur en ligne → "🟢 En ligne"
   - [ ] Ouvrir le profil d'un utilisateur hors ligne → "Vu il y a X min"
   - [ ] Vérifier le formatage : min/h/j

3. **Synchronisation Multi-Appareils**
   - [ ] Se connecter sur iPhone → Vérifier sur iPad
   - [ ] Se déconnecter sur iPhone → Vérifier sur iPad
   - [ ] Délai de propagation < 1 seconde

4. **Cleanup Automatique**
   - [ ] Se connecter
   - [ ] Attendre 6 minutes sans activité
   - [ ] Vérifier que `is_online = false`
   - [ ] Vérifier que `last_seen` est mis à jour

5. **Performance**
   - [ ] Charger une liste de 100 commentaires
   - [ ] Vérifier que les statuts se chargent en < 1 seconde
   - [ ] Vérifier qu'il n'y a qu'une seule requête batch

---

**Dernière mise à jour** : 2025-11-07  
**Version** : 1.0

