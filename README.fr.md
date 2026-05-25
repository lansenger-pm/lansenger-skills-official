[English](README.md) | [简体中文](README.zhHans.md) | [繁体中文](README.zhHant.md) | [繁体中文（香港）](README.zhHantHK.md) | [Français](README.fr.md)

# lansenger-skills-official

Skills pour Agent IA Lansenger CLI — documents Markdown structurés pour CLI Python et Go, couvrant la messagerie, les calendriers, les groupes, les contacts, les départements, les todos, le streaming, les callbacks, OAuth et plus encore.

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
skill_manifest.json                      # Index de tous les skills
skill-template/                          # Templates pour créer de nouveaux skills
```

## Index des Skills

| Skill | Description |
|-------|-------------|
| `lansenger-shared` | Auth, config, gestion des erreurs, règles de sécurité (auto-chargé par tous les autres) |
| `lansenger-messaging` | 4 canaux de messagerie, matrice des types de messages, règles @mention, sélection des méthodes CLI |
| `lansenger-chat` | Récupérer la liste des chats (privés + groupes) et extraire les messages des conversations |
| `lansenger-group` | Créer des groupes, récupérer info/membres, lister les groupes, vérifier l'appartenance, modifier les paramètres |
| `lansenger-staff` | Récupérer les infos du personnel, mapping d'ID (téléphone/email→staffId), champs org supplémentaires, recherche |
| `lansenger-department` | Naviguer la hiérarchie org, récupérer détail/enfants de département, lister le personnel d'un département |
| `lansenger-calendar` | Calendrier principal, CRUD de planifications, gestion des participants |
| `lansenger-todo` | Créer, mettre à jour, interroger, supprimer des tâches todo, gérer les exécutants, compter les statuts |
| `lansenger-oauth` | Flux d'authentification utilisateur OAuth2, URL d'autorisation, échange de code, renouvellement de token |
| `lansenger-streaming` | Diffusion de messages en temps réel via SSE pour les Agents IA |
| `lansenger-callback` | 25 types d'événements, parsing structuré, décryptage AES, vérification de signature |

## Compatibilité CLI

Ces Skills sont compatibles avec le CLI Python et le CLI Go :

```bash
# CLI Python
pip install lansenger-cli
lansenger message send-text staff123 "Hello"

# CLI Go
go install github.com/lansenger-pm/lansenger-sdk-go/cmd/lansenger@latest
lansenger message send-text staff123 "Hello"
```

Les deux CLIs partageant la même structure de commandes, les mêmes noms de paramètres et les mêmes formats de sortie, un seul ensemble de Skills les couvre tous.

## Configuration Multi-App / Multi-Bot

Le CLI supporte plusieurs profils (chaque profil correspondant à un appID). Les credentials sont isolés par appID. Voir `lansenger-shared/SKILL.md` pour plus de détails :

```bash
# Configurer plusieurs apps par nom de profil
lansenger config set --profile "my-personal-bot"
lansenger config set --profile "my-lansenger-app"

# Changer d'identité via --profile
lansenger message send-text staff123 "Hello" --profile "my-personal-bot"
lansenger calendar primary --profile "my-lansenger-app" --user-token "ut1"
```

## Contribuer

Consultez le répertoire `skill-template/` pour les templates lors de la création de nouveaux Skills.

## Licence

MIT