Sub Aktualizace()
    Dim Nadpis      As String
    Dim Hlavicka    As Variant
    Dim SQL         As String, sDataServer As String

    Dim Conn        As adodb.Connection, RS As adodb.Recordset

    On Error Resume Next
    GlobalScope.BasicLibraries.loadLibrary ("ZFunkce")
    On Error GoTo 0

    Set Conn = New adodb.Connection
    sDataServer = "172.25.15.32"
    OpenZepterDb "snake", Conn, , sDataServer, "datarep", "Honda621"
    'udelam rocni moc, tim ocenuju odbdeno za minule mesice
    Dim ttMOC_YTM As String, sMesRok As String, sMOC, sStavy, sCena

    i = 1
    ttMOC_YTM = " tt.moc_curryear"
    Conn.Execute "drop table if exists " & ttMOC_YTM
    For i = 1 To 12        '12 uz jsem to projel, ted uz jen posledni
        sMesRok = Format(DateAdd("m", -i, Date), "mmyy")
        Conn.Execute IIf(i > 1, "insert into ", "create table ") & ttMOC_YTM & " select _latin2'" & sMesRok & "' mesrok, moc.*  from mezc" & sMesRok & " moc where moc.op=(" & _
          " select max(op) op from mezc" & sMesRok & " uvn where uvn.OZCIS=moc.ozcis " & _
          ")"
    Next i
    Conn.Execute "alter table " & ttMOC_YTM & " add index mesrok(mesrok,ozcis)"





    i = 1
    For i = 1 To 1        '12 uz jsem to projel, ted uz jen posledni
        SQL = ""
        sMOC = "mezc" & Format(DateAdd("m", -i, Date), "mmyy")
        sStavy = "ks" & Format(DateAdd("m", -i, Date), "mm")
        sCena = "cena" & Format(DateAdd("m", -i, Date), "mm")
        sObdobi = Format(DateAdd("m", -i, Date), "mm, yyyy")
        sMesRok = Format(DateAdd("m", -i, Date), "mmyy")

        SkocNaList ("Stavy " & sObdobi)
        Cells.Delete

        Nadpis = "Koneèné stavy " & sObdobi
        '413115-20.000.00  tahle polozka ma opracovani a odvedeno v 10/23
        'uvn.mat+uvn.mzda+uvn.koo+uvn.sr+uvn.vr+uvn.tr+uvn.opn+uvn.OR_
        '*( Select ( uvn.min + uvn.opracovani ) nm from " & smoc & " uvn wher uvn.ozcis=s.artnr And op=(select max(uvn.op) op from " & sMOC & " uvn where uvn.OZCIS=s.artnr))

        SQL = " select * from ( " & SQL & IIf(SQL = "", "", " union all ") & _
              " Select        '" & sObdobi & "' obdobi,'Material' as typ, if(skup.d_market='NeMa','xEmpty',ifnull(skup.d_market,'xEmpty')) artgruppe,concat(c.artnr,'-',c.kurzbez,'-',j.nazev) as mat,s.lagerort sklad," & _
              " sum(s." & sStavy & ")/ifnull(skup.podil,1) stav,sum(s." & sStavy & "*s." & sCena & ")/ifnull(skup.podil,1) stavkc, null MesOdvedeno, null nh_MesOdvedeno, null YTMOdvedeno, null nh_YTMOdvedeno " & _
              " from vm2s s left join vm2 c On c.artnr=s.artnr left join jednotky j On j.mj=c.meinheit" & _
              " ,json_table(mat_mktskup('M',c.artnr),        '$[*]' columns(  d_market  varchar(10) path '$.d_market',  podil  int path '$.podil' ) ) skup " & _
              " where 1=1 group by 1,2,3,4" & _
              " union all" & _
              " Select        '" & sObdobi & "' obdobi,case when c.artnr like '4%' then 'Finished product' else 'Semi-finished product' end as typ, if(skup.d_market='NeMa','xEmpty',ifnull(skup.d_market,'xEmpty')),concat(c.artnr,'-',c.kurzbez,'-',j.nazev) as mat,s.lagerort sklad," & _
              " sum(s." & sStavy & ")/ifnull(skup.podil,1) stav,sum(s." & sStavy & "*" & _
              " ( Select ( uvn.mat+uvn.mzda+uvn.koo+uvn.sr+uvn.vr+uvn.tr+uvn.opn+uvn.OR_ ) uvn from " & sMOC & " uvn where uvn.ozcis=s.artnr And op=(select max(uvn.op) op from " & sMOC & " uvn where uvn.OZCIS=s.artnr)) " & _
              " )/ifnull(skup.podil,1) stavkc," & _
              " ( SELECT sum(zugang) from vm21 denik WHERE denik.artnr=s.artnr AND c_mes1=left('" & sMesRok & "',2) AND c_rok1=right('" & sMesRok & "',2) and lager in ( 30,32,33) and V_TYP in ('OH','PL') and D_DILEC = 1 ) MesOdvedeno," & _
              " ( SELECT ifnull(sum(zugang),0) from vm21 denik WHERE denik.artnr=s.artnr AND c_mes1=left('" & sMesRok & "',2) AND c_rok1=right('" & sMesRok & "',2) and lager in ( 30,32,33) and V_TYP in ('OH','PL') and D_DILEC = 1 )*( Select ( uvn.min + uvn.opracovani ) nm from " & sMOC & " uvn where uvn.ozcis=s.artnr And op=(select max(uvn.op) op from " & sMOC & " uvn where uvn.OZCIS=s.artnr)) " & _
              " /60/ifnull(skup.podil,1) nh_MesOdvedeno, " & _
              " ( SELECT sum(zugang) from vm21 denik WHERE denik.artnr=s.artnr AND c_mes1<=left('" & sMesRok & "',2) AND c_rok1=right('" & sMesRok & "',2) and lager in ( 30,32,33) and V_TYP in ('OH','PL') and D_DILEC = 1 ) YTMOdvedeno," & _
              " ( SELECT ifnull(sum(zugang*( uvn.min + uvn.opracovani )),0) from vm21 denik left join " & ttMOC_YTM & " uvn on uvn.mesrok=concat(denik.c_mes1,denik.c_rok1) and uvn.ozcis=denik.artnr WHERE denik.artnr=s.artnr AND c_mes1<=left('" & sMesRok & "',2) AND c_rok1=right('" & sMesRok & "',2) and lager in ( 30,32,33) and V_TYP in ('OH','PL') and D_DILEC = 1 ) " & _
              " /60/ifnull(skup.podil,1) nh_YTMOdvedeno " & _
              " from prodats s left join prodat c On c.artnr=s.artnr left join jednotky j On j.mj=c.meinheit " & _
              " ,json_table(mat_mktskup('D',c.artnr),        '$[*]' columns(  d_market  varchar(10) path '$.d_market',  podil  int path '$.podil' ) ) skup " & _
              " where 1=1 group by 1,2,3,4" & _
              " ) tall where mesodvedeno<>0 or stav<>0 "

              's." & sStavy & "<>0

        PivotTableSQL "snake", sDataServer, "datarep", "Honda621", SQL, Nadpis, 1, 10, _
                      Array("typ", "sklad", "obdobi", "artgruppe"), Array("mat"), Array(), Array("stav", "stavkc", "nh_mesodvedeno", "nh_YTModvedeno"), _
                      Array("Typ", "Sklad", "Období", "Skupina"), Array("KódPoložky"), Array(), Array("StavMJ", "StavKè", "NhMesOdvedeno", "NhYTMOdvedeno"), "zeptersoft"

        With ActiveSheet.PivotTables("PivotTabulka")
            .PivotFields("StavMJ").NumberFormat = "# ### ##0.000"
            .PivotFields("StavKè").NumberFormat = "# ### ##0 Kè"
            .PivotFields("NhMesOdvedeno").NumberFormat = "# ### ##0.0"
            .PivotFields("NhYTMOdvedeno").NumberFormat = "# ### ##0.0"
            .DataPivotField.Orientation = xlColumnField
            '        .DataPivotField.Orientation.xlColumnField.Position = 1
            .PivotFields("KódPoložky").AutoSort xlDescending, "StavKè"
