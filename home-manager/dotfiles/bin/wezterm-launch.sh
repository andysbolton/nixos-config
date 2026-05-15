#!/bin/bash

open -na WezTerm --args \
	--config "enable_tab_bar=false" \
	--config "window_decorations='RESIZE'" \
	start --always-new-process -- 'launch.sh'
