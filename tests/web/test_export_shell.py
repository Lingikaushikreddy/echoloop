import hashlib
import pathlib
import subprocess
import sys
import tempfile
import unittest


class WebPackageVersionTest(unittest.TestCase):
    def test_package_content_changes_the_exported_loader_version(self):
        script = pathlib.Path(__file__).resolve().parents[2] / 'scripts/finalize_web_export.py'
        with tempfile.TemporaryDirectory() as directory:
            build = pathlib.Path(directory)
            versions = []
            for content in [b'first game package', b'new mobile controls']:
                (build / 'index.pck').write_bytes(content)
                (build / 'index.html').write_text('const packVersion = "__YESTERSELF_PACK_HASH__";')
                result = subprocess.run([sys.executable, str(script), str(build)], capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                output = (build / 'index.html').read_text()
                self.assertIn(hashlib.sha256(content).hexdigest()[:16], output)
                versions.append(output)
            self.assertNotEqual(*versions)


if __name__ == '__main__':
    unittest.main()