'            '        .PivotFields("období").CurrentPage = Format(DateAdd("m", -1, Date), "mm, yyyy") 'posledni mesic

'            .CalculatedFields.Add "NHMesOdvedenoMzda", "= iferror(stavkc /nh_mesodvedeno ,0)", True
'            .PivotFields("NHMesOdvedenoMzda").Orientation = xlDataField
'            .PivotFields("Souèet z NHMesOdvedenoMzda").Caption = "Obrátkovost"
'            .PivotFields("Obrátkovost").NumberFormat = "# ### ##0.0"
        End With
        DleSkupin ""

'        ActiveSheet.PivotTables("PivotTabulka").PivotFields("NhMesOdvedeno").Orientation = xlHidden
'        ActiveSheet.PivotTables("PivotTabulka").PivotFields("NhYTMMesOdvedeno").Orientation = xlHidden
'        ActiveSheet.PivotTables("PivotTabulka").PivotFields("Obratkovost").Orientation = xlHidden

    ActiveSheet.Shapes.AddChart2(286, xlColumnStacked).Select  'xl3DColumn
'    ActiveChart.FullSeriesCollection(1).ChartType = xlLine
'    ActiveChart.FullSeriesCollection(1).AxisGroup = 2
'    ActiveChart.FullSeriesCollection(3).ChartType = xlLine
'    ActiveChart.FullSeriesCollection(3).AxisGroup = 2
'    ActiveChart.FullSeriesCollection(5).ChartType = xlLine
'    ActiveChart.FullSeriesCollection(5).AxisGroup = 2

    Next i
    graf "Stavy " & sObdobi
End Sub



Sub DleSkupin(nic As String)
    Range("A11").Select
    With ActiveSheet.PivotTables("PivotTabulka").PivotFields("KódPoložky")
        .Orientation = xlPageField
        .Position = 1
    End With
    ActiveSheet.PivotTables("PivotTabulka").PivotSelect "Skupina", xlButton, True
    Range("A5").Select
    With ActiveSheet.PivotTables("PivotTabulka").PivotFields("Skupina")
        .Orientation = xlRowField
        .Position = 1
    End With
    'typ do sloupce
    ActiveSheet.PivotTables("PivotTabulka").PivotSelect "Typ", xlButton, True
    Range("A7").Select
    With ActiveSheet.PivotTables("PivotTabulka").PivotFields("Typ")
        .Orientation = xlColumnField
        .Position = 2
    End With
    Range("C10").Select
    With ActiveSheet.PivotTables("PivotTabulka").PivotFields("Typ")
        .Orientation = xlColumnField
        .Position = 1
    End With
    ActiveSheet.PivotTables("PivotTabulka").PivotFields("StavMJ").Orientation = xlHidden
    With ActiveSheet.PivotTables("PivotTabulka").PivotFields("KódPoložky")
        .Orientation = xlRowField
        .Position = 2
    End With
    ActiveSheet.PivotTables("PivotTabulka").PivotFields("Skupina").ShowDetail = False
    ActiveSheet.PivotTables("PivotTabulka").PivotFields("Typ").PivotItems("Finished product").Position = 1

End Sub

Function SkocNaList(sName As String)
    Dim exists      As Boolean
    For i = 1 To Worksheets.Count
        If Worksheets(i).Name = sName Then
            exists = True
        End If
    Next i

    If Not exists Then
        Sheets.Add(before:=Sheets(1)).Name = sName        'na zacatek
        'Sheets.Add(After:=Sheets(Sheets.Count)).Name = sName  'nakonec
    End If

    Worksheets(sName).Activate

End Function
Sub testgraf()
    sObdobi = "11, 2023"

    graf "Stavy " & sObdobi
End Sub

Sub graf(sLastList)
    Dim sGrafSheet
    Sheets(sLastList).Activate

        ActiveSheet.PivotTables("PivotTabulka").PivotFields("Skupina").PivotItems("LML" _
        ).Position = 1
    ActiveSheet.PivotTables("PivotTabulka").PivotFields("Skupina").PivotItems("LML" _
        ).Position = 2
    ActiveSheet.PivotTables("PivotTabulka").PivotFields("Skupina").PivotItems("RRI" _
        ).Position = 3
    ActiveSheet.PivotTables("PivotTabulka").PivotFields("Skupina").PivotItems("WAT" _
        ).Position = 4
    ActiveSheet.PivotTables("PivotTabulka").PivotFields("Skupina").PivotItems( _
        "SCOE").Position = 5
    ActiveSheet.PivotTables("PivotTabulka").PivotFields("Skupina").PivotItems( _
        "SCOG").Position = 6
    ActiveSheet.PivotTables("PivotTabulka").PivotFields("Skupina").PivotItems("LEL" _
        ).Position = 7

    ActiveSheet.PivotTables("PivotTabulka").PivotFields("Typ").PivotItems( _
        "Material").Position = 3


    sGrafSheet = Replace(sLastList, "Stavy", "Graf")
    SkocNaList (sGrafSheet)
    Application.CutCopyMode = False
    Cells.Delete Shift:=xlUp
    Range("A3").Select
    Sheets(sLastList).Select
    Cells(12, 1).CurrentRegion.Select
    Selection.Copy
    Sheets(sGrafSheet).Select
    Range("a2").Select
    Selection.PasteSpecial Paste:=xlPasteValues, Operation:=xlNone, SkipBlanks _
        :=False, Transpose:=False
    Application.CutCopyMode = False
    Range("m3").FormulaR1C1 = "Equivalent units(Month)"
    Range("n3").FormulaR1C1 = "Equivalent units(YTM)"

    Range("B:B,D:D,E:E,G:G,H:H,J:J,K:K,L:L").Delete Shift:=xlToLeft
    Cells(1, 1).Select
    Range("B5:F13").NumberFormat = "#,##0"
    Rows(13).Delete

    Range("B2:F3").Select
    Selection.Cut
    Range("B3").Select
    ActiveSheet.Paste
    Range("A3").FormulaR1C1 = "StavKè"


    Columns("A:F").AutoFit

    ActiveSheet.Shapes.AddChart2(201, xlColumnClustered).Select
    ActiveChart.SetSourceData Source:=Range("$A$4:$F$12")
    ActiveChart.FullSeriesCollection(1).ChartType = xlColumnStacked
    ActiveChart.FullSeriesCollection(1).AxisGroup = 1
    ActiveChart.FullSeriesCollection(2).ChartType = xlColumnStacked
    ActiveChart.FullSeriesCollection(2).AxisGroup = 1
    ActiveChart.FullSeriesCollection(3).ChartType = xlColumnStacked
    ActiveChart.FullSeriesCollection(3).AxisGroup = 1
    ActiveChart.FullSeriesCollection(4).ChartType = xlLine
    ActiveChart.FullSeriesCollection(4).AxisGroup = 1
    ActiveChart.FullSeriesCollection(5).ChartType = xlLine
    ActiveChart.FullSeriesCollection(5).AxisGroup = 1
    ActiveChart.FullSeriesCollection(4).AxisGroup = 2
    ActiveChart.FullSeriesCollection(5).AxisGroup = 2



    ActiveSheet.Shapes(1).IncrementLeft -51.75
    ActiveSheet.Shapes(1).IncrementTop -129.75
    ActiveSheet.ChartObjects(1).Activate
    ActiveSheet.Shapes(1).ScaleWidth 1.6791666667, msoFalse, _
        msoScaleFromTopLeft
    ActiveSheet.Shapes(1).ScaleHeight 1.7048611111, msoFalse, _
        msoScaleFromTopLeft


    ActiveChart.HasDataTable = True




    ActiveChart.SetElement (msoElementChartTitleAboveChart)
    ActiveChart.SetElement (msoElementPrimaryValueAxisTitleAdjacentToAxis)
    ActiveChart.SetElement (msoElementSecondaryValueAxisTitleAdjacentToAxis)
    ActiveChart.SetElement (msoElementPrimaryValueAxisTitleAdjacentToAxis)
    ActiveChart.SetElement (msoElementLegendRight)
    ActiveChart.SetElement (msoElementLegendNone)


    ActiveChart.ChartTitle.Text = "Inventory"






    ActiveChart.Axes(xlValue, xlSecondary).AxisTitle.Select
    ActiveChart.Axes(xlValue, xlSecondary).AxisTitle.Text = _
        "Equivalent units produced/(Month,YTM)"
    Selection.Format.TextFrame2.TextRange.Characters.Text = _
        "Equivalent units produced/(Month,YTM)"
    ActiveChart.SetElement (msoElementPrimaryValueAxisTitleAdjacentToAxis)
'    ActiveChart.Axes(xlValue).AxisTitle.Select
'    ActiveChart.Axes(xlValue, xlPrimary).AxisTitle.Text = "In CZK"
    Selection.Format.TextFrame2.TextRange.Characters.Text = "In CZK"
'    ActiveChart.Axes(xlValue).AxisTitle.Selection.Format.TextFrame2.TextRange.Font.Bold = msoTrue
'    ActiveChart.Axes(xlValue, xlSecondary).AxisTitle.Select
    ActiveChart.Axes(xlValue, xlSecondary).AxisTitle.Text = _
        "Equivalent units produced/(Month,YTM)"


    ActiveSheet.Shapes(1).IncrementLeft 30
    ActiveSheet.Shapes(1).IncrementTop -66.75
    ActiveSheet.Shapes(1).ScaleWidth 1.1166253102, msoFalse, _
        msoScaleFromTopLeft
    ActiveSheet.Shapes(1).ScaleHeight 1.5885947047, msoFalse, _
        msoScaleFromTopLeft





radek = 18
Cells(radek, 1).Value = "AMT"
Cells(radek, 2).Value = "Combi system"
radek = radek + 1
Cells(radek, 1).Value = "LML"
Cells(radek, 2).Value = "Lawn mowers"
radek = radek + 1
Cells(radek, 1).Value = "Rri"
Cells(radek, 2).Value = "Mielec"
radek = radek + 1
Cells(radek, 1).Value = "WAT"
Cells(radek, 2).Value = "Watering"
radek = radek + 1
Cells(radek, 1).Value = "SCOE"
Cells(radek, 2).Value = "OEM"
radek = radek + 1
Cells(radek, 1).Value = "SCOG"
Cells(radek, 2).Value = "Vrbno, Bruntal"
radek = radek + 1
Cells(radek, 1).Value = "LEL"
Cells(radek, 2).Value = "Aycliffe"
radek = radek + 1
Cells(radek, 1).Value = "xEmpty"
Cells(radek, 2).Value = "Overhead material"


    Sheets(sLastList).Select
    Sheets(sGrafSheet).Select
    Cells(1, 1).Select
End Sub





