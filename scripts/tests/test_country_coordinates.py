import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('catalog', ROOT / 'scripts/build_full_country_catalog.py')
catalog = importlib.util.module_from_spec(spec)
spec.loader.exec_module(catalog)

class CountryCoordinatesTests(unittest.TestCase):
    def test_all_shipped_countries_have_valid_coordinates(self):
        countries = json.loads((ROOT / 'World Arena. Flags/Resources/game_countries.json').read_text())
        self.assertGreaterEqual(len(countries), 240)
        for country in countries:
            with self.subTest(country=country['cca3']):
                lat, lon = country['latlng']
                self.assertTrue(-90 <= lat <= 90)
                self.assertTrue(-180 <= lon <= 180)
        # Regression: countries must not collapse onto one longitude per continent.
        self.assertGreater(len({c['latlng'][1] for c in countries}), 150)

    def test_generator_preserves_coordinates(self):
        iso = catalog.load_iso()
        parts = catalog.load_existing_parts()
        for code, item in parts.items():
            if code in catalog.EXCLUDE_FROM_GAME:
                continue
            if code not in catalog.REGION_MAP:
                continue
            country = catalog.to_game_country(code, iso, item)
            if country:
                self.assertEqual(country['latlng'], catalog.COUNTRY_COORDINATES[country['cca3']])

    def test_geographic_reference_points(self):
        points = catalog.COUNTRY_COORDINATES
        self.assertTrue(44 < points['UKR'][0] < 53 and 22 < points['UKR'][1] < 41)
        self.assertTrue(points['BRA'][0] < 0 and points['BRA'][1] < -30)
        self.assertTrue(points['AUS'][0] < 0 and points['AUS'][1] > 110)
        self.assertTrue(41 < points['XKX'][0] < 44 and 20 < points['XKX'][1] < 23)

if __name__ == '__main__':
    unittest.main()
