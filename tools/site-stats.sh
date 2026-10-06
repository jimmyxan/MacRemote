#!/bin/bash
# Writes the lines of code (and the current stars and forks, as a no-JS fallback) into site/index.html.
# The site fetches live stars and forks from the GitHub API; lines of code only change here. Run it before publishing the site.
set -euo pipefail
cd "$(dirname "$0")/.."
count() { cat "$@" | grep -c '[^[:space:]]'; }   # non-blank lines
APP=$(count $(git ls-files '*.swift' '*.m' '*.sh'))
SITE=$(cd site && count $(git ls-files '*.html' '*.css' '*.js'))
read -r STARS FORKS < <(gh api repos/jimmyxan/MacRemote --jq '"\(.stargazers_count) \(.forks_count)"' 2>/dev/null || echo "")
sed -i '' -E \
  -e "s/(data-stat=\"loc\">)[0-9]*/\1$((APP + SITE))/" \
  -e "s/(data-stat=\"loc-app\">)[0-9]*/\1$APP/" \
  -e "s/(data-stat=\"loc-site\">)[0-9]*/\1$SITE/" \
  -e "s/(--app:)[0-9.]*%/\1$((APP * 100 / (APP + SITE)))%/" \
  ${STARS:+-e "s/(data-stat=\"stars\">)[0-9]*/\1$STARS/"} \
  ${FORKS:+-e "s/(data-stat=\"forks\">)[0-9]*/\1$FORKS/"} \
  site/index.html
echo "app $APP + site $SITE = $((APP + SITE)) lines; stars ${STARS:-?}, forks ${FORKS:-?}"
