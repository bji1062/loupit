# RESEARCH — loupit

> 이 문서는 **얇은 인덱스**다. 조사·설계 노트의 요약과 참조 파일 목록만 담는다. 상세는 각 `RESEARCH/xx.md` 파일에 있다. 여기 정리된 결정(DEC-*)은 SPEC(6단계)·데이터요구사항이 인용한다.

## 참조 파일 목록

| 파일 | 설명 | 핵심 결정 |
| --- | --- | --- |
| [RESEARCH/benefit-scraping.md](RESEARCH/benefit-scraping.md) | 회사 복지 데이터 수집·구조화·검증 전략(소스 티어링·추출 파이프라인·신뢰도·법적 안전장치·단계 실행안) | DEC-1(docs/RESEARCH 보관), DEC-2(96개 출처=official·추정금액 정직 표기) |

## 확정 결정 요약

- **DEC-1**: 복지 스크래핑 전략을 `docs/RESEARCH`에 문서화.
- **DEC-2**: 큐레이션 96개 복지 데이터는 **출처 신뢰도 = `official`**(공식 페이지 기반)로 인정하되, **앵커 추정 금액은 `amt_source=estimated`로 정직하게 별도 표기**. 출처 신뢰도(배지)와 금액 신뢰도(밴드)를 **디커플링** — PRD D3.9 정교화.
- **방향**: 3rd-party 크롤링·재게시 배제, 공식 1차 출처 + 공식 오픈 API만 → 헤드리스 + LLM 스키마 파싱. **MVP는 96 재이식 + 프리셋 폴백으로 론칭 가능**(신규 스크래핑은 2차 갱신 도구).

## 미결 이슈(발췌, 상세는 benefit-scraping.md §8)

OI-1 96↔200 교집합 · OI-3 카테고리 TTL 확정 · OI-4 bokziri 폴백 · OI-5 Phase2 시점·예산 · OI-6 amt_source 백필 규칙 · OI-7 정정요청 SLA.
