-- Cross-language programming knowledge graph using BigQuery ML.
-- Source: data/toc.jsonl
--
-- Prerequisites:
--   1. Load data/toc.jsonl into `${PROJECT_ID}.${DATASET}.toc_raw`.
--   2. Create a BigQuery ML remote embedding model named `toc_embedding_model`
--      backed by a Vertex AI text embedding model, or replace the model name below.
--
-- Design:
--   TOC entry -> semantic embedding -> BQML KMeans concept cluster
--             -> similarity edges -> cross-language knowledge graph
--
-- The graph deliberately separates language/book from concept. This lets
-- Java, JavaScript, PHP, Python, TypeScript and Go converge on shared concepts.

DECLARE project_id STRING DEFAULT 'YOUR_PROJECT_ID';
DECLARE dataset_id STRING DEFAULT 'programming_books';

-- 1. Normalized TOC entries -------------------------------------------------
CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.programming_books.toc_entries` AS
SELECT
  TO_HEX(SHA256(CONCAT(book, '|', CAST(entry_offset AS STRING), '|', title))) AS entry_id,
  book,
  language,
  source,
  entry_offset,
  level,
  title,
  LOWER(REGEXP_REPLACE(title, r'[^[:alnum:]_]+', ' ')) AS normalized_title
FROM `YOUR_PROJECT_ID.programming_books.toc_raw`,
UNNEST(entries) AS entry WITH OFFSET AS entry_offset;

-- 2. Semantic embeddings ---------------------------------------------------
-- Replace the model identifier with your deployed embedding model.
CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.programming_books.toc_embeddings` AS
SELECT
  entry_id,
  book,
  language,
  title,
  ml_generate_embedding_result AS embedding
FROM ML.GENERATE_EMBEDDING(
  MODEL `YOUR_PROJECT_ID.programming_books.toc_embedding_model`,
  (
    SELECT entry_id, book, language, title
    FROM `YOUR_PROJECT_ID.programming_books.toc_entries`
  ),
  STRUCT(TRUE AS flatten_json_output)
);

-- 3. Concept clustering with BQML ------------------------------------------
-- A concept cluster is language-neutral. Examples that should naturally
-- converge include functions, data structures, error handling, concurrency,
-- testing, databases and web programming.
CREATE OR REPLACE MODEL `YOUR_PROJECT_ID.programming_books.concept_kmeans`
OPTIONS(
  model_type = 'KMEANS',
  num_clusters = 24,
  distance_type = 'COSINE',
  standardize_features = TRUE
) AS
SELECT
  entry_id,
  embedding
FROM `YOUR_PROJECT_ID.programming_books.toc_embeddings`;

-- 4. Assign each TOC entry to a concept cluster ----------------------------
CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.programming_books.concept_membership` AS
SELECT
  e.entry_id,
  e.book,
  e.language,
  e.title,
  p.centroid_id AS concept_id,
  p.nearest_centroids_distance AS distance
FROM ML.PREDICT(
  MODEL `YOUR_PROJECT_ID.programming_books.concept_kmeans`,
  (
    SELECT entry_id, embedding
    FROM `YOUR_PROJECT_ID.programming_books.toc_embeddings`
  )
) AS p
JOIN `YOUR_PROJECT_ID.programming_books.toc_entries` AS e
USING (entry_id);

-- 5. Knowledge graph nodes -------------------------------------------------
CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.programming_books.graph_nodes` AS
SELECT
  CONCAT('language:', LOWER(language)) AS node_id,
  'language' AS node_type,
  language AS label
FROM `YOUR_PROJECT_ID.programming_books.toc_entries`
GROUP BY language

UNION ALL

SELECT
  CONCAT('book:', TO_HEX(SHA256(book))) AS node_id,
  'book' AS node_type,
  book AS label
FROM `YOUR_PROJECT_ID.programming_books.toc_entries`
GROUP BY book

UNION ALL

SELECT
  CONCAT('concept:', CAST(concept_id AS STRING)) AS node_id,
  'concept' AS node_type,
  CONCAT('concept-', CAST(concept_id AS STRING)) AS label
FROM `YOUR_PROJECT_ID.programming_books.concept_membership`
GROUP BY concept_id

UNION ALL

SELECT
  CONCAT('topic:', entry_id) AS node_id,
  'topic' AS node_type,
  title AS label
FROM `YOUR_PROJECT_ID.programming_books.toc_entries`;

-- 6. Structural graph edges ------------------------------------------------
CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.programming_books.graph_edges` AS
SELECT
  CONCAT('language:', LOWER(e.language)) AS source_id,
  CONCAT('book:', TO_HEX(SHA256(e.book))) AS target_id,
  'WRITTEN_IN' AS relation,
  1.0 AS weight
FROM `YOUR_PROJECT_ID.programming_books.toc_entries` e
GROUP BY source_id, target_id

UNION ALL

SELECT
  CONCAT('book:', TO_HEX(SHA256(m.book))) AS source_id,
  CONCAT('concept:', CAST(m.concept_id AS STRING)) AS target_id,
  'HAS_CONCEPT' AS relation,
  COUNT(*) AS weight
FROM `YOUR_PROJECT_ID.programming_books.concept_membership` m
GROUP BY source_id, target_id

UNION ALL

SELECT
  CONCAT('topic:', m.entry_id) AS source_id,
  CONCAT('concept:', CAST(m.concept_id AS STRING)) AS target_id,
  'INSTANCE_OF' AS relation,
  EXP(-m.distance) AS weight
FROM `YOUR_PROJECT_ID.programming_books.concept_membership` m;

-- 7. Cross-language semantic edges ----------------------------------------
-- Only connect topics from different languages. The threshold is deliberately
-- conservative; tune it after inspecting the distribution of distances.
CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.programming_books.cross_language_edges` AS
WITH pairs AS (
  SELECT
    a.entry_id AS source_entry_id,
    b.entry_id AS target_entry_id,
    a.language AS source_language,
    b.language AS target_language,
    ML.DISTANCE(a.embedding, b.embedding, 'COSINE') AS distance
  FROM `YOUR_PROJECT_ID.programming_books.toc_embeddings` a
  JOIN `YOUR_PROJECT_ID.programming_books.toc_embeddings` b
    ON a.language < b.language
)
SELECT
  CONCAT('topic:', source_entry_id) AS source_id,
  CONCAT('topic:', target_entry_id) AS target_id,
  'SEMANTICALLY_SIMILAR' AS relation,
  1.0 - distance AS weight
FROM pairs
WHERE distance <= 0.22;

-- 8. Final graph ------------------------------------------------------------
CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.programming_books.knowledge_graph` AS
SELECT * FROM `YOUR_PROJECT_ID.programming_books.graph_edges`
UNION ALL
SELECT * FROM `YOUR_PROJECT_ID.programming_books.cross_language_edges`;

-- 9. Useful analysis views -------------------------------------------------
CREATE OR REPLACE VIEW `YOUR_PROJECT_ID.programming_books.cross_language_concepts` AS
SELECT
  concept_id,
  COUNT(*) AS topic_count,
  COUNT(DISTINCT language) AS language_count,
  ARRAY_AGG(DISTINCT language ORDER BY language) AS languages,
  ARRAY_AGG(STRUCT(language, title) ORDER BY language, title LIMIT 20) AS examples
FROM `YOUR_PROJECT_ID.programming_books.concept_membership`
GROUP BY concept_id;

-- 10. Ranking: concepts that bridge the most languages --------------------
SELECT
  concept_id,
  language_count,
  languages,
  topic_count,
  examples
FROM `YOUR_PROJECT_ID.programming_books.cross_language_concepts`
ORDER BY language_count DESC, topic_count DESC;
