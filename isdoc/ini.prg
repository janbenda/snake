FUNCTION Main()

   LOCAL I_H := ;
      { ;
      "davka" => { ;
      "F_VS" => "*/Invoice/ID", ;
      "DIC" => "*/Invoice/SellerSupplierParty/Party/PartyTaxScheme/CompanyID", ;
      "ICO" => "*/Invoice/SellerSupplierParty/Party/PartyIdentification/ID", ;
      "BELEGDAT" => "*/Invoice/IssueDate", ;
      "BUCHDAT" => "*/Invoice/TaxPointDate", ;
      "BETRAG" => "*/Invoice/LegalMonetaryTotal/TaxInclusiveAmount", ;
      "DPH" => { ;
      'ROOT' => '*/Invoice/TaxTotal/TaxSubTotal', ;
      'ITEMS' => { ;
      "MWST" => 'TaxCategory/Percent', ;
      "BETRAG" => "TaxAmount", ;
      "ZAKLAD" => "TaxableAmount" ;
      } ;
      } ;
      } ;
      }

   RETURN NIL
