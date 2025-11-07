# 🔮 Fonctionnalités Futures - TomoScan

Ce document décrit les fonctionnalités futures préparées grâce au système de présence en ligne (Phase 7).

---

## 📋 Vue d'ensemble

Le système de présence en ligne implémenté en Phase 7 fournit l'infrastructure nécessaire pour plusieurs fonctionnalités sociales avancées. Toutes ces fonctionnalités sont **prêtes à être implémentées** car la base technique est déjà en place.

---

## 💬 Chat en Temps Réel

### Description
Système de messagerie instantanée entre utilisateurs avec indicateurs de présence en ligne.

### Fonctionnalités
- **Messages privés** entre utilisateurs
- **Indicateur "en ligne"** pour savoir qui est disponible
- **Indicateur "en train d'écrire..."** en temps réel
- **Notifications** de nouveaux messages
- **Historique** des conversations
- **Statut de lecture** (lu/non lu)

### Infrastructure Existante
✅ **Déjà disponible** :
- Table `scanio_user_presence` avec statut en ligne
- Fonction `getUsersPresence()` pour récupérer le statut de plusieurs utilisateurs
- Realtime Supabase activé pour les mises à jour en temps réel

### Schéma SQL à Créer
```sql
-- Table des conversations
CREATE TABLE scanio_conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des participants
CREATE TABLE scanio_conversation_participants (
    conversation_id UUID REFERENCES scanio_conversations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    last_read_at TIMESTAMPTZ,
    PRIMARY KEY (conversation_id, user_id)
);

-- Table des messages
CREATE TABLE scanio_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES scanio_conversations(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    edited_at TIMESTAMPTZ,
    is_deleted BOOLEAN DEFAULT FALSE
);

-- Index pour performance
CREATE INDEX idx_messages_conversation ON scanio_messages(conversation_id, created_at DESC);
CREATE INDEX idx_participants_user ON scanio_conversation_participants(user_id);

-- RLS Policies
ALTER TABLE scanio_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE scanio_conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE scanio_messages ENABLE ROW LEVEL SECURITY;

-- Les utilisateurs peuvent voir les conversations dont ils sont participants
CREATE POLICY "Users can view their conversations"
    ON scanio_conversations FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM scanio_conversation_participants
            WHERE conversation_id = id AND user_id = auth.uid()
        )
    );

-- Les utilisateurs peuvent voir les messages de leurs conversations
CREATE POLICY "Users can view messages in their conversations"
    ON scanio_messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM scanio_conversation_participants
            WHERE conversation_id = scanio_messages.conversation_id AND user_id = auth.uid()
        )
    );

-- Activer Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE scanio_messages;
```

### Exemple d'Implémentation Swift
```swift
// Récupérer les amis en ligne pour le chat
let friendIds = await getFriendsList()
let onlineFriends = try await supabase.getUsersPresence(userIds: friendIds)
    .filter { $0.isOnline }

// Afficher la liste avec indicateur en ligne
ForEach(onlineFriends) { friend in
    HStack {
        Avatar(userId: friend.userId)
        Text(friend.userName)
        Spacer()
        OnlineStatusBadge(isOnline: true)
    }
}

// Écouter les nouveaux messages en temps réel
supabase.realtime
    .channel("messages:\(conversationId)")
    .on(.insert) { message in
        // Ajouter le message à la conversation
        self.messages.append(message)
    }
    .subscribe()
```

---

## 👥 Liste d'Amis

### Description
Système d'amis avec demandes d'amitié, acceptation/refus, et liste des amis en ligne.

### Fonctionnalités
- **Demandes d'amitié** (envoyer/recevoir)
- **Accepter/Refuser** les demandes
- **Liste d'amis** avec statut en ligne
- **Bloquer** des utilisateurs
- **Tri automatique** : amis en ligne en premier
- **Notifications** de nouvelles demandes

### Infrastructure Existante
✅ **Déjà disponible** :
- Table `scanio_user_presence` avec statut en ligne
- Fonction `getUsersPresence()` pour récupérer le statut de plusieurs amis
- Modèle `UserProfile` avec informations utilisateur

