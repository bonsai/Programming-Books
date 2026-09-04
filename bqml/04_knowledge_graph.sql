-- Stage 4: construct cross-language graph and concept importance.

CREATE OR REPLACE TABLE `programming_books.bqml.concept_metrics` AS
SELECT
  concept_id,
  ANY_VALUE(title) AS representative_title,
  COUNT(DISTINCT book) AS book_count,
  COUNT(DISTINCT language) AS language_count,
  COUNT(*) AS occurrence_count,
  SAFE_DIVIDE(COUNT(DISTINCT language), 6) AS language_coverage,
  SAFE_DIVIDE(COUNT(DISTINCT book), 23) AS book_coverage
FROM `programming_books.bqml.concept_occurrences`
GROUP BY concept_id;

CREATE OR REPLACE TABLE `programming_books.bqml.knowledge_graph_nodes` AS
SELECT
  concept_id AS node_id,
  'concept' AS node_type,
  representative_title AS label,
  book_count,
  language_count,
  occurrence_count,
  language_coverage,
  book_coverage
FROM `programming_books.bqml.concept_metrics`;

CREATE OR REPLACE TABLE `programming_books.bqml.knowledge_graph_edges` AS
SELECT
  a.concept_id AS source_id,
  b.concept_id AS target_id,
  'co_occurs_in_language' AS relation,
  COUNT(DISTINCT a.language) AS shared_language_count
FROM `programming_books.bqml.concept_occurrences` a
JOIN `programming_books.bqml.concept_occurrences` b
  ON a.language = b.language
 AND a.concept_id < b.concept_id
GROUP BY source_id, target_id;

CREATE OR REPLACE VIEW `programming_books.bqml.rankable_concepts` AS
SELECT
  n.*,
  (0.60 * language_coverage + 0.30 * book_coverage + 0.10 * LOG(1 + occurrence_count)) AS importance_score
FROM `programming_books.bqml.knowledge_graph_nodes` n;
