# 웨이브 5 어휘표 — 코퍼스 실측 89종 (2026-09-21 작성, 2026-10-04 R-3 후속 정리 2 기준으로 다시 찍음 — 회사 147 · 복지 3,174행 · severance_plus 신설)

새 코드를 만들기 전에 **여기서 같은 뜻을 찾는다.** 대응 어휘가 정말 없을 때만 신규 코드(evidence 에 「신규 코드」절로 사유 — 원문이 혜택 내용을 밝힐 때만).

`n` = 이 코드를 쓴 회사 수. 대표 명칭은 코퍼스에서 가장 흔한 표기 순.

재생성은 `python3 _vocab_scan.py` — 시드 SQL 전수를 파싱해 이 표를 다시 찍는다(행 누락 0 을 스스로 증명한다).

| 코드 | n | 카테고리 | 코퍼스의 대표 명칭 |
|---|---:|---|---|
| `health_check` | 134 | health | 건강검진 · 종합건강검진 · 건강검진 지원 |
| `event` | 130 | family | 경조사 지원 · 경조사비 지원 · 경조금 지원 |
| `resort` | 125 | leisure | 휴양소 지원 · 휴양시설 · 숙박·여가 지원 |
| `child_edu` | 107 | family | 자녀 학자금 지원 · 자녀 학자금 · 자녀학자금 |
| `flex_work` | 102 | flexibility | 유연근무제 · 선택적 근로시간제 · 시차출퇴근제 |
| `welfare_point` | 102 | perks | 복지포인트 · 카페테리아 포인트 · 선택적 복리후생 포인트 |
| `meal` | 99 | perks | 사내식당 · 사내 식당 · 식대 지원 |
| `club` | 97 | leisure | 사내 동호회 · 동호회 지원 · 동호회 활동 지원 |
| `parenting` | 89 | family | 임신·출산·육아 · 임신·출산·육아 지원 · 출산/육아 지원 |
| `childcare` | 84 | family | 사내 어린이집 · 직장 어린이집 · 직장어린이집 |
| `mental` | 82 | health | 심리상담센터 · 심리상담 서비스 · 심리상담 지원 |
| `edu_support` | 80 | growth | 자기계발 지원 · 인문학 특강 · 직무 교육비 지원 |
| `fitness` | 79 | health | 사내 피트니스 · 피트니스 센터 · 피트니스센터 |
| `lang` | 79 | growth | 어학시험 응시료 · 어학 교육 · 외국어 교육 지원 |
| `housing_loan` | 76 | perks | 주택자금 대출 · 주택자금 지원 · 대출 이자 지원 |
| `medical` | 76 | health | 의료비 지원 · 의료비 지원 (본인·가족) · 가족 의료비 지원 |
| `long_service_leave` | 75 | time_off | 장기근속 포상 · 장기근속 휴가 · CREATIVE WEEK(창의휴가) |
| `commute_subsidy` | 73 | perks | 통근버스 · 출퇴근 지원 · 셔틀버스 |
| `insurance` | 72 | health | 단체상해보험 · 단체 상해보험 · 단체보험 |
| `leave_general` | 66 | time_off | 2시간 단위 휴가 · 경조휴가 · 경조휴가제 |
| `dormitory` | 62 | work_env | 기숙사 · 기숙사 지원 · 기숙사 운영 |
| `snack_bar` | 62 | perks | 사내 카페 · 사내카페 · 사내 카페테리아 |
| `incentive` | 59 | compensation | 성과급 · 성과 인센티브 · 인센티브 |
| `holiday_gift` | 58 | compensation | 명절 선물 · 명절선물 · 기념일 기념품 |
| `long_service_bonus` | 57 | compensation | 장기근속 포상 · 장기근속자 포상 · 장기근속 포상금 |
| `clinic` | 52 | health | 건강관리실 · 사내 부속의원 · 사내 병원 |
| `company_event` | 52 | leisure | 가족 초청 행사 · 가족친화 프로그램 · 송년회·사내 이벤트 |
| `discount` | 48 | perks | CJ 계열사 할인 · 제휴업체 직원 할인 · 차량구입 지원 |
| `excellence_award` | 48 | compensation | 우수사원 포상 · 포상제도 · Beyond Excellence Service 우수 서비스 직원 포상 |
| `self_development` | 44 | growth | 자격증 취득 지원 · 본인 학자금 · 자격증 응시료 지원 |
| `mba` | 43 | growth | MBA·EMBA 지원 · 국내외 학술연수 · H-MBA 핵심인재 프로그램 |
| `birthday_gift` | 42 | perks | 생일 선물 · 기념일 선물 · 기념일 선물 지원 |
| `lounge` | 36 | work_env | 휴게실 · 직원 휴게실 · 휴게 공간 |
| `remote_work` | 35 | flexibility | 재택근무 · 재택근무제 · 육아기 재택근무 |
| `career` | 33 | growth | 멘토링 제도 · 사내공모제도 · Career Growth Program |
| `fertility_support` | 33 | family | 난임 지원 · 난임 치료비 지원 · 난임 시술비 지원 |
| `transport` | 33 | perks | 교통비 지원 · 야근 교통비 · 23시 이후 퇴근 택시비 |
| `nap_room` | 31 | work_env | 모성보호실 · 모유 수유실 · 남/여 휴게실 |
| `pension_support` | 31 | perks | 개인연금 지원 · 개인연금 · New Pension |
| `summer_leave` | 27 | time_off | 하계휴가 · 하기휴가 · 여름휴가 |
| `refresh_leave` | 26 | time_off | 리프레시 휴가 · Refresh 휴가 · '쉴랜다' 리프레시 휴가 |
| `books` | 25 | growth | 도서 구입비 지원 · 사내 도서관 · 도서구입비 지원 |
| `leisure_ticket` | 23 | leisure | 티빙·CGV 이용권 · CGV 영화예매권 (연 6매) · 네이버 서비스 이용권 |
| `library` | 22 | leisure | 전자도서관 · 전자 도서관 · 만화책·보드게임 |
| `satellite_office` | 22 | flexibility | CJ Work On 거점오피스 · 거점오피스 · 거점 오피스 |
| `pc_off` | 21 | flexibility | PC-OFF 제도 · PC OFF 제도 · PC-OFF |
| `profit_sharing` | 20 | compensation | 경영성과급 · 경영성과금 · Profit Sharing |
| `welfare_fund_loan` | 20 | perks | 사내 근로복지기금 대출 · 생활안정자금 대출 · 긴급자금 융자 |
| `stock_option` | 18 | compensation | 우리사주제도 · 우리사주조합 · 우리사주 |
| `housing_support` | 17 | perks | 거주비 지원 · 사택 또는 주거지원금 · 새내기 정착·주거지원금 |
| `summer_vacation_subsidy` | 15 | leisure | 하계 휴가비 · 3주 휴가 독려 여가포인트 · 롱스테이 휴가 포인트 |
| `conference` | 14 | growth | 외부 교육 및 연수 · 교육·세미나 참석 지원 · 사외 직무교육·국내외 세미나 |
| `massage` | 14 | health | 네일케어·안마 서비스 · 네일케어룸 · 마사지 테라피 라온 |
| `relocation` | 13 | perks | 부임이사 지원 · 가재이전비·전지지원금 · 부임여비 지원 |
| `telecom` | 13 | perks | 통신비 지원 · 무과금 휴대폰 (통신비 지원) · 통신비 |
| `team_dinner` | 12 | perks | 회식비 지원 · 부서 문화행사 지원 · 부서별 문화활동 지원 (리조트부문) |
| `welcome_kit` | 12 | leisure | 웰컴키트 · Welcome Kit · 사무용품 Welcome Kit 제공 |
| `uniform` | 11 | work_env | 근무복 지급 · 근무복 지원·세탁 · 근무복·체육복 |
| `work_tools` | 11 | work_env | AI Tool 지원 · AI 도구·개인별 AI API 크레딧·업무 장비 · AI 업무 Tool 지원 |
| `birthday_leave` | 10 | time_off | 개인 기념일 휴가 · 본인 생일 반일 휴가 · 생일 당일 오후 휴가 |
| `parking` | 10 | work_env | 주차 지원 · 무료 주차장 (300대) · 사옥별 주차 지원 |
| `retirement_support` | 10 | growth | 상시 경력 전환 프로그램 (만 50세 이상 간부) · 정년 앞둔 장기근속자 공로여행 · 정년 퇴임식·기념품 |
| `sports_ticket` | 9 | leisure | LG트윈스·FC 서울 스포츠 티켓 · NC DINOS 경기 관람 지원 · SK Knights 농구 관람 지원 |
| `foundation_day_leave` | 8 | time_off | 창립기념일 휴무 · 창립기념 휴가 · 창립기념일 · 노조창립기념일 휴가 |
| `office_furniture` | 8 | work_env | 허먼밀러 의자 · 데스크테리어 비용 지원 · 모션 데스크 |
| `bonus` | 7 | compensation | 상여금 · 특별상여 (연간 3회) · 보너스(600%) |
| `family_day` | 6 | flexibility | Family Day · 가정의 날 · 스마트워킹데이 (1시간 조기 퇴근) |
| `leisure_room` | 6 | leisure | 건강한 문화 공간 · 게임존 (오껨존) · 골프 시뮬레이터 라운지 |
| `disability_family_support` | 5 | family | 발달장애 자녀 특수교육비 지원 · 장애 자녀 치료비 · 장애인 가족 지원금 |
| `free_seating` | 5 | work_env | 자율좌석제 · 자율 좌석제 · 자율좌석제 (글로벌부문) |
| `travel_support` | 5 | leisure | Global 문화체험 (해외 배낭여행 지원) · 여행비 지원 (국내·해외) · 해외 배낭여행비 지원 |
| `welfare_fund` | 5 | perks | 사내근로복지기금 · 사내 근로복지기금 운영 · 생활안정자금 지원 |
| `car_rental` | 4 | perks | 무료 전기차 대여 · 주말 업무용 차량 대여 · 캠핑카·캠핑 용품 무료 대여 |
| `culture_day` | 4 | leisure | 문화가 있는 날 · 문화의 날 · 컬쳐데이 |
| `car_wash` | 3 | perks | 세차 서비스 · 스팀 세차 서비스 카온 · 카케어 (출장 세차) |
| `promotion_gift` | 3 | perks | 승진자 식사 바우처 · 승진자 축하선물 · 호칭 변경 기념 선물 |
| `severance_plus` | 3 | compensation | 퇴직금 누진제도 · 퇴직금 누진율 (업계 최고수준) |
| `smoking_cessation` | 3 | health | 금연수당 · 금연 성공 축하금 |
| `workation` | 3 | flexibility | 워케이션 · 강릉 워케이션 |
| `overseas_safety` | 2 | health | 해외 근무자 의료·보안 지원 · 해외종합안전관리서비스 |
| `smart_office` | 2 | work_env | Smart Working Zone · 스마트오피스 |
| `stock_grant` | 2 | compensation | 자사주 지급 프로그램 · 주식 지급(Stock Grant) |
| `visa_support` | 2 | perks | 비자 발급 지원 · 비자 발급 지원 (E7) |
| `youth_savings` | 2 | compensation | 청년 내일채움공제 · 청년내일채움공제 |
| `blood_bank` | 1 | health | 혈액은행 |
| `guest_house` | 1 | leisure | 영빈관 |
| `home_security` | 1 | perks | 여직원 무인경비 지원 |
| `homecoming` | 1 | family | Home-coming 제도 |
| `parent_care` | 1 | family | 부모 요양 치료비 지원 |

