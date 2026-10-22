CREATE OR REPLACE VIEW
  `ga4-portfolio-analysis-511401.p01_mart.v_product_conversion`
AS

-- P01: GA4 상품별 장바구니 전환 데이터 마트(View) 생성
-- 사전 작업: BigQuery에서 데이터셋 p01_mart를 위치 US로 먼저 생성하세요.
-- 현재 실습 프로젝트: ga4-portfolio-analysis-511401
-- 데이터 기간: 2020-12-01 ~ 2020-12-07 (고정 스냅샷)
-- 한계: 동일 사용자/상품 최초 조회 이후 장바구니 여부만 확인.
-- 동일 세션, 상품 옵션, cross-device 일치 여부는 보장하지 않음.
-- Mart의 각 행은 상품별 집계이므로 사용자 수의 합계는 전체 고유 사용자가 아님.

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
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS e,
    UNNEST(e.items) AS i
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201207'
    AND e.event_name IN ('view_item', 'add_to_cart')
    AND e.user_pseudo_id IS NOT NULL
),
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
  COALESCE(NULLIF(i.item_category, ''), '(미분류)') AS item_category,
  p.view_users,
  p.cart_users,
  SAFE_DIVIDE(p.cart_users, p.view_users) AS cart_conversion_rate,
  p.view_users - p.cart_users AS drop_off_users,
  SAFE_DIVIDE(p.view_users - p.cart_users, p.view_users) AS drop_off_rate
FROM product_counts AS p
LEFT JOIN product_info AS i
  ON p.item_key = i.item_key
WHERE p.view_users >= 30
ORDER BY p.view_users DESC
LIMIT 30;

-- 뷰 생성 후 아래 조회 쿼리를 별도로 실행해 확인하세요.
-- SELECT * FROM `ga4-portfolio-analysis-511401.p01_mart.v_product_conversion`
-- ORDER BY view_users DESC;
