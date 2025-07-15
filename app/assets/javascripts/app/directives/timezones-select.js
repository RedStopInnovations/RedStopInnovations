(function() {
  var TIMEZONES =
  [
    {
      "name": "Pacific/Pago_Pago",
      "display_name": "American Samoa",
      "utc_offset": "-11:00",
      "abbr": "SST"
    },
    {
      "name": "Pacific/Midway",
      "display_name": "International Date Line West",
      "utc_offset": "-11:00",
      "abbr": "SST"
    },
    {
      "name": "Pacific/Midway",
      "display_name": "Midway Island",
      "utc_offset": "-11:00",
      "abbr": "SST"
    },
    {
      "name": "Pacific/Honolulu",
      "display_name": "Hawaii",
      "utc_offset": "-10:00",
      "abbr": "HST"
    },
    {
      "name": "America/Juneau",
      "display_name": "Alaska",
      "utc_offset": "-09:00",
      "abbr": "AKST"
    },
    {
      "name": "America/Los_Angeles",
      "display_name": "Pacific Time (US & Canada)",
      "utc_offset": "-08:00",
      "abbr": "PST"
    },
    {
      "name": "America/Tijuana",
      "display_name": "Tijuana",
      "utc_offset": "-08:00",
      "abbr": "PST"
    },
    {
      "name": "America/Phoenix",
      "display_name": "Arizona",
      "utc_offset": "-07:00",
      "abbr": "MST"
    },
    {
      "name": "America/Chihuahua",
      "display_name": "Chihuahua",
      "utc_offset": "-07:00",
      "abbr": "MST"
    },
    {
      "name": "America/Mazatlan",
      "display_name": "Mazatlan",
      "utc_offset": "-07:00",
      "abbr": "MST"
    },
    {
      "name": "America/Denver",
      "display_name": "Mountain Time (US & Canada)",
      "utc_offset": "-07:00",
      "abbr": "MST"
    },
    {
      "name": "America/Guatemala",
      "display_name": "Central America",
      "utc_offset": "-06:00",
      "abbr": "CST"
    },
    {
      "name": "America/Chicago",
      "display_name": "Central Time (US & Canada)",
      "utc_offset": "-06:00",
      "abbr": "CST"
    },
    {
      "name": "America/Mexico_City",
      "display_name": "Guadalajara",
      "utc_offset": "-06:00",
      "abbr": "CST"
    },
    {
      "name": "America/Mexico_City",
      "display_name": "Mexico City",
      "utc_offset": "-06:00",
      "abbr": "CST"
    },
    {
      "name": "America/Monterrey",
      "display_name": "Monterrey",
      "utc_offset": "-06:00",
      "abbr": "CST"
    },
    {
      "name": "America/Regina",
      "display_name": "Saskatchewan",
      "utc_offset": "-06:00",
      "abbr": "CST"
    },
    {
      "name": "America/Bogota",
      "display_name": "Bogota",
      "utc_offset": "-05:00",
      "abbr": "COT"
    },
    {
      "name": "America/New_York",
      "display_name": "Eastern Time (US & Canada)",
      "utc_offset": "-05:00",
      "abbr": "EST"
    },
    {
      "name": "America/Indiana/Indianapolis",
      "display_name": "Indiana (East)",
      "utc_offset": "-05:00",
      "abbr": "EST"
    },
    {
      "name": "America/Lima",
      "display_name": "Lima",
      "utc_offset": "-05:00",
      "abbr": "PET"
    },
    {
      "name": "America/Lima",
      "display_name": "Quito",
      "utc_offset": "-05:00",
      "abbr": "PET"
    },
    {
      "name": "America/Halifax",
      "display_name": "Atlantic Time (Canada)",
      "utc_offset": "-04:00",
      "abbr": "AST"
    },
    {
      "name": "America/Caracas",
      "display_name": "Caracas",
      "utc_offset": "-04:00",
      "abbr": "VET"
    },
    {
      "name": "America/Guyana",
      "display_name": "Georgetown",
      "utc_offset": "-04:00",
      "abbr": "GYT"
    },
    {
      "name": "America/La_Paz",
      "display_name": "La Paz",
      "utc_offset": "-04:00",
      "abbr": "BOT"
    },
    {
      "name": "America/Santiago",
      "display_name": "Santiago",
      "utc_offset": "-04:00",
      "abbr": "CLST"
    },
    {
      "name": "America/St_Johns",
      "display_name": "Newfoundland",
      "utc_offset": "-03:30",
      "abbr": "NST"
    },
    {
      "name": "America/Sao_Paulo",
      "display_name": "Brasilia",
      "utc_offset": "-03:00",
      "abbr": "BRST"
    },
    {
      "name": "America/Argentina/Buenos_Aires",
      "display_name": "Buenos Aires",
      "utc_offset": "-03:00",
      "abbr": "ART"
    },
    {
      "name": "America/Godthab",
      "display_name": "Greenland",
      "utc_offset": "-03:00",
      "abbr": "WGT"
    },
    {
      "name": "America/Montevideo",
      "display_name": "Montevideo",
      "utc_offset": "-03:00",
      "abbr": "UYT"
    },
    {
      "name": "Atlantic/South_Georgia",
      "display_name": "Mid-Atlantic",
      "utc_offset": "-02:00",
      "abbr": "GST"
    },
    {
      "name": "Atlantic/Azores",
      "display_name": "Azores",
      "utc_offset": "-01:00",
      "abbr": "AZOT"
    },
    {
      "name": "Atlantic/Cape_Verde",
      "display_name": "Cape Verde Is.",
      "utc_offset": "-01:00",
      "abbr": "CVT"
    },
    {
      "name": "Africa/Casablanca",
      "display_name": "Casablanca",
      "utc_offset": "+00:00",
      "abbr": "WET"
    },
    {
      "name": "Europe/Dublin",
      "display_name": "Dublin",
      "utc_offset": "+00:00",
      "abbr": "GMT"
    },
    {
      "name": "Europe/Lisbon",
      "display_name": "Lisbon",
      "utc_offset": "+00:00",
      "abbr": "WET"
    },
    {
      "name": "Europe/London",
      "display_name": "London",
      "utc_offset": "+00:00",
      "abbr": "GMT"
    },
    {
      "name": "Africa/Monrovia",
      "display_name": "Monrovia",
      "utc_offset": "+00:00",
      "abbr": "GMT"
    },
    {
      "name": "Etc/UTC",
      "display_name": "UTC",
      "utc_offset": "+00:00",
      "abbr": "UTC"
    },
    {
      "name": "Europe/Amsterdam",
      "display_name": "Amsterdam",
      "utc_offset": "+01:00",
      "abbr": "CET"
    },
    {
      "name": "Europe/Belgrade",
      "display_name": "Belgrade",
      "utc_offset": "+01:00",
      "abbr": "CET"
    },
    {
      "name": "Europe/Berlin",
      "display_name": "Berlin",
      "utc_offset": "+01:00",
      "abbr": "CET"
    },
    {
      "name": "Europe/Zurich",
      "display_name": "Bern",
      "utc_offset": "+01:00",
      "abbr": "CET"
    },
    {
      "name": "Europe/Bratislava",
      "display_name": "Bratislava",
      "utc_offset": "+01:00",
      "abbr": "CET"
    },
    {
      "name": "Europe/Brussels",
      "display_name": "Brussels",
      "utc_offset": "+01:00",
      "abbr": "CET"
    },
    {
      "name": "Europe/Budapest",
      "display_name": "Budapest",
      "utc_offset": "+01:00",
      "abbr": "CET"
    },
    {
      "name": "Europe/Copenhagen",
      "display_name": "Copenhagen",
      "utc_offset": "+01:00",
      "abbr": "CET"
    },
    {
      "name": "Europe/Ljubljana",
      "display_name": "Ljubljana",
      "utc_offset": "+01:00",
      "abbr": "CET"
    },
    {
      "name": "Europe/Madrid",
      "display_name": "Madrid",
      "utc_offset": "+01:00",
      "abbr": "CET"
    },
    {
      "name": "Europe/Paris",
      "display_name": "Paris",
      "utc_offset": "+01:00",
      "abbr": "CET"
    },
    {
      "name": "Europe/Prague",
      "display_name": "Prague",
      "utc_offset": "+01:00",
      "abbr": "CET"
    },
    {
      "name": "Europe/Rome",
      "display_name": "Rome",
      "utc_offset": "+01:00",
      "abbr": "CET"
    },
    {
      "name": "Europe/Sarajevo",
      "display_name": "Sarajevo",
      "utc_offset": "+01:00",
      "abbr": "CET"
    },
    {
      "name": "Europe/Skopje",
      "display_name": "Skopje",
      "utc_offset": "+01:00",
      "abbr": "CET"
    },
    {
      "name": "Europe/Stockholm",
      "display_name": "Stockholm",
      "utc_offset": "+01:00",
      "abbr": "CET"
    },
    {
      "name": "Europe/Vienna",
      "display_name": "Vienna",
      "utc_offset": "+01:00",
      "abbr": "CET"
    },
    {
      "name": "Europe/Warsaw",
      "display_name": "Warsaw",
      "utc_offset": "+01:00",
      "abbr": "CET"
    },
    {
      "name": "Africa/Algiers",
      "display_name": "West Central Africa",
      "utc_offset": "+01:00",
      "abbr": "CET"
    },
    {
      "name": "Europe/Zagreb",
      "display_name": "Zagreb",
      "utc_offset": "+01:00",
      "abbr": "CET"
    },
    {
      "name": "Europe/Zurich",
      "display_name": "Zurich",
      "utc_offset": "+01:00",
      "abbr": "CET"
    },
    {
      "name": "Europe/Athens",
      "display_name": "Athens",
      "utc_offset": "+02:00",
      "abbr": "EET"
    },
    {
      "name": "Europe/Bucharest",
      "display_name": "Bucharest",
      "utc_offset": "+02:00",
      "abbr": "EET"
    },
    {
      "name": "Africa/Cairo",
      "display_name": "Cairo",
      "utc_offset": "+02:00",
      "abbr": "EET"
    },
    {
      "name": "Africa/Harare",
      "display_name": "Harare",
      "utc_offset": "+02:00",
      "abbr": "CAT"
    },
    {
      "name": "Europe/Helsinki",
      "display_name": "Helsinki",
      "utc_offset": "+02:00",
      "abbr": "EET"
    },
    {
      "name": "Asia/Jerusalem",
      "display_name": "Jerusalem",
      "utc_offset": "+02:00",
      "abbr": "IST"
    },
    {
      "name": "Europe/Kaliningrad",
      "display_name": "Kaliningrad",
      "utc_offset": "+02:00",
      "abbr": "EET"
    },
    {
      "name": "Europe/Kiev",
      "display_name": "Kyiv",
      "utc_offset": "+02:00",
      "abbr": "EET"
    },
    {
      "name": "Africa/Johannesburg",
      "display_name": "Pretoria",
      "utc_offset": "+02:00",
      "abbr": "SAST"
    },
    {
      "name": "Europe/Riga",
      "display_name": "Riga",
      "utc_offset": "+02:00",
      "abbr": "EET"
    },
    {
      "name": "Europe/Sofia",
      "display_name": "Sofia",
      "utc_offset": "+02:00",
      "abbr": "EET"
    },
    {
      "name": "Europe/Tallinn",
      "display_name": "Tallinn",
      "utc_offset": "+02:00",
      "abbr": "EET"
    },
    {
      "name": "Europe/Vilnius",
      "display_name": "Vilnius",
      "utc_offset": "+02:00",
      "abbr": "EET"
    },
    {
      "name": "Asia/Baghdad",
      "display_name": "Baghdad",
      "utc_offset": "+03:00",
      "abbr": "AST"
    },
    {
      "name": "Europe/Istanbul",
      "display_name": "Istanbul",
      "utc_offset": "+03:00",
      "abbr": "+03"
    },
    {
      "name": "Asia/Kuwait",
      "display_name": "Kuwait",
      "utc_offset": "+03:00",
      "abbr": "AST"
    },
    {
      "name": "Europe/Minsk",
      "display_name": "Minsk",
      "utc_offset": "+03:00",
      "abbr": "+03"
    },
    {
      "name": "Europe/Moscow",
      "display_name": "Moscow",
      "utc_offset": "+03:00",
      "abbr": "MSK"
    },
    {
      "name": "Africa/Nairobi",
      "display_name": "Nairobi",
      "utc_offset": "+03:00",
      "abbr": "EAT"
    },
    {
      "name": "Asia/Riyadh",
      "display_name": "Riyadh",
      "utc_offset": "+03:00",
      "abbr": "AST"
    },
    {
      "name": "Europe/Moscow",
      "display_name": "St. Petersburg",
      "utc_offset": "+03:00",
      "abbr": "MSK"
    },
    {
      "name": "Europe/Volgograd",
      "display_name": "Volgograd",
      "utc_offset": "+03:00",
      "abbr": "+03"
    },
    {
      "name": "Asia/Tehran",
      "display_name": "Tehran",
      "utc_offset": "+03:30",
      "abbr": "IRST"
    },
    {
      "name": "Asia/Muscat",
      "display_name": "Abu Dhabi",
      "utc_offset": "+04:00",
      "abbr": "GST"
    },
    {
      "name": "Asia/Baku",
      "display_name": "Baku",
      "utc_offset": "+04:00",
      "abbr": "+04"
    },
    {
      "name": "Asia/Muscat",
      "display_name": "Muscat",
      "utc_offset": "+04:00",
      "abbr": "GST"
    },
    {
      "name": "Europe/Samara",
      "display_name": "Samara",
      "utc_offset": "+04:00",
      "abbr": "+04"
    },
    {
      "name": "Asia/Tbilisi",
      "display_name": "Tbilisi",
      "utc_offset": "+04:00",
      "abbr": "+04"
    },
    {
      "name": "Asia/Yerevan",
      "display_name": "Yerevan",
      "utc_offset": "+04:00",
      "abbr": "+04"
    },
    {
      "name": "Asia/Kabul",
      "display_name": "Kabul",
      "utc_offset": "+04:30",
      "abbr": "AFT"
    },
    {
      "name": "Asia/Yekaterinburg",
      "display_name": "Ekaterinburg",
      "utc_offset": "+05:00",
      "abbr": "+05"
    },
    {
      "name": "Asia/Karachi",
      "display_name": "Islamabad",
      "utc_offset": "+05:00",
      "abbr": "PKT"
    },
    {
      "name": "Asia/Karachi",
      "display_name": "Karachi",
      "utc_offset": "+05:00",
      "abbr": "PKT"
    },
    {
      "name": "Asia/Tashkent",
      "display_name": "Tashkent",
      "utc_offset": "+05:00",
      "abbr": "+05"
    },
    {
      "name": "Asia/Kolkata",
      "display_name": "Chennai",
      "utc_offset": "+05:30",
      "abbr": "IST"
    },
    {
      "name": "Asia/Kolkata",
      "display_name": "Kolkata",
      "utc_offset": "+05:30",
      "abbr": "IST"
    },
    {
      "name": "Asia/Kolkata",
      "display_name": "Mumbai",
      "utc_offset": "+05:30",
      "abbr": "IST"
    },
    {
      "name": "Asia/Kolkata",
      "display_name": "New Delhi",
      "utc_offset": "+05:30",
      "abbr": "IST"
    },
    {
      "name": "Asia/Colombo",
      "display_name": "Sri Jayawardenepura",
      "utc_offset": "+05:30",
      "abbr": "+0530"
    },
    {
      "name": "Asia/Kathmandu",
      "display_name": "Kathmandu",
      "utc_offset": "+05:45",
      "abbr": "NPT"
    },
    {
      "name": "Asia/Almaty",
      "display_name": "Almaty",
      "utc_offset": "+06:00",
      "abbr": "+06"
    },
    {
      "name": "Asia/Dhaka",
      "display_name": "Astana",
      "utc_offset": "+06:00",
      "abbr": "BDT"
    },
    {
      "name": "Asia/Dhaka",
      "display_name": "Dhaka",
      "utc_offset": "+06:00",
      "abbr": "BDT"
    },
    {
      "name": "Asia/Urumqi",
      "display_name": "Urumqi",
      "utc_offset": "+06:00",
      "abbr": "XJT"
    },
    {
      "name": "Asia/Rangoon",
      "display_name": "Rangoon",
      "utc_offset": "+06:30",
      "abbr": "MMT"
    },
    {
      "name": "Asia/Bangkok",
      "display_name": "Bangkok",
      "utc_offset": "+07:00",
      "abbr": "ICT"
    },
    {
      "name": "Asia/Bangkok",
      "display_name": "Hanoi",
      "utc_offset": "+07:00",
      "abbr": "ICT"
    },
    {
      "name": "Asia/Jakarta",
      "display_name": "Jakarta",
      "utc_offset": "+07:00",
      "abbr": "WIB"
    },
    {
      "name": "Asia/Krasnoyarsk",
      "display_name": "Krasnoyarsk",
      "utc_offset": "+07:00",
      "abbr": "+07"
    },
    {
      "name": "Asia/Novosibirsk",
      "display_name": "Novosibirsk",
      "utc_offset": "+07:00",
      "abbr": "+07"
    },
    {
      "name": "Asia/Shanghai",
      "display_name": "Beijing",
      "utc_offset": "+08:00",
      "abbr": "CST"
    },
    {
      "name": "Asia/Chongqing",
      "display_name": "Chongqing",
      "utc_offset": "+08:00",
      "abbr": "CST"
    },
    {
      "name": "Asia/Hong_Kong",
      "display_name": "Hong Kong",
      "utc_offset": "+08:00",
      "abbr": "HKT"
    },
    {
      "name": "Asia/Irkutsk",
      "display_name": "Irkutsk",
      "utc_offset": "+08:00",
      "abbr": "+08"
    },
    {
      "name": "Asia/Kuala_Lumpur",
      "display_name": "Kuala Lumpur",
      "utc_offset": "+08:00",
      "abbr": "MYT"
    },
    {
      "name": "Australia/Perth",
      "display_name": "Perth",
      "utc_offset": "+08:00",
      "abbr": "AWST"
    },
    {
      "name": "Asia/Singapore",
      "display_name": "Singapore",
      "utc_offset": "+08:00",
      "abbr": "SGT"
    },
    {
      "name": "Asia/Taipei",
      "display_name": "Taipei",
      "utc_offset": "+08:00",
      "abbr": "CST"
    },
    {
      "name": "Asia/Ulaanbaatar",
      "display_name": "Ulaanbaatar",
      "utc_offset": "+08:00",
      "abbr": "ULAT"
    },
    {
      "name": "Asia/Tokyo",
      "display_name": "Osaka",
      "utc_offset": "+09:00",
      "abbr": "JST"
    },
    {
      "name": "Asia/Tokyo",
      "display_name": "Sapporo",
      "utc_offset": "+09:00",
      "abbr": "JST"
    },
    {
      "name": "Asia/Seoul",
      "display_name": "Seoul",
      "utc_offset": "+09:00",
      "abbr": "KST"
    },
    {
      "name": "Asia/Tokyo",
      "display_name": "Tokyo",
      "utc_offset": "+09:00",
      "abbr": "JST"
    },
    {
      "name": "Asia/Yakutsk",
      "display_name": "Yakutsk",
      "utc_offset": "+09:00",
      "abbr": "+09"
    },
    {
      "name": "Australia/Adelaide",
      "display_name": "Adelaide",
      "utc_offset": "+09:30",
      "abbr": "ACDT"
    },
    {
      "name": "Australia/Darwin",
      "display_name": "Darwin",
      "utc_offset": "+09:30",
      "abbr": "ACST"
    },
    {
      "name": "Australia/Brisbane",
      "display_name": "Brisbane",
      "utc_offset": "+10:00",
      "abbr": "AEST"
    },
    {
      "name": "Pacific/Guam",
      "display_name": "Guam",
      "utc_offset": "+10:00",
      "abbr": "ChST"
    },
    {
      "name": "Australia/Hobart",
      "display_name": "Hobart",
      "utc_offset": "+10:00",
      "abbr": "AEDT"
    },
    {
      "name": "Australia/Melbourne",
      "display_name": "Melbourne",
      "utc_offset": "+10:00",
      "abbr": "AEDT"
    },
    {
      "name": "Pacific/Port_Moresby",
      "display_name": "Port Moresby",
      "utc_offset": "+10:00",
      "abbr": "PGT"
    },
    {
      "name": "Australia/Sydney",
      "display_name": "Sydney",
      "utc_offset": "+10:00",
      "abbr": "AEDT"
    },
    {
      "name": "Asia/Vladivostok",
      "display_name": "Vladivostok",
      "utc_offset": "+10:00",
      "abbr": "+10"
    },
    {
      "name": "Asia/Magadan",
      "display_name": "Magadan",
      "utc_offset": "+11:00",
      "abbr": "+11"
    },
    {
      "name": "Pacific/Noumea",
      "display_name": "New Caledonia",
      "utc_offset": "+11:00",
      "abbr": "NCT"
    },
    {
      "name": "Pacific/Guadalcanal",
      "display_name": "Solomon Is.",
      "utc_offset": "+11:00",
      "abbr": "SBT"
    },
    {
      "name": "Asia/Srednekolymsk",
      "display_name": "Srednekolymsk",
      "utc_offset": "+11:00",
      "abbr": "+11"
    },
    {
      "name": "Pacific/Auckland",
      "display_name": "Auckland",
      "utc_offset": "+12:00",
      "abbr": "NZDT"
    },
    {
      "name": "Pacific/Fiji",
      "display_name": "Fiji",
      "utc_offset": "+12:00",
      "abbr": "FJST"
    },
    {
      "name": "Asia/Kamchatka",
      "display_name": "Kamchatka",
      "utc_offset": "+12:00",
      "abbr": "+12"
    },
    {
      "name": "Pacific/Majuro",
      "display_name": "Marshall Is.",
      "utc_offset": "+12:00",
      "abbr": "MHT"
    },
    {
      "name": "Pacific/Auckland",
      "display_name": "Wellington",
      "utc_offset": "+12:00",
      "abbr": "NZDT"
    },
    {
      "name": "Pacific/Chatham",
      "display_name": "Chatham Is.",
      "utc_offset": "+12:45",
      "abbr": "CHADT"
    },
    {
      "name": "Pacific/Tongatapu",
      "display_name": "Nuku'alofa",
      "utc_offset": "+13:00",
      "abbr": "+14"
    },
    {
      "name": "Pacific/Apia",
      "display_name": "Samoa",
      "utc_offset": "+13:00",
      "abbr": "WSDT"
    },
    {
      "name": "Pacific/Fakaofo",
      "display_name": "Tokelau Is.",
      "utc_offset": "+13:00",
      "abbr": "TKT"
    }
  ]


  Vue.directive('timezones-select', {
    inserted: function(el) {
      var $el = $(el);
      for (var i = 0; i < TIMEZONES.length; i++) {
        var z = TIMEZONES[i];
        $el.append($('<option>', {
          value: z.name,
          text: TIMEZONES[i].display_name
        }));
      }
    }
  });
})();
