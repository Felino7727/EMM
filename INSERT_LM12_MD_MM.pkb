CREATE OR REPLACE PACKAGE BODY APPL_DBW.INSERT_LM12_MD_MM
AS
   --Заполнение таблицы NUMBERM - катологу маршрутов
   PROCEDURE R1_BASE (MSG IN OUT S_T_UZXDOC_MESSAGE)
   IS
      --X_IDF_MM   S_ITF_MAIN_MM.IDF_MM%TYPE;
      J   S_ITF_SUBS_LOK_MM%ROWTYPE;

      -- Курсор на S_ITF_SUBS_BRIG_MM
      CURSOR CR_BRIG
      IS
         SELECT *
           FROM S_ITF_SUBS_BRIG_MM B
          WHERE B.TMP_IDF_OBJ = MM_.TMP_IDF_OBJ;
   -- Курсор на S_ITF_SUBS_LOK_MM
   /*CURSOR CR_LOK
   IS
       SELECT *
         FROM S_ITF_SUBS_LOK_MM B
        WHERE B.TMP_IDF_OBJ = MM_.TMP_IDF_OBJ AND B.OZN_TAKS = 1;*/



   BEGIN
      MSG.EXITCODE := 0;

      /*DELETE FROM S_ITF_MAIN_MM
            WHERE CODE_OP != 12;*/


      --Перекодировка Депо Прип Бриг
      UPDATE S_ITF_SUBS_BRIG_MM m
         SET DEPO_PRIP =
                NVL ( (SELECT ID_DEPO_IOMM
                         FROM PEREKODIROVKA_DEPO B
                        WHERE m.DEPO_PRIP = B.ID_DEPO),
                     m.DEPO_PRIP);

      --Запонлняем даными с S_ITF_MAIN_MM
      INSERT INTO S_ldzlb_TMP_R1_BASE (NOMMAR_ID,
                                       NOMMAR,
                                       KODDDPPR,
                                       DATA,
                                       POSPRPOM,
                                       POSPR3,
                                       POSPR4                       --,NOMLOK1
                                             --,KODSERLOK
                                       ,
                                       TABNOM3,
                                       TABNOM4,
                                       KODDDP_POS3,
                                       KODDDP_POS4,
                                       IDF_MM)
         (SELECT LPAD (TO_CHAR (nommar_id1), 8, '0'),
                 MM_.NOM_MRM,
                 MM_.DEPO,
                 TRUNC (MM_.JAVKA, 'dd'),
                 -1,
                 -1,
                 -1                                --,SUBSTR (L.NAME_LOK, 1,4)
                   --,V.KOD_SER
                 ,
                 0,
                 0,
                 0,
                 0,
                 MM_.IDF_MM
            FROM S_ITF_MAIN_MM a
           WHERE data_source = 0 /* ,S_ITF_SUBS_LOK_MM L,S_V_DIC_SER V
              where L.TMP_IDF_OBJ = MM_.TMP_IDF_OBJ
               AND OZN_TAKS = 1
               and L.KOD_SER= V.ID_SER */
                                );

      --Заполняем бригаду
      FOR I IN CR_BRIG
      LOOP
         CASE
            WHEN I.DOLG_MM = 1
            THEN
               --Заполняем Машиниста
               UPDATE S_ldzlb_TMP_R1_BASE
                  SET TABNOMMASH = I.TAB_BRIG,
                      FAMMASH = I.FAM_BRIG,
                      POSPRMASH = 0                                --I.DOLG_MM
                                   ,
                      KODDDP_MASH = I.DEPO_PRIP
                WHERE idf_mm = MM_.idf_mm             /*AND MM_.CODE_OP = 12*/
                                         ;
            WHEN I.DOLG_MM = 2
            THEN
               --Заполняем помощника
               UPDATE S_ldzlb_TMP_R1_BASE
                  SET TABNOMPOM = I.TAB_BRIG,
                      FAMPOM = I.FAM_BRIG,
                      POSPRPOM = 0                                 --I.DOLG_MM
                                  ,
                      KODDDP_POM = I.DEPO_PRIP
                WHERE idf_mm = MM_.idf_mm             /*AND MM_.CODE_OP = 12*/
                                         ;
            WHEN I.DOLG_MM = 3
            THEN
               --Заполняем 3-е лицо
               UPDATE S_ldzlb_TMP_R1_BASE
                  SET TABNOM3 = I.TAB_BRIG,
                      FAM3 = I.FAM_BRIG,
                      POSPR3 = 0                                   --I.DOLG_MM
                                ,
                      KODDDP_POS3 = I.DEPO_PRIP
                WHERE idf_mm = MM_.idf_mm             /*AND MM_.CODE_OP = 12*/
                                         ;
            WHEN I.DOLG_MM = 4
            THEN
               --Заполняем 4-е лицо
               UPDATE S_ldzlb_TMP_R1_BASE
                  SET TABNOM4 = I.TAB_BRIG,
                      FAM4 = I.FAM_BRIG,
                      POSPR4 = 0                                   --I.DOLG_MM
                                ,
                      KODDDP_POS4 = I.DEPO_PRIP
                WHERE idf_mm = MM_.idf_mm             /*AND MM_.CODE_OP = 12*/
                                         ;
            ELSE
               --Ошибка
               S_LOG_WORK.ADD_RECORD (
                  S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                  'Немаэ даних CR_BRIG');
         END CASE;
      END LOOP;



      --Заполняем ЛОК
      IF (MM_.OZN_MM = 1 OR MM_.OZN_MM IS NULL)
      THEN
         --Пререкодировка Депо прип ЛОК
         UPDATE S_ITF_SUBS_LOK_MM m
            SET DEPO_LOK =
                   NVL ( (SELECT ID_DEPO_IOMM
                            FROM PEREKODIROVKA_DEPO B
                           WHERE m.DEPO_LOK = B.ID_DEPO),
                        m.DEPO_LOK);


         BEGIN
            SELECT *
              INTO J
              FROM S_ITF_SUBS_LOK_MM B
             WHERE B.TMP_IDF_OBJ = MM_.TMP_IDF_OBJ AND B.OZN_TAKS = 1 /*
                                                    AND MM_.CODE_OP = 12*/
                                                                     ;


            CASE
               WHEN J.PR_SEC = 0
               THEN
                  --Целый
                  UPDATE S_LDZLB_TMP_R1_BASE
                     SET NOMLOK1 = J.NAME_LOK
                   WHERE idf_mm = MM_.idf_mm          /*AND MM_.CODE_OP = 12*/
                                            ;
               WHEN J.PR_SEC = 1
               THEN
                  --Половинка
                  UPDATE S_LDZLB_TMP_R1_BASE
                     SET NOMLOK1 =
                            (SELECT a.NOM_LOK || '/' || a.KOD_SEK
                               FROM S_ITF_SUBS_SEC_MM a
                              WHERE     a.IDF_TPS = J.IDF_TPS
                                    AND idf_mm = MM_.idf_mm /*AND MM_.CODE_OP = 12*/
                                                           );
               WHEN J.PR_SEC = 9
               THEN
                  --Гибрид
                  UPDATE S_LDZLB_TMP_R1_BASE
                     SET NOMLOK1 =
                            (SELECT a.NOM_LOK || '/' || a.KOD_SEK
                               FROM S_ITF_SUBS_SEC_MM a
                              WHERE     a.IDF_TPS = J.IDF_TPS
                                    AND ROWNUM = 1
                                    AND idf_mm = MM_.idf_mm /*AND MM_.CODE_OP = 12*/
                                                           );

                  --заполняем 4 раздел частично
                  INSERT INTO S_LDZLB_TMP_R4_BASE (NOMMAR_ID,
                                                   NOMMAR,
                                                   KODSLID,
                                                   KODDORDEP,
                                                   KODSERLOK,
                                                   NOMLOK,
                                                   KODSECT,
                                                   BEGSLID,
                                                   ENDSLID,
                                                   NOMROW,
                                                   IDF_MM)
                     (SELECT LPAD (TO_CHAR (nommar_id1), 8, '0'),
                             MM_.NOM_MRM,
                             0,
                             J.DEPO_LOK,
                             V.KOD_SER,
                             C.NOM_LOK || '/' || C.KOD_SEK,
                             0,
                             1,
                             (SELECT COUNT (*) FROM S_ITF_SUBS_RABOTA_PM_MM),
                             ROWNUM,
                             MM_.IDF_MM
                        FROM S_V_DIC_SER V, S_ITF_SUBS_SEC_MM C /*,
                                             S_ITF_MAIN_MM e*/
                       WHERE     C.IDF_TPS = J.IDF_TPS
                             AND C.KOD_SEK != 1
                             AND V.ID_SER = J.KOD_SER);
               ELSE
                  --Ошибка
                  S_LOG_WORK.ADD_RECORD (
                     S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                     'Немаэ даних CR_LOK');
            END CASE;

            UPDATE S_ldzlb_TMP_R1_BASE
               SET (                                              /*NOMLOK1,*/
                    KODSERLOK, KODPRLOK) =
                      (SELECT /*SUBSTR(
                                  L.NAME_LOK
                                 ,1
                                 ,INSTR(
                                         L.NAME_LOK
                                        ,' '
                                        ,1
                                        ,1 ) )
                         ,*/
                             V.KOD_SER, DEPO_LOK
                         FROM                               --S_ITF_MAIN_MM a,
                             S_ITF_SUBS_LOK_MM L, S_V_DIC_SER V
                        WHERE     L.TMP_IDF_OBJ = MM_.TMP_IDF_OBJ
                              AND OZN_TAKS = 1
                              AND L.KOD_SER = V.ID_SER)
             WHERE idf_mm = MM_.idf_mm               /* AND MM_.CODE_OP = 12*/
                                      ;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               S_LOG_WORK.ADD_RECORD (
                  S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                  'S_ITF_SUBS_LOK_MM');
         END;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'Немаэ даних S_R1_BASE');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
      WHEN OTHERS
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'OTHERS S_R1_BASE');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
   END;

   PROCEDURE R3_BASE (MSG IN OUT S_T_UZXDOC_MESSAGE)
   IS
      kol   NUMBER;
   BEGIN
      MSG.EXITCODE := 0;

      SELECT COUNT (*) INTO kol FROM S_ITF_SUBS_SEC_MM;

      IF (kol > 0)
      THEN
         INSERT INTO S_LDZLB_TMP_R3_BASE (NOMMAR_ID,
                                          NOMMAR,
                                          JAVKA,
                                          PRUJOMLOK,
                                          KPOUT,
                                          KPIN,
                                          ZDACHALOK,
                                          ENDWORK,
                                          PEREVID,
                                          ZDACHAPOP,
                                          PROSLD,
                                          PROSLT,
                                          TEMPER,
                                          IDF_MM)
            (SELECT DISTINCT LPAD (TO_CHAR (nommar_id1), 8, '0'),
                             MM_.NOM_MRM,
                             TO_CHAR (MM_.JAVKA, 'hh24:mi'),
                             TO_CHAR (MM_.PRIEM, 'hh24:mi'),
                             TO_CHAR (MM_.DEPO_OUT, 'hh24:mi'),
                             TO_CHAR (MM_.DEPO_IN, 'hh24:mi'),
                             TO_CHAR (MM_.SD_LOK, 'hh24:mi'),
                             TO_CHAR (MM_.END_RAB, 'hh24:mi'),
                             MM_.OTDYH,
                             TO_CHAR (B.SDACHA_PRED, 'hh24:mi'),
                             TO_CHAR (B.SDACHA_PRED, 'dd.mm.yyyy'),
                             TO_CHAR (B.SDACHA_PRED, 'hh24:mi'),
                             0,
                             MM_.IDF_MM
               FROM S_ITF_SUBS_SEC_MM B
              WHERE SDACHA_PRED IS NOT NULL);
      ELSE
         INSERT INTO S_LDZLB_TMP_R3_BASE (NOMMAR_ID,
                                          NOMMAR,
                                          JAVKA,
                                          PRUJOMLOK,
                                          KPOUT,
                                          KPIN,
                                          ZDACHALOK,
                                          ENDWORK,
                                          PEREVID,
                                          TEMPER,
                                          IDF_MM)
            (SELECT DISTINCT LPAD (TO_CHAR (nommar_id1), 8, '0'),
                             NOM_MRM,
                             TO_CHAR (JAVKA, 'hh24:mi'),
                             TO_CHAR (PRIEM, 'hh24:mi'),
                             TO_CHAR (DEPO_OUT, 'hh24:mi'),
                             TO_CHAR (DEPO_IN, 'hh24:mi'),
                             TO_CHAR (SD_LOK, 'hh24:mi'),
                             TO_CHAR (END_RAB, 'hh24:mi'),
                             OTDYH,
                             0,
                             IDF_MM
               FROM S_V_ITF_MAIN_MM_MSG
              WHERE DATA_SOURCE = 0);
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'Немаэ даних S_R3_BASE');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
      WHEN OTHERS
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'OTHERS S_R3_BASE');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
   END;

   PROCEDURE R2_BASE (MSG IN OUT S_T_UZXDOC_MESSAGE)
   IS
   BEGIN
      MSG.EXITCODE := 0;

      INSERT INTO S_LDZLB_TMP_R2_BASE (NOMMAR_ID,
                                       NOMMAR,
                                       HOUROUT,
                                       HOURIN,
                                       KODDRAFT,
                                       KODDRIVE,
                                       SERIES,
                                       STOUT,
                                       STIN,
                                       NOMROW,
                                       NAPRJAM,
                                       NUMBER_,
                                       ORDER_,
                                       IDF_MM)
         (SELECT LPAD (TO_CHAR (nommar_id1), 8, '0'),
                 MM_.NOM_MRM,
                 TO_CHAR (B.DATE_OTPR, 'hh24:mi'),
                 TO_CHAR (B.DATE_PRIB, 'hh24:mi'),
                 B.KOD_TJAGA,
                 B.KOD_DV,
                 B.ID_SER_P,
                 B.ST_OTPR,
                 B.ST_PRIB,
                 B.NPP,
                 DECODE (B.NPP,  1, 1,  2, 2),
                 B.NOM_P,
                 B.N_NAK_DNC,
                 MM_.IDF_MM
            FROM                                          /*S_ITF_MAIN_MM a,*/
                S_ITF_SUBS_BR_PASS_MM B            /*WHERE a.DATA_SOURCE = 0*/
                                       );
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'Немаэ даних S_R2_BASE');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
      WHEN OTHERS
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'OTHERS S_R2_BASE');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
   END;


   PROCEDURE R4_BASE (MSG IN OUT S_T_UZXDOC_MESSAGE)
   IS
   BEGIN
      MSG.EXITCODE := 0;

      --Другий локомотив за СБО
      INSERT INTO S_LDZLB_TMP_R4_BASE (NOMMAR_ID,
                                       NOMMAR,
                                       KODSLID,
                                       KODDORDEP,
                                       KODSERLOK,
                                       NOMLOK,
                                       KODSECT,
                                       BEGSLID,
                                       ENDSLID,
                                       NOMROW,
                                       IDF_MM)
         (SELECT LPAD (TO_CHAR (nommar_id1), 8, '0'),
                 MM_.NOM_MRM,
                 12,
                 B.DEPO_LOK,
                 V.KOD_SER,
                 B.NAME_LOK,
                 0,
                 D.STR_NOM_BEG,
                 D.STR_NOM_END,
                 ROWNUM,
                 MM_.IDF_MM
            FROM                                      --S_V_ITF_MAIN_MM_MSG A,
                S_ITF_SUBS_LOK_MM B, S_ITF_SUBS_LSLED_MM D, S_V_DIC_SER V
           WHERE     D.IDF_TPS = B.IDF_TPS
                 AND B.TMP_IDF_OBJ = MM_.TMP_IDF_OBJ
                 AND B.OZN_TAKS = 2
                 AND B.KOD_SER = V.ID_SER);
   --Вторая секция Гибрида???


   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'Немаэ даних');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
      WHEN OTHERS
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'OTHERS R4_BASE');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
   END;

   PROCEDURE R6_BASE (MSG IN OUT S_T_UZXDOC_MESSAGE)
   IS
      KOL   NUMBER;
   BEGIN
      MSG.EXITCODE := 0;

      INSERT INTO S_LDZLB_TMP_R6_BASE (NOMMAR_ID,
                                       NOMMAR,
                                       KODPRYM,
                                       PRYMIT,
                                       ADDPR1,
                                       ADDPR2,
                                       ADDPR3,
                                       NOMROW,
                                       IDF_MM)
         (SELECT LPAD (TO_CHAR (nommar_id1), 8, '0'),
                 MM_.NOM_MRM,
                 B.KOD_PRIM,
                 1,
                 B.DODAT1,
                 B.DODAT2,
                 B.DODAT3,
                 B.NPP,
                 MM_.IDF_MM
            FROM                                          /*S_ITF_MAIN_MM a,*/
                S_ITF_SUBS_PRIMIT_MM B
           WHERE B.TMP_IDF_OBJ = MM_.TMP_IDF_OBJ);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'Немаэ даних');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
      WHEN OTHERS
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'OTHERS R6_BASE');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
   END;

   PROCEDURE R7_BASE (MSG IN OUT S_T_UZXDOC_MESSAGE)
   IS
      KOL   NUMBER;
   BEGIN
      MSG.EXITCODE := 0;

      INSERT INTO S_LDZLB_TMP_R7_BASE (NOMMAR_ID,
                                       NOMMAR,
                                       ROBOTA,
                                       NOMROW,
                                       KODST,
                                       NAMEST,
                                       PRPRYB,
                                       PRVIDPR,
                                       PRMANEVR,
                                       PRPROST,
                                       PRNOMTR,
                                       PRKINDWR,
                                       WEIGHTNET,
                                       WEIGHTBRYT,
                                       KILKOSEY,
                                       NAGON,
                                       KILVAG,
                                       KTYDINNER,
                                       INDSTFORM,
                                       INDNOMER,
                                       INDSTPRYZN,
                                       SER_KOL_MASH,
                                       PASECT,
                                       PASH_S,
                                       PASPOSHT,
                                       PASBAG,
                                       PRVYKL,
                                       IDF_MM)
         (SELECT LPAD (TO_CHAR (nommar_id1), 8, '0'),
                 MM_.NOM_MRM,
                 B.PR_RAB,
                 B.STR_NOM,
                 B.ESR,
                 D.name,
                 TO_CHAR (B.NACH, 'hh24:mi'),
                 TO_CHAR (B.KONEC, 'hh24:mi'),
                 TO_CHAR (ROUND (B.P_MAN_STAY_TEH / 60, 2), 'FM00.00'),
                 TO_CHAR (ROUND (B.STAY_OGID_RAB / 60, 2), 'FM00.00'),
                 DECODE (
                    b.str_nom,
                    C.STR_NOM_BEG, DECODE (B.PR_RAB,
                                           1, B.KOD_WORK,
                                           0, C.NOM_P,
                                           NULL, 0),
                    0),
                 DECODE (B.PR_RAB,  1, B.NOM_PARK,  0, B.KOD_WORK),
                 DECODE (
                    b.str_nom,
                    C.STR_NOM_BEG, DECODE (B.PR_RAB,
                                           1, 0,
                                           C.NETTO, NULL,
                                           0),
                    0),
                 DECODE (
                    b.str_nom,
                    C.STR_NOM_BEG, DECODE (B.PR_RAB,
                                           1, 0,
                                           C.BRUTTO, NULL,
                                           0),
                    0),
                 DECODE (
                    b.str_nom,
                    C.STR_NOM_BEG, DECODE (B.PR_RAB,  1, 0,  C.OSI, NULL,  0),
                    0),
                 0,
                 DECODE (
                    b.str_nom,
                    C.STR_NOM_BEG, DECODE (B.PR_RAB,
                                           1, 0,
                                           C.VS_VAG, 0,
                                           NULL, 0,
                                           0),
                    NULL, 0,
                    0),
                 B.DINNER,
                 0,
                 0,
                 0,
                 0,
                 0,
                 0,
                 0,
                 0,
                 B.STAY_OGID_DV,
                 MM_.IDF_MM
            FROM                                            --S_ITF_MAIN_MM a,
                S_ITF_SUBS_RABOTA_PM_MM B,
                 S_ITF_SUBS_POIZD_MM C,
                 NSI.V_DIC_STATION_PSVNSI D
           WHERE     (   (    B.STR_NOM =
                                 (SELECT MAX (str_nom_end)
                                    FROM S_ITF_SUBS_POIZD_MM)
                          AND B.STR_NOM = C.STR_NOM_END)
                      OR (B.STR_NOM BETWEEN C.STR_NOM_BEG
                                        AND C.STR_NOM_END - 1))
                 AND D.CODE_ST = B.ESR);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'Немаэ даних');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
      WHEN OTHERS
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'OTHERS R7_BASE');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
   END;


   PROCEDURE R8_BASE (MSG IN OUT S_T_UZXDOC_MESSAGE)
   IS
   BEGIN
      MSG.EXITCODE := 0;

      INSERT INTO S_LDZLB_TMP_R8_BASE (NOMMAR_ID,
                                       NOMMAR,
                                       STNAME,
                                       STKOD,
                                       MANBEG,
                                       MANEND,
                                       KODWORK,
                                       PRWAIT,
                                       PRVYKL,
                                       KTYDINNER,
                                       KODPARK,
                                       NOMROW,
                                       IDF_MM)
         (SELECT LPAD (TO_CHAR (nommar_id1), 8, '0'),
                 MM_.NOM_MRM,
                 1,
                 B.ESR,
                 TO_CHAR (B.NACH, 'hh24:mi'),
                 TO_CHAR (B.KONEC, 'hh24:mi'),
                 B.KOD_WORK,
                 B.STAY_OGID_RAB,
                 B.STAY_OGID_DV,
                 B.DINNER,
                 1,
                 B.STR_NOM,
                 MM_.IDF_MM
            FROM                                          /*S_ITF_MAIN_MM a,*/
                S_ITF_SUBS_RABOTA_PM_MM B);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'Немаэ даних S_R2_BASE');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
      WHEN OTHERS
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'OTHERS R8_BASE');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
   END;


   --Заполнение таблицы NUMBERM - катологу маршрутов
   PROCEDURE NUMBERM (MSG IN OUT S_T_UZXDOC_MESSAGE)
   IS
   BEGIN
      MSG.EXITCODE := 0;

      --перекодировка депо с учето ИОММ
      BEGIN
         UPDATE S_V_ITF_MAIN_MM_MSG a
            SET KPZ =
                   (NVL ( (SELECT ID_DEPO_IOMM
                             FROM PEREKODIROVKA_DEPO B
                            WHERE b.id_depo = a.kpz),
                         a.kpz));

         DBMS_OUTPUT.put_line (' 777');

         SELECT *
           INTO MM_
           FROM S_V_ITF_MAIN_MM_MSG
          WHERE                          /*(CODE_OP = 12 or code_op=300) AND*/
                DATA_SOURCE = 0;

         DBMS_OUTPUT.put_line (' 77');
      /*SELECT ID_DEPO_IOMM
         INTO MM_.KPZ
         FROM PEREKODIROVKA_DEPO B
        WHERE MM_.KPZ = B.ID_DEPO;

       DBMS_OUTPUT.put_line (' 7777');*/



      EXCEPTION
         WHEN OTHERS
         THEN
            DBMS_OUTPUT.put_line (' Нет ID_DEPO_IOMM');
      END;

      BEGIN
         nommar_id1 := S_NUMBER_SEQ.NEXTVAL;
         DBMS_OUTPUT.put_line (' nommar_id1: ' || nommar_id1);
      EXCEPTION
         WHEN OTHERS
         THEN
            S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                   'Нет nommar_id (S_NUMBER_SEQ)');
            S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                   SQLERRM);
            MSG.EXITCODE := 1;
            DBMS_OUTPUT.put_line (' Нет nommar_id (S_NUMBER_SEQ)');
      END;


      INSERT INTO S_LDZLB_TMP_NUMBERM (NOMMAR_ID,
                                       IDF_MOD,
                                       KPZ,
                                       NOMMAR,
                                       DATEMOD,
                                       CLEANPASS,
                                       SFORM,
                                       TAKSUV,
                                       BEDMAK,
                                       PRUJN,
                                       PERED,
                                       DATE_DOCUM,
                                       PRINT,
                                       new,
                                       ARCHIV,
                                       SEND,
                                       DATE_MM,
                                       IDF_MM)
         (SELECT LPAD (TO_CHAR (nommar_id1), 8, '0'),
                 MM_.IDF_MOD,
                 MM_.KPZ,
                 MM_.NOM_MRM,
                 MM_.DATE_CALC,
                 DECODE (MM_.OZN_MM,  1, 0,  2, 2,0 /*DBMS_RANDOM.VALUE( 1, 9 )*/
                                                 )             --Ознака ЗЛБ ММ
                                                  ,
                 1,
                 1                          --DECODE( a.IDF_TAKS, NULL, 0, 1 )
                  ,
                 0                          --DECODE( a.STATUS,  0, 0,  1, 1 )
                  ,
                 1,
                 1                                                     --,NULL
                  ,
                 TRUNC (MM_.JAVKA, 'dd'),
                 0,
                 0,
                 0,
                 0,
                 MM_.DATE_MM,
                 MM_.IDF_MM
            FROM S_ITF_MAIN_MM a
           WHERE DATA_SOURCE = 0);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'Немаэ даних NUMBERM');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
      WHEN OTHERS
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'OTHERS NUMBERM');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
   END;



   PROCEDURE TAKSUV (MSG IN OUT S_T_UZXDOC_MESSAGE)
   IS
   BEGIN
      MSG.EXITCODE := 0;

      INSERT INTO S_LDZLB_TMP_TAKSUV (PRPRYPST,
                                      NOMMAR_ID,
                                      NOMMAR,
                                      LINDIST,
                                      FACTTIME,
                                      PRST,
                                      MANST,
                                      DATEMOD,
                                      PALFACT,
                                      PALNORMA,
                                      RECUPER,
                                      TKMWORKNETO,
                                      TKMWORKBRYTO,
                                      PRPROMST,
                                      PROBOROTST,
                                      PRZMINABRGST,
                                      PRPRYPDEPO,
                                      PROBOROTDEPO,
                                      MANPROMST,
                                      MANOBOROTST,
                                      MANPRYPST,
                                      KILKPROMST,
                                      VYTRDEPOKG,
                                      VYTRDEPOL,
                                      PALNORMAL,
                                      PROSTVHSVITL,
                                      NEPTIME,
                                      KOLPRVHSV,
                                      KODSERLOK,
                                      NOMLOK,
                                      OPAL,
                                      OPAL_ZM,
                                      POGRAN,
                                      POGRAN_ZM,
                                      NAGINALL,
                                      KODDOR1,
                                      FAKT_DOR1,
                                      DATE_1,
                                      palfactl,
                                      IDF_MM)
         (  SELECT DECODE (
                      ROUND (SUM (prip_prost / 60), 2),
                      NULL, '00.00',
                      0, '00.00',
                         TO_CHAR (MOD (FLOOR (SUM (prip_prost) / 60), 24),
                                  'FM00')
                      || '.'
                      || TO_CHAR (MOD (SUM (prip_prost), 60), 'FM00') --TO_CHAR (ROUND (SUM (prip_prost / 60), 2), 'FM00.00')
                                                                     ),
                   LPAD (TO_CHAR (nommar_id1), 8, '0'),
                   MM_.NOM_MRM,
                   SUM (B.LOK_KM),
                   DECODE (
                      ROUND (SUM (B.VR_FACT / 60), 2),
                      NULL, '00.00',
                      0, '00.00',
                         TO_CHAR (MOD (FLOOR (SUM (B.VR_FACT) / 60), 24),
                                  'FM00')
                      || '.'
                      || TO_CHAR (MOD (SUM (B.VR_FACT), 60), 'FM00') --TO_CHAR (ROUND (SUM (B.VR_FACT / 60), 2), 'FM00.00')
                                                                    ),
                      TO_CHAR (
                         MOD (
                            FLOOR (
                                 SUM (
                                      B.PR_PROST
                                    + B.PRIP_PROST
                                    + B.ST_OB_PROST
                                    + B.SM_BR_PROST)
                               / 60),
                            24),
                         'FM00')
                   || '.'
                   || TO_CHAR (
                         MOD (
                            SUM (
                                 B.PR_PROST
                               + B.PRIP_PROST
                               + B.ST_OB_PROST
                               + B.SM_BR_PROST),
                            60),
                         'FM00')     /*TO_CHAR (
ROUND (
   SUM (
        (  B.PR_PROST
         + B.PRIP_PROST
         + B.ST_OB_PROST
         + B.SM_BR_PROST)
      / 60),
   2),
'FM00.00')*/
                                ,
                   DECODE (
                      ROUND (
                         SUM (
                            (B.MAN_PR_ST + B.MAN_ST_OB + B.MAN_ST_PRIP) / 60),
                         2),
                      NULL, '00.00',
                      0, '00.00',
                         TO_CHAR (
                            MOD (
                               FLOOR (
                                    SUM (
                                         B.MAN_PR_ST
                                       + B.MAN_ST_OB
                                       + B.MAN_ST_PRIP)
                                  / 60),
                               24),
                            'FM00')
                      || '.'
                      || TO_CHAR (
                            MOD (
                               SUM (B.MAN_PR_ST + B.MAN_ST_OB + B.MAN_ST_PRIP),
                               60),
                            'FM00')                      /* TO_CHAR (
SUM (
   (B.MAN_PR_ST + B.MAN_ST_OB + B.MAN_ST_PRIP) / 60),
'FM00.00')*/
                                   ),
                   TRUNC (MM_.DATE_OP, 'dd'),
                   DECODE (e.fact,  NULL, 00.00,  0, 00.00,  e.fact),
                   DECODE (e.norm, NULL, 0, e.norm),
                   0,
                   SUM (b.tkm_netto),
                   SUM (b.tkm_brutto),
                   DECODE (
                      SUBSTR (TO_CHAR (SUM (b.pr_prost / 60), 'FM00.00'), 1, 5),
                      0, '00.00',
                      NULL, '00.00',
                         TO_CHAR (MOD (FLOOR (SUM (b.pr_prost) / 60), 24),
                                  'FM00')
                      || '.'
                      || TO_CHAR (MOD (SUM (b.pr_prost), 60), 'FM00') --SUBSTR (TO_CHAR (SUM (b.pr_prost / 60), 'FM00.00'), 1, 5)
                                                                     ),
                   DECODE (
                      ROUND (SUM (b.prip_prost / 60), 2),
                      0, '00.00',
                      NULL, '00.00',
                         TO_CHAR (MOD (FLOOR (SUM (b.prip_prost) / 60), 24),
                                  'FM00')
                      || '.'
                      || TO_CHAR (MOD (SUM (b.prip_prost), 60), 'FM00') --TO_CHAR (SUM (b.prip_prost / 60), 'FM00.00')
                                                                       ),
                   DECODE (
                      ROUND (SUM (b.st_ob_prost / 60), 2),
                      0, '00.00',
                      NULL, '00.00',
                         TO_CHAR (MOD (FLOOR (SUM (b.st_ob_prost) / 60), 24),
                                  'FM00')
                      || '.'
                      || TO_CHAR (MOD (SUM (b.st_ob_prost), 60), 'FM00') --TO_CHAR (SUM (b.st_ob_prost / 60), 'FM00.00')
                                                                        ),
                   DECODE (
                      ROUND (SUM (b.sm_br_prost / 60), 2),
                      0, '00.00',
                      NULL, '00.00',
                         TO_CHAR (MOD (FLOOR (SUM (b.sm_br_prost) / 60), 24),
                                  'FM00')
                      || '.'
                      || TO_CHAR (MOD (SUM (b.sm_br_prost), 60), 'FM00') --TO_CHAR (SUM (b.sm_br_prost / 60), 'FM00.00')
                                                                        ),
                   DECODE (
                      ROUND (SUM (b.dep_prip_prost / 60), 2),
                      0, '00.00',
                      NULL, '00.00',
                         TO_CHAR (
                            MOD (FLOOR (SUM (b.dep_prip_prost) / 60), 24),
                            'FM00')
                      || '.'
                      || TO_CHAR (MOD (SUM (b.dep_prip_prost), 60), 'FM00') --TO_CHAR (SUM (b.dep_prip_prost / 60), 'FM00.00')
                                                                           ),
                   DECODE (
                      ROUND (SUM (b.dep_ob_prost / 60), 2),
                      0, '00.00',
                      NULL, '00.00',
                         TO_CHAR (MOD (FLOOR (SUM (b.dep_ob_prost) / 60), 24),
                                  'FM00')
                      || '.'
                      || TO_CHAR (MOD (SUM (b.dep_ob_prost), 60), 'FM00') --TO_CHAR (SUM (b.dep_ob_prost / 60), 'FM00.00')
                                                                         ),
                   DECODE (
                      ROUND (SUM (b.man_pr_st / 60), 2),
                      0, '00.00',
                      NULL, '00.00',
                         TO_CHAR (MOD (FLOOR (SUM (b.man_pr_st) / 60), 24),
                                  'FM00')
                      || '.'
                      || TO_CHAR (MOD (SUM (b.man_pr_st), 60), 'FM00') --TO_CHAR (SUM (b.man_pr_st / 60), 'FM00.00')
                                                                      ),
                   DECODE (
                      ROUND (SUM (b.man_st_ob / 60), 2),
                      0, '00.00',
                      NULL, '00.00',
                         TO_CHAR (MOD (FLOOR (SUM (b.man_st_ob) / 60), 24),
                                  'FM00')
                      || '.'
                      || TO_CHAR (MOD (SUM (b.man_st_ob), 60), 'FM00') --TO_CHAR (SUM (b.man_st_ob / 60), 'FM00.00')
                                                                      ),
                   DECODE (
                      ROUND (SUM (b.man_st_prip / 60), 2),
                      0, '00.00',
                      NULL, '00.00',
                         TO_CHAR (MOD (FLOOR (SUM (b.man_st_prip) / 60), 24),
                                  'FM00')
                      || '.'
                      || TO_CHAR (MOD (SUM (b.man_st_prip), 60), 'FM00') --TO_CHAR (SUM (b.man_st_prip / 60), 'FM00.00')
                                                                        ),
                   0,                      --ROUND (SUM (b.pr_prost / 60), 2),
                   0,
                   e.norm,
                   DECODE (
                      k.STAY_OGID_RAB,
                      NULL, '00:00',
                         TO_CHAR (MOD (FLOOR (k.STAY_OGID_RAB / 60), 24),
                                  'FM00')
                      || '.'
                      || TO_CHAR (MOD (k.STAY_OGID_RAB, 60), 'FM00')),
                   0,
                   k.STAY_OGID_RAB1,
                   C.KODSERLOK,
                   C.NOMLOK1,
                   0,
                   0,
                   0,
                   0,
                   0,
                   45,
                   35.00,
                   MM_.JAVKA,
                   e.fact,
                   MM_.IDF_MM
              FROM                                          --S_ITF_MAIN_MM a,
                  ASKVP_VIEW.V_EMM_TAKS_RAB B,
                   S_ldzlb_TMP_R1_BASE C,
                   s_st_per_mm_mm e,
                   (  SELECT SUM (k.STAY_OGID_RAB) AS STAY_OGID_RAB,
                             SUM (DECODE (k.STAY_OGID_RAB,  0, 1,  NULL, 1,  0))
                                AS STAY_OGID_RAB1,
                             k.idf_doc
                        FROM s_SUBS_RABOTA_PM_MM k         --, S_ITF_MAIN_MM a
                       WHERE k.idf_doc = MM_.idf_mm
                    GROUP BY k.idf_doc) k
             WHERE     B.idf_doc = MM_.idf_mm
                   AND e.idf_mm = MM_.IDF_MM
                   AND k.idf_doc = MM_.idf_mm
          GROUP BY MM_.IDF_MM,
                   MM_.NOM_MRM,
                   MM_.DATE_OP,
                   C.KODSERLOK,
                   C.NOMLOK1,
                   MM_.JAVKA,
                   e.fact,
                   e.norm,
                   k.STAY_OGID_RAB,
                   k.STAY_OGID_RAB1);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'Немаэ даних TAKSUV');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
      WHEN OTHERS
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'OTHERS TAKSUV');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
   END;

   PROCEDURE TAKSUV_R7 (MSG IN OUT S_T_UZXDOC_MESSAGE)
   IS
   BEGIN
      MSG.EXITCODE := 0;

      INSERT INTO S_LDZLB_TMP_TAKSUV_R7 (NOMMAR_ID,
                                         NOMMAR,
                                         NOMROW,
                                         timeout,
                                         TIMEIN,
                                         KODDOR,
                                         KODST,
                                         NOMTRAIN,
                                         KODWORK,
                                         KODPD,
                                         LINDIST_R7,
                                         WNETTO,
                                         WBRUTTO,
                                         FACTTIME_R7,
                                         PRZMINABRGST_R7,
                                         KOLVANTVAG,
                                         KOLPORVAG,
                                         KILKOSEY,
                                         KILVAG,
                                         KODSERLOK,
                                         NOMLOK,
                                         ROBOTA,
                                         promstprost,
                                         promstmanevr,
                                         tkmworkneto_r7,
                                         tkmworkbryto_r7,
                                         prpromst_r7,
                                         prprypst_r7,
                                         proborotst_r7,
                                         mpromst_r7,
                                         moborotst_r7,
                                         mprypst_r7,
                                         prprypdepo_r7,
                                         proborotdepo_r7,
                                         nagin,
                                         kilkst,
                                         ktydinner,
                                         nom_row_u7,
                                         enor,
                                         prst_r7,
                                         manst_r7,
                                         IDF_MM)
         (  SELECT RRRR.A,
                   RRRR.B,
                   RRRR.C,
                   RRRR.Q,
                   RRRR.W,
                   RRRR.E,
                   RRRR.R,
                   RRRR.T,
                   RRRR.Y,
                   RRRR.U,
                   RRRR.I,
                   RRRR.O,
                   RRRR.P,
                   DECODE (
                      ROUND (SUM (RRRR.F / 60), 2),
                      NULL, '00.00',
                      0, '00.00',
                         TO_CHAR (MOD (FLOOR (SUM (RRRR.F) / 60), 24), 'FM00')
                      || '.'
                      || TO_CHAR (MOD (SUM (RRRR.F), 60), 'FM00') -- TO_CHAR (ROUND (SUM (RRRR.F / 60), 2), 'FM00.00')
                                                                 ),
                   DECODE (
                      ROUND (SUM (RRRR.S / 60), 2),
                      NULL, '00.00',
                      0, '00.00',
                         TO_CHAR (MOD (FLOOR (SUM (RRRR.S) / 60), 24), 'FM00')
                      || '.'
                      || TO_CHAR (MOD (SUM (RRRR.S), 60), 'FM00') --TO_CHAR (ROUND (SUM (RRRR.S / 60), 2), 'FM00.00')
                                                                 ),
                   SUM (RRRR.G),
                   DECODE (SUM (RRRR.H),  NULL, '0',  0, '0',  SUM (RRRR.H)),
                   RRRR.J,
                   RRRR.K,
                   RRRR.L,
                   RRRR.Z,
                   RRRR.X,
                   ROUND (SUM (RRRR.x1 / 60), 2),
                   ROUND (SUM (RRRR.x2 / 60), 2),
                   RRRR.X3,
                   RRRR.X4,
                   DECODE (
                      ROUND (SUM (RRRR.X5 / 60), 2),
                      NULL, '00.00',
                      0, '00.00',
                         TO_CHAR (MOD (FLOOR (SUM (RRRR.X5) / 60), 24), 'FM00')
                      || '.'
                      || TO_CHAR (MOD (SUM (RRRR.X5), 60), 'FM00') --TO_CHAR (ROUND (SUM (RRRR.X5 / 60), 2), 'FM00.00')
                                                                  ),
                   DECODE (
                      ROUND (SUM (RRRR.X6 / 60), 2),
                      NULL, '00.00',
                      0, '00.00',
                         TO_CHAR (MOD (FLOOR (SUM (RRRR.X6) / 60), 24), 'FM00')
                      || '.'
                      || TO_CHAR (MOD (SUM (RRRR.X6), 60), 'FM00') --TO_CHAR (ROUND (SUM (RRRR.X6 / 60), 2), 'FM00.00')
                                                                  ),
                   DECODE (
                      ROUND (SUM (RRRR.X7 / 60), 2),
                      NULL, '00.00',
                      0, '00.00',
                         TO_CHAR (MOD (FLOOR (SUM (RRRR.X7) / 60), 24), 'FM00')
                      || '.'
                      || TO_CHAR (MOD (SUM (RRRR.X7), 60), 'FM00') --TO_CHAR (ROUND (SUM (RRRR.X7 / 60), 2), 'FM00.00')
                                                                  ),
                   DECODE (
                      ROUND (SUM (RRRR.X8 / 60), 2),
                      NULL, '00.00',
                      0, '00.00',
                         TO_CHAR (MOD (FLOOR (SUM (RRRR.X8) / 60), 24), 'FM00')
                      || '.'
                      || TO_CHAR (MOD (SUM (RRRR.X8), 60), 'FM00') --TO_CHAR (ROUND (SUM (RRRR.X8 / 60), 2), 'FM00.00')
                                                                  ),
                   DECODE (
                      ROUND (SUM (RRRR.X9 / 60), 2),
                      NULL, '00.00',
                      0, '00.00',
                         TO_CHAR (MOD (FLOOR (SUM (RRRR.X9) / 60), 24), 'FM00')
                      || '.'
                      || TO_CHAR (MOD (SUM (RRRR.X9), 60), 'FM00') --TO_CHAR (ROUND (SUM (RRRR.X9 / 60), 2), 'FM00.00')
                                                                  ),
                   DECODE (
                      ROUND (SUM (RRRR.X10 / 60), 2),
                      NULL, '00.00',
                      0, '00.00',
                         TO_CHAR (MOD (FLOOR (SUM (RRRR.X10) / 60), 24),
                                  'FM00')
                      || '.'
                      || TO_CHAR (MOD (SUM (RRRR.X10), 60), 'FM00') --TO_CHAR (ROUND (SUM (RRRR.X10 / 60), 2), 'FM00.00')
                                                                   ),
                   DECODE (
                      ROUND (SUM (RRRR.X11 / 60), 2),
                      NULL, '00.00',
                      0, '00.00',
                         TO_CHAR (MOD (FLOOR (SUM (RRRR.X11) / 60), 24),
                                  'FM00')
                      || '.'
                      || TO_CHAR (MOD (SUM (RRRR.X11), 60), 'FM00') --TO_CHAR (ROUND (SUM (RRRR.X11 / 60), 2), 'FM00.00')
                                                                   ),
                   DECODE (
                      ROUND (SUM (RRRR.X12 / 60), 2),
                      NULL, '00.00',
                      0, '00.00',
                         TO_CHAR (MOD (FLOOR (SUM (RRRR.X12) / 60), 24),
                                  'FM00')
                      || '.'
                      || TO_CHAR (MOD (SUM (RRRR.X12), 60), 'FM00') --TO_CHAR (ROUND (SUM (RRRR.X12 / 60), 2), 'FM00.00')
                                                                   ),
                   RRRR.X13,
                   RRRR.X14,
                   DECODE (
                      ROUND (SUM (RRRR.X15), 2),
                      NULL, '00.00',
                      0, '00.00',
                         TO_CHAR (MOD (FLOOR (SUM (RRRR.X15) / 60), 24),
                                  'FM00')
                      || '.'
                      || TO_CHAR (MOD (SUM (RRRR.X15), 60), 'FM00') --TO_CHAR (ROUND (SUM (RRRR.X15), 2), 'FM00.00')
                                                                   ),
                   RRRR.X16,
                   1,
                   DECODE (
                      ROUND (
                         (RRRR.X5 + RRRR.x6 + RRRR.x7 + RRRR.x11 + RRRR.S / 60),
                         2),
                      NULL, '00.00',
                      0, '00.00',
                         TO_CHAR (
                            MOD (
                               FLOOR (
                                    (  RRRR.X5
                                     + RRRR.x6
                                     + RRRR.x7
                                     + RRRR.x11
                                     + RRRR.S)
                                  / 60),
                               24),
                            'FM00')
                      || '.'
                      || TO_CHAR (
                            MOD (
                               (RRRR.X5 + RRRR.x6 + RRRR.x7 + RRRR.x11 + RRRR.S),
                               60),
                            'FM00')                                                                                                                             /*TO_CHAR (
ROUND (
   (  (RRRR.X5 + RRRR.x6 + RRRR.x7 + RRRR.x11 + RRRR.S)
    / 60),
   2),
'FM00.00')
*/
                                   ),
                   DECODE (
                      ROUND ( (RRRR.X8 + RRRR.X9 + RRRR.X10), 2),
                      NULL, '00.00',
                      0, '00.00',
                         TO_CHAR (
                            MOD (FLOOR ( (RRRR.X8 + RRRR.X9 + RRRR.X10) / 60),
                                 24),
                            'FM00')
                      || '.'
                      || TO_CHAR (MOD ( (RRRR.X8 + RRRR.X9 + RRRR.X10), 60),
                                  'FM00')                                                                           /*TO_CHAR (ROUND ( (RRRR.X8 + RRRR.X9 + RRRR.X10), 2),
'FM00.00')*/
                                         ),
                   RRRR.X55
              FROM (SELECT DISTINCT
                           LPAD (TO_CHAR (nommar_id1), 8, '0') AS A,
                           MM_.NOM_MRM AS B,
                           B.STR_NOM7 AS C,
                           TO_CHAR (C.NACH, 'hh24:mi') AS Q,
                           TO_CHAR (C.KONEC, 'hh24:mi') AS W,
                           B.KOD_DOR_PD AS E,
                           C.ESR AS R,
                           DECODE (c.pr_rab,  1, c.nom_park,  0, d.nom_p) AS T,
                           B.ROD_RAB AS Y,
                           DECODE (B.UCHASTOK, NULL, 0, B.UCHASTOK) AS U,
                           DECODE (B.LOK_KM, NULL, 0, B.LOK_KM * 1000) AS I,
                           DECODE (D.NETTO, NULL, 0, D.NETTO) AS O,
                           DECODE (D.BRUTTO, NULL, 0, D.BRUTTO) AS P,
                           SUBSTR (B.VR_FACT, 1, 5) AS F,
                           B.SM_BR_PROST AS S,
                           e.KOL_GR AS G,
                           e.KOL_POR AS H,
                           D.OSI AS J,
                           D.VS_VAG AS K,
                           g.KOD_SER AS L,
                           g.NAME_LOK AS Z,
                           C.PR_RAB AS X,
                           c.stay_ogid_rab AS X1,
                           c.p_man_stay_teh AS X2,
                           DECODE (b.tkm_netto, NULL, 0, b.tkm_netto) AS X3,
                           DECODE (b.tkm_brutto, NULL, 0, b.tkm_brutto) AS X4,
                           b.pr_prost AS X5,
                           b.prip_prost AS X6,
                           b.st_ob_prost AS X7,
                           b.man_pr_st AS X8,
                           b.man_st_ob AS X9,
                           b.man_st_prip AS X10,
                           b.dep_prip_prost AS X11,
                           b.dep_ob_prost AS X12,
                           0 AS X13,
                           DECODE (c.stay_ogid_rab,  NULL, 0,  0, 0,  1) AS X14,
                           c.dinner AS X15,
                           c.str_nom AS X16,
                           MM_.IDF_MM AS X55
                      FROM                                  --S_ITF_MAIN_MM a,
                          ASKVP_VIEW.V_EMM_TAKS_RAB B,
                           S_ITF_SUBS_RABOTA_PM_MM C,
                           S_ITF_SUBS_POIZD_MM D,
                           S_ITF_SUBS_P_RPS_MM e,
                           S_ITF_SUBS_LOK_MM g,
                           PSVNSI.TPS_SERII Z
                     WHERE     B.STR_NOM7 = C.STR_NOM
                           AND B.STR_NOM7 BETWEEN D.STR_NOM_BEG
                                              AND D.STR_NOM_END - 1
                           AND g.KOD_SER = SUBSTR (Z.K_SER, 1, 3)
                           AND B.IDF_DOC = MM_.IDF_MM
                           AND g.OZN_TAKS = 1
                           AND g.IDF_TPS = B.IDF_TPS
                    UNION
                    SELECT DISTINCT
                           LPAD (TO_CHAR (nommar_id1), 8, '0') AS A,
                           MM_.NOM_MRM AS B,
                           B.STR_NOM7 AS C,
                           TO_CHAR (C.NACH, 'hh24:mi') AS Q,
                           TO_CHAR (C.KONEC, 'hh24:mi') AS W,
                           B.KOD_DOR_PD AS E,
                           C.ESR AS R,
                           DECODE (c.pr_rab,  1, c.nom_park,  0, d.nom_p) AS T,
                           B.ROD_RAB AS Y,
                           DECODE (B.UCHASTOK, NULL, 0, B.UCHASTOK) AS U,
                           DECODE (B.LOK_KM, NULL, 0, B.LOK_KM * 1000) AS I,
                           DECODE (D.NETTO, NULL, 0, D.NETTO) AS O,
                           DECODE (D.BRUTTO, NULL, 0, D.BRUTTO) AS P,
                           SUBSTR (B.VR_FACT, 1, 5) AS F,
                           B.SM_BR_PROST AS S,
                           e.KOL_GR AS G,
                           e.KOL_POR AS H,
                           D.OSI AS J,
                           D.VS_VAG AS K,
                           g.KOD_SER AS L,
                           g.NAME_LOK AS Z,
                           C.PR_RAB AS X,
                           c.stay_ogid_rab AS X1,
                           c.p_man_stay_teh AS X2,
                           DECODE (b.tkm_netto, NULL, 0, b.tkm_netto) AS X3,
                           DECODE (b.tkm_brutto, NULL, 0, b.tkm_brutto) AS X4,
                           b.pr_prost AS X5,
                           b.prip_prost AS X6,
                           b.st_ob_prost AS X7,
                           b.man_pr_st AS X8,
                           b.man_st_ob AS X9,
                           b.man_st_prip AS X10,
                           b.dep_prip_prost AS X11,
                           b.dep_ob_prost AS X12,
                           0 AS X13,
                           DECODE (c.stay_ogid_rab,  NULL, 0,  0, 0,  1) AS X14,
                           c.dinner AS X15,
                           c.str_nom AS X16,
                           MM_.IDF_MM AS X55
                      FROM                                  --S_ITF_MAIN_MM a,
                          ASKVP_VIEW.V_EMM_TAKS_RAB B,
                           S_ITF_SUBS_RABOTA_PM_MM C,
                           S_ITF_SUBS_POIZD_MM D,
                           S_ITF_SUBS_P_RPS_MM e,
                           S_ITF_SUBS_LOK_MM g,
                           PSVNSI.TPS_SERII Z
                     WHERE     B.STR_NOM7 = C.STR_NOM
                           AND MM_.IDF_MM = B.IDF_DOC
                           AND B.STR_NOM7 IN (SELECT MAX (STR_NOM_END)
                                                FROM S_ITF_SUBS_POIZD_MM)
                           AND d.str_nom_end = B.STR_NOM7
                           AND g.KOD_SER = SUBSTR (Z.K_SER, 1, 3)
                           AND g.OZN_TAKS = 1
                           AND g.IDF_TPS = B.IDF_TPS
                    ORDER BY C) RRRR
             WHERE 1 = 1
          GROUP BY RRRR.A,
                   RRRR.B,
                   RRRR.C,
                   RRRR.Q,
                   RRRR.W,
                   RRRR.E,
                   RRRR.R,
                   RRRR.T,
                   RRRR.Y,
                   RRRR.U,
                   RRRR.I,
                   RRRR.O,
                   RRRR.P,
                   RRRR.F,
                   RRRR.S,
                   RRRR.J,
                   RRRR.K,
                   RRRR.L,
                   RRRR.Z,
                   RRRR.X,
                   RRRR.X3,
                   RRRR.X4,
                   RRRR.X5,
                   RRRR.X6,
                   RRRR.X7,
                   RRRR.X8,
                   RRRR.X9,
                   RRRR.X10,
                   RRRR.X11,
                   RRRR.X13,
                   RRRR.X14,
                   RRRR.X16,
                   RRRR.X55);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'Немаэ даних TAKSUV');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
      WHEN OTHERS
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'OTHERS TAKSUV');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
   END;

   PROCEDURE TAKSUV_LM003 (MSG IN OUT S_T_UZXDOC_MESSAGE)
   IS
      nommar_   S_LDZLB_NUMBERM.NOMMAR_ID%TYPE;
   BEGIN
      MSG.EXITCODE := 1;

      SELECT b.nommar_id
        INTO nommar_
        FROM S_ITF_MAIN_MM a, S_LDZLB_NUMBERM b
       WHERE     b.IDF_MM = a.IDF_MM
             AND b.kpz = a.depo
             AND b.date_mm = a.date_mm
             AND a.DATA_SOURCE = 0;

      IF (nommar_ IS NOT NULL)
      THEN
         MSG.EXITCODE := 0;

         INSERT INTO S_LDZLB_TMP_TAKSUV (PRPRYPST,
                                         NOMMAR_ID,
                                         NOMMAR,
                                         LINDIST,
                                         FACTTIME,
                                         PRST,
                                         MANST,
                                         DATEMOD,
                                         --PALFACT,
                                         --PALNORMA,
                                         RECUPER,
                                         TKMWORKNETO,
                                         TKMWORKBRYTO,
                                         PRPROMST,
                                         PROBOROTST,
                                         PRZMINABRGST,
                                         PRPRYPDEPO,
                                         PROBOROTDEPO,
                                         MANPROMST,
                                         MANOBOROTST,
                                         MANPRYPST,
                                         KILKPROMST,
                                         VYTRDEPOKG,
                                         VYTRDEPOL,
                                         --PALNORMAL,
                                         PROSTVHSVITL,
                                         NEPTIME,
                                         KOLPRVHSV,
                                         KODSERLOK,
                                         NOMLOK,
                                         OPAL,
                                         OPAL_ZM,
                                         POGRAN,
                                         POGRAN_ZM,
                                         NAGINALL,
                                         KODDOR1,
                                         FAKT_DOR1,
                                         DATE_1                            --,
                                               --palfactl
                                         ,
                                         IDF_MM)
            (  SELECT DECODE (
                         ROUND (SUM (prip_prost / 60), 2),
                         NULL, '00.00',
                         0, '00.00',
                            TO_CHAR (MOD (FLOOR (SUM (prip_prost) / 60), 24),
                                     'FM00')
                         || '.'
                         || TO_CHAR (MOD (SUM (prip_prost), 60), 'FM00') --TO_CHAR (ROUND (SUM (prip_prost / 60), 2), 'FM00.00')
                                                                        ),
                      nommar_,
                      a.NOM_MRM,
                      SUM (B.LOK_KM),
                      DECODE (
                         ROUND (SUM (B.VR_FACT / 60), 2),
                         NULL, '00.00',
                         0, '00.00',
                            TO_CHAR (MOD (FLOOR (SUM (B.VR_FACT) / 60), 24),
                                     'FM00')
                         || '.'
                         || TO_CHAR (MOD (SUM (B.VR_FACT), 60), 'FM00') --TO_CHAR (ROUND (SUM (B.VR_FACT / 60), 2), 'FM00.00')
                                                                       ),
                         TO_CHAR (
                            MOD (
                               FLOOR (
                                    SUM (
                                         B.PR_PROST
                                       + B.PRIP_PROST
                                       + B.ST_OB_PROST
                                       + B.SM_BR_PROST)
                                  / 60),
                               24),
                            'FM00')
                      || '.'
                      || TO_CHAR (
                            MOD (
                               SUM (
                                    B.PR_PROST
                                  + B.PRIP_PROST
                                  + B.ST_OB_PROST
                                  + B.SM_BR_PROST),
                               60),
                            'FM00')  /*TO_CHAR (
ROUND (
   SUM (
        (  B.PR_PROST
         + B.PRIP_PROST
         + B.ST_OB_PROST
         + B.SM_BR_PROST)
      / 60),
   2),
'FM00.00')*/
                                   ,
                      DECODE (
                         ROUND (
                            SUM (
                               (B.MAN_PR_ST + B.MAN_ST_OB + B.MAN_ST_PRIP) / 60),
                            2),
                         NULL, '00.00',
                         0, '00.00',
                            TO_CHAR (
                               MOD (
                                  FLOOR (
                                       SUM (
                                            B.MAN_PR_ST
                                          + B.MAN_ST_OB
                                          + B.MAN_ST_PRIP)
                                     / 60),
                                  24),
                               'FM00')
                         || '.'
                         || TO_CHAR (
                               MOD (
                                  SUM (
                                     B.MAN_PR_ST + B.MAN_ST_OB + B.MAN_ST_PRIP),
                                  60),
                               'FM00')                                                                                                                      /*TO_CHAR (
SUM (
   (B.MAN_PR_ST + B.MAN_ST_OB + B.MAN_ST_PRIP) / 60),
'FM00.00')*/
                                      ),
                      TRUNC (a.DATE_OP, 'dd'),
                      --DECODE (e.fact,  NULL, 00.00,  0, 00.00,  e.fact),
                      -- DECODE (e.norm, NULL, 0, e.norm),
                      0,
                      SUM (b.tkm_netto),
                      SUM (b.tkm_brutto),
                      DECODE (
                         SUBSTR (TO_CHAR (SUM (b.pr_prost / 60), 'FM00.00'),
                                 1,
                                 5),
                         0, '00.00',
                         NULL, '00.00',
                            TO_CHAR (MOD (FLOOR (SUM (b.pr_prost) / 60), 24),
                                     'FM00')
                         || '.'
                         || TO_CHAR (MOD (SUM (b.pr_prost), 60), 'FM00') --SUBSTR (TO_CHAR (SUM (b.pr_prost / 60), 'FM00.00'), 1, 5)
                                                                        ),
                      DECODE (
                         ROUND (SUM (b.prip_prost / 60), 2),
                         0, '00.00',
                         NULL, '00.00',
                            TO_CHAR (MOD (FLOOR (SUM (b.prip_prost) / 60), 24),
                                     'FM00')
                         || '.'
                         || TO_CHAR (MOD (SUM (b.prip_prost), 60), 'FM00') --TO_CHAR (SUM (b.prip_prost / 60), 'FM00.00')
                                                                          ),
                      DECODE (
                         ROUND (SUM (b.st_ob_prost / 60), 2),
                         0, '00.00',
                         NULL, '00.00',
                            TO_CHAR (
                               MOD (FLOOR (SUM (b.st_ob_prost) / 60), 24),
                               'FM00')
                         || '.'
                         || TO_CHAR (MOD (SUM (b.st_ob_prost), 60), 'FM00') --TO_CHAR (SUM (b.st_ob_prost / 60), 'FM00.00')
                                                                           ),
                      DECODE (
                         ROUND (SUM (b.sm_br_prost / 60), 2),
                         0, '00.00',
                         NULL, '00.00',
                            TO_CHAR (
                               MOD (FLOOR (SUM (b.sm_br_prost) / 60), 24),
                               'FM00')
                         || '.'
                         || TO_CHAR (MOD (SUM (b.sm_br_prost), 60), 'FM00') --TO_CHAR (SUM (b.sm_br_prost / 60), 'FM00.00')
                                                                           ),
                      DECODE (
                         ROUND (SUM (b.dep_prip_prost / 60), 2),
                         0, '00.00',
                         NULL, '00.00',
                            TO_CHAR (
                               MOD (FLOOR (SUM (b.dep_prip_prost) / 60), 24),
                               'FM00')
                         || '.'
                         || TO_CHAR (MOD (SUM (b.dep_prip_prost), 60), 'FM00') --TO_CHAR (SUM (b.dep_prip_prost / 60), 'FM00.00')
                                                                              ),
                      DECODE (
                         ROUND (SUM (b.dep_ob_prost / 60), 2),
                         0, '00.00',
                         NULL, '00.00',
                            TO_CHAR (
                               MOD (FLOOR (SUM (b.dep_ob_prost) / 60), 24),
                               'FM00')
                         || '.'
                         || TO_CHAR (MOD (SUM (b.dep_ob_prost), 60), 'FM00') --TO_CHAR (SUM (b.dep_ob_prost / 60), 'FM00.00')
                                                                            ),
                      DECODE (
                         ROUND (SUM (b.man_pr_st / 60), 2),
                         0, '00.00',
                         NULL, '00.00',
                            TO_CHAR (MOD (FLOOR (SUM (b.man_pr_st) / 60), 24),
                                     'FM00')
                         || '.'
                         || TO_CHAR (MOD (SUM (b.man_pr_st), 60), 'FM00') --TO_CHAR (SUM (b.man_pr_st / 60), 'FM00.00')
                                                                         ),
                      DECODE (
                         ROUND (SUM (b.man_st_ob / 60), 2),
                         0, '00.00',
                         NULL, '00.00',
                            TO_CHAR (MOD (FLOOR (SUM (b.man_st_ob) / 60), 24),
                                     'FM00')
                         || '.'
                         || TO_CHAR (MOD (SUM (b.man_st_ob), 60), 'FM00') --TO_CHAR (SUM (b.man_st_ob / 60), 'FM00.00')
                                                                         ),
                      DECODE (
                         ROUND (SUM (b.man_st_prip / 60), 2),
                         0, '00.00',
                         NULL, '00.00',
                            TO_CHAR (
                               MOD (FLOOR (SUM (b.man_st_prip) / 60), 24),
                               'FM00')
                         || '.'
                         || TO_CHAR (MOD (SUM (b.man_st_prip), 60), 'FM00') --TO_CHAR (SUM (b.man_st_prip / 60), 'FM00.00')
                                                                           ),
                      0,                   --ROUND (SUM (b.pr_prost / 60), 2),
                      0,
                      --e.norm,
                      DECODE (
                         k.STAY_OGID_RAB,
                         NULL, '00:00',
                            TO_CHAR (MOD (FLOOR (k.STAY_OGID_RAB / 60), 24),
                                     'FM00')
                         || '.'
                         || TO_CHAR (MOD (k.STAY_OGID_RAB, 60), 'FM00')), --to_char(mod(floor(minutes/60),24),'FM00')||':'||to_char(mod(minutes,60),'FM00');
                      0,
                      k.STAY_OGID_RAB1,
                      C.KODSERLOK,
                      C.NOMLOK1,
                      0,
                      0,
                      0,
                      0,
                      0,
                      45,
                      35.00,
                      a.JAVKA                                              --,
                             --e.fact
                      ,
                      a.IDF_MM
                 FROM S_ITF_MAIN_MM a,
                      S_itf_subs_taks_rab_mm B,
                      S_LDZLB_R1_BASE C,
                      --s_st_per_mm_mm e,
                      (  SELECT SUM (k.STAY_OGID_RAB) AS STAY_OGID_RAB,
                                SUM (
                                   DECODE (k.STAY_OGID_RAB,  0, 1,  NULL, 1,  0))
                                   AS STAY_OGID_RAB1,
                                k.idf_doc
                           FROM s_SUBS_RABOTA_PM_MM k, S_ITF_MAIN_MM m
                          WHERE k.idf_doc = m.idf_mm
                       GROUP BY k.idf_doc) k
                WHERE a.data_source = 0             --AND B.idf_doc = a.idf_mm
                                        --AND e.idf_mm = a.IDF_MM
                      AND k.idf_doc = a.idf_mm AND c.NOMMAR_ID = nommar_
             GROUP BY a.IDF_MM,
                      a.NOM_MRM,
                      a.DATE_OP,
                      C.KODSERLOK,
                      C.NOMLOK1,
                      a.JAVKA,
                      -- e.fact,
                      -- e.norm,
                      k.STAY_OGID_RAB,
                      k.STAY_OGID_RAB1);
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'Немаэ даних TAKSUV');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
      WHEN OTHERS
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'OTHERS TAKSUV');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
   END;

   PROCEDURE TAKSUV_R7_LM003 (MSG IN OUT S_T_UZXDOC_MESSAGE)
   IS
      nommar_   S_LDZLB_NUMBERM.NOMMAR_ID%TYPE;
   BEGIN
      MSG.EXITCODE := 1;

      SELECT b.NOMMAR_ID
        INTO nommar_
        FROM S_ITF_MAIN_MM a, S_LDZLB_NUMBERM b
       WHERE     b.idf_mm = a.IDF_MM
             AND b.kpz = a.depo
             AND b.date_mm = a.date_mm
             AND a.DATA_SOURCE = 0;

      IF (nommar_ IS NOT NULL)
      THEN
         MSG.EXITCODE := 0;

         INSERT INTO S_LDZLB_TMP_TAKSUV_R7 (NOMMAR_ID,
                                            NOMMAR,
                                            NOMROW,
                                            timeout,
                                            TIMEIN,
                                            KODDOR,
                                            KODST,
                                            NOMTRAIN,
                                            KODWORK,
                                            KODPD,
                                            LINDIST_R7,
                                            WNETTO,
                                            WBRUTTO,
                                            FACTTIME_R7,
                                            PRZMINABRGST_R7,
                                            KOLVANTVAG,
                                            KOLPORVAG,
                                            KILKOSEY,
                                            KILVAG,
                                            KODSERLOK,
                                            NOMLOK,
                                            ROBOTA,
                                            promstprost,
                                            promstmanevr,
                                            tkmworkneto_r7,
                                            tkmworkbryto_r7,
                                            prpromst_r7,
                                            prprypst_r7,
                                            proborotst_r7,
                                            mpromst_r7,
                                            moborotst_r7,
                                            mprypst_r7,
                                            prprypdepo_r7,
                                            proborotdepo_r7,
                                            nagin,
                                            kilkst,
                                            ktydinner,
                                            nom_row_u7,
                                            enor,
                                            prst_r7,
                                            manst_r7,
                                            IDF_MM)
            (  SELECT RRRR.A,
                      RRRR.B,
                      RRRR.C,
                      RRRR.Q,
                      RRRR.W,
                      RRRR.E,
                      RRRR.R,
                      RRRR.T, --to_char(mod(floor(minutes/60),24),'FM00')||':'||to_char(mod(minutes,60),'FM00');
                      RRRR.Y,
                      RRRR.U,
                      RRRR.I,
                      RRRR.O,
                      RRRR.P,
                      DECODE (
                         RRRR.F,
                         NULL, '00.00',
                         0, '00.00',
                            TO_CHAR (MOD (FLOOR (RRRR.F / 60), 24), 'FM00')
                         || '.'
                         || TO_CHAR (MOD (RRRR.F, 60), 'FM00')),
                      DECODE (
                         RRRR.S,
                         NULL, '00.00',
                         0, '00.00',
                            TO_CHAR (MOD (FLOOR (RRRR.S / 60), 24), 'FM00')
                         || '.'
                         || TO_CHAR (MOD (RRRR.S, 60), 'FM00')),
                      SUM (RRRR.G),
                      DECODE (RRRR.H,  NULL, '0',  0, '0',  SUM (RRRR.H)),
                      DECODE (RRRR.J,  NULL, '0',  0, '0',  RRRR.J),
                      DECODE (RRRR.K,  NULL, '0',  0, '0',  RRRR.K),
                      RRRR.L,
                      RRRR.Z,
                      RRRR.X,
                      ROUND (SUM (RRRR.x1 / 60), 2),
                      ROUND (SUM (RRRR.x2 / 60), 2),
                      RRRR.X3,
                      RRRR.X4,
                      DECODE (
                         ROUND (SUM (RRRR.X5 / 60), 2),
                         NULL, '00.00',
                         0, '00.00',
                            TO_CHAR (MOD (FLOOR (SUM (RRRR.X5) / 60), 24),
                                     'FM00')
                         || '.'
                         || TO_CHAR (MOD (SUM (RRRR.X5), 60), 'FM00') --TO_CHAR (ROUND (SUM (RRRR.X5 / 60), 2), 'FM00.00')
                                                                     ),
                      DECODE (
                         ROUND (SUM (RRRR.X6 / 60), 2),
                         NULL, '00.00',
                         0, '00.00',
                            TO_CHAR (MOD (FLOOR (SUM (RRRR.X6) / 60), 24),
                                     'FM00')
                         || '.'
                         || TO_CHAR (MOD (SUM (RRRR.X6), 60), 'FM00') --TO_CHAR (ROUND (SUM (RRRR.X6 / 60), 2), 'FM00.00')
                                                                     ),
                      DECODE (
                         ROUND (SUM (RRRR.X7 / 60), 2),
                         NULL, '00.00',
                         0, '00.00',
                            TO_CHAR (MOD (FLOOR (SUM (RRRR.X7) / 60), 24),
                                     'FM00')
                         || '.'
                         || TO_CHAR (MOD (SUM (RRRR.X7), 60), 'FM00') --TO_CHAR (ROUND (SUM (RRRR.X7 / 60), 2), 'FM00.00')
                                                                     ),
                      DECODE (
                         ROUND (SUM (RRRR.X8 / 60), 2),
                         NULL, '00.00',
                         0, '00.00',
                            TO_CHAR (MOD (FLOOR (SUM (RRRR.X8) / 60), 24),
                                     'FM00')
                         || '.'
                         || TO_CHAR (MOD (SUM (RRRR.X8), 60), 'FM00') --TO_CHAR (ROUND (SUM (RRRR.X8 / 60), 2), 'FM00.00')
                                                                     ),
                      DECODE (
                         ROUND (SUM (RRRR.X9 / 60), 2),
                         NULL, '00.00',
                         0, '00.00',
                            TO_CHAR (MOD (FLOOR (SUM (RRRR.X9) / 60), 24),
                                     'FM00')
                         || '.'
                         || TO_CHAR (MOD (SUM (RRRR.X9), 60), 'FM00') --TO_CHAR (ROUND (SUM (RRRR.X9 / 60), 2), 'FM00.00')
                                                                     ),
                      DECODE (
                         ROUND (SUM (RRRR.X10 / 60), 2),
                         NULL, '00.00',
                         0, '00.00',
                            TO_CHAR (MOD (FLOOR (SUM (RRRR.X10) / 60), 24),
                                     'FM00')
                         || '.'
                         || TO_CHAR (MOD (SUM (RRRR.X10), 60), 'FM00') --TO_CHAR (ROUND (SUM (RRRR.X10 / 60), 2), 'FM00.00')
                                                                      ),
                      DECODE (
                         ROUND (SUM (RRRR.X11 / 60), 2),
                         NULL, '00.00',
                         0, '00.00',
                            TO_CHAR (MOD (FLOOR (SUM (RRRR.X11) / 60), 24),
                                     'FM00')
                         || '.'
                         || TO_CHAR (MOD (SUM (RRRR.X11), 60), 'FM00') --TO_CHAR (ROUND (SUM (RRRR.X11 / 60), 2), 'FM00.00')
                                                                      ),
                      DECODE (
                         ROUND (SUM (RRRR.X12 / 60), 2),
                         NULL, '00.00',
                         0, '00.00',
                            TO_CHAR (MOD (FLOOR (SUM (RRRR.X12) / 60), 24),
                                     'FM00')
                         || '.'
                         || TO_CHAR (MOD (SUM (RRRR.X12), 60), 'FM00') --TO_CHAR (ROUND (SUM (RRRR.X12 / 60), 2), 'FM00.00')
                                                                      ),
                      RRRR.X13,
                      RRRR.X14,
                      DECODE (
                         ROUND (SUM (RRRR.X15), 2),
                         NULL, '00.00',
                         0, '00.00',
                            TO_CHAR (MOD (FLOOR (SUM (RRRR.X15) / 60), 24),
                                     'FM00')
                         || '.'
                         || TO_CHAR (MOD (SUM (RRRR.X15), 60), 'FM00') --TO_CHAR (ROUND (SUM (RRRR.X15), 2), 'FM00.00')
                                                                      ),
                      RRRR.X16,
                      1,
                      DECODE (
                         ROUND (
                            SUM (
                                 RRRR.X5
                               + RRRR.x6
                               + RRRR.x7
                               + RRRR.x11
                               + RRRR.S / 60),
                            2),
                         NULL, '00.00',
                         0, '00.00',
                            TO_CHAR (
                               MOD (
                                  FLOOR (
                                       SUM (
                                            RRRR.X5
                                          + RRRR.x6
                                          + RRRR.x7
                                          + RRRR.x11
                                          + RRRR.S)
                                     / 60),
                                  24),
                               'FM00')
                         || '.'
                         || TO_CHAR (
                               MOD (
                                  SUM (
                                       RRRR.X5
                                     + RRRR.x6
                                     + RRRR.x7
                                     + RRRR.x11
                                     + RRRR.S),
                                  60),
                               'FM00')                                       /*TO_CHAR (
ROUND (
   (  (RRRR.X5 + RRRR.x6 + RRRR.x7 + RRRR.x11 + RRRR.S)
    / 60),
   2),
'FM00.00')*/
                                      ),
                      DECODE (
                         ROUND (SUM (RRRR.X8 + RRRR.X9 + RRRR.X10), 2),
                         NULL, '00.00',
                         0, '00.00',
                            TO_CHAR (
                               MOD (
                                  FLOOR (
                                     SUM (RRRR.X8 + RRRR.X9 + RRRR.X10) / 60),
                                  24),
                               'FM00')
                         || '.'
                         || TO_CHAR (
                               MOD (SUM (RRRR.X8 + RRRR.X9 + RRRR.X10), 60),
                               'FM00')              /*TO_CHAR (ROUND ( (RRRR.X8 + RRRR.X9 + RRRR.X10), 2),
'FM00.00')*/
                                      ),
                      RRRR.X17
                 FROM (SELECT DISTINCT
                              nommar_ AS A,
                              a.NOM_MRM AS B,
                              B.STR_NOM7 AS C,
                              TO_CHAR (C.NACH, 'hh24:mi') AS Q,
                              TO_CHAR (C.KONEC, 'hh24:mi') AS W,
                              B.KOD_DOR_PD AS E,
                              C.ESR AS R,
                              DECODE (c.pr_rab,  1, c.nom_park,  0, d.nom_p)
                                 AS T,
                              B.ROD_RAB AS Y,
                              DECODE (B.UCHASTOK, NULL, 0, B.UCHASTOK) AS U,
                              DECODE (B.LOK_KM, NULL, 0, B.LOK_KM * 1000) AS I,
                              DECODE (D.NETTO, NULL, 0, D.NETTO) AS O,
                              DECODE (D.BRUTTO, NULL, 0, D.BRUTTO) AS P,
                              SUBSTR (B.VR_FACT, 1, 5) AS F,
                              B.SM_BR_PROST AS S,
                              e.KOL_GR AS G,
                              e.KOL_POR AS H,
                              D.OSI AS J,
                              D.VS_VAG AS K,
                              g.KODSERLOK AS L,
                              g.NOMLOK1 AS Z,
                              C.PR_RAB AS X,
                              c.stay_ogid_rab AS X1,
                              c.p_man_stay_teh AS X2,
                              DECODE (b.tkm_netto, NULL, 0, b.tkm_netto) AS X3,
                              DECODE (b.tkm_brutto, NULL, 0, b.tkm_brutto)
                                 AS X4,
                              b.pr_prost AS X5,
                              b.prip_prost AS X6,
                              b.st_ob_prost AS X7,
                              b.man_pr_st AS X8,
                              b.man_st_ob AS X9,
                              b.man_st_prip AS X10,
                              b.dep_prip_prost AS X11,
                              b.dep_ob_prost AS X12,
                              0 AS X13,
                              DECODE (c.stay_ogid_rab,  NULL, 0,  0, 0,  1)
                                 AS X14,
                              c.dinner AS X15,
                              c.str_nom AS X16,
                              a.IDF_MM AS X17
                         FROM S_ITF_MAIN_MM a,
                              S_itf_subs_taks_rab_mm B,
                              S_ITF_SUBS_RABOTA_PM_MM C,
                              S_ITF_SUBS_POIZD_MM D,
                              (  SELECT TMP_IDF_OBJ,
                                        SUM (KOL_GR) AS KOL_GR,
                                        SUM (KOL_POR) AS KOL_POR
                                   FROM S_ITF_SUBS_P_RPS_MM
                               GROUP BY TMP_IDF_OBJ) e,
                              S_LDZLB_R1_BASE g        --,S_ITF_SUBS_LOK_MM g,
                        --PSVNSI.TPS_SERII Z
                        WHERE     B.STR_NOM7 = C.STR_NOM
                              AND (   (    B.STR_NOM7 =
                                              (SELECT MAX (STR_NOM_END)
                                                 FROM S_ITF_SUBS_POIZD_MM)
                                       AND d.STR_NOM_END = B.STR_NOM7)
                                   OR (B.STR_NOM7 BETWEEN D.STR_NOM_BEG
                                                      AND D.STR_NOM_END - 1))
                              AND G.NOMMAR_ID = nommar_
                              -- AND g.KOD_SER = SUBSTR (Z.K_SER, 1, 3)
                              -- AND g.OZN_TAKS = 1
                              --AND g.IDF_TPS = B.IDF_TPS
                              AND a.data_source = 0) RRRR
                WHERE 1 = 1
             GROUP BY RRRR.A,
                      RRRR.B,
                      RRRR.C,
                      RRRR.Q,
                      RRRR.W,
                      RRRR.E,
                      RRRR.R,
                      RRRR.T,
                      RRRR.Y,
                      RRRR.U,
                      RRRR.I,
                      RRRR.H,
                      RRRR.O,
                      RRRR.P,
                      RRRR.F,
                      RRRR.S,
                      RRRR.J,
                      RRRR.K,
                      RRRR.L,
                      RRRR.Z,
                      RRRR.X,
                      RRRR.X3,
                      RRRR.X4,
                      RRRR.X5,
                      RRRR.X6,
                      RRRR.X7,
                      RRRR.X8,
                      RRRR.X9,
                      RRRR.X10,
                      RRRR.X11,
                      RRRR.X13,
                      RRRR.X14,
                      RRRR.X16,
                      RRRR.X17);
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'Немаэ даних TAKSUV');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
      WHEN OTHERS
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'OTHERS TAKSUV');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
   END;



  /* PROCEDURE CLEAR_TABLE (MSG IN OUT S_T_UZXDOC_MESSAGE)
   IS
   BEGIN
      MSG.EXITCODE := 0;

      --чистка таблиц
      DELETE FROM S_R1_BASE
            WHERE NOMMAR != 7777777;

      DELETE FROM S_R2_BASE
            WHERE NOMMAR != 7777777;

      DELETE FROM S_R3_BASE
            WHERE NOMMAR != 7777777;

      DELETE FROM S_R4_BASE
            WHERE NOMMAR != 7777777;

      DELETE FROM S_R6_BASE
            WHERE NOMMAR != 7777777;

      DELETE FROM S_R7_BASE
            WHERE NOMMAR != 7777777;

      DELETE FROM S_R8_BASE
            WHERE NOMMAR != 7777777;

      DELETE FROM S_NUMBERM
            WHERE NOMMAR != 7777777;

      DELETE FROM S_TAKSUV
            WHERE NOMMAR != 7777777;

      DELETE FROM S_TAKSUV_R7
            WHERE NOMMAR != 7777777;
   END;*/

   PROCEDURE MAIN (MSG IN OUT S_T_UZXDOC_MESSAGE)
   IS
      X_MESAGE   S_ITF_KEY_MSG.KOD_MESS%TYPE;
   BEGIN
      MSG.EXITCODE := 0;

      SELECT *
        INTO MM_
        FROM S_V_ITF_MAIN_MM_MSG
       WHERE (CODE_OP = 12 OR CODE_OP = 300) AND DATA_SOURCE = 0;

      SELECT KOD_MESS INTO X_MESAGE FROM S_ITF_KEY_MSG;
   /* CASE X_MESAGE
       WHEN 'LM012'
       THEN
          CLEAR_TABLE ();
          NUMBERM ();
          R1_BASE ();
          R2_BASE ();
          R3_BASE ();
          R4_BASE ();
          R6_BASE ();
          R7_BASE ();
          R8_BASE ();
          TAKSUV_R7 ();
          TAKSUV ();
       WHEN 'LM002'
       THEN
          CLEAR_TABLE ();
          NUMBERM ();
          R1_BASE ();
          R2_BASE ();
          R3_BASE ();
          R4_BASE ();
          R6_BASE ();
          R7_BASE ();
          R8_BASE ();
       WHEN 'LM003'
       THEN
          TAKSUV_R7_LM003 ();
          TAKSUV_LM003 ();
       ELSE
          S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                 'Цепочка не LM012 LM002');
    END CASE;*/
   --визначення типу маршруту(з локомотивом чи ЗП)


   /* CLEAR_TABLE ();
    NUMBERM ();
    R1_BASE ();
    R2_BASE ();
    R3_BASE ();
    R4_BASE ();
    R6_BASE ();
    R7_BASE ();
    R8_BASE ();
    TAKSUV_R7 ();
    TAKSUV ();*/
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'Немаэ даних');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
      WHEN OTHERS
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'OTHERS MAIN');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
   END;


   PROCEDURE REMOVE (MSG IN OUT S_T_UZXDOC_MESSAGE)
   IS
      NOM_MRM1   S_ITF_MAIN_MM.NOM_MRM%TYPE;
      DATE_MM1   S_ITF_MAIN_MM.DATE_MM%TYPE;
      depo1      S_ITF_MAIN_MM.depo%TYPE;
   BEGIN
      MSG.EXITCODE := 0;

      SELECT NOM_MRM, DATE_MM, depo
        INTO NOM_MRM1, DATE_MM1, depo1
        FROM S_ITF_MAIN_MM
       WHERE DATA_SOURCE = 0;

      DELETE FROM S_LDZLB_NUMBERM
            WHERE NOMMAR = NOM_MRM1 AND DATE_MM = DATE_MM1 AND kpz = depo1 /*AND (CODE_OP = 12 or code_op = 300 )*/
                                                                          ;

      /*DELETE FROM S_R4_BASE
            WHERE NOMMAR_ID = (SELECT IDF_MM
                                 FROM S_ITF_MAIN_MM
                                WHERE DATA_SOURCE = 0
                                AND CODE_OP = 12);
    */

      S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                             'Данные удалены');
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'Немаэ даних');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
      WHEN OTHERS
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'OTHERS MAIN');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
   END;

   --Запись с временных таблиц
   PROCEDURE WRITE_TABLE (MSG IN OUT S_T_UZXDOC_MESSAGE)
   IS
   BEGIN
      MSG.EXITCODE := 0;

      INSERT INTO S_LDZLB_NUMBERM (NOMMAR_ID,
                                   IDF_MOD,
                                   KPZ,
                                   NOMMAR,
                                   DATEMOD,
                                   CLEANPASS,
                                   SFORM,
                                   TAKSUV,
                                   BEDMAK,
                                   PRUJN,
                                   PERED,
                                   DATE_DOCUM,
                                   PRINT,
                                   new,
                                   ARCHIV,
                                   SEND,
                                   DATE_MM,
                                   IDF_MM)
         (SELECT NOMMAR_ID,
                 IDF_MOD,
                 KPZ,
                 NOMMAR,
                 DATEMOD,
                 CLEANPASS,
                 SFORM,
                 TAKSUV,
                 BEDMAK,
                 PRUJN,
                 PERED,
                 DATE_DOCUM,
                 PRINT,
                 new,
                 ARCHIV,
                 SEND,
                 DATE_MM,
                 IDF_MM
            FROM S_LDZLB_TMP_NUMBERM);

      INSERT INTO S_LDZLB_R1_BASE
         (SELECT * FROM S_LDZLB_TMP_R1_BASE);

      INSERT INTO S_LDZLB_R2_BASE
         (SELECT * FROM S_LDZLB_TMP_R2_BASE);

      INSERT INTO S_LDZLB_R3_BASE (NOMMAR_ID,
                                   NOMMAR,
                                   JAVKA,
                                   PRUJOMLOK,
                                   KPOUT,
                                   KPIN,
                                   ZDACHALOK,
                                   ENDWORK,
                                   PEREVID,
                                   ZDACHAPOP,
                                   PROSLD,
                                   PROSLT,
                                   TEMPER,
                                   IDF_MM)
         (SELECT NOMMAR_ID,
                 NOMMAR,
                 JAVKA,
                 PRUJOMLOK,
                 KPOUT,
                 KPIN,
                 ZDACHALOK,
                 ENDWORK,
                 PEREVID,
                 ZDACHAPOP,
                 PROSLD,
                 PROSLT,
                 TEMPER,
                 IDF_MM
            FROM S_LDZLB_TMP_R3_BASE);

      INSERT INTO S_LDZLB_R4_BASE
         (SELECT * FROM S_LDZLB_TMP_R4_BASE);

      INSERT INTO S_LDZLB_R6_BASE
         (SELECT * FROM S_LDZLB_TMP_R6_BASE);

      INSERT INTO S_LDZLB_R7_BASE
         (SELECT * FROM S_LDZLB_TMP_R7_BASE);

      INSERT INTO S_LDZLB_R8_BASE
         (SELECT * FROM S_LDZLB_TMP_R8_BASE);

      INSERT INTO S_LDZLB_TAKSUV
         (SELECT * FROM S_LDZLB_TMP_TAKSUV);

      S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                             'S_TMP_ldzlb_TAKSUV');

      INSERT INTO S_LDZLB_TAKSUV_R7 (NOMMAR_ID,
                                     NOMMAR,
                                     NOMROW,
                                     timeout,
                                     TIMEIN,
                                     KODDOR,
                                     KODST,
                                     NOMTRAIN,
                                     KODWORK,
                                     KODPD,
                                     LINDIST_R7,
                                     WNETTO,
                                     WBRUTTO,
                                     FACTTIME_R7,
                                     PRZMINABRGST_R7,
                                     KOLVANTVAG,
                                     KOLPORVAG,
                                     KILKOSEY,
                                     KILVAG,
                                     KODSERLOK,
                                     NOMLOK,
                                     ROBOTA,
                                     promstprost,
                                     promstmanevr,
                                     tkmworkneto_r7,
                                     tkmworkbryto_r7,
                                     prpromst_r7,
                                     prprypst_r7,
                                     proborotst_r7,
                                     mpromst_r7,
                                     moborotst_r7,
                                     mprypst_r7,
                                     prprypdepo_r7,
                                     proborotdepo_r7,
                                     nagin,
                                     kilkst,
                                     ktydinner,
                                     nom_row_u7,
                                     enor,
                                     prst_r7,
                                     manst_r7,
                                     IDF_MM)
         (SELECT NOMMAR_ID,
                 NOMMAR,
                 NOMROW,
                 timeout,
                 TIMEIN,
                 KODDOR,
                 KODST,
                 NOMTRAIN,
                 KODWORK,
                 KODPD,
                 LINDIST_R7,
                 WNETTO,
                 WBRUTTO,
                 FACTTIME_R7,
                 PRZMINABRGST_R7,
                 KOLVANTVAG,
                 KOLPORVAG,
                 KILKOSEY,
                 KILVAG,
                 KODSERLOK,
                 NOMLOK,
                 ROBOTA,
                 promstprost,
                 promstmanevr,
                 tkmworkneto_r7,
                 tkmworkbryto_r7,
                 prpromst_r7,
                 prprypst_r7,
                 proborotst_r7,
                 mpromst_r7,
                 moborotst_r7,
                 mprypst_r7,
                 prprypdepo_r7,
                 proborotdepo_r7,
                 nagin,
                 kilkst,
                 ktydinner,
                 nom_row_u7,
                 enor,
                 prst_r7,
                 manst_r7,
                 IDF_MM
            FROM S_LDZLB_TMP_TAKSUV_R7);

      S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                             'S_TAKSUV_R7');


      S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                             'Данные записаны');
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'Немаэ даних');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
      WHEN OTHERS
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'OTHERS MAIN');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
   END;

   PROCEDURE WRITE_TABLE_LM003 (MSG IN OUT S_T_UZXDOC_MESSAGE)
   IS
   BEGIN
      MSG.EXITCODE := 0;


      INSERT INTO S_LDZLB_TAKSUV
         (SELECT * FROM S_ldzlb_tmp_TAKSUV);

      INSERT INTO S_LDZLB_TAKSUV_R7 (NOMMAR_ID,
                                     NOMMAR,
                                     NOMROW,
                                     timeout,
                                     TIMEIN,
                                     KODDOR,
                                     KODST,
                                     NOMTRAIN,
                                     KODWORK,
                                     KODPD,
                                     LINDIST_R7,
                                     WNETTO,
                                     WBRUTTO,
                                     FACTTIME_R7,
                                     PRZMINABRGST_R7,
                                     KOLVANTVAG,
                                     KOLPORVAG,
                                     KILKOSEY,
                                     KILVAG,
                                     KODSERLOK,
                                     NOMLOK,
                                     ROBOTA,
                                     promstprost,
                                     promstmanevr,
                                     tkmworkneto_r7,
                                     tkmworkbryto_r7,
                                     prpromst_r7,
                                     prprypst_r7,
                                     proborotst_r7,
                                     mpromst_r7,
                                     moborotst_r7,
                                     mprypst_r7,
                                     prprypdepo_r7,
                                     proborotdepo_r7,
                                     nagin,
                                     kilkst,
                                     ktydinner,
                                     nom_row_u7,
                                     enor,
                                     prst_r7,
                                     manst_r7,
                                     IDF_MM)
         (SELECT NOMMAR_ID,
                 NOMMAR,
                 NOMROW,
                 timeout,
                 TIMEIN,
                 KODDOR,
                 KODST,
                 NOMTRAIN,
                 KODWORK,
                 KODPD,
                 LINDIST_R7,
                 WNETTO,
                 WBRUTTO,
                 FACTTIME_R7,
                 PRZMINABRGST_R7,
                 KOLVANTVAG,
                 KOLPORVAG,
                 KILKOSEY,
                 KILVAG,
                 KODSERLOK,
                 NOMLOK,
                 ROBOTA,
                 promstprost,
                 promstmanevr,
                 tkmworkneto_r7,
                 tkmworkbryto_r7,
                 prpromst_r7,
                 prprypst_r7,
                 proborotst_r7,
                 mpromst_r7,
                 moborotst_r7,
                 mprypst_r7,
                 prprypdepo_r7,
                 proborotdepo_r7,
                 nagin,
                 kilkst,
                 ktydinner,
                 nom_row_u7,
                 enor,
                 prst_r7,
                 manst_r7,
                 IDF_MM
            FROM S_LDZLB_TMP_TAKSUV_R7);

      S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                             'Данные записаны');
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'Немаэ даних');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
      WHEN OTHERS
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'OTHERS MAIN');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
   END;

   PROCEDURE MSG_NSI (MSG IN OUT S_T_UZXDOC_MESSAGE)
   IS
      depo_   S_V_ITF_MAIN_MM_MSG.kpz%TYPE;
   BEGIN
      MSG.EXITCODE := 1;

      /*SELECT *
        INTO depo_
        FROM S_V_ITF_MAIN_MM_MSG
       WHERE (CODE_OP = 12 OR CODE_OP = 300) AND DATA_SOURCE = 0;*/

      SELECT OZN_TCHU
        INTO depo_
        FROM S_LD_PIDPR_ASU_T a, S_V_ITF_MAIN_MM_MSG b
       WHERE b.DATA_SOURCE = 0 AND a.ID_PIDPR = b.kpz;

      IF (depo_ = 1)
      THEN
         MSG.EXITCODE := 0;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'Немаэ даних');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
      WHEN OTHERS
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'OTHERS MAIN');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
         MSG.EXITCODE := 1;
   END;
END INSERT_LM12_MD_MM;
/