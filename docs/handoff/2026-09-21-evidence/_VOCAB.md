# 웨이브 5 어휘표 — 코퍼스 실측 90종 (2026-09-21, 회사 150 · 복지 2,451행)

새 코드를 만들기 전에 **여기서 같은 뜻을 찾는다.** 대응 어휘가 정말 없을 때만 신규 코드(evidence 에 「신규 코드」절로 사유 — 원문이 혜택 내용을 밝힐 때만).

`n` = 이 코드를 쓴 회사 수. 대표 명칭은 코퍼스에서 가장 흔한 표기 순.

재생성은 `python3 _vocab_scan.py` — 시드 SQL 전수를 파싱해 이 표를 다시 찍는다(행 누락 0 을 스스로 증명한다).

| 코드 | n | 카테고리 | 코퍼스의 대표 명칭 |
|---|---:|---|---|
| `event` | 135 | family | 경조사 지원 · 경조금 지원 · 경조사/명절 |
| `health_check` | 133 | health | 건강검진 · 종합건강검진 · 건강검진 지원 |
| `resort` | 118 | leisure | 휴양시설 · 숙박·여가 지원 · 휴양시설 지원 |
| `child_edu` | 106 | family | 자녀학자금 · 자녀 학자금 지원 · 자녀 학자금 |
| `meal` | 96 | perks | 구내식당 · 사내식당 · 식대 지원 |
| `welfare_point` | 94 | perks | 복지포인트 · 카페테리아 포인트 · 선택적 복리후생 |
| `club` | 91 | leisure | 사내 동호회 · 동호회 · 사내동호회 |
| `housing_loan` | 79 | perks | 주택자금 대출 · 주택자금 대출 지원 · 주택자금 지원 |
| `edu_support` | 77 | growth | 직무/리더십 교육 · 자기계발 지원 · 교육 프로그램 |
| `medical` | 75 | health | 의료비 지원 · 본인 의료비 지원 · 가족 의료비 보조 |
| `flex_work` | 74 | flexibility | 유연근무제 · 자율출퇴근제 · 선택적 근로시간제 |
| `fitness` | 66 | health | 피트니스센터 · 사내 피트니스 · 사내 헬스장 |
| `long_service_leave` | 64 | time_off | 장기근속 포상 · CREATIVE WEEK(창의휴가) · 장기근속 휴가 |
| `childcare` | 62 | family | 사내 어린이집 · 직장 어린이집 · CJ키즈빌(직장 어린이집) |
| `insurance` | 62 | health | 단체상해보험 · 단체 상해보험 · 단체보험 |
| `parenting` | 58 | family | 임신·출산·육아 · 출산/육아 지원 · 임신/출산/육아 지원 |
| `snack_bar` | 57 | perks | 사내 카페 · 사내 카페/간식 · 사내 카페/무인매점 |
| `commute_subsidy` | 53 | perks | 통근버스 · 출퇴근 지원 · 셔틀버스 |
| `lang` | 53 | growth | 어학시험 응시료 · 어학교육 · 외국어 교육 지원 |
| `mental` | 50 | health | 심리상담 · 심리상담 지원 · 심리상담센터 |
| `holiday_gift` | 48 | compensation | 명절 선물 · 명절 상여 · 기념일 기념품 |
| `discount` | 47 | perks | CJ 계열사 할인 · 그룹사 제품 할인 · 제휴업체 할인 |
| `dormitory` | 41 | work_env | 기숙사 · 기숙사 지원 · 사택 지원 |
| `leave_general` | 40 | time_off | 2시간 단위 휴가 · 경조휴가 · 1시간 단위 휴가 |
| `incentive` | 37 | compensation | 성과급 · 인센티브 · 성과 인센티브 |
| `long_service_bonus` | 36 | compensation | 장기근속 포상 · 장기근속자 포상 · 장기근속 포상금 |
| `excellence_award` | 35 | compensation | 우수사원 포상 · 우수/모범사원 포상 · ENM Awards |
| `refresh_leave` | 35 | time_off | 리프레시 휴가 · Refresh 휴가 · 장기근속 포상 |
| `clinic` | 34 | health | 사내 부속의원 · 건강관리실 · 사내 건강관리실 |
| `books` | 27 | growth | 사내 도서관 · 도서 구입비 지원 · 도서구입비 지원 |
| `lounge` | 25 | work_env | 직원 휴게실 · 고급 안마의자 · 공장 편의시설(휴게실·안마의자) |
| `transport` | 25 | perks | 통근버스 · 교통비 지원 · KTX 비용 지원 |
| `mba` | 24 | growth | 국내외 학술연수 · Global MBA/유학 · H-MBA 핵심인재 프로그램 |
| `remote_work` | 24 | flexibility | 재택근무 · 재택근무제 · 자율 재택근무 |
| `summer_leave` | 23 | time_off | 하계휴가 · 하기휴가 · 여름휴가 |
| `birthday_gift` | 22 | perks | 생일 선물 · 기념일 선물 · 생일포인트 |
| `self_development` | 22 | growth | 자기계발비 · 자격증 취득 지원 · 자기계발비 지원 |
| `career` | 20 | growth | 멘토링 제도 · 멘토링 프로그램 · Global Talent/지역전문가 |
| `company_event` | 19 | leisure | KB 패밀리데이 · 가정의 날 과일 선물·종무식 · 가족 초청 행사 |
| `pension_support` | 18 | perks | 개인연금 지원 · 개인연금 · 개인연금(IRP) 50% 지원 |
| `satellite_office` | 16 | flexibility | CJ Work On 거점오피스 · 거점오피스 · 거점 오피스 |
| `work_tools` | 15 | work_env | AI Tool 지원 · IT 장비 지원 · 고사양 PC 지원 |
| `leisure_ticket` | 14 | leisure | 티빙·CGV 이용권 · 문화 활동 (콘서트 초대권) · 문화생활 지원(영화티켓 등) |
| `fertility_support` | 13 | family | 난임 치료비 지원 · 난임 지원 · 난임 수술 지원 |
| `telecom` | 13 | perks | 통신비 지원 · 통신비 · 통신사 제휴 할인 |
| `parking` | 12 | work_env | 주차비 지원 · 주차장 · 주차장 제공 |
| `library` | 10 | leisure | 사내 북카페 · 전자 도서관 · 전자도서관 |
| `stock_option` | 10 | compensation | 스톡옵션 · 우리사주조합 · 우리사주제도 |
| `welcome_kit` | 10 | leisure | 웰컴키트 · Welcome Kit · 신규입사자 웰컴패키지 |
| `birthday_leave` | 9 | time_off | 본인/가족 기념일 선물+휴가 · 생일 선물+조기퇴근 · 생일 연차 휴식 |
| `housing_support` | 9 | perks | 주거 지원 · 새내기 정착/주거지원금 · 숙소임차비용 지원 |
| `nap_room` | 9 | work_env | 남/여 휴게실 · 릴렉스룸 · 사내 수면실/샤워실 |
| `pc_off` | 9 | flexibility | PC-OFF 제도 · PC OFF 제도 · PC OFF제 |
| `family_day` | 8 | flexibility | 가정의 날 · 패밀리데이 · 가족의 날 조기 퇴근 |
| `relocation` | 8 | perks | 부임여비 지원 · 부임이사 지원 · 사택/정착지원금 |
| `massage` | 7 | health | 마사지 테라피 라온(RA-ON) · 마사지(사이다룸) · 사내 마사지룸 |
| `conference` | 6 | growth | 교육·세미나 참석 지원 · 세미나/컨퍼런스 · 외부 교육/컨퍼런스 |
| `profit_sharing` | 6 | compensation | PS (Profit Sharing) · 경영성과금 · 부가급여(Profit Sharing System) |
| `bonus` | 5 | compensation | 상여금 · 보너스(600%) · 성과급 |
| `foundation_day_leave` | 4 | time_off | 창립기념일 휴무 · 창립기념 휴가 · 창립기념일 휴가 |
| `sports_ticket` | 4 | leisure | SSG랜더스 홈경기 혜택 · 스포츠 티켓 · 스포츠경기 관람권 |
| `uniform` | 4 | work_env | 근무복 지원·세탁 · 유니폼 제공 · 유니폼·복장 |
| `culture_day` | 3 | leisure | 문화가 있는 날 · 문화의 날 · 컬쳐데이 |
| `retirement_support` | 3 | growth | 정년퇴직자·퇴직예정자 지원 · 퇴직자 재취업 지원 · 퇴직자 지원 제도 |
| `summer_vacation_subsidy` | 3 | leisure | 하계 휴가비 · 하계휴가비 · 하계휴양비(체력단련비) |
| `team_dinner` | 3 | perks | 부서 문화행사 지원 · 팀 회식비 지원 · 회식비 지원 |
| `travel_support` | 3 | leisure | 해외 배낭여행비 지원 · 해외여행 지원 · 휴양프로그램 |
| `welfare_fund_loan` | 3 | perks | 사내 근로복지기금 대출 · 사내근로복지기금 대출 |
| `free_seating` | 2 | work_env | 자율좌석제 |
| `office_furniture` | 2 | work_env | 데스크테리어 비용 지원 · 인체공학 사무가구 |
| `smart_office` | 2 | work_env | Smart Working Zone · 스마트오피스 |
| `smoking_cessation` | 2 | health | 금연 성공 축하금 · 금연수당 |
| `welfare_fund` | 2 | perks | 사내 근로복지기금 운영 · 생활안정자금 지원 |
| `blood_bank` | 1 | health | 혈액은행 |
| `car_rental` | 1 | perks | 무료 전기차 대여 |
| `car_wash` | 1 | perks | 세차 서비스 |
| `disability_family_support` | 1 | family | 장애인 가족 지원금 |
| `guest_house` | 1 | leisure | 영빈관 |
| `home_security` | 1 | perks | 여직원 무인경비 지원 |
| `homecoming` | 1 | family | Home-coming 제도 |
| `leisure_room` | 1 | leisure | 카지노룸 |
| `long_service` | 1 | time_off | 장기근속 포상 |
| `overseas_safety` | 1 | health | 해외종합안전관리서비스 |
| `parent_care` | 1 | family | 부모 요양 치료비 |
| `promotion_gift` | 1 | perks | 호칭 변경 기념 선물 |
| `stock_grant` | 1 | compensation | 전 직원 주식 부여 |
| `visa_support` | 1 | perks | 비자 발급 지원 |
| `wedding` | 1 | family | 결혼 축하금+휴가 |
| `workation` | 1 | flexibility | 워케이션 |
| `youth_savings` | 1 | compensation | 청년내일채움공제 |

