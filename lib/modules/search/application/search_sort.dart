enum SearchSort {
  recommended,
  priceLowHigh,
  priceHighLow;

  String get label => switch (this) {
        SearchSort.recommended => 'Recommended',
        SearchSort.priceLowHigh => 'Price: Low to High',
        SearchSort.priceHighLow => 'Price: High to Low',
      };
}
