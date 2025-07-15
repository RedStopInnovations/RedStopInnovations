# Fix deprecations for new release of Money gem
Money.rounding_mode = BigDecimal::ROUND_HALF_EVEN
Money.locale_backend = nil