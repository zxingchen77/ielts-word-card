from pathlib import Path
import plistlib
import subprocess

root = Path(__file__).resolve().parent
project = root.parent
out = project / 'build'
app = out / '雅思词卡.app'
contents = app / 'Contents'
resources = contents / 'Resources'
binary = contents / 'MacOS' / 'IELTSWordCard'
resources.mkdir(parents=True, exist_ok=True)
binary.parent.mkdir(parents=True, exist_ok=True)
subprocess.run(['python3', str(root / 'build_deck.py')], check=True)
subprocess.run(['xcrun', 'clang', '-fobjc-arc', '-O2', '-mmacosx-version-min=13.0',
                '-Wno-deprecated-declarations', '-Wno-incompatible-pointer-types',
                '-framework', 'Cocoa', str(root / 'Main.m'), '-o', str(binary)], check=True)
subprocess.run([str(binary), '--self-test'], check=True)
(resources / 'words.json').write_bytes((root / 'words.json').read_bytes())
info = {
    'CFBundleName': '雅思词卡',
    'CFBundleDisplayName': '雅思词卡',
    'CFBundleIdentifier': 'local.codex.ieltswordcard',
    'CFBundleExecutable': 'IELTSWordCard',
    'CFBundlePackageType': 'APPL',
    'CFBundleShortVersionString': '1.0',
    'CFBundleVersion': '1',
    'CFBundleIconFile': 'AppIcon',
    'LSMinimumSystemVersion': '13.0',
    'NSHighResolutionCapable': True,
    'NSSupportsAutomaticTermination': False,
    'NSHumanReadableCopyright': 'Original starter deck and local native application, 2026.'
}
(contents / 'Info.plist').write_bytes(plistlib.dumps(info))
(contents / 'PkgInfo').write_bytes(b'APPL????')
subprocess.run([str(binary), '--make-icon', str(root / 'icon.png')], check=True)
iconset = root / 'AppIcon.iconset'
iconset.mkdir(exist_ok=True)
for size in (16, 32, 128, 256, 512):
    for scale in (1, 2):
        name = f'icon_{size}x{size}' + ('@2x' if scale == 2 else '') + '.png'
        subprocess.run(['sips', '-z', str(size*scale), str(size*scale), str(root / 'icon.png'),
                        '--out', str(iconset / name)], check=True, capture_output=True)
subprocess.run(['iconutil', '-c', 'icns', str(iconset), '-o', str(resources / 'AppIcon.icns')], check=True)
subprocess.run(['codesign', '--force', '--sign', '-', str(app)], check=True)
print(app)
