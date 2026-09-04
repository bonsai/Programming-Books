# Generated Book Outline

> Candidate editorial structure generated from the 23-book TOC corpus. This is a synthesis layer, not a reproduction of any source book.

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

The exact chapter contents are produced by `bqml/05_book_outline.sql` into `programming_books.bqml.generated_book_outline` and grouped by `generated_chapters`.

## Editorial principle

The generated book should be language-independent. Java, JavaScript, PHP, Python, TypeScript, and Go are evidence sources; the chapter structure is organized around programming concepts that recur across languages.

## Provenance

The current corpus contains a mixture of web-verified TOC entries and inventory-only books. The generated outline must therefore expose coverage and provenance rather than imply that every PDF has been fully extracted.
