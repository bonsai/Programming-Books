-- Cross-language programming knowledge graph
-- Stage 1: normalize the 23-book TOC corpus.
-- BigQuery Standard SQL.

CREATE OR REPLACE TABLE `programming_books.bqml.toc_entries` AS
SELECT
  JSON_VALUE(line, '$.book') AS book,
  JSON_VALUE(line, '$.language') AS language,
  JSON_VALUE(line, '$.source') AS source,
  JSON_VALUE(line, '$.toc_status') AS toc_status,
  SAFE_CAST(JSON_VALUE(entry, '$.level') AS INT64) AS level,
  JSON_VALUE(entry, '$.title') AS title,
  LOWER(TRIM(REGEXP_REPLACE(JSON_VALUE(entry, '$.title'), r'[^[:alnum:] ]', ' '))) AS normalized_title
FROM `programming_books.raw.toc_jsonl` t,
UNNEST(JSON_QUERY_ARRAY(t.line, '$.entries')) AS entry;

CREATE OR REPLACE TABLE `programming_books.bqml.concepts` AS
SELECT DISTINCT
  FARM_FINGERPRINT(normalized_title) AS concept_id,
  normalized_title AS concept,
  title AS representative_title
FROM `programming_books.bqml.toc_entries`
WHERE normalized_title IS NOT NULL AND normalized_title != '';

CREATE OR REPLACE TABLE `programming_books.bqml.concept_occurrences` AS
SELECT
  FARM_FINGERPRINT(normalized_title) AS concept_id,
  book,
  language,
  source,
  level,
  title,
  toc_status
FROM `programming_books.bqml.toc_entries`;