### Schéma SQL à Créer
```sql
-- Table des amitiés
CREATE TABLE scanio_friendships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    friend_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT CHECK (status IN ('pending', 'accepted', 'blocked')) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, friend_id)
);

-- Index pour performance
CREATE INDEX idx_friendships_user ON scanio_friendships(user_id, status);
CREATE INDEX idx_friendships_friend ON scanio_friendships(friend_id, status);

-- RLS Policies
ALTER TABLE scanio_friendships ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their friendships"
    ON scanio_friendships FOR SELECT
    USING (user_id = auth.uid() OR friend_id = auth.uid());

CREATE POLICY "Users can create friendships"
    ON scanio_friendships FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their friendships"
    ON scanio_friendships FOR UPDATE
    USING (user_id = auth.uid() OR friend_id = auth.uid());

-- Fonction pour récupérer les amis avec leur statut
CREATE OR REPLACE FUNCTION scanio_get_friends_with_presence(p_user_id UUID)
RETURNS TABLE (
    friend_id UUID,
    user_name TEXT,
    avatar_url TEXT,
    is_online BOOLEAN,
    last_seen TIMESTAMPTZ,
    friendship_status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        CASE 
            WHEN f.user_id = p_user_id THEN f.friend_id
            ELSE f.user_id
        END as friend_id,
        p.user_name,
        p.avatar_url,
        COALESCE(pr.is_online, FALSE) as is_online,
        pr.last_seen,
        f.status as friendship_status
    FROM scanio_friendships f
    LEFT JOIN scanio_profiles p ON (
        CASE 
            WHEN f.user_id = p_user_id THEN f.friend_id = p.user_id
            ELSE f.user_id = p.user_id
        END
    )
    LEFT JOIN scanio_user_presence pr ON pr.user_id = (
        CASE 
            WHEN f.user_id = p_user_id THEN f.friend_id
            ELSE f.user_id
        END
    )
    WHERE (f.user_id = p_user_id OR f.friend_id = p_user_id)
        AND f.status = 'accepted'
    ORDER BY 
        COALESCE(pr.is_online, FALSE) DESC,
        pr.last_seen DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Exemple d'Implémentation Swift
```swift
// Récupérer la liste d'amis avec statut en ligne
struct Friend: Codable {
    let friendId: String
    let userName: String
    let avatarUrl: String?
    let isOnline: Bool
    let lastSeen: Date?
    let friendshipStatus: String
}

func getFriendsWithPresence() async throws -> [Friend] {
    let response = try await supabase.rpc(
        "scanio_get_friends_with_presence",
        params: ["p_user_id": currentUserId]
    )
    return try JSONDecoder().decode([Friend].self, from: response.data)
}

// Afficher la liste avec section "En ligne"
var onlineFriends: [Friend] { friends.filter { $0.isOnline } }
var offlineFriends: [Friend] { friends.filter { !$0.isOnline } }

List {
    if !onlineFriends.isEmpty {
        Section("En ligne (\(onlineFriends.count))") {
            ForEach(onlineFriends) { friend in
                FriendRow(friend: friend)
            }
        }
    }
    
    if !offlineFriends.isEmpty {
        Section("Hors ligne") {
            ForEach(offlineFriends) { friend in
                FriendRow(friend: friend)
            }
        }
    }
}
```

---

## 💬 Indicateurs dans les Commentaires

### Description
Afficher le statut en ligne des auteurs de commentaires pour savoir si on peut avoir une réponse rapide.

### Fonctionnalités
- **Badge "En ligne"** à côté du nom d'utilisateur
- **"Vu il y a X min"** pour les utilisateurs récemment actifs
- **Chargement en batch** pour optimiser les performances
- **Mise à jour en temps réel** du statut

### Infrastructure Existante
✅ **Déjà disponible** :
- Table `scanio_user_presence` avec statut en ligne
- Fonction `getUsersPresence(userIds:)` pour récupérer le statut en batch
- Composant `OnlineStatusBadge` déjà créé

### Implémentation
Aucun schéma SQL supplémentaire nécessaire ! Tout est déjà prêt.

### Exemple d'Implémentation Swift
```swift
// Dans CommentListView
@State private var userPresences: [String: UserPresence] = [:]

func loadCommentPresences() async {
    // Récupérer tous les IDs d'auteurs uniques
    let authorIds = Array(Set(comments.map { $0.userId }))
    
    // Charger les statuts en une seule requête
    do {
        let presences = try await supabase.getUsersPresence(userIds: authorIds)
        
        // Créer un dictionnaire pour accès rapide
        await MainActor.run {
            userPresences = Dictionary(
                uniqueKeysWithValues: presences.map { ($0.userId, $0) }
            )
        }
    } catch {
        print("❌ Error loading presences: \(error)")
    }
}

