---
public: true
tags: lang:en, meta
---

# How to use yasushisakai.com

## `/pages`

The page list has two modes, controlled entirely through URL parameters.

### Modes

- **Browse** — no `q`. Lists notes, default sort by visits.
- **Search** — non-empty `q`. Cosine similarity against note embeddings, default sort by similarity.

### Parameters

| key    | meaning                                                                      |
|--------|------------------------------------------------------------------------------|
| `q`    | free-text query; enables search mode                                         |
| `all`  | comma-separated tags; result must have **every** tag                         |
| `any`  | comma-separated tags; result must have **at least one**                      |
| `none` | comma-separated tags; exclude results having **any** of these                |
| `sort` | see below; valid values depend on mode                                       |
| `l`    | max results, `1`–`200` (default `50`)                                        |
| `t`    | distance threshold, `0.0`–`2.0` (search only; lower = stricter; default `1.0`) |

#### Sort values

| value    | browse | search | meaning              |
|----------|:------:|:------:|----------------------|
| `visits` |   ✓ (default)  |   ✓    | most visited first   |
| `dist`   |        |   ✓ (default)   | most similar first   |
| `new`    |   ✓    |   ✓    | newest first         |
| `old`    |   ✓    |   ✓    | oldest first         |

Invalid sort values fall back to the mode's default.

### Examples

- `/pages` — everything, by visits
- `/pages?all=research` — only `research`-tagged
- `/pages?sort=new&l=5` — five newest notes
- `/pages?q=consensus` — semantic search
- `/pages?q=consensus&all=research&t=0.4` — narrow search with strict threshold
- `/pages?q=consensus&sort=visits` — search, re-ranked by popularity

### Notes

- `t` and `l` apply *before* re-sorting. `?q=foo&sort=visits&l=5` means "the 5 closest matches, re-sorted by visits."
- Clicking a tag in the result row sets `all=<tag>`. Clicking an active filter chip removes it.
- The URL is the state — bookmark or share any view directly.
