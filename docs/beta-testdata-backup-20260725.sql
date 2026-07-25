-- docs/beta-testdata-backup-20260725.sql
-- 베타(loupit_beta) M9 테스트 데이터 스냅샷 — 2026-07-25 정리 직전 상태(15행).
--
-- 무엇인가: 2026-07-24~25 M9 수동/e2e 테스트로 쌓인 참여 데이터. 정리(삭제) 전에 뜬 덤프이며,
--   삭제 후 loupit_beta 는 시드 상태(회사 95·복지 1317·도메인 31)로 돌아갔다.
-- 어디까지 복원 가능한가: 복지 2건(TCOMPANY_BENEFIT)·편집 이력 4건·회원/인증 뼈대는 그대로.
--   ⚠️ 아래 컬럼은 **마스킹**돼 있어 그대로는 인증에 쓸 수 없다(세션·코드 재현 불가 — 의도된 것).
--     TMEMBER.LOGIN_EMAIL_NM  → '<masked:email>'   (테스트 계정 이메일)
--     TSESSION.TOKEN_HASH_VAL → '<masked:sha256>'  (세션 토큰 해시)
--     TAUTH_CODE.CODE_HASH_VAL·TARGET_HASH_VAL → '<masked:hmac>'  (운영 pepper 로 만든 HMAC)
--     TEMPLOY_VERIFICATION.COMP_EMAIL_HASH_VAL → '<masked:hmac>'  (회사 이메일 HMAC)
--   운영 pepper(login_code_hmac_pepper·comp_email_hmac_pepper)로 생성된 값을 리포에 남기지
--   않으려는 조치다(사용자 결정 2026-07-25). 복원이 필요하면 마스킹 값을 실값으로 바꿔야 하는데,
--   UNIQUE 제약(uq_employ_email 등) 때문에 다건 복원 시 충돌한다 — 참고용 스냅샷으로 볼 것.
-- 프로덕션(LOUPIT)과 무관하다. 이 파일은 문서루트(web/) 밖이라 공개 노출되지 않는다.
--
-- MySQL dump 10.13  Distrib 8.0.42, for Linux (aarch64)
--
-- Host: 127.0.0.1    Database: loupit_beta
-- ------------------------------------------------------
-- Server version	8.0.42

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Dumping data for table `TMEMBER`
--

/*!40000 ALTER TABLE `TMEMBER` DISABLE KEYS */;
INSERT INTO `TMEMBER` VALUES (1,'<masked:email>','직장인-624051','active',NULL,'2026-07-24 00:06:50',NULL,NULL),(2,'<masked:email>','직장인-084004','active',NULL,'2026-07-24 04:29:09',NULL,NULL),(3,'<masked:email>','직장인-378575','active',NULL,'2026-07-25 13:14:06',NULL,NULL);
/*!40000 ALTER TABLE `TMEMBER` ENABLE KEYS */;

--
-- Dumping data for table `TSESSION`
--

/*!40000 ALTER TABLE `TSESSION` DISABLE KEYS */;
INSERT INTO `TSESSION` VALUES (3,2,'<masked:sha256>','2026-08-23 04:36:24',NULL,2,'2026-07-24 04:36:24',NULL,NULL),(4,3,'<masked:sha256>','2026-08-24 13:14:06',NULL,3,'2026-07-25 13:14:06',NULL,NULL);
/*!40000 ALTER TABLE `TSESSION` ENABLE KEYS */;

--
-- Dumping data for table `TAUTH_CODE`
--

/*!40000 ALTER TABLE `TAUTH_CODE` DISABLE KEYS */;
INSERT INTO `TAUTH_CODE` VALUES (13,'employ_verify','<masked:hmac>','<masked:hmac>',35,3,0,'2026-07-25 15:08:16','2026-07-25 15:03:29',NULL,'2026-07-25 15:03:16',NULL,'2026-07-25 15:03:29');
/*!40000 ALTER TABLE `TAUTH_CODE` ENABLE KEYS */;

--
-- Dumping data for table `TEMPLOY_VERIFICATION`
--

/*!40000 ALTER TABLE `TEMPLOY_VERIFICATION` DISABLE KEYS */;
INSERT INTO `TEMPLOY_VERIFICATION` VALUES (1,1,40,'domain','<masked:hmac>','2027-07-24 00:09:42',NULL,1,'2026-07-24 00:09:42',NULL,NULL),(3,2,40,'domain','<masked:hmac>','2027-07-24 06:06:45',NULL,2,'2026-07-24 06:06:45',NULL,NULL),(4,3,40,'domain','<masked:hmac>','2027-07-25 13:14:43',NULL,3,'2026-07-25 13:14:43',NULL,NULL);
/*!40000 ALTER TABLE `TEMPLOY_VERIFICATION` ENABLE KEYS */;

