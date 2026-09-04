# Programming Principles

> 23冊のプログラミング書籍から共通原理を抽出し、言語非依存の本へ再構成する。

## Pipeline

`data/toc.jsonl` → normalization → embeddings → BQML KMeans → cross-language knowledge graph → concept importance → chapterization

## Candidate chapters

1. Data and Types
2. Control and Program Structure
3. Functions and Abstraction
4. Objects and Interfaces
5. Modules and Composition
6. Errors, Testing, and Quality
7. Concurrency and Time
8. Data and Networks
9. Runtime and Performance
10. Language Ecology and Practice

## Development status

- [x] 23-book TOC corpus
- [x] Concept normalization
- [x] Embedding pipeline definition
- [x] BQML clustering definition
- [x] Cross-language knowledge graph definition
- [x] Concept importance ranking
- [x] Candidate chapterization
- [ ] BigQuery実行・結果取得
- [ ] 章ごとの詳細目次
- [ ] 本文執筆
- [ ] Review

## Provenance

This is a synthesis layer, not a reproduction of any source book. The current corpus contains a mixture of web-verified TOC entries and inventory-only books.
