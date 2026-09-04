# Cross-language programming knowledge graph

This directory turns `data/toc.jsonl` into a language-neutral programming knowledge graph with BigQuery ML.

## Graph model

```text
Language ──WRITTEN_IN──> Book ──HAS_CONCEPT──> Concept
                             
Topic ──INSTANCE_OF──> Concept
Topic ──SEMANTICALLY_SIMILAR──> Topic (different languages)
```

The important modeling choice is that **concepts are not owned by a programming language**. A concept cluster can therefore connect Java, JavaScript, PHP, Python, TypeScript and Go.

## Pipeline

1. `toc_raw` — JSONL imported from `data/toc.jsonl`.
2. `toc_entries` — one normalized row per TOC entry.
3. `toc_embeddings` — semantic vectors generated with a BigQuery ML remote embedding model.
4. `concept_kmeans` — BQML KMeans groups semantically related TOC entries.
5. `concept_membership` — topic → concept assignments.
6. `graph_nodes` / `graph_edges` — structural graph.
7. `cross_language_edges` — semantic edges between topics from different languages.
8. `knowledge_graph` — final edge table.
9. `cross_language_concepts` — concepts ranked by language coverage.

## Run

Edit `bqml/cross_language_knowledge_graph.sql` and replace `YOUR_PROJECT_ID` and `programming_books` with the target GCP project and dataset.

The embedding step expects a BigQuery ML remote model backed by a Vertex AI text-embedding model. Keep the embedding model configurable because the graph should be reproducible with different embedding models.

The current `data/toc.jsonl` is a seed dataset: some books have verified top-level TOC entries while others are inventory-only. Complete PDF TOC extraction will increase graph coverage without changing the graph schema.

## BQML role

- **Embedding**: maps heterogeneous TOC wording into a common semantic vector space.
- **KMeans**: performs unsupervised concept discovery.
- **Distance**: creates weighted semantic links across languages.
- **SQL graph layer**: preserves provenance and makes the graph queryable.

## Suggested queries

### Concepts shared by the most languages

```sql
SELECT *
FROM `YOUR_PROJECT_ID.programming_books.cross_language_concepts`
ORDER BY language_count DESC, topic_count DESC;
```

### Python ↔ Go semantic links

```sql
SELECT *
FROM `YOUR_PROJECT_ID.programming_books.cross_language_edges` e
JOIN `YOUR_PROJECT_ID.programming_books.toc_entries` s
  ON e.source_id = CONCAT('topic:', s.entry_id)
JOIN `YOUR_PROJECT_ID.programming_books.toc_entries` t
  ON e.target_id = CONCAT('topic:', t.entry_id)
WHERE s.language = 'Python'
  AND t.language = 'Go'
ORDER BY weight DESC;
```

### Next evolution

After full TOC extraction, extend the graph from `Book → Part → Chapter → Section → Topic`, and add edition/year metadata. This enables longitudinal concept evolution and BQML clustering by language, era and abstraction level.
