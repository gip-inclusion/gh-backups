# GitHub Backup

Ce projet contient un script en ruby pour sauvegarder l'historique git et les métadonnées de tous les dépôts d'une organisation GitHub vers un bucket S3.

## 📋 Description

Ce projet permet de sauvegarder automatiquement :

- **L'historique git complet** de chaque dépôt (clone mirror compressé en tar.gz)
- **Les métadonnées GitHub** : issues, pull requests, commentaires d'issues et commentaires de pull requests

Le script parcourt tous les dépôts **non archivés** et **non forkés** de l'organisation spécifiée et sauvegarde leurs données dans un bucket S3.

⚠️ Attention : pour exécuter le script via la CI, il faut que les repos en question soient public, autrement l'historique git ne pourra pas être récupéré via la CI.

## 🔧 Configuration

### Variables d'environnement requises

Pour lancer le script en local, créez un fichier `.env` à la racine du projet ou configurez les variables suivantes:

```bash
# Organisation GitHub à sauvegarder
GH_ORG_NAME=votre-organisation

# Token GitHub avec les permissions de lecture sur l'organisation
GH_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx

# Credentials S3
S3_ACCESS_KEY=votre-access-key
S3_SECRET_KEY=votre-secret-key
S3_REGION=fr-par
S3_ENDPOINT=https://....
S3_BUCKET_NAME=nom-de-votre-bucket
```

### Permissions GitHub requises

Les permissions dépendent du type de dépôts à sauvegarder :

#### Pour sauvegarder uniquement les dépôts publics :
- Aucune permission spéciale sur l'organisation n'est requise
- Un token personnel avec accès en lecture suffit

#### Pour sauvegarder les dépôts privés :
- Accès à la lecture des issues et pull requests des dépôts à sauvegarder.

#### ⚠️ Limitations importantes

Le script détecte automatiquement l'environnement CI et **ignore la sauvegarde git des dépôts privés** parce que l'authentification pour récupérer l'historique git des dépôts privés n'est pas gérée.

**Comportement :**
- ✅ **Dépôts publics** : Sauvegarde complète (Git + métadonnées)
- ⚠️ **Dépôts privés en CI** : Métadonnées uniquement
- ✅ **Dépôts privés en local** : Sauvegarde complète (si token autorisé)

### Configuration S3

1. Créez un bucket S3 chez votre provider
2. Générez des clés d'API avec les permissions pour faire des actions sur ce bucket
3. Notez l'endpoint de votre région (ex: `https://s3.fr-par.scw.cloud` pour Paris sur Scaleway)

## 🚀 Utilisation

### Exécution locale

#### Prérequis
- Un gestionnaire de versions ruby (rbenv ou rvm)
- Ruby (version définie dans `.ruby-version`)

#### Commandes

```bash
# 1. Installer rbenv (macOS avec Homebrew)
brew install rbenv

# 1. Ou installer rbenv (Linux)
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash

# 2. Installer la version Ruby requise
rbenv install  # lit automatiquement .ruby-version

# 3. Installation des dépendances
bundle install

# 4. Exécution du backup
bin/backup.rb
```

### Exécution automatisée via GitHub Actions

Le projet inclut un workflow GitHub Actions (`daily-backup.yml`) qui permet de lancer automatiquement le backup tous les jours à 2h00 UTC.

#### Configuration des secrets GitHub

Dans les paramètres de votre dépôt GitHub, ajoutez :

**Secrets :**
- `GH_TOKEN` : Token d'accès GitHub
- `S3_ACCESS_KEY` : Clé d'accès S3
- `S3_SECRET_KEY` : Clé secrète S3
- `NOTIFICATION_WEBHOOK_URL` (optionnel): Sert à envoyer les notifications sur un channel Slack ou Mattermost

**Variables :**
- `GH_ORG_NAME` : Nom de l'organisation GitHub
- `S3_BUCKET` : Nom du bucket S3
- `S3_REGION` : Région S3 (ex: `fr-par`)
- `S3_ENDPOINT` : Endpoint S3


## 🔄 Fonctionnalités

- **Backup incrémental** : Évite de re-sauvegarder des données inchangées
- **Gestion des erreurs** : Continue le processus même si la sauvegarde d'un dépôt échoue
- **Notifications** : Rapports de succès/échec via Slack ou autre messagerie si l'url est passé dans la variable d'env `NOTIFICATION_WEBHOOK_URL`
- **Retry automatique** : Nouvelle tentative en cas d'échec temporaire

## 🛠️ Architecture

### Classes principales

- `BackupRunner` : Orchestrateur principal
- `RepoGitBackup` : Gestion du backup Git
- `RepoMetadataBackup` : Gestion du backup des métadonnées
- `Config` : Configuration et clients API
- `Utils` : Utilitaires (retry, etc.)
- `Notifier` : Notifications Slack
