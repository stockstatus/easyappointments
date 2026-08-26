# ═══════════════════════════════════════════════════════════
# ⚠  TENTO DOCKERFILE SA NA NASADZOVANIE NEPOUŽÍVA  ⚠
#
# Produkčný image sa stavia z Dockerfile.overrides. Ten berie ako
# základ už odladený image z ghcr a prekrýva v ňom len konkrétne
# súbory — nesťahuje nič z upstreamu.
#
# Prečo: alextselegidis/easyappointments:latest má vo variante
# linux/amd64 načítané dva Apache MPM moduly naraz. Apache s ním
# vôbec neštartuje a padá na:
#
#     apache2: Configuration error: More than one MPM loaded
#
# Overené 26. 8. 2026 — build z tohto súboru zhodil produkciu
# a musel sa vracať rollback tag. Pozor, chyba je len v amd64;
# arm64 variant (lokálny vývoj na Apple Silicon) beží v poriadku,
# takže sa to lokálnym testom nechytí. Testuj vždy s
# --platform linux/amd64.
#
# Zmysel tohto súboru: dokumentuje, ako sa základný custom image
# postavil od nuly (kompilácia SCSS témy). Dockerfile.overrides to
# nenahrádza — len naň nadväzuje. Ak bude raz treba prestavať
# základ, vyjde sa odtiaľto a najprv sa musí vyriešiť ten MPM
# konflikt, pravdepodobne cez:
#
#     RUN a2dismod mpm_event && a2enmod mpm_prefork
#
# ═══════════════════════════════════════════════════════════
# Masáže Karin — Custom EasyAppointments Image
# Stage 1: Skompiluje SCSS (karin téma + backend layout)
# Stage 2: Skopíruje CSS do oficiálneho EA image
# ═══════════════════════════════════════════════════════════

# Stage 1: Build SCSS
FROM node:18-alpine AS css-builder

WORKDIR /build

# Nainštaluj závislosti (potrebné pre Bootstrap SCSS)
COPY package*.json ./
RUN npm ci

# Skopíruj len to čo treba na kompiláciu
COPY gulpfile.js ./
COPY assets/css ./assets/css

# Skompiluj SCSS → CSS
RUN npx gulp styles

# ═══════════════════════════════════════════════════════════

# Stage 2: Produkčný image
FROM alextselegidis/easyappointments:latest

# Nahraď skompilované CSS súbory custom verziou
COPY --from=css-builder /build/assets/css /var/www/html/assets/css

# Custom hlavička (salon názov namiesto EA brandingu)
COPY application/views/components/backend_header.php /var/www/html/application/views/components/backend_header.php

# ── Vlastné úpravy ─────────────────────────────────────────
# Rovnaká sada ako v Dockerfile.overrides. Pri zmene uprav OBA súbory,
# inak sa prípadný build od nuly bude správať inak než produkcia.

# E-mailová konfigurácia čítaná z env premenných (MAIL_*).
# Nezávislá od toho, či base image generuje email.php cez entrypoint.
COPY application/config/email.php /var/www/html/application/config/email.php

# Ochranná pauza medzi rezerváciami (APPOINTMENT_PADDING_MINUTES).
COPY application/libraries/Availability.php /var/www/html/application/libraries/Availability.php

# Potvrdzovací e-mail: zákazníčke telefón na zrušenie namiesto odkazu,
# ktorým sa rezervácia zrušiť nedá. Personál si odkaz ponecháva.
COPY application/views/emails/appointment_saved_email.php /var/www/html/application/views/emails/appointment_saved_email.php
COPY application/language/czech/translations_lang.php /var/www/html/application/language/czech/translations_lang.php
