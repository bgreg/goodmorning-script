#!/usr/bin/env zsh

###############################################################################
# Country of the Day Section
#
# Displays random country information using REST Countries API
###############################################################################

# Section dependencies
SECTION_DEPS_TOOLS=(curl jq)
SECTION_DEPS_NETWORK=true

get_country_cache_file() {
  echo "${GOODMORNING_CONFIG_DIR}/cache/country_of_day.json"
}

get_random_country() {
  local cache_file="$(get_country_cache_file)"

  # List of country codes for random selection
  local country_codes=(
    "usa" "canada" "mexico" "brazil" "argentina" "chile" "peru" "colombia"
    "uk" "france" "germany" "spain" "italy" "netherlands" "belgium" "sweden"
    "norway" "denmark" "finland" "poland" "austria" "switzerland" "portugal"
    "japan" "china" "india" "australia" "newzealand" "southkorea" "thailand"
    "vietnam" "indonesia" "malaysia" "singapore" "philippines" "egypt" "morocco"
    "southafrica" "kenya" "nigeria" "ghana" "israel" "turkey" "greece" "ireland"
  )

  # Use day of year for daily rotation
  local day_of_year=$(date +%j | sed 's/^0*//')
  local index=$((day_of_year % ${#country_codes[@]}))
  local country_name="${country_codes[$index]}"

  local country_data=$(curl -s --max-time 10 "https://restcountries.com/v3.1/name/${country_name}?fullText=false" 2>/dev/null)

  if [ -z "$country_data" ]; then
    return 1
  fi

  # Extract first result and validate
  local single_country=$(printf '%s' "$country_data" | jq '.[0]' 2>/dev/null)
  local country_name_check=$(printf '%s' "$country_data" | jq -r '.[0].name.common // empty' 2>/dev/null)

  if [ -n "$country_name_check" ]; then
    mkdir -p "$(dirname "$cache_file")"
    print -r -- "$single_country"
    return 0
  fi

  return 1
}

show_country_of_day() {
  if [ -n "$GOODMORNING_FORCE_OFFLINE" ]; then
    return 0
  fi

  print_section "Country of the Day" "cyan"

  local country_data=$(fetch_with_spinner "Fetching country..." get_random_country)

  if [ -z "$country_data" ]; then
    show_setup_message "$(echo_yellow '  ⚠ Could not fetch country information')"
    return 0
  fi

  local name=$(printf '%s' "$country_data" | jq -r '.name.common' 2>/dev/null)
  local official_name=$(printf '%s' "$country_data" | jq -r '.name.official' 2>/dev/null)
  local capital=$(printf '%s' "$country_data" | jq -r '.capital[0]? // "N/A"' 2>/dev/null)
  local region=$(printf '%s' "$country_data" | jq -r '.region' 2>/dev/null)
  local subregion=$(printf '%s' "$country_data" | jq -r '.subregion // "N/A"' 2>/dev/null)
  local population=$(printf '%s' "$country_data" | jq -r '.population' 2>/dev/null)
  local area=$(printf '%s' "$country_data" | jq -r '.area' 2>/dev/null)
  local flag=$(printf '%s' "$country_data" | jq -r '.flag' 2>/dev/null)

  local languages=$(printf '%s' "$country_data" | jq -r '.languages // {} | to_entries | .[].value' 2>/dev/null | tr '\n' ', ' | sed 's/,$//')
  local currencies=$(printf '%s' "$country_data" | jq -r '.currencies // {} | to_entries | .[].value.name' 2>/dev/null | tr '\n' ', ' | sed 's/,$//')

  echo ""
  echo_cyan "  $flag  $name"
  echo_gray "  Official: $official_name"
  echo ""
  echo "  🏛️  Capital: $(echo_green "$capital")"
  echo "  🌍 Region: $region ($subregion)"
  echo "  👥 Population: $(printf "%'d" "$population" 2>/dev/null || echo "$population")"
  echo "  📏 Area: $(printf "%'d" "$area" 2>/dev/null || echo "$area") km²"

  if [ -n "$languages" ]; then
    echo "  🗣️  Languages: $languages"
  fi

  if [ -n "$currencies" ]; then
    echo "  💰 Currency: $currencies"
  fi

  echo ""
}
