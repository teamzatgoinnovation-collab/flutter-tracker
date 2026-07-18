# Project Tracker (Flutter)

Field companion for `project_tracker` against a shared ERPNext site.

## Phase 8 surface

| Tab | APIs |
|-----|------|
| Dashboard | hub ping + `dashboard_summary` |
| Projects | `list_projects` → `get_project` (+ filtered tasks) |
| Tasks | `list_tasks` → `get_task` + `update_task_status` |
| Approvals | `list_mine` + `approve` / `reject` |
| Connection | site ping, Probe PT, FCM register |

Stack matches Delivery/Kitchen: **Riverpod** + **go_router** + `zatgo_dart_sdk`.

Kanban / Gantt / org tree remain on Frappe Desk.

## Run

```bash
cd Clients/flutter/project_tracker
flutter pub get
flutter run \
  --dart-define=FRAPPE_BASE_URL=http://127.0.0.1:8082
```
