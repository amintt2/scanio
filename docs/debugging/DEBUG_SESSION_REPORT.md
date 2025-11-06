# 🐛 Session de Débogage - TomoScan
**Date**: 2025-11-05  
**Status Build**: ✅ BUILD SUCCEEDED

---

## 📊 Résumé de l'exploration

### ✅ Points positifs
1. **Build réussi** - Le projet compile sans erreurs
2. **Architecture solide** - SwiftUI + Supabase + CoreData bien structuré
3. **Features implémentées** - Toutes les phases du PROFILE_FEATURES_PLAN.md sont codées
4. **Logs de debug** - Bons logs avec emojis dans ProfileViewModel et SupabaseManager
5. **Bouton favori** - Implémenté dans MangaDetailsHeaderView (ligne 319-329)
6. **Classement personnel** - PersonalRankingsView avec drag & drop fonctionnel
7. **Historique de lecture** - ReadingHistoryView implémenté

### 🔍 Zones à vérifier

#### 1. **Base de données Supabase**
**Priorité**: 🔴 HAUTE

**Tables à vérifier**:
- `scanio_profiles` - Profils utilisateurs
- `scanio_reading_history` - Historique de lecture
- `scanio_personal_rankings` - Classements personnels
- `scanio_canonical_manga` - Mangas canoniques
- `scanio_chapter_comments` - Commentaires
- `scanio_profile_visibility_settings` - Paramètres de visibilité

**Fonctions SQL à vérifier**:
```sql
-- 1. Vérifier que la fonction existe
SELECT routine_name, routine_definition
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name = 'scanio_get_user_stats';

-- 2. Tester la fonction avec votre user ID
SELECT * FROM scanio_get_user_stats(auth.uid());

-- 3. Vérifier les données brutes
SELECT COUNT(*) FROM scanio_reading_history WHERE user_id = auth.uid();
SELECT COUNT(DISTINCT canonical_manga_id) FROM scanio_reading_history WHERE user_id = auth.uid();
SELECT COUNT(*) FROM scanio_personal_rankings WHERE user_id = auth.uid() AND is_favorite = true;
SELECT COUNT(*) FROM scanio_chapter_comments WHERE user_id = auth.uid();
```

**Vues à vérifier**:
```sql
-- Vérifier que les vues existent
SELECT table_name FROM information_schema.views 
WHERE table_schema = 'public' 
AND table_name IN (
    'scanio_reading_history_with_manga',
    'scanio_personal_rankings_with_manga'
);
```

**RLS Policies à vérifier**:
```sql
-- Vérifier les policies sur scanio_reading_history
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'scanio_reading_history';

-- Vérifier les policies sur scanio_personal_rankings
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'scanio_personal_rankings';
```

#### 2. **Synchronisation CoreData ↔ Supabase**
**Priorité**: 🟡 MOYENNE

**Fichiers concernés**:
- `Shared/Managers/SyncManager.swift`
- `Shared/Managers/SupabaseManager.swift`

**Points à vérifier**:
1. La sync se lance-t-elle au démarrage ? (AppDelegate.swift ligne 202-212)
2. Les erreurs de sync sont-elles loggées ?
3. L'historique local (CoreData) est-il bien uploadé vers Supabase ?

**Test manuel**:
```swift
// Dans la console Xcode, chercher ces logs:
// "🔄 User is authenticated, starting background sync..."
// "✅ Background sync completed successfully"
// "⚠️ Background sync failed: ..."
```

#### 3. **Fonction getLibraryMangaCount()**
**Priorité**: 🟢 BASSE (déjà implémentée)

**Fichier**: `Shared/Managers/CoreData/CoreDataManager+LibraryManga.swift` (ligne 49-58)

✅ La fonction existe et est correctement implémentée
✅ Elle est appelée dans ProfileViewModel (ligne 353)

**Problème potentiel**: La fonction est synchrone mais appelée dans un contexte async
```swift
// Ligne 353 de ProfileSettingsView.swift
libraryCount = CoreDataManager.shared.getLibraryMangaCount()
```

**Solution recommandée**: Rendre l'appel async pour éviter de bloquer le main thread
```swift
libraryCount = await CoreDataManager.shared.container.performBackgroundTask { context in
    CoreDataManager.shared.getLibraryMangaCount(context: context)
}
```