## 함정 (계약 규칙 5·8-2 와 같은 효력)

- `family_day` = 조기퇴근(가족 행사는 `company_event`) · `long_service_leave` = 근속 휴가(휴가와 포상을 한 줄에 함께 적은 원문 포함 — SPEC 20 경계) · `long_service_bonus` = 휴가 없는 포상금 · 기념품 · 여행 · 원문이 휴가와 포상을 다른 항목으로 나누면 두 행 (사용자 결정 2026-10-04)
- `work_tools` = IT 장비 · `insurance` = 단체상해보험 · `pension_support` = 개인연금 지원 · `uniform` = 근무복(자율복장 아님)
- `meal` 은 끼니·단가 명시가 없으면 AMT NULL(일액은 연 환산이 아니다)
- `smart_office` = 업무 공간 / `lounge` = 휴게·카페 공간 / `satellite_office` = 거점·공유 오피스(`remote_office` 는 소멸한 코드다)
- `refresh_leave` = 연차 외에 주는 휴가(리프레시 · 안식 · 연차와 별도인 추가 휴가 — 이름만 있어도 싣는다) / `long_service_leave` = 근속 연동 휴가(휴가와 포상이 한 줄이면 이쪽) / `leave_general` = 사건 보상·집중휴가·○○데이·**연차 일수를 밝힌 문장(총량 · 가산)** (사용자 결정 2026-10-04)
- `parenting` = 자녀 양육·보육·입학 / `parent_care` = 부모 요양·돌봄 / `child_edu` = 자녀 학자금
- `welfare_point` = 포인트·복지몰 / `self_development` = 자기계발비·개인 업무 지원비
- `housing_loan` = 대출·이자 / `housing_support` = 임차비 현금 / `dormitory` = 사택·기숙사 시설 / `relocation` = 이주·정착지원금
- **`welfare_fund` = 사내근로복지기금 운영·생활안정자금 지원(원문에 대출이 없을 때) / `welfare_fund_loan` = 주거 외 용도(생활안정·긴급·의료비)이거나 용도가 적히지 않은 사내 대출 · 대출이자 지원(사내근로복지기금 대출 포함, 사용자 결정 2026-10-04)** — 원문이 대출·융자·대부를 밝히면 뒤엣것이고, 원문에 기금 낱말이 없으면 명칭·서술에 기금을 쓰지 않는다. 주택 대출과 한 라벨이면 `housing_loan`(2026-09-26 재수집 감사 — LIG 의료비 대출을 새 코드 대신 여기로)
- `summer_vacation_subsidy` = 휴가를 쓸 때 주는 현금(휴가비) — 이름과 달리 하계 한정이 아니다. 휴가를 붙여 쓸 때 주는 연중 휴가비도 이 코드(NAVER 붙여쓰면 지원금). 휴가 이름만 있고 돈이 원문의 주어가 아니면 휴가 코드
- 사원이 스스로 지원하는 사내 이동(사내공모·잡포스팅·커리어 마켓·그룹사 내부 이동)은 `career` — 회사 주도 직무순환과 온보딩 멘토링·OJT 는 행이 아니다(규칙 8, 2026-09-26 재수집 감사)
- 급여성 수당(학위·자격 수당·초임)·조직문화 담당자 역할(GWP·서포터즈)·상담실 「운영」만 있는 서술·보훈/장애 법정 의무 서술은 **행이 아니다**
- `lang` = 어학 비용 지원 **과 회사가 여는 어학 강좌 · 과정 · 전화외국어**(규칙 8) / `edu_support` = 사외 교육비 · 자기계발 · 교양 강좌 · 학습모임 지원. 신입 · 직무 필수 · 리더십 교육만 적힌 원문은 행이 아니다(사용자 결정 2026-10-04)
- 복지포인트 제도(복지카드 · 복지몰 · 선택형 · 연간 배정)는 지급 시기가 명절이어도 `welfare_point` 다. 명절 · 기념일에 선물 대신 주는 포인트(원문 이름이 선물 · 명절 포인트)는 `holiday_gift` 다. 한 회사에 둘 다 있으면 두 행이다.
- 경영성과급 · 경영성과금 · PS · 이익 배분을 **단독 제도**로 밝힌 행은 `profit_sharing` 이다. 개인 · 조직 평가 차등, 또는 PS 와 PI 를 한 줄에 함께 적은 원문은 `incentive` 다.
- 근로시간 제도: 선택 · 시차 · 자율출퇴근 · 탄력(RA-1) · 재량근로(근로기준법 58조 ③)는 `flex_work` 다. 사업장 밖 간주근로(58조 ①)는 근로시간 산정 방식이라 행이 아니다.
- 법정 신설 · 개정으로 겹치게 된 회사 휴가는 기준선을 넘는 일수 · 유급분만 「(법정 N일에 M일 추가)」로 적는다. 배우자 유산 · 사산휴가는 법정 5일 · 유급 3일이다(남녀고용평등법 제18조의4, 2026-09-18 시행).
- 퇴직금 누진제 · 누진율 등 법정 퇴직급여를 넘는 상회분은 `severance_plus`(compensation, 사용자 승인 2026-10-04). 원문이 제도 이름을 밝힐 때만 싣고 누진율 · 금액은 서술에 적되 금액 칸은 NULL.
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
- 재취업지원서비스(고령자고용법 제21조의3 — 1,000인 이상 사업주가 50세 이상 비자발적 이직예정자에게 주는 진로설계·취업 알선·재취업·창업 교육) → **법정**. 문안에서 뺀다. 대상 확대(재직 중 상시·50세 미만)·유급 휴가·퇴직 후 혜택·기념품·행사만 남긴다(2026-09-26 재수집 감사 · 코퍼스 4행 정리). 원문이 스스로 「재취업지원 서비스의 일환」이라 밝히면 그 문장 전체가 법정이다. **1,000인 미만 사업주는 노력의무(법 21조의3 ①)뿐이라 복지로 남긴다** — 직원 수(DART)를 먼저 본다.
- 법정만 담긴 행은 **지우지 않고** `generator/data/row_marks.json`(kind legal · 업무 교육 work_edu — 2026-10-04 `legal_rows.json` 에서 이름이 바뀜)에 등록 → 배지 「법정」 + 집계 제외(사용자 결정 2026-09-16).
- ⚠ **등록된 행의 `BENEFIT_NM` 을 바꾸지 마라** — `test_registry_rows_all_exist_in_seed_sql` 이 항목명 문자열로 판정해서, 이름이 바뀌면 법정 행이 조용히 다시 복지로 세어진다.
