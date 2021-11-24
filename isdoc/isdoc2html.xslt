<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="/">
    <html>
      <body>
        <table border="1">
          <tr>
            <td>
              <xsl:value-of select="Invoice/ID" />
            </td>
            <td>
              <xsl:value-of select="Invoice/IssueDate" />
            </td>
            <td>
              <xsl:value-of select="/Invoice/SellerSupplierParty/Party/PartyIdentification/ID" />
            </td>
          </tr>
        </table>
        <table label="items" border="1">
          <xsl:for-each select="/Invoice/InvoiceLines/InvoiceLine">
            <tr>
              <td>
                <xsl:value-of select="Item/Description" />
              </td>
              <td>
                <xsl:value-of select="InvoicedQuantity" />
              </td>
              <td>
                <xsl:value-of select="ClassifiedTaxCategory/Percent" />
              </td>
            </tr>
          </xsl:for-each>
        </table>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>