# 웨이브 5 어휘표 — 코퍼스 실측 89종 (2026-10-10 재생성 · 회사 147 · 복지 3,179행)

새 코드를 만들기 전에 **여기서 같은 뜻을 찾는다.** 대응 어휘가 정말 없을 때만 신규 코드(근거표 「신규 코드」 절 — 수집 계약 규칙 5).
**카테고리 열은 정본이다** — 코드가 표에 있으면 그 카테고리를 그대로 베낀다(수집 계약 2-3).

- 재생성: `python3 -I /home/ubuntu/loupit-evidence/2026-10-10-wave5/_vocab_scan.py` — 리포 `docs/handoff/2026-09-21-evidence/_vocab_scan.py` 의 사본이고, 리포 밖에서 돌리려고 시드 경로만 절대경로(`/home/ubuntu/loupit/db/seed/benefit/sql`)로 바꿨다. 파싱 · 표 로직은 원본 그대로다.
- 이번 실행(2026-10-10, 리포 `main` = `ab47ce6`): **회사 147 · 복지 3,179행 · 코드 89종 · 파서가 놓친 줄 0(전수 파싱 증명) · 카테고리 분열 0종.** 3,179 = 서빙 복지 행 수 핀(`server/tests/test_seed_counts.py` SD-4)과 같다. 전체 출력은 `W5/_vocab_scan.out.txt`.
- 09-21 판(10-04 재생성 · 3,174행) 대비: 코드 종류 · 카테고리 변화 없음. n 만 움직였다(10-04 ~ 10-08 데이터 정리 — `edu_support` 80 → 85 · `lang` 79 → 82 · `welfare_point` 102 → 103 · `excellence_award` · `discount` +1 · `welfare_fund_loan` · `welfare_fund` · `retirement_support` +1 · `resort` · `club` · `medical` · `long_service_leave` · `commute_subsidy` · `lounge` · `remote_work` · `refresh_leave` · `foundation_day_leave` −1).

`n` = 이 코드를 쓴 회사 수. 대표 명칭은 코퍼스에서 가장 흔한 표기 순(동률은 이름순).

