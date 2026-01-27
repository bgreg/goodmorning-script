#!/usr/bin/env zsh

###############################################################################
# Country of the Day Section
#
# Displays country information using REST Countries API
# Fetches all country names, selects one based on day of year, then fetches details
###############################################################################

register_section "country_of_day" --tools "curl" "jq" --network

get_country_of_day() {
  local all_names
  local attempt

  for attempt in 1 2; do
    all_names=$(fetch_url "https://restcountries.com/v3.1/all?fields=name" $((attempt * 4)))
    [[ -n "$all_names" ]] && break
    sleep $((RANDOM % 2 + 1))
  done

  require_non_empty "$all_names" || return 1

  local response_type=$(printf '%s\n' "$all_names" | jq -r 'type' 2>> "$LOG_FILE")
  [[ "$response_type" != "array" ]] && return 1

  local count=$(printf '%s\n' "$all_names" | jq 'length' 2>> "$LOG_FILE")
  [[ -z "$count" || "$count" -eq 0 ]] && return 1

  local day_of_year=$(date +%j | sed 's/^0*//')
  local index=$((day_of_year % count))
  local country_name=$(printf '%s\n' "$all_names" | jq -r ".[$index].name.common" 2>> "$LOG_FILE")
  require_non_empty "$country_name" || return 1

  local encoded_name="${country_name// /%20}"
  local country_data

  for attempt in 1 2; do
    country_data=$(fetch_url "https://restcountries.com/v3.1/name/${encoded_name}?fullText=true" $((attempt * 4)))
    [[ -n "$country_data" ]] && break
    sleep $((RANDOM % 2 + 1))
  done

  require_non_empty "$country_data" || return 1

  local detail_type=$(printf '%s\n' "$country_data" | jq -r 'type' 2>> "$LOG_FILE")
  [[ "$detail_type" != "array" ]] && return 1

  printf '%s\n' "$country_data" | jq '.[0]' 2>> "$LOG_FILE"
}

show_country_of_day() {
  print_section "Country of the Day" "cyan"

  local country_data=$(fetch_with_spinner "Fetching country..." get_country_of_day)

  if [ -z "$country_data" ]; then
    show_setup_message "$(echo_yellow '  ⚠ Could not fetch country information')"
    return 0
  fi

  local name=$(jq_extract "$country_data" '.name.common')
  local official_name=$(jq_extract "$country_data" '.name.official')
  local capital=$(printf '%s' "$country_data" | jq -r '.capital[0]? // "N/A"' 2>> "$LOG_FILE")
  local region=$(jq_extract "$country_data" '.region')
  local subregion=$(printf '%s' "$country_data" | jq -r '.subregion // "N/A"' 2>> "$LOG_FILE")
  local population=$(jq_extract "$country_data" '.population')
  local area=$(jq_extract "$country_data" '.area')
  local flag=$(jq_extract "$country_data" '.flag')

  local lang_jq='.languages // {} | to_entries | .[].value'
  local languages=$(printf '%s' "$country_data" | jq -r "$lang_jq" 2>> "$LOG_FILE" | tr '\n' ', ' | sed 's/,$//')
  local curr_jq='.currencies // {} | to_entries | .[].value.name'
  local currencies=$(printf '%s' "$country_data" | jq -r "$curr_jq" 2>> "$LOG_FILE" | tr '\n' ', ' | sed 's/,$//')

  show_new_line
  echo_cyan "  $flag  $name"
  echo_gray "  Official: $official_name"
  show_new_line
  echo "  🏛️  Capital: $(echo_green "$capital")"
  echo "  🌍 Region: $region ($subregion)"
  echo "  👥 Population: $(printf "%'d" "$population" 2>> "$LOG_FILE" || echo "$population")"
  echo "  📏 Area: $(printf "%'d" "${area%.*}" 2>> "$LOG_FILE" || echo "$area") km²"

  if [ -n "$languages" ]; then
    echo "  🗣️  Languages: $languages"
  fi

  if [ -n "$currencies" ]; then
    echo "  💰 Currency: $currencies"
  fi

  show_new_line
}
