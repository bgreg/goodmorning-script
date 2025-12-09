#!/usr/bin/env zsh

###############################################################################
# Country of the Day Section
#
# Displays random country information using REST Countries API
###############################################################################

# Country codes for daily rotation (44 countries = ~6 week cycle)
COUNTRY_CODES=(
  "usa" "canada" "mexico" "brazil" "argentina" "chile" "peru" "colombia"
  "uk" "france" "germany" "spain" "italy" "netherlands" "belgium" "sweden"
  "norway" "denmark" "finland" "poland" "austria" "switzerland" "portugal"
  "japan" "china" "india" "australia" "newzealand" "southkorea" "thailand"
  "vietnam" "indonesia" "malaysia" "singapore" "philippines" "egypt" "morocco"
  "southafrica" "kenya" "nigeria" "ghana" "israel" "turkey" "greece" "ireland"
)

get_random_country() {
  local day_of_year=$(date +%j | sed 's/^0*//')
  local index=$((day_of_year % ${#COUNTRY_CODES[@]}))
  local country_name="${COUNTRY_CODES[$index]}"

  local country_data=$(fetch_url "https://restcountries.com/v3.1/name/${country_name}?fullText=false")

  require_non_empty "$country_data" || return 1
  require_non_empty "$(jq_extract "$country_data" '.[0].name.common')" || return 1

  printf '%s' "$country_data" | jq '.[0]' 2>/dev/null
  return 0
}

show_country_of_day() {
  print_section "Country of the Day" "cyan"

  local country_data=$(fetch_with_spinner "Fetching country..." get_random_country)

  if [ -z "$country_data" ]; then
    show_setup_message "$(echo_yellow '  ⚠ Could not fetch country information')"
    return 0
  fi

  local name=$(jq_extract "$country_data" '.name.common')
  local official_name=$(jq_extract "$country_data" '.name.official')
  local capital=$(printf '%s' "$country_data" | jq -r '.capital[0]? // "N/A"' 2>/dev/null)
  local region=$(jq_extract "$country_data" '.region')
  local subregion=$(printf '%s' "$country_data" | jq -r '.subregion // "N/A"' 2>/dev/null)
  local population=$(jq_extract "$country_data" '.population')
  local area=$(jq_extract "$country_data" '.area')
  local flag=$(jq_extract "$country_data" '.flag')

  local languages=$(printf '%s' "$country_data" | jq -r '.languages // {} | to_entries | .[].value' 2>/dev/null | tr '\n' ', ' | sed 's/,$//')
  local currencies=$(printf '%s' "$country_data" | jq -r '.currencies // {} | to_entries | .[].value.name' 2>/dev/null | tr '\n' ', ' | sed 's/,$//')

  show_new_line
  echo_cyan "  $flag  $name"
  echo_gray "  Official: $official_name"
  show_new_line
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

  show_new_line
}
