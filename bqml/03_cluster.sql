-- Stage 3: self-organize concepts with BQML KMeans.

CREATE OR REPLACE MODEL `programming_books.bqml.concept_clusters`
OPTIONS(
  model_type='kmeans',
  num_clusters=12,
  standardize_features=TRUE
) AS
SELECT
  concept_id,
  * EXCEPT(concept_id, content, ml_generate_embedding_result, ml_generate_embedding_status)
FROM `programming_books.bqml.concept_embeddings`
WHERE ml_generate_embedding_status IS NULL;

CREATE OR REPLACE TABLE `programming_books.bqml.cluster_membership` AS
SELECT
  *
FROM ML.PREDICT(
  MODEL `programming_books.bqml.concept_clusters`,
  (SELECT
     concept_id,
     * EXCEPT(concept_id, content, ml_generate_embedding_result, ml_generate_embedding_status)
   FROM `programming_books.bqml.concept_embeddings`
   WHERE ml_generate_embedding_status IS NULL)
);
