bookmarks_folder="$1"

if [ -z "$bookmarks_folder" ]; then
	echo "Usage: $0 <bookmarks folder>"
	exit 1
fi

db="${bookmarks_folder}/places.sqlite"
cache_file="$HOME/.cache/bookmarks.txt"
stamp=$(stat -c '%Y %s' "$db" 2>/dev/null)

if [ -f "$cache_file" ] && [ -n "$stamp" ] && [ "$stamp" = "$(head -n 1 "$cache_file")" ]; then
	tail -n +2 "$cache_file"
	exit 0
fi

# Copy DB since it's locked while Firefox is running
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cp -f "$db" "$work/places.sqlite"
for suffix in -wal -shm; do
	if [ -f "${db}${suffix}" ]; then
		cp -f "${db}${suffix}" "$work/places.sqlite${suffix}"
	fi
done

output=$(sqlite3 -separator ": " \
	"$work/places.sqlite" \
	"SELECT b.title, p.url FROM moz_bookmarks b JOIN moz_places p ON b.fk = p.id WHERE b.title IS NOT NULL AND p.url NOT LIKE 'place:%' ORDER BY b.title")

{
	echo "$stamp"
	echo "$output"
} >"$cache_file"

echo "$output"
