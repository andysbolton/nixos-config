system=$(cliphist -db-path "$HOME/.cache/cliphist/system-db" list | head -10 | sort -nr | nl)

echo "$system" |
	rofi -dmenu \
		-no-fixed-num-lines \
		-display-columns 1,3