| 코드 | n | 카테고리 | 코퍼스의 대표 명칭 |
|---|---:|---|---|
| `health_check` | 134 | health | 건강검진 · 종합건강검진 · 건강검진 지원 |
| `event` | 130 | family | 경조사 지원 · 경조사비 지원 · 경조금 지원 |
| `resort` | 124 | leisure | 휴양소 지원 · 휴양시설 · 숙박·여가 지원 |
| `child_edu` | 107 | family | 자녀 학자금 지원 · 자녀 학자금 · 자녀학자금 |
| `welfare_point` | 103 | perks | 복지포인트 · 카페테리아 포인트 · 선택적 복리후생 포인트 |
| `flex_work` | 102 | flexibility | 유연근무제 · 선택적 근로시간제 · 시차출퇴근제 |
| `meal` | 99 | perks | 사내식당 · 사내 식당 · 식대 지원 |
| `club` | 96 | leisure | 사내 동호회 · 동호회 지원 · 동호회 활동 지원 |
| `parenting` | 89 | family | 임신·출산·육아 · 임신·출산·육아 지원 · 출산/육아 지원 |
| `edu_support` | 85 | growth | 자기계발 지원 · 인문학 특강 · 직무 교육비 지원 |
| `childcare` | 84 | family | 사내 어린이집 · 직장 어린이집 · 직장어린이집 |
| `lang` | 82 | growth | 어학시험 응시료 · 어학 교육 · 외국어 교육 지원 |
| `mental` | 82 | health | 심리상담센터 · 심리상담 서비스 · 심리상담 지원 |
| `fitness` | 79 | health | 사내 피트니스 · 피트니스 센터 · 피트니스센터 |
| `housing_loan` | 76 | perks | 주택자금 대출 · 주택자금 지원 · 대출 이자 지원 |
| `medical` | 75 | health | 의료비 지원 · 의료비 지원 (본인·가족) · 가족 의료비 지원 |
| `long_service_leave` | 74 | time_off | 장기근속 포상 · 장기근속 휴가 · CREATIVE WEEK(창의휴가) |
| `commute_subsidy` | 72 | perks | 통근버스 · 출퇴근 지원 · 셔틀버스 |
| `insurance` | 72 | health | 단체상해보험 · 단체 상해보험 · 단체보험 |
| `leave_general` | 66 | time_off | 2시간 단위 휴가 · 경조휴가 · 경조휴가제 |
| `dormitory` | 62 | work_env | 기숙사 · 기숙사 지원 · 기숙사 운영 |
| `snack_bar` | 62 | perks | 사내 카페 · 사내카페 · 사내 카페테리아 |
| `incentive` | 59 | compensation | 성과급 · 성과 인센티브 · 인센티브 |
| `holiday_gift` | 58 | compensation | 명절 선물 · 명절선물 · 기념일 기념품 |
| `long_service_bonus` | 57 | compensation | 장기근속 포상 · 장기근속자 포상 · 장기근속 포상금 |
| `clinic` | 52 | health | 건강관리실 · 사내 부속의원 · 사내 병원 |
| `company_event` | 52 | leisure | 가족 초청 행사 · 가족친화 프로그램 · 송년회·사내 이벤트 |
| `discount` | 49 | perks | CJ 계열사 할인 · 제휴업체 직원 할인 · 차량구입 지원 |
| `excellence_award` | 49 | compensation | 우수사원 포상 · 포상제도 · Beyond Excellence Service 우수 서비스 직원 포상 |
| `self_development` | 44 | growth | 자격증 취득 지원 · 본인 학자금 · 자격증 응시료 지원 |
| `mba` | 43 | growth | MBA·EMBA 지원 · 국내외 학술연수 · H-MBA 핵심인재 프로그램 |
| `birthday_gift` | 42 | perks | 생일 선물 · 기념일 선물 · 기념일 선물 지원 |
| `lounge` | 35 | work_env | 휴게실 · 직원 휴게실 · 휴게 공간 |
| `remote_work` | 34 | flexibility | 재택근무 · 재택근무제 · 육아기 재택근무 |
| `career` | 33 | growth | 멘토링 제도 · 사내공모제도 · Career Growth Program |
| `fertility_support` | 33 | family | 난임 지원 · 난임 치료비 지원 · 난임 시술비 지원 |
| `transport` | 33 | perks | 교통비 지원 · 야근 교통비 · 23시 이후 퇴근 택시비 |
| `nap_room` | 31 | work_env | 모성보호실 · 모유 수유실 · 남/여 휴게실 |
| `pension_support` | 31 | perks | 개인연금 지원 · 개인연금 · New Pension |
| `summer_leave` | 27 | time_off | 하계휴가 · 하기휴가 · 여름휴가 |
| `books` | 25 | growth | 도서 구입비 지원 · 사내 도서관 · 도서구입비 지원 |
| `refresh_leave` | 25 | time_off | 리프레시 휴가 · Refresh 휴가 · '쉴랜다' 리프레시 휴가 |
| `leisure_ticket` | 23 | leisure | 티빙·CGV 이용권 · CGV 영화예매권 (연 6매) · 네이버 서비스 이용권 |
| `library` | 22 | leisure | 전자도서관 · 전자 도서관 · 만화책·보드게임 |
| `satellite_office` | 22 | flexibility | CJ Work On 거점오피스 · 거점오피스 · 거점 오피스 |
| `pc_off` | 21 | flexibility | PC-OFF 제도 · PC OFF 제도 · PC-OFF |
| `welfare_fund_loan` | 21 | perks | 사내 근로복지기금 대출 · 생활안정자금 대출 · 긴급자금 융자 |
| `profit_sharing` | 20 | compensation | 경영성과급 · 경영성과금 · Profit Sharing |
| `stock_option` | 18 | compensation | 우리사주제도 · 우리사주조합 · 우리사주 |
| `housing_support` | 17 | perks | 거주비 지원 · 사택 또는 주거지원금 · 새내기 정착·주거지원금 |
| `summer_vacation_subsidy` | 15 | leisure | 하계 휴가비 · 3주 휴가 독려 여가포인트 · 롱스테이 휴가 포인트 |
| `conference` | 14 | growth | 외부 교육 및 연수 · 교육·세미나 참석 지원 · 사외 직무교육·국내외 세미나 |
| `massage` | 14 | health | 네일케어·안마 서비스 · 네일케어룸 · 마사지 테라피 라온 |
| `relocation` | 13 | perks | 부임이사 지원 · 가재이전비·전지지원금 · 부임여비 지원 |
| `telecom` | 13 | perks | 통신비 지원 · 무과금 휴대폰 (통신비 지원) · 통신비 |
| `team_dinner` | 12 | perks | 회식비 지원 · 부서 문화행사 지원 · 부서별 문화활동 지원 (리조트부문) |
| `welcome_kit` | 12 | leisure | 웰컴키트 · Welcome Kit · 사무용품 Welcome Kit 제공 |
| `retirement_support` | 11 | growth | 상시 경력 전환 프로그램 (만 50세 이상 간부) · 정년 앞둔 장기근속자 공로여행 · 정년 퇴임식·기념품 |
| `uniform` | 11 | work_env | 근무복 지급 · 근무복 지원·세탁 · 근무복·체육복 |
| `work_tools` | 11 | work_env | AI Tool 지원 · AI 도구·개인별 AI API 크레딧·업무 장비 · AI 업무 Tool 지원 |
| `birthday_leave` | 10 | time_off | 개인 기념일 휴가 · 본인 생일 반일 휴가 · 생일 당일 오후 휴가 |
| `parking` | 10 | work_env | 주차 지원 · 무료 주차장 (300대) · 사옥별 주차 지원 |
| `sports_ticket` | 9 | leisure | LG트윈스·FC 서울 스포츠 티켓 · NC DINOS 경기 관람 지원 · SK Knights 농구 관람 지원 |
| `office_furniture` | 8 | work_env | 허먼밀러 의자 · 데스크테리어 비용 지원 · 모션 데스크 |
| `bonus` | 7 | compensation | 상여금 · 특별상여 (연간 3회) · 보너스(600%) |
| `foundation_day_leave` | 7 | time_off | 창립기념일 휴무 · 창립기념일 · 노조창립기념일 휴가 · 창립기념일 대체 유급 휴가 (12월 26일) |
| `family_day` | 6 | flexibility | Family Day · 가정의 날 · 스마트워킹데이 (1시간 조기 퇴근) |
| `leisure_room` | 6 | leisure | 건강한 문화 공간 · 게임존 (오껨존) · 골프 시뮬레이터 라운지 |
| `welfare_fund` | 6 | perks | 사내근로복지기금 · 사내 근로복지기금 운영 · 생활안정자금 지원 |
| `disability_family_support` | 5 | family | 발달장애 자녀 특수교육비 지원 · 장애 자녀 치료비 · 장애인 가족 지원금 |
| `free_seating` | 5 | work_env | 자율좌석제 · 자율 좌석제 · 자율좌석제 (글로벌부문) |
| `travel_support` | 5 | leisure | Global 문화체험 (해외 배낭여행 지원) · 여행비 지원 (국내·해외) · 해외 배낭여행비 지원 |
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

