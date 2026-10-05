# Notes
## Changes
- Fixed AND/OR precedence in the search query (repo, SQL file, Oracle package): archived tasks leaked and status filter was ignored.
- Frontend: error/loading state, request cancellation, page reset on filter change.
- Backend: removed artificial Thread.sleep, added input validation, moved pagination into the DB.
## Not changed
- Search debounce, LIKE wildcard escaping, DB indexes: lower value / out of time.
## Biggest remaining risk
- LIKE '%term%' cannot use an index, so search will slow down at scale; no authentication or tests.
