"""Regression checks for missing text, damaged markers and reordered arguments."""
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[2]/'scripts'))
from audit_app_localization import audit, signature

class CatalogTests(unittest.TestCase):
    def test_numbered_arguments_preserve_timer_values(self):
        self.assertEqual(signature('+%d in %02d:%02d'), signature('%2$02d:%3$02d +%1$d'))
        self.assertNotEqual(signature('+%d in %02d:%02d'), signature('%02d:%02d +%d'))

    def test_types_widths_and_counts_must_match(self):
        for invalid in ['%@', '%ld', '%02d', '%d %d', '％d', '__PERTINATE_D__']:
            self.assertNotEqual(signature('%d'), signature(invalid))

    def test_literal_percent_is_not_a_prose_argument(self):
        self.assertEqual(signature('80% de precisión'), signature('80% accuracy'))
        self.assertEqual(signature('Save %d%%'), signature('%1$d%%'))
        self.assertNotEqual(signature('Save %d%%'), signature('%d%'))

    def test_all_catalogs_report_missing_empty_and_corrupt_strings(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp)
            examples={'en':{'missing':'Text', 'empty':'Title', 'format':'%d', 'marker':'Coins'},
                      'ja':{'empty':'', 'format':'％d', 'marker':'__PERTINATE_D__'}}
            for locale, values in examples.items():
                folder=root/(locale+'.lproj');folder.mkdir()
                (folder/'Localizable.strings').write_text('\n'.join(
                    json.dumps(k)+' = '+json.dumps(v,ensure_ascii=False)+';' for k,v in values.items()))
            result=audit(root)
            self.assertEqual(result['locales'],2)
            error=result['errors'][0]
            self.assertEqual(error['missing'],['missing'])
            self.assertEqual(error['empty'],['empty'])
            self.assertEqual(error['format_mismatches'],['format'])
            self.assertEqual(error['unresolved_markers'],['marker'])

if __name__=='__main__':
    unittest.main()
