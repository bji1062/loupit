# 부분 실행에서 파일 순서를 바꾸면 남의 세션 픽스처 잔존행이 내 변경 탓으로 보인다

**발견**: 2026-08-27 커뮤니티 스키마 레인(`lane/comm-backend`), DDL 4테이블을 `db/schema.sql` 에 넣은 직후.
**증상**: 스키마 계열 5파일만 골라 돌리니 **94 errors** — 새 테이블이 무언가를 부순 것처럼 보였다.

```
pytest server/tests/test_community_schema.py test_schema_isolation.py test_schema_load.py \
       test_corp_finance_schema.py test_constraints.py
→ 19 passed, 94 errors
```

## 무엇이 잘못됐나

내 변경이 아니었다. 첫 에러는 `test_corp_finance_schema.py::test_CF6` 의
`Duplicate entry 'large' for key 'TCOMPANY_TYPE.COMP_TP_CD'` 였고, 그 `large` 행은 **앞 파일**
`test_schema_load.py` 가 세션 스코프 `schema_db` 위에 심어 둔 것이다(CF-6 의 `_mk_type` 이 같은 코드를
다시 INSERT 한다). 정규 실행(알파벳 순)에서는 `test_corp_finance_schema` 가 `test_schema_load` **앞**에
와서 충돌이 없다. 내가 명령줄에 파일을 손으로 나열하면서 순서를 뒤집었을 뿐이다.

에러 94개가 한 파일에서 연쇄한 이유: `clean_tx` 는 롤백 격리지만 `schema_db` 는 세션 하나를 공유하므로
앞 파일이 autocommit 으로 남긴 행은 뒤 파일 전체에 보인다.

## 왜 헷갈리나

- "DDL 을 넣자마자 94개가 깨졌다" 는 시간적 상관이 인과처럼 읽힌다.
- 요약줄(`19 passed, 94 errors`)만 보면 스키마가 통째로 잘못된 것 같다. **첫 에러 메시지 한 줄**
  (`Duplicate entry 'large'`)이 진단의 전부였다 — 내 테이블 이름이 아니었다.

## 처방

1. 부분 실행으로 실패가 나면 **같은 파일들을 알파벳 순으로** 다시 돌려 본다(`pytest` 에 디렉터리를
   주거나 파일을 정렬해 넘긴다). 그래도 나면 내 것이다.
2. 실패 수가 아니라 **첫 실패의 오류 문장**을 읽는다 — 거기에 어느 테이블·어느 키인지가 있다.
3. 세션 픽스처(`schema_db`) 위에 행을 심는 테스트는 남의 파일 순서에 기댄 채로 초록일 수 있다는 것을
   안다. 이번엔 고치지 않았다(레인 범위 밖·정규 실행 초록). 고친다면 `_mk_type` 이 `INSERT … ON
   DUPLICATE KEY` 이거나 고유 코드를 쓰면 된다.

**교훈 한 줄**: 부분 실행은 순서도 함께 바꾼다 — 실패가 내 것인지 보려면 순서부터 정규로 되돌려라.