## 함정 (계약 규칙 5·8-2 와 같은 효력)

- `family_day` = 조기퇴근(가족 행사는 `company_event`) · `long_service_leave` = 휴가만(포상금은 `long_service_bonus`)
- `work_tools` = IT 장비 · `insurance` = 단체상해보험 · `pension_support` = 개인연금 지원 · `uniform` = 근무복(자율복장 아님)
- `meal` 은 끼니·단가 명시가 없으면 AMT NULL(일액은 연 환산이 아니다)
- `smart_office` = 업무 공간 / `lounge` = 휴게·카페 공간 / `satellite_office` = 거점·공유 오피스(`remote_office` 는 소멸한 코드다)
- `refresh_leave` = 조건 없는 추가 휴가 / `long_service_leave` = 근속 연동 / `leave_general` = 사건 보상·집중휴가·○○데이
- `parenting` = 자녀 양육·보육·입학 / `parent_care` = 부모 요양·돌봄 / `child_edu` = 자녀 학자금
- `welfare_point` = 포인트·복지몰 / `self_development` = 자기계발비·개인 업무 지원비
- `housing_loan` = 대출·이자 / `housing_support` = 임차비 현금 / `dormitory` = 사택·기숙사 시설 / `relocation` = 이주·정착지원금
- **`welfare_fund` = 사내근로복지기금 운영·생활안정자금 / `welfare_fund_loan` = 그 기금의 대출**(웨이브 4 에서 갈라진 두 코드다 — 대출이면 뒤엣것)
- 급여성 수당(학위·자격 수당·초임)·조직문화 담당자 역할(GWP·서포터즈)·상담실 「운영」만 있는 서술·보훈/장애 법정 의무 서술은 **행이 아니다**
- 스톡옵션은 복지가 아니다(경영진 재량 선별) · **우리사주조합은 전원 대상이라 남기되, 코퍼스 실제 코드는 `stock_option` 이다**(루닛·에스티팜 선례 — `employee_stock` 은 코퍼스에 없는 코드다, 2026-09-20 정정)

