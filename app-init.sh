#!/bin/bash

color_green='\033[0;32m'
color_clear='\033[0m'

echo "1) rm -rf .env vendor composer.lock node_modules package-lock.json" && rm -rf .env vendor composer.lock node_modules package-lock.json \
    && echo "2) cp .env.example .env" && cp .env.example .env \
    && echo "3) docker-compose down -v" && ./ver down -v >/dev/null 2>&1 \
    && echo "4) docker-compose build" && ./ver build >/dev/null 2>&1 \
    && echo "5) docker-compose up -d" && ./ver start \
    && echo "6) composer install" && ./ver composer install >/dev/null 2>&1 \
    && echo "7) php artisan key:generate" && ./ver artisan key:generate >/dev/null 2>&1 \
    && echo "7) php artisan storage:link" && ./ver artisan storage:link >/dev/null 2>&1 \
    && echo "8) php artisan migrate:fresh --seed" && ./ver artisan migrate:fresh --seed \
    && echo "9) npm install" && ./ver npm install >/dev/null 2>&1 \
    && echo "10) npm run dev" && ./ver npm run dev >/dev/null 2>&1 \
    && echo -e "${color_green}Done. Now go to work!${color_clear}" \
    && source .env && echo "$APP_URL"
