enum TaxMode {
  taxIncluded,
  taxExcluded;

  bool get isTaxIncluded => this == TaxMode.taxIncluded;
  bool get isTaxExcluded => this == TaxMode.taxExcluded;
}