## 카테고리는 9칸 고정 — 새 서랍은 못 만든다

`compensation · flexibility · work_env · time_off · health · family · growth · leisure · perks`
(정본 순서 = `generator/pages/company.py` `CATEGORY_ORDER`. 9각형 그래프·카테고리 집계가 이 9개를 축으로 쓴다.)

⚠ **한 코드는 한 카테고리에만 넣는다.** 표의 카테고리가 정본이다.

수집 계약은 「카테고리 ∈ 9개」만 정하고 코드↔카테고리 1:1 을 못 박지 않았다. 그래서 2026-09-21 이전에는 같은 코드가 회사마다 다른 축에 들어간 것이 **6종 · 28행 · 25개 회사** 있었다(「명절 선물」이 7곳은 compensation, 4곳은 perks — 같은 복지가 다른 축으로 세어졌다).

**데이터 정리 2차에서 전부 통일했다**(2026-09-21, 30행 재코딩 + 1행 삭제 — `db/migrations/20260921_data_cleanup_2.sql`).

⚠ 위의 **28행**과 아래 **30+1행**은 어긋난 수치가 아니다. 28은 「다수결 기준 소수파」이고, `massage` 의 정본을 **소수파인 health 로 뒤집었기 때문에**(사용자 결정) 대상이 leisure 5행으로 바뀌어 31행이 됐다 — 28 − 2 + 5 = 31 = 재코딩 30 + 삭제 1.

