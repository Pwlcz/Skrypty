#!/bin/python3
# run with sudo
# TODO
import sys, subprocess
# SCREEN_NAME="${1:-}"
# SCREEN_PARAMS="${2:-}"
# command = sys.argv[1:]
screen_name = sys.argv[1]
screen_params = sys.argv[2]
#gtf 1920 1080 60 | awk 'NR%2==1 {$1=""; print $0}'

# from gtf command get second line, remove first word and print the rest, then from output the first word is one variable and the rest is another variable, then run xrandr --newmode with those variables, then add the mode to the screen and apply it
SUB = subprocess.run("gtf 1920 1080 60 | awk 'NR%2==1 {$1=\"\"; print $0}'", shell = True, executable="/bin/bash", capture_output=True, text=True)

mode_name, mode_params = SUB.stdout.split()
subprocess.run(f"xrandr --newmode {mode_name} {mode_params}", shell = True, executable="/bin/bash")
subprocess.run(f"xrandr --addmode {screen_name} {mode_name}", shell = True, executable="/bin/bash")
subprocess.run(f"xrandr --output {screen_name} --mode {mode_name}", shell = True, executable="/bin/bash")
# xrandr newmode "jebany_szajs"  "${SCREEN_PARAMS}" -hsync +vsync
# xrandr --newmode "jebany_szajs"  "${SCREEN_PARAMS}" -hsync +vsync
# xrandr --addmode "${SCREEN_NAME}" "jebany_szajs"
# xrandr --output "${SCREEN_NAME}" --mode "jebany_szajs"

# ModeName
# ModeParams
# xrandr --newmode $(gtf 1920 1080 60 | awk 'NR%2==1 {$1=""; print $0}')

# # Well, the string within the quotes is the nick/alias
# # of the display mode - you can as well pass something
# # as "MyAwesomeHDResolution". But, careful! :-|

# # Then all you have to do is to add the new mode to the
# # display you want to apply, like this:
# xrandr --addmode VGA1 "1920x1080_60.00"

# # VGA1 is the display name, it might differ for you.
# # Run "xrandr" without any parameters to be sure.
# # The last parameter is the mode-alias/name which
# # you've set in the previous command (--newmode)

# # It should add the new mode to the display & apply it.
# # Usually unlikely, but if it doesn't apply automatically
# # then force it with this command:
# xrandr --output VGA1 --mode "1920x1080_60.00"


