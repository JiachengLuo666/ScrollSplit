"""Build and verify using a private temporary mount, without writing into /Volumes."""
import os
import plistlib
import subprocess
import sys
import tempfile
from pathlib import Path

import dmgbuild.core

app, background, output = map(os.path.abspath, sys.argv[1:4])
with open(os.path.join(app, "Contents", "Info.plist"), "rb") as plist:
    version = plistlib.load(plist)["CFBundleShortVersionString"]
release = version[:-2] if version.endswith(".0") else version
original_hdiutil = dmgbuild.core.hdiutil

with tempfile.TemporaryDirectory(prefix="scrollsplit-mount-", dir=os.path.dirname(output)) as mount:
    def hdiutil_in_temporary_directory(command, *args, **kwargs):
        if command == "attach":
            args = ("-mountpoint", mount, *args)
        return original_hdiutil(command, *args, **kwargs)

    dmgbuild.core.hdiutil = hdiutil_in_temporary_directory
    try:
        dmgbuild.core.build_dmg(
            output, f"ScrollSplit {release}",
            settings_file=str(Path(__file__).with_name("dmg-settings.py")),
            defines={"app": app, "background": background},
        )
    finally:
        dmgbuild.core.hdiutil = original_hdiutil

    subprocess.run(["hdiutil", "attach", output, "-readonly", "-nobrowse", "-mountpoint", mount], check=True)
    try:
        installed = os.path.join(mount, "ScrollSplit.app")
        subprocess.run(["codesign", "--verify", "--strict", installed], check=True)
        subprocess.run(["cmp", os.path.join(installed, "Contents/MacOS/ScrollSplit"),
                        os.path.join(app, "Contents/MacOS/ScrollSplit")], check=True)
        assert os.readlink(os.path.join(mount, "Applications")) == "/Applications"
        assert os.readlink(os.path.join(mount, "打开已安装版本.app")) == "/Applications/ScrollSplit.app"
        with open(os.path.join(installed, "Contents", "Info.plist"), "rb") as plist:
            assert plistlib.load(plist)["CFBundleShortVersionString"] == version
        print(f"Installer {version} verified: signature, executable and installation shortcuts.")
    finally:
        subprocess.run(["hdiutil", "detach", mount], check=True)
