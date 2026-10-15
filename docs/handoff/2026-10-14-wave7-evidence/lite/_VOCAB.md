# 어휘표 — 91종 (웨이브 7부터 · 2026-10-14 판)

새 코드를 만들기 전에 **여기서 같은 뜻을 찾는다.** 대응 어휘가 정말 없을 때만 신규 코드(계약 §3-4). **카테고리 열은 정본이다** — 코드가 표에 있으면 그 카테고리를 베낀다. 아래 「경계」 절은 계약과 같은 효력이다.

- 표 = 웨이브 6 통합본까지 넣은 시드 전수 파싱: **회사 173 · 복지 3,791행 · 코드 91종 · 파서가 놓친 줄 0 · 카테고리 분열 0**. 웨이브 6 worktree(`/home/ubuntu/loupit/.claude/worktrees/wave6`, 브랜치 `data/wave6-13-companies` — 13파일이 감사 모의본과 행 단위로 같다) 시드 폴더로 `_vocab_scan.py` 를 돌렸다 — 웨이브 6 감사의 합본 재현값과 같다. 웨이브 6 이 머지되면 리포 시드로 돌려도 같은 표가 나온다.
- 재생성: `python3 -I /home/ubuntu/loupit-evidence/2026-10-14-wave6/_vocab_scan.py`(시드 경로 = 리포). 머지 전 웨이브를 넣으려면 사본의 `SEED` 줄만 바꾼다. **표 줄 모양(`| \`code\` | n | category | … |`)은 `_row_check.py` 가 읽으니 바꾸지 않는다.**
- 웨이브 6 신규 2종: `grocery_support`(perks · SK케미칼) · `leave_buyout`(compensation · GS리테일).
- `n` = 그 코드를 쓴 회사 수. 대표 명칭 = 코퍼스에서 흔한 표기 순(동률은 이름순). 대표 명칭은 관례일 뿐 정의가 아니다 — 정의는 「경계」 절.

