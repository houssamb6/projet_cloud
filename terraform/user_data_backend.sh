#!/bin/bash
set -e   # Arrêter le script si une commande échoue

# ── Mise à jour du système et installation des outils ──
apt update -y
apt install -y git nodejs npm

# ── Cloner votre application ──
cd /home/ubuntu
git clone ${github_repo} app
cd app

# ── Installer les dépendances ──
npm install

# ── Injecter les variables d'environnement (jamais en dur dans le code !) ──
export DB_HOST="${db_host}"
export DB_NAME="${db_name}"
export DB_USER="${db_username}"
export DB_PASS="${db_password}"
export PORT="${app_port}"
export NODE_ENV="production"

# ── Écrire les variables dans un fichier .env pour la persistance ──
cat > /home/ubuntu/app/.env <<EOF
DB_HOST=${db_host}
DB_NAME=${db_name}
DB_USER=${db_username}
DB_PASS=${db_password}
PORT=${app_port}
NODE_ENV=production
EOF

# ── Démarrer l'application ──
npm start &

# ── (Optionnel) Installer PM2 pour une gestion plus robuste du processus ──
# npm install -g pm2
# pm2 start npm -- start
# pm2 startup && pm2 save