# API list response conventions (M11)

## Canonical shape

```json
{
  "success": true,
  "data": [ /* items */ ],
  "meta": { "page": 1, "limit": 20, "total": 100, "totalPages": 5 }
}
```

Helpers:

- `sendSuccess(res, data, status, meta)` — generic
- `sendList(res, items, meta)` — always arrays in `data`

## Legacy nested wrappers (migrate carefully)

Some older endpoints still return nested keys, e.g.:

- `{ data: { penalties: [] } }`
- `{ data: { videoLessons: [] } }`
- `{ data: { earnings: [] } }`
- `{ data: { children: [] } }`

Flutter datasources already parse those keys. When migrating, update **API + client together** in the same PR.

## New endpoints

Always use `sendList` / flat `data` arrays. Do not introduce new nested collection keys.
