# BOOKS

本リポジトリで生成・執筆する「本」を管理する領域。

## Development status

| Book | Stage | Source | Next |
|---|---|---|---|
| Programming Principles | 🟡 Outline | 23 programming books | BQML実行 → 章構成確定 → 執筆 |
| AI Agent Usage | 🟠 Design | Agent/AI knowledge corpus | TOC corpus → BQML → outline |

## Development flow

`SOURCE → TOC → CONCEPT → EMBEDDING → BQML → KNOWLEDGE GRAPH → OUTLINE → DRAFT → REVIEW → PUBLISH`

## Directory convention

Each book gets its own directory under `BOOKS/`.

- `README.md` — book status and scope
- `outline.md` — current table of contents
- `draft/` — manuscript chapters
- `research/` — evidence and notes
- `review/` — review results

The `bqml/` directory remains the shared analysis engine; `data/` remains the source corpus.
