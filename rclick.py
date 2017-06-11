#!/usr/bin/python

import gi
gi.require_version('Gtk', '3.0')
import subprocess
from gi.repository import Gtk

class MyStatusIconApp:
    def __init__(self):
        self.status_icon = Gtk.StatusIcon()
        self.status_icon.set_from_icon_name('input-mouse')
        self.status_icon.connect("activate", self.left_click_event)

    def left_click_event(self, icon):
		subprocess.call("eval $(xdotool getmouselocation --shell)", shell=True)
		subprocess.call("xdotool mousemove --sync $X  $Y", shell=True)
		subprocess.call("xdotool selectwindow click 3", shell=True)

app = MyStatusIconApp()
Gtk.main()