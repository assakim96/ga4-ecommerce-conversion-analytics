-- GA4 데이터 탐색 실습 --
-- 이벤트수, 총 사용자 추출 --

SELECT 
  event_name,
  count(*) as event_count,
  count(distinct(user_pseudo_id)) as user_count
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE  _TABLE_SUFFIX BETWEEN '20201201' AND '20201207'
GROUP BY event_name
ORDER BY event_count DESC;