#### 4. **Gestion des erreurs dans ProfileSettingsView**
**Priorité**: 🟡 MOYENNE

**Fichier**: `iOS/New/Views/Settings/ProfileSettingsView.swift`

**Problèmes potentiels**:
1. Ligne 356-386: La gestion d'erreur est bonne mais pourrait être plus spécifique
2. Les erreurs de décodage JSON ne sont pas catchées séparément
3. Pas de retry automatique en cas d'erreur réseau

**Amélioration suggérée**:
```swift
} catch let error as DecodingError {
    print("🔴 Decoding error: \(error)")
    errorMessage = "Erreur de format de données. Veuillez réessayer."
    showError = true
} catch let error as SupabaseError {
    // Gérer les erreurs Supabase spécifiquement
    print("🔴 Supabase error: \(error)")
    errorMessage = error.localizedDescription
    showError = true
} catch {
    // Autres erreurs
    print("🔴 Unknown error: \(error)")
    errorMessage = "Une erreur inattendue s'est produite"
    showError = true
}
```

#### 5. **Bouton Favori dans MangaDetailsHeaderView**
**Priorité**: 🟢 BASSE (déjà implémenté)

**Fichier**: `iOS/New/Views/Manga/MangaDetailsHeaderView.swift`

✅ Le bouton existe (ligne 319-329)
✅ La fonction toggleFavorite() est implémentée (ligne 444-485)
✅ Le chargement du statut favori est implémenté (ligne 488-514)

**Problème potentiel**: 
- Ligne 503: Fetch de TOUS les rankings (limit: 1000) juste pour vérifier si un manga est favori
- Cela peut être lent si l'utilisateur a beaucoup de rankings

**Solution recommandée**:
```swift
// Au lieu de fetcher tous les rankings, créer une fonction spécifique
func checkIsFavorite(canonicalMangaId: String) async throws -> Bool {
    let url = URL(string: "\(supabaseURL)/rest/v1/scanio_personal_rankings?canonical_manga_id=eq.\(canonicalMangaId)&is_favorite=eq.true&limit=1")!
    // ... fetch et retourner true si résultat non vide
}
```

---

## 🧪 Tests à effectuer

### Test 1: Vérifier les stats utilisateur
1. Ouvrir l'app
2. Aller dans Settings → Profile
3. Vérifier que les stats s'affichent correctement
4. Chercher dans les logs Xcode:
   - `🟢 Stats loaded: karma=X`
   - `📊 fetchUserStats - Success! Chapters: X, Manga: Y`

**Si erreur**: Chercher `❌ fetchUserStats` dans les logs

### Test 2: Vérifier le bouton favori
1. Ouvrir un manga
2. Cliquer sur le bouton cœur
3. Chercher dans les logs:
   - `❤️ toggleFavorite called`
   - `✅ Added to favorites` ou `✅ Removed from favorites`
4. Aller dans Settings → Profile → Classement personnel
5. Vérifier que le manga apparaît

**Si erreur**: Chercher `❌ Error toggling favorite` dans les logs

### Test 3: Vérifier l'historique de lecture
1. Lire quelques pages d'un chapitre
2. Aller dans Settings → Profile → Historique de lecture
3. Vérifier que le chapitre apparaît
4. Vérifier que le compteur "Chapitres lus" augmente

**Si erreur**: Vérifier la table `scanio_reading_history` dans Supabase

### Test 4: Vérifier le drag & drop du classement
1. Aller dans Settings → Profile → Classement personnel
2. Cliquer sur "Modifier"
3. Réorganiser les mangas
4. Chercher dans les logs:
   - `🔄 moveRanking - from: X indexes, to: Y`
   - `✅ Rankings reordered successfully`

---

## 🔧 Commandes de débogage

### Vérifier le build
```bash
xcodebuild -project Aidoku.xcodeproj -scheme "Aidoku (iOS)" -configuration Debug -sdk iphonesimulator -skipPackagePluginValidation build 2>&1 | grep -E "(\*\* BUILD)" | tail -1
```

