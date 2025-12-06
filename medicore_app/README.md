# MediCore - Application de Gestion Médicale Ophtalmologique

Application de gestion de cabinet d'ophtalmologie développée avec Flutter.

## Fonctionnalités

- **Gestion des patients** - Dossiers patients complets avec historique
- **Consultations** - Saisie et suivi des visites médicales
- **Ordonnances** - Création d'ordonnances avec base de médicaments
- **Certificats & Bilans** - Génération de documents médicaux
- **Comptabilité** - Suivi des paiements et honoraires
- **Messagerie** - Communication entre salles
- **Impression PDF** - Export professionnel des documents

## Plateformes Supportées

- ✅ macOS
- ✅ Windows (7, 8, 10, 11 - 64-bit)
- 🔄 Linux (prévu)

## Installation Windows

Téléchargez la dernière version depuis [Releases](../../releases).

### Configuration Requise
- Windows 7 ou supérieur (64-bit)
- 4 GB RAM minimum
- 200 MB d'espace disque

## Développement

### Prérequis
- Flutter 3.32.4+
- Dart SDK

### Commandes

```bash
# Installer les dépendances
flutter pub get

# Lancer en mode développement
flutter run -d macos  # ou windows

# Construire pour Windows
flutter build windows --release

# Construire pour macOS
flutter build macos --release
```

## Architecture

- **Frontend**: Flutter avec Riverpod (state management)
- **Base de données locale**: Drift (SQLite)
- **Backend**: Go avec gRPC
- **Design**: Material Design personnalisé (MediCore Theme)

## Structure du Projet

```
medicore_app/
├── lib/
│   ├── src/
│   │   ├── core/           # Theme, database, utilities
│   │   └── features/       # Modules fonctionnels
│   └── main.dart
├── assets/                  # Images, logos, sons
├── installer/              # Scripts d'installation Windows
└── .github/workflows/      # CI/CD GitHub Actions
```

## Licence

Propriétaire - Thaziri Medical © 2024
