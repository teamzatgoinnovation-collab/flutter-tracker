# Tracker (Flutter)

Field companion for `tracker` against a shared ERPNext site.

## Surface

| Tab | APIs |
|-----|------|
| Dashboard | hub ping + project/task counts + running now |
| Projects | `list_projects` / `create_project` → `get_project` |
| Tasks | My/Team `list_tasks`, create/assign, Start/Pause/Next/Stop |
| Tickets | `list_tickets` / `create_ticket` |
| Connection | site ping |

Stack: **Riverpod** + **go_router** + `zatgo_dart_sdk`.

Org setup and who-is-running detail remain on Frappe Desk (`tracker-org`, `tracker-workbench`).

## Run

```bash
cd Clients/flutter/tracker
flutter pub get
flutter run \
  --dart-define=FRAPPE_BASE_URL=https://erp.zatgo.online
```