### Lancer l'app en mode debug
```bash
# Ouvrir Xcode et lancer avec Cmd+R
# Ouvrir la console de logs (Cmd+Shift+Y)
# Filtrer par emoji: 🔴 🟢 🔵 ❌ ✅ 📊 ❤️ 🔄
```

### Vérifier les logs Supabase
1. Aller sur https://supabase.com
2. Ouvrir votre projet
3. Aller dans "Logs" → "Postgres Logs"
4. Chercher les erreurs liées à `scanio_get_user_stats`

---

## 📝 Checklist de débogage

- [ ] Vérifier que la fonction SQL `scanio_get_user_stats` existe
- [ ] Tester la fonction SQL avec `SELECT * FROM scanio_get_user_stats(auth.uid())`
- [ ] Vérifier que les tables Supabase contiennent des données
- [ ] Vérifier les RLS policies
- [ ] Tester le chargement du profil dans l'app
- [ ] Tester le bouton favori
- [ ] Tester l'historique de lecture
- [ ] Tester le classement personnel
- [ ] Vérifier les logs de sync au démarrage
- [ ] Vérifier que `getLibraryMangaCount()` retourne la bonne valeur

---

## 🚀 Prochaines étapes

1. **Vérifier Supabase** - Exécuter les requêtes SQL ci-dessus
2. **Tester l'app** - Suivre les tests 1-4
3. **Analyser les logs** - Chercher les erreurs dans Xcode
4. **Corriger les bugs** - Selon les résultats des tests
5. **Optimiser** - Implémenter les solutions recommandées

---

## 📚 Fichiers clés à surveiller

| Fichier | Rôle | Logs à chercher |
|---------|------|-----------------|
| `ProfileSettingsView.swift` | Vue du profil | 🔵 🟢 🔴 |
| `SupabaseManager.swift` | API Supabase | 📊 ❌ ✅ |
| `MangaDetailsHeaderView.swift` | Bouton favori | ❤️ |
| `PersonalRankingsView.swift` | Classement | 🔄 |
| `SyncManager.swift` | Synchronisation | 🔄 ✅ ⚠️ |

---

## 🔥 Problèmes critiques identifiés

### Problème 1: Expiration de session non gérée
**Priorité**: 🔴 CRITIQUE

**Fichier**: `Shared/Managers/SupabaseManager.swift` ligne 48-51

**Code actuel**:
```swift
var isAuthenticated: Bool {
    guard let session = currentSession else { return false }
    return session.expiresAt > Date()
}
```

**Problème**: Si la session expire, l'utilisateur reste "connecté" dans l'app mais toutes les requêtes API échoueront avec 401 Unauthorized.

**Solution recommandée**: Ajouter un refresh token automatique
```swift
var isAuthenticated: Bool {
    guard let session = currentSession else { return false }

    // Si la session expire dans moins de 5 minutes, la rafraîchir
    if session.expiresAt.timeIntervalSinceNow < 300 {
        Task {
            try? await refreshSession()
        }
    }

    return session.expiresAt > Date()
}

func refreshSession() async throws {
    guard let session = currentSession else {
        throw SupabaseError.notAuthenticated
    }

    let url = URL(string: "\(supabaseURL)/auth/v1/token?grant_type=refresh_token")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")

    let body = ["refresh_token": session.refreshToken]
    request.httpBody = try JSONEncoder().encode(body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw SupabaseError.authenticationFailed
    }

    let newSession = try JSONDecoder().decode(AuthSession.self, from: data)
    saveSession(newSession)
}
```

### Problème 2: Sync au démarrage peut bloquer l'UI
**Priorité**: 🟡 MOYENNE

**Fichier**: `iOS/AppDelegate.swift` ligne 202-212

**Code actuel**:
```swift
Task {
    if SupabaseManager.shared.isAuthenticated {
        print("🔄 User is authenticated, starting background sync...")
        do {
            try await SyncManager.shared.syncAll()
            print("✅ Background sync completed successfully")
        } catch {
            print("⚠️ Background sync failed: \(error)")
        }
    }
}
```

**Problème**: La sync complète peut prendre du temps et bloquer l'app au démarrage.