⚠ 대표 명칭의 「'쉴랜다' 리프레시 휴가」는 옛 행(CJ ENM 커머스부문)의 표기다. 새 행 이름 · 서술에는 홑 · 겹따옴표를 쓰지 않는다(분할기) — 「」를 쓴다.

## 함정 (수집 계약 규칙 5 · 8-2 와 같은 효력 — 출처는 괄호)

**휴가**
- `refresh_leave` = 연차 **외에** 주는 휴가(리프레시 · Refresh · 재충전 · 안식 · 연차와 별도인 추가 휴가). 이름만 있어도 싣는다(사용자 결정 2026-10-04). 근속 연동이면 `long_service_leave`. 원문이 **본인 연차를 쓰는 것**이라고 밝히면 법정이라 싣지 않는다(R-3 기준 31).
- `long_service_leave` = 근속 연동 휴가(휴가와 포상을 한 줄에 함께 적은 원문 포함 — SPEC 20 경계) · `long_service_bonus` = 휴가 없는 포상금 · 기념품 · 여행. 원문이 휴가와 포상을 다른 항목으로 나누면 두 행(사용자 결정 2026-10-04).
- `leave_general` = 사건 보상(출장 · 심야근무 보상) · 이름 있는 집중 · 단체 휴무 · 「○○데이」 · **연차 일수를 밝힌 문장(총량 「연간 휴가 총 N일」 · 가산 「법정보다 N일 추가」)** · 그 밖에 전용 코드가 없는 회사 재량 휴가(병가 · 인병휴가 등)(웨이브 4 감사 §10 ② · R-3 후속 PR2-SURVEY-v2 §5-5 · §5-7).
- `summer_leave` = 「하계 · 하기 · 여름」 이름의 휴가에 회사가 일수를 더 주는 것(R-3 기준 23 · 묶음 4 현대오토에버 판정). `summer_vacation_subsidy` = 휴가를 쓸 때 주는 **현금**(휴가비) — 이름과 달리 하계 한정이 아니다(NAVER 붙여쓰면 지원금). 돈이 원문의 주어가 아니면 휴가 코드.
- `foundation_day_leave` = 창립기념일 휴무 · `birthday_leave` = 생일 휴가(반일 포함 — 화면에 「반차」 대신 「반일」) · 생일 선물은 `birthday_gift`(R-3 묶음 7 네오위즈 재코딩).
- 반반차 · 회사가 밝힌 시간 단위 연차 쪼개 쓰기 = `leave_general` 「2시간 단위 휴가」(사용자 결정 2026-09-20 — 화면에 「반반차」를 쓰지 않는다).
- 적립휴가 · 보상휴가(초과근무 시간을 휴가로 바꾸는 장치) = 휴가 행이 아니라 `flex_work` 서술(웨이브 4 감사 §10 ②). 선택근로 안에서 주는 월 1회 휴무(Happy Friday 등)도 `flex_work` 서술(R-3 기준 21).
- `family_day` = 조기퇴근(가족 행사는 `company_event`).

**근무 유연성**
- 근로시간 제도: 선택 · 시차 · 자율출퇴근 · 탄력 · 재량근로(근로기준법 58조 ③) = `flex_work`. 사업장 밖 간주근로(58조 ①)는 산정 방식이라 행이 아니다(PR2-SURVEY-v2 §5-9). 시차출퇴근 · 선택근로는 **법정이 아니다**(웨이브 4 리드 오류 · 감사 B-1).
- `remote_work` · `telecommute` · `wfh` · `flex_work` · `refresh_leave` · `long_service_leave` 행이 전 직원 제도가 아니면 한정을 **이름**의 정해진 꼴로 적는다(수집 계약 규칙 13 · SI-13d).
- `smart_office` = 업무 공간(스마트워크존) / `satellite_office` = 거점 · 공유 오피스(`remote_office` 는 소멸한 코드다).

**보상 · 금전**
- 경영성과급 · 경영성과금 · PS · 이익 배분을 **단독 제도**로 밝힌 행 = `profit_sharing`. 개인 · 조직 평가 차등, 또는 PS 와 PI 를 한 줄에 함께 적은 원문 = `incentive`(PR2-SURVEY-v2 §5-9). 「임직원」 · 「전 직원」 성과금 · 인센티브 문장 · 직군 한정 성과급 · 공고 급여 칸 「성과급 내부 규정에 따라 지급」 · 재무제표 주석 「종업원에게 지급할 성과급」 · 기관 공시 평균보수 표 성과상여금 · 「모든 임직원」 안전장려금 = `incentive`(R-3 기준 20 · 27 · 35 · 리드 판정 ㊹ · ㊾ · ㊿). 임원 · 사내이사 전용 보수 문장은 아니다(기준 17).
- `bonus` = 회사가 **복리후생 블록 안에** 적은 정기 상여율(「상여금 연 800%」 · 「특별상여 연 3회」) — 금액 칸 NULL. 근무환경 · 임금 구성 문장(「임금은 기본급, 제수당, 명절 상여로 구성」)은 행이 아니다(재수집 R-1 감사 §2-2 · §2-4).
- `holiday_gift` = 명절 선물 · 명절 상여금 · 귀성(귀향)여비 · 명절 상품권 · 창립기념일 · 노동절 기념품(날의 급부 — 웨이브 4 감사 §10 ①). 명절 · 기념일에 선물 대신 주는 포인트도 `holiday_gift`, 연간 배정 복지포인트 제도는 지급 시기가 명절이어도 `welfare_point` — 한 회사에 둘 다 있으면 두 행(PR2-SURVEY-v2 §5-9).
- `excellence_award` = 회사 포상 제도(라벨만 있어도 — R-1 감사 §2-2). **아닌 것:** 인재추천 포상금(채용 보상 — 리드 판정 ⑦) · 안전 · EHS 포상(안전관리 수단 — R-3 기준 30) · 「직무발명 보상(제도)」(발명진흥법 15조 법정 — 기준 34). 회사 포상 제도 안의 「특허 · 제안 · 직무발명 포상」은 `excellence_award` 서술.
- `stock_option` = **우리사주조합**(전원 대상 — 코퍼스 실제 코드). 스톡옵션 · RSU 처럼 경영진 · 핵심인력에게 재량으로 고르는 부여는 복지가 아니다(웨이브 4 추가 규칙 · 루닛 REFUTED). 공시 주주 현황 표의 「우리사주조합 N주」 한 칸만으로는 세우지 않는다(리드 판정 ㊼).
- `stock_grant` = 직원에게 자사주를 지급하는 제도(공시가 직원 대상이라고 밝힐 때 — 처분 총액은 1인당 금액이 아니다, R-1 감사 계약 L5).
- `severance_plus` = 퇴직금 누진제 · 누진율 등 법정 퇴직급여를 넘는 부분(compensation, 사용자 승인 2026-10-04). 제도 이름이 원문에 있을 때만, 누진율은 서술에, 금액 칸 NULL.
- 급여성 수당(학위 · 자격 수당 · 초임 · 직무 수당 · 무사고 운전 수당)은 행이 아니다(규칙 8-2 · 웨이브 4 JYP).

