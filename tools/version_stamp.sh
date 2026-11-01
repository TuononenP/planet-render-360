# Sourced by the build scripts. Stamps the version Settings → About shows
# (application/config/version) into project.godot for the export only:
# "0.1.0 (2412d09)", with -dirty after the commit when tracked files have
# uncommitted changes. Call stamp_version before the script edits any
# tracked file; restore_version puts the committed project.godot back.
stamp_version() {
	PROJECT_BACKUP="$(mktemp)"
	cp project.godot "$PROJECT_BACKUP"
	short="${VERSION:-$(sed -n 's/^application\/short_version="\(.*\)"$/\1/p' export_presets.cfg | head -n 1)}"
	commit="$(git describe --always --dirty --abbrev=7 2>/dev/null || echo unknown)"
	STAMP="$short ($commit)" perl -pi -e 's/^\[application\]$/$&\n\nconfig\/version="$ENV{STAMP}"/' project.godot
	echo "Version: $short ($commit)"
}
restore_version() {
	if [ -n "$PROJECT_BACKUP" ]; then
		cp "$PROJECT_BACKUP" project.godot
		rm -f "$PROJECT_BACKUP"
		PROJECT_BACKUP=""
	fi
}
