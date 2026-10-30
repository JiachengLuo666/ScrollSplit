"""Finder layout for the drag-to-install disk image; loaded by dmgbuild."""
import os

application = defines["app"]
format = "UDZO"
size = None
files = [application]
symlinks = {"Applications": "/Applications", "打开已安装版本.app": "/Applications/ScrollSplit.app"}
icon = os.path.join(application, "Contents", "Resources", "AppIcon.icns")
badge_icon = icon
background = defines["background"]
window_rect = ((180, 180), (640, 500))
icon_locations = {"ScrollSplit.app": (175, 195), "Applications": (465, 195), "打开已安装版本.app": (320, 385)}
icon_size = 84
text_size = 12
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
default_view = "icon-view"
include_icon_view_settings = True
include_list_view_settings = False
arrange_by = None
grid_spacing = 100
label_pos = "bottom"
hide_extensions = []
