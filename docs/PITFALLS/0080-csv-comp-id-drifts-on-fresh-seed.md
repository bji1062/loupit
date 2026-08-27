# 매핑 CSV 의 comp_id 는 fresh 재시드 DB 에서 101행 중 100행이 어긋난다 — 이름이 키다

**발견**: 2026-08-27 레인 fin, `load_corp` 멱등 테스트(`seeded_db` = loupit_test fresh 재시드)
**증상**: `id_drift` 100건 — `('DB손해보험', csv=2, db=9)`, … 101행 중 100행.

## 무엇이 일어났나

`db/seed/corp_code_map.csv` 는 2026-08-21 에 **prod DB** 에서 `SELECT COMP_ID, COMP_NM` 으로 뽑아
만들었다. prod 의 COMP_ID 는 증분 적재의 역사다(95개 → CJ 계열 7개가 97~103 으로 뒤에 붙음).
`load.py --fresh` 는 TCOMPANY 를 DROP/재생성하고 `benefit/sql/*.sql` 을 **파일명 순**으로 돌리므로
AUTO_INCREMENT 가 처음부터 다시 배정된다 — 같은 회사가 다른 번호를 받는다.

즉 CSV 의 `comp_id` 는 "그때 그 DB 의 번호"일 뿐이다. 이걸 조인 키로 쓰면:

- fresh 재시드 DB(테스트·CI·새 환경)에서는 **삼성전자 페이지가 남의 법인 실적을 받는다.**
- 에러는 없다. 매핑 행 수도 101 로 맞다. 화면에 틀린 숫자가 나갈 뿐이다(함정 (57) 계열).

## 왜 위험한가

#15(TCOMPARE_LOG 옛 COMP_ID 잔존)·conftest 참여 7테이블 격리 결함과 **같은 뿌리**다 —
`COMP_ID` 는 안정 식별자가 아니다. 재시드를 건너 살아남는 것은 **이름**(복지 SQL 의 자기등록
INSERT, 함정 (72))뿐이다.

## 어떻게 막았나

1. `load_corp.apply` 는 **`COMP_NM` 으로만** 맞춘다. CSV `comp_id` 는 힌트 — 다르면 요약 한 줄 경고
   (행마다 찍으면 100줄이 정상 출력이 되어 진짜 경고가 묻힌다).
2. 이름이 DB 에 없으면 적재하지 않고 `unmatched` 로 **말한다**(표시명 변경 시 CSV 재생성 필요, 함정 (70)).
3. `TCOMPANY_CORP` 는 CSV 와 완전 동기화 — `--fresh` 는 `FOREIGN_KEY_CHECKS=0` 아래서 TCOMPANY 를
   DROP 하므로 CASCADE 가 안 걸려 **옛 COMP_ID 행이 살아남는다.** CSV 밖 행은 지운다.
4. 테스트(`test_FN1_reapply_is_idempotent`)는 드리프트가 **있는 것이 정상**임을 전제로, 드리프트
   전부가 이름으로 해소돼 101행이 맞물리는지를 잰다.

## 교훈

- 외부 파일에 박힌 `COMP_ID` 는 어느 DB 의 번호인지 적혀 있지 않으면 **없는 것으로** 취급하라.
  조인은 재시드를 건너 살아남는 키(이름·코드)로만.
- "행 수가 맞다"는 "맞는 행이다"가 아니다. 1:1 매핑의 멱등 테스트는 **누가 누구와** 이어졌는지를
  확인해야 한다(개수만 세면 이 결함은 초록이다).
