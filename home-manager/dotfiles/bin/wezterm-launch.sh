#!/bin/bash

"$HOME/Applications/Home Manager Apps/WezTerm.app/wezterm-gui" \
	--config "enable_tab_bar=false" \
	--config "window_decorations='RESIZE'" \
	start --always-new-process -- "launch.sh" &
