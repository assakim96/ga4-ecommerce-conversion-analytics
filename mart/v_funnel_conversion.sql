-- P01 DAY 6
-- GA4 전환 퍼널 데이터 마트 VIEW 생성

CREATE OR REPLACE VIEW
`ga4-portfolio-analysis-511401.p01_mart.v_funnel_conversion`
AS

WITH base_events AS (
  SELECT
    user_pseudo_id,
    event_name,
    event_timestamp
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20201201' AND '20201207'
    AND event_name IN (
      'view_item',
      'add_to_cart',
      'begin_checkout',
      'purchase'
    )
    AND user_pseudo_id IS NOT NULL
),

step1_view AS (
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS step_timestamp
  FROM base_events
  WHERE event_name = 'view_item'
  GROUP BY user_pseudo_id
),

step2_cart AS (
  SELECT
    s.user_pseudo_id,
    MIN(e.event_timestamp) AS step_timestamp
  FROM step1_view s
  JOIN base_events e
    ON s.user_pseudo_id = e.user_pseudo_id
    AND e.event_name = 'add_to_cart'
    AND e.event_timestamp > s.step_timestamp
  GROUP BY s.user_pseudo_id
),

step3_checkout AS (
  SELECT
    s.user_pseudo_id,
    MIN(e.event_timestamp) AS step_timestamp
  FROM step2_cart s
  JOIN base_events e
    ON s.user_pseudo_id = e.user_pseudo_id
    AND e.event_name = 'begin_checkout'
    AND e.event_timestamp > s.step_timestamp
  GROUP BY s.user_pseudo_id
),

step4_purchase AS (
  SELECT
    s.user_pseudo_id,
    MIN(e.event_timestamp) AS step_timestamp
  FROM step3_checkout s
  JOIN base_events e
    ON s.user_pseudo_id = e.user_pseudo_id
    AND e.event_name = 'purchase'
    AND e.event_timestamp > s.step_timestamp
  GROUP BY s.user_pseudo_id
),

step_counts AS (
  SELECT 1 AS step_no,
    'view_item' AS event_name,
    COUNT(*) AS user_count
  FROM step1_view

  UNION ALL
  SELECT 2, 'add_to_cart', COUNT(*)
  FROM step2_cart

  UNION ALL
  SELECT 3, 'begin_checkout', COUNT(*)
  FROM step3_checkout

  UNION ALL
  SELECT 4, 'purchase', COUNT(*)
  FROM step4_purchase
),

step_comparison AS (
  SELECT
    step_no,
    event_name,
    user_count,
    LAG(user_count) OVER (
      ORDER BY step_no
    ) AS previous_step_users,
    FIRST_VALUE(user_count) OVER (
      ORDER BY step_no
    ) AS first_step_users
  FROM step_counts
)

SELECT
  step_no,
  event_name,
  user_count,

  CASE
    WHEN step_no = 1 THEN 100.0
    ELSE ROUND(
      100.0 * SAFE_DIVIDE(
        user_count, previous_step_users
      ), 2
    )
  END AS step_conversion_rate_pct,

  CASE
    WHEN step_no = 1 THEN NULL
    ELSE previous_step_users - user_count
  END AS drop_off_users,

  CASE
    WHEN step_no = 1 THEN NULL
    ELSE ROUND(
      100.0 * SAFE_DIVIDE(
        previous_step_users - user_count,
        previous_step_users
      ), 2
    )
  END AS drop_off_rate_pct,

  ROUND(
    100.0 * SAFE_DIVIDE(
      user_count, first_step_users
    ), 2
  ) AS overall_conversion_rate_pct

FROM step_comparison;
