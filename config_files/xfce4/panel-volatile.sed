# Drops the parts of xfce4-panel.xml that record what has been run on a
# machine rather than how its panels are laid out: whiskermenu's recently-used
# list and the systray's known items. They change on every launch, both
# plugins rebuild them from nothing, and this repo is public.
#
# capture.sh runs this on the way into the repo. workstation.yml runs it on the
# live file before comparing, since otherwise that file would never match the
# repo's and every run would replace it.
#
# Only the multi-line form is matched: an empty array is written self-closed
# (type="array"/>), and a range opened on that would run on to some unrelated
# </property>.
/<property name="\(recent\|known-items\|known-legacy-items\)" type="array">/,/<\/property>/d