**생활 · 금융 · 주거**
- `welfare_point` = 포인트 · 복지카드 · 복지몰 · 선택적 복리후생비(직급별 정액 통합복리후생비 포함 — 웨이브 4 감사 §3-2) / 자기계발비 · 개인 업무 지원비는 `self_development`(growth).
- `housing_loan` = 주택 구입 · 전세 · 임차 대출 · 이자 / `housing_support` = 임차비 · 주거비 **현금** / `dormitory` = 사택 · 기숙사 · 숙소 **시설** / `relocation` = 이주 · 정착지원금 · 부임 이사.
- `welfare_fund` = 사내근로복지기금 운영 · 생활안정자금 지원(원문에 대출이 없을 때) / `welfare_fund_loan` = 주거 외 용도(생활안정 · 긴급 · 의료비)이거나 **용도가 적히지 않은** 사내 대출 · 대출이자 지원(사내근로복지기금 대출 포함 — 사용자 결정 2026-10-04 · R-3 기준 13 개정). 원문이 대출 · 융자 · 대부를 밝히면 뒤엣것. 원문에 기금 낱말이 없으면 이름 · 서술에 기금을 쓰지 않는다. 주택 대출과 한 라벨이면 `housing_loan`. 코드에 `_loan` 을 붙이려면 원문이 대출을 밝혀야 한다(웨이브 4 HL만도).
- `commute_subsidy` = 회사가 버스 · 셔틀을 **운행**하는 것 / `transport` = 이동 비용을 돈 · 포인트 · 실비로 보태는 것(야근 택시비 · 교통비 · 유류대 · 연고지 왕래 교통비). 버스와 교통비가 한 행이면 버스가 있으니 `commute_subsidy`(benefit_pages `commute_subsidy.json` · `transport.json` `_경계`).
- `discount` = 임직원 할인(제휴 할인 · 항공권 · 차량 구입). 혜택이 적히지 않은 **그룹 제휴카드**(롯데 W카드 · SK패밀리카드류)는 행이 아니다(R-1 감사 §2-5 #2 · 재수집 R-2 어휘 경계). 복지몰은 `welfare_point`.
- `pension_support` = 개인연금 지원(회사 부담이 원문에 있을 때 — 「편의 제공」만이면 문안에 회사 부담 미기재를 적는다, 웨이브 4 감사 L-1). 퇴직연금(DC/DB) 자체는 법정.
- `meal` 금액은 수집 계약 규칙 4-5 식(1끼 단가 × 끼니 × 240일). 끼니 · 단가가 하나도 없으면 NULL.

**건강 · 시설**
- `insurance` = 단체(상해)보험 상품(진단비 · 사망까지 묶인 상품) / 실손(실비)만인 상품 · 본인 · 가족 의료비 = `medical`(R-1 감사 §2-5 #5).
- `health_check` = 종합검진 · 매년 검진(사무직 법정 주기 상회) · 배우자 · 가족 검진 · 검진비 지원. 원문이 산업안전보건법 검진 이름(일반 · 특수건강진단 · 배치전 · 사후관리)**만** 적었으면 행이 아니다(R-3 묶음 7 오스코텍 판정 · 리드 판정 (71) 대한항공 「특수항목」). 「건강검진 지원」 라벨만 있는 것은 코퍼스 관례(134사)대로 싣는다 — 법정 여부 판정은 보류(웨이브 4 감사 L-4 · 수집 계약 ⚖ C-17).
- `clinic` = 사내 의원 · 건강관리실 · 의무실(상담실 「운영」만 있고 내용 없으면 아님) · `mental` = 심리상담 · EAP(명상실은 `nap_room` 서술) · `fitness` = 사내 피트니스 · 운동 지원 · `massage` = 안마 · 마사지(health).
- `lounge` = 휴게 · 카페형 휴게 공간만(옥외 조경 · 업무 공간은 아님) · `nap_room` = 수면실 · 모성보호실 · 수유실(수유 **시설**은 법정 아님 — 법정은 근로기준법 75조 수유 **시간**, R-1 감사 §2-5 #7) · `snack_bar` = 사내 카페 · 간식 · 음료 · 무료 카페테리아(「카페테리아 포인트」는 `welfare_point`) · `library` = 사내 도서관 · 북카페 · 전자도서관(leisure) / `books` = 도서 구입비 지원(growth) · `leisure_room` = 사내 영화관 · 게임존 · 골프 시뮬레이터 같은 문화 시설(리드 판정 ② 묶음 3).
- `work_tools` = IT 장비 · AI 도구 · `uniform` = 근무복(자율복장 아님) · `office_furniture` = 의자 · 데스크 · `parking` = 주차.
- 사옥 시설 목록 · 사진 캡션의 이름뿐인 시설(샤워실 · 회의실 · 탈의실)은 행이 아니다 — 회사가 **복리후생 목록의 항목**으로 적은 이름은 라벨만으로 선다(웨이브 4 감사 M-4 · R-1 감사 §2-5 #4 · ⚖ C-5).

**가족**
- `parenting` = 자녀 양육 · 보육 · 입학축하금 · 출산축하금 · 임신 축하 선물 · 가사도우미 / `parent_care` = 부모 요양 · 돌봄 / `child_edu` = 자녀 학자금 · 유아교육비 · 장애자녀 특수교육비(리드 판정 (71)) / `childcare` = 사내 · 직장 어린이집 / `fertility_support` = 난임 치료비 · 난임 휴가 상회분 / `disability_family_support` = 장애 가족 지원.
- 예식장 · 웨딩홀 대관 = `event` 서술(`wedding` 은 쓰는 회사 0 — 경조금 행에 합친다).

**성장 · 교육**
- `lang` = 어학 비용 지원 **과** 회사가 여는 어학 강좌 · 과정 · 전화외국어 · 랭귀지 세션 / `edu_support` = 사외 교육비 · 자기계발 · 교양 강좌 · 특강 · 자율 수강 온라인 과정 · 학습모임 지원 / `self_development` = 자기계발비 · 본인 학자금 · 자격증 취득 지원 / `mba` = 학위 · 학술연수 / `conference` = 외부 교육 · 세미나 · 학회 참석. 신입 · 입문 · 온보딩 · OJT · 멘토링 · 직무 필수 · 리더십 · 직급별 · 승진자 · 법정 의무 · 선발형 핵심인재 과정만 적힌 원문은 행이 아니다(규칙 8 · 사용자 결정 2026-10-04).
- `career` = 사원이 **스스로 지원하는** 사내 이동(사내공모 · 잡포스팅 · 커리어 마켓 · 그룹사 내부 이동) · 해외 파견 · 지역전문가(규칙 8-1). 회사 주도 직무순환 · 온보딩 멘토링은 행이 아니다(R-1 감사 §2-2).
- `retirement_support` = 법정 재취업지원서비스를 **넘는** 부분만(정년 퇴임식 · 기념품 · 공로여행 · 재직 중 상시 경력 전환 · 퇴직 후 혜택). 1,000인 이상 사업주의 50세 이상 비자발적 이직예정자 진로설계 · 취업 알선 · 재취업 · 창업 교육은 법정(규칙 3).

## 카테고리는 9칸 고정 — 새 서랍은 못 만든다

`compensation · flexibility · work_env · time_off · health · family · growth · leisure · perks`
(정본 순서 = `/home/ubuntu/loupit/generator/pages/company.py` `CATEGORY_ORDER`. 9각형 그래프 · 카테고리 집계가 이 9개를 축으로 쓴다.)

⚠ **한 코드는 한 카테고리에만 넣는다.** 표의 카테고리가 정본이다. 2026-09-21 이전에는 같은 코드가 회사마다 다른 축에 들어간 것이 6종 · 28행 · 25개 회사 있었고(「명절 선물」이 7곳은 compensation, 4곳은 perks), 데이터 정리 2차(`db/migrations/20260921_data_cleanup_2.sql`, 재코딩 30 + 삭제 1)로 전부 통일했다. 지금 분열은 **0종**이다(`_vocab_scan.py` 가 매번 확인한다).

확정된 정본(그때 갈렸던 6종):

| 코드 | 정본 | 근거 |
|---|---|---|
| `holiday_gift` | compensation | 다수(33행) · 「명절 상여금」 등 현금성이 섞여 있다 |
| `work_tools` | work_env | 업무 장비는 근무환경 |
| `parking` | work_env | 주차장 · 주차비는 근무환경 시설 |
| `family_day` | flexibility | 조기퇴근 = 근무 유연성 |
| `massage` | **health** | 사용자 결정 — 다수는 leisure 였으나 건강관리 성격을 따랐다 |
| `welcome_kit` | leisure | 입사 선물 **물품** |

## 법정 제도 판정선 (수집 계약 규칙 3 과 같은 효력)

법정 기준선 정본 = `/home/ubuntu/loupit/generator/data/legal_baseline.json`(reviewed 2026-09-28 · 17항목): 연차유급휴가 · 출산전후휴가 90일(미숙아 100 · 다태아 120) · 임신기 근로시간 단축 · **배우자 출산전후휴가 20일** · **배우자 유산 · 사산휴가 5일(최초 3일 유급, 2026-09-18 시행)** · 육아휴직 12개월(요건 충족 시 18) · 육아기 근로시간 단축 12개월(최대 36) · **난임치료휴가 6일(최초 2일 유급)** · 가족돌봄휴가 10일 · 가족돌봄휴직 90일 · 생리휴가 · **노동절** · 관공서 공휴일 · 주휴일 · 연장 · 야간 · 휴일 가산수당 · 4대 보험 · 퇴직급여.

- 연차 · 반차 → 법정. 문안에서 뺀다. 반반차(2시간 단위) · 회사가 밝힌 시간 단위 → 복지 「2시간 단위 휴가」(사용자 결정 2026-09-20).
- 법정 기준선과 겹치는 회사 휴가는 **기준선을 넘는 일수 · 유급분만** 「(법정 N일에 M일 추가)」로 적는다 — 「난임 치료 휴가 유급 5일(법정 유급 2일에 3일 추가)」(리드 판정 ⑲) · 「배우자 출산휴가 26일(법정 20일에 6일 추가)」. 배우자 출산휴가 10일 · 「법정 10 + 추가 10」은 상회분이 아니다(R-3 기준 31 아래 줄 · ㈜두산 판정).
- 재취업지원서비스(고령자고용법 제21조의3 — 1,000인 이상 사업주가 50세 이상 비자발적 이직예정자에게 주는 진로설계 · 취업 알선 · 재취업 · 창업 교육) → 법정. 대상 확대(재직 중 상시 · 50세 미만) · 유급 휴가 · 퇴직 후 혜택 · 기념품 · 행사만 남긴다. 원문이 스스로 「재취업지원 서비스의 일환」이라 밝히면 그 문장 전체가 법정이다. 같은 회사 보고서가 대상을 「퇴직 예정인 만 50세 이상」으로 적으면 페이지가 「만 50세 이상 임직원」이라 써도 법정이다(리드 판정 ㊽). **1,000인 미만 사업주는 노력의무뿐이라 복지로 남긴다** — 직원 수(OpenDART 사업보고서)를 먼저 본다.
- 노동절(근로자의 날) **휴무**는 법정 — 행으로도 다른 행 서술에도 쓰지 않는다. 그날 회사가 주는 **기념품 · 선물**은 복지(웨이브 4 감사 §10 ① · `legal_baseline.json` labor_day).
- 「직무발명 보상(제도)」 = 발명진흥법 15조 법정 보상 → 싣지 않는다(R-3 기준 34). 안전보호구 · 산업안전보건 의무 · 산재 · 보상휴가제(근로기준법 57조) · 모성보호 「제도 운영」 한 줄도 법정이다(웨이브 4 감사 §9-2).
- 시차출퇴근제 · 선택적근로시간제는 **법정이 아니다**(근로기준법 52조 — 사용자가 도입을 고르는 제도). 수유 **시설**은 법정이 아니다.
- 지금 코퍼스의 「법정만 적힌 행」 · 「업무 교육만 적힌 행」은 지우지 않고 `/home/ubuntu/loupit/generator/data/row_marks.json`(kind `legal` · `work_edu` — 2026-10-04 `legal_rows.json` 에서 이름이 바뀜, 지금 6행)에 등록해 「법정」 · 「업무 교육」 표시 + 집계 제외한다(사용자 결정 2026-09-16 · 2026-10-04). **신규 회사 수집은 그런 행을 처음부터 만들지 않는다**(수집 계약 규칙 3 · 8 · ⚖ C-6). 등록된 행의 `BENEFIT_NM` 을 바꾸면 `test_registry_rows_all_exist_in_seed_sql` 이 깨진다.
