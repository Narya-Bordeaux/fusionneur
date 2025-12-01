# Principes généraux

**Avant de commencer à coder, toute question donne lieu à un échange** pour s'assurer d'une bonne compréhension conceptuelle de la question (quel est le but, que veut-on éviter, quel rendu est attendu pour les utilisateurs).

**Le code sera factorisé**, à la fois pour assurer l'uniformité des comportements et pour distinguer clairement services et interfaces.

**Toute règle est faite pour être enfreinte quand c'est absolument pertinent**, mais il faut que ce soit absolument pertinent.
&
---

# Architecture

## Organisation des features

`features/` comprend les différents modules du programme.

Chacune est gérée via un dossier contenant une page principale :
- `feature home` => `homepage`
- `feature settings` => `settingspage`

Ces pages sont avant tout des interfaces visuelles qui présentent différents widgets qui appellent différents services.

### Structure des features

```
features/
├── home/
│   ├── homepage.dart              # Page principale
│   ├── screens/                   # Pages secondaires du module
│   ├── widgets/                   # Widgets spécifiques au module
│   └── services/                  # Services spécifiques au module
```

### Règles de placement

#### Services et widgets locaux au module
Créés sous le dossier de la page dans `widgets/` ou `services/` quand :
- Utilisés dans **1 seule feature**
- Logique très spécifique au métier de cette feature

#### Services et widgets partagés (`shared/`)
Créés sous `shared/services/` ou `shared/widgets/` quand :
- Utilisés dans **2+ features** OU
- Service technique générique (stockage, cache, réseau, validation) OU
- Widget réutilisable (composant UI, widget métier)

**En cas de doute** : Commencer en local, déplacer vers `shared/` au 2e usage.

### Classification des widgets

#### Widgets locaux (`features/[module]/widgets/`)
Widgets spécifiques à une seule page ou feature.

**Exemples** : `HomeHeaderWidget`, `SettingsListTile`

#### Widgets UI partagés (`shared/widgets/ui/`)
Composants génériques du design system.

**Exemples** : `AppIcon`, `PrimaryButton`, `CustomCard`

#### Widgets métier partagés (`shared/widgets/`)
Widgets réutilisables mais liés au métier de l'application.

**Exemples** : `QrCodeDisplay`, `DesignOptionPicker`, `GroupCard`

---

# Langage

## Noms de code
Les noms de méthodes, variables, symboles sont **en anglais**.

```dart
// ✅ Correct
Future<void> saveImage(String id, Uint8List bytes) async { ... }
final imagesPath = await getImagesPath();

// ❌ Incorrect
Future<void> sauvegarderImage(String id, Uint8List octets) async { ... }
```

## Commentaires
**Tous les commentaires sont en français** (commentaires de documentation `///` et commentaires inline `//`).

**Exception** : Termes techniques courants ou établis restent en anglais.

### Termes acceptés en anglais dans les commentaires
- **Termes techniques** : HTTP, JSON, API, URL, hash, seed, cache
- **Termes métier établis** : QRC, Hive, Firebase, Storage, Firestore
- **Sigles** : PDF, PNG, SHA-256, UTF-8

```dart
// ✅ Correct
/// Sauvegarde une image dans le cache local ou Firebase Storage.
/// Utilise un hash SHA-256 comme identifiant unique.
Future<void> saveImage(String id, Uint8List bytes) async {
  // Upload vers Firebase Storage pour les utilisateurs Pro
  final ref = storage.ref().child('images/$id.png');
}

// ❌ Incorrect
/// Save an image in local cache or Firebase Storage
Future<void> saveImage(String id, Uint8List bytes) async {
  // Uploade vers Firebase Storage pour les users Pro
}
```

## Textes utilisateur (ARB)

Les textes affichés à l'utilisateur sont gérés via des fichiers ARB (Application Resource Bundle).

### Structure d'une clé ARB

```json
"keyName": "Texte affiché",
"@keyName": {
  "description": "Description du contexte d'usage",
  "context": "nom_de_la_page_ou_générique",
  "needTranslation": true
}
```

### Règles pour les clés ARB

#### Nom de la clé
- **En anglais** et **explicite**
- Doit être auto-descriptif du contenu

