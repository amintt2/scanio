# 🚀 Guide de Déploiement - Système de Présence en Ligne

Guide étape par étape pour déployer le système de présence en ligne sur Supabase.

---

## ✅ Prérequis

- [x] Compte Supabase actif
- [x] Projet Supabase créé
- [x] Accès à l'éditeur SQL de Supabase
- [x] App TomoScan avec le code de présence déjà intégré

---

## 📋 Étapes de Déploiement

### Étape 1 : Exécuter le Schéma SQL

1. **Ouvrir Supabase Dashboard**
   - Aller sur [https://supabase.com/dashboard](https://supabase.com/dashboard)
   - Sélectionner votre projet TomoScan

2. **Ouvrir l'Éditeur SQL**
   - Dans le menu de gauche, cliquer sur **SQL Editor**
   - Cliquer sur **New Query**

3. **Copier le Schéma**
   - Ouvrir le fichier `bdd/supabase_user_presence_schema.sql`
   - Copier tout le contenu

4. **Exécuter le Script**
   - Coller le contenu dans l'éditeur SQL
   - Cliquer sur **Run** (ou `Cmd+Enter`)
   - Vérifier qu'il n'y a pas d'erreurs

5. **Vérifier la Création**
   ```sql
   -- Vérifier que la table existe
   SELECT * FROM scanio_user_presence LIMIT 1;
   
   -- Vérifier les fonctions
   SELECT routine_name 
   FROM information_schema.routines 
   WHERE routine_name LIKE 'scanio_%presence%';
   ```

   **Résultat attendu** :
   ```
   scanio_update_user_presence
   scanio_get_user_presence
   scanio_get_users_presence
   scanio_cleanup_stale_presence
   ```

---

### Étape 2 : Activer Realtime

1. **Ouvrir l'Éditeur SQL**
   - Nouvelle requête dans SQL Editor

2. **Activer Realtime pour la Table**
   ```sql
   ALTER PUBLICATION supabase_realtime ADD TABLE scanio_user_presence;
   ```

3. **Vérifier l'Activation**
   - Aller dans **Database** → **Replication**
   - Vérifier que `scanio_user_presence` apparaît dans la liste des tables répliquées

---

### Étape 3 : Configurer le Cleanup Automatique (Optionnel)

Choisir **UNE** des options suivantes :

#### Option A : pg_cron (Recommandé si disponible)

**Avantages** : Automatique, côté serveur, fiable  
**Inconvénients** : Nécessite l'extension pg_cron (pas disponible sur tous les plans)

```sql
-- 1. Vérifier si pg_cron est disponible
SELECT * FROM pg_extension WHERE extname = 'pg_cron';

-- 2. Si disponible, créer le cron job
SELECT cron.schedule(
    'cleanup-stale-presence',
    '*/5 * * * *', -- Toutes les 5 minutes
    $$SELECT scanio_cleanup_stale_presence()$$
);

-- 3. Vérifier que le job est créé
SELECT * FROM cron.job WHERE jobname = 'cleanup-stale-presence';
```

#### Option B : Client-side (Temporaire, simple)

**Avantages** : Simple, pas de configuration serveur  
**Inconvénients** : Dépend de l'activité des utilisateurs

Cette option est **déjà implémentée** dans le code Swift via `keepPresenceAlive()`.  
Aucune action supplémentaire nécessaire.

#### Option C : Edge Function + Cron Externe (Alternative)

**Avantages** : Fonctionne sur tous les plans  
**Inconvénients** : Nécessite un service externe

1. **Créer une Edge Function**
   - Aller dans **Edge Functions** dans Supabase Dashboard
   - Créer une nouvelle fonction `cleanup-presence`
   - Code :
   ```typescript
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

2. **Configurer un Cron Externe**
   - Utiliser GitHub Actions, Vercel Cron, ou cron-job.org
   - Appeler l'Edge Function toutes les 5 minutes

---

### Étape 4 : Tester le Système

#### Test 1 : Connexion/Déconnexion

1. **Lancer l'app TomoScan**
2. **Se connecter avec un compte**
3. **Vérifier dans Supabase** :
   ```sql
   SELECT * FROM scanio_user_presence 
   WHERE user_id = 'VOTRE_USER_ID';
   ```
   
   **Résultat attendu** :
   ```
   user_id: 24b71abe-0dee-428f-a0d7-e23e98b32f48
   is_online: true
   last_seen: 2025-11-07 14:30:00+00
   updated_at: 2025-11-07 14:30:00+00
   ```

4. **Se déconnecter**
5. **Vérifier à nouveau** :
   ```sql
   SELECT * FROM scanio_user_presence 
   WHERE user_id = 'VOTRE_USER_ID';
   ```
   
   **Résultat attendu** :
   ```
   is_online: false
   last_seen: 2025-11-07 14:35:00+00
   ```

#### Test 2 : Affichage du Statut

1. **Se connecter avec le compte A**
2. **Ouvrir le profil du compte A** (Settings → Profile)
3. **Vérifier** : Badge "🟢 En ligne" apparaît

4. **Se connecter avec le compte B sur un autre appareil**
5. **Ouvrir le profil du compte A depuis le compte B**
6. **Vérifier** : Badge "🟢 En ligne" apparaît

#### Test 3 : Cleanup Automatique

1. **Se connecter**
2. **Vérifier dans Supabase** : `is_online = true`
3. **Attendre 6 minutes sans activité**
4. **Exécuter manuellement** (si pas de cron) :
   ```sql
   SELECT scanio_cleanup_stale_presence();
   ```
5. **Vérifier** : `is_online = false`

#### Test 4 : Realtime

1. **Ouvrir l'app sur 2 appareils**
2. **Se connecter avec le compte A sur l'appareil 1**
3. **Ouvrir le profil du compte A sur l'appareil 2**
4. **Vérifier** : Le statut se met à jour en temps réel (< 1 seconde)

---

## 🐛 Dépannage

### Problème : La table n'est pas créée

**Erreur** :
```
ERROR: relation "scanio_user_presence" does not exist
```

**Solution** :
1. Vérifier que le script SQL a bien été exécuté
2. Vérifier qu'il n'y a pas d'erreurs dans les logs
3. Réexécuter le script `supabase_user_presence_schema.sql`

---

### Problème : Les fonctions n'existent pas

**Erreur** :
```
ERROR: function scanio_update_user_presence() does not exist
```

**Solution** :
1. Vérifier que le script SQL a créé les fonctions :
   ```sql
   SELECT routine_name 
   FROM information_schema.routines 
   WHERE routine_name LIKE 'scanio_%presence%';
   ```
2. Si aucune fonction n'apparaît, réexécuter le script

---

### Problème : Realtime ne fonctionne pas

**Symptôme** : Les mises à jour ne se propagent pas en temps réel

**Solution** :
1. Vérifier que Realtime est activé :
   ```sql
   SELECT * FROM pg_publication_tables 
   WHERE pubname = 'supabase_realtime' 
     AND tablename = 'scanio_user_presence';
   ```
2. Si aucun résultat, exécuter :
   ```sql
   ALTER PUBLICATION supabase_realtime ADD TABLE scanio_user_presence;
   ```

---

### Problème : RLS bloque les requêtes

**Erreur** :
```
ERROR: new row violates row-level security policy
```

**Solution** :
1. Vérifier que l'utilisateur est authentifié
2. Vérifier les RLS policies :
   ```sql
   SELECT * FROM pg_policies 
   WHERE tablename = 'scanio_user_presence';
   ```
3. Si nécessaire, recréer les policies (dans le script SQL)

---

### Problème : Le cleanup ne fonctionne pas

**Symptôme** : Les utilisateurs restent "en ligne" indéfiniment

**Solution** :
1. Vérifier que le cron job existe :
   ```sql
   SELECT * FROM cron.job WHERE jobname = 'cleanup-stale-presence';
   ```
2. Si pas de cron, exécuter manuellement :
   ```sql
   SELECT scanio_cleanup_stale_presence();
   ```
3. Ou utiliser l'option client-side (déjà implémentée)

---

## 📊 Vérification Post-Déploiement

### Checklist

- [ ] Table `scanio_user_presence` créée
- [ ] 4 fonctions SQL créées
- [ ] RLS policies activées
- [ ] Realtime activé
- [ ] Cleanup configuré (au moins une option)
- [ ] Test connexion/déconnexion réussi
- [ ] Test affichage du statut réussi
- [ ] Test cleanup réussi (si configuré)
- [ ] Test Realtime réussi

### Requêtes de Vérification

```sql
-- 1. Vérifier la table
SELECT COUNT(*) FROM scanio_user_presence;

-- 2. Vérifier les fonctions
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_name LIKE 'scanio_%presence%'
ORDER BY routine_name;

-- 3. Vérifier les RLS policies
SELECT policyname, cmd, qual 
FROM pg_policies 
WHERE tablename = 'scanio_user_presence';

-- 4. Vérifier Realtime
SELECT * FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' 
  AND tablename = 'scanio_user_presence';

-- 5. Vérifier les utilisateurs en ligne
SELECT 
    user_id,
    is_online,
    last_seen,
    updated_at,
    NOW() - updated_at as inactive_duration
FROM scanio_user_presence
WHERE is_online = true
ORDER BY updated_at DESC;
```

---

## 🎯 Prochaines Étapes

Une fois le système déployé et testé :

1. **Monitorer l'utilisation**
   - Vérifier le nombre d'utilisateurs en ligne
   - Vérifier la fréquence des mises à jour
   - Vérifier les performances

2. **Optimiser si nécessaire**
   - Ajuster l'intervalle de cleanup (5 min par défaut)
   - Ajuster l'intervalle de `keepPresenceAlive()` (3 min par défaut)

3. **Implémenter les fonctionnalités futures**
   - Chat en temps réel
   - Liste d'amis
   - Indicateurs dans les commentaires

Voir [`FUTURE_FEATURES.md`](FUTURE_FEATURES.md) pour les détails.

---

## 📞 Support

En cas de problème :
1. Vérifier les logs Supabase (Dashboard → Logs)
2. Vérifier les logs de l'app (Xcode Console)
3. Consulter la documentation Supabase : [https://supabase.com/docs](https://supabase.com/docs)

---

**Dernière mise à jour** : 2025-11-07  
**Version** : 1.0