확정된 정본:

| 코드 | 정본 | 근거 |
|---|---|---|
| `holiday_gift` | compensation | 다수(33행) · 「명절 상여금」 등 현금성이 섞여 있다 |
| `work_tools` | work_env | 업무 장비는 근무환경 |
| `parking` | work_env | 주차장·주차비는 근무환경 시설 |
| `family_day` | flexibility | 조기퇴근 = 근무 유연성 |
| `massage` | **health** | 사용자 결정 — 다수는 leisure 였으나 건강관리 성격을 따랐다 |
| `welcome_kit` | leisure | 입사 선물 **물품**. 휴젤의 「온보딩 프로그램」 행은 뜻이 달라 삭제했다 |

지금 코퍼스의 분열은 **0종**이다(`_vocab_scan.py` 가 매번 확인한다). 새 회사를 넣을 때 표의 카테고리 열을 그대로 쓸 것 — 여기서 갈리면 9각형 비교가 다시 오염된다.

## 법정 제도 판정선 (2026-09-20 확정)

- 연차 · 반차 → **법정**. 문안에서 제거한다(모든 회사가 준다).
- 반반차(2시간 단위) · 회사가 밝힌 시간 단위 → **복지**. 단 내부 낱말 「반반차」를 화면에 쓰지 않고 **「2시간 단위 휴가」**로 적는다.
- 법정만 담긴 행은 **지우지 않고** `generator/data/legal_rows.json` 에 등록 → 배지 「법정」 + 집계 제외(사용자 결정 2026-09-16). 현재 13행 / 12사.
- ⚠ **등록된 행의 `BENEFIT_NM` 을 바꾸지 마라** — `test_legal_rows_all_exist_in_seed_sql` 이 항목명 문자열로 판정해서, 이름이 바뀌면 법정 행이 조용히 다시 복지로 세어진다.
