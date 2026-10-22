-- P01 DAY 6
-- 기기별 상품 조회 → 장바구니 전환 데이터 마트

CREATE OR REPLACE VIEW
`ga4-portfolio-analysis-511401.p01_mart.v_device_conversion`
AS

WITH base_events AS (
  SELECT
    user_pseudo_id,
    event_name,
    event_timestamp,
    device.category AS device_category
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20201201' AND '20201207'
    AND event_name IN ('view_item', 'add_to_cart')
    AND user_pseudo_id IS NOT NULL
),

-- 사용자별 최초 상품 조회 시점과 기기
first_view AS (
  SELECT
    user_pseudo_id,
    device_category,
    event_timestamp AS view_timestamp
  FROM base_events
  WHERE event_name = 'view_item'
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY user_pseudo_id
    ORDER BY event_timestamp
  ) = 1
),

-- 최초 상품 조회 이후 장바구니 전환 사용자
cart_users AS (
  SELECT DISTINCT
    v.user_pseudo_id
  FROM first_view AS v
  JOIN base_events AS e
    ON v.user_pseudo_id = e.user_pseudo_id
    AND e.event_name = 'add_to_cart'
    AND e.event_timestamp > v.view_timestamp
)

SELECT
  COALESCE(v.device_category, 'unknown')
    AS device_category,

  COUNT(*) AS view_users,

  COUNT(c.user_pseudo_id) AS cart_users,

  ROUND(
    100 * SAFE_DIVIDE(
      COUNT(c.user_pseudo_id),
      COUNT(*)
    ), 2
  ) AS cart_conversion_rate_pct,

  COUNT(*) - COUNT(c.user_pseudo_id)
    AS drop_off_users,

  ROUND(
    100 * SAFE_DIVIDE(
      COUNT(*) - COUNT(c.user_pseudo_id),
      COUNT(*)
    ), 2
  ) AS drop_off_rate_pct

FROM first_view AS v
LEFT JOIN cart_users AS c
  ON v.user_pseudo_id = c.user_pseudo_id

GROUP BY device_category;
