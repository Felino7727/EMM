CREATE OR REPLACE PACKAGE BODY APPL_DBW.EMM_NEW 
IS
   KOL_STR       NUMBER;
   KOL_STR_TPS   NUMBER;
   P_OZN_EMM     NUMBER;
   CNT_DAT       NUMBER;

   PROCEDURE ERR_MSG
   IS
   BEGIN
      DBMS_OUTPUT.put_line (
         'Неможливо сформувати електронний маршрут');
      S_MESSAGE_0497.SET_F1_CODE_ERR (1 || 0);
      S_MESSAGE_0497.FRAZA2 (
         100,
         NULL,
         1,
         0,
         NULL,
         0,
         'Неможливо сформувати електронний маршрут',
         1,
         NULL,
         NULL,
         NULL,
         NULL);
   END;

   --Формирование разделов 1,3
   PROCEDURE PART_1_3 (MSG IN OUT S_T_UZXDOC_MESSAGE)
   IS
      /*V_KPZ           S_ITF_MAIN_MM.KPZ%TYPE;
      X_NOM_MRM       TMP_EMM.NOM_MM%TYPE;
      X_DEPO_PRIP     S_V_ITF_MAIN_BRIG_DB.DEPO_PRIP%TYPE;
      X_DEPO_TOUR     S_V_ITF_MAIN_BRIG_DB.DEPO_TOUR%TYPE;
      X_TALON         S_V_ITF_MAIN_BRIG_DB.TALON%TYPE;
      X_DOLG_MM       S_ITF_SUBS_BRIG_MM.DOLG_MM%TYPE;
      X_MESAGE        S_ITF_KEY_MSG.KOD_MESS%TYPE;
      X_JAVKA         S_ITF_MAIN_MM.JAVKA%TYPE;
      P_CODE_OP       S_V_ITF_MAIN_BRIG_MSG.CODE_OP%TYPE;
      X_DATA_SOURCE   NUMBER;*/
      P_CODE_OP       S_V_ITF_MAIN_BRIG_MSG.CODE_OP%TYPE;
      X_DATA_SOURCE   NUMBER;
      KOL_STR         NUMBER;
   BEGIN
      MSG.EXITCODE := 0;

      /* SELECT DISTINCT CODE_OP
         INTO P_CODE_OP
         FROM S_V_ITF_MAIN_BRIG_MSG
        WHERE PR_MASH = 1;*/

      --VV 20.02.2018
      /* CASE
          WHEN P_CODE_OP IN (28, 29, 35)
          THEN
             X_DATA_SOURCE := 0;                     --Помечаем грани на запись
          WHEN P_CODE_OP IN (31, 37, 137)
          THEN
             X_DATA_SOURCE := -1;                 --не Помечаем грани на запись
          ELSE
             X_DATA_SOURCE := 0;
       END CASE;*/

      -- SELECT KOD_MESS INTO X_MESAGE FROM S_ITF_KEY_MSG;
      --VV 20.02.2018
      --высчитуем явку
      /*  CASE X_MESAGE
            WHEN 'LM011'
            THEN
                SELECT a.TIME_YAVKA
                  INTO X_JAVKA
                  FROM S_V_ITF_MAIN_BRIG_MSG a, TMP_EMM B
                 WHERE a.IDF_BRIG = B.IDF_BRIG;
            WHEN 'LM001'
            THEN
                SELECT a.TIME_YAVKA
                  INTO X_JAVKA
                  FROM S_V_ITF_MAIN_BRIG_MSG a, TMP_EMM B
                 WHERE a.IDF_BRIG = B.IDF_BRIG;
            WHEN '0260'
            THEN
                BEGIN
                    SELECT a.TIME_YAVKA
                      INTO X_JAVKA
                      FROM S_V_ITF_MAIN_BRIG_MSG a, TMP_EMM B
                     WHERE a.IDF_BRIG = B.IDF_BRIG;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        SELECT a.TIME_YAVKA
                          INTO X_JAVKA
                          FROM S_V_ITF_MAIN_BRIG_DB a, TMP_EMM B
                         WHERE a.IDF_BRIG = B.IDF_BRIG;
                END;
            ELSE
                X_JAVKA   := NULL;
        END CASE;*/

      --Запись в интерфейсную таблицу  S_ITF_MAIN_MM <-- S_V_ITF_MAIN_BRIG_MSG, S_V_ITF_MAIN_BRIG_DB
      INSERT INTO S_ITF_MAIN_MM (TMP_IDF_OBJ,
                                 CODE_OP,
                                 DATE_OP,
                                 NOM_MRM,
                                 DEPO,
                                 DATE_MM,
                                 JAVKA,
                                 OPER_TYPE,
                                 TYPE_MM,
                                 NUM_COLUMN,
                                 KPZ,
                                 DATE_CALC,
                                 DEPO_PR_KOL,
                                 DATA_SOURCE,
                                 TYPE_RAB,
                                 TYPE_OBJ_JAVKA,
                                 CODE_OBJ_JAVKA                            --,
                                               --OZN_POIZDKY
                                 )
         (SELECT 1,
                 51 CODE_OP,
                 TRUNC (MSG.DATE_OP, 'dd'),
                 TMP.NOM_MM,
                 TMP.DEPO_OBLIC,
                 TO_CHAR (MSG.DATE_OP, 'YYYYMM'),
                 DECODE (MSG.TIME_YAVKA, NULL, BD.TIME_YAVKA, MSG.TIME_YAVKA) --X_JAVKA
                                                                             , --msg.TIME_YAVKA,
                 S_WRITE_TO_MODELS.OP_OPEN_OBJECT OPER_TYPE,
                 1 TYPE_MM,
                 BD.NUM_COLUMN,
                 TMP.DEPO_TCHU,
                 TRUNC (MSG.DATE_OP, 'dd'),
                 TMP.DEPO_KOL,
                 0,                                          -- X_DATA_SOURCE,
                 SUBSTR (MSG.VID_ROB, 0, 1),
                 DECODE (LENGTH (MSG.ESR_OP),  4, 205,  6, 201), --кол-во знаков
                 MSG.ESR_OP /*,
                  DECODE (MSG.ESR_OP,
                          TMP.DEPO_KOL, 1,
                          (SELECT KOD_ESR
                             FROM ASKVP_VIEW.V_LD_ESR_DEPO
                            WHERE ID_DEPO = TMP.DEPO_KOL), 1,
                          2)*/
            FROM S_V_ITF_MAIN_BRIG_MSG MSG,
                 S_V_ITF_MAIN_BRIG_DB BD,
                 TMP_EMM TMP
           WHERE MSG.IDF_BRIG = BD.IDF_BRIG AND MSG.IDF_BRIG = TMP.IDF_BRIG);

      KOL_STR := SQL%ROWCOUNT;

      S_LOG_WORK.ADD_RECORD (
         S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
         'Записей - S_ITF_MAIN_MM = ' || KOL_STR || 'ExitCode := 0');

      DBMS_OUTPUT.put_line (' Записей - S_ITF_MAIN_MM = ' || KOL_STR);

      IF NVL (KOL_STR, 0) != 0
      THEN
         --Запись в интерфейсную таблицу  S_ITF_SUBS_BRIG_MM <-- S_V_ITF_MAIN_BRIG_MSG, S_V_ITF_MAIN_BRIG_DB

         INSERT INTO S_ITF_SUBS_BRIG_MM (TMP_IDF_OBJ,
                                         IDF_BRIG,
                                         TAB_BRIG,
                                         DEPO_PRIP,
                                         FAM_BRIG,
                                         --DOLG_BRIG,
                                         CLASS_MASH,
                                         DOLG_MM,
                                         OZN_MASH,
                                         DATE_BEG_RAB)
            (SELECT DISTINCT
                    1,
                    SVIMBM.IDF_BRIG,
                    SVIMBD.TAB_NOM,
                    SVIMBD.DEPO_PRIP,
                    SVIMBD.FAM                                             --,
                              --SVIMBD.JOB
                              /*DECODE( B.POS_OZNAKA
                                      ,NULL, SVIMBD.JOB
                                      ,B.POS_OZNAKA)*/
                    ,
                    SVIMBD.CLASS_MASH,
                    DECODE (SVIMBM.PR_MASH, NULL, 1, SVIMBM.PR_MASH), -- для 0260 сообщения!
                    SVIMBD.OZN_ST_MASH --SVIMBM.OZN_ST_MASH                         --a.OZN_ST_MASH
                                      ,
                    SVIMBM.TIME_YAVKA
               FROM S_V_ITF_MAIN_BRIG_MSG SVIMBM, S_V_ITF_MAIN_BRIG_DB SVIMBD
              --,S_V_FULL_BRIG_ONLINE a
              --,VIEW_EMM B
              WHERE SVIMBM.IDF_BRIG = SVIMBD.IDF_BRIG --AND a.IDF_BRIG = SVIMBM.IDF_BRIG --AND B.IDF_POSAD = SVIMBD.JOB
                                                     --AND B.TYPE_MM = SVIMBM.PR_MASH
                                                     --AND (    B.VID_ROB = SVIMBM.VID_ROB
                                                     --    OR 1 = 1 AND B.VID_ROB IS NULL )
            );

         --Обновляем DOLG_BRIG
         /* FOR J IN ( SELECT IDF_BRIG, DOLG_BRIG FROM S_ITF_SUBS_BRIG_MM )
          LOOP
              UPDATE S_ITF_SUBS_BRIG_MM
                 SET DOLG_BRIG      = ( NVL(
                                             ( SELECT B.POS_OZNAKA
                                                 FROM VIEW_EMM B
                                                     ,S_V_ITF_MAIN_BRIG_DB SVIMBD
                                                     ,S_V_ITF_MAIN_BRIG_MSG SVIMBM
                                                WHERE     SVIMBM.IDF_BRIG =
                                                              J.IDF_BRIG
                                                      AND SVIMBD.IDF_BRIG =
                                                              SVIMBM.IDF_BRIG
                                                      AND B.IDF_POSAD =
                                                              SVIMBD.JOB
                                                      AND B.TYPE_MM =
                                                              SVIMBM.PR_MASH
                                                      AND B.VID_ROB =
                                                              SVIMBM.VID_ROB )
                                            ,J.DOLG_BRIG ) )
               WHERE IDF_BRIG = J.IDF_BRIG;
          END LOOP;*/

         -- Помечаем грани на запись
         S_WRITE_TO_MODELS.MARK_STATE_FOR_CHANGE ('MM', 'DOC');
      --VV 20.02.2018
      /*  IF X_DATA_SOURCE != -1
        THEN
            S_WRITE_TO_MODELS.MARK_STATE_FOR_CHANGE( 'MM', 'DOC' );
        ELSE
            S_LOG_WORK.ADD_RECORD(
                                   S_CHANGEDOM_PROC.GETVALUE(
                                                              'IDF_EVENT' )
                                  ,'Считали с сообщения' );
        END IF;*/
      ELSE
         S_LOG_WORK.ADD_RECORD (
            S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
            'Ошибка S_ITF_SUBS_BRIG_MM, ExitCode := 1');
         MSG.EXITCODE := 1;
         ERR_MSG;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         MSG.EXITCODE := 1;
         ERR_MSG;
      WHEN OTHERS
      THEN
         MSG.EXITCODE := 3;
         --ERR_MSG;
         S_LOG_WORK.ADD_RECORD (
            S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
            (   ' Ошибка!!! Выход по гл.exception'
             || SUBSTR (SQLERRM, 1, 230)));
   END;

   --Считывание разделов 1,3
   PROCEDURE PART_MM_READ (MSG IN OUT S_T_UZXDOC_MESSAGE)
   IS
   BEGIN
      MSG.EXITCODE := 0;

      SELECT NVL (OZN_EMM, 0) INTO P_OZN_EMM FROM tmp_emm;

      DBMS_OUTPUT.put_line (' p_ozn_emm = ' || P_OZN_EMM);

      IF (P_OZN_EMM = 0)
      THEN                                              -- проверка на чтение!
         MSG.EXITCODE := 1;
         DBMS_OUTPUT.put_line (' p_ozn_emm = 0 && Msg.ExitCode := 1');
      ELSE
         BEGIN
            --Запись в интерфейсную таблицу  S_ITF_MAIN_MM <-- S_SREZ_ACTUAL_MM
            INSERT INTO S_ITF_MAIN_MM (TMP_IDF_OBJ,
                                       IDF_MM,
                                       IDF_DOC,
                                       CODE_OP,
                                       DATE_OP,
                                       NOM_MRM,
                                       DEPO,
                                       JAVKA,
                                       DATE_MM,
                                       TYPE_MM,
                                       NUM_COLUMN,
                                       DATA_SOURCE,
                                       KPZ,
                                       DEPO_PR_KOL,
                                       TYPE_RAB,
                                       TYPE_OBJ_JAVKA,
                                       CODE_OBJ_JAVKA,
                                       OZN_POIZDKY)
               (SELECT SSAM.IDF_DOC TMP_IDF_OBJ,
                       SSAM.IDF_MM,
                       SSAM.IDF_DOC,
                       SSAM.CODE_OP CODE_OP,
                       TRUNC (SVIMSG.DATE_OP, 'dd') DATE_OP, ----S_V_ITF_MAIN_BRIG_MSG SVIMSG
                       SSAM.NOM_MRM NOM_MRM,
                       SSAM.DEPO DEPO,
                       DECODE (SSAM.JAVKA,
                               NULL, SVIMSG.TIME_YAVKA, ---------S_V_ITF_MAIN_BRIG_MSG SVIMSG
                               SSAM.JAVKA)
                          JAVKA,
                       SSAM.DATE_MM DATE_MM,
                       SSAM.TYPE_MM TYPE_MM,
                       SSAM.NUM_COLUMN NUM_COLUMN,
                       0,                                     --1 DATA_SOURCE,
                       SSAM.KPZ KPZ,
                       SSAM.DEPO_PR_KOL,
                       SSAM.TYPE_RAB,
                       SSAM.TYPE_OBJ_JAVKA,
                       SSAM.CODE_OBJ_JAVKA,
                       SSAM.OZN_POIZDKY
                  FROM S_SREZ_ACTUAL_MM SSAM,
                       TMP_EMM STE,
                       S_V_ITF_MAIN_BRIG_DB SVIMBD,
                       S_V_ITF_MAIN_BRIG_MSG SVIMSG
                 WHERE     SSAM.NOM_MRM = STE.NOM_MM
                       AND SSAM.DEPO = STE.DEPO_OBLIC
                       AND SSAM.DATE_MM =
                              TO_CHAR (SVIMBD.TIME_YAVKA, 'YYYYMM')
                       AND SVIMBD.PR_MASH = 1
                       AND SSAM.TYPE_MM = 1
                       AND STE.IDF_BRIG = SVIMBD.IDF_BRIG
                       AND STE.IDF_BRIG = SVIMSG.IDF_BRIG);

            KOL_STR := SQL%ROWCOUNT;
            DBMS_OUTPUT.put_line (' записей = ' || KOL_STR);
            S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                   'записей  - kol_str = ' || KOL_STR);

            IF KOL_STR != 0
            THEN                                     --Для переходного периода
               --Запись в интерфейсную таблицу  S_ITF_SUBS_BRIG_MM <-- SUBS_BRIG_MM
               INSERT INTO S_ITF_SUBS_BRIG_MM (TMP_IDF_OBJ,
                                               IDF_BRIG,
                                               TAB_BRIG,
                                               DEPO_PRIP,
                                               FAM_BRIG,
                                               --DOLG_BRIG,
                                               CLASS_MASH,
                                               DOLG_MM)
                  (SELECT SBM.IDF_DOC TMP_IDF_OBJ,
                          SBM.IDF_BRIG IDF_BRIG,
                          SBM.TAB_BRIG TAB_BRIG,
                          SBM.DEPO_PRIP DEPO_PRIP,
                          SBM.FAM_BRIG FAM_BRIG,
                          --SBM.DOLG_BRIG DOLG_BRIG,
                          SBM.CLASS_MASH CLASS_MASH,
                          SBM.DOLG_MM DOLG_MM
                     FROM S_SUBS_BRIG_MM SBM, S_ITF_MAIN_MM SIMM
                    WHERE SBM.IDF_DOC = SIMM.TMP_IDF_OBJ);

               DBMS_OUTPUT.put_line (' cnt_zak != 0 && Msg.ExitCode := 0');
               S_LOG_WORK.ADD_RECORD (
                  S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                  'cnt_zak != 0 && Msg.ExitCode := 0 ');
            ELSE
               MSG.EXITCODE := 1;

               UPDATE tmp_emm
                  SET OZN_EMM = 0;

               DBMS_OUTPUT.put_line (' Msg.ExitCode := 1( OK!!!)');
               S_LOG_WORK.ADD_RECORD (
                  S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                  'Msg.ExitCode := 1( OK!!!) ');
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               MSG.EXITCODE := 1;
         END;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         S_LOG_WORK.ADD_RECORD (
            S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
            (' Ошибка!!! PART_MM_READ выход по гл.exception'));

         ERR_MSG;
   END;

   --Главная процедура
   PROCEDURE MAIN (MSG IN OUT S_T_UZXDOC_MESSAGE)
   IS
      P_CODE_OP   S_V_ITF_MAIN_BRIG_MSG.CODE_OP%TYPE;
   --P_MM        tmp_emm.NOM_MM%TYPE;
   BEGIN
      --выход если нет маршрута машиниста

      -- SELECT NOM_MM INTO P_MM FROM TMP_EMM;


      -- Вывод сообщения, если нет NOM_MM
      /* IF NVL( P_MM, 0 ) = 0
       THEN
           S_LOG_WORK.ADD_RECORD( S_CHANGEDOM_PROC.GETVALUE( 'IDF_EVENT' )
                                 ,'Нет номера маршрута ' );
       -- Err_Msg;
       END IF;*/


      -- Выполняем если есть NOM_MM (определение кода операции)
      --  IF NVL( P_MM, 0 ) != 0
      -- THEN
      SELECT DISTINCT CODE_OP INTO P_CODE_OP FROM S_V_ITF_MAIN_BRIG_MSG;

      DBMS_OUTPUT.put_line (' p_code_op  = ' || P_CODE_OP);

      CASE
         WHEN P_CODE_OP IN (28, 29, 35)
         THEN
            S_LOG_WORK.ADD_RECORD (
               S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
               'Явка - p_code_op = ' || P_CODE_OP || 'ExitCode := 0');

            MSG.EXITCODE := 0;
         WHEN P_CODE_OP IN (31, 37, 137)
         THEN
            S_LOG_WORK.ADD_RECORD (
               S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
               'Отдых - p_code_op = ' || P_CODE_OP || 'ExitCode := 1');

            MSG.EXITCODE := 1;
         ELSE
            S_LOG_WORK.ADD_RECORD (
               S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                  'Другая операция - p_code_op = '
               || P_CODE_OP
               || 'ExitCode := 2');

            MSG.EXITCODE := 2;
            ERR_MSG;
      END CASE;
   /* ELSE
        S_LOG_WORK.ADD_RECORD(
                               S_CHANGEDOM_PROC.GETVALUE( 'IDF_EVENT' )
                              ,   'Нет маршрута машиниста = '
                               || P_MM
                               || 'ExitCode := 3' );

        MSG.EXITCODE   := 3;
        ERR_MSG;
    END IF;*/

   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         S_LOG_WORK.ADD_RECORD (
            S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
            ('NO_DATA_FOUND!!! MAIN_MM выход по гл.exception'));

         MSG.EXITCODE := 3;
         ERR_MSG;
      WHEN OTHERS
      THEN
         S_LOG_WORK.ADD_RECORD (
            S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
            ('OTHERS!!! MAIN_MM выход по гл.exception'));

         --MSG.EXITCODE   := 3;
         ERR_MSG;
   END;

   -- Дописуем не достоющие данные
   PROCEDURE UPDATE_MM (MSG IN OUT S_T_UZXDOC_MESSAGE)
   IS
      MM          S_ITF_MAIN_MM%ROWTYPE;
      /*P_DATE_BEG      S_ITF_MAIN_MM.PRIEM%TYPE;
      P_DATE_RAB      S_ITF_MAIN_MM.DATE_RAB%TYPE;
      P_SD_LOK        S_ITF_MAIN_MM.SD_LOK%TYPE;
      P_PRIEM_END     S_ITF_MAIN_MM.PRIEM_END%TYPE;
      P_SD_LOK_BEG    S_ITF_MAIN_MM.SD_LOK_BEG%TYPE;*/
      P_IDF_TPS   S_ITF_SUBS_LOK_MM.IDF_TPS%TYPE;
      -- S_PROV          S_ITF_MAIN_MM.OPER_TYPE%TYPE;
      P_CODE_OP   S_ITF_MAIN_TPS.CODE_OP%TYPE;
      --N_IDF_DOC       S_ITF_MAIN_MM.IDF_DOC%TYPE;
      --P_OZN_EMM       tmp_emm.OZN_EMM%TYPE;
      -- N_IDF_TPS       tmp_emm.IDF_TPS%TYPE;
      --N_TMP_IDF_OBJ   tmp_emm.TMP_IDF_OBJ%TYPE;
      --P_D_END_LUNCH   S_ITF_MAIN_MM.D_END_LUNCH%TYPE;
      --P_D_BEG_LUNCH   S_ITF_MAIN_MM.D_BEG_LUNCH%TYPE;
      --N_PRIEM         DATE;
      --N_DATE_OP       DATE;
      -- N_KOD_SEK       NUMBER;
      -- N_DATA_SOURCE   NUMBER;
      --KOL_STR_SBO     NUMBER;
      --D_SOURCE        NUMBER;
      D_GR1       NUMBER;
      D_GR2       NUMBER;
      --TRO             NUMBER;
      -- XXX             NUMBER;
      PROVERKA1   NUMBER;
      PROVERKA2   NUMBER;
      PROVERKA3   NUMBER;
      CODE_OP_    S_ITF_MAIN_BRIG.CODE_OP%TYPE;
      -- D_DATE_SOURCE   NUMBER;
      X_CODE_OP   NUMBER;
      kol         NUMBER;
   --X_KOD_ESR       S_ITF_MAIN_TPS.KOD_OBJ_DISL%TYPE;
   --X_ID_DEPO       ASKVP_VIEW.V_LD_ESR_DEPO.ID_DEPO%TYPE;
   -- NACH_           TMP_RABOTA_MM.NACH%TYPE;
   --KONEC_          TMP_RABOTA_MM.KONEC%TYPE;
   --Z_TIP_PARKA_    S_ITF_SUBS_P_RPS_MM.Z_TIP_PARKA%TYPE;
   BEGIN
      MSG.EXITCODE := 0;

      BEGIN
         --SELECT CODE_OP INTO X_CODE_OP FROM S_ITF_MAIN_MM;     --VV 27.02.2018
         SELECT * INTO MM FROM S_ITF_MAIN_MM;
      -- WHERE DATA_SOURCE IN (1, -1)
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            MM.code_op := NULL;
      --X_CODE_OP := NULL;
      END;

      IF (MM.code_op = 51)
      THEN
         /* BEGIN
              SELECT D_END_LUNCH, D_BEG_LUNCH  --считуем информацию про обед
                INTO P_D_END_LUNCH, P_D_BEG_LUNCH
                FROM S_V_ITF_MAIN_MM_MSG;
          EXCEPTION
              WHEN OTHERS
              THEN
                  P_D_END_LUNCH   := NULL;
                  P_D_BEG_LUNCH   := NULL;
          END;*/
         --VV 27.02.2018
         /*SELECT DISTINCT DATA_SOURCE
           INTO D_DATE_SOURCE
           FROM S_ITF_MAIN_MM;
          WHERE DATA_SOURCE IN (-1, 1)*/

         /*UPDATE S_ITF_MAIN_MM a --Обновляем в S_ITF_MAIN_MM <--------- d_end_lunch, d_beg_lunch
            SET a.D_END_LUNCH   = P_D_END_LUNCH
               ,a.D_BEG_LUNCH   = P_D_BEG_LUNCH
          WHERE DATA_SOURCE = D_DATE_SOURCE;*/
         MM.D_END_LUNCH := NULL;
         MM.D_BEG_LUNCH := NULL;

         UPDATE S_ITF_MAIN_MM --Обновляем в S_ITF_MAIN_MM <---------  END_RAB, DATE_CALC, br_time_rab
            SET (END_RAB,
                 DATE_CALC,
                 BR_TIME_RAB,
                 TYPE_OBJ_END_RAB,
                 CODE_OBJ_END_RAB,
                 CODE_OP                                           --,DATE_RAB
                        -- ,PRIEM     --22.12.2017
                        --,SD_LOK     --22.12.2017
                        --,PRIEM_END    --22.12.2017
                        --,SD_LOK_BEG   --22.12.2017
                 ) =
                   (SELECT MSG.DATE_OP END_RAB,
                           TRUNC (MSG.DATE_OP, 'dd') DATE_CALC,
                           DECODE (
                              MM.D_END_LUNCH,
                              NULL, CASE
                                       WHEN (MSG.DATE_OP - MM.JAVKA) --MSG.TIME_JAVKA
                                                                    * 1440 >=
                                               1440
                                       THEN
                                          NULL
                                       ELSE
                                          (MSG.DATE_OP - MM.JAVKA) --MSG.TIME_JAVKA
                                                                  * 1440
                                    END)
                              AS BR_TIME_RAB,
                           DECODE (LENGTH (MSG.ESR_OP),  4, 205,  6, 201),
                           MSG.ESR_OP,
                           52
                      /*,DECODE(
                               a.DATE_END
                              ( SELECT a.DATE_END
                                  FROM S_ST_DISL_BRIG a
                                      ,S_V_ITF_MAIN_BRIG_MSG MSG
                                      ,Tmp_Emm B
                                 WHERE     a.IDF_BRIG =
                                               B.IDF_BRIG
                                       AND a.DATE_BEG BETWEEN MSG.TIME_YAVKA
                                                          AND MSG.DATE_OP
                                       AND a.TYPE_OBJ_DISL =
                                               103
                                       AND MSG.PR_MASH =
                                               1
                                       AND ROWNUM =
                                               1 )
                              ,GET_MAX_DATE, MSG.DATE_OP
                              ,a.DATE_END ( SELECT a.DATE_END
                                    FROM S_ST_DISL_BRIG a
                                        ,S_V_ITF_MAIN_BRIG_MSG MSG
                                        ,Tmp_Emm B
                                   WHERE     a.IDF_BRIG =
                                                 B.IDF_BRIG
                                         AND a.DATE_BEG BETWEEN MSG.TIME_YAVKA
                                                            AND MSG.DATE_OP
                                         AND a.TYPE_OBJ_DISL =
                                                 103
                                         AND MSG.PR_MASH =
                                                 1
                                         AND ROWNUM =
                                                 1 )
                                          )
                                          ,a.DATE_BEG--22.12.2017
                                          ,DECODE( a.DATE_END
     ,GET_MAX_DATE, MSG.DATE_OP
     ,a.DATE_END )--22.12.2017
     ,a.DATE_BEG--22.12.2017
     ,DECODE( a.DATE_END
     ,GET_MAX_DATE, MSG.DATE_OP
     ,a.DATE_END )--22.12.2017*/
                      FROM S_V_ITF_MAIN_BRIG_MSG MSG, TMP_EMM TMP --22.12.2017
                     --,S_ST_DISL_BRIG a
                     WHERE MSG.IDF_BRIG = TMP.IDF_BRIG            --22.12.2017
                                                       -- a.TYPE_OBJ_DISL = 103
                           AND MSG.PR_MASH = 1 -- AND a.DATE_BEG BETWEEN MSG.TIME_YAVKA
                                              --                    AND MSG.DATE_OP
                                              -- AND a.IDF_BRIG = MSG.IDF_BRIG
                                              -- AND ROWNUM = 1
                   );

         --WHERE DATA_SOURCE = D_DATE_SOURCE

         UPDATE S_ITF_SUBS_BRIG_MM            --Обновляем в S_ITF_SUBS_BRIG_MM
            SET (DATE_END_RAB) =
                   (SELECT MSG.DATE_OP
                      FROM S_V_ITF_MAIN_BRIG_MSG MSG
                           JOIN Tmp_Emm TMP ON MSG.IDF_BRIG = TMP.IDF_BRIG);


         SELECT NVL (OZN_EMM, 0) INTO P_OZN_EMM FROM tmp_emm; --Определяем ozn_emm

         --VV 27.02.2018
         IF P_OZN_EMM = 1
         THEN                                --Условие для переходного периода
            UPDATE S_ITF_MAIN_MM SIMM --Обновляем в S_ITF_MAIN_MM если ozn_emm =1 <---------  CODE_OP и OPER_TYPE
               SET                                             --CODE_OP = 52,
                  SIMM.OPER_TYPE = S_WRITE_TO_MODELS.OP_CHANGE_OBJECT;
         --WHERE DATA_SOURCE = D_DATE_SOURCE
         ELSE
            UPDATE S_ITF_MAIN_MM SIMM --Обновляем в S_ITF_MAIN_MM если ozn_emm =0 <---------  CODE_OP и OPER_TYPE
               SET                                             --CODE_OP = 52,
                  OPER_TYPE = S_WRITE_TO_MODELS.OP_OPEN_OBJECT;
         --WHERE DATA_SOURCE = D_DATE_SOURCE
         END IF;

         -- KOL_STR := SQL%ROWCOUNT;

         /* --Находим переменные  date_beg, sd_lok, idf_tps
          begin
          UPDATE S_ITF_MAIN_MM SIMM
             SET (SIMM.PRIEM ,
                 SIMM.SD_LOK ,
                 SIMM.PRIEM_END,
                 SIMM.SD_LOK_BEG,
                 SIMM.DATE_RAB)=(SELECT DISL.DATE_BEG PRIEM,
                    DECODE (DISL.DATE_END,
                            GET_MAX_DATE, MSG.DATE_OP,
                            DISL.DATE_END)
                       SD_LOK,
                    --DISL.CODE_OBJ_DISL IDF_TPS,
                    DISL.DATE_BEG,
                    DECODE (DISL.DATE_END,
                            GET_MAX_DATE, MSG.DATE_OP,
                            DISL.DATE_END),
                    DECODE (DISL.DATE_END,
                            GET_MAX_DATE, MSG.DATE_OP,
                            DISL.DATE_END)
               FROM S_V_ITF_MAIN_BRIG_MSG MSG
                    JOIN S_ST_DISL_BRIG DISL ON (MSG.IDF_BRIG = DISL.IDF_BRIG)
              WHERE     MSG.PR_MASH = 1
                    AND DISL.STATUS = 0
                    AND DISL.TYPE_OBJ_DISL = 103
                    AND DISL.DATE_BEG BETWEEN MSG.TIME_YAVKA AND MSG.DATE_OP);
          -- WHERE DATA_SOURCE = D_DATE_SOURCE
          EXCEPTION
             WHEN OTHERS
             THEN

          end; */
         --VV 27.02.2018
         BEGIN
            SELECT DISL.DATE_BEG PRIEM,
                   DECODE (DISL.DATE_END,
                           GET_MAX_DATE, MSG.DATE_OP,
                           DISL.DATE_END)
                      SD_LOK,
                   DISL.CODE_OBJ_DISL IDF_TPS,
                   DISL.DATE_BEG,
                   DECODE (DISL.DATE_END,
                           GET_MAX_DATE, MSG.DATE_OP,
                           DISL.DATE_END),
                   DECODE (DISL.DATE_END,
                           GET_MAX_DATE, MSG.DATE_OP,
                           DISL.DATE_END)
              INTO MM.priem,                                     --P_DATE_BEG,
                   MM.sd_lok,                                      --P_SD_LOK,
                   P_IDF_TPS,
                   MM.priem_end,                                --P_PRIEM_END,
                   MM.sd_lok_beg,                              --P_SD_LOK_BEG,
                   MM.date_rab                                    --P_DATE_RAB
              FROM S_V_ITF_MAIN_BRIG_MSG MSG
                   JOIN S_ST_DISL_BRIG DISL ON (MSG.IDF_BRIG = DISL.IDF_BRIG)
             WHERE     MSG.PR_MASH = 1
                   AND DISL.STATUS = 0
                   AND DISL.TYPE_OBJ_DISL = 103
                   AND DISL.DATE_BEG BETWEEN MSG.TIME_YAVKA AND MSG.DATE_OP;
         EXCEPTION
            WHEN OTHERS
            THEN                                               --VV 27.02.2018
               MM.priem := NULL;
               MM.sd_lok := NULL;
               P_IDF_TPS := NULL;
               MM.PRIEM_END := NULL;
               MM.SD_LOK_BEG := NULL;
               MM.DATE_RAB := NULL;
         END;


         --Обновляем в S_ITF_MAIN_MM <---------  PRIEM, SD_LOK, DATE_RAB

         UPDATE S_ITF_MAIN_MM SIMM
            SET SIMM.PRIEM = MM.priem,
                SIMM.SD_LOK = MM.SD_LOK,
                SIMM.PRIEM_END = MM.PRIEM_END,
                SIMM.SD_LOK_BEG = MM.SD_LOK_BEG,
                SIMM.DATE_RAB = MM.DATE_RAB;

         --WHERE DATA_SOURCE = D_DATE_SOURCE    --VV 27.02.2018

         --Обновляем в TMP_EMM <---------  idf_tps
         IF P_IDF_TPS IS NOT NULL
         THEN
            DBMS_OUTPUT.put_line (
               'p_idf_tps IS NOT NULL   p_idf_tps = ' || P_IDF_TPS);

            UPDATE tmp_emm
               SET IDF_TPS = P_IDF_TPS;

            DBMS_OUTPUT.put_line ('UPDATE tmp_emm  = ' || SQL%ROWCOUNT);
         END IF;


         --VV 27.02.2018
         /* UPDATE S_ITF_MAIN_MM      --Если была запись с сообщения а не с базы!
             SET data_source = 0
           WHERE data_source = -1;*/



         BEGIN
            IF NVL (P_IDF_TPS, 0) != 0
            THEN
               LOK_MM ();
               FUEL_MM ();

               SELECT COUNT (*)
                 INTO kol
                 FROM S_ITF_MAIN_TPS
                WHERE TYPE_OBJ_DISL = 110;

               IF NVL (kol, 0) != 0
               THEN
                  BEGIN
                     PART7_MM ();

                     BEGIN
                        PART4_MM ();

                        --VV 27.02.2018
                        /*UPDATE S_ITF_MAIN_MM --Если была запись с сообщения а не с базы!
                           SET DATA_SOURCE = 0
                         WHERE DATA_SOURCE = -1;*/

                        SELECT COUNT (*)                      --Если есть NULL
                          INTO PROVERKA2
                          FROM S_ITF_SUBS_LSLED_MM
                         WHERE    (SDATE_BEG IS NULL OR SDATE_END IS NULL)
                               OR (SDATE_BEG IS NULL AND SDATE_END IS NULL);

                        IF NVL (PROVERKA2, 0) > 0
                        THEN
                           DELETE FROM S_ITF_SUBS_LSLED_MM;

                           S_LOG_WORK.ADD_RECORD (
                              S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                              (' PART4_MM не формируем'));
                        END IF;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           DELETE FROM S_ITF_SUBS_LSLED_MM;

                           S_LOG_WORK.ADD_RECORD (
                              S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                              (' Ошибка!!! PART4_MM не отработал'));
                     END;

                     SELECT COUNT (*)                         --Если есть NULL
                       INTO PROVERKA1
                       FROM S_ITF_SUBS_POIZD_MM
                      WHERE    (SDATE_BEG IS NULL OR SDATE_END IS NULL)
                            OR (SDATE_BEG IS NULL AND SDATE_END IS NULL);

                     SELECT COUNT (*)                         --Если есть NULL
                       INTO PROVERKA3
                       FROM S_ITF_SUBS_P_RPS_MM
                      WHERE    (SDATE_BEG IS NULL OR SDATE_END IS NULL)
                            OR (SDATE_BEG IS NULL AND SDATE_END IS NULL);


                     IF NVL (PROVERKA1, 0) > 0
                     THEN
                        DELETE FROM S_ITF_SUBS_POIZD_MM;

                        DELETE FROM S_ITF_SUBS_RABOTA_PM_MM;

                        DELETE FROM S_ITF_SUBS_SOST_P_POIZD;

                        DELETE FROM S_ITF_SUBS_P_RPS_MM;

                        S_LOG_WORK.ADD_RECORD (
                           S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                           (' PART7_MM не формируем'));
                     END IF;


                     IF NVL (PROVERKA3, 0) > 0
                     THEN
                        DELETE FROM S_ITF_SUBS_POIZD_MM;

                        DELETE FROM S_ITF_SUBS_RABOTA_PM_MM;

                        DELETE FROM S_ITF_SUBS_SOST_P_POIZD;

                        DELETE FROM S_ITF_SUBS_P_RPS_MM;

                        S_LOG_WORK.ADD_RECORD (
                           S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                           (' PART7_MM не формируем'));
                     END IF;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        DELETE FROM S_ITF_SUBS_POIZD_MM;

                        DELETE FROM S_ITF_SUBS_RABOTA_PM_MM;

                        DELETE FROM S_ITF_SUBS_SOST_P_POIZD;

                        DELETE FROM S_ITF_SUBS_P_RPS_MM;

                        S_LOG_WORK.ADD_RECORD (
                           S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                           (' Ошибка!!! PART7_MM не отработал'));
                  END;
               ELSE
                  S_LOG_WORK.ADD_RECORD (
                     S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                     (' S_ITF_POIZD нет инфы (7,4 пустые)'));
                  MSG.EXITCODE := 3;
               END IF;
            ELSE
               S_LOG_WORK.ADD_RECORD (
                  S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                  (' 7 раздела нет'));
               MSG.EXITCODE := 3;
            END IF;

            BEGIN
               /*SELECT COUNT (*)
                 INTO XXX
                 FROM S_ITF_SUBS_P_RPS_MM
                WHERE Z_TIP_PARKA IS NULL;*/


               UPDATE S_ITF_SUBS_P_RPS_MM
                  SET Z_TIP_PARKA = 1
                WHERE Z_TIP_PARKA IS NULL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  S_LOG_WORK.ADD_RECORD (
                     S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                     (' Ошибка!!!! S_ITF_SUBS_P_RPS_MM'));
            END;
         EXCEPTION
            WHEN OTHERS
            THEN
               S_LOG_WORK.ADD_RECORD (
                  S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                  (' LOK_MM не формируем'));
         END;

         -- Помечаем грани на запись
         --DBMS_OUTPUT.put_line (' kol_str  = ' || kol_str);
         BEGIN
            SELECT CODE_OPER
              INTO CODE_OP_            -- проверяем была ли поездка пассажиром
              FROM S_ITF_MAIN_BRIG
             WHERE CODE_OP IN (33, 34);

            DBMS_OUTPUT.put_line (' code_op = ' || CODE_OP_);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               CODE_OP_ := NULL;
         END;

         IF CODE_OP_ IN (33, 34)
         THEN
            PASS ();                                   --следование пассажиром
            S_LOG_WORK.ADD_RECORD (
               S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
               'следование пассажиром есть ');
         ELSE
            S_LOG_WORK.ADD_RECORD (
               S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
               'следование пассажиром нет ');
         END IF;

         IF NVL (KOL_STR, 0) != 0
         THEN
            S_WRITE_TO_MODELS.MARK_STATE_FOR_CHANGE ('MM', 'DOC');
            S_WRITE_TO_MODELS.MARK_STATE_FOR_CHANGE ('MM', 'ZP_ALL_TAKS');
         END IF;
      ELSE
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                (' Операция не 51'));
         DBMS_OUTPUT.put_line (
            ' Операция не 51!!! Операция =  ' || X_CODE_OP);
         ERR_MSG;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         S_LOG_WORK.ADD_RECORD (
            S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
            (   ' Ошибка!!! UPDATE_MM выход по гл.exception'
             || SUBSTR (SQLERRM, 1, 230)));

         MSG.EXITCODE := 1;

         ERR_MSG;
   END;


   --Пишем локомотивы
   PROCEDURE LOK_MM
   IS
      N_IDF_TPS         TMP_EMM.IDF_TPS%TYPE;
      N_KOD_SEC         TMP_EMM.IDF_TPS%TYPE;
      D_TYPE_OBJ_DISL   S_ITF_MAIN_TPS.TYPE_OBJ_DISL%TYPE;
      D_KOD_ESR         S_ITF_MAIN_TPS.KOD_OBJ_DISL%TYPE;
      D_ID_DEPO         ASKVP_VIEW.V_LD_ESR_DEPO.ID_DEPO%TYPE;
      D_GR              S_V_D_SERII.ID_GR%TYPE;
      D_ID_SER          S_ITF_MAIN_TPS.ID_SER%TYPE;
      D_IDF_TPS         S_ITF_SUBS_LOK_MM.IDF_TPS%TYPE;
      KOL_ZAPISI        NUMBER;
      D_SOURCE          NUMBER;
      l_start           NUMBER;
      l_start1           NUMBER;
      lok_kol           NUMBER;
   BEGIN
      --определяем idf_tps
      BEGIN
         SELECT IDF_TPS INTO N_IDF_TPS FROM TMP_EMM;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            N_IDF_TPS := NULL;
            S_LOG_WORK.ADD_RECORD (
               S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
               'Ошибка нет TMP_EMM.idf_tps ' || N_IDF_TPS || '');
      END;

      IF (N_IDF_TPS IS NOT NULL)
      THEN
         --Читаем информицию по ТРО S_ITF_MAIN_TPS <------ S_V_FULL_TPS_ONLINE (Все что есть)

         --time_before := DBMS_UTILITY.GET_TIME;
         l_start := DBMS_UTILITY.get_time;

         INSERT INTO S_ITF_MAIN_TPS (DATA_SOURCE,
                                     TMP_IDF_OBJ,
                                     CODE_OP,
                                     DATE_OP,
                                     IDF_TPS,
                                     NAME_LOK,
                                     ID_DEPO,
                                     CNT_SEK,
                                     ID_SER,
                                     KOD_OBJ_DISL,
                                     TYPE_OBJ_DISL,
                                     CNT_VAG_M,
                                     KOD_SEK,
                                     DATE_BEG_DISL,
                                     DATE_END_DISL,
                                     ST_CODE_WORK)
            (SELECT 1,
                    LOK.IDF_TPS,
                    LOK.CODE_OP,
                    LOK.DATE_OP,
                    LOK.IDF_TPS,
                    LOK.NAME_LOK,
                    LOK.ID_DEPO,
                    LOK.CNT_SEK,
                    LOK.ID_SER,
                    LOK.KOD_OBJ_DISL,
                    LOK.TYPE_OBJ_DISL,
                    LOK.CNT_VAG_M,
                    LOK.KOD_SEK,
                    LOK.DATE_BEG_DISL,
                    LOK.DATE_END_DISL,
                    LOK.ST_CODE_WORK
               FROM                                             /*TMP_EMM B,*/
                   S_ITF_MAIN_MM C, S_V_FULL_TPS_ONLINE LOK
              WHERE     LOK.DATE_OP BETWEEN C.PRIEM AND C.SD_LOK
                    AND LOK.IDF_TPS = N_IDF_TPS                    --B.IDF_TPS
                    AND (   lok.idf_disl = lok.idf_op
                         OR lok.idf_work = lok.idf_op
                         OR lok.idf_brig = lok.idf_op));
                         
                         l_start1 := DBMS_UTILITY.get_time;

         KOL_ZAPISI := SQL%ROWCOUNT;

         S_LOG_WORK.ADD_RECORD (
            S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
               'LOK_insert = '
            || ROUND ( (l_start1/*DBMS_UTILITY.get_time*/ - l_start) / 100, 2)
            || ' sec.');



         S_LOG_WORK.ADD_RECORD (
            S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
            'Записей в S_ITF_MAIN_TPS =  ' || KOL_ZAPISI || '');

         IF NVL (KOL_ZAPISI, 0) != 0
         THEN
            D_SOURCE := 1;    --Переменая для выборки записи в ITF_SUBS_LOK_MM

            BEGIN
               SELECT S_ITF_MAIN_TPS.KOD_SEK
                 INTO N_KOD_SEC
                 FROM S_ITF_MAIN_TPS
                WHERE DATA_SOURCE = 1 AND ROWNUM = 1;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  N_KOD_SEC := NULL;

                  S_LOG_WORK.ADD_RECORD (
                     S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                     (' Ошибка!!! Нет в S_ITF_MAIN_TPS.KOD_SEK '));
            END;

            IF (N_KOD_SEC = 8)
            THEN
               -- Проверяем СБО

               INSERT INTO S_ITF_MAIN_TPS (DATA_SOURCE,
                                           TMP_IDF_OBJ,
                                           IDF_TPS,
                                           NAME_LOK,
                                           ID_DEPO,
                                           CNT_SEK,
                                           ID_SER,
                                           CNT_VAG_M,
                                           KOD_SEK,
                                           TYPE_OBJ_DISL,
                                           KOD_OBJ_DISL)
                  (SELECT 2,
                          a.IDF_TPS,
                          a.IDF_TPS,
                          a.NAME_LOK,
                          a.ID_DEPO,
                          a.CNT_SEK,
                          a.ID_SER,
                          a.CNT_VAG_M,
                          a.KOD_SEK,
                          a.TYPE_OBJ_DISL,
                          a.KOD_OBJ_DISL
                     FROM S_V_FULL_TPS_ONLINE a                  --, TMP_EMM B
                    WHERE     a.TYPE_OBJ_DISL = 103
                          AND a.KOD_OBJ_DISL = N_IDF_TPS           --B.IDF_TPS
                                                        );

               KOL_ZAPISI := SQL%ROWCOUNT;

               S_LOG_WORK.ADD_RECORD (
                  S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                  'Записей в S_ITF_MAIN_TPS =  ' || KOL_ZAPISI || '');

               D_SOURCE := 2; --Переменая для выборки записи в ITF_SUBS_LOK_MM
            ELSE
               S_LOG_WORK.ADD_RECORD (
                  S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                  (' СБО нет'));
            END IF;


            BEGIN
               SELECT S_ITF_MAIN_TPS.TYPE_OBJ_DISL
                 INTO D_TYPE_OBJ_DISL
                 FROM S_ITF_MAIN_TPS
                WHERE CODE_OP = 902 AND DATA_SOURCE = 1 AND ROWNUM = 1;

               DBMS_OUTPUT.put_line (
                  ' S_ITF_MAIN_TPS.TYPE_OBJ_DISL = ' || D_TYPE_OBJ_DISL);
            EXCEPTION
               WHEN OTHERS
               THEN
                  D_TYPE_OBJ_DISL := NULL;
                  DBMS_OUTPUT.put_line (
                     ' S_ITF_MAIN_TPS.TYPE_OBJ_DISL IS NULL ');
            END;

            --Обновляем в S_ITF_MAIN_MM <---------  DEPO_OUT, ID_DEPO_OUT


            CASE D_TYPE_OBJ_DISL
               WHEN 205
               THEN
                  UPDATE S_ITF_MAIN_MM a
                     SET (a.DEPO_OUT, a.ID_DEPO_OUT) =
                            (SELECT a.DATE_OP D_DEPO_OUT,
                                    a.KOD_OBJ_DISL D_ID_DEPO_OUT
                               FROM S_ITF_MAIN_TPS a, S_ITF_MAIN_MM B
                              WHERE     a.CODE_OP = 902
                                    --AND B.DATA_SOURCE IN (-1, 1)
                                    AND a.DATE_OP > B.PRIEM
                                    AND a.DATA_SOURCE = 1
                                    AND ROWNUM = 1);
               --WHERE a.DATA_SOURCE IN (-1, 1);
               WHEN 201
               THEN
                  BEGIN
                     SELECT C.ID_DEPO               --KOD_OBJ_DISL--22.12.2017
                       INTO D_ID_DEPO                  --D_KOD_ESR--22.12.2017
                       FROM S_ITF_MAIN_TPS a,
                            S_ITF_MAIN_MM B,
                            ASKVP_VIEW.V_LD_ESR_DEPO C            --22.12.2017
                      WHERE     a.CODE_OP = 902
                            AND B.CODE_OP IS NOT NULL
                            AND a.DATE_OP > B.PRIEM
                            AND a.DATA_SOURCE = 1
                            AND C.KOD_ESR = a.KOD_OBJ_DISL        --22.12.2017
                            AND C.DATE_END =
                                   TO_DATE ('01/01/3001 00:00:00',
                                            'MM/DD/YYYY HH24:MI:SS') --22.12.2017
                            AND ROWNUM = 1;                       --22.12.2017
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        --D_KOD_ESR   := NULL;--22.12.2017
                        D_ID_DEPO := NULL;
                  END;

                  /* BEGIN
                       SELECT ID_DEPO
                         INTO D_ID_DEPO
                         FROM ASKVP_VIEW.V_LD_ESR_DEPO
                        WHERE     KOD_ESR = D_KOD_ESR
                              AND DATE_END =
                                      TO_DATE( '01/01/3001 00:00:00'
                                              ,'MM/DD/YYYY HH24:MI:SS' )
                              AND ROWNUM = 1;
                   EXCEPTION
                       WHEN NO_DATA_FOUND
                       THEN
                           D_ID_DEPO   := NULL;
                   END;*/
                  --22.12.2017

                  BEGIN
                     UPDATE S_ITF_MAIN_MM a
                        SET (a.DEPO_OUT, a.ID_DEPO_OUT) =
                               (SELECT a.DATE_OP D_DEPO_OUT,
                                       D_ID_DEPO D_ID_DEPO_OUT
                                  FROM S_ITF_MAIN_TPS a, S_ITF_MAIN_MM B
                                 WHERE     a.CODE_OP = 902
                                       --AND B.DATA_SOURCE IN (-1, 1)
                                       AND a.DATE_OP > B.PRIEM
                                       AND a.DATA_SOURCE = 1
                                       AND ROWNUM = 1);
                  --WHERE a.DATA_SOURCE IN (-1, 1);
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        S_LOG_WORK.ADD_RECORD (
                           S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                           (' DEPO_OUT, ID_DEPO_OUT - НЕТ'));
                  END;
               ELSE
                  S_LOG_WORK.ADD_RECORD (
                     S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                     (' Ошибка!!! DEPO_OUT, ID_DEPO_OUT 205,201'));
            END CASE;

            --Время вьезда в депо через контрольный пост
            BEGIN
               UPDATE S_ITF_MAIN_MM a --Обновляем в S_ITF_MAIN_MM <---------  DEPO_IN, ID_DEPO_IN
                  SET (a.DEPO_IN, a.ID_DEPO_IN) =
                         (SELECT a.DATE_OP D_DEPO_OUT,
                                 a.KOD_OBJ_DISL D_ID_DEPO_OUT
                            FROM S_ITF_MAIN_TPS a, S_ITF_MAIN_MM B
                           WHERE     a.CODE_OP = 901
                                 AND a.DATA_SOURCE = 1
                                 --AND B.DATA_SOURCE IN (-1, 1)
                                 AND a.DATE_OP < B.SD_LOK
                                 AND ROWNUM =
                                        (SELECT COUNT (*)
                                           FROM S_ITF_MAIN_TPS a,
                                                S_ITF_MAIN_MM B
                                          WHERE     a.CODE_OP = 901
                                                AND a.DATA_SOURCE = 1
                                                --AND B.DATA_SOURCE IN (-1, 1)
                                                AND a.DATE_OP < B.SD_LOK));
            --WHERE a.DATA_SOURCE IN (-1, 1);


            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  S_LOG_WORK.ADD_RECORD (
                     S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                     (' Ошибка!!! UPDATE S_ITF_MAIN_MM'));
            END;

            BEGIN
               SELECT C.ID_GR                                       --a.ID_SER
                 INTO D_GR                                          --D_ID_SER
                 FROM S_ITF_MAIN_TPS a, S_ITF_MAIN_MM B, S_V_D_SERII C --22.12.2017
                WHERE     a.DATE_OP = B.PRIEM
                      AND C.ID_SER = a.ID_SER                     --22.12.2017
                      AND ROWNUM = 1;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  D_GR := NULL;
            --D_ID_SER   := NULL;--22.12.2017
            END;

            /* BEGIN
                 SELECT ID_GR
                   INTO D_GR
                   FROM S_V_D_SERII a
                  WHERE a.ID_SER = D_ID_SER;

                 DBMS_OUTPUT.put_line( ' d_gr = ' || D_GR || '' );
             EXCEPTION
                 WHEN NO_DATA_FOUND
                 THEN
                     D_GR   := NULL;
             END;*/

            --    якщо V_D_SERII.id_gr = 1
            IF D_GR = 1
            THEN
               BEGIN
                  UPDATE S_ITF_MAIN_MM
                     SET KOD_KOL =
                            NVL (
                               (SELECT a.KOD_KOL
                                  FROM S_V_DIC_SER a, S_ITF_MAIN_TPS B
                                 WHERE     a.ID_SER = B.ID_SER
                                       AND B.DATA_SOURCE = 1
                                       AND ROWNUM = 1),
                               1);


                  INSERT INTO S_ITF_SUBS_LOK_MM (TMP_IDF_OBJ,
                                                 IDF_TPS,
                                                 KOD_SER,
                                                 NAME_LOK,
                                                 DEPO_LOK,
                                                 CNT_SEK,
                                                 PR_SEC,
                                                 OZN_TAKS,
                                                 IDF_TPS_SBO,
                                                 PRIEM,
                                                 SD_LOK,
                                                 PRIEM_END,
                                                 SD_LOK_BEG)
                     (SELECT DISTINCT
                             a.TMP_IDF_OBJ,
                             L.IDF_TPS,
                             L.ID_SER,
                             L.NAME_LOK,
                             L.ID_DEPO,
                             L.CNT_SEK, /*CASE
                                           WHEN L.CNT_SEK = S.KOL_SEKC THEN 0   -- закоментил 24,11,2017
                                           WHEN L.CNT_SEK < S.KOL_SEKC THEN 1
                                           WHEN L.CNT_SEK > S.KOL_SEKC THEN 2
                                           ELSE NULL
                                        END,*/
                             DECODE (L.KOD_SEK, 2, 1, L.KOD_SEK),
                             D_SOURCE,
                             DECODE (L.TYPE_OBJ_DISL,
                                     103, L.KOD_OBJ_DISL,
                                     NULL),
                             a.PRIEM /*( SELECT a.DATE_BEG--22.12.2017
                                  FROM S_ST_DISL_BRIG a
                                      ,S_V_ITF_MAIN_BRIG_MSG MSG
                                      ,Tmp_Emm B
                                 WHERE     a.IDF_BRIG = B.IDF_BRIG
                                       AND a.DATE_BEG BETWEEN MSG.TIME_YAVKA
                                                          AND MSG.DATE_OP
                                       AND a.TYPE_OBJ_DISL = 103
                                       AND MSG.PR_MASH = 1
                                       AND ROWNUM = 1 )*/
                                    ,
                             a.DATE_RAB,
                             a.PRIEM_END /*( SELECT a.DATE_BEG--22.12.2017
                                  FROM S_ST_DISL_BRIG a
                                      ,S_V_ITF_MAIN_BRIG_MSG MSG
                                      ,Tmp_Emm B
                                 WHERE     a.IDF_BRIG = B.IDF_BRIG
                                       AND a.DATE_BEG BETWEEN MSG.TIME_YAVKA
                                                          AND MSG.DATE_OP
                                       AND a.TYPE_OBJ_DISL = 103
                                       AND MSG.PR_MASH = 1
                                       AND ROWNUM = 1 )*/
                                        ,
                             a.DATE_RAB
                        FROM S_ITF_MAIN_TPS L,              /*S_V_DIC_SER S,*/
                                              S_ITF_MAIN_MM a
                       --,MD_LOK.ST_TID_TPS k--обговорить с Максом по поводу связки
                       --,S_ST_DISL_BRIG B
                       WHERE L.DATA_SOURCE = D_SOURCE -- AND k.IDF_TID(+) = L.IDF_TID
                                                     -- AND L.IDF_DISL = B.IDF_DISL
                                                     --AND l.date_op = a.priem--вопрос
                                                     --AND L.ID_SER = S.ID_SER -- закоментил 24,11,2017
                                                     --AND S.DATE_END = GET_MAX_DATE  -- закоментил 24,11,2017
                                                     --AND a.DATA_SOURCE IN (-1, 1)
                     );

                  lok_kol := SQL%ROWCOUNT;
                  DBMS_OUTPUT.put_line (
                     ' Отработало d_gr1 =  ' || D_SOURCE);

                  UPDATE S_ITF_SUBS_LOK_MM
                     SET (ID_DEPO_OUT,
                          ID_DEPO_IN,
                          DEPO_OUT,
                          DEPO_IN) =
                            (SELECT ID_DEPO_OUT,
                                    ID_DEPO_IN,
                                    DEPO_OUT,
                                    DEPO_IN
                               FROM S_ITF_MAIN_MM --WHERE DATA_SOURCE IN (-1, 1)
                                                 );


                  DBMS_OUTPUT.put_line (' LOK( 11)');
                  DBMS_OUTPUT.put_line (' Отработало d_gr = 1 ');
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     S_LOG_WORK.ADD_RECORD (
                        S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                        (' Ошибка!!! S_ITF_SUBS_LOK_MM, id_gr = 1'));
               END;
            ELSE
               S_LOG_WORK.ADD_RECORD (
                  S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                  (' id_gr = 1 НЕ СРАБОТАЛ'));
            END IF;

            --    якщо V_D_SERII.id_gr = 2
            IF D_GR = 2
            THEN
               BEGIN
                  UPDATE S_ITF_MAIN_MM
                     SET KOD_KOL =
                            NVL (
                               (SELECT a.KOD_KOL
                                  FROM S_V_DIC_SER_MVRS a, S_ITF_MAIN_TPS B
                                 WHERE     a.ID_SER = B.ID_SER
                                       AND B.DATA_SOURCE = 1
                                       AND ROWNUM = 1),
                               1);


                  INSERT INTO S_ITF_SUBS_LOK_MM (TMP_IDF_OBJ,
                                                 IDF_TPS,
                                                 KOD_SER,
                                                 NAME_LOK,
                                                 DEPO_LOK,
                                                 CNT_SEK,
                                                 PR_SEC,
                                                 OZN_TAKS,
                                                 IDF_TPS_SBO,
                                                 PRIEM,
                                                 SD_LOK,
                                                 PRIEM_END,
                                                 SD_LOK_BEG)
                     (SELECT DISTINCT
                             a.TMP_IDF_OBJ,
                             L.IDF_TPS,
                             L.ID_SER,
                             L.NAME_LOK,
                             L.ID_DEPO,
                             L.CNT_VAG_M,
                             L.CNT_VAG_M / C.MOTOR_IN_SEK,
                             D_SOURCE,
                             DECODE (L.TYPE_OBJ_DISL,
                                     103, L.KOD_OBJ_DISL,
                                     NULL),
                             a.PRIEM /*( SELECT a.DATE_BEG--22.12.2017
                                  FROM S_ST_DISL_BRIG a
                                      ,S_V_ITF_MAIN_BRIG_MSG MSG
                                      ,Tmp_Emm B
                                 WHERE     a.IDF_BRIG = B.IDF_BRIG
                                       AND a.DATE_BEG BETWEEN MSG.TIME_YAVKA
                                                          AND MSG.DATE_OP
                                       AND a.TYPE_OBJ_DISL = 103
                                       AND MSG.PR_MASH = 1
                                       AND ROWNUM = 1 )*/
                                    ,
                             a.DATE_RAB,
                             a.PRIEM_END /*( SELECT a.DATE_BEG--22.12.2017
                                  FROM S_ST_DISL_BRIG a
                                      ,S_V_ITF_MAIN_BRIG_MSG MSG
                                      ,Tmp_Emm B
                                 WHERE     a.IDF_BRIG = B.IDF_BRIG
                                       AND a.DATE_BEG BETWEEN MSG.TIME_YAVKA
                                                          AND MSG.DATE_OP
                                       AND a.TYPE_OBJ_DISL = 103
                                       AND MSG.PR_MASH = 1
                                       AND ROWNUM = 1 )*/
                                        ,
                             a.DATE_RAB
                        FROM S_ITF_MAIN_TPS L,
                             S_ITF_MAIN_MM a,
                             S_V_DIC_SER_MVRS C
                       --,S_ST_DISL_BRIG B
                       WHERE     L.DATA_SOURCE = D_SOURCE
                             --AND L.IDF_DISL = B.IDF_DISL
                             --AND l.date_op = a.priem --Вопрос
                             AND C.ID_SER = L.ID_SER
                             AND C.DATE_END = GET_MAX_DATE --AND a.DATA_SOURCE IN (-1, 1)
                                                          );

                  lok_kol := SQL%ROWCOUNT;
                  DBMS_OUTPUT.put_line (
                     ' Отработало d_gr2 =  ' || D_SOURCE);

                  UPDATE S_ITF_SUBS_LOK_MM
                     SET (ID_DEPO_OUT,
                          ID_DEPO_IN,
                          DEPO_OUT,
                          DEPO_IN) =
                            (SELECT ID_DEPO_OUT,
                                    ID_DEPO_IN,
                                    DEPO_OUT,
                                    DEPO_IN
                               FROM S_ITF_MAIN_MM --WHERE DATA_SOURCE IN (-1, 1)
                                                 );

                  DBMS_OUTPUT.put_line (' LOK( 14)');

                  DBMS_OUTPUT.put_line (' Отработало d_gr = 2 ');
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     S_LOG_WORK.ADD_RECORD (
                        S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                        (' Ошибка!!! S_ITF_SUBS_LOK_MM, id_gr = 2'));
               END;
            ELSE
               S_LOG_WORK.ADD_RECORD (
                  S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                  (' id_gr = 2 НЕ СРАБОТАЛ'));
            END IF;

            --Читання інформації складу секцій локомотива (вагонів поїзда МВРС) з моделі секцій
            IF NVL (lok_kol, 0) > 0
            THEN
               BEGIN
                  BEGIN
                     SELECT IDF_TPS
                       INTO D_IDF_TPS
                       FROM S_ITF_SUBS_LOK_MM
                      WHERE ROWNUM = 1;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        D_IDF_TPS := NULL;
                        S_LOG_WORK.ADD_RECORD (
                           S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                           (' Ошибка!!! S_ITF_SUBS_LOK_MM.idf_tps'));
                  END;

                  UPDATE S_ITF_SUBS_LOK_MM               ---------------вопрос
                     SET OZN_TAKS = 1
                   WHERE ROWNUM = 1;


                  INSERT INTO S_ITF_MAIN_SEC (DATA_SOURCE,
                                              TMP_IDF_OBJ,
                                              IDF_SEC,
                                              ID_SER,
                                              NOM,
                                              KOD_SEC)
                     (SELECT DISTINCT 1,
                                      C.TMP_IDF_OBJ,
                                      a.IDF_SEC,
                                      a.ID_SER,
                                      a.NOM,
                                      a.KOD_SEC
                        FROM S_V_FULL_SEC_ONLINE a,
                             S_ITF_MAIN_MM C,
                             S_ITF_MAIN_TPS B
                       WHERE     a.KOD_OBJ_DISL = B.IDF_TPS        --d_idf_tps
                             AND B.DATA_SOURCE = D_SOURCE
                             --AND C.DATA_SOURCE IN (-1, 1)
                             AND a.DATE_OP <= C.PRIEM
                             AND a.DATE_OP_END > C.PRIEM);
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     S_LOG_WORK.ADD_RECORD (
                        S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                        (' Ошибка!!! S_ITF_MAIN_SEC'));
               END;

               --Формування даних складу секцій локомотива (вагонів поїзда МВРС)
               BEGIN
                  INSERT INTO S_ITF_SUBS_SEC_MM (TMP_IDF_OBJ,
                                                 IDF_SEC,
                                                 ID_SER,
                                                 NOM_LOK,
                                                 KOD_SEK,
                                                 IDF_TPS)
                     (SELECT a.TMP_IDF_OBJ,
                             a.IDF_SEC,
                             a.ID_SER,
                             a.NOM,
                             a.KOD_SEC,
                             D_IDF_TPS
                        FROM S_ITF_MAIN_SEC a);
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     S_LOG_WORK.ADD_RECORD (
                        S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                        (' Ошибка!!! S_ITF_SUBS_SEC_MM'));
               END;
            END IF;
         ELSE
            S_LOG_WORK.ADD_RECORD (
               S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
               (' Ошибка!!! Кол-во записей  S_ITF_MAIN_TPS = 0'));
         END IF;
      ELSE
         S_LOG_WORK.ADD_RECORD (
            S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
            (' Ошибка!!! Кол-во записей  S_ITF_MAIN_TPS = 0'));
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         S_LOG_WORK.ADD_RECORD (
            S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
            (' Ошибка!!! LOK_MM выход по гл.exception'));
         DBMS_OUTPUT.put_line (
            ' Ошибка!!! LOK_MM = ' || SUBSTR (SQLERRM, 1, 230));
         ERR_MSG;
   END;

   --Процедура для формирования полного ММ
   PROCEDURE PART_FULL_MM_MAIN (MSG IN OUT S_T_UZXDOC_MESSAGE)
   IS
      KOL_STR     NUMBER;
      KOL_STROK   NUMBER;
      P_IDF_TPS   tmp_emm.IDF_TPS%TYPE;
      PROVERKA1   NUMBER;
      PROVERKA2   NUMBER;
      PROVERKA3   NUMBER;
   BEGIN
      MSG.EXITCODE := 0;

      -- Обновление ЕММ
      --UPDATE_MM;

      BEGIN
         SELECT COUNT (*) INTO KOL_STR FROM S_ITF_MAIN_MM;
      EXCEPTION
         WHEN OTHERS
         THEN
            KOL_STR := 0;
      END;

      DBMS_OUTPUT.put_line (' kol_str  = ' || KOL_STR);
      DBMS_OUTPUT.put_line (' UPDATE_MM( OK!!!)');
   EXCEPTION
      WHEN OTHERS
      THEN
         S_LOG_WORK.ADD_RECORD (
            S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
            (' Ошибка!!! LOK_MM выход по гл.exception'));

         ERR_MSG;
   END;



   PROCEDURE CLOSE02 (MSG IN OUT S_T_UZXDOC_MESSAGE)
   IS
      KOL         NUMBER;
      P_IDF_DOC   S_ITF_MAIN_MM.IDF_DOC%TYPE;
      P_IDF_TPS   S_ITF_SUBS_LOK_MM.IDF_TPS%TYPE;
      X_MESAGE    S_ITF_KEY_MSG.KOD_MESS%TYPE;
      X_TYPE_MM   S_SREZ_ACTUAL_MM.TYPE_MM%TYPE;
   BEGIN
      --Читання інформації для закриття ЕММ
      MSG.EXITCODE := 0;

      --Формування даних для закритя ЕММ LM002
      INSERT INTO S_ITF_MAIN_MM (TMP_IDF_OBJ,
                                 IDF_MM,
                                 DATE_OP,
                                 DATA_SOURCE,
                                 OPER_TYPE,
                                 CODE_OP,
                                 IDF_OP,
                                 IDF_DOC,
                                 IDF_TAKS,
                                 BR_TIME_RAB                    --,D_END_LUNCH
                                                                --,D_BEG_LUNCH
                                 ,
                                 NOM_MRM,
                                 DEPO,
                                 DATE_MM,
                                 OTDYH,
                                 JAVKA,
                                 PRIEM,
                                 DEPO_OUT,
                                 DEPO_IN,
                                 SD_LOK,
                                 END_RAB,
                                 DATE_CALC,
                                 DEPO_PR_KOL,
                                 KPZ,
                                 NUM_COLUMN,
                                 DATE_RAB,
                                 KOD_KOL,
                                 PRIEM_END,
                                 SD_LOK_BEG)
         (SELECT a.IDF_OP,
                 a.IDF_MM,
                 B.DATE_CALC,
                 1 DATA_SOURCE,
                 S_WRITE_TO_MODELS.OP_CHANGE_OBJECT OPER_TYPE,
                 54 CODE_OP,
                 a.IDF_OP,
                 a.IDF_DOC,
                 a.IDF_TAKS,
                 DECODE (
                    A.BR_TIME_RAB,
                    NULL, CASE
                             WHEN (B.END_RAB - B.JAVKA) * 1440 >= 1440
                             THEN
                                NULL
                             ELSE
                                (B.END_RAB - B.JAVKA) * 1440
                          END,
                    A.BR_TIME_RAB)                            --,B.D_END_LUNCH
                                                              --,B.D_BEG_LUNCH
                 ,
                 a.NOM_MRM,
                 a.DEPO,
                 a.DATE_MM,
                 a.BR_TIME_RAB OTDYH,
                 A.JAVKA,
                 A.PRIEM,
                 A.DEPO_OUT,
                 A.DEPO_IN,
                 A.SD_LOK,
                 A.END_RAB,
                 B.DATE_CALC,
                 A.DEPO_PR_KOL,
                 A.KPZ,
                 a.NUM_COLUMN,
                 a.DATE_RAB,
                 a.KOD_KOL,
                 a.PRIEM_END,
                 a.SD_LOK_BEG
            FROM S_SREZ_ACTUAL_MM a, S_V_ITF_MAIN_MM_MSG B
           WHERE     a.NOM_MRM = B.NOM_MRM
                 AND a.TYPE_MM = 1
                 AND                                     --a.CODE_OP != 54 AND
                    a.DEPO = B.DEPO
                 AND a.DATE_MM = B.DATE_MM);


      --очищаем таблицу от лишних данных
      /*DELETE S_ITF_MAIN_MM
       WHERE NVL (CODE_OP, 0) not in (54,300);*/

      /*DELETE S_ITF_SUBS_LOK_MM;

      DELETE S_ITF_SUBS_SEC_MM;

      DELETE S_ITF_SUBS_BR_PASS_MM;

      DELETE S_ITF_SUBS_RABOTA_PM_MM;

      DELETE S_ITF_SUBS_LSLED_MM;

      DELETE S_ITF_SUBS_POIZD_MM;

      DELETE S_ITF_SUBS_P_RPS_MM;

      DELETE S_ITF_SUBS_SOST_P_POIZD;

      DELETE S_ITF_SUBS_PRED_MM;

      DELETE S_ITF_SUBS_TPEREGON_MM;

      DELETE S_ITF_SUBS_PER_SEC_MM;*/

      SELECT COUNT (*) INTO KOL FROM S_ITF_MAIN_MM where code_op = 54;

      S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                             'EMM_NEW.CLOSE02  kol :' || KOL);

      /* SELECT idf_doc INTO p_idf_doc FROM s_itf_main_mm;

       INSERT INTO S_ITF_SUBS_LOK_MM (tmp_idf_obj,
                                      idf_tps,
                                      kod_ser,
                                      name_lok,
                                      depo_lok,
                                      cnt_sek,
                                      pr_sec,
                                      ozn_taks)
          (SELECT p_idf_doc,
                  l.idf_tps,
                  l.kod_ser,
                  l.name_lok,
                  l.depo_lok,
                  l.cnt_sek,
                  l.pr_sec,
                  l.ozn_taks
             FROM MD_MM.SUBS_LOK_MM l
            WHERE l.idf_doc = p_idf_doc);

       FOR j IN (SELECT idf_tps FROM S_ITF_SUBS_LOK_MM)
       LOOP
          INSERT INTO S_ITF_SUBS_SEC_MM (tmp_idf_obj,
                                         idf_sec,
                                         idf_tps,
                                         id_ser,
                                         nom_lok,
                                         kod_sek)
             (SELECT DISTINCT p_idf_doc,
                              a.IDF_SEC,
                              a.idf_tps,
                              a.id_ser,
                              a.nom_lok,
                              a.kod_sek
                FROM MD_MM.SUBS_SEC_MM a
               WHERE a.idf_tps = j.idf_tps);
       END LOOP;

       INSERT INTO S_ITF_SUBS_BR_PASS_MM (TMP_IDF_OBJ,
                                          NPP,
                                          DATE_OTPR,
                                          DATE_PRIB,
                                          NOM_P,
                                          ST_OTPR,
                                          ST_PRIB)
          (SELECT p_idf_doc,
                  a.NPP,
                  a.DATE_OTPR,
                  a.DATE_PRIB,
                  a.NOM_P,
                  a.ST_OTPR,
                  a.ST_PRIB
             FROM MD_MM.SUBS_BR_PASS_MM a
            WHERE a.idf_doc = p_idf_doc);

       UPDATE S_ITF_SUBS_BRIG_MM a
          SET a.TMP_IDF_OBJ = p_idf_doc;

       INSERT INTO S_ITF_SUBS_RABOTA_PM_MM (tmp_idf_obj,
                                            str_nom,
                                            pr_rab,
                                            esr,
                                            kod_work,
                                            nach,
                                            konec,
                                            tip_inf_otpr,
                                            tip_inf_pr)
          (SELECT p_idf_doc,
                  str_nom,
                  pr_rab,
                  esr,
                  kod_work,
                  nach,
                  konec,
                  tip_inf_otpr,
                  tip_inf_pr
             FROM MD_MM.SUBS_RABOTA_PM_MM a
            WHERE idf_doc = p_idf_doc);

       INSERT INTO S_ITF_SUBS_LSLED_MM (TMP_IDF_OBJ,
                                        IDF_TPS,
                                        SDATE_BEG,
                                        SDATE_END,
                                        KOD_SLED_OKDL,
                                        STR_NOM_BEG,
                                        STR_NOM_END,
                                        OZN_TAKS,
                                        npp,
                                        kod_sled)
          (SELECT p_idf_doc,
                  IDF_TPS,
                  SDATE_BEG,
                  SDATE_END,
                  KOD_SLED_OKDL,
                  STR_NOM_BEG,
                  STR_NOM_END,
                  OZN_TAKS,
                  npp,
                  kod_sled
             FROM MD_MM.SUBS_LSLED_MM
            WHERE idf_doc = p_idf_doc);

       INSERT INTO S_ITF_SUBS_POIZD_MM (tmp_idf_obj,
                                        sdate_beg,
                                        SDATE_END,
                                        str_nom_beg,
                                        str_nom_end,
                                        idf_poizd,
                                        esr_form,
                                        ord_num,
                                        esr_nazn,
                                        nom_pok,
                                        VID_RUXU,
                                        ROD_P,
                                        osi,
                                        vs_vag,
                                        netto,
                                        brutto)
          (SELECT p_idf_doc,
                  sdate_beg,
                  SDATE_END,
                  str_nom_beg,
                  str_nom_end,
                  idf_poizd,
                  esr_form,
                  ord_num,
                  esr_nazn,
                  nom_pok,
                  VID_RUXU,
                  ROD_P,
                  osi,
                  vs_vag,
                  netto,
                  brutto
             FROM MD_MM.SUBS_POIZD_MM
            WHERE idf_doc = p_idf_doc);

       INSERT INTO S_ITF_SUBS_P_RPS_MM (tmp_idf_obj,
                                        nom_pok,
                                        str_nom_beg,
                                        str_nom_end,
                                        sdate_beg,
                                        SDATE_END,
                                        kod_rps,
                                        kol_gr,
                                        kol_por,
                                        z_tip_parka)
          (SELECT p_idf_doc,
                  nom_pok,
                  str_nom_beg,
                  str_nom_end,
                  sdate_beg,
                  SDATE_END,
                  kod_rps,
                  kol_gr,
                  kol_por,
                  z_tip_parka
             FROM MD_MM.SUBS_P_RPS_MM
            WHERE idf_doc = p_idf_doc);

       INSERT INTO S_ITF_SUBS_SOST_P_POIZD (tmp_idf_obj,
                                            tip_parka,
                                            rod_vag,
                                            kol_vag,
                                            PR_OSN,
                                            PR_INV,
                                            NOM_GR,
                                            DOR_NAZN,
                                            NOD_NAZN,
                                            ST_SD_DOR,
                                            ESR_NAZN,
                                            KOD_ADM,
                                            PR_ZN,
                                            KOD_STAN_PARK)
          (SELECT p_idf_doc,
                  tip_parka,
                  rod_vag,
                  kol_vag,
                  PR_OSN,
                  PR_INV,
                  NOM_GR,
                  DOR_NAZN,
                  NOD_NAZN,
                  ST_SD_DOR,
                  ESR_NAZN,
                  KOD_ADM,
                  PR_ZN,
                  KOD_STAN_PARK
             FROM MD_TRAIN.SUBS_SOST_P_POIZD
            WHERE IDF_ITOG = p_idf_doc);

       INSERT INTO S_ITF_SUBS_PRED_MM (TMP_IDF_OBJ,
                                       IDF_PRED,
                                       ESR_BEG,
                                       KM_BEG,
                                       PIKET_BEG,
                                       ESR_END,
                                       KM_END,
                                       PIKET_END,
                                       POSK,
                                       PPR_ID)
          (SELECT p_idf_doc,
                  IDF_PRED,
                  ESR_BEG,
                  KM_BEG,
                  PIKET_BEG,
                  ESR_END,
                  KM_END,
                  PIKET_END,
                  POSK,
                  PPR_ID
             FROM MD_MM.SUBS_PRED_MM
            WHERE idf_doc = p_idf_doc);

       INSERT INTO S_ITF_SUBS_TPEREGON_MM (tmp_idf_obj,
                                           STR_NOM,
                                           KOD_ELPL,
                                           SDATE_BEG,
                                           SDATE_END,
                                           NOM_ELPL,
                                           KOD_PEREG,
                                           UCHASTOK,
                                           PLECH_T,
                                           PLECH_ZP,
                                           KOD_DOR_PD,
                                           KOD_OTD_PD,
                                           DIST,
                                           VR_FACT,
                                           PROST_VH_SV,
                                           PROST_PROH_SV,
                                           KILK_PROH_SV,
                                           CATEGOR_DIRTY,
                                           PR_MOUNT,
                                           PR_UZK_KOL,
                                           IDF_PRED)
          (SELECT p_idf_doc,
                  STR_NOM,
                  KOD_ELPL,
                  SDATE_BEG,
                  SDATE_END,
                  NOM_ELPL,
                  KOD_PEREG,
                  UCHASTOK,
                  PLECH_T,
                  PLECH_ZP,
                  KOD_DOR_PD,
                  KOD_OTD_PD,
                  DIST,
                  VR_FACT,
                  PROST_VH_SV,
                  PROST_PROH_SV,
                  KILK_PROH_SV,
                  CATEGOR_DIRTY,
                  PR_MOUNT,
                  PR_UZK_KOL,
                  IDF_PRED
             FROM MD_MM.SUBS_TPEREGON_MM a
            WHERE a.idf_doc = p_idf_doc);

        INSERT INTO S_ITF_SUBS_PER_SEC_MM (tmp_idf_obj,
                                      idf_sec,
                                      date_zam,
                                      op_zam,
                                      lich_p,
                                      lich_zm,
                                      lich_op,
                                      lich_rec,
                                      topl_l,
                                      topl_kg,
                                      mas_l,
                                      mas_kg)
      (SELECT p_idf_doc,
              a.idf_sec,
              a.date_zam,
              a.op_zam,
              a.lich_p,
              a.lich_zm,
              a.lich_op,
              a.lich_rec,
              a.topl_l,
              a.topl_kg,
              a.mas_l,
              a.mas_kg
         FROM MD_MM.SUBS_PER_SEC_MM a
        WHERE a.IDF_PER_MM = p_idf_doc);*/

      IF NVL (KOL, 0) > 0
      THEN                                          --Помечяем грани на запись
         --S_WRITE_TO_MODELS.MARK_STATE_FOR_CHANGE ('MM', 'OPERS');--VV02.03.2018
         -- s_write_to_models.mark_state_for_change ('MM', 'DOC');--
         --S_WRITE_TO_MODELS.MARK_STATE_FOR_CHANGE ('MM', 'PER_MM');          --VV02.03.2018


         FOR I IN (SELECT *
                     FROM S_ITF_MAIN_MM
                    WHERE OTDYH IS NULL and code_op=54)
         LOOP
            S_WRITE_TO_MODELS.MARK_STATE_FOR_CHANGE ('MM',
                                                     'ZP_ALL_TAKS',
                                                     I.TMP_IDF_OBJ);
         END LOOP;
      ELSE
         MSG.EXITCODE := 1;

         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'Записей - S_ITF_MAIN_MM = ' || KOL);
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         MSG.EXITCODE := 1;
         DBMS_OUTPUT.put_line (' NO_DATA_FOUND Msg.ExitCode := 1');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
      WHEN TOO_MANY_ROWS
      THEN
         MSG.EXITCODE := 1;
         DBMS_OUTPUT.put_line ('TOO_MANY_ROWS Msg.ExitCode := 1');
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                SQLERRM);
   END;

   --коригування ЕММ
   PROCEDURE CORRECTION (MSG IN OUT S_T_UZXDOC_MESSAGE)
   IS
      KOL_STR         NUMBER;
      TMP             NUMBER;
      P_CODE_OP       S_V_ITF_MAIN_MM_MSG.CODE_OP%TYPE;
      P_IDF_DOC       S_ITF_MAIN_MM.IDF_DOC%TYPE;
      P_BR_TIME_RAB   S_ITF_MAIN_MM.BR_TIME_RAB%TYPE;
      X_BR_TIME_RAB   S_ITF_MAIN_MM.BR_TIME_RAB%TYPE;
      P_BR_TIME       S_ITF_MAIN_MM.BR_TIME_RAB%TYPE;
      P_IDF_BRIG      S_ITF_SUBS_BRIG_MM.IDF_BRIG%TYPE;
      P_IDF_TPS       S_ITF_SUBS_LOK_MM.IDF_TPS%TYPE;
      P_IDF_TPS1      S_ITF_SUBS_LOK_MM.IDF_TPS%TYPE;
   BEGIN
      MSG.EXITCODE := 0;


      BEGIN
         SELECT CODE_OP INTO P_CODE_OP FROM S_V_ITF_MAIN_MM_MSG;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            DBMS_OUTPUT.put_line (' code_op NOT DATE FOUND = ' || P_CODE_OP);
         WHEN OTHERS
         THEN
            DBMS_OUTPUT.put_line (' code_op OTHERS = ' || P_CODE_OP);
      END;

      DBMS_OUTPUT.put_line (' code_op = ' || P_CODE_OP);

      IF P_CODE_OP IN (53, 12)
      THEN
         --SELECT COUNT (*) INTO TMP FROM S_TMP_EMM;

         --DBMS_OUTPUT.put_line (' S_tmp_emm = ' || TMP);

         /* BEGIN
             --Высчитываем BR_TIME_RAB
              SELECT ( CASE                                           --Обед
                          WHEN ( D_END_LUNCH - D_BEG_LUNCH ) * 1440 >= 1440
                          THEN
                              NULL
                          WHEN ( D_END_LUNCH - D_BEG_LUNCH ) * 1440 <= 1440
                          THEN
                              ( D_END_LUNCH - D_BEG_LUNCH ) * 1440
                          ELSE
                              0
                      END )
                INTO P_BR_TIME_RAB
                FROM S_ITF_MAIN_MM;*/
         --вслучаи обеда удалить

         --DBMS_OUTPUT.put_line( ' p_br_time_rab = ' || P_BR_TIME_RAB );

         /* SELECT (CASE                                              --Работа
                     WHEN (END_RAB - JAVKA) * 1440 >= 1440 THEN NULL
                     ELSE (END_RAB - JAVKA) * 1440
                  END)
            INTO X_BR_TIME_RAB
            FROM S_ITF_MAIN_MM;

          DBMS_OUTPUT.put_line (' x_br_time_rab = ' || X_BR_TIME_RAB);

          P_BR_TIME := X_BR_TIME_RAB; --- P_BR_TIME_RAB;    --вслучаи обеда разкоментить--BR_TIME_RAB

          DBMS_OUTPUT.put_line (' p_br_time = ' || P_BR_TIME);

          BEGIN
             SELECT IDF_TPS
               INTO P_IDF_TPS
               FROM S_ITF_SUBS_LOK_MM
              WHERE OZN_TAKS = 1;
          EXCEPTION
             WHEN NO_DATA_FOUND
             THEN
                P_IDF_TPS := NULL;
          END;

          DBMS_OUTPUT.put_line (' yyyyyy' || P_BR_TIME);
       EXCEPTION
          WHEN NO_DATA_FOUND
          THEN
             P_BR_TIME := NULL;
             X_BR_TIME_RAB := NULL;
             DBMS_OUTPUT.put_line (
                ' code_op NOT DATE FOUND = ' || P_CODE_OP);
          WHEN OTHERS
          THEN
             P_BR_TIME := NULL;
             X_BR_TIME_RAB := NULL;
             DBMS_OUTPUT.put_line (' code_op OTHERS = ' || P_CODE_OP);
       END;*/

         -- Обновляем таблицу при корректировки S_ITF_MAIN_MM
         UPDATE S_ITF_MAIN_MM a
            SET (TMP_IDF_OBJ,
                 IDF_MM,
                 IDF_DOC,
                 a.OPER_TYPE,
                 a.BR_TIME_RAB,
                 a.DATE_OP,
                 a.DEPO_PR_KOL,
                 a.NUM_COLUMN,
                 a.TYPE_MM,
                 a.KOD_KOL) =
                   (SELECT a.IDF_DOC,
                           a.IDF_MM,
                           a.IDF_DOC,
                           S_WRITE_TO_MODELS.OP_CHANGE_OBJECT OPER_TYPE,
                           (CASE                                      --Работа
                               WHEN (x.END_RAB - x.JAVKA) * 1440 >= 1440
                               THEN
                                  NULL
                               ELSE
                                  (x.END_RAB - x.JAVKA) * 1440
                            END) /*DECODE( P_BR_TIME--22.12.2017
                                          ,NULL, X_BR_TIME_RAB
                                          ,P_BR_TIME )*/
                                ,
                           TRUNC (SYSDATE, 'dd'),
                           a.DEPO_PR_KOL,
                           a.NUM_COLUMN,
                           1,
                           a.KOD_KOL
                      FROM S_SREZ_ACTUAL_MM a, TMP_EMM C, S_ITF_MAIN_MM X
                     WHERE a.IDF_MM = C.IDF_EMM AND a.CODE_OP != 54);

         DBMS_OUTPUT.put_line (' xxxxx' || P_BR_TIME);

         SELECT IDF_DOC INTO P_IDF_DOC FROM S_ITF_MAIN_MM;

         -- Обновляем таблицу при корректировки S_ITF_SUBS_LOK_MM
         INSERT INTO S_ITF_SUBS_LOK_MM (TMP_IDF_OBJ,
                                        IDF_TPS,
                                        KOD_SER,
                                        NAME_LOK,
                                        DEPO_LOK,
                                        CNT_SEK,
                                        PR_SEC,
                                        OZN_TAKS,
                                        IDF_TPS_SBO,
                                        PRIEM,
                                        SD_LOK,
                                        PRIEM_END,
                                        SD_LOK_BEG,
                                        DEPO_IN,
                                        DEPO_OUT)
            (SELECT P_IDF_DOC,
                    L.IDF_TPS,
                    L.KOD_SER,
                    L.NAME_LOK,
                    L.DEPO_LOK,
                    L.CNT_SEK,
                    L.PR_SEC,
                    L.OZN_TAKS,
                    L.IDF_TPS_SBO,
                    m.PRIEM,
                    m.SD_LOK,
                    m.PRIEM_END,
                    m.SD_LOK_BEG,
                    m.DEPO_IN,
                    m.DEPO_OUT
               FROM MD_MM.SUBS_LOK_MM L, S_V_ITF_MAIN_MM_MSG m
              WHERE L.IDF_DOC = P_IDF_DOC AND m.CODE_OP = 53);

         -- Обновляем таблицу при корректировки S_ITF_SUBS_BR_PASS_MM
         INSERT INTO S_ITF_SUBS_BR_PASS_MM (TMP_IDF_OBJ,
                                            NPP,
                                            DATE_OTPR,
                                            DATE_PRIB,
                                            NOM_P,
                                            ST_OTPR,
                                            ST_PRIB)
            (SELECT P_IDF_DOC,
                    a.NPP,
                    a.DATE_OTPR,
                    a.DATE_PRIB,
                    a.NOM_P,
                    a.ST_OTPR,
                    a.ST_PRIB
               FROM MD_MM.SUBS_BR_PASS_MM a
              WHERE a.IDF_DOC = P_IDF_DOC);

         -- Обновляем таблицу при корректировки S_ITF_SUBS_SEC_MM
         FOR J IN (SELECT IDF_TPS FROM S_ITF_SUBS_LOK_MM)
         LOOP
            INSERT INTO S_ITF_SUBS_SEC_MM (TMP_IDF_OBJ,
                                           IDF_SEC,
                                           IDF_TPS,
                                           ID_SER,
                                           NOM_LOK,
                                           KOD_SEK)
               (SELECT DISTINCT P_IDF_DOC,
                                a.IDF_SEC,
                                a.IDF_TPS,
                                a.ID_SER,
                                a.NOM_LOK,
                                a.KOD_SEK
                  FROM MD_MM.SUBS_SEC_MM a
                 WHERE a.IDF_TPS = J.IDF_TPS);
         END LOOP;

         UPDATE S_ITF_SUBS_BRIG_MM a
            SET a.TMP_IDF_OBJ = P_IDF_DOC;

         FOR I
            IN (SELECT JOB,
                       CLASS_MASH,
                       IDF_BRIG,
                       FAM,
                       TAB_NOM,
                       DEPO_PRIP,
                       PR_MASH,
                       OZN_ST_MASH,
                       C.JAVKA,
                       C.END_RAB
                  FROM S_V_FULL_BRIG_ONLINE B, S_ITF_MAIN_MM C
                 WHERE     B.DATE_OP <= C.JAVKA
                       AND B.DATE_OP_END > C.JAVKA
                       AND B.IDF_BRIG IN (SELECT IDF_BRIG
                                            FROM S_ITF_SUBS_BRIG_MM))
         -- Обновляем таблицу при корректировки S_ITF_SUBS_BRIG_MM
         LOOP
            UPDATE S_ITF_SUBS_BRIG_MM a
               SET a.DOLG_BRIG = I.job,
                   a.CLASS_MASH = I.CLASS_MASH,
                   a.FAM_BRIG = I.FAM,
                   a.TAB_BRIG = I.TAB_NOM,
                   a.DEPO_PRIP = I.DEPO_PRIP,
                   --a.DOLG_MM = I.PR_MASH,
                   a.OZN_MASH = I.OZN_ST_MASH,
                   a.DATE_BEG_RAB = I.JAVKA,
                   a.DATE_END_RAB = I.END_RAB
             WHERE a.IDF_BRIG = I.IDF_BRIG;
         END LOOP;

         -- Обновляем таблицу при корректировки S_ITF_SUBS_RABOTA_PM_MM
         INSERT INTO S_ITF_SUBS_RABOTA_PM_MM (TMP_IDF_OBJ,
                                              STR_NOM,
                                              PR_RAB,
                                              ESR,
                                              KOD_WORK,
                                              NACH,
                                              KONEC,
                                              TIP_INF_OTPR,
                                              TIP_INF_PR)
            (SELECT P_IDF_DOC,
                    STR_NOM,
                    PR_RAB,
                    ESR,
                    KOD_WORK,
                    NACH,
                    KONEC,
                    TIP_INF_OTPR,
                    TIP_INF_PR
               FROM MD_MM.SUBS_RABOTA_PM_MM a
              WHERE IDF_DOC = P_IDF_DOC);

         -- Обновляем таблицу при корректировки S_ITF_SUBS_LSLED_MM
         INSERT INTO S_ITF_SUBS_LSLED_MM (TMP_IDF_OBJ,
                                          IDF_TPS,
                                          SDATE_BEG,
                                          SDATE_END,
                                          KOD_SLED_OKDL,
                                          STR_NOM_BEG,
                                          STR_NOM_END,
                                          OZN_TAKS,
                                          NPP,
                                          KOD_SLED)
            (SELECT P_IDF_DOC,
                    IDF_TPS,
                    SDATE_BEG,
                    SDATE_END,
                    KOD_SLED_OKDL,
                    STR_NOM_BEG,
                    STR_NOM_END,
                    OZN_TAKS,
                    NPP,
                    KOD_SLED
               FROM MD_MM.SUBS_LSLED_MM
              WHERE IDF_DOC = P_IDF_DOC);

         -- Обновляем таблицу при корректировки S_ITF_SUBS_POIZD_MM
         INSERT INTO S_ITF_SUBS_POIZD_MM (TMP_IDF_OBJ,
                                          SDATE_BEG,
                                          SDATE_END,
                                          STR_NOM_BEG,
                                          STR_NOM_END,
                                          IDF_POIZD,
                                          ESR_FORM,
                                          ORD_NUM,
                                          ESR_NAZN,
                                          NOM_POK,
                                          VID_RUXU,
                                          ROD_P,
                                          OSI,
                                          VS_VAG,
                                          NETTO,
                                          BRUTTO,
                                          NOM_P)
            (SELECT P_IDF_DOC,
                    SDATE_BEG,
                    SDATE_END,
                    STR_NOM_BEG,
                    STR_NOM_END,
                    IDF_POIZD,
                    ESR_FORM,
                    ORD_NUM,
                    ESR_NAZN,
                    NOM_POK,
                    VID_RUXU,
                    ROD_P,
                    OSI,
                    VS_VAG,
                    NETTO,
                    BRUTTO,
                    NOM_P
               FROM MD_MM.SUBS_POIZD_MM
              WHERE IDF_DOC = P_IDF_DOC);

         -- Обновляем таблицу при корректировки S_ITF_SUBS_P_RPS_MM
         INSERT INTO S_ITF_SUBS_P_RPS_MM (TMP_IDF_OBJ,
                                          NOM_POK,
                                          STR_NOM_BEG,
                                          STR_NOM_END,
                                          SDATE_BEG,
                                          SDATE_END,
                                          KOD_RPS,
                                          KOL_GR,
                                          KOL_POR,
                                          Z_TIP_PARKA)
            (SELECT P_IDF_DOC,
                    NOM_POK,
                    STR_NOM_BEG,
                    STR_NOM_END,
                    SDATE_BEG,
                    SDATE_END,
                    KOD_RPS,
                    KOL_GR,
                    KOL_POR,
                    Z_TIP_PARKA
               FROM MD_MM.SUBS_P_RPS_MM
              WHERE IDF_DOC = P_IDF_DOC);

         -- Обновляем таблицу при корректировки S_ITF_SUBS_SOST_P_POIZD
         INSERT INTO S_ITF_SUBS_SOST_P_POIZD (TMP_IDF_OBJ,
                                              TIP_PARKA,
                                              ROD_VAG,
                                              KOL_VAG,
                                              PR_OSN,
                                              PR_INV,
                                              NOM_GR,
                                              DOR_NAZN,
                                              NOD_NAZN,
                                              ST_SD_DOR,
                                              ESR_NAZN,
                                              KOD_ADM,
                                              PR_ZN,
                                              KOD_STAN_PARK)
            (SELECT P_IDF_DOC,
                    TIP_PARKA,
                    ROD_VAG,
                    KOL_VAG,
                    PR_OSN,
                    PR_INV,
                    NOM_GR,
                    DOR_NAZN,
                    NOD_NAZN,
                    ST_SD_DOR,
                    ESR_NAZN,
                    KOD_ADM,
                    PR_ZN,
                    KOD_STAN_PARK
               FROM MD_TRAIN.SUBS_SOST_P_POIZD
              WHERE IDF_ITOG = P_IDF_DOC);

         -- Обновляем таблицу при корректировки S_ITF_SUBS_PRED_MM
         INSERT INTO S_ITF_SUBS_PRED_MM (TMP_IDF_OBJ,
                                         IDF_PRED,
                                         ESR_BEG,
                                         KM_BEG,
                                         PIKET_BEG,
                                         ESR_END,
                                         KM_END,
                                         PIKET_END,
                                         POSK,
                                         PPR_ID)
            (SELECT P_IDF_DOC,
                    IDF_PRED,
                    ESR_BEG,
                    KM_BEG,
                    PIKET_BEG,
                    ESR_END,
                    KM_END,
                    PIKET_END,
                    POSK,
                    PPR_ID
               FROM MD_MM.SUBS_PRED_MM
              WHERE IDF_DOC = P_IDF_DOC);

         -- Обновляем таблицу при корректировки S_ITF_SUBS_TPEREGON_MM
         INSERT INTO S_ITF_SUBS_TPEREGON_MM (TMP_IDF_OBJ,
                                             STR_NOM,
                                             KOD_ELPL,
                                             SDATE_BEG,
                                             SDATE_END,
                                             NOM_ELPL,
                                             KOD_PEREG,
                                             UCHASTOK,
                                             PLECH_T,
                                             PLECH_ZP,
                                             KOD_DOR_PD,
                                             KOD_OTD_PD,
                                             DIST,
                                             VR_FACT,
                                             PROST_VH_SV,
                                             PROST_PROH_SV,
                                             KILK_PROH_SV,
                                             CATEGOR_DIRTY,
                                             PR_MOUNT,
                                             PR_UZK_KOL,
                                             IDF_PRED)
            (SELECT P_IDF_DOC,
                    STR_NOM,
                    KOD_ELPL,
                    SDATE_BEG,
                    SDATE_END,
                    NOM_ELPL,
                    KOD_PEREG,
                    UCHASTOK,
                    PLECH_T,
                    PLECH_ZP,
                    KOD_DOR_PD,
                    KOD_OTD_PD,
                    DIST,
                    VR_FACT,
                    PROST_VH_SV,
                    PROST_PROH_SV,
                    KILK_PROH_SV,
                    CATEGOR_DIRTY,
                    PR_MOUNT,
                    PR_UZK_KOL,
                    IDF_PRED
               FROM MD_MM.SUBS_TPEREGON_MM a
              WHERE a.IDF_DOC = P_IDF_DOC);

         -- Обновляем таблицу при корректировки S_ITF_SUBS_PER_SEC_MM
         INSERT INTO S_ITF_SUBS_PER_SEC_MM (TMP_IDF_OBJ,
                                            IDF_SEC,
                                            DATE_ZAM,
                                            OP_ZAM,
                                            LICH_P,
                                            LICH_ZM,
                                            LICH_OP,
                                            LICH_REC,
                                            TOPL_L,
                                            TOPL_KG,
                                            MAS_L,
                                            MAS_KG)
            (SELECT P_IDF_DOC,
                    a.IDF_SEC,
                    a.DATE_ZAM,
                    a.OP_ZAM,
                    a.LICH_P,
                    a.LICH_ZM,
                    a.LICH_OP,
                    a.LICH_REC,
                    a.TOPL_L,
                    a.TOPL_KG,
                    a.MAS_L,
                    a.MAS_KG
               FROM MD_MM.SUBS_PER_SEC_MM a
              WHERE a.IDF_PER_MM = P_IDF_DOC);

         --помечаем грани на запись
         S_WRITE_TO_MODELS.MARK_STATE_FOR_CHANGE ('MM', 'OPERS');
         S_WRITE_TO_MODELS.MARK_STATE_FOR_CHANGE ('MM', 'DOC');
         S_WRITE_TO_MODELS.MARK_STATE_FOR_CHANGE ('MM', 'ZP_ALL_TAKS');
         S_WRITE_TO_MODELS.MARK_STATE_FOR_CHANGE ('MM', 'PER_MM');
      ELSE
         S_LOG_WORK.ADD_RECORD (
            S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
               'Другая операция - p_code_op = '
            || P_CODE_OP
            || 'ExitCode := 1');
         MSG.EXITCODE := 1;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         MSG.EXITCODE := 1;
         DBMS_OUTPUT.put_line (' p_br_time = ' || SQLERRM);
      WHEN OTHERS
      THEN
         MSG.EXITCODE := 1;
         DBMS_OUTPUT.put_line (' p_br_time = ' || SQLERRM);
   END;

   --Добавление данных о поездки пассажиром
   PROCEDURE PASS
   IS
      END_RAB_        S_ITF_MAIN_MM.END_RAB%TYPE;
      JAVKA_          S_ITF_MAIN_MM.JAVKA%TYPE;
      END_RAB_START   S_ITF_MAIN_MM.END_RAB%TYPE;
      JAVKA_START     S_ITF_MAIN_MM.JAVKA%TYPE;
      IDF_EVENT_      S_ITF_KEY_MSG.IDF_EVENT%TYPE;
      TMP_IDF_OBJ_    tmp_emm.TMP_IDF_OBJ%TYPE;
      IDF_BRIG_       tmp_emm.IDF_BRIG%TYPE;
      DATE_PRIEM      S_ITF_MAIN_BRIG.DATE_OP%TYPE;
      DATE_PRIEM_1    S_ITF_MAIN_BRIG.DATE_OP%TYPE;
      KOL             NUMBER;
   BEGIN
      DBMS_OUTPUT.put_line (
         ' формирование данных про поездку бригады пассажирами ');

      -- SELECT idf_event INTO idf_event_ FROM s_itf_key_msg;

      ------------------------------------------------
      --DBMS_OUTPUT.put_line (' idf_event = ' || idf_event_);


      /*SELECT date_op_end
        INTO date_priem      --записуем date_op_end
        FROM s_itf_main_brig
       WHERE code_oper = nvl(33,34);

      SELECT date_op
        INTO date_priem_1    --записуем date_op
        FROM s_itf_main_brig
       WHERE code_oper = nvl(33,34);

       select distinct tmp_idf_obj into tmp_idf_obj_    --записуем tmp_idf_obj
     from S_ITF_SUBS_BRIG_MM;

     begin
     select idf_brig into idf_brig_       --записуем idf_brig
     from tmp_emm;
     EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
       idf_brig_:=null;
     end;


      IF (date_priem - (date_priem - date_priem_1)) > --теория Макса))))
            ( (date_priem - date_priem_1) - date_priem_1)
      THEN
         -- Поездка туда, отправление
         INSERT INTO S_ITF_SUBS_BR_PASS_MM (TMP_IDF_OBJ,
                                            NPP,
                                            DATE_OTPR,
                                            NOM_P,
                                            ST_OTPR)
            SELECT tmp_idf_obj_,
                   1,
                   date_op,
                   a.num_train,
                   a.esr_op
              FROM S_V_FULL_BRIG_ONLINE a, tmp_emm b
             WHERE a.idf_brig = b.idf_brig --and a.nom_mm = b.nom_mm
                   AND a.code_oper = 33 AND date_op <= date_priem;    --END_RAB_;

            -- Поездка туда, прибытие
            MERGE INTO appl_dbw.s_itf_subs_br_pass_mm t
                 USING (SELECT *
                          FROM appl_dbw.S_V_FULL_BRIG_ONLINE
                         WHERE     code_oper = 34
                               AND idf_brig = idf_brig_
                               AND date_op <= date_priem            --<= END_RAB_
                                                        ) e
                    ON (t.npp = 1)
            WHEN MATCHED
            THEN
               UPDATE SET t.date_prib = e.date_op, t.st_prib = e.esr_op
            WHEN NOT MATCHED
            THEN
               INSERT     (tmp_idf_obj,
                           npp,
                           date_prib,
                           nom_p,
                           st_prib)
                   VALUES (tmp_idf_obj_,
                           1,
                           e.date_op,
                           e.num_train,
                           e.esr_op);
      ELSE
         -- Поездка оттуда, отправление
         INSERT INTO S_ITF_SUBS_BR_PASS_MM (TMP_IDF_OBJ,
                                            NPP,
                                            DATE_OTPR,
                                            NOM_P,
                                            ST_OTPR)
            SELECT tmp_idf_obj_,
                   2,
                   date_op,
                   a.num_train,
                   a.esr_op
              FROM S_V_FULL_BRIG_ONLINE a, tmp_emm b
             WHERE a.idf_brig = b.idf_brig --and a.nom_mm = b.nom_mm
                   AND a.code_oper = 33 AND date_op >= date_priem;  -->= JAVKA_ ;


            -- Поездка оттуда, прибытие
            MERGE INTO appl_dbw.s_itf_subs_br_pass_mm t
                 USING (SELECT *
                          FROM appl_dbw.s_itf_main_brig a
                         WHERE     code_oper = 34
                               AND idf_brig = idf_brig_
                               AND date_op >= date_priem                 --JAVKA_
                                                        ) e
                    ON (t.npp = 2)
            WHEN MATCHED
            THEN
               UPDATE SET t.date_prib = e.date_op, t.st_prib = e.esr_op
            WHEN NOT MATCHED
            THEN
               INSERT     (tmp_idf_obj,
                           npp,
                           date_prib,
                           nom_p,
                           st_prib)
                   VALUES (tmp_idf_obj_,
                           2,
                           e.date_op,
                           e.num_train,
                           e.esr_op);

      END IF;*/

      BEGIN
         SELECT PRIEM, JAVKA, END_RAB
           INTO DATE_PRIEM, JAVKA_START, END_RAB_START
           FROM S_ITF_MAIN_MM
          WHERE TYPE_MM = 1;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            DATE_PRIEM := NULL;
            JAVKA_START := NULL;
            END_RAB_START := NULL;
      END;

      /* BEGIN
           SELECT JAVKA
             INTO JAVKA_START
             FROM S_ITF_MAIN_MM
            WHERE TYPE_MM = 1;
       EXCEPTION
           WHEN NO_DATA_FOUND
           THEN
               JAVKA_START   := NULL;
       END;*/

      /* BEGIN
           SELECT END_RAB
             INTO END_RAB_START
             FROM S_ITF_MAIN_MM
            WHERE TYPE_MM = 1;
       EXCEPTION
           WHEN NO_DATA_FOUND
           THEN
               END_RAB_START   := NULL;
       END;*/


      IF (DATE_PRIEM IS NOT NULL)
      THEN
         BEGIN
            SELECT IDF_BRIG INTO IDF_BRIG_ FROM tmp_emm;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               IDF_BRIG_ := NULL;
         END;



         DBMS_OUTPUT.put_line (' S_ITF_MAIN_MM.JAVKA = ' || JAVKA_);
         DBMS_OUTPUT.put_line (' S_ITF_MAIN_MM.END_RAB = ' || END_RAB_);
         DBMS_OUTPUT.put_line (' S_ITF_MAIN_MM.date_priem = ' || DATE_PRIEM);

         DELETE FROM S_ITF_SUBS_BR_PASS_MM;

         SELECT DISTINCT TMP_IDF_OBJ
           INTO TMP_IDF_OBJ_
           FROM S_ITF_SUBS_BRIG_MM;

         -- Поездка туда, отправление
         INSERT INTO S_ITF_SUBS_BR_PASS_MM (TMP_IDF_OBJ,
                                            NPP,
                                            DATE_OTPR,
                                            NOM_P,
                                            ST_OTPR)
            SELECT TMP_IDF_OBJ_,
                   1,
                   DATE_OP,
                   a.NUM_TRAIN,
                   a.ESR_OP
              FROM S_V_FULL_BRIG_ONLINE a            --, tmp_emm B--22.12.2017
             WHERE     a.IDF_BRIG = IDF_BRIG_ --B.IDF_BRIG--22.12.2017   --and a.nom_mm = b.nom_mm
                   AND a.CODE_OPER = 33
                   AND a.DATE_OP <= DATE_PRIEM
                   AND DATE_OP BETWEEN JAVKA_START AND END_RAB_START; --END_RAB_;

         KOL := SQL%ROWCOUNT;

         IF NVL (KOL, 0) != 0
         THEN
            -- Поездка туда, прибытие
            MERGE INTO appl_dbw.S_ITF_SUBS_BR_PASS_MM t
                 USING (SELECT *
                          FROM S_V_FULL_BRIG_ONLINE
                         WHERE     CODE_OPER = 34
                               AND IDF_BRIG = IDF_BRIG_
                               AND DATE_OP <= DATE_PRIEM
                               AND DATE_OP BETWEEN JAVKA_START
                                               AND END_RAB_START --<= END_RAB_
                                                                ) e
                    ON (t.NPP = 1)
            WHEN MATCHED
            THEN
               UPDATE SET t.DATE_PRIB = e.DATE_OP, t.ST_PRIB = e.ESR_OP
            WHEN NOT MATCHED
            THEN
               INSERT     (TMP_IDF_OBJ,
                           NPP,
                           DATE_PRIB,
                           NOM_P,
                           ST_PRIB)
                   VALUES (TMP_IDF_OBJ_,
                           1,
                           e.DATE_OP,
                           e.NUM_TRAIN,
                           e.ESR_OP);
         ELSE
            S_LOG_WORK.ADD_RECORD (
               S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
               'Поездка туда, отправление нет');
         END IF;

         -- Поездка оттуда, отправление
         INSERT INTO S_ITF_SUBS_BR_PASS_MM (TMP_IDF_OBJ,
                                            NPP,
                                            DATE_OTPR,
                                            NOM_P,
                                            ST_OTPR)
            SELECT TMP_IDF_OBJ_,
                   2,
                   DATE_OP,
                   a.NUM_TRAIN,
                   a.ESR_OP
              FROM S_V_FULL_BRIG_ONLINE a            --, tmp_emm B--22.12.2017
             WHERE     a.IDF_BRIG = IDF_BRIG_ --B.IDF_BRIG--22.12.2017   --and a.nom_mm = b.nom_mm
                   AND a.CODE_OPER = 33
                   AND a.DATE_OP >= DATE_PRIEM
                   AND DATE_OP BETWEEN JAVKA_START AND END_RAB_START; -->= JAVKA_ ;

         KOL := SQL%ROWCOUNT;

         IF NVL (KOL, 0) != 0
         THEN
            -- Поездка оттуда, прибытие
            MERGE INTO S_ITF_SUBS_BR_PASS_MM t
                 USING (SELECT *
                          FROM S_ITF_MAIN_BRIG a
                         WHERE     CODE_OPER = 34
                               AND IDF_BRIG = IDF_BRIG_
                               AND DATE_OP >= DATE_PRIEM
                               AND DATE_OP BETWEEN JAVKA_START
                                               AND END_RAB_START      --JAVKA_
                                                                ) e
                    ON (t.NPP = 2)
            WHEN MATCHED
            THEN
               UPDATE SET t.DATE_PRIB = e.DATE_OP, t.ST_PRIB = e.ESR_OP
            WHEN NOT MATCHED
            THEN
               INSERT     (TMP_IDF_OBJ,
                           NPP,
                           DATE_PRIB,
                           NOM_P,
                           ST_PRIB)
                   VALUES (TMP_IDF_OBJ_,
                           2,
                           e.DATE_OP,
                           e.NUM_TRAIN,
                           e.ESR_OP);
         ELSE
            S_LOG_WORK.ADD_RECORD (
               S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
               'Поездка оттуда, отправление нет');
         END IF;


         UPDATE S_ITF_SUBS_BR_PASS_MM
            SET ST_PRIB =
                   (SELECT KOD_ESR
                      FROM NSI.LD_ESR_DEPO
                     WHERE ST_PRIB = ID_DEPO AND ROWNUM = 1)
          WHERE LENGTH (ST_PRIB) = 4;

         UPDATE S_ITF_SUBS_BR_PASS_MM
            SET ST_OTPR =
                   (SELECT KOD_ESR
                      FROM NSI.LD_ESR_DEPO
                     WHERE ST_OTPR = ID_DEPO AND ROWNUM = 1)
          WHERE LENGTH (ST_OTPR) = 4;
      ELSE
         BEGIN
            SELECT IDF_BRIG INTO IDF_BRIG_ FROM tmp_emm;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               IDF_BRIG_ := NULL;
         END;

         BEGIN
            SELECT JAVKA, END_RAB                                 --22.12.2017
              INTO JAVKA_, END_RAB_                               --22.12.2017
              FROM S_ITF_MAIN_MM
             WHERE TYPE_MM = 1;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               JAVKA_ := NULL;
               END_RAB_ := NULL;                                  --22.12.2017
         END;

         /* BEGIN--22.12.2017
              SELECT END_RAB
                INTO END_RAB_
                FROM S_ITF_MAIN_MM
               WHERE TYPE_MM = 1;
          EXCEPTION
              WHEN NO_DATA_FOUND
              THEN
                  END_RAB_   := NULL;
          END;*/

         BEGIN
            SELECT DATE_OP
              INTO DATE_PRIEM_1                             --записуем date_op
              FROM S_ITF_MAIN_BRIG
             WHERE CODE_OPER IN (33, 34) AND ROWNUM = 1;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               DATE_PRIEM_1 := NULL;
            WHEN OTHERS
            THEN
               DATE_PRIEM_1 := NULL;
         END;

         DBMS_OUTPUT.put_line (' S_ITF_MAIN_MM.JAVKA = ' || JAVKA_);
         DBMS_OUTPUT.put_line (' S_ITF_MAIN_MM.END_RAB = ' || END_RAB_);
         DBMS_OUTPUT.put_line (' S_ITF_MAIN_MM.date_priem = ' || DATE_PRIEM);
         DBMS_OUTPUT.put_line (
            ' S_ITF_MAIN_MM.date_priem_1 = ' || DATE_PRIEM_1);

         DELETE FROM S_ITF_SUBS_BR_PASS_MM;

         SELECT DISTINCT TMP_IDF_OBJ
           INTO TMP_IDF_OBJ_
           FROM S_ITF_SUBS_BRIG_MM;

         IF ( (DATE_PRIEM_1 - JAVKA_) > (END_RAB_ - DATE_PRIEM_1))
         THEN
            -- Поездка туда, отправление
            INSERT INTO S_ITF_SUBS_BR_PASS_MM (TMP_IDF_OBJ,
                                               NPP,
                                               DATE_OTPR,
                                               NOM_P,
                                               ST_OTPR)
               SELECT TMP_IDF_OBJ_,
                      1,
                      DATE_OP,
                      a.NUM_TRAIN,
                      a.ESR_OP
                 FROM S_V_FULL_BRIG_ONLINE a         --, tmp_emm B--22.12.2017
                WHERE     a.IDF_BRIG = IDF_BRIG_ --B.IDF_BRIG--22.12.2017 --and a.nom_mm = b.nom_mm
                      AND a.CODE_OPER = 33
                      AND a.DATE_OP <= END_RAB_
                      AND DATE_OP BETWEEN JAVKA_ AND END_RAB_;     --END_RAB_;

            KOL := SQL%ROWCOUNT;

            IF NVL (KOL, 0) != 0
            THEN
               -- Поездка туда, прибытие
               MERGE INTO S_ITF_SUBS_BR_PASS_MM t
                    USING (SELECT *
                             FROM S_V_FULL_BRIG_ONLINE
                            WHERE     CODE_OPER = 34
                                  AND IDF_BRIG = IDF_BRIG_
                                  AND DATE_OP <= END_RAB_
                                  AND DATE_OP BETWEEN JAVKA_ AND END_RAB_ --<= END_RAB_
                                                                         ) e
                       ON (t.NPP = 1)
               WHEN MATCHED
               THEN
                  UPDATE SET t.DATE_PRIB = e.DATE_OP, t.ST_PRIB = e.ESR_OP
               WHEN NOT MATCHED
               THEN
                  INSERT     (TMP_IDF_OBJ,
                              NPP,
                              DATE_PRIB,
                              NOM_P,
                              ST_PRIB)
                      VALUES (TMP_IDF_OBJ_,
                              1,
                              e.DATE_OP,
                              e.NUM_TRAIN,
                              e.ESR_OP);
            ELSE
               S_LOG_WORK.ADD_RECORD (
                  S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                  'Поездка туда, отправление нет (по ЯВКЕ)');
            END IF;

            UPDATE S_ITF_SUBS_BR_PASS_MM
               SET ST_PRIB =
                      (SELECT KOD_ESR
                         FROM NSI.LD_ESR_DEPO
                        WHERE ST_PRIB = ID_DEPO AND ROWNUM = 1)
             WHERE LENGTH (ST_PRIB) = 4;

            UPDATE S_ITF_SUBS_BR_PASS_MM
               SET ST_OTPR =
                      (SELECT KOD_ESR
                         FROM NSI.LD_ESR_DEPO
                        WHERE ST_OTPR = ID_DEPO AND ROWNUM = 1)
             WHERE LENGTH (ST_OTPR) = 4;
         ELSE
            -- Поездка оттуда, отправление
            INSERT INTO S_ITF_SUBS_BR_PASS_MM (TMP_IDF_OBJ,
                                               NPP,
                                               DATE_OTPR,
                                               NOM_P,
                                               ST_OTPR)
               SELECT TMP_IDF_OBJ_,
                      2,
                      DATE_OP,
                      a.NUM_TRAIN,
                      a.ESR_OP
                 FROM S_V_FULL_BRIG_ONLINE a         --, tmp_emm B--22.12.2017
                WHERE     a.IDF_BRIG = IDF_BRIG_ --B.IDF_BRIG --22.12.2017--and a.nom_mm = b.nom_mm
                      AND a.CODE_OPER = 33
                      AND a.DATE_OP >= JAVKA_
                      AND DATE_OP BETWEEN JAVKA_ AND END_RAB_;   -->= JAVKA_ ;

            KOL := SQL%ROWCOUNT;

            IF NVL (KOL, 0) != 0
            THEN
               -- Поездка оттуда, прибытие
               MERGE INTO S_ITF_SUBS_BR_PASS_MM t
                    USING (SELECT *
                             FROM S_ITF_MAIN_BRIG a
                            WHERE     CODE_OPER = 34
                                  AND IDF_BRIG = IDF_BRIG_
                                  AND DATE_OP >= JAVKA_
                                  AND DATE_OP BETWEEN JAVKA_ AND END_RAB_ --JAVKA_
                                                                         ) e
                       ON (t.NPP = 2)
               WHEN MATCHED
               THEN
                  UPDATE SET t.DATE_PRIB = e.DATE_OP, t.ST_PRIB = e.ESR_OP
               WHEN NOT MATCHED
               THEN
                  INSERT     (TMP_IDF_OBJ,
                              NPP,
                              DATE_PRIB,
                              NOM_P,
                              ST_PRIB)
                      VALUES (TMP_IDF_OBJ_,
                              2,
                              e.DATE_OP,
                              e.NUM_TRAIN,
                              e.ESR_OP);
            ELSE
               S_LOG_WORK.ADD_RECORD (
                  S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                  'Поездка оттуда, отправление нет');
            END IF;

            UPDATE S_ITF_SUBS_BR_PASS_MM
               SET ST_PRIB =
                      (SELECT KOD_ESR
                         FROM NSI.LD_ESR_DEPO
                        WHERE ST_PRIB = ID_DEPO AND ROWNUM = 1)
             WHERE LENGTH (ST_PRIB) = 4;

            UPDATE S_ITF_SUBS_BR_PASS_MM
               SET ST_OTPR =
                      (SELECT KOD_ESR
                         FROM NSI.LD_ESR_DEPO
                        WHERE ST_OTPR = ID_DEPO AND ROWNUM = 1)
             WHERE LENGTH (ST_OTPR) = 4;
         END IF;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         S_LOG_WORK.ADD_RECORD (IDF_EVENT_, 'EMM_NEW.PASS - ' || SQLERRM);
      WHEN OTHERS
      THEN
         S_LOG_WORK.ADD_RECORD (IDF_EVENT_, 'EMM_NEW.PASS - ' || SQLERRM);
   END;


   --Відомість про хід, вагу, склад поїзда та виділену маневрову роботу на станціях
   PROCEDURE PART7_MM
   IS
      X_TMP_IDF_OBJ   S_ITF_MAIN_MM.TMP_IDF_OBJ%TYPE;
      KOD_ST          NUMBER (6) := 0;
      N               NUMBER (4) := 0;
      CNT_ESR         NUMBER := 0; -- признак повтора ЕСР (при заездах на чужую дорогу)
      CNT_LSLED       NUMBER (3) := 1; -- признак смены кода следования основного локомотива
      CNT_ST_POEZD    NUMBER (3) := 1;       -- признак смены состояния поезда
      KOL_STR         NUMBER;
   BEGIN
      SELECT TMP_IDF_OBJ INTO X_TMP_IDF_OBJ FROM S_ITF_MAIN_MM;

      --WHERE DATA_SOURCE IN (-1, 1);

      --Заполняем Поезд
      INSERT INTO S_ITF_MAIN_POIZD (TMP_IDF_OBJ,
                                    IDF_POIZD,
                                    IDF_OP,
                                    IDF_OP_END_DISL,
                                    ESR_FORM,
                                    NOM_SOST,
                                    ESR_NAZN,
                                    NOM_P,
                                    tip_poizd,
                                    CODE_OP,
                                    DATE_OP,
                                    ESR_OP,
                                    TIP_DISL,
                                    KOD_DOR,
                                    KOD_OTD,
                                    NOM_UCH,
                                    PROBEG,
                                    TIP_KOL,
                                    VES_BRUTTO,
                                    VES_NETTO,
                                    NOM_POK,
                                    KOL_VAG,
                                    KOL_VAG_GR_SNG,
                                    KOL_VAG_POR_SNG,
                                    KOL_OS,
                                    KOL_LOK,
                                    IDF_LOK,
                                    IDF_POK,
                                    IDF_ITOG,
                                    DATE_BEG_LOK,
                                    DATE_END_LOK,
                                    TIP_INF,
                                    ROW_ORDER)
         (SELECT DISTINCT X_TMP_IDF_OBJ,
                          p.IDF_POIZD,
                          p.IDF_OP,
                          L.IDF_OP,
                          p.ESR_FORM,
                          p.NOM_SOST,
                          p.ESR_NAZN,
                          p.NOM_P,
                          p.tip_poizd,
                          p.CODE_OP,
                          p.DATE_OP,
                          p.ESR_OP,
                          p.TIP_DISL,
                          p.KOD_DOR,
                          p.KOD_OTD,
                          p.NOM_UCH,
                          p.PROBEG,
                          p.TIP_KOL,
                          p.VES_BRUTTO,
                          p.VES_NETTO,
                          p.NOM_POK,
                          p.KOL_VAG,
                          p.KOL_VAG_GR_SNG,
                          p.KOL_VAG_POR_SNG,
                          p.KOL_OS,
                          p.KOL_LOK,
                          p.IDF_LOK,
                          p.IDF_POK,
                          p.IDF_ITOG,
                          p.DATE_BEG_LOK,
                          p.DATE_END_LOK,
                          p.TIP_INF,
                          L.ST_CODE_WORK
            FROM S_V_FULL_POIZD_ONLINE p                  --,S_ITF_MAIN_BRIG B
                                        , S_ITF_MAIN_TPS L
           WHERE     P.DATE_OP BETWEEN L.DATE_BEG_DISL AND L.DATE_END_DISL
                 AND P.IDF_POIZD = L.KOD_OBJ_DISL
                 AND p.IDF_OP = p.IDF_DISL
                 AND L.TYPE_OBJ_DISL = 110)
         ORDER BY DATE_OP;

      KOL_STR := SQL%ROWCOUNT;     -------------------------------------------


      IF NVL (KOL_STR, 0) != 0           --Если были записи в S_ITF_MAIN_POIZD
      THEN
         -- Определение рода работы поезда
         UPDATE S_ITF_MAIN_POIZD R
            SET PART_POIZD =
                   (SELECT ROD_RAB
                      FROM S_LR_KOD1_UZ
                     WHERE (VID_SLED, VID_RUXU, ROD_P) =
                              (SELECT R.ROW_ORDER, VID_RUXU, ROD_P
                                 FROM S_DOV_POIZD_DIAPAZ
                                WHERE R.NOM_P BETWEEN MIN_KOD AND MAX_KOD));



         -- Формируем последовательность строк
         FOR I IN (  SELECT *
                       FROM S_ITF_MAIN_POIZD
                   ORDER BY DATE_OP)
         LOOP
            IF KOD_ST = I.ESR_OP
            THEN
               CNT_ESR := CNT_ESR + 1;
            ELSE
               CNT_ESR := 0;
            END IF;

            IF (I.ESR_OP <> KOD_ST) OR (CNT_ESR > 1)
            THEN
               N := N + 1;
               CNT_ESR := 0;
            END IF;

            KOD_ST := I.ESR_OP;

            UPDATE S_ITF_MAIN_POIZD
               SET DATA_SOURCE = N
             WHERE IDF_POIZD = I.IDF_POIZD AND DATE_OP = I.DATE_OP;
         END LOOP;



         -- Отправление
         INSERT INTO TMP_RABOTA_MM t (TMP_IDF_OBJ,
                                      STR_NOM,
                                      PR_RAB,
                                      ESR,
                                      KONEC,
                                      KOD_WORK,
                                      KOD_SLED_LOK,
                                      VID_RUXU,
                                      ROD_P,
                                      IDF_POIZD,
                                      NOM_P,
                                      ESR_FORM,
                                      NOM_SOST,
                                      ESR_NAZN,
                                      NOM_POK,
                                      KOL_OS,
                                      KOL_VAG,
                                      VES_NETTO,
                                      VES_BRUTTO,
                                      IDF_ITOG_POEZD,
                                      IDF_LOK_POEZD,
                                      TIP_INF_OTPR)
            (SELECT e.TMP_IDF_OBJ,
                    e.DATA_SOURCE,
                    0,
                    e.ESR_OP,
                    e.DATE_OP,
                    e.PART_POIZD,
                    e.ROW_ORDER,
                    S.VID_RUXU,
                    S.ROD_P,
                    e.IDF_POIZD,
                    e.NOM_P,
                    e.ESR_FORM,
                    e.NOM_SOST,
                    e.ESR_NAZN,
                    e.NOM_POK,
                    e.KOL_OS,
                    e.KOL_VAG,
                    e.VES_NETTO,
                    e.VES_BRUTTO,
                    IDF_POK,
                    IDF_LOK,
                    e.TIP_INF
               FROM S_ITF_MAIN_POIZD e, S_DOV_POIZD_DIAPAZ S
              WHERE     (   SUBSTR (CODE_OP, LENGTH (CODE_OP), 1) = 2
                         OR CODE_OP = 10)
                    AND NOM_P BETWEEN MIN_KOD AND MAX_KOD);



         -- Прибытие
         MERGE INTO TMP_RABOTA_MM t
              USING (SELECT *
                       FROM S_ITF_MAIN_POIZD p, S_DOV_POIZD_DIAPAZ S
                      WHERE     ( (   SUBSTR (p.CODE_OP,
                                              LENGTH (p.CODE_OP),
                                              1) = 1
                                   OR p.CODE_OP = 20))
                            AND NOM_P BETWEEN MIN_KOD AND MAX_KOD) e
                 ON (    t.TMP_IDF_OBJ = e.TMP_IDF_OBJ
                     AND t.STR_NOM = e.DATA_SOURCE)
         WHEN MATCHED
         THEN
            UPDATE SET t.NACH = e.DATE_OP, t.TIP_INF_PR = e.TIP_INF
         WHEN NOT MATCHED
         THEN
            INSERT     (TMP_IDF_OBJ,
                        STR_NOM,
                        PR_RAB,
                        ESR,
                        NACH,
                        KOD_WORK,
                        KOD_SLED_LOK,
                        VID_RUXU,
                        ROD_P,
                        IDF_POIZD,
                        NOM_P,
                        ESR_FORM,
                        NOM_SOST,
                        ESR_NAZN,
                        NOM_POK,
                        KOL_OS,
                        KOL_VAG,
                        VES_NETTO,
                        VES_BRUTTO,
                        IDF_ITOG_POEZD,
                        IDF_LOK_POEZD,
                        TIP_INF_PR)
                VALUES (e.TMP_IDF_OBJ,
                        e.DATA_SOURCE,
                        0,
                        e.ESR_OP,
                        e.DATE_OP,
                        e.PART_POIZD,
                        e.ROW_ORDER,
                        e.VID_RUXU,
                        e.ROD_P,
                        e.IDF_POIZD,
                        e.NOM_P,
                        e.ESR_FORM,
                        e.NOM_SOST,
                        e.ESR_NAZN,
                        e.NOM_POK,
                        e.KOL_OS,
                        e.KOL_VAG,
                        e.VES_NETTO,
                        e.VES_BRUTTO,
                        e.IDF_POK,
                        e.IDF_LOK,
                        e.TIP_INF);



         -- Проследование
         INSERT INTO TMP_RABOTA_MM t (TMP_IDF_OBJ,
                                      STR_NOM,
                                      PR_RAB,
                                      ESR,
                                      NACH,
                                      KONEC,
                                      KOD_WORK,
                                      KOD_SLED_LOK,
                                      VID_RUXU,
                                      ROD_P,
                                      IDF_POIZD,
                                      NOM_P,
                                      ESR_FORM,
                                      NOM_SOST,
                                      ESR_NAZN,
                                      NOM_POK,
                                      KOL_OS,
                                      KOL_VAG,
                                      VES_NETTO,
                                      VES_BRUTTO,
                                      IDF_ITOG_POEZD,
                                      IDF_LOK_POEZD,
                                      TIP_INF_OTPR,
                                      TIP_INF_PR)
            (SELECT e.TMP_IDF_OBJ,
                    e.DATA_SOURCE,
                    0,
                    e.ESR_OP,
                    e.DATE_OP,
                    e.DATE_OP,
                    e.PART_POIZD,
                    e.ROW_ORDER,
                    S.VID_RUXU,
                    S.ROD_P,
                    e.IDF_POIZD,
                    e.NOM_P,
                    e.ESR_FORM,
                    e.NOM_SOST,
                    e.ESR_NAZN,
                    e.NOM_POK,
                    e.KOL_OS,
                    e.KOL_VAG,
                    e.VES_NETTO,
                    e.VES_BRUTTO,
                    IDF_POK,
                    IDF_LOK,
                    e.TIP_INF,
                    e.TIP_INF
               FROM S_ITF_MAIN_POIZD e, S_DOV_POIZD_DIAPAZ S
              WHERE     SUBSTR (CODE_OP, LENGTH (CODE_OP), 1) = 3
                    AND NOM_P BETWEEN MIN_KOD AND MAX_KOD);



         BEGIN
            DELETE FROM TMP_RABOTA_MM a
                  WHERE     a.STR_NOM IN (SELECT STR_NOM
                                            FROM (  SELECT COUNT (*), STR_NOM
                                                      FROM TMP_RABOTA_MM
                                                  GROUP BY STR_NOM
                                                    HAVING COUNT (*) > 1))
                        AND ROWNUM = 1;
         EXCEPTION
            WHEN OTHERS
            THEN
               DBMS_OUTPUT.put_line (' TMP_RABOTA_MM = ');
         END;



         -- Заполнение подграни ITF_SUBS_RABOTA_PM_MM
         INSERT INTO S_ITF_SUBS_RABOTA_PM_MM (TMP_IDF_OBJ,
                                              STR_NOM,
                                              PR_RAB,
                                              ESR,
                                              KOD_WORK,
                                              NACH,
                                              KONEC,
                                              TIP_INF_OTPR,
                                              TIP_INF_PR)
            SELECT TMP_IDF_OBJ,
                   STR_NOM,
                   PR_RAB,
                   ESR,
                   KOD_WORK,
                   NACH,
                   KONEC,
                   TIP_INF_OTPR,
                   TIP_INF_PR
              FROM TMP_RABOTA_MM;



         -- Формирование уникального значения для каждой смены следования основного локомотива
         FOR I
            IN (  SELECT TMP_IDF_OBJ,
                         STR_NOM,
                         KOD_SLED_LOK,
                         LAG (KOD_SLED_LOK, 1, KOD_SLED_LOK)
                            OVER (ORDER BY STR_NOM)
                            NEXT_LSLED
                    FROM tmp_rabota_mm
                ORDER BY STR_NOM)
         LOOP
            IF I.KOD_SLED_LOK <> I.NEXT_LSLED
            THEN
               CNT_LSLED := CNT_LSLED + 1;
            END IF;

            INSERT INTO TMP_SLED_LOK_MM (TMP_IDF_OBJ,
                                         STR_NOM,
                                         KOD_SLED_LOK,
                                         RANG_SLED_LOK)
                 VALUES (I.TMP_IDF_OBJ,
                         I.STR_NOM,
                         I.KOD_SLED_LOK,
                         CNT_LSLED);
         END LOOP;



         UPDATE tmp_rabota_mm a
            SET RANG_SLED_LOK =
                   (SELECT RANG_SLED_LOK
                      FROM tmp_sled_lok_mm
                     WHERE     TMP_IDF_OBJ = a.TMP_IDF_OBJ
                           AND                          ----------------------
                              STR_NOM = a.STR_NOM);



         BEGIN
            INSERT INTO S_ITF_SUBS_LSLED_MM (TMP_IDF_OBJ,
                                             IDF_TPS,
                                             SDATE_BEG,
                                             KOD_SLED_OKDL,
                                             STR_NOM_BEG,
                                             STR_NOM_END,
                                             OZN_TAKS)
                 SELECT TMP_IDF_OBJ,
                        (SELECT IDF_TPS
                           FROM S_ITF_SUBS_LOK_MM
                          WHERE OZN_TAKS = 1),
                        MIN (KONEC) KEEP (DENSE_RANK FIRST ORDER BY STR_NOM),
                        KOD_SLED_LOK,
                        MIN (STR_NOM),
                        RANG_SLED_LOK,
                        1
                   FROM TMP_RABOTA_MM
               GROUP BY TMP_IDF_OBJ, KOD_SLED_LOK, RANG_SLED_LOK;
         EXCEPTION
            WHEN OTHERS
            THEN
               S_LOG_WORK.ADD_RECORD (
                  S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                  '1');
         END;



         BEGIN
            UPDATE S_ITF_SUBS_LSLED_MM a
               SET (STR_NOM_END, SDATE_END) =
                      (  SELECT MAX (Q.STR_NOM) STR_END,
                                MAX (NACH)
                                   KEEP (DENSE_RANK LAST ORDER BY Q.STR_NOM)
                                   DATE_END
                           FROM TMP_RABOTA_MM t,
                                (SELECT STR_NOM,
                                        LAG (RANG_SLED_LOK, 1, RANG_SLED_LOK)
                                           OVER (ORDER BY STR_NOM)
                                           GRP
                                   FROM TMP_RABOTA_MM) Q
                          WHERE t.STR_NOM = Q.STR_NOM AND Q.GRP = a.STR_NOM_END
                       GROUP BY Q.GRP);
         EXCEPTION
            WHEN OTHERS
            THEN
               S_LOG_WORK.ADD_RECORD (
                  S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                  '2');
         END;



         -- Формирование уникального значения по изменению состояния поезда, состава поезда, вспомогательным локомотивам
         UPDATE TMP_RABOTA_MM a
            SET (RANG_ITOG_POEZD, RANG_LOK_POEZD) =
                   (SELECT RANG_ITOG, RANG_LOK_POEZD
                      FROM (SELECT STR_NOM,
                                     10
                                   * DENSE_RANK ()
                                        OVER (ORDER BY IDF_ITOG_POEZD)
                                      RANG_ITOG,
                                     10
                                   * DENSE_RANK ()
                                        OVER (ORDER BY IDF_LOK_POEZD)
                                      RANG_LOK_POEZD
                              FROM TMP_RABOTA_MM)
                     WHERE STR_NOM = a.STR_NOM);


         -- Формирование уникального значения для каждой смены состояния поезда
         FOR I
            IN (  SELECT TMP_IDF_OBJ,
                         STR_NOM,
                         IDF_POIZD,
                         NOM_P,
                         ESR_FORM,
                         NOM_SOST,
                         ESR_NAZN,
                         NOM_POK,
                         VID_RUXU,
                         ROD_P,
                         KOL_OS,
                         KOL_VAG,
                         VES_NETTO,
                         VES_BRUTTO,
                         LAG (IDF_POIZD || NOM_POK) OVER (ORDER BY STR_NOM)
                            NEXT_ST_P
                    FROM tmp_rabota_mm
                ORDER BY STR_NOM)
         LOOP
            IF I.IDF_POIZD || I.NOM_POK <> I.NEXT_ST_P
            THEN
               CNT_ST_POEZD := CNT_ST_POEZD + 1;
            END IF;

            INSERT INTO TMP_SOST_POEZD_MM (TMP_IDF_OBJ,
                                           STR_NOM,
                                           IDF_POIZD,
                                           NOM_P,
                                           ESR_FORM,
                                           NOM_SOST,
                                           ESR_NAZN,
                                           NOM_POK,
                                           VID_RUXU,
                                           ROD_P,
                                           KOL_OS,
                                           KOL_VAG,
                                           VES_NETTO,
                                           VES_BRUTTO,
                                           RANG_POEZD)
                 VALUES (I.TMP_IDF_OBJ,
                         I.STR_NOM,
                         I.IDF_POIZD,
                         I.NOM_P,
                         I.ESR_FORM,
                         I.NOM_SOST,
                         I.ESR_NAZN,
                         I.NOM_POK,
                         I.VID_RUXU,
                         I.ROD_P,
                         I.KOL_OS,
                         I.KOL_VAG,
                         I.VES_NETTO,
                         I.VES_BRUTTO,
                         CNT_ST_POEZD);
         END LOOP;



         UPDATE tmp_rabota_mm a
            SET RANG_POEZD =
                   (SELECT RANG_POEZD
                      FROM tmp_sost_poezd_mm
                     WHERE     TMP_IDF_OBJ = a.TMP_IDF_OBJ
                           AND STR_NOM = a.STR_NOM);



         BEGIN
            INSERT INTO S_ITF_SUBS_POIZD_MM (TMP_IDF_OBJ,
                                             SDATE_BEG,
                                             STR_NOM_BEG,
                                             STR_NOM_END,
                                             IDF_POIZD,
                                             ESR_FORM,
                                             ORD_NUM,
                                             ESR_NAZN,
                                             NOM_POK,
                                             VID_RUXU,
                                             ROD_P,
                                             OSI,
                                             VS_VAG,
                                             NETTO,
                                             BRUTTO)
                 SELECT TMP_IDF_OBJ,
                        MIN (KONEC) KEEP (DENSE_RANK FIRST ORDER BY STR_NOM)
                           SDATE_BEG,
                        MIN (STR_NOM) STR_NOM_BEG,
                        RANG_POEZD STR_NOM_END,
                        IDF_POIZD,
                        ESR_FORM,
                        NOM_SOST,
                        ESR_NAZN,
                        NOM_POK,
                        VID_RUXU,
                        ROD_P,
                        KOL_OS,
                        KOL_VAG,
                        VES_NETTO,
                        VES_BRUTTO
                   FROM TMP_RABOTA_MM
                  WHERE KONEC IS NOT NULL
               GROUP BY TMP_IDF_OBJ,
                        RANG_POEZD,
                        IDF_POIZD,
                        ESR_FORM,
                        NOM_SOST,
                        ESR_NAZN,
                        NOM_POK,
                        VID_RUXU,
                        ROD_P,
                        KOL_OS,
                        KOL_VAG,
                        VES_NETTO,
                        VES_BRUTTO
               ORDER BY STR_NOM_BEG;
         EXCEPTION
            WHEN OTHERS
            THEN
               S_LOG_WORK.ADD_RECORD (
                  S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                  '3');
         END;



         BEGIN
            UPDATE S_ITF_SUBS_POIZD_MM a
               SET (STR_NOM_END, SDATE_END) =
                      (  SELECT MAX (Q.STR_NOM) STR_END,
                                MAX (NACH)
                                   KEEP (DENSE_RANK LAST ORDER BY Q.STR_NOM)
                                   DATE_END
                           FROM TMP_RABOTA_MM t,
                                (SELECT STR_NOM,
                                        LAG (RANG_POEZD, 1, RANG_POEZD)
                                           OVER (ORDER BY STR_NOM)
                                           GRP
                                   FROM TMP_RABOTA_MM) Q
                          WHERE t.STR_NOM = Q.STR_NOM AND Q.GRP = a.STR_NOM_END
                       GROUP BY Q.GRP);

            UPDATE S_ITF_SUBS_POIZD_MM a
               SET (NOM_P) =
                      (SELECT NOM_P
                         FROM TMP_RABOTA_MM t
                        WHERE     t.IDF_POIZD = a.IDF_POIZD
                              AND t.STR_NOM = a.STR_NOM_BEG);
         EXCEPTION
            WHEN OTHERS
            THEN
               S_LOG_WORK.ADD_RECORD (
                  S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                  '4');
         END;


         --VV 28.02.2018
         /* BEGIN
             INSERT INTO S_ITF_SUBS_P_RPS_MM (TMP_IDF_OBJ,
                                              NOM_POK,
                                              STR_NOM_BEG,
                                              STR_NOM_END,
                                              SDATE_BEG,
                                              KOD_RPS,
                                              KOL_GR,
                                              KOL_POR,
                                              Z_TIP_PARKA)
                (  SELECT /*+ index(l I_LINK_POIZD_VAG_IDFBACK) */
         --Проблема была в запросе по выполнению!Юля помогла этой сылкой(Индекс)
               /* p.TMP_IDF_OBJ,
                p.NOM_POK,
                p.STR_NOM STR_NOM_BEG,
                p.RANG_ITOG_POEZD STR_NOM_END,
                p.SDATE_BEG,
                N.RVO1198 KOD_RPS,
                SUM (DECODE (PR_GRUZH, 1, 1, 0)) KOL_GR,
                SUM (DECODE (PR_GRUZH, 0, 1, 0)) KOL_POR,
                CASE
                   WHEN t.KOD_STAN IN (1, 4) THEN 1
                   WHEN t.KOD_STAN = 8 THEN 2
                   ELSE 1
                END
                   TIP_PARKA
           FROM (  SELECT TMP_IDF_OBJ,
                          IDF_ITOG_POEZD,
                          NOM_POK,
                          MIN (STR_NOM) STR_NOM,
                          MIN (KONEC)
                             KEEP (DENSE_RANK FIRST ORDER BY STR_NOM)
                             SDATE_BEG,
                          RANG_ITOG_POEZD
                     FROM tmp_rabota_mm
                    WHERE     TMP_IDF_OBJ = X_TMP_IDF_OBJ
                          AND STR_NOM <>
                                 (SELECT MAX (STR_NOM) FROM tmp_rabota_mm)
                 GROUP BY TMP_IDF_OBJ,
                          NOM_POK,
                          IDF_ITOG_POEZD,
                          RANG_ITOG_POEZD) p,
                MD_VAG.LINK_POIZD_VAG L,
                MD_VAG.OPERS_VAG O,
                MD_VAG.ST_POGRUZKA_VAG p,
                MD_VAG.ST_TEH_SOST_VAG H,
                MD_VAG.ST_ARC_VAG a,
                NSI.DOV_PAR_P2 t,
                NSI.M1198 N
          WHERE     1 = 1
                AND O.STATUS = 0
                AND O.PART = 300101
                AND IDF_POK_POIZD = p.IDF_ITOG_POEZD
                AND IDF_OP = IDF_DISL_VAG
                AND O.IDF_POGRUZKA = p.IDF_POGRUZKA
                AND O.IDF_ARC = a.IDF_ARC
                AND O.IDF_TEH_SOST = H.IDF_TEH_SOST(+)
                AND CASE
                       WHEN EXISTS
                               (SELECT 1
                                  FROM NSI.DOV_PAR_P2
                                 WHERE     H.TIP_PARKA_TEH_SOST =
                                              KOD_PARK
                                       AND KOD_STAN = 8)
                       THEN
                          H.TIP_PARKA_TEH_SOST
                       ELSE
                          p.TIP_PARKA_POGRUZKA
                    END = t.KOD_PARK
                AND t.KOD_STAN IN (1, 4, 8)
                AND a.ROD_VAG = N.RV1198
       GROUP BY p.TMP_IDF_OBJ,
                p.IDF_ITOG_POEZD,
                p.NOM_POK,
                p.STR_NOM,
                p.RANG_ITOG_POEZD,
                p.SDATE_BEG,
                CASE
                   WHEN t.KOD_STAN IN (1, 4) THEN 1
                   WHEN t.KOD_STAN = 8 THEN 2
                   ELSE 1
                END,
                N.RVO1198);
EXCEPTION
   WHEN OTHERS
   THEN
      S_LOG_WORK.ADD_RECORD (
         S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
         '5');
END;


         --VV 28.02.2018
         /* BEGIN
             INSERT INTO S_ITF_SUBS_P_RPS_MM (TMP_IDF_OBJ,
                                              NOM_POK,
                                              STR_NOM_BEG,
                                              STR_NOM_END,
                                              SDATE_BEG,
                                              KOD_RPS,
                                              KOL_GR,
                                              KOL_POR,
                                              Z_TIP_PARKA)
                (  SELECT p.TMP_IDF_OBJ,
                          p.NOM_POK,
                          p.STR_NOM STR_NOM_BEG,
                          p.RANG_ITOG_POEZD STR_NOM_END,
                          p.SDATE_BEG,
                          a.ROD_VAG KOD_RPS,
                          SUM (DECODE (PR_GRUZH, 1, 1, 0)) KOL_GR,
                          SUM (DECODE (PR_GRUZH, 0, 1, 0)) KOL_POR,
                          CASE
                             WHEN USL_TIP BETWEEN 100 AND 200 THEN 3
                             ELSE 4
                          END
                             TIP_PARKA
                     FROM (  SELECT TMP_IDF_OBJ,
                                    IDF_ITOG_POEZD,
                                    NOM_POK,
                                    MIN (STR_NOM) STR_NOM,
                                    MIN (KONEC)
                                       KEEP (DENSE_RANK FIRST ORDER BY STR_NOM)
                                       SDATE_BEG,
                                    RANG_ITOG_POEZD
                               FROM tmp_rabota_mm
                              WHERE     TMP_IDF_OBJ = X_TMP_IDF_OBJ
                                    AND STR_NOM <>
                                           (SELECT MAX (STR_NOM)
                                              FROM tmp_rabota_mm)
                           GROUP BY TMP_IDF_OBJ,
                                    NOM_POK,
                                    IDF_ITOG_POEZD,
                                    RANG_ITOG_POEZD) p,
                          MD_VAG.LINK_POIZD_VAG L,
                          MD_VAG.OPERS_VAG O,
                          MD_VAG.ST_POGRUZKA_VAG p,
                          MD_VAG.ST_ARC_VAG a
                    WHERE     1 = 1
                          AND O.STATUS = 0
                          AND O.PART = 300101
                          AND L.IDF_POK_POIZD = p.IDF_ITOG_POEZD
                          AND O.IDF_OP = L.IDF_DISL_VAG
                          AND O.IDF_POGRUZKA = p.IDF_POGRUZKA
                          AND p.TIP_PARKA_POGRUZKA = 50
                          AND O.IDF_ARC = a.IDF_ARC
                 GROUP BY p.TMP_IDF_OBJ,
                          p.IDF_ITOG_POEZD,
                          p.NOM_POK,
                          p.STR_NOM,
                          p.RANG_ITOG_POEZD,
                          p.SDATE_BEG,
                          CASE
                             WHEN USL_TIP BETWEEN 100 AND 200 THEN 3
                             ELSE 4
                          END,
                          ROD_VAG);
          EXCEPTION
             WHEN OTHERS
             THEN
                S_LOG_WORK.ADD_RECORD (
                   S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                   '6');
          END;*/


         --VV 28.02.2018
         /*  BEGIN
              UPDATE S_ITF_SUBS_P_RPS_MM a
                 SET (STR_NOM_END, SDATE_END) =
                        (  SELECT MAX (Q.STR_NOM) STR_END,
                                  MAX (NACH)
                                     KEEP (DENSE_RANK LAST ORDER BY Q.STR_NOM)
                                     DATE_END
                             FROM TMP_RABOTA_MM t,
                                  (SELECT STR_NOM,
                                          LAG (RANG_ITOG_POEZD,
                                               1,
                                               RANG_ITOG_POEZD)
                                          OVER (ORDER BY STR_NOM)
                                             GRP
                                     FROM TMP_RABOTA_MM) Q
                            WHERE t.STR_NOM = Q.STR_NOM AND Q.GRP = a.STR_NOM_END
                         GROUP BY Q.GRP);
           EXCEPTION
              WHEN OTHERS
              THEN
                 S_LOG_WORK.ADD_RECORD (
                    S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                    '7');
           END;*/


         -- Формирование данных по составу поезда только для пассажирских поездов
         INSERT INTO S_ITF_SUBS_SOST_P_POIZD (TMP_IDF_OBJ,
                                              TIP_PARKA,
                                              ROD_VAG,
                                              KOL_VAG,
                                              kod_stan_park)
            (SELECT IDF_ITOG,
                    TIP_PARKA,
                    ROD_VAG,
                    KOL_VAG,
                    kod_stan_park
               FROM S_V_SUBS_SOST_P_POIZD S
              WHERE S.IDF_ITOG IN (SELECT DISTINCT IDF_ITOG
                                     FROM tmp_emm a,
                                          S_ITF_MAIN_BRIG B,
                                          S_ITF_MAIN_POIZD p,
                                          S_ITF_MAIN_TPS L
                                    WHERE     B.NOM_MM = a.NOM_MM
                                          AND B.IDF_BRIG = a.IDF_BRIG
                                          --AND L.IDF_TPS = B.CODE_OBJ_DISL
                                          AND p.IDF_POIZD = L.KOD_OBJ_DISL
                                          AND p.IDF_ITOG IS NOT NULL));

         --VV 28.02.2018 AND TIP_PARKA = 70);

         BEGIN
            INSERT INTO S_ITF_SUBS_P_RPS_MM (TMP_IDF_OBJ,
                                             NOM_POK,
                                             STR_NOM_BEG,
                                             STR_NOM_END,
                                             SDATE_BEG,
                                             KOD_RPS,
                                             KOL_GR,
                                             KOL_POR,
                                             Z_TIP_PARKA)
               (  SELECT p.TMP_IDF_OBJ,
                         p.NOM_POK,
                         p.STR_NOM STR_NOM_BEG,
                         p.RANG_ITOG_POEZD STR_NOM_END,
                         p.SDATE_BEG,
                         I.ROD_VAG KOD_RPS,
                         SUM (DECODE (b.gr, 1, 1, 0)) KOL_GR,
                         SUM (DECODE (b.gr, 0, 1, 0)) KOL_POR,
                         --SUM (I.KOL_VAG) KOL_GR,
                         --0 KOL_POR,
                         b.Z_TIP_PARKA
                    FROM (  SELECT TMP_IDF_OBJ,
                                   IDF_ITOG_POEZD,
                                   NOM_POK,
                                   MIN (STR_NOM) STR_NOM,
                                   MIN (KONEC)
                                      KEEP (DENSE_RANK FIRST ORDER BY STR_NOM)
                                      SDATE_BEG,
                                   RANG_ITOG_POEZD
                              FROM tmp_rabota_mm
                             --WHERE TMP_IDF_OBJ = X_TMP_IDF_OBJ
                          GROUP BY TMP_IDF_OBJ,
                                   NOM_POK,
                                   IDF_ITOG_POEZD,
                                   RANG_ITOG_POEZD) p,
                         S_ITF_SUBS_SOST_P_POIZD I,
                         S_P_RPS_MM_EMM b
                   WHERE     I.TMP_IDF_OBJ = p.IDF_ITOG_POEZD
                         AND b.tip_parka = i.tip_parka
                         AND b.kod_stan_park = i.kod_stan_park
                GROUP BY p.TMP_IDF_OBJ,
                         p.NOM_POK,
                         p.STR_NOM,
                         p.RANG_ITOG_POEZD,
                         p.SDATE_BEG,
                         I.ROD_VAG,
                         b.Z_TIP_PARKA);
         EXCEPTION
            WHEN OTHERS
            THEN
               S_LOG_WORK.ADD_RECORD (
                  S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                  '8');
         END;

         --VV 28.02.2018
         /* BEGIN
             INSERT INTO S_ITF_SUBS_P_RPS_MM (TMP_IDF_OBJ,
                                              NOM_POK,
                                              STR_NOM_BEG,
                                              STR_NOM_END,
                                              SDATE_BEG,
                                              KOD_RPS,
                                              KOL_GR,
                                              KOL_POR)
                (  SELECT p.TMP_IDF_OBJ,
                          p.NOM_POK,
                          p.STR_NOM STR_NOM_BEG,
                          p.RANG_ITOG_POEZD STR_NOM_END,
                          p.SDATE_BEG,
                          I.ROD_VAG KOD_RPS,
                          SUM (I.KOL_VAG) KOL_GR,
                          0 KOL_POR
                     FROM (  SELECT TMP_IDF_OBJ,
                                    IDF_ITOG_POEZD,
                                    NOM_POK,
                                    MIN (STR_NOM) STR_NOM,
                                    MIN (KONEC)
                                       KEEP (DENSE_RANK FIRST ORDER BY STR_NOM)
                                       SDATE_BEG,
                                    RANG_ITOG_POEZD
                               FROM tmp_rabota_mm
                              WHERE TMP_IDF_OBJ = X_TMP_IDF_OBJ
                           GROUP BY TMP_IDF_OBJ,
                                    NOM_POK,
                                    IDF_ITOG_POEZD,
                                    RANG_ITOG_POEZD) p,
                          S_ITF_SUBS_SOST_P_POIZD I
                    WHERE I.TMP_IDF_OBJ = p.IDF_ITOG_POEZD AND I.TIP_PARKA = 70
                 GROUP BY p.TMP_IDF_OBJ,
                          p.NOM_POK,
                          p.STR_NOM,
                          p.RANG_ITOG_POEZD,
                          p.SDATE_BEG,
                          I.ROD_VAG);
          EXCEPTION
             WHEN OTHERS
             THEN
                S_LOG_WORK.ADD_RECORD (
                   S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                   '8');
          END;*/


         --VV 28.02.2018
         IF SQL%FOUND
         THEN
            UPDATE S_ITF_SUBS_P_RPS_MM a
               SET (STR_NOM_END, SDATE_END) =
                      (  SELECT MAX (Q.STR_NOM) STR_END,
                                MAX (NACH)
                                   KEEP (DENSE_RANK LAST ORDER BY Q.STR_NOM)
                                   DATE_END
                           FROM TMP_RABOTA_MM t,
                                (SELECT STR_NOM,
                                        LAG (RANG_ITOG_POEZD,
                                             1,
                                             RANG_ITOG_POEZD)
                                        OVER (ORDER BY STR_NOM)
                                           GRP
                                   FROM TMP_RABOTA_MM) Q
                          WHERE t.STR_NOM = Q.STR_NOM AND Q.GRP = a.STR_NOM_END
                       GROUP BY Q.GRP)
             WHERE SDATE_END IS NULL;
         END IF;
      ELSE
         S_LOG_WORK.ADD_RECORD (
            S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
            'Ошибка не считали S_ITF_MAIN_POIZD');
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'Ошибка NO_DATA_FOUND PART 7 MM');
      WHEN OTHERS
      THEN
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                'Ошибка OTHERS PART 7 MM' || SQLERRM);
   END;

   --інформація про локомотиви, які працюють у різних з’єднаннях
   PROCEDURE PART4_MM
   IS
      X_TMP_IDF_OBJ   S_ITF_MAIN_MM.TMP_IDF_OBJ%TYPE;
      IDF_EVENT_      S_ITF_KEY_MSG.IDF_EVENT%TYPE;
   BEGIN
      SELECT TMP_IDF_OBJ INTO X_TMP_IDF_OBJ FROM S_ITF_MAIN_MM--WHERE DATA_SOURCE IN (-1, 1)
      ;

      SELECT IDF_EVENT INTO IDF_EVENT_ FROM S_ITF_KEY_MSG;

      --delete S_ITF_MAIN_TPS;
      ------------------------------------------------
      --инсертим в S_ITF_LINK_TRAIN_TPS
      INSERT INTO S_ITF_LINK_TRAIN_TPS IP (TMP_IDF_DISL_TPS,
                                           TMP_IDF_LOK_POIZD,
                                           IDF_DISL_TPS,
                                           IDF_LOK_POIZD,
                                           PART)
         (SELECT DISTINCT p.IDF_LOK,
                          p.TMP_IDF_OBJ,
                          L.IDF_DISL_TPS,
                          L.IDF_LOK_POIZD,
                          L.PART
            FROM S_ITF_MAIN_POIZD p, S_V_LINK_TRAIN_TPS L
           WHERE     p.IDF_LOK IS NOT NULL
                 AND p.KOL_LOK > 1
                 AND L.IDF_LOK_POIZD = p.IDF_LOK
                 AND L.PART = 300101
                 AND p.TMP_IDF_OBJ = X_TMP_IDF_OBJ);        --v_mm.tmp_idf_obj

      --инсертим в S_ITF_MAIN_TPS
      INSERT INTO S_ITF_MAIN_TPS I (TMP_IDF_OBJ,
                                    IDF_DISL,
                                    IDF_OP,
                                    DATA_SOURCE,
                                    IDF_TPS,
                                    ROW_ORDER,
                                    NAME_LOK,
                                    ID_SER,
                                    KOD_SEK,
                                    DATE_OP,
                                    DATE_TO2,
                                    DATE_OP_END,
                                    CNT_SEK,
                                    ST_CODE_WORK,
                                    ID_DEPO,
                                    PROBEG_LIN,
                                    CODE_OP,
                                    IDF_BRIG,
                                    DATE_BEG_BRIG,
                                    DATE_END_BRIG,
                                    DATE_BEG_DISL,
                                    DATE_END_DISL)
         (SELECT L.TMP_IDF_LOK_POIZD,
                 L.TMP_IDF_DISL_TPS,
                 t.IDF_OP,
                 1,
                 t.IDF_TPS,
                 ROWNUM,
                 NAME_LOK,
                 ID_SER,
                 KOD_SEK,
                 t.DATE_OP,
                 DATE_TO2,
                 t.DATE_OP_END,
                 CNT_SEK,
                 ST_CODE_WORK,
                 ID_DEPO,
                 PROBEG_LIN,
                 t.CODE_OP,
                 t.IDF_BRIG,
                 DATE_BEG_BRIG,
                 DATE_END_BRIG,
                 t.DATE_BEG_DISL,
                 t.DATE_END_DISL
            FROM S_ITF_LINK_TRAIN_TPS L, S_V_FULL_TPS_BY_DISL t
           WHERE     L.TMP_IDF_LOK_POIZD = X_TMP_IDF_OBJ    --v_mm.tmp_idf_obj
                 AND t.IDF_DISL = L.IDF_DISL_TPS
                 AND t.PART_DISL = 300101
                 AND t.PART_OP = 300101
                 AND t.IDF_OP = t.IDF_DISL
                 AND t.IDF_TPS NOT IN (SELECT IDF_TPS
                                         FROM S_ITF_MAIN_TPS
                                        WHERE TMP_IDF_OBJ =
                                                 L.TMP_IDF_LOK_POIZD));


      IF SQL%FOUND
      THEN
         --инсертим вS_ITF_SUBS_LOK_MM
         INSERT INTO S_ITF_SUBS_LOK_MM (TMP_IDF_OBJ,
                                        IDF_TPS,
                                        KOD_SER,
                                        NAME_LOK,
                                        DEPO_LOK,
                                        CNT_SEK,
                                        PR_SEC,
                                        OZN_TAKS)
            SELECT DISTINCT
                   L.TMP_IDF_OBJ,
                   L.IDF_TPS,
                   L.ID_SER,
                   NAME_LOK,
                   ID_DEPO,
                   CNT_SEK,
                   CASE
                      WHEN CNT_SEK = S.KOL_SEKC THEN 0
                      WHEN CNT_SEK < S.KOL_SEKC THEN 1
                      WHEN CNT_SEK > S.KOL_SEKC THEN 2
                   END,
                   0
              FROM S_ITF_MAIN_TPS L, S_V_DIC_SER S, TMP_EMM k
             WHERE     L.TMP_IDF_OBJ = X_TMP_IDF_OBJ
                   AND                                  --v_mm.tmp_idf_obj and
                      L.ID_SER = S.ID_SER
                   AND L.DATA_SOURCE = 1
                   AND L.IDF_TPS != k.IDF_TPS; -- (SELECT IDF_TPS FROM TMP_EMM);--22.12.2017

         -----------------------------------------------------------------
         DELETE S_ITF_MAIN_SEC;

         --инсертим в S_ITF_MAIN_SEC
         INSERT INTO S_ITF_MAIN_SEC (DATA_SOURCE,
                                     TMP_IDF_OBJ,
                                     IDF_SEC,
                                     ID_SER,
                                     NOM,
                                     KOD_SEC,
                                     KOD_OBJ_DISL)
            (SELECT DISTINCT 1,
                             C.TMP_IDF_OBJ,
                             a.IDF_SEC,
                             a.ID_SER,
                             a.NOM,
                             a.KOD_SEC,
                             B.IDF_TPS
               FROM S_V_FULL_SEC_ONLINE a,
                    S_ITF_MAIN_MM C,
                    S_ITF_MAIN_TPS B,
                    TMP_EMM k
              WHERE     B.IDF_TPS != k.IDF_TPS --(SELECT IDF_TPS FROM TMP_EMM)--22.12.2017
                    AND a.KOD_OBJ_DISL = B.IDF_TPS --AND C.DATA_SOURCE IN (-1, 1)
                    AND a.DATE_OP <= C.PRIEM
                    AND a.DATE_OP_END > C.PRIEM);

         -------------------------------------------------------------
         --инсертим в S_ITF_SUBS_SEC_MM
         INSERT INTO S_ITF_SUBS_SEC_MM (TMP_IDF_OBJ,
                                        IDF_SEC,
                                        ID_SER,
                                        NOM_LOK,
                                        KOD_SEK,
                                        IDF_TPS)
            (SELECT a.TMP_IDF_OBJ,
                    a.IDF_SEC,
                    a.ID_SER,
                    a.NOM,
                    a.KOD_SEC,
                    a.KOD_OBJ_DISL
               FROM S_ITF_MAIN_SEC a);

         -----------------------------------------------------------------------
         BEGIN
            --инсертим в S_ITF_SUBS_LSLED_MM
            INSERT INTO S_ITF_SUBS_LSLED_MM (TMP_IDF_OBJ,
                                             STR_NOM_BEG,
                                             STR_NOM_END,
                                             SDATE_BEG,
                                             IDF_TPS,
                                             KOD_SLED_OKDL,
                                             NPP,
                                             OZN_TAKS)
               (SELECT p.TMP_IDF_OBJ,
                       p.BEG_STR,
                       p.RANG_LOK_POEZD,
                       p.SDATE_BEG,
                       L.IDF_TPS,
                       L.ST_CODE_WORK,
                       ROWNUM,
                       DECODE (L.ST_CODE_WORK,
                               8, 2,
                               3, DECODE (L.IDF_TPS, NULL, 3, 0),
                               4, DECODE (L.IDF_TPS, NULL, 3, 0),
                               0)
                  FROM (  SELECT p.TMP_IDF_OBJ,
                                 p.IDF_LOK_POEZD,
                                 p.RANG_LOK_POEZD,
                                 MIN (p.STR_NOM) BEG_STR,
                                 MIN (p.KONEC)
                                    KEEP (DENSE_RANK FIRST ORDER BY p.STR_NOM)
                                    SDATE_BEG
                            FROM tmp_rabota_mm p
                           WHERE p.TMP_IDF_OBJ = X_TMP_IDF_OBJ --v_mm.tmp_idf_obj
                        GROUP BY p.TMP_IDF_OBJ,
                                 p.IDF_LOK_POEZD,
                                 p.RANG_LOK_POEZD) p,
                       S_ITF_MAIN_TPS L,
                       TMP_EMM k
                 WHERE     p.TMP_IDF_OBJ = X_TMP_IDF_OBJ
                       AND                              --v_mm.tmp_idf_obj and
                          L.TMP_IDF_OBJ = p.TMP_IDF_OBJ
                       AND p.IDF_LOK_POEZD = L.IDF_DISL
                       AND L.DATA_SOURCE = 1
                       AND L.IDF_TPS != k.IDF_TPS); --(SELECT IDF_TPS FROM TMP_EMM)--22.12.2017
         EXCEPTION
            WHEN OTHERS
            THEN
               S_LOG_WORK.ADD_RECORD (
                  S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                  '9');
         END;

         BEGIN
            --обновляем в S_ITF_SUBS_LSLED_MM
            UPDATE S_ITF_SUBS_LSLED_MM a
               SET (STR_NOM_END, SDATE_END) =
                      (  SELECT MAX (Q.STR_NOM) STR_END,
                                MAX (NACH)
                                   KEEP (DENSE_RANK LAST ORDER BY Q.STR_NOM)
                                   DATE_END
                           FROM TMP_RABOTA_MM t,
                                (SELECT STR_NOM,
                                        LAG (RANG_LOK_POEZD, 1, RANG_LOK_POEZD)
                                           OVER (ORDER BY STR_NOM)
                                           GRP
                                   FROM TMP_RABOTA_MM) Q
                          WHERE t.STR_NOM = Q.STR_NOM AND Q.GRP = a.STR_NOM_END
                       GROUP BY Q.GRP)
             WHERE OZN_TAKS <> 1;

            -----------------------------------------------------------------
            BEGIN
               BEGIN
                  FOR I IN (SELECT *
                              FROM S_ITF_SUBS_LSLED_MM
                             WHERE NPP IS NOT NULL)
                  LOOP
                     --обновляем в S_ITF_SUBS_LSLED_MM
                     UPDATE S_ITF_SUBS_LSLED_MM
                        SET KOD_SLED =
                               NVL (
                                  (SELECT KOD_SLED_MM
                                     FROM NSI.LM_KOD_SLED_OKDL --22.08.2017 сменили наNSI.LM_KOD_SLED_OKDL с привязкой к PR_actual
                                    WHERE     VID_SLED_1 =
                                                 (SELECT KOD_SLED_OKDL
                                                    FROM S_ITF_SUBS_LSLED_MM
                                                   WHERE     STR_NOM_BEG <=
                                                                I.STR_NOM_BEG
                                                         AND STR_NOM_END >=
                                                                I.STR_NOM_END
                                                         AND NPP IS NULL
                                                         AND ROWNUM = 1)
                                          AND VID_SLED_4 = I.KOD_SLED_OKDL
                                          AND PR_ACTUAL != 1
                                          AND PR_BRIG_4 =
                                                 DECODE (I.IDF_TPS,
                                                         NULL, 0,
                                                         1)),
                                  0)
                      WHERE NPP = I.NPP;
                  END LOOP;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     DBMS_OUTPUT.put_line (
                        'Ошибка UPDATE S_ITF_SUBS_LSLED_MM.kod_sled ');
               END;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  DBMS_OUTPUT.put_line (
                     'Ошибка UPDATE S_ITF_SUBS_LSLED_MM ');

                  UPDATE S_ITF_SUBS_LSLED_MM
                     SET KOD_SLED = 0
                   WHERE OZN_TAKS != 1;
            END;
         -----------------------------------------------------------------------------------------------
         EXCEPTION
            WHEN OTHERS
            THEN
               S_LOG_WORK.ADD_RECORD (
                  S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                  '10');
         END;
      END IF;
   END;

   --Топливo
   PROCEDURE FUEL_MM
   IS
      KOL_STROK   NUMBER;
   BEGIN
      --инсертим в S_ITF_MAIN_SEC
      INSERT INTO S_ITF_MAIN_SEC (DATA_SOURCE,
                                  TMP_IDF_OBJ,
                                  DATE_OP,
                                  IDF_OP,
                                  IDF_OP_END_SEC,
                                  IDF_SEC,
                                  ID_SER,
                                  NOM,
                                  KOD_SEC,
                                  T_LICH_POS,
                                  T_LICH_ZM,
                                  LICH_OP,
                                  LICH_REC,
                                  EK_PAL_END_KG,
                                  EK_PAL_END_L,
                                  EK_MASL_END_L,
                                  EK_MASL_END_KG)
         (SELECT 3,
                 C.TMP_IDF_OBJ,
                 a.DATE_OP,
                 a.IDF_OP,
                 a.IDF_OP_END,
                 a.IDF_SEC,
                 a.ID_SER,
                 a.NOM,
                 a.KOD_SEC,
                 a.T_LICH_POS,
                 a.T_LICH_ZM,
                 a.LICH_OP,
                 a.LICH_REC,
                 a.EK_PAL_END_KG,
                 a.EK_PAL_END_L,
                 a.EK_MASL_END_L,
                 a.EK_MASL_END_KG
            FROM S_V_FULL_SEC_ONLINE a, S_ITF_SUBS_LOK_MM B, S_ITF_MAIN_MM C
           WHERE     a.DATE_OP >= C.PRIEM
                 AND a.DATE_OP <= C.SD_LOK
                 AND a.KOD_OBJ_DISL = B.IDF_TPS
                 AND B.OZN_TAKS = 1);

      --инсертим в S_ITF_SUBS_PER_SEC_MM
      INSERT INTO S_ITF_SUBS_PER_SEC_MM (TMP_IDF_OBJ,
                                         IDF_SEC,
                                         DATE_ZAM,
                                         OP_ZAM,
                                         LICH_P,
                                         LICH_ZM,
                                         LICH_OP,
                                         LICH_REC,
                                         TOPL_L,
                                         TOPL_KG,
                                         MAS_L,
                                         MAS_KG)
         (SELECT C.TMP_IDF_OBJ,
                 B.IDF_SEC,
                 B.DATE_OP,
                 CASE
                    WHEN B.DATE_OP = C.PRIEM THEN 2
                    WHEN B.DATE_OP = C.SD_LOK THEN 3
                    ELSE NULL
                 END,
                 T_LICH_POS,
                 T_LICH_ZM,
                 LICH_OP,
                 LICH_REC,
                 EK_PAL_END_L,
                 EK_PAL_END_KG,
                 EK_MASL_END_L,
                 EK_MASL_END_KG
            FROM S_ITF_MAIN_SEC B, S_ITF_MAIN_MM C
           WHERE     B.DATA_SOURCE = 3          --AND C.DATA_SOURCE IN (-1, 1)
                 AND (B.DATE_OP = C.PRIEM OR B.DATE_OP = C.SD_LOK));

      KOL_STROK := SQL%ROWCOUNT;

      UPDATE S_ITF_MAIN_MM
         SET NORM = 0;


      IF NVL (KOL_STROK, 0) > 0
      THEN
         S_WRITE_TO_MODELS.MARK_STATE_FOR_CHANGE ('MM', 'PER_MM');
         DBMS_OUTPUT.put_line (
            'Записей в S_ITF_SUBS_PER_SEC_MM = ' || KOL_STROK);
      ELSE
         S_LOG_WORK.ADD_RECORD (S_CHANGEDOM_PROC.GETVALUE ('IDF_EVENT'),
                                (' Топлива нет'));
         DBMS_OUTPUT.put_line ('Топлива нет ');
      END IF;
   END;
END EMM_NEW;
/