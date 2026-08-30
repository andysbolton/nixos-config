# GAppInfo applies NoDisplay, Hidden, OnlyShowIn/NotShowIn and TryExec for the
# current desktop; the ids it returns are launchable by `uwsm app --`.
exec python3 -c "
from gi.repository import Gio

apps = sorted(
    (app.get_display_name(), app.get_id())
    for app in Gio.AppInfo.get_all()
    if app.should_show()
)

for name, app_id in apps:
    print(f'{name}: {app_id}')
"