**Exemples** :
```json
"removeOrphanedDesignOptions": "Supprimer les orphelins"
"createNewGroup": "Créer un nouveau groupe"
"exportAsPdf": "Exporter en PDF"
```

#### Champ `description`
**Optionnel** si la clé anglaise est suffisamment explicite.

```json
// ✅ Description optionnelle (clé auto-descriptive)
"removeOrphanedDesignOptions": "Supprimer les orphelins",
"@removeOrphanedDesignOptions": {
  "context": "design_option_picker_grid"
}

// ✅ Description nécessaire (contexte non évident)
"seedEmpty": "Aucune donnée",
"@seedEmpty": {
  "description": "Message affiché quand la base de données de démonstration est vide",
  "context": "seed_editor"
}
```

#### Champ `context`
**Obligatoire**. Indique où la clé est utilisée.

- Nom de la page pour les clés spécifiques : `"design_option_picker_grid"`, `"home_page"`
- `"générique"` pour les termes réutilisables partout

#### Champ `needTranslation`
**Temporaire**. Indique que la traduction est en attente.

```json
"myNewKey": "Mon nouveau texte",
"@myNewKey": {
  "context": "settings_page",
  "needTranslation": true  // ← À supprimer une fois traduit
}
```

### Clés génériques

Pour les termes récurrents, utiliser le contexte `"générique"` :

```json
"create": "Créer",
"@create": { "context": "générique" },

"delete": "Supprimer",
"@delete": { "context": "générique" },

"cancel": "Annuler",
"@cancel": { "context": "générique" },

"save": "Enregistrer",
"@save": { "context": "générique" }
```

**Si une expression générique pertinente existe, l'utiliser** plutôt que de créer une nouvelle clé.

---

# Composants standards

## AppIcon

`lib/shared/widgets/ui/app_icon.dart` permet d'homogénéiser les icônes dans l'application.

**Toujours l'utiliser** au lieu d'utiliser directement `Icons.*` de Material.

### Usage recommandé

```dart
// ✅ Usage standard
AppIcon(glyph: AppGlyph.settings, color: currentFontColor)

// ✅ Si vous avez besoin de l'IconData brut
final data = AppIcon.data(AppGlyph.settings);

// ❌ À éviter
Icon(Icons.settings, color: currentFontColor)
```

---

# Exceptions aux règles

## Quand déroger à l'architecture

### ❌ Jamais acceptable
- Pour gagner du temps sur un "quick fix"
- Par flemme de créer un nouveau fichier
- "Juste pour tester, je refactorise plus tard" (sans ticket de suivi)

### ✅ Acceptable si absolument pertinent
- Une dépendance externe impose une structure différente
- Un prototype jetable de validation de concept (clairement identifié)
- Une contrainte technique forte rend l'architecture standard impossible

**Règle d'or** : Toute exception doit être **justifiée et documentée** (commentaire ou issue GitHub).

## Quand mélanger anglais/français

### ✅ Acceptable dans les commentaires
```dart
// Upload des fichiers vers le bucket S3
// Utilise un hash SHA-256 pour éviter les doublons
```

### ❌ Jamais acceptable
```dart
// Franglais inventé
final createurService = CreatorService();
final deleteurHelper = DeleteHelper();
```

---

# Tests et documentation

## Tests

### Services critiques
Les services dans `shared/services/` doivent avoir des tests unitaires.

**Exemples de services à tester** :
- `StorageResolver`
- `HiveService`
- `QrcReader` / `QrcWriter`
- Services de validation

### Features
Tests d'intégration pour les flows critiques.

**Exemples** :
- Création de QRC
- Export PDF
- Authentification (MAJ 2)

## Documentation

### Services complexes
Créer un README dédié dans le dossier du service.

**Exemples** :
- `shared/services/storage/README_storage.md`
- `shared/services/qrc/README_qrc_format.md`

### Documentation du projet
Centraliser la documentation dans `docs/` :
- `README_architecture.md` : Architecture globale
- `README_migration.md` : Migrations de données
- `README_maj.md` : Plan de mises à jour
- `README_instructions.md` : Ce fichier

---

📘 **Document** : README_instructions.md
📅 **Version** : 2025-10-25
✍️ **Auteur** : Narya / Olivier Claverie
