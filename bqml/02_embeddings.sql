-- Stage 2: semantic embeddings for normalized programming concepts.
-- Requires a remote embedding model configured in BigQuery ML.
-- Replace the MODEL reference with the project/model actually deployed in the dataset.

CREATE OR REPLACE TABLE `programming_books.bqml.concept_embeddings` AS
SELECT *
FROM ML.GENERATE_EMBEDDING(
  MODEL `programming_books.bqml.text_embedding_model`,
  (SELECT concept_id, concept AS content
   FROM `programming_books.bqml.concepts`),
  STRUCT(TRUE AS flatten_json_output)
);