**Solution recommandée**: Ajouter un délai et rendre la sync vraiment asynchrone
```swift
Task.detached(priority: .background) {
    // Attendre 2 secondes pour laisser l'UI se charger
    try? await Task.sleep(nanoseconds: 2_000_000_000)

    if SupabaseManager.shared.isAuthenticated {
        print("🔄 User is authenticated, starting background sync...")
        do {
            try await SyncManager.shared.syncAll()
            print("✅ Background sync completed successfully")
        } catch {
            print("⚠️ Background sync failed: \(error)")
        }
    }
}
```

### Problème 3: Pas de gestion des erreurs réseau
**Priorité**: 🟡 MOYENNE

**Fichier**: `Shared/Managers/SupabaseManager.swift` (toutes les fonctions fetch)

**Problème**: Si l'utilisateur n'a pas de connexion internet, les requêtes échouent sans message clair.

**Solution recommandée**: Ajouter une vérification de connectivité
```swift
func checkNetworkConnection() -> Bool {
    // Utiliser Reachability qui existe déjà dans le projet
    return Reachability.connectionType != .none
}

// Dans chaque fonction fetch, ajouter:
guard checkNetworkConnection() else {
    throw SupabaseError.networkError
}
```

### Problème 4: AuthSession manque le refreshToken
**Priorité**: 🔴 CRITIQUE

**Fichier**: `Shared/Models/UserProfile.swift` (chercher AuthSession)

**Problème**: Pour rafraîchir la session, il faut un refresh_token. Vérifier que AuthSession le contient.

**À vérifier**:
```swift
struct AuthSession: Codable {
    let accessToken: String
    let refreshToken: String  // ← Doit exister
    let expiresAt: Date
    let user: SupabaseUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case user
    }
}
```

### Problème 5: Pas de retry automatique sur les erreurs réseau
**Priorité**: 🟢 BASSE

**Fichier**: Tous les managers

**Solution recommandée**: Créer une fonction helper pour retry
```swift
func retryRequest<T>(
    maxRetries: Int = 3,
    delay: TimeInterval = 1.0,
    operation: @escaping () async throws -> T
) async throws -> T {
    var lastError: Error?

    for attempt in 1...maxRetries {
        do {
            return try await operation()
        } catch {
            lastError = error
            print("⚠️ Attempt \(attempt)/\(maxRetries) failed: \(error)")

            if attempt < maxRetries {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }

    throw lastError ?? SupabaseError.networkError
}

// Utilisation:
let stats = try await retryRequest {
    try await SupabaseManager.shared.fetchUserStats()
}
```

---

## 📋 Checklist de vérification complète

### Base de données Supabase
- [ ] Toutes les tables existent
- [ ] La fonction `scanio_get_user_stats` existe
- [ ] Les vues `_with_manga` existent
- [ ] Les RLS policies sont correctes
- [ ] Les index sont créés pour les performances
- [ ] Les triggers sont actifs

### Authentification
- [ ] La session se sauvegarde correctement
- [ ] La session se charge au démarrage
- [ ] Le refresh token existe dans AuthSession
- [ ] L'expiration de session est gérée
- [ ] La déconnexion nettoie bien la session

### Synchronisation
- [ ] La sync se lance au démarrage (si authentifié)
- [ ] La sync se lance après sign in
- [ ] Les erreurs de sync sont loggées
- [ ] La sync ne bloque pas l'UI
- [ ] Les données CoreData sont bien uploadées

### Interface utilisateur
- [ ] Le profil se charge sans erreur
- [ ] Les stats affichent les bonnes valeurs
- [ ] Le bouton favori fonctionne
- [ ] Le classement personnel s'affiche
- [ ] L'historique de lecture s'affiche
- [ ] Le drag & drop fonctionne

### Gestion d'erreurs
- [ ] Les erreurs réseau sont catchées
- [ ] Les erreurs de décodage sont catchées
- [ ] Les messages d'erreur sont clairs
- [ ] Les erreurs sont loggées avec emojis
- [ ] L'utilisateur est informé des erreurs

### Performance
- [ ] Pas d'appels API inutiles
- [ ] Les requêtes sont optimisées (limit, select)
- [ ] Les images sont cachées (Nuke)
- [ ] CoreData utilise des background contexts
- [ ] Pas de blocage du main thread

---

**Fin du rapport** 🎯

