
-- DAY 1: GA4 이벤트 데이터 탐색

SELECT
  event_name,
  COUNT(*) AS event_count,
  COUNT(DISTINCT user_pseudo_id) AS user_count
FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE
  _TABLE_SUFFIX BETWEEN '20201201' AND '20201207'
GROUP BY
  event_name
ORDER BY
  event_count DESC;
