# 🔧 Guide de Débogage Interactif - TomoScan

Ce guide vous accompagne pas à pas pour déboguer l'application.

---

## 🎯 Étape 1 : Vérifier la base de données Supabase

### 1.1 Exécuter le diagnostic SQL

1. Ouvrez [Supabase Dashboard](https://supabase.com)
2. Sélectionnez votre projet TomoScan
3. Allez dans **SQL Editor**
4. Créez une nouvelle requête
5. Copiez-collez le contenu de `supabase_diagnostic.sql`
6. Cliquez sur **Run**

### 1.2 Analyser les résultats

**Vérifiez que toutes ces tables existent** :
- ✅ `scanio_profiles`
- ✅ `scanio_reading_history`
- ✅ `scanio_personal_rankings`
- ✅ `scanio_canonical_manga`
- ✅ `scanio_chapter_comments`
- ✅ `scanio_profile_visibility_settings`

**Si une table manque** :
- Exécutez le fichier SQL correspondant dans `supabase_*.sql`
- Exemple : `supabase_scanio_schema.sql`

**Vérifiez que la fonction `scanio_get_user_stats` existe** :
- Cherchez dans les résultats : `routine_name = scanio_get_user_stats`
- Si elle n'existe pas, exécutez `supabase_fix_user_stats_function.sql`

**Vérifiez les données utilisateur** :
- Section "7. DONNÉES DE L'UTILISATEUR ACTUEL"
- Notez les compteurs : chapitres lus, mangas lus, favoris, commentaires

---

## 🎯 Étape 2 : Tester l'application

### 2.1 Lancer l'app en mode debug

```bash
# Ouvrir Xcode
open Aidoku.xcodeproj

# Ou depuis le terminal
xcodebuild -project Aidoku.xcodeproj -scheme "Aidoku (iOS)" -configuration Debug -sdk iphonesimulator -skipPackagePluginValidation build
```

### 2.2 Ouvrir la console de logs

1. Dans Xcode : **Cmd + Shift + Y**
2. Filtrer par emoji pour faciliter la lecture :
   - 🔴 = Erreurs
   - ✅ = Succès
   - 🔵 = Info
   - ❤️ = Favoris
   - 📊 = Stats
   - 🔄 = Sync

### 2.3 Tester le chargement du profil

1. Lancez l'app (Cmd + R)
2. Allez dans **Settings → Profile**
3. Observez les logs dans la console

**Logs attendus** :
```
🔵 loadProfile called
🔵 isAuthenticated: true
🟢 Fetching profile, stats, and visibility settings...
🟢 Profile loaded: VotreNom
🟢 Stats loaded: karma=X
📊 fetchUserStats - Success! Chapters: X, Manga: Y
🟢 Visibility settings loaded
📚 Library count loaded: X
```

**Si vous voyez des erreurs** :
```
🔴 Error loading profile: ...
❌ fetchUserStats - Decoding error: ...
```
→ Passez à l'Étape 3 : Diagnostic des erreurs

---

## 🎯 Étape 3 : Diagnostic des erreurs courantes

### Erreur 1 : "Les données n'ont pas pu être lues"

**Symptôme** : Erreur lors du chargement du profil

**Causes possibles** :
1. La fonction SQL `scanio_get_user_stats` n'existe pas
2. La fonction retourne un format incorrect
3. Les RLS policies bloquent l'accès

**Solution** :

1. **Vérifier la fonction SQL** :
```sql
SELECT * FROM scanio_get_user_stats(auth.uid());
```

2. **Si erreur "function does not exist"** :
   - Exécutez `supabase_fix_user_stats_function.sql`

3. **Si erreur "permission denied"** :
   - Vérifiez les RLS policies :
```sql
SELECT * FROM pg_policies WHERE tablename = 'scanio_reading_history';
```

4. **Si la fonction retourne des données vides** :
   - Vérifiez que vous avez des données :
```sql
SELECT COUNT(*) FROM scanio_reading_history WHERE user_id = auth.uid();
```

### Erreur 2 : Compteur "Chapitres lus" affiche 0

**Symptôme** : Le compteur affiche 0 alors que vous avez lu des chapitres

**Causes possibles** :
1. Les données ne sont pas synchronisées avec Supabase
2. La fonction SQL compte mal
3. Les données sont dans CoreData mais pas dans Supabase

**Solution** :

1. **Vérifier les données locales (CoreData)** :
   - Cherchez dans les logs : `📚 Library count loaded: X`
   - Si X > 0, les données locales existent

2. **Vérifier les données Supabase** :
```sql
SELECT COUNT(*) FROM scanio_reading_history WHERE user_id = auth.uid();
```

3. **Si les données Supabase sont vides** :
   - Forcer une synchronisation :
   - Dans l'app : Settings → Profile → Se déconnecter → Se reconnecter
   - Cherchez dans les logs : `🔄 User is authenticated, starting background sync...`

4. **Si la sync échoue** :
   - Cherchez : `⚠️ Background sync failed: ...`
   - Vérifiez les permissions Supabase

### Erreur 3 : Le bouton favori ne fonctionne pas

**Symptôme** : Cliquer sur le cœur ne fait rien

**Causes possibles** :
1. Pas authentifié
2. Erreur lors de la création du canonical manga
3. Erreur lors de l'upsert du ranking

**Solution** :

1. **Vérifier l'authentification** :
   - Le bouton cœur n'apparaît que si vous êtes connecté
   - Allez dans Settings → Profile
   - Si "Créer un compte" apparaît, vous n'êtes pas connecté

2. **Tester le bouton** :
   - Ouvrez un manga
   - Cliquez sur le cœur
   - Cherchez dans les logs :
```
❤️ toggleFavorite called - Current state: false
🔍 loadCanonicalMangaId called
✅ Got canonical ID: xxx-xxx-xxx
❤️ Adding to favorites...
✅ Added to favorites
```

3. **Si erreur "canonical manga not found"** :
   - Vérifiez la table `scanio_canonical_manga` :
```sql
SELECT * FROM scanio_canonical_manga LIMIT 10;
```

4. **Si la table est vide** :
   - Exécutez `supabase_scanio_schema.sql`

### Erreur 4 : Le classement personnel est vide

**Symptôme** : "Aucun classement" alors que vous avez ajouté des favoris

**Causes possibles** :
1. Les favoris ne sont pas marqués comme `is_favorite = true`
2. La vue `scanio_personal_rankings_with_manga` n'existe pas
3. Les RLS policies bloquent l'accès

**Solution** :

1. **Vérifier les favoris** :
```sql
SELECT * FROM scanio_personal_rankings 
WHERE user_id = auth.uid() AND is_favorite = true;
```

2. **Si vide mais vous avez cliqué sur le cœur** :
   - Vérifiez les logs de l'upsert :
```
❤️ Adding to favorites...
✅ Added to favorites
```

3. **Si la requête SQL retourne des données mais l'app affiche "Aucun classement"** :
   - Vérifiez la vue :
```sql
SELECT * FROM scanio_personal_rankings_with_manga 
WHERE user_id = auth.uid() AND is_favorite = true;
```

4. **Si la vue n'existe pas** :
   - Créez-la avec le script approprié

---

## 🎯 Étape 4 : Optimisations recommandées

### 4.1 Optimiser le chargement du statut favori

**Problème actuel** : Fetch de tous les rankings (jusqu'à 1000) juste pour vérifier si un manga est favori

**Fichier** : `iOS/New/Views/Manga/MangaDetailsHeaderView.swift` ligne 503

**Solution** : Créer une fonction spécifique dans `SupabaseManager.swift`

```swift
func checkIsFavorite(canonicalMangaId: String) async throws -> Bool {
    guard isAuthenticated, let userId = currentSession?.user.id else {
        throw SupabaseError.notAuthenticated
    }
    
    let url = URL(string: "\(supabaseURL)/rest/v1/scanio_personal_rankings?user_id=eq.\(userId)&canonical_manga_id=eq.\(canonicalMangaId)&is_favorite=eq.true&limit=1")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
    request.setValue("Bearer \(currentSession?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw SupabaseError.networkError
    }
    
    let rankings = try JSONDecoder().decode([PersonalRanking].self, from: data)
    return !rankings.isEmpty
}
```

### 4.2 Rendre getLibraryMangaCount() async

**Problème actuel** : Appel synchrone dans un contexte async

**Fichier** : `iOS/New/Views/Settings/ProfileSettingsView.swift` ligne 353

**Solution** :

```swift
// Remplacer
libraryCount = CoreDataManager.shared.getLibraryMangaCount()

// Par
libraryCount = await CoreDataManager.shared.container.performBackgroundTask { context in
    CoreDataManager.shared.getLibraryMangaCount(context: context)
}
```

### 4.3 Améliorer la gestion d'erreur

**Fichier** : `iOS/New/Views/Settings/ProfileSettingsView.swift` ligne 355-386

**Solution** : Ajouter des cas spécifiques pour les erreurs de décodage

```swift
} catch let error as DecodingError {
    print("🔴 Decoding error: \(error)")
    errorMessage = "Erreur de format de données. Veuillez contacter le support."
    showError = true
} catch let error as SupabaseError {
    print("🔴 Supabase error: \(error)")
    errorMessage = error.localizedDescription
    showError = true
} catch {
    print("🔴 Unknown error: \(error)")
    errorMessage = "Une erreur inattendue s'est produite"
    showError = true
}
```

---

## 🎯 Étape 5 : Checklist finale

Avant de considérer le débogage terminé, vérifiez :

- [ ] ✅ Build réussi sans warnings
- [ ] ✅ Toutes les tables Supabase existent
- [ ] ✅ La fonction `scanio_get_user_stats` existe et fonctionne
- [ ] ✅ Les RLS policies sont correctes
- [ ] ✅ Le profil se charge sans erreur
- [ ] ✅ Les stats affichent les bonnes valeurs
- [ ] ✅ Le bouton favori fonctionne
- [ ] ✅ Le classement personnel affiche les favoris
- [ ] ✅ L'historique de lecture s'affiche
- [ ] ✅ Le drag & drop du classement fonctionne
- [ ] ✅ La synchronisation CoreData ↔ Supabase fonctionne
- [ ] ✅ Pas d'erreurs dans les logs Xcode

---

## 📞 Besoin d'aide ?

Si vous êtes bloqué :

1. **Vérifiez les logs** : Cherchez les emojis 🔴 ❌ dans la console Xcode
2. **Exécutez le diagnostic SQL** : `supabase_diagnostic.sql`
3. **Vérifiez les fichiers** : Consultez `DEBUG_SESSION_REPORT.md`
4. **Demandez de l'aide** : Partagez les logs et les résultats du diagnostic

---

**Bon débogage ! 🚀**

