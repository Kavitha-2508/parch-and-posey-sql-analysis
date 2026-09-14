# Parch & Posey — Retail SQL Analysis

A retail analytics project on the classic **Parch & Posey** dataset: a paper company with accounts, sales reps, regions, orders, and web marketing events.

## What's in this repo

| File | Description |
|---|---|
| `parch-and-posey.sql` | Raw database dump (schema + data) — 5 tables |
| `erd.png` | Entity Relationship Diagram showing table relationships |
| `data_dictionary.docx` | Column-level data dictionary for all 5 tables (types, keys, descriptions) |
| `queries.sql` | All 15 analysis queries, in order, commented |
| `Parch_and_Posey_Answers.docx` | Full write-up: each question, its SQL, and the resulting output table |

## Database schema

```
region ← sales_reps ← accounts ← orders
                          ↑
                      web_events
```

- **region** — 4 sales regions
- **sales_reps** — sales reps, each tied to one region
- **accounts** — customer accounts, each tied to one sales rep
- **orders** — paper orders (standard / gloss / poster) placed by accounts
- **web_events** — marketing touchpoints (channel, timestamp) tied to accounts

## Analysis covered

- **EDA** — row counts, date ranges, quantities/revenue by paper type, top accounts, channel mix, sales rep distribution by region
- **Joins** — cross-table questions on channel performance and regional revenue
- **CTEs & subqueries** — categorizing regions against a company-wide benchmark
- **Window functions** — partitioned averages, running totals, and a 7-day moving average

## Tools

PostgreSQL · pgAdmin · dbdiagram.io (ERD)
