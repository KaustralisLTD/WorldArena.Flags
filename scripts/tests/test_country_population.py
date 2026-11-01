import importlib.util
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('catalog_builder', ROOT / 'scripts/build_full_country_catalog.py')
builder = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(builder)

class PopulationTests(unittest.TestCase):
    def test_missing_is_not_a_person(self):
        for value in ['', '—', '-', '-1']:
            self.assertEqual(builder.parse_pop(value), -1)
        self.assertEqual(builder.parse_pop('39,329'), 39329)
        self.assertEqual(builder.parse_pop('0'), 0)

    def test_all_corrections_survive_regeneration_and_match_details(self):
        countries = {x['cca3']: x for x in json.loads((builder.RES / 'game_countries.json').read_text())}
        parts = builder.load_existing_parts()
        iso = builder.load_iso()
        self.assertEqual(len(builder.POPULATION_CORRECTIONS), 42)
        self.assertTrue(all(x['population'] >= 0 and x['population'] != 1 for x in countries.values()))
        for code, correction in builder.POPULATION_CORRECTIONS.items():
            self.assertTrue(correction['source'].startswith('https://'))
            self.assertEqual(countries[iso[code]]['population'], correction['population'])
            self.assertEqual(builder.to_game_country(code, iso, parts[code])['population'], correction['population'])
            for localized in parts[code].values():
                self.assertEqual(builder.parse_pop(localized['population']), correction['population'])

if __name__ == '__main__': unittest.main()
