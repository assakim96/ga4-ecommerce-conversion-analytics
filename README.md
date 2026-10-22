# GA4 E-Commerce Conversion Analytics

**GA4 · BigQuery · SQL · Looker Studio · Google Sheets**

> Google에서 제공하는 GA4 이커머스 공개 샘플 데이터로 구매 전환 퍼널을 분석하고, 분석용 BigQuery VIEW와 Looker Studio 대시보드를 구축하는 개인 사이드 프로젝트입니다.

## 프로젝트 개요

- **목적:** 사용자 구매 여정에서 전환이 저조한 단계를 발견하고, 기기 및 상품별 성과 차이를 분석해 추가 검증할 가설을 도출합니다.
- **데이터:** `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
- **분석 기간:** 2020-12-01 ~ 2020-12-07
- **진행 방식:** 개인 프로젝트 / 공개·비식별화 샘플 데이터 사용
- **진행 상태:** 분석 및 데이터 마트 구축 완료, 대시보드 구성 진행 중

## 주요 분석 결과

| 지표 | 분석 결과 |
|---|---:|
| 상품 조회 사용자 | 6,780명 |
| 장바구니 단계 도달 사용자 | 2,216명 |
| 결제 시작 단계 도달 사용자 | 864명 |
| 순차 구매 완료 사용자 | 430명 |
| 상품 조회 대비 순차 구매 전환율 | **6.34%** |
| 상품 조회 → 장바구니 미전환율 | **67.32%** |

- **기기 비교:** 모바일 33.40%, 데스크톱 32.14%로 장바구니 전환율 차이는 **1.26%p**였습니다. 이 차이만으로 UX 문제가 있다고 단정하지 않습니다.
- **상품 분석:** 상품별 조회 규모와 장바구니 전환율을 비교해 추가 조사가 필요한 상품을 추렸습니다.

> **해석 주의:** 순차 퍼널은 `user_pseudo_id`를 기준으로 지정 기간 내 이벤트 발생 순서를 검사합니다. 동일 세션·동일 상품으로 한정한 퍼널이 아니며, 여기서의 미전환은 실제 사이트 이탈 또는 개선 효과를 의미하지 않습니다.

## 데이터 처리 구조

```text
Google GA4 공개 샘플 데이터
          ↓
BigQuery SQL 분석 (sql/)
          ↓
BigQuery VIEW 데이터 마트 (mart/)
          ↓  CSV 수동 추출
Google Sheets
          ↓
Looker Studio 대시보드 (dashboard/)
```

**데이터 마트:** `v_product_conversion`, `v_funnel_conversion`, `v_device_conversion` (VIEW 기반). **예약 쿼리 자동화는 구현하지 않았습니다.**

## 분석 코드

| 파일 | 내용 |
|---|---|
| [`sql/01_event_overview.sql`](sql/01_event_overview.sql) | 이벤트별 발생 횟수 및 고유 사용자 수 |
| [`sql/02_conversion_funnel.sql`](sql/02_conversion_funnel.sql) | 사용자 기준 순차 구매 전환 퍼널 |
| [`sql/03_device_conversion.sql`](sql/03_device_conversion.sql) | 기기별 상품 조회 → 장바구니 전환 비교 |
| [`sql/04_product_conversion.sql`](sql/04_product_conversion.sql) | 사용자·상품 기준 장바구니 전환 분석 |

BigQuery에서 공개 데이터에 접근할 수 있는 프로젝트를 선택하고 각 쿼리를 실행할 수 있습니다. 분석 기간은 SQL의 `_TABLE_SUFFIX` 조건에서 변경합니다.

## 대시보드

Looker Studio에서 **퍼널 / 기기별 성과 / 상품별 성과** 3개 화면을 제작하고 있습니다. 완성 및 검수 후 링크와 캡처를 추가할 예정입니다.

## 한계 및 향후 과제

- 공개된 과거 샘플 데이터이므로 현재 운영 사이트의 성과를 의미하지 않습니다.
- VIEW는 조회 시 쿼리를 다시 실행합니다. 현재 보고서는 CSV·Google Sheets를 사용한 **정적 스냅샷**이며 자동 갱신 파이프라인이 아닙니다.
- 전환율 차이의 원인을 판단하려면 유입 경로, 상품 가격·재고, 세션 기준 분석, 데이터 수집 품질 등을 추가 검증해야 합니다.

**포트폴리오 용도:** 데이터 추출 → 지표 정의 → SQL 분석 → VIEW 데이터 마트 → 시각화 → 개선 가설 도출 과정을 재현 가능하게 기록합니다.


Looker Studio


Project Overview

GA4 공개 이커머스 데이터를 활용해 사용자 전환 퍼널, 기기별 전환율, 상품별 전환 성과를 분석한 개인 프로젝트.

Key Findings
- 상품 조회 대비 순차 구매 전환율: 6.34%
- 상품 조회 → 장바구니 미전환율: 67.32%
- 기기별 전환율 및 상품별 개선 검토 대상 도출
Data Pipeline
GA4 Sample Data

BigQuery SQL

Data Mart (VIEW)

Google Sheets → Looker Studio
