[English](README.md) | [简体中文](README.zhHans.md) | [繁体中文](README.zhHant.md) | [繁体中文（香港）](README.zhHantHK.md) | [Français](README.fr.md)

# lansenger-skills-official

Skills pour Agent IA Lansenger CLI — documents Markdown structurés pour CLI Python, Go et TypeScript, couvrant la messagerie, les calendriers, les groupes, les contacts, les départements, les todos, le streaming, les callbacks, OAuth et plus encore.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Qu'est-ce que les Skills ?

Les Skills sont des documents Markdown structurés qui enseignent aux Agents IA comment utiliser le CLI `lansenger`. Chaque Skill couvre un domaine métier (messagerie, calendrier, groupes, etc.) avec :

- **Concepts fondamentaux** et terminologie
- **Référence des commandes CLI** avec paramètres et exemples
- **Contraintes CRITIQUES** pour éviter les erreurs de l'Agent
- **Tableau des erreurs courantes**
- **Documentation détaillée** pour les opérations complexes

## Installation rapide

### Méthode 1 — `npx skills` (Recommandée)

La méthode la plus rapide. Compatible avec **OpenCode**, **Claude Code**, **Cursor**, **Codex**, **Cline** et [50+ autres agents](https://github.com/vercel-labs/skills#supported-agents).

```bash
# Installer tous les Skills sur tous les agents détectés (interactif)
npx skills add lansenger-pm/lansenger-skills-official

# Installer sur un agent spécifique (ex. opencode)
npx skills add lansenger-pm/lansenger-skills-official -a opencode

# Installer sur Claude Code globalement
npx skills add lansenger-pm/lansenger-skills-official -a claude-code -g

# Installer sur plusieurs agents
npx skills add lansenger-pm/lansenger-skills-official -a opencode -a claude-code -a cursor

# Installer uniquement certains Skills
npx skills add lansenger-pm/lansenger-skills-official --skill lansenger-messaging --skill lansenger-calendar

# Liste des Skills disponibles avant installation
npx skills add lansenger-pm/lansenger-skills-official --list

# Non-interactif / compatible CI
npx skills add lansenger-pm/lansenger-skills-official --all -y
```

### Méthode 2 — opencode `.opencode/skills/`

Pour les utilisateurs **opencode**, copiez ou liez symboliquement le répertoire `skills/` :

```bash
# Lien symbolique (recommandé — source unique, facile à mettre à jour)
ln -s $(pwd)/skills ~/.config/opencode/skills/lansenger-skills-official

# Ou copier
cp -r skills ~/.config/opencode/skills/lansenger-skills-official
```

### Méthode 3 — Claude Code `.claude/skills/`

```bash
# Lien symbolique dans le répertoire skills de Claude Code
ln -s $(pwd)/skills .claude/skills/lansenger-skills-official

# Installation globale
ln -s $(pwd)/skills ~/.claude/skills/lansenger-skills-official
```

### Méthode 4 — Manuel (Tout Agent)

Clonez ce dépôt et indiquez à votre Agent IA le répertoire `skills/` :

```bash
git clone https://github.com/lansenger-pm/lansenger-skills-official.git
# Indiquez ensuite à votre Agent IA de lire skill_manifest.json en premier,
# puis les fichiers SKILL.md pertinents selon les besoins de l'utilisateur.
```

### Méthode 5 — `.agents/skills/` (Chemin universel)

De nombreux agents (Amp, Cline, Codex, Cursor, Gemini CLI, etc.) utilisent `.agents/skills/` comme chemin standard :

```bash
ln -s $(pwd)/skills .agents/skills/lansenger-skills-official
```

## Mise à jour des Skills

```bash
# Si installé via npx skills
npx skills update lansenger-skills-official

# Si lien symbolique — simplement git pull
cd lansenger-skills-official && git pull
```

## Structure

```
skills/
  lansenger-shared/SKILL.md              # Règles partagées (auth, config, sécurité, erreurs)
  lansenger-messaging/SKILL.md           # Stratégie de messagerie + references/
  lansenger-chat/SKILL.md               # APIs de lecture des chats
  lansenger-group/SKILL.md              # Gestion des groupes
  lansenger-staff/SKILL.md              # Contacts & personnel
  lansenger-department/SKILL.md         # Hiérarchie des départements
  lansenger-calendar/SKILL.md           # Calendrier & planifications + references/
  lansenger-todo/SKILL.md               # Todo unifié
  lansenger-oauth/SKILL.md              # Authentification utilisateur OAuth2
  lansenger-streaming/SKILL.md          # Messages streaming (SSE Agent IA)
  lansenger-callback/SKILL.md           # Événements callback & webhook
  lansenger-media/SKILL.md              # Upload/download de fichiers médias
skill_manifest.json                      # Index de tous les skills
skill-template/                          # Templates pour créer de nouveaux skills
```

## Index des Skills

| Skill | Description |
|-------|-------------|
| `lansenger-shared` | Auth, config, gestion des erreurs, règles de sécurité (auto-chargé par tous les autres) |
| `lansenger-messaging` | 4 canaux de messagerie, matrice des types de messages, règles @mention, rappels, sélection des méthodes CLI |
| `lansenger-chat` | Récupérer la liste des chats (privés + groupes) et extraire les messages ; `--split-month`, `--progress`, assistant SDK `plain_text()` |
| `lansenger-group` | Créer des groupes, récupérer info/membres, lister les groupes, vérifier l'appartenance, modifier les paramètres, dissoudre des groupes |
| `lansenger-staff` | Récupérer les infos du personnel, mapping d'ID (téléphone/email→staffId), champs org supplémentaires, recherche |
| `lansenger-department` | Naviguer la hiérarchie org, récupérer détail/enfants de département, lister le personnel d'un département |
| `lansenger-calendar` | Calendrier principal, CRUD de planifications, gestion des participants, métadonnées des participants |
| `lansenger-todo` | Créer, mettre à jour, interroger, supprimer des tâches todo, gérer les exécutants, compter les statuts |
| `lansenger-oauth` | Flux d'authentification utilisateur OAuth2, URL d'autorisation, échange de code, renouvellement de token, commande `local-callback`, auto-refresh UserTokenManager |
| `lansenger-streaming` | Diffusion de messages en temps réel via SSE pour les Agents IA |
| `lansenger-callback` | 25 types d'événements, parsing structuré, décryptage AES, vérification de signature |
| `lansenger-media` | Upload/download de fichiers, images, vidéos, audio, récupérer le chemin média |

## Compatibilité CLI

**Recommandé** : Python SDK et CLI. Go et TypeScript comme alternatives.

```bash
# CLI Python (Recommandé)
pip install lansenger-cli
pip install lansenger-sdk  # pour l'usage programmatique
lansenger message send-text staff123 "Hello"

# CLI Go (Alternative)
go install github.com/lansenger-pm/lansenger-sdk-go/cmd/lansenger@latest
lansenger message send-text staff123 "Hello"

# CLI TypeScript (Alternative)
npm install -g lansenger-cli
lansenger message send-text staff123 "Hello"
```

Les trois CLIs partageant la même structure de commandes, les mêmes noms de paramètres et les mêmes formats de sortie, un seul ensemble de Skills les couvre tous. Requiert Python SDK v1.5+ et CLI v0.10+.

## Configuration Multi-App / Multi-Bot

Le CLI supporte plusieurs profils ( chaque profil correspondant à un appID). Les identifiants sont isolés par profil et stockés dans `~/.lansenger/sdk_state.json` (permissions 0600). Voir `lansenger-shared/SKILL.md` pour plus de détails :

### Champs d'identifiants

| Champ | Obligatoire ? | Quand nécessaire | Variable d'environnement |
|-------|---------------|------------------|--------------------------|
| `app_id` | **Obligatoire** | Tous les appels API | `LANSENGER_APP_ID` |
| `app_secret` | **Obligatoire** | Tous les appels API | `LANSENGER_APP_SECRET` |
| `api_gateway_url` | **Obligatoire** | URL de la passerelle API (modifier pour déploiement privé) | `LANSENGER_API_GATEWAY_URL` |
| `passport_url` | OAuth2 | Page d'autorisation OAuth2 (modifier pour déploiement privé) | `LANSENGER_PASSPORT_URL` |
| `redirect_uri` | OAuth2 | URL de rappel OAuth2 (doit être configuré dans la console Lansenger comme domaine de confiance, inclure le protocole et le port ; CLI par défaut http://localhost:8765 nécessite aussi config, ~10min de cache) | `LANSENGER_REDIRECT_URI` |
| `encoding_key` | Callbacks | Clé AES de décryptage des callbacks (Base64) | `LANSENGER_ENCODING_KEY` |
| `callback_token` | Callbacks | Token de vérification de signature (fallback vers encoding_key) | `LANSENGER_CALLBACK_TOKEN` |

```bash
# Identifiants de base (tous les utilisateurs)
lansenger config set app_id YOUR_APP_ID
lansenger config set app_secret YOUR_APP_SECRET
# api_gateway_url defaults to Lansenger public cloud; private deployment requires manual setup
# lansenger config set api_gateway_url YOUR_PRIVATE_GATEWAY_URL

# Authentification utilisateur OAuth2 (private deployment requires manual setup)
# lansenger config set passport_url YOUR_PRIVATE_PASSPORT_URL

# Réception de callbacks (décryptage et vérification de signature)
lansenger config set encoding_key YOUR_ENCODING_KEY
lansenger config set callback_token YOUR_CALLBACK_TOKEN

# Configurer plusieurs applications par profil
lansenger config set app_id xxx1 --profile "my-bot"
lansenger config set app_id xxx2 --profile "my-app"
lansenger config set encoding_key yyy2 --profile "my-app"

# Changer d'identité via --profile
lansenger message send-text staff123 "Hello" --profile "my-bot"
lansenger callback parse-payload DATA --profile "my-app"
```

## Contribuer

Consultez le répertoire `skill-template/` pour les templates lors de la création de nouveaux Skills.

## Licence

MIT