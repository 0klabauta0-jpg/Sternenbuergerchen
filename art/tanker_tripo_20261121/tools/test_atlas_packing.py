"""Pure rectangle-packing checks; does not launch or import Blender."""
import unittest
from atlas_materials import _pack_rectangles


class AtlasPackingTest(unittest.TestCase):
    def test_actual_tanker_native_sizes_preserved_and_nonoverlapping(self):
        sizes = [1024, 512] + [256]*30 + [128]*27 + [64]*21 + [32]*2
        rects = [(str(i), n+8, n+8) for i, n in enumerate(sizes)]
        result = None
        for width, height in ((2048, 2048), (2048, 4096), (4096, 4096)):
            result = _pack_rectangles(rects, width, height)
            if result is not None:
                break
        self.assertIsNotNone(result)
        self.assertEqual(len(result), 82)
        for key, expected_w, expected_h in rects:
            x, y, w, h = result[key]
            self.assertEqual((w, h), (expected_w, expected_h))
            self.assertGreaterEqual(min(x, y), 0)
            self.assertLessEqual(x+w, width)
            self.assertLessEqual(y+h, height)
        values = list(result.values())
        for i, (x, y, w, h) in enumerate(values):
            for a, b, c, d in values[i+1:]:
                self.assertTrue(x+w <= a or a+c <= x or y+h <= b or b+d <= y)
        self.assertEqual(result, _pack_rectangles(list(reversed(rects)), width, height))

    def test_impossible_input_fails_without_resizing(self):
        self.assertIsNone(_pack_rectangles([('wide', 2049, 1)], 2048, 2048))
        self.assertIsNone(_pack_rectangles([('a', 10, 10), ('b', 10, 10)], 10, 10))

    def test_invalid_and_empty_inputs(self):
        self.assertEqual(_pack_rectangles([], 16, 16), {})
        with self.assertRaises(ValueError):
            _pack_rectangles([('a', 0, 4)], 16, 16)
        with self.assertRaises(ValueError):
            _pack_rectangles([('a', 4, 4), ('a', 4, 4)], 16, 16)


if __name__ == '__main__':
    unittest.main()