// Dans CommentRow
HStack {
    Avatar(userId: comment.userId)
    
    VStack(alignment: .leading) {
        HStack {
            Text(comment.userName)
                .font(.headline)
            
            // Afficher le badge si en ligne
            if let presence = userPresences[comment.userId], presence.isOnline {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("En ligne")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            } else if let presence = userPresences[comment.userId], let lastSeen = presence.lastSeen {
                Text(formatLastSeen(lastSeen))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        
        Text(comment.content)
    }
}
```

---

## 🧹 Cleanup Automatique

### Description
Marquer automatiquement les utilisateurs inactifs comme hors ligne après 5 minutes d'inactivité.

### Fonctionnalités
- **Détection automatique** des utilisateurs inactifs
- **Mise à jour du statut** à "hors ligne"
- **Exécution périodique** (toutes les 5 minutes)
- **Optimisation** : ne traite que les utilisateurs récemment actifs

### Infrastructure Existante
✅ **Déjà disponible** :
- Fonction SQL `scanio_cleanup_stale_presence()` déjà créée
- Logique de détection d'inactivité (>5 min)

### Options d'Implémentation

#### Option 1 : pg_cron (Recommandé)
**Avantages** : Automatique, côté serveur, fiable  
**Inconvénients** : Nécessite l'extension pg_cron sur Supabase

```sql
-- Installer pg_cron (si pas déjà fait)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Planifier le cleanup toutes les 5 minutes
SELECT cron.schedule(
    'cleanup-stale-presence',
    '*/5 * * * *', -- Toutes les 5 minutes
    $$SELECT scanio_cleanup_stale_presence()$$
);

-- Vérifier que le cron est actif
SELECT * FROM cron.job;
```

#### Option 2 : Edge Function + Cron Externe
**Avantages** : Fonctionne sur tous les plans Supabase  
**Inconvénients** : Nécessite un service externe (GitHub Actions, Vercel Cron, etc.)

```typescript
// Edge Function: cleanup-presence.ts
import { createClient } from '@supabase/supabase-js'

Deno.serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  const { data, error } = await supabase.rpc('scanio_cleanup_stale_presence')

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }

  return new Response(JSON.stringify({ success: true, data }), {
    headers: { 'Content-Type': 'application/json' }
  })
})
```

```yaml
# GitHub Actions: .github/workflows/cleanup-presence.yml
name: Cleanup Stale Presence
on:
  schedule:
    - cron: '*/5 * * * *' # Toutes les 5 minutes

jobs:
  cleanup:
    runs-on: ubuntu-latest
    steps:
      - name: Call Edge Function
        run: |
          curl -X POST https://your-project.supabase.co/functions/v1/cleanup-presence \
            -H "Authorization: Bearer ${{ secrets.SUPABASE_ANON_KEY }}"
```

#### Option 3 : Client-side (Temporaire)
**Avantages** : Simple, pas de configuration serveur  
**Inconvénients** : Dépend de l'activité des utilisateurs

```swift
// Dans AppDelegate ou SceneDelegate
var presenceTimer: Timer?

func applicationDidBecomeActive(_ application: UIApplication) {
    guard SupabaseManager.shared.isAuthenticated else { return }
    
    // Marquer comme en ligne
    Task { await SupabaseManager.shared.setOnline() }
    
    // Maintenir la présence active toutes les 3 minutes
    presenceTimer = Timer.scheduledTimer(withTimeInterval: 180, repeats: true) { _ in
        Task { await SupabaseManager.shared.keepPresenceAlive() }
    }
}

func applicationDidEnterBackground(_ application: UIApplication) {
    presenceTimer?.invalidate()
    presenceTimer = nil
    
    if SupabaseManager.shared.isAuthenticated {
        Task { await SupabaseManager.shared.setOffline() }
    }
}

func applicationWillTerminate(_ application: UIApplication) {
    presenceTimer?.invalidate()
    
    if SupabaseManager.shared.isAuthenticated {
        Task { await SupabaseManager.shared.setOffline() }
    }
}
```

---

## 📊 Résumé

| Fonctionnalité | Infrastructure | SQL à Créer | Complexité | Priorité |
|----------------|----------------|-------------|------------|----------|
| **Chat en temps réel** | ✅ Prête | 3 tables + RLS | Moyenne | Haute |
| **Liste d'amis** | ✅ Prête | 1 table + fonction | Faible | Haute |
| **Indicateurs commentaires** | ✅ Prête | Aucun | Très faible | Moyenne |
| **Cleanup automatique** | ✅ Prête | Aucun (config) | Faible | Haute |

---

## 🎯 Prochaines Étapes Recommandées

1. **Configurer le cleanup automatique** (Option 1 ou 3)
2. **Implémenter la liste d'amis** (base pour le chat)
3. **Ajouter les indicateurs dans les commentaires** (rapide, bon impact UX)
4. **Développer le chat en temps réel** (fonctionnalité majeure)

---

**Dernière mise à jour** : 2025-11-07  
**Version** : 1.0