| 코드 | n | 카테고리 | 코퍼스의 대표 명칭 |
|---|---:|---|---|
| `health_check` | 158 | health | 건강검진 · 종합건강검진 · 건강검진 지원 |
| `event` | 153 | family | 경조사 지원 · 경조금·경조휴가 · 경조사비 지원 |
| `resort` | 145 | leisure | 휴양소 지원 · 휴양시설 · 숙박·여가 지원 |
| `child_edu` | 129 | family | 자녀 학자금 지원 · 자녀 학자금 · 자녀학자금 |
| `flex_work` | 123 | flexibility | 유연근무제 · 선택적 근로시간제 · 시차출퇴근제 |
| `welfare_point` | 118 | perks | 복지포인트 · 카페테리아 포인트 · 선택적 복리후생 포인트 |
| `club` | 116 | leisure | 사내 동호회 · 동호회 지원 · 동호회 활동 지원 |
| `meal` | 112 | perks | 사내식당 · 사내 식당 · 구내식당 |
| `parenting` | 108 | family | 임신·출산·육아 · 임신·출산·육아 지원 · 자녀 입학 축하금 |
| `edu_support` | 107 | growth | 자기계발 지원 · 인문학 특강 · 직무 교육비 지원 |
| `lang` | 100 | growth | 어학시험 응시료 · 어학 교육 · 외국어 교육 지원 |
| `mental` | 96 | health | 심리상담센터 · 심리상담 지원 · 심리상담 서비스 |
| `childcare` | 95 | family | 직장 어린이집 · 사내 어린이집 · 직장어린이집 |
| `fitness` | 89 | health | 사내 피트니스 · 피트니스 센터 · 피트니스센터 |
| `medical` | 88 | health | 의료비 지원 · 의료비 지원 (본인·배우자·자녀) · 가족 의료비 지원 |
| `housing_loan` | 87 | perks | 주택자금 대출 · 주택자금 지원 · 주택구입·전세자금 지원 |
| `long_service_leave` | 86 | time_off | 장기근속 포상 · 장기근속 휴가 · CREATIVE WEEK(창의휴가) |
| `commute_subsidy` | 85 | perks | 통근버스 · 출퇴근 지원 · 셔틀버스 |
| `insurance` | 82 | health | 단체상해보험 · 단체 상해보험 · 단체보험 |
| `dormitory` | 76 | work_env | 기숙사 · 기숙사 지원 · 기숙사 운영 |
| `incentive` | 72 | compensation | 성과급 · 성과 인센티브 · 인센티브 |
| `long_service_bonus` | 72 | compensation | 장기근속 포상 · 장기근속자 포상 · 장기근속 포상금 |
| `leave_general` | 71 | time_off | 2시간 단위 휴가 · 리프레시 데이 · 병가 |
| `holiday_gift` | 70 | compensation | 명절 선물 · 명절선물 · 기념일 기념품 |
| `snack_bar` | 67 | perks | 사내 카페 · 사내 카페테리아 · 사내카페 |
| `company_event` | 66 | leisure | 가족 초청 행사 · 가족친화 프로그램 · 송년회·사내 이벤트 |
| `excellence_award` | 63 | compensation | 우수사원 포상 · 포상제도 · Beyond Excellence Service 우수 서비스 직원 포상 |
| `clinic` | 62 | health | 건강관리실 · 사내 부속의원 · 사내 건강관리실 |
| `discount` | 62 | perks | CJ 계열사 할인 · 제휴업체 직원 할인 · 차량구입 지원 |
| `mba` | 56 | growth | MBA·EMBA 지원 · 국내외 학술연수 · H-MBA 핵심인재 프로그램 |
| `self_development` | 56 | growth | 자격증 취득 지원 · 자기계발비 지원 · 본인 학자금 |
| `lounge` | 51 | work_env | 휴게실 · 직원 휴게실 · 휴게 공간 |
| `birthday_gift` | 48 | perks | 생일 선물 · 기념일 선물 · 기념일 선물 지원 |
| `remote_work` | 45 | flexibility | 재택근무 · 재택근무제 · 원격근무제(재택근무 포함) |
| `transport` | 41 | perks | 교통비 지원 · 야근 교통비 · 23시 이후 퇴근 택시비 |
| `career` | 40 | growth | 멘토링 제도 · 사내공모제도 · CDP·글로벌 우수 인재 프로그램 |
| `fertility_support` | 37 | family | 난임 지원 · 난임 치료비 지원 · 난임 시술비 지원 |
| `pension_support` | 35 | perks | 개인연금 지원 · 개인연금 · New Pension |
| `summer_leave` | 33 | time_off | 하계휴가 · 하기휴가 · 여름휴가 |
| `nap_room` | 32 | work_env | 모성보호실 · 맘스룸 · 모유 수유실 |
| `refresh_leave` | 31 | time_off | 리프레시 휴가 · Refresh 휴가 · '쉴랜다' 리프레시 휴가 |
| `pc_off` | 29 | flexibility | PC-OFF 제도 · PC OFF 제도 · PC-OFF |
| `books` | 28 | growth | 도서 구입비 지원 · 도서구입비 지원 · 사내 도서관 |
| `profit_sharing` | 26 | compensation | 경영성과급 · 경영성과금 · 성과급 |
| `housing_support` | 25 | perks | 거주비 지원 · 사택 또는 주거지원금 · 새내기 정착·주거지원금 |
| `library` | 25 | leisure | 전자도서관 · 전자 도서관 · 만화책·보드게임 |
| `welfare_fund_loan` | 25 | perks | 사내 근로복지기금 대출 · 생활안정자금 대출 · 긴급자금 융자 |
| `leisure_ticket` | 24 | leisure | 티빙·CGV 이용권 · CGV 영화예매권 (연 6매) · 네이버 서비스 이용권 |
| `satellite_office` | 23 | flexibility | CJ Work On 거점오피스 · 거점오피스 · 거점 오피스 |
| `summer_vacation_subsidy` | 20 | leisure | 하계 휴가비 · 휴가비 지원 · 3주 휴가 독려 여가포인트 |
| `relocation` | 19 | perks | 부임이사 지원 · 가재이전비·전지지원금 · 발령 임직원 주거 복지 지원 |
| `conference` | 18 | growth | 외부 교육 및 연수 · 교육·세미나 참석 지원 · 국제 포럼·학회·세미나 참가비 지원 |
| `stock_option` | 18 | compensation | 우리사주제도 · 우리사주조합 · 우리사주 |
| `telecom` | 18 | perks | 통신비 지원 · 개인휴대전화비 지원 (책임급 이상·영업 외근직 등) · 무과금 휴대폰 (통신비 지원) |
| `retirement_support` | 15 | growth | 상시 경력 전환 프로그램 (만 50세 이상 간부) · 정년 앞둔 장기근속자 공로여행 · 정년 퇴임식·기념품 |
| `team_dinner` | 15 | perks | 회식비 지원 · 부서 단합비 · 부서 문화행사 지원 |
| `massage` | 14 | health | 네일케어·안마 서비스 · 네일케어룸 · 마사지 테라피 라온 |
| `welcome_kit` | 14 | leisure | 웰컴키트 · Welcome Kit · 사무용품 Welcome Kit 제공 |
| `birthday_leave` | 13 | time_off | 생일휴가 · 개인 기념일 휴가 · 본인 생일 반일 휴가 |
| `uniform` | 13 | work_env | 근무복 지급 · 근무복 지원 · 근무복 지원·세탁 |
| `sports_ticket` | 12 | leisure | LG트윈스·FC 서울 스포츠 티켓 · NC DINOS 경기 관람 지원 · SK Knights 농구 관람 지원 |
| `work_tools` | 12 | work_env | AI Tool 지원 · AI 도구·개인별 AI API 크레딧·업무 장비 · AI 업무 Tool 지원 |
| `parking` | 10 | work_env | 주차 지원 · 무료 주차장 (300대) · 사옥별 주차 지원 |
| `family_day` | 8 | flexibility | 패밀리데이 · Family Day · 가정의 날 |
| `free_seating` | 8 | work_env | 자율좌석제 · 자율 좌석제 · 자율좌석제 (글로벌부문) |
| `office_furniture` | 8 | work_env | 허먼밀러 의자 · 데스크테리어 비용 지원 · 모션 데스크 |
| `bonus` | 7 | compensation | 상여금 · 특별상여 (연간 3회) · 보너스(600%) |
| `disability_family_support` | 7 | family | 발달장애 자녀 특수교육비 지원 · 장애 자녀 치료비 · 장애인 가족 지원금 |
| `foundation_day_leave` | 7 | time_off | 창립기념일 휴무 · 창립기념일 · 노조창립기념일 휴가 · 창립기념일 대체 유급 휴가 (12월 26일) |
| `culture_day` | 6 | leisure | SL CULTURE DAY · 금호문화데이 · 문화가 있는 날 |
| `leisure_room` | 6 | leisure | 건강한 문화 공간 · 게임존 (오껨존) · 골프 시뮬레이터 라운지 |
| `welfare_fund` | 6 | perks | 사내근로복지기금 · 사내 근로복지기금 운영 · 생활안정자금 지원 |
| `smart_office` | 5 | work_env | 스마트오피스 · Smart Working Zone · 스마트오피스 (베어코웍) |
| `travel_support` | 5 | leisure | Global 문화체험 (해외 배낭여행 지원) · 여행비 지원 (국내·해외) · 해외 배낭여행비 지원 |
| `car_rental` | 4 | perks | 무료 전기차 대여 · 주말 업무용 차량 대여 · 캠핑카·캠핑 용품 무료 대여 |
| `severance_plus` | 4 | compensation | 퇴직금 누진제도 · 퇴직금 가산제도 · 퇴직금 누진율 (업계 최고수준) |
| `smoking_cessation` | 4 | health | 금연수당 · 금연 성공 축하금 · 금연클리닉 |
| `workation` | 4 | flexibility | 워케이션 · 강릉 워케이션 · 워케이션·힐링 연수 |
| `car_wash` | 3 | perks | 세차 서비스 · 스팀 세차 서비스 카온 · 카케어 (출장 세차) |
| `overseas_safety` | 3 | health | 해외 근무자 의료·보안 지원 · 해외종합안전관리서비스 · 해외출장자 Travel Medical Kit |
| `promotion_gift` | 3 | perks | 승진자 식사 바우처 · 승진자 축하선물 · 호칭 변경 기념 선물 |
| `stock_grant` | 3 | compensation | 자사주 지급 (성과급 일부) · 자사주 지급 프로그램 · 주식 지급(Stock Grant) |
| `visa_support` | 2 | perks | 비자 발급 지원 · 비자 발급 지원 (E7) |
| `youth_savings` | 2 | compensation | 청년 내일채움공제 · 청년내일채움공제 |
| `blood_bank` | 1 | health | 혈액은행 |
| `grocery_support` | 1 | perks | 유기농 식품 구매 지원 |
| `guest_house` | 1 | leisure | 영빈관 |
| `home_security` | 1 | perks | 여직원 무인경비 지원 |
| `homecoming` | 1 | family | Home-coming 제도 |
| `leave_buyout` | 1 | compensation | 미사용 휴가 1.5배 보상 |
| `parent_care` | 1 | family | 부모 요양 치료비 지원 |

⚠ 대표 명칭 주의 2:
- 「'쉴랜다' 리프레시 휴가」는 옛 행 표기다. 새 행 이름 · 서술에는 홑 · 겹따옴표를 쓰지 않는다(분할기) — 「」.
- `disability_family_support` 1위 「발달장애 자녀 특수교육비 지원」은 독립 항목 2행(같은 그룹 2사)의 이름이다. **장애 자녀 특수교육비의 정의는 `child_edu`** — 거꾸로 배우지 않는다(에코프로 2행 정리는 코퍼스 별건).

## 경계 (계약과 같은 효력 · 계약 §3 에 없는 코드 가르기만 여기 둔다)

**휴가 (time_off)**
- `refresh_leave` = 연차 **외에** 주는 휴가(리프레시 · Refresh · 재충전 · 안식 · 「연차 외 추가 N일」 · 「법정 휴가 외 추가 휴가」) — 이름만 있어도 싣는다. 근속 연동이면 `long_service_leave`. **휴가 적립형 안식휴가는 `leave_general` 「안식휴가 (휴가 적립형)」**(적립 재원이 본인 휴가일 수 있다).
- `long_service_leave` = 근속 연동 휴가(휴가와 포상을 **한 줄에** 함께 적은 원문 포함) / `long_service_bonus` = 휴가 없는 근속 포상금 · 기념품 · 여행, 그리고 휴가인지 포상인지 원문에 없는 근속 급부(재무제표 주석 「장기 근속 임직원 기타장기종업원급여」). 원문이 휴가와 포상을 다른 항목으로 나누면 두 행.
- `leave_general` = 사건 보상(출장 · 심야근무 뒤 **임금과 별도로** 더 주는 휴가) · 이름 있는 집중 · 단체 휴무(하계 · 연말 단체 휴가 · 집중휴가제 · 월말휴무 · 의무 · 필수 집중휴가) · 「○○데이」 · **연차 일수를 밝힌 문장**(「연간 휴가 총 N일」 · 「법정보다 N일 추가」 — 이름 · 서술에 「총」 · 「추가」를 남기고 「연차」 낱말은 걷는다) · 「2시간 단위 휴가」(반반차 · 회사가 밝힌 시간 단위) · 리프레시가 아닌 **이름뿐인 휴가**(자기계발휴가) · 「공동연차 N일 추가」처럼 회사가 더 주는 날 · 경조사 밖 특별휴가(반려동물 · 입양 · 결혼기념일) · 병가 · 인병휴가 · 휴가 이월 · 휴가 사용 방식(자가승인).
- `summer_leave` = 「하계 · 하기 · 여름」 이름 + 회사가 일수를 더 주는 휴가 / `summer_vacation_subsidy` = 휴가를 쓸 때 주는 **현금**(휴가비 — 이름과 달리 하계 한정 아님, leisure). 돈이 원문의 주어가 아니면 휴가 코드.
- `foundation_day_leave` = 창립기념일 휴무 · `birthday_leave` = 생일 휴가(반일이면 「반일」) · 생일 **선물**은 `birthday_gift`.
- **경조휴가 = `event` 서술**(경조금 행에 함께 · 경조휴가만 있으면 `event` 행 이름 「경조휴가」). `leave_general` 에는 경조사 밖 특별휴가만.
- 자녀 입학 · 첫 등교 · 졸업 때 주는 휴가 = `parenting`(`leave_general` 아님).
- `leave_buyout` = 쓰지 않은 휴가를 **법보다 많이(배수 · 가산) 돈으로** 보상하는 제도(compensation). 법정 미사용 연차수당(통상임금 1배)만 적힌 원문은 행이 아니다. 휴가 이월 · 당겨쓰기는 `leave_general`. 서술에 「연차」 · 「연차수당」 낱말을 쓰지 않고 상회 구조가 드러나게(「휴가촉진제 실시 후 25% 범위 내 미사용분에 대해 1.5배 보상」).
- `family_day` = 조기퇴근(가족 행사는 `company_event`).
- 적립휴가(근무시간 적립) · 선택근로 안에서 주는 월 1회 휴무(Happy Friday · 부분적 주 4일) = 휴가 행이 아니라 `flex_work` 서술.
- 행이 아닌 휴가(권장 · 장려 휴가 · 본인 연차 사용 · 보상휴가제)는 계약 §3-6.

**근무 유연성**
- 선택 · 시차 · 자율출퇴근 · 탄력 · 재량근로(근로기준법 58조 ③) = `flex_work` — 법정이 아니다. 사업장 밖 간주근로(58조 ①)는 산정 방식이라 행이 아니다. 보고서 인증 문단의 「유연근무제 운영」처럼 이름만 있어도 `flex_work`(꼬리 「제도 유형·대상 미기재」).
- `remote_work` = 재택 · 원격근무. 공시 「유연근무제도 사용 현황」 표의 제도 이름(재택근무 · 원격근무제)도 그 자체로 행이다 — 다른 행 서술에 묻으면 칩이 「없음」으로 나온다. 설명 없는 「Mobile Office 지원」 라벨은 `work_tools`(원격 근무 칩을 켜지 않는다).
- `smart_office` = 업무 공간(스마트워크존) / `satellite_office` = 거점 · 공유 오피스(`remote_office` 는 소멸한 코드).
- 칩 6코드(`remote_work` · `telecommute` · `wfh` · `flex_work` · `refresh_leave` · `long_service_leave`) 이름 꼴 = 계약 §3-10.

**보상 · 금전 (compensation)**
- `profit_sharing` = 이익 배분(PS) · 경영성과급을 **단독 제도**로 밝힌 것 · 「경영실적에 따른 성과급」 · 「경영성과에 따라 지급」처럼 평가 차등 · PI 언급 없이 회사 실적 연동만 적은 성과급 / `incentive` = 개인 · 조직 평가 차등 · PS 와 PI 를 한 줄에 적은 원문 · 「임직원」 · 「전 직원」 성과금 · 인센티브 문장 · 직군 · 집단 한정 성과급(서술에 대상) · 공고 급여 칸 「성과급 내부 규정에 따라 지급」 · 재무제표 주석 「종업원에게 지급할 성과급」 · 기관 공시 평균보수 표 성과상여금 · 「모든 임직원」 안전장려금 · 공시 보수지급기준의 「직원과 함께 개인성과급 산정」.
- `bonus` = 회사가 **복리후생 블록 안에** 적은 정기 상여율(「상여금 연 800%」 · 「특별상여 연 3회」 — 금액 NULL). 임금 구성 문장(「임금은 기본급, 제수당, 명절 상여로 구성」)은 행이 아니다.
- `holiday_gift` = 명절 선물 · 명절 상여금 · 귀성(귀향)여비 · 명절 상품권 · 창립기념일 · 노동절 기념품(날의 급부) · 기념일 낱말 없는 「선물비」(서술에 원문에 없는 「명절」을 더하지 않는다) · 명절에 선물 대신 주는 포인트 / `birthday_gift` = **개인 기념일**(생일 · 결혼기념일 등) 선물 · 기프트 카드 — 명절과 한 줄에 섞이면 가른다 / `welfare_point` = 연간 배정 복지포인트(지급 시기가 명절이어도) — 한 회사에 둘 다 있으면 두 행.
- `excellence_award` = 회사 포상 제도(라벨만 있어도 · 동료 추천상 류 · 회사 포상 안의 특허 · 제안 · 직무발명 포상). **아닌 것:** 인재추천 포상금(채용 보상) · 안전 · EHS 포상(안전관리 수단) · 「직무발명 보상(제도)」(발명진흥법 15조 법정).
- `stock_option` = **우리사주조합**(전원 대상). 스톡옵션 · RSU 처럼 경영진 · 핵심인력에게 재량으로 고르는 부여는 복지가 아니다. 공시 주주 현황 표의 「우리사주조합 N주」 한 칸만으로는 세우지 않는다 / `stock_grant` = 직원에게 자사주를 지급하는 제도(공시가 직원 대상이라고 밝힐 때 — 처분 총액은 금액이 아니다).
- `severance_plus` = 퇴직금 누진제 · 가산 등 법정 퇴직급여를 넘는 부분(제도 이름이 원문에 있을 때 · 누진율은 서술 · 금액 NULL).
- 급여성 수당(학위 · 자격 · 직무 · 초임 · 무사고 운전 수당)은 행이 아니다.

**생활 · 금융 · 주거 (perks)**
- `welfare_point` = 포인트 · 복지카드 · 복지몰 · 선택적 복리후생비(직급별 정액 통합복리후생비 포함) / 자기계발비 · 개인 업무 지원비 = `self_development`(growth).
- `housing_loan` = 원문이 주택 구입 · 전세 · 임차 **대출 · 이자**를 밝힌 것, 또는 「주택구입 · 전세자금 지원」처럼 **용도가 주택 구입 · 전세 자금인 지원(방식 미기재)** — 코퍼스 다수 관례 / `housing_support` = 임차료 · 월세 · 주거비 **현금**(방식이 「보조금」 등 현금으로 적힌 주택 구입 · 전세 지원도) / `dormitory` = 사택 · 기숙사 · 사원아파트 · 숙소 **시설**(work_env) / `relocation` = 이주 · 정착지원금 · 부임 이사 · 발령 주거 지원 · 전입여비(`housing_loan` 에 넣지 않는다). 이름 · 서술에 원문에 없는 「대출」 낱말을 더하지 않는다.
- `welfare_fund` = 사내근로복지기금 운영 · 생활안정자금 지원(원문에 대출이 없을 때) / `welfare_fund_loan` = 주거 외 용도(생활안정 · 긴급 · 의료비)이거나 **용도가 적히지 않은** 사내 대출 · 대출이자 지원(기금 대출 포함). 원문이 대출 · 융자 · 대부를 밝히면 뒤엣것. 주택 대출과 한 라벨이면 `housing_loan`. 원문에 기금 낱말이 없으면 이름 · 서술에 기금을 쓰지 않는다. `welfare_fund_loan` 은 원문이 대출 · 융자 · 대부를 밝혀야 한다(없으면 `welfare_fund`).
- `commute_subsidy` = 회사가 버스 · 셔틀을 **운행** / `transport` = 이동 비용을 돈 · 포인트 · 실비로 보탬(야근 택시비 · 교통비 · 유류대 · 연고지 왕래 교통비). 버스와 교통비가 한 행이면 `commute_subsidy`.
- `discount` = 임직원 할인(제휴 할인 · 항공권 · 차량 구입 · 자사 제품 할인 판매 · 회사 복리후생 목록의 「제휴업체 할인」 · 계열 시설 할인). 아님: 혜택이 적히지 않은 그룹 제휴카드 이름 · 복지몰(`welfare_point`).
- `grocery_support` = 집에서 먹을 **식품을 사 주거나 주는** 제도(유기농 식품 구매 지원 등) / 사내에서 먹는 끼니 · 간식 = `meal` · `snack_bar` / 자사 제품 할인 판매 = `discount` / 포인트 사용처 = `welfare_point`.
- `pension_support` = 개인연금 지원(회사 부담이 원문에 있을 때 — 「편의 제공」만이면 꼬리에 회사 부담 미기재). 퇴직연금(DC/DB) 자체는 법정.
- `meal` 금액 = 계약 §3-3 식대 식. 끼니 · 단가가 하나도 없으면 NULL.

**건강 · 시설**
- `insurance` = 단체(상해)보험 상품(진단비 · 사망까지 묶인 상품) / 실손(실비)만인 상품 · 본인 · 가족 의료비 = `medical`.
- `health_check` = 종합검진 · 매년 검진 · 배우자 · 가족 검진 · 검진비 지원(법정 검진 이름만이면 행 아님 — 계약 §3-2).
- `clinic` = 사내 의원 · 건강관리실 · 의무실 · 보건관리실 · 사내 간호사(법정 열거 밖 — 「산안법 성격」으로 거르지 않는다 · 상담실 「운영」만 있고 내용이 없으면 아님) · `mental` = 심리상담 · EAP · `fitness` = 사내 피트니스 · 운동 지원 · `massage` = 안마 · 마사지(health) · `smoking_cessation` = 금연 영역 전체(금연수당 · 금연 성공 축하금 · 금연클리닉 — 원문이 별 항목이면 독립 행).
- `lounge` = **쉬는 공간 전부** — 일반 · 성별 휴게실 · 카페형 휴게 공간 · 안마의자 · 리클라이너 · **수면실 · 명상실**(옥외 조경 · 업무 공간은 아님) / `nap_room` = **수유 · 모성 · 임산부 시설만**(모성보호실 · 수유실 · 임산부 휴게실). 한 줄에 섞이거나 한 방이 두 역할(여성 휴게실 겸 수유실)이면 시설별 두 행 — 이름 · 서술에 「겸용」을 적어 과장을 막는다.
- `snack_bar` = 사내 카페 · 간식 · 음료 · 무료 카페테리아(「카페테리아 포인트」는 `welfare_point`) · `library` = 사내 도서관 · 북카페 · 전자도서관(leisure) / `books` = 도서 구입비 지원(growth) · `leisure_room` = 사내 영화관 · 게임존 · 골프 시뮬레이터 같은 문화 시설.
- `work_tools` = IT 장비 · AI 도구 · `uniform` = 근무복(자율복장 아님) · `office_furniture` = 의자 · 데스크 · `parking` = 주차.

**가족 (family)**
- `parenting` = 자녀 양육 · 보육 · 입학 · 출산 축하금 · 임신 축하 선물 · 가사도우미 · 자녀 입학 · 등교 · 졸업 휴가 · 법정 기준을 넘는 육아휴직의 회사 제도 이름(상회분만 서술에 — 새 행 없음) / `parent_care` = 부모 요양 · 돌봄 / `child_edu` = 자녀 학자금 · 유아교육비 · 유치원 보조비(보육비와 한 줄이어도 가른다) · 장애 자녀 특수교육비 · 대상이 적히지 않은 「학자금」(서술에 「자녀」를 더하지 않는다) / `childcare` = 사내 · 직장 어린이집 / `fertility_support` = 난임 치료비 · 시술비 · 난임 휴가 상회분 · 난임 휴직 / `disability_family_support` = 장애 가족 지원(재활 · 보장구 · 장애 가족 지원금).
- 예식장 · 웨딩홀 대관 = `event` 서술(`wedding` 은 쓰지 않는다).

**성장 · 교육 (growth)**
- `lang` = 어학 비용 지원 **과** 회사가 여는 어학 강좌 · 과정 · 전화외국어 · 랭귀지 세션 / `edu_support` = 사외 교육비 · 자기계발 · 교양 · 문화 강좌 · 특강(동호회 문장에 붙어 나와도 — 문장이 아니라 제도 단위로 코딩) · 자율 수강 온라인 과정 · **학습 플랫폼**(직무 콘텐츠가 섞여도 전 임직원 자율 수강이면 — 어학 몫은 `lang`) · 학습모임 지원 · 일반 사무 기술 과정(OA) / `self_development` = 자기계발비 · 본인 학자금 · 자격증 취득 지원(「직무 역량 개발」 문단 안의 나열이어도) / `mba` = 학위 · 학술연수 / `conference` = 외부 교육 · 세미나 · 학회 참석.
- `career` = 사원이 **스스로 지원하는** 사내 이동(사내공모 · 잡포스팅 · 커리어 마켓 · 그룹사 내부 이동) · 해외 파견 · 지역전문가. 회사 주도 직무순환 · 온보딩 멘토링은 아님.
- `retirement_support` = 법정 재취업지원서비스를 **넘는** 부분만(정년 퇴임식 · 기념품 · 공로여행 · 재직 중 상시 경력 전환 · 50세 미만 · 퇴직 후 혜택 · 1,000인 미만 사업주의 재취업 지원).

**여가 · 행사 (leisure)**
- `company_event` = 가족 초청 행사 · 체육대회 · 원팀데이 · 송년회 같은 회사 행사(보고서 조직문화 · 노사 절에서 자주 나온다 — 「직원 복지 아님」으로 한꺼번에 걷지 않는다) · `welcome_kit` = 입사 선물 **물품**.

## 카테고리는 9칸 고정 — 새 서랍은 못 만든다

`compensation · flexibility · work_env · time_off · health · family · growth · leisure · perks`(정본 순서 = `/home/ubuntu/loupit/generator/pages/company.py` `CATEGORY_ORDER` — 9각형 그래프 · 카테고리 집계의 축).

**한 코드는 한 카테고리에만.** 지금 분열 0종(`_vocab_scan.py` 가 매번 확인). 한때 갈렸다가 통일한 6종의 정본: `holiday_gift` = compensation · `work_tools` = work_env · `parking` = work_env · `family_day` = flexibility · `massage` = **health**(사용자 결정) · `welcome_kit` = leisure. 표에 없는 신규 코드는 가장 가까운 뜻의 기존 코드 카테고리.
