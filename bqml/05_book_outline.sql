-- Stage 5: derive a deterministic candidate outline for a new book.
-- The result is a candidate editorial structure, not a reproduction of any source book.

CREATE OR REPLACE TABLE `programming_books.bqml.generated_book_outline` AS
WITH ranked AS (
  SELECT
    concept_id,
    representative_title,
    language_count,
    book_count,
    occurrence_count,
    importance_score,
    ROW_NUMBER() OVER (ORDER BY importance_score DESC, representative_title) AS rn
  FROM `programming_books.bqml.rankable_concepts`
),
chapterized AS (
  SELECT
    concept_id,
    representative_title,
    language_count,
    book_count,
    occurrence_count,
    importance_score,
    CASE
      WHEN REGEXP_CONTAINS(LOWER(representative_title), r'(value|type|data type|basic data|strings|arrays|list|dictionary|object)') THEN '01_data_and_types'
      WHEN REGEXP_CONTAINS(LOWER(representative_title), r'(control|if|loop|flow|program structure)') THEN '02_control_and_program_structure'
      WHEN REGEXP_CONTAINS(LOWER(representative_title), r'(function|method|lambda|higher.order)') THEN '03_functions_and_abstraction'
      WHEN REGEXP_CONTAINS(LOWER(representative_title), r'(object.oriented|class|interface|inheritance|composition)') THEN '04_objects_and_interfaces'
      WHEN REGEXP_CONTAINS(LOWER(representative_title), r'(package|module|namespace|library)') THEN '05_modules_and_composition'
      WHEN REGEXP_CONTAINS(LOWER(representative_title), r'(error|exception|debug|testing)') THEN '06_errors_testing_and_quality'
      WHEN REGEXP_CONTAINS(LOWER(representative_title), r'(concurr|goroutine|channel|async|parallel)') THEN '07_concurrency_and_time'
      WHEN REGEXP_CONTAINS(LOWER(representative_title), r'(file|database|sql|storage|data loading|web scraping|http)') THEN '08_data_and_networks'
      WHEN REGEXP_CONTAINS(LOWER(representative_title), r'(performance|optimization|runtime)') THEN '09_runtime_and_performance'
      ELSE '10_language_ecology_and_practice'
    END AS chapter_key
  FROM ranked
)
SELECT
  chapter_key,
  concept_id,
  representative_title AS concept,
  language_count,
  book_count,
  occurrence_count,
  importance_score,
  ROW_NUMBER() OVER (PARTITION BY chapter_key ORDER BY importance_score DESC, representative_title) AS concept_order
FROM chapterized;

CREATE OR REPLACE TABLE `programming_books.bqml.generated_chapters` AS
SELECT
  chapter_key,
  COUNT(*) AS concept_count,
  ARRAY_AGG(STRUCT(concept, language_count, book_count, importance_score) ORDER BY concept_order LIMIT 12) AS concepts
FROM `programming_books.bqml.generated_book_outline`
GROUP BY chapter_key;
