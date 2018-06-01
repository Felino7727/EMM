CREATE OR REPLACE PACKAGE BODY APPL_DBW.EMM_TCHU
AS
    PROCEDURE MSG_NORMAL( MSG IN OUT S_T_UZXDOC_MESSAGE )
    IS
        P_IDF_DOC   S_ITF_MAIN_MM.IDF_DOC%TYPE; --Переменная для считывания idf_doc
    BEGIN
        MSG.EXITCODE   := 0;

        UPDATE S_ITF_MAIN_MM a   --Производим обновление таблицы S_ITF_MAIN_MM
           SET ( TMP_IDF_OBJ
                ,IDF_MM
                ,IDF_DOC
                ,a.OPER_TYPE
                ,a.DATE_OP
                ,a.DEPO_PR_KOL
                ,a.NUM_COLUMN
                ,a.TYPE_MM
                ,a.KOD_KOL
                ,a.BR_TIME_RAB )      = ( SELECT a.IDF_DOC
                                                ,a.IDF_MM
                                                ,a.IDF_DOC
                                                ,S_WRITE_TO_MODELS.OP_CHANGE_OBJECT
                                                     OPER_TYPE
                                                ,TRUNC( SYSDATE, 'dd' )
                                                ,a.DEPO_PR_KOL
                                                ,a.NUM_COLUMN
                                                ,1
                                                ,a.KOD_KOL
                                                ,( CASE
                                                      WHEN   ( X.END_RAB - X.JAVKA )
                                                           * 1440 >= 1440
                                                      THEN
                                                          NULL
                                                      WHEN   (   X.END_RAB
                                                               - X.JAVKA )
                                                           * 1440 <= 1400
                                                      THEN
                                                                    (   X.END_RAB
                                                                      - X.JAVKA )
                                                                  * 1440
                                                        
                                                  END )
                                            FROM S_SREZ_ACTUAL_MM a
                                                ,TMP_EMM C
                                                ,S_ITF_MAIN_MM X
                                           WHERE     a.IDF_MM = C.IDF_EMM
                                                 AND a.CODE_OP != 54 );

        UPDATE S_ITF_SUBS_BRIG_MM a
           SET a.TMP_IDF_OBJ      = ( SELECT IDF_DOC
                                        FROM S_ITF_MAIN_MM
                                       WHERE CODE_OP = 53 );

        FOR I
            IN ( SELECT JOB
                       ,CLASS_MASH
                       ,IDF_BRIG
                       ,FAM
                       ,TAB_NOM
                       ,OZN_ST_MASH
                   FROM S_V_FULL_BRIG_ONLINE B, S_ITF_MAIN_MM C
                  WHERE     B.DATE_OP <= C.JAVKA
                        AND C.CODE_OP = 53
                        AND B.DATE_OP_END > C.JAVKA
                        AND B.IDF_BRIG IN ( SELECT IDF_BRIG
                                              FROM S_ITF_SUBS_BRIG_MM ) )
        LOOP                --Производим обновление таблицы S_ITF_SUBS_BRIG_MM
            UPDATE S_ITF_SUBS_BRIG_MM a
               SET a.DOLG_BRIG    = I.job
                  ,a.CLASS_MASH   = I.CLASS_MASH
                  ,a.FAM_BRIG     = I.FAM
                  ,a.TAB_BRIG     = I.TAB_NOM
                  ,a.OZN_MASH     = I.OZN_ST_MASH
             WHERE a.IDF_BRIG = I.IDF_BRIG;
        END LOOP;


        SELECT IDF_DOC INTO P_IDF_DOC FROM S_ITF_MAIN_MM;

        INSERT INTO S_ITF_SUBS_LOK_MM( TMP_IDF_OBJ
                                      ,IDF_TPS
                                      ,KOD_SER
                                      ,NAME_LOK
                                      ,DEPO_LOK
                                      ,CNT_SEK
                                      ,PR_SEC
                                      ,OZN_TAKS )
            ( SELECT P_IDF_DOC
                    ,L.IDF_TPS
                    ,L.KOD_SER
                    ,L.NAME_LOK
                    ,L.DEPO_LOK
                    ,L.CNT_SEK
                    ,L.PR_SEC
                    ,L.OZN_TAKS
                FROM MD_MM.SUBS_LOK_MM L
               WHERE L.IDF_DOC = P_IDF_DOC );

        INSERT INTO S_ITF_SUBS_BR_PASS_MM( TMP_IDF_OBJ
                                          ,NPP
                                          ,DATE_OTPR
                                          ,DATE_PRIB
                                          ,NOM_P
                                          ,ST_OTPR
                                          ,ST_PRIB )
            ( SELECT P_IDF_DOC
                    ,a.NPP
                    ,a.DATE_OTPR
                    ,a.DATE_PRIB
                    ,a.NOM_P
                    ,a.ST_OTPR
                    ,a.ST_PRIB
                FROM MD_MM.SUBS_BR_PASS_MM a
               WHERE a.IDF_DOC = P_IDF_DOC );

        FOR J IN ( SELECT IDF_TPS FROM S_ITF_SUBS_LOK_MM )
        LOOP
            INSERT INTO S_ITF_SUBS_SEC_MM( TMP_IDF_OBJ
                                          ,IDF_SEC
                                          ,IDF_TPS
                                          ,ID_SER
                                          ,NOM_LOK
                                          ,KOD_SEK )
                ( SELECT DISTINCT P_IDF_DOC
                                 ,a.IDF_SEC
                                 ,a.IDF_TPS
                                 ,a.ID_SER
                                 ,a.NOM_LOK
                                 ,a.KOD_SEK
                    FROM MD_MM.SUBS_SEC_MM a
                   WHERE a.IDF_TPS = J.IDF_TPS );
        END LOOP;

        INSERT INTO S_ITF_SUBS_RABOTA_PM_MM( TMP_IDF_OBJ
                                            ,STR_NOM
                                            ,PR_RAB
                                            ,ESR
                                            ,KOD_WORK
                                            ,NACH
                                            ,KONEC
                                            ,TIP_INF_OTPR
                                            ,TIP_INF_PR )
            ( SELECT P_IDF_DOC
                    ,STR_NOM
                    ,PR_RAB
                    ,ESR
                    ,KOD_WORK
                    ,NACH
                    ,KONEC
                    ,TIP_INF_OTPR
                    ,TIP_INF_PR
                FROM MD_MM.SUBS_RABOTA_PM_MM a
               WHERE IDF_DOC = P_IDF_DOC );

        INSERT INTO S_ITF_SUBS_LSLED_MM( TMP_IDF_OBJ
                                        ,IDF_TPS
                                        ,SDATE_BEG
                                        ,SDATE_END
                                        ,KOD_SLED_OKDL
                                        ,STR_NOM_BEG
                                        ,STR_NOM_END
                                        ,OZN_TAKS
                                        ,NPP
                                        ,KOD_SLED )
            ( SELECT P_IDF_DOC
                    ,IDF_TPS
                    ,SDATE_BEG
                    ,SDATE_END
                    ,KOD_SLED_OKDL
                    ,STR_NOM_BEG
                    ,STR_NOM_END
                    ,OZN_TAKS
                    ,NPP
                    ,KOD_SLED
                FROM MD_MM.SUBS_LSLED_MM
               WHERE IDF_DOC = P_IDF_DOC );

        INSERT INTO S_ITF_SUBS_POIZD_MM( TMP_IDF_OBJ
                                        ,SDATE_BEG
                                        ,SDATE_END
                                        ,STR_NOM_BEG
                                        ,STR_NOM_END
                                        ,IDF_POIZD
                                        ,ESR_FORM
                                        ,ORD_NUM
                                        ,ESR_NAZN
                                        ,NOM_POK
                                        ,VID_RUXU
                                        ,ROD_P
                                        ,OSI
                                        ,VS_VAG
                                        ,NETTO
                                        ,BRUTTO )
            ( SELECT P_IDF_DOC
                    ,SDATE_BEG
                    ,SDATE_END
                    ,STR_NOM_BEG
                    ,STR_NOM_END
                    ,IDF_POIZD
                    ,ESR_FORM
                    ,ORD_NUM
                    ,ESR_NAZN
                    ,NOM_POK
                    ,VID_RUXU
                    ,ROD_P
                    ,OSI
                    ,VS_VAG
                    ,NETTO
                    ,BRUTTO
                FROM MD_MM.SUBS_POIZD_MM
               WHERE IDF_DOC = P_IDF_DOC );

        INSERT INTO S_ITF_SUBS_P_RPS_MM( TMP_IDF_OBJ
                                        ,NOM_POK
                                        ,STR_NOM_BEG
                                        ,STR_NOM_END
                                        ,SDATE_BEG
                                        ,SDATE_END
                                        ,KOD_RPS
                                        ,KOL_GR
                                        ,KOL_POR
                                        ,Z_TIP_PARKA )
            ( SELECT P_IDF_DOC
                    ,NOM_POK
                    ,STR_NOM_BEG
                    ,STR_NOM_END
                    ,SDATE_BEG
                    ,SDATE_END
                    ,KOD_RPS
                    ,KOL_GR
                    ,KOL_POR
                    ,Z_TIP_PARKA
                FROM MD_MM.SUBS_P_RPS_MM
               WHERE IDF_DOC = P_IDF_DOC );

        INSERT INTO S_ITF_SUBS_SOST_P_POIZD( TMP_IDF_OBJ
                                            ,TIP_PARKA
                                            ,ROD_VAG
                                            ,KOL_VAG
                                            ,PR_OSN
                                            ,PR_INV
                                            ,NOM_GR
                                            ,DOR_NAZN
                                            ,NOD_NAZN
                                            ,ST_SD_DOR
                                            ,ESR_NAZN
                                            ,KOD_ADM
                                            ,PR_ZN
                                            ,KOD_STAN_PARK )
            ( SELECT P_IDF_DOC
                    ,TIP_PARKA
                    ,ROD_VAG
                    ,KOL_VAG
                    ,PR_OSN
                    ,PR_INV
                    ,NOM_GR
                    ,DOR_NAZN
                    ,NOD_NAZN
                    ,ST_SD_DOR
                    ,ESR_NAZN
                    ,KOD_ADM
                    ,PR_ZN
                    ,KOD_STAN_PARK
                FROM MD_TRAIN.SUBS_SOST_P_POIZD
               WHERE IDF_ITOG = P_IDF_DOC );

        INSERT INTO S_ITF_SUBS_PRED_MM( TMP_IDF_OBJ
                                       ,IDF_PRED
                                       ,ESR_BEG
                                       ,KM_BEG
                                       ,PIKET_BEG
                                       ,ESR_END
                                       ,KM_END
                                       ,PIKET_END
                                       ,POSK
                                       ,PPR_ID )
            ( SELECT P_IDF_DOC
                    ,IDF_PRED
                    ,ESR_BEG
                    ,KM_BEG
                    ,PIKET_BEG
                    ,ESR_END
                    ,KM_END
                    ,PIKET_END
                    ,POSK
                    ,PPR_ID
                FROM MD_MM.SUBS_PRED_MM
               WHERE IDF_DOC = P_IDF_DOC );

        INSERT INTO S_ITF_SUBS_TPEREGON_MM( TMP_IDF_OBJ
                                           ,STR_NOM
                                           ,KOD_ELPL
                                           ,SDATE_BEG
                                           ,SDATE_END
                                           ,NOM_ELPL
                                           ,KOD_PEREG
                                           ,UCHASTOK
                                           ,PLECH_T
                                           ,PLECH_ZP
                                           ,KOD_DOR_PD
                                           ,KOD_OTD_PD
                                           ,DIST
                                           ,VR_FACT
                                           ,PROST_VH_SV
                                           ,PROST_PROH_SV
                                           ,KILK_PROH_SV
                                           ,CATEGOR_DIRTY
                                           ,PR_MOUNT
                                           ,PR_UZK_KOL
                                           ,IDF_PRED )
            ( SELECT P_IDF_DOC
                    ,STR_NOM
                    ,KOD_ELPL
                    ,SDATE_BEG
                    ,SDATE_END
                    ,NOM_ELPL
                    ,KOD_PEREG
                    ,UCHASTOK
                    ,PLECH_T
                    ,PLECH_ZP
                    ,KOD_DOR_PD
                    ,KOD_OTD_PD
                    ,DIST
                    ,VR_FACT
                    ,PROST_VH_SV
                    ,PROST_PROH_SV
                    ,KILK_PROH_SV
                    ,CATEGOR_DIRTY
                    ,PR_MOUNT
                    ,PR_UZK_KOL
                    ,IDF_PRED
                FROM MD_MM.SUBS_TPEREGON_MM a
               WHERE a.IDF_DOC = P_IDF_DOC );

        INSERT INTO S_ITF_SUBS_PER_SEC_MM( TMP_IDF_OBJ
                                          ,IDF_SEC
                                          ,DATE_ZAM
                                          ,OP_ZAM
                                          ,LICH_P
                                          ,LICH_ZM
                                          ,LICH_OP
                                          ,LICH_REC
                                          ,TOPL_L
                                          ,TOPL_KG
                                          ,MAS_L
                                          ,MAS_KG )
            ( SELECT P_IDF_DOC
                    ,a.IDF_SEC
                    ,a.DATE_ZAM
                    ,a.OP_ZAM
                    ,a.LICH_P
                    ,a.LICH_ZM
                    ,a.LICH_OP
                    ,a.LICH_REC
                    ,a.TOPL_L
                    ,a.TOPL_KG
                    ,a.MAS_L
                    ,a.MAS_KG
                FROM MD_MM.SUBS_PER_SEC_MM a
               WHERE a.IDF_PER_MM = P_IDF_DOC );

        S_WRITE_TO_MODELS.MARK_STATE_FOR_CHANGE( 'MM', 'DOC' );
        S_WRITE_TO_MODELS.MARK_STATE_FOR_CHANGE( 'MM', 'ZP_ALL_TAKS' );
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            MSG.EXITCODE   := 2;
            S_LOG_WORK.ADD_RECORD( S_CHANGEDOM_PROC.GETVALUE( 'IDF_EVENT' )
                                  ,SQLERRM );
        WHEN OTHERS
        THEN
            MSG.EXITCODE   := 2;
            S_LOG_WORK.ADD_RECORD( S_CHANGEDOM_PROC.GETVALUE( 'IDF_EVENT' )
                                  ,SQLERRM );
    END;

    PROCEDURE MSG_CANCEL( MSG IN OUT S_T_UZXDOC_MESSAGE )
    IS
    BEGIN
        MSG.EXITCODE   := 0;

        UPDATE S_ITF_MAIN_MM a
           SET ( a.IDF_OP, a.OPER_TYPE, a.IDF_MM )      = ( SELECT IDF_EMM
                                                                  ,S_WRITE_TO_MODELS.OP_CANCEL_OPER
                                                                  ,IDF_EMM
                                                              FROM S_TMP_EMM );

        S_WRITE_TO_MODELS.MARK_STATE_FOR_CHANGE( 'MM', 'DOC' );
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            MSG.EXITCODE   := 2;
            S_LOG_WORK.ADD_RECORD( S_CHANGEDOM_PROC.GETVALUE( 'IDF_EVENT' )
                                  ,SQLERRM );
        WHEN OTHERS
        THEN
            MSG.EXITCODE   := 2;
            S_LOG_WORK.ADD_RECORD( S_CHANGEDOM_PROC.GETVALUE( 'IDF_EVENT' )
                                  ,SQLERRM );
    END;

    PROCEDURE MSG_CLOSE( MSG IN OUT S_T_UZXDOC_MESSAGE )
    IS
    BEGIN
        MSG.EXITCODE   := 0;

        INSERT INTO S_ITF_MAIN_MM( TMP_IDF_OBJ
                                  ,IDF_MM
                                  ,DATE_OP
                                  ,DATA_SOURCE
                                  ,OPER_TYPE
                                  ,CODE_OP
                                  ,IDF_OP
                                  ,IDF_DOC
                                  ,IDF_TAKS
                                  ,BR_TIME_RAB
                                  ,NOM_MRM
                                  ,DEPO
                                  ,DATE_MM
                                  ,OTDYH
                                  ,JAVKA
                                  ,PRIEM
                                  ,DEPO_OUT
                                  ,DEPO_IN
                                  ,SD_LOK
                                  ,END_RAB
                                  ,DATE_CALC
                                  ,DEPO_PR_KOL
                                  ,KPZ
                                  ,NUM_COLUMN
                                  ,DATE_RAB
                                  ,KOD_KOL )
            ( SELECT a.IDF_OP
                    ,a.IDF_MM
                    ,B.DATE_CALC
                    ,1 DATA_SOURCE
                    ,S_WRITE_TO_MODELS.OP_CHANGE_OBJECT OPER_TYPE
                    ,54 CODE_OP
                    ,a.IDF_OP
                    ,a.IDF_DOC
                    ,a.IDF_TAKS
                    ,DECODE(
                             A.BR_TIME_RAB
                            ,NULL, CASE 
                                               WHEN   ( B.END_RAB - B.JAVKA )
                                                    * 1440 >= 1440
                                               THEN
                                                   NULL
                                               ELSE
                                                     ( B.END_RAB - B.JAVKA )
                                                   * 1440
                                   END
                            ,A.BR_TIME_RAB )
                    ,a.NOM_MRM
                    ,a.DEPO
                    ,a.DATE_MM
                    ,a.BR_TIME_RAB OTDYH
                    ,A.JAVKA
                    ,A.PRIEM
                    ,A.DEPO_OUT
                    ,A.DEPO_IN
                    ,A.SD_LOK
                    ,A.END_RAB
                    ,B.DATE_CALC
                    ,A.DEPO_PR_KOL
                    ,A.KPZ
                    ,a.NUM_COLUMN
                    ,a.DATE_RAB
                    ,a.KOD_KOL
                FROM S_SREZ_ACTUAL_MM a, S_V_ITF_MAIN_MM_MSG B
               WHERE     a.NOM_MRM = B.NOM_MRM
                     AND a.TYPE_MM = 1
                     AND a.DEPO = B.DEPO
                     AND a.DATE_MM = B.DATE_MM );

        S_WRITE_TO_MODELS.MARK_STATE_FOR_CHANGE( 'MM', 'ZP_ALL_TAKS' );
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            MSG.EXITCODE   := 2;
            S_LOG_WORK.ADD_RECORD( S_CHANGEDOM_PROC.GETVALUE( 'IDF_EVENT' )
                                  ,SQLERRM );
        WHEN OTHERS
        THEN
            MSG.EXITCODE   := 2;
            S_LOG_WORK.ADD_RECORD( S_CHANGEDOM_PROC.GETVALUE( 'IDF_EVENT' )
                                  ,SQLERRM );
    END;
END EMM_TCHU;
/