tohle musim udelat jinak to pada ve worksheet.close
--- a/src/worksheet.c
+++ b/src/worksheet.c
@@ -4547,6 +4547,7 @@ worksheet_set_column_opt(lxw_worksheet *self,
lxw_col_t col;
lxw_error err;

+   format = NULL;
    if (user_options) {
    hidden = user_options->hidden;
    level = user_options->level;

timhle jsem prelozil dbf2xls
hbc.sh dbf2xls.prg -L/usr/local/src/hbvs/hblibxlsxwriter/ -i/usr/local/src/hbvs/hblibxlsxwriter/ -L/usr/local/src/hbvs/libxlsxwriter/lib/ -lxlsxwriter -lhblibxlsxwriter xhb.hbc -static