--
-- Dumping data for table `TEMPLOY_VRF_REQUEST`
--

/*!40000 ALTER TABLE `TEMPLOY_VRF_REQUEST` DISABLE KEYS */;
/*!40000 ALTER TABLE `TEMPLOY_VRF_REQUEST` ENABLE KEYS */;

--
-- Dumping data for table `TBENEFIT_EDIT_LOG`
--

/*!40000 ALTER TABLE `TBENEFIT_EDIT_LOG` DISABLE KEYS */;
INSERT INTO `TBENEFIT_EDIT_LOG` VALUES (1,1318,40,1,'create',NULL,'{\"qual_yn\": false, \"badge_cd\": \"verified\", \"note_ctnt\": null, \"amt_source\": \"estimated\", \"benefit_cd\": \"beta_test_meal\", \"benefit_nm\": \"베타 식대\", \"benefit_amt\": 240, \"benefit_ctgr_cd\": \"compensation\"}','베타 테스트 등록','2026-07-24 00:09:55'),(2,1319,40,3,'create',NULL,'{\"qual_yn\": false, \"badge_cd\": \"verified\", \"note_ctnt\": \"e2e 검증용\", \"amt_source\": \"estimated\", \"benefit_cd\": \"e2e_smoke_perk\", \"benefit_nm\": \"E2E 스모크 복지\", \"benefit_amt\": 50, \"benefit_ctgr_cd\": \"perks\"}','e2e 등록','2026-07-25 13:14:43'),(3,1319,40,3,'update','{\"qual_yn\": false, \"badge_cd\": \"verified\", \"note_ctnt\": \"e2e 검증용\", \"amt_source\": \"estimated\", \"benefit_cd\": \"e2e_smoke_perk\", \"benefit_nm\": \"E2E 스모크 복지\", \"benefit_amt\": 50, \"benefit_ctgr_cd\": \"perks\"}','{\"qual_yn\": false, \"badge_cd\": \"verified\", \"note_ctnt\": \"e2e 수정 검증\", \"amt_source\": \"estimated\", \"benefit_cd\": \"e2e_smoke_perk\", \"benefit_nm\": \"E2E 스모크 복지(수정)\", \"benefit_amt\": 70, \"benefit_ctgr_cd\": \"perks\"}','e2e 금액 50→70','2026-07-25 13:16:19'),(4,1319,40,3,'update','{\"qual_yn\": false, \"badge_cd\": \"verified\", \"note_ctnt\": \"e2e 수정 검증\", \"amt_source\": \"estimated\", \"benefit_cd\": \"e2e_smoke_perk\", \"benefit_nm\": \"E2E 스모크 복지(수정)\", \"benefit_amt\": 70, \"benefit_ctgr_cd\": \"perks\"}','{\"qual_yn\": true, \"badge_cd\": \"verified\", \"note_ctnt\": \"정성 전환\", \"amt_source\": \"none\", \"benefit_cd\": \"e2e_smoke_perk\", \"benefit_nm\": \"E2E 스모크 복지(정성)\", \"benefit_amt\": null, \"benefit_ctgr_cd\": \"perks\"}','e2e 정성 전환','2026-07-25 13:16:20');

/*!40000 ALTER TABLE `TBENEFIT_EDIT_LOG` ENABLE KEYS */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-07-25 15:51:40
-- MySQL dump 10.13  Distrib 8.0.42, for Linux (aarch64)
--
-- Host: 127.0.0.1    Database: loupit_beta
-- ------------------------------------------------------
-- Server version	8.0.42

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Dumping data for table `TCOMPANY_BENEFIT`
--
-- WHERE:  BADGE_SRC_CD='user_report'

/*!40000 ALTER TABLE `TCOMPANY_BENEFIT` DISABLE KEYS */;
INSERT INTO `TCOMPANY_BENEFIT` VALUES (1318,40,'beta_test_meal','베타 식대',240,'compensation','verified','estimated','user_report',NULL,'2026-07-24 00:09:55','2028-01-24 00:09:55',NULL,0,NULL,0,1,'2026-07-24 00:09:55',NULL,NULL),(1319,40,'e2e_smoke_perk','E2E 스모크 복지(정성)',NULL,'perks','verified','none','user_report',NULL,'2026-07-25 13:16:20','2028-01-25 13:16:20','정성 전환',1,NULL,0,3,'2026-07-25 13:14:43',3,'2026-07-25 13:16:20');

/*!40000 ALTER TABLE `TCOMPANY_BENEFIT` ENABLE KEYS */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-07-25 15:51:40
