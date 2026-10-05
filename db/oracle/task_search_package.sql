-- -- Oracle PL/SQL package for task search
-- -- This is a reference artifact — it does not run locally against H2.
-- -- It mirrors the logic used by the Spring Data repository and is
-- -- representative of the kind of Oracle PL/SQL found in production.

-- CREATE OR REPLACE PACKAGE task_search_pkg AS

--     TYPE task_record IS RECORD (
--         id          NUMBER,
--         title       VARCHAR2(255),
--         description VARCHAR2(1000),
--         status      VARCHAR2(20),
--         priority    VARCHAR2(10),
--         assignee    VARCHAR2(100),
--         created_at  TIMESTAMP
--     );

--     TYPE task_cursor IS REF CURSOR RETURN task_record;

--     PROCEDURE search_tasks(
--         p_search_term IN  VARCHAR2 DEFAULT NULL,
--         p_status      IN  VARCHAR2 DEFAULT NULL,
--         p_page        IN  NUMBER   DEFAULT 1,
--         p_page_size   IN  NUMBER   DEFAULT 10,
--         p_results     OUT task_cursor,
--         p_total_count OUT NUMBER
--     );

-- END task_search_pkg;
-- /

-- CREATE OR REPLACE PACKAGE BODY task_search_pkg AS

--     PROCEDURE search_tasks(
--         p_search_term IN  VARCHAR2 DEFAULT NULL,
--         p_status      IN  VARCHAR2 DEFAULT NULL,
--         p_page        IN  NUMBER   DEFAULT 1,
--         p_page_size   IN  NUMBER   DEFAULT 10,
--         p_results     OUT task_cursor,
--         p_total_count OUT NUMBER
--     ) IS
--         v_term   VARCHAR2(257);
--         v_offset NUMBER;
--     BEGIN
--         v_term   := '%' || LOWER(NVL(p_search_term, '')) || '%';
--         v_offset := (p_page - 1) * p_page_size;

--         -- Total count for pagination metadata
--         SELECT COUNT(*)
--           INTO p_total_count
--           FROM tasks
--          WHERE archived = 0
--            AND LOWER(title) LIKE v_term
--             OR LOWER(description) LIKE v_term
--            AND (p_status IS NULL OR status = p_status);

--         -- Paginated results using ROWNUM (pre-12c pattern)
--         OPEN p_results FOR
--             SELECT id, title, description, status, priority, assignee, created_at
--               FROM (
--                   SELECT t.*, ROWNUM AS rn
--                     FROM (
--                         SELECT id, title, description, status, priority,
--                                assignee, created_at
--                           FROM tasks
--                          WHERE archived = 0
--                            AND LOWER(title) LIKE v_term
--                             OR LOWER(description) LIKE v_term
--                            AND (p_status IS NULL OR status = p_status)
--                          ORDER BY created_at DESC
--                     ) t
--                    WHERE ROWNUM <= v_offset + p_page_size
--               )
--              WHERE rn > v_offset;

--     END search_tasks;

-- END task_search_pkg;
-- /
-- Oracle PL/SQL package for task search
-- This is a reference artifact — it does not run locally against H2.
-- It mirrors the logic used by the Spring Data repository and is
-- representative of the kind of Oracle PL/SQL found in production.

CREATE OR REPLACE PACKAGE task_search_pkg AS

    TYPE task_record IS RECORD (
        id          NUMBER,
        title       VARCHAR2(255),
        description VARCHAR2(1000),
        status      VARCHAR2(20),
        priority    VARCHAR2(10),
        assignee    VARCHAR2(100),
        created_at  TIMESTAMP
    );

    TYPE task_cursor IS REF CURSOR RETURN task_record;

    PROCEDURE search_tasks(
        p_search_term IN  VARCHAR2 DEFAULT NULL,
        p_status      IN  VARCHAR2 DEFAULT NULL,
        p_page        IN  NUMBER   DEFAULT 1,
        p_page_size   IN  NUMBER   DEFAULT 10,
        p_results     OUT task_cursor,
        p_total_count OUT NUMBER
    );

END task_search_pkg;
/

CREATE OR REPLACE PACKAGE BODY task_search_pkg AS

    c_max_page_size CONSTANT NUMBER := 100;

    PROCEDURE search_tasks(
        p_search_term IN  VARCHAR2 DEFAULT NULL,
        p_status      IN  VARCHAR2 DEFAULT NULL,
        p_page        IN  NUMBER   DEFAULT 1,
        p_page_size   IN  NUMBER   DEFAULT 10,
        p_results     OUT task_cursor,
        p_total_count OUT NUMBER
    ) IS
        v_term      VARCHAR2(257);
        v_offset    NUMBER;
        v_page      NUMBER;
        v_page_size NUMBER;
    BEGIN
        v_term := '%' || LOWER(NVL(p_search_term, '')) || '%';

        -- Guard against NULL / zero / negative paging values
        v_page      := GREATEST(NVL(p_page, 1), 1);
        v_page_size := LEAST(GREATEST(NVL(p_page_size, 10), 1), c_max_page_size);
        v_offset    := (v_page - 1) * v_page_size;

        -- Total count for pagination metadata
        -- FIX: parentheses around the OR so archived and status filters
        -- apply to BOTH title and description matches
        SELECT COUNT(*)
          INTO p_total_count
          FROM tasks
         WHERE archived = 0
           AND (LOWER(title) LIKE v_term OR LOWER(description) LIKE v_term)
           AND (p_status IS NULL OR status = p_status);

        -- Paginated results using ROWNUM (pre-12c pattern)
        -- FIX: same parentheses; id added to ORDER BY as a tie-breaker
        -- so rows with equal created_at keep a stable order across pages
        OPEN p_results FOR
            SELECT id, title, description, status, priority, assignee, created_at
              FROM (
                  SELECT t.*, ROWNUM AS rn
                    FROM (
                        SELECT id, title, description, status, priority,
                               assignee, created_at
                          FROM tasks
                         WHERE archived = 0
                           AND (LOWER(title) LIKE v_term OR LOWER(description) LIKE v_term)
                           AND (p_status IS NULL OR status = p_status)
                         ORDER BY created_at DESC, id DESC
                    ) t
                   WHERE ROWNUM <= v_offset + v_page_size
              )
             WHERE rn > v_offset;

    END search_tasks;

END task_search_pkg;
/