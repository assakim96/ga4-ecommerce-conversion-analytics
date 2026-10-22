
-- P01 DAY 4: 상품별 장바구니 전환율 분석
-- 분석 기간: 2020.12.01 ~ 2020.12.07
-- 사용자 + 상품 기준 순차 전환

WITH item_events AS (
  SELECT
    e.user_pseudo_id,
    e.event_name,
    e.event_timestamp,
    COALESCE(
      CONCAT('id:', NULLIF(i.item_id, '')),
      CONCAT('name:', NULLIF(i.item_name, ''))
    ) AS item_key,
    i.item_name,
    i.item_category
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS e,
    UNNEST(e.items) AS i
  WHERE
    _TABLE_SUFFIX BETWEEN '20201201' AND '20201207'
    AND e.event_name IN ('view_item', 'add_to_cart')
    AND e.user_pseudo_id IS NOT NULL
),

-- STEP 1: 사용자별 상품 최초 조회 시점
first_views AS (
  SELECT
    user_pseudo_id,
    item_key,
    MIN(event_timestamp) AS first_view_ts
  FROM item_events
  WHERE event_name = 'view_item'
    AND item_key IS NOT NULL
  GROUP BY user_pseudo_id, item_key
),

-- STEP 2: 같은 상품을 조회한 이후 장바구니에 담았는지
cart_users AS (
  SELECT DISTINCT
    v.user_pseudo_id,
    v.item_key
  FROM first_views AS v
  JOIN item_events AS e
    ON v.user_pseudo_id = e.user_pseudo_id
    AND v.item_key = e.item_key
    AND e.event_name = 'add_to_cart'
    AND e.event_timestamp > v.first_view_ts
),

-- STEP 3: 상품별 사용자 수 집계
product_counts AS (
  SELECT
    v.item_key,
    COUNT(*) AS view_users,
    COUNTIF(c.user_pseudo_id IS NOT NULL) AS cart_users
  FROM first_views AS v
  LEFT JOIN cart_users AS c
    ON v.user_pseudo_id = c.user_pseudo_id
    AND v.item_key = c.item_key
  GROUP BY v.item_key
),

-- STEP 4: 상품명과 카테고리 연결
product_info AS (
  SELECT
    item_key,
    ANY_VALUE(item_name) AS item_name,
    ANY_VALUE(item_category) AS item_category
  FROM item_events
  WHERE item_key IS NOT NULL
  GROUP BY item_key
)

SELECT
  p.item_key,
  COALESCE(i.item_name, p.item_key) AS item_name,
  i.item_category,
  p.view_users,
  p.cart_users,

  ROUND(
    100 * SAFE_DIVIDE(p.cart_users, p.view_users),
    2
  ) AS cart_conversion_rate_pct,

  p.view_users - p.cart_users AS drop_off_users,

  ROUND(
    100 * SAFE_DIVIDE(
      p.view_users - p.cart_users,
      p.view_users
    ),
    2
  ) AS drop_off_rate_pct

FROM product_counts AS p
LEFT JOIN product_info AS i
  ON p.item_key = i.item_key

-- 조회 사용자 30명 이상 상품만 비교
WHERE p.view_users >= 30

ORDER BY p.view_users DESC
LIMIT 30;
