CREATE OR REPLACE PACKAGE BODY APPL_PKG.MSG_LM012
AS
    UZXDOC_BLANK   VARCHAR2( 1000 )
        :=    '<?xml version="1.0" encoding="windows-1251"?>'
           || '<UZ-XDOC schema="uzvp" doc_version="1.0" doc_type="reply">'
           || '<HEAD messcode="0497" from="change" password="tiger"></HEAD>'
           || '<BODY></BODY>'
           || '</UZ-XDOC>';

    PROCEDURE Main( MSG IN OUT S_T_UZXDOC_MESSAGE )
    IS
        KPZ             VARCHAR2( 4 );
        KOD_DOR_        VARCHAR2( 2 );
        DEPO_PR_        VARCHAR2( 4 );
        NOM_MM_         VARCHAR2( 7 );
        DATE_MM_        VARCHAR2( 20 );
        P_TIME_YAVKA    VARCHAR2( 20 );
        P_END_RAB       VARCHAR2( 20 );
        P_DATE_MM_OTD   VARCHAR2( 20 );
        P_CODE_OP       VARCHAR2( 4 );
        M_TEXT          VARCHAR2( 1000 );
        IDF_EVENT_      NUMBER;
        CNT_SOURCE_5    NUMBER;
        KOL7728         NUMBER;
        P_KOD_MESS      VARCHAR2( 25 );
        P_PR_POEZDKY    NUMBER;
        X_IDF_EMM       APPL_DBW.S_TMP_EMM.OZN_EMM%TYPE;
        X_SUBTYPE       S_ITF_KEY_MSG.subtype%TYPE;
        X_OZN_EMM       APPL_DBW.S_TMP_EMM.OZN_EMM%TYPE;
    BEGIN
        DBMS_OUTPUT.put_line( 'Старт Msg_Lm024' );


        Msg_Lm012.FORM_LM012( MSG );

        M_TEXT   := 'формируем  регламент (LM024)';
        S_LOG_WORK.ADD_RECORD( S_E_SERVICE.IDF_EVENT, M_TEXT ); --event.service



        /* для потока */

        --   s_changedom_proc.SetValue('OUT_DOCTYPE', 'LM024');
        --   s_changedom_proc.SetValue('REGL_DOCTYPE','LM024');
        --   s_changedom_proc.SetValue('RETFMT','XML');
        --   s_changedom_proc.SetValue('SEND_ONE','1');


        /*  для отладочного сервера  - начало   */

        --закоментил я

        /* IF msg.OutgoingXML IS NULL
         THEN
             DBMS_OUTPUT.put_line( 'OutgoingXML IS NULL' );

             DBMS_LOB.CREATETEMPORARY( msg.OutgoingXML, TRUE );
             DBMS_LOB.OPEN( msg.OutgoingXML, DBMS_LOB.lob_readwrite );
             DBMS_LOB.TRIM( msg.OutgoingXML, 0 );
         END IF;

         msg.OutgoingDOM.writeToCLOB( msg.OutgoingXML );    -- ?? ???? ? ??????
         DBMS_OUTPUT.put_line( 'Finish  writeToCLOB' );


         s_Msg_Event.Reg_Mess_End( msg );   */
        -- ??????????? ?????????



        ---dbms_output.put_line('Finish  Reg_Mess_End');

        --s_Uvp_Queue.PutMes('(11 3305 5)02','(11 7777 7)51',msg.outgoingxml,SYSDATE,12,0,0);  --тправить запрос явно
        DBMS_OUTPUT.put_line( 'Finish Msg_Lm024' );
    END;

    PROCEDURE FORM_LM012( MSG IN OUT S_T_UZXDOC_MESSAGE )
    IS
        M_DOM_OUT       XDB.DBMS_XMLDOM.domdocument;
        TAGBODY         XDB.DBMS_XMLDOM.domnode;
        TAGINFBODY      XDB.DBMS_XMLDOM.domnode;
        TAGINFBODY1     XDB.DBMS_XMLDOM.domnode;
        TAGINFBODY2     XDB.DBMS_XMLDOM.domnode;
        TAGINFBODYLOK   XDB.DBMS_XMLDOM.domnode;
        TAGINFBODYSEC   XDB.DBMS_XMLDOM.domnode;

        TAGNUMBERM      XDB.DBMS_XMLDOM.domelement;
        TAGR1           XDB.DBMS_XMLDOM.domelement;
        TAGR2           XDB.DBMS_XMLDOM.domelement;
        TAGATTR2        XDB.DBMS_XMLDOM.domelement;
        TAGR3           XDB.DBMS_XMLDOM.domelement;
        TAGR4           XDB.DBMS_XMLDOM.domelement;
        TAGR6           XDB.DBMS_XMLDOM.domelement;
        TAGR7           XDB.DBMS_XMLDOM.domelement;
        TAGR8           XDB.DBMS_XMLDOM.domelement;
        TAGRTAKSUV      XDB.DBMS_XMLDOM.domelement;
        TAGRTAKSUV_R7   XDB.DBMS_XMLDOM.domelement;
        TAGATTRSEC      XDB.DBMS_XMLDOM.domelement;
        STR_ERR         VARCHAR2( 255 );

        P_SUBTYPE       VARCHAR2( 25 );
        P_KOD_MESS      VARCHAR2( 25 );
        P_STATUS_260    NUMBER;
        X_COUNT         NUMBER;
        X_COUNT1        NUMBER;
        KOL             NUMBER;
        -----------------------------------------
        TBL_MAIN        S_ITF_MAIN_MM%ROWTYPE;
        A_IDF_MM        S_ITF_MAIN_MM.IDF_MM%TYPE;
        NOM             S_NUMBERM.NOMMAR%TYPE;
    BEGIN
        MSG.EXITCODE    := 0;

        DBMS_OUTPUT.put_line( 'Start Msg_Lm012.Form_Lm012' );
        S_LOG_WORK.ADD_RECORD( S_CHANGEDOM_PROC.GETVALUE( MSG, 'IDF_EVENT' )
                              ,'Start Regl_Form_Lm024: ' || SYSDATE );

        SELECT KOD_MESS INTO P_KOD_MESS FROM S_ITF_KEY_MSG;
        SELECT SUBTYPE INTO P_SUBTYPE FROM S_ITF_KEY_MSG;

        --P_SUBTYPE       := 'normal';
        DBMS_OUTPUT.put_line( 'subtype=' || P_SUBTYPE );
        DBMS_OUTPUT.put_line( 'p_kod_mess=' || P_KOD_MESS );

        SELECT IDF_MM
          INTO A_IDF_MM
          FROM S_ITF_MAIN_MM
         WHERE DATA_SOURCE = 0;

        M_DOM_OUT       := XDB.DBMS_XMLDOM.newdomdocument;
        M_DOM_OUT.ID    := MSG.OUTGOINGDOM.ID;


        TAGBODY         := XDB.DBMS_XSLPROCESSOR.selectSingleNode(
                                                                   XDB.DBMS_XMLDOM.makenode(
                                                                                             M_DOM_OUT )
                                                                  ,'UZ-XDOC'
                                                                  ,STR_ERR );
        XDB.DBMS_XMLDOM.setAttribute( XDB.DBMS_XMLDOM.MAKEELEMENT( TAGBODY )
                                     ,'subtype'
                                     ,P_SUBTYPE
                                     ,STR_ERR );

        TAGBODY         := XDB.DBMS_XSLPROCESSOR.selectSingleNode(
                                                                   XDB.DBMS_XMLDOM.makenode(
                                                                                             M_DOM_OUT )
                                                                  ,'UZ-XDOC/@doc_type'
                                                                  ,STR_ERR );
        XDB.DBMS_XMLDOM.setNodeValue( TAGBODY, 'data' );

        TAGBODY         := XDB.DBMS_XSLPROCESSOR.selectSingleNode(
                                                                   XDB.DBMS_XMLDOM.makenode(
                                                                                             M_DOM_OUT )
                                                                  ,'UZ-XDOC/HEAD/@messcode'
                                                                  ,STR_ERR );
        XDB.DBMS_XMLDOM.setNodeValue( TAGBODY, 'LM024' );
        TAGBODY         := XDB.DBMS_XSLPROCESSOR.selectSingleNode(
                                                                   XDB.DBMS_XMLDOM.makenode(
                                                                                             M_DOM_OUT )
                                                                  ,'UZ-XDOC/BODY'
                                                                  ,STR_ERR );
        TAGNUMBERM      := XDB.DBMS_XMLDOM.createElement( M_DOM_OUT
                                                         ,'NUMBERM' );

        SELECT COUNT( * )
          INTO KOL
          FROM S_NUMBERM_
         WHERE NOMMAR_ID = A_IDF_MM;
         begin
         SELECT NOMMAR
          INTO NOM
          FROM S_NUMBERM_
         WHERE NOMMAR_ID = A_IDF_MM;
         EXCEPTION
        WHEN OTHERS
        THEN
           NOM:=null;
         end;

        IF ( KOL > 0 )
        THEN
            FOR J IN ( SELECT *
                         FROM S_NUMBERM_
                        WHERE NOMMAR_ID = A_IDF_MM )
            LOOP
                XDB.DBMS_XMLDOM.setAttribute( TAGNUMBERM
                                             ,'Nommar_id'
                                             ,''
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGNUMBERM
                                             ,'NOMMAR'
                                             ,J.NOMMAR
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute(
                                              TAGNUMBERM
                                             ,'DATEMOD'
                                             ,TO_CHAR( J.DATEMOD
                                                      ,'dd.mm.yyyy' )
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGNUMBERM
                                             ,'CLEANPASS'
                                             ,J.CLEANPASS
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGNUMBERM
                                             ,'LNKNEXT'
                                             ,J.LNKNEXT
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGNUMBERM
                                             ,'Sform'
                                             ,J.SFORM
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGNUMBERM
                                             ,'TAKSUV'
                                             ,J.TAKSUV
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGNUMBERM
                                             ,'BEDMAK'
                                             ,J.BEDMAK
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGNUMBERM
                                             ,'PRUJN'
                                             ,J.PRUJN
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGNUMBERM
                                             ,'PERED'
                                             ,J.PERED
                                             ,STR_ERR );
                                             XDB.DBMS_XMLDOM.setAttribute(
                                              TAGNUMBERM
                                             ,'DATE_DOCUM'
                                             ,TO_CHAR( J.DATE_DOCUM
                                                      ,'dd.mm.yyyy' )
                                             ,STR_ERR );
            END LOOP;
        ELSE
            XDB.DBMS_XMLDOM.setAttribute( TAGNUMBERM
                                         ,'Nommar_id'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGNUMBERM
                                         ,'NOMMAR'
                                         ,NOM
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGNUMBERM
                                         ,'DATEMOD'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGNUMBERM
                                         ,'CLEANPASS'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGNUMBERM
                                         ,'LNKNEXT'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGNUMBERM
                                         ,'Sform'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGNUMBERM
                                         ,'TAKSUV'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGNUMBERM
                                         ,'BEDMAK'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGNUMBERM
                                         ,'PRUJN'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGNUMBERM
                                         ,'PERED'
                                         ,''
                                         ,STR_ERR );
        END IF;

        TAGBODY         := XDB.DBMS_XMLDOM.AppendChild(
                                                        TAGBODY
                                                       ,XDB.DBMS_XMLDOM.makenode(
                                                                                  TAGNUMBERM ) );

        SELECT COUNT( * )
          INTO KOL
          FROM S_R1_BASE
         WHERE NOMMAR_ID = A_IDF_MM;

        IF ( KOL > 0 )
        THEN
            FOR J IN ( SELECT *
                         FROM S_R1_BASE
                        WHERE NOMMAR_ID = A_IDF_MM )
            LOOP
                TAGINFBODY      := XDB.DBMS_XSLPROCESSOR.selectSingleNode(
                                                                           XDB.DBMS_XMLDOM.makenode(
                                                                                                     M_DOM_OUT )
                                                                          ,'UZ-XDOC/BODY'
                                                                          ,STR_ERR );
                TAGR1           := XDB.DBMS_XMLDOM.createElement( M_DOM_OUT
                                                                 ,'R1_BASE' );

                DBMS_OUTPUT.put_line( 'R1_BASE' );
                XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                             ,'Nommar_id'
                                             ,''
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                             ,'NOMMAR'
                                             ,J.NOMMAR
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                             ,'KODDDPPR'
                                             ,J.KODDDPPR
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                             ,'KODPRLOK'
                                             ,J.KODPRLOK
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                             ,'KODSERLOK'
                                             ,J.KODSERLOK
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                             ,'NOMLOK1'
                                             ,J.NOMLOK1
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                             ,'DATA'
                                             ,TO_CHAR( J.DATA, 'dd.mm.yyyy' )
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                             ,'TABNOMMASH'
                                             ,J.TABNOMMASH
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                             ,'FAMMASH'
                                             ,J.FAMMASH
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                             ,'POSPRMASH'
                                             ,J.POSPRMASH
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                             ,'TABNOMPOM'
                                             ,J.TABNOMPOM
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                             ,'FAMPOM'
                                             ,J.FAMPOM
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                             ,'POSPRPOM'
                                             ,J.POSPRPOM
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                             ,'TABNOM3'
                                             ,J.TABNOM3
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                             ,'FAM3'
                                             ,J.FAM3
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                             ,'POSPR3'
                                             ,J.POSPR3
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                             ,'KODDDP_MASH'
                                             ,J.KODDDP_MASH
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                             ,'KODDDP_POM'
                                             ,J.KODDDP_POM
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                             ,'KODDDP_POS3'
                                             ,J.KODDDP_POS3
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                             ,'KODDDP_POS4'
                                             ,J.KODDDP_POS4
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                             ,'TABNOM4'
                                             ,J.TABNOM4
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                             ,'FAM4'
                                             ,J.FAM4
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                             ,'POSPR4'
                                             ,J.POSPR4
                                             ,STR_ERR );


                TAGBODY         := XDB.DBMS_XMLDOM.AppendChild(
                                                                TAGINFBODY
                                                               ,XDB.DBMS_XMLDOM.makenode(
                                                                                          TAGR1 ) );
            END LOOP;
        ELSE
            TAGINFBODY      := XDB.DBMS_XSLPROCESSOR.selectSingleNode(
                                                                       XDB.DBMS_XMLDOM.makenode(
                                                                                                 M_DOM_OUT )
                                                                      ,'UZ-XDOC/BODY'
                                                                      ,STR_ERR );
            TAGR1           := XDB.DBMS_XMLDOM.createElement( M_DOM_OUT
                                                             ,'R1_BASE' );

            DBMS_OUTPUT.put_line( 'R1_BASE' );
            XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                         ,'Nommar_id'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                         ,'NOMMAR'
                                         ,NOM
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                         ,'KODDDPPR'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                         ,'KODPRLOK'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                         ,'KODSERLOK'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                         ,'NOMLOK1'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                         ,'DATA'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                         ,'TABNOMMASH'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                         ,'FAMMASH'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                         ,'POSPRMASH'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                         ,'TABNOMPOM'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                         ,'FAMPOM'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                         ,'POSPRPOM'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                         ,'TABNOM3'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                         ,'FAM3'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                         ,'POSPR3'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                         ,'KODDDP_MASH'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                         ,'KODDDP_POM'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                         ,'KODDDP_POS3'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                         ,'KODDDP_POS4'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                         ,'TABNOM4'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                         ,'FAM4'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR1
                                         ,'POSPR4'
                                         ,''
                                         ,STR_ERR );


            TAGBODY         := XDB.DBMS_XMLDOM.AppendChild(
                                                            TAGINFBODY
                                                           ,XDB.DBMS_XMLDOM.makenode(
                                                                                      TAGR1 ) );
        END IF;

        SELECT COUNT( * )
          INTO KOL
          FROM S_R2_BASE
         WHERE NOMMAR_ID = A_IDF_MM;

        IF ( KOL > 0 )
        THEN
            FOR J IN ( SELECT *
                         FROM S_R2_BASE
                        WHERE NOMMAR_ID = A_IDF_MM )
            LOOP
                TAGINFBODY1      := XDB.DBMS_XSLPROCESSOR.selectSingleNode(
                                                                            XDB.DBMS_XMLDOM.makenode(
                                                                                                      M_DOM_OUT )
                                                                           ,'UZ-XDOC/BODY'
                                                                           ,STR_ERR );
                TAGR2            := XDB.DBMS_XMLDOM.createElement(
                                                                   M_DOM_OUT
                                                                  ,'R2_BASE' );

                DBMS_OUTPUT.put_line( 'R2_BASE' );
                XDB.DBMS_XMLDOM.setAttribute( TAGR2
                                             ,'Nommar_id'
                                             ,''
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR2
                                             ,'NOMMAR'
                                             ,J.NOMMAR
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute(
                                              TAGR2
                                             ,'HOUROUT'
                                             ,TO_CHAR( J.HOUROUT
                                                      ,'dd.mm.yyyy hh24:mi' )
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute(
                                              TAGR2
                                             ,'HOURIN'
                                             ,TO_CHAR( J.HOURIN
                                                      ,'dd.mm.yyyy hh24:mi' )
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR2
                                             ,'KODDRAFT'
                                             ,J.KODDRAFT
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR2
                                             ,'KODDRIVE'
                                             ,J.KODDRIVE
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR2
                                             ,'SERIES'
                                             ,J.SERIES
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR2
                                             ,'STOUT'
                                             ,J.STOUT
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR2
                                             ,'STIN'
                                             ,J.STIN
                                             ,STR_ERR );
                                             XDB.DBMS_XMLDOM.setAttribute( TAGR2
                                             ,'NAPRJAM'
                                             ,J.NAPRJAM
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR2
                                             ,'NOMROW'
                                             ,J.NOMROW
                                             ,STR_ERR );
                TAGBODY          := XDB.DBMS_XMLDOM.AppendChild(
                                                                 TAGINFBODY
                                                                ,XDB.DBMS_XMLDOM.makenode(
                                                                                           TAGR2 ) );
            END LOOP;
        ELSE
            TAGINFBODY1      := XDB.DBMS_XSLPROCESSOR.selectSingleNode(
                                                                        XDB.DBMS_XMLDOM.makenode(
                                                                                                  M_DOM_OUT )
                                                                       ,'UZ-XDOC/BODY'
                                                                       ,STR_ERR );
            TAGR2            := XDB.DBMS_XMLDOM.createElement( M_DOM_OUT
                                                              ,'R2_BASE' );

            DBMS_OUTPUT.put_line( 'R2_BASE' );
            XDB.DBMS_XMLDOM.setAttribute( TAGR2
                                         ,'Nommar_id'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR2
                                         ,'NOMMAR'
                                         ,NOM
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR2
                                         ,'HOUROUT'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR2
                                         ,'HOURIN'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR2
                                         ,'KODDRAFT'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR2
                                         ,'KODDRIVE'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR2
                                         ,'SERIES'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR2
                                         ,'STOUT'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR2
                                         ,'STIN'
                                         ,''
                                         ,STR_ERR );
                                         XDB.DBMS_XMLDOM.setAttribute( TAGR2
                                             ,'NAPRJAM'
                                             ,''
                                             ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR2
                                         ,'NOMROW'
                                         ,''
                                         ,STR_ERR );
            TAGBODY          := XDB.DBMS_XMLDOM.AppendChild(
                                                             TAGINFBODY
                                                            ,XDB.DBMS_XMLDOM.makenode(
                                                                                       TAGR2 ) );
        END IF;

        SELECT COUNT( * )
          INTO KOL
          FROM S_R3_BASE
         WHERE NOMMAR_ID = A_IDF_MM;

        IF ( KOL > 0 )
        THEN
            FOR J IN ( SELECT *
                         FROM S_R3_BASE
                        WHERE NOMMAR_ID = A_IDF_MM )
            LOOP
                TAGINFBODY2      := XDB.DBMS_XSLPROCESSOR.selectSingleNode(
                                                                            XDB.DBMS_XMLDOM.makenode(
                                                                                                      M_DOM_OUT )
                                                                           ,'UZ-XDOC/BODY'
                                                                           ,STR_ERR );
                TAGR3            := XDB.DBMS_XMLDOM.createElement(
                                                                   M_DOM_OUT
                                                                  ,'R3_BASE' );

                DBMS_OUTPUT.put_line( 'R3_BASE' );
                --tagattr := s_Xmldocumentcover.createElement(UzxdocMsg.outgoingDOM.id,'LOK');
                XDB.DBMS_XMLDOM.setAttribute( TAGR3
                                             ,'Nommar_id'
                                             ,''
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR3
                                             ,'NOMMAR'
                                             ,J.NOMMAR
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR3
                                             ,'JAVKA'
                                             ,J.JAVKA
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR3
                                             ,'PRUJOMLOK'
                                             ,J.PRUJOMLOK
                                             ,STR_ERR );

                XDB.DBMS_XMLDOM.setAttribute( TAGR3
                                             ,'KPOUT'
                                             ,J.KPOUT
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR3
                                             ,'KPIN'
                                             ,J.KPIN
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR3
                                             ,'ZDACHALOK'
                                             ,J.ZDACHALOK
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR3
                                             ,'ENDWORK'
                                             ,J.ENDWORK
                                             ,STR_ERR );

                XDB.DBMS_XMLDOM.setAttribute( TAGR3
                                             ,'PEREVID'
                                             ,J.PEREVID
                                             ,STR_ERR );


                TAGBODY          := XDB.DBMS_XMLDOM.AppendChild(
                                                                 TAGINFBODY
                                                                ,XDB.DBMS_XMLDOM.makenode(
                                                                                           TAGR3 ) );
            END LOOP;
        ELSE
            TAGINFBODY2      := XDB.DBMS_XSLPROCESSOR.selectSingleNode(
                                                                        XDB.DBMS_XMLDOM.makenode(
                                                                                                  M_DOM_OUT )
                                                                       ,'UZ-XDOC/BODY'
                                                                       ,STR_ERR );
            TAGR3            := XDB.DBMS_XMLDOM.createElement( M_DOM_OUT
                                                              ,'R3_BASE' );

            DBMS_OUTPUT.put_line( 'R3_BASE' );
            --tagattr := s_Xmldocumentcover.createElement(UzxdocMsg.outgoingDOM.id,'LOK');
            XDB.DBMS_XMLDOM.setAttribute( TAGR3
                                         ,'Nommar_id'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR3
                                         ,'NOMMAR'
                                         ,NOM
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR3
                                         ,'JAVKA'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR3
                                         ,'PRUJOMLOK'
                                         ,''
                                         ,STR_ERR );

            XDB.DBMS_XMLDOM.setAttribute( TAGR3
                                         ,'KPOUT'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR3
                                         ,'KPIN'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR3
                                         ,'ZDACHALOK'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR3
                                         ,'ENDWORK'
                                         ,''
                                         ,STR_ERR );

            XDB.DBMS_XMLDOM.setAttribute( TAGR3
                                         ,'PEREVID'
                                         ,''
                                         ,STR_ERR );


            TAGBODY          := XDB.DBMS_XMLDOM.AppendChild(
                                                             TAGINFBODY
                                                            ,XDB.DBMS_XMLDOM.makenode(
                                                                                       TAGR3 ) );
        END IF;

        SELECT COUNT( * )
          INTO KOL
          FROM S_R4_BASE
         WHERE NOMMAR_ID = A_IDF_MM;

        IF ( KOL > 0 )
        THEN
            FOR J IN ( SELECT *
                         FROM S_R4_BASE
                        WHERE NOMMAR_ID = A_IDF_MM )
            LOOP
                TAGINFBODY1      := XDB.DBMS_XSLPROCESSOR.selectSingleNode(
                                                                            XDB.DBMS_XMLDOM.makenode(
                                                                                                      M_DOM_OUT )
                                                                           ,'UZ-XDOC/BODY'
                                                                           ,STR_ERR );
                TAGR4            := XDB.DBMS_XMLDOM.createElement(
                                                                   M_DOM_OUT
                                                                  ,'R4_BASE' );

                DBMS_OUTPUT.put_line( 'R4_BASE' );
                XDB.DBMS_XMLDOM.setAttribute( TAGR4
                                             ,'Nommar_id'
                                             ,''
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR4
                                             ,'NOMMAR'
                                             ,J.NOMMAR
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR4
                                             ,'kodslid'
                                             ,J.KODSLID
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR4
                                             ,'koddordep'
                                             ,J.KODDORDEP
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR4
                                             ,'kodserlok'
                                             ,J.KODSERLOK
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR4
                                             ,'nomlok'
                                             ,J.NOMLOK
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR4
                                             ,'kodsect'
                                             ,J.KODSECT
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR4
                                             ,'begslid'
                                             ,J.BEGSLID
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR4
                                             ,'endslid'
                                             ,J.ENDSLID
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR4
                                             ,'bezbrdate'
                                             ,J.BEZBRDATE
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR4
                                             ,'bezbrhour'
                                             ,J.BEZBRHOUR
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR4
                                             ,'nomrow'
                                             ,J.NOMROW
                                             ,STR_ERR );
                TAGBODY          := XDB.DBMS_XMLDOM.AppendChild(
                                                                 TAGINFBODY
                                                                ,XDB.DBMS_XMLDOM.makenode(
                                                                                           TAGR4 ) );
            END LOOP;
        ELSE
            TAGINFBODY1      := XDB.DBMS_XSLPROCESSOR.selectSingleNode(
                                                                        XDB.DBMS_XMLDOM.makenode(
                                                                                                  M_DOM_OUT )
                                                                       ,'UZ-XDOC/BODY'
                                                                       ,STR_ERR );
            TAGR4            := XDB.DBMS_XMLDOM.createElement( M_DOM_OUT
                                                              ,'R4_BASE' );

            DBMS_OUTPUT.put_line( 'R4_BASE' );
            XDB.DBMS_XMLDOM.setAttribute( TAGR4
                                         ,'Nommar_id'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR4
                                         ,'NOMMAR'
                                         ,NOM
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR4
                                         ,'kodslid'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR4
                                         ,'koddordep'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR4
                                         ,'kodserlok'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR4
                                         ,'nomlok'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR4
                                         ,'kodsect'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR4
                                         ,'begslid'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR4
                                         ,'endslid'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR4
                                         ,'bezbrdate'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR4
                                         ,'bezbrhour'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR4
                                         ,'nomrow'
                                         ,''
                                         ,STR_ERR );
            TAGBODY          := XDB.DBMS_XMLDOM.AppendChild(
                                                             TAGINFBODY
                                                            ,XDB.DBMS_XMLDOM.makenode(
                                                                                       TAGR4 ) );
        END IF;

        SELECT COUNT( * )
          INTO KOL
          FROM S_R6_BASE
         WHERE NOMMAR_ID = A_IDF_MM;

        IF ( KOL > 0 )
        THEN
            FOR J IN ( SELECT *
                         FROM S_R6_BASE
                        WHERE NOMMAR_ID = A_IDF_MM )
            LOOP
                TAGINFBODY1      := XDB.DBMS_XSLPROCESSOR.selectSingleNode(
                                                                            XDB.DBMS_XMLDOM.makenode(
                                                                                                      M_DOM_OUT )
                                                                           ,'UZ-XDOC/BODY'
                                                                           ,STR_ERR );
                TAGR6            := XDB.DBMS_XMLDOM.createElement(
                                                                   M_DOM_OUT
                                                                  ,'R6_BASE' );

                DBMS_OUTPUT.put_line( 'R6_BASE' );
                XDB.DBMS_XMLDOM.setAttribute( TAGR6
                                             ,'Nommar_id'
                                             ,''
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR6
                                             ,'NOMMAR'
                                             ,J.NOMMAR
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR6
                                             ,'kodprym'
                                             ,J.KODPRYM
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR6
                                             ,'prymit'
                                             ,J.PRYMIT
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR6
                                             ,'addpr1'
                                             ,J.ADDPR1
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR6
                                             ,'addpr2'
                                             ,J.ADDPR2
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR6
                                             ,'addpr3'
                                             ,J.ADDPR3
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR6
                                             ,'nomrow'
                                             ,J.NOMROW
                                             ,STR_ERR );
                TAGBODY          := XDB.DBMS_XMLDOM.AppendChild(
                                                                 TAGINFBODY
                                                                ,XDB.DBMS_XMLDOM.makenode(
                                                                                           TAGR6 ) );
            END LOOP;
        ELSE
            TAGINFBODY1      := XDB.DBMS_XSLPROCESSOR.selectSingleNode(
                                                                        XDB.DBMS_XMLDOM.makenode(
                                                                                                  M_DOM_OUT )
                                                                       ,'UZ-XDOC/BODY'
                                                                       ,STR_ERR );
            TAGR6            := XDB.DBMS_XMLDOM.createElement( M_DOM_OUT
                                                              ,'R6_BASE' );

            DBMS_OUTPUT.put_line( 'R6_BASE' );
            XDB.DBMS_XMLDOM.setAttribute( TAGR6
                                         ,'Nommar_id'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR6
                                         ,'NOMMAR'
                                         ,NOM
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR6
                                         ,'kodprym'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR6
                                         ,'prymit'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR6
                                         ,'addpr1'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR6
                                         ,'addpr2'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR6
                                         ,'addpr3'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR6
                                         ,'nomrow'
                                         ,''
                                         ,STR_ERR );
            TAGBODY          := XDB.DBMS_XMLDOM.AppendChild(
                                                             TAGINFBODY
                                                            ,XDB.DBMS_XMLDOM.makenode(
                                                                                       TAGR6 ) );
        END IF;

        SELECT COUNT( * )
          INTO KOL
          FROM S_R7_BASE
         WHERE NOMMAR_ID = A_IDF_MM;

        IF ( KOL > 0 )
        THEN
            FOR J IN ( SELECT *
                         FROM S_R7_BASE
                        WHERE NOMMAR_ID = A_IDF_MM )
            LOOP
                TAGINFBODY1      := XDB.DBMS_XSLPROCESSOR.selectSingleNode(
                                                                            XDB.DBMS_XMLDOM.makenode(
                                                                                                      M_DOM_OUT )
                                                                           ,'UZ-XDOC/BODY'
                                                                           ,STR_ERR );
                TAGR7            := XDB.DBMS_XMLDOM.createElement(
                                                                   M_DOM_OUT
                                                                  ,'R7_BASE' );

                DBMS_OUTPUT.put_line( 'R7_BASE' );
                XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                             ,'Nommar_id'
                                             ,''
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                             ,'NOMMAR'
                                             ,J.NOMMAR
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                             ,'robota'
                                             ,J.ROBOTA
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                             ,'nomrow'
                                             ,J.NOMROW
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                             ,'kodst'
                                             ,J.KODST
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                             ,'namest'
                                             ,J.NAMEST
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                             ,'prpryb'
                                             ,J.PRPRYB
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                             ,'prvidpr'
                                             ,J.PRVIDPR
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                             ,'prmanevr'
                                             ,J.PRMANEVR
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                             ,'prprost'
                                             ,J.PRPROST
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                             ,'prnomtr'
                                             ,J.PRNOMTR
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                             ,'prkindwr'
                                             ,J.PRKINDWR
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                             ,'weightnet'
                                             ,J.WEIGHTNET
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                             ,'weightbryt'
                                             ,J.WEIGHTBRYT
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                             ,'kilkosey'
                                             ,J.KILKOSEY
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                             ,'nagon'
                                             ,J.NAGON
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                             ,'kilvag'
                                             ,J.KILVAG
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                             ,'ktydinner'
                                             ,J.KTYDINNER
                                             ,STR_ERR );
                TAGBODY          := XDB.DBMS_XMLDOM.AppendChild(
                                                                 TAGINFBODY
                                                                ,XDB.DBMS_XMLDOM.makenode(
                                                                                           TAGR7 ) );
            END LOOP;
        ELSE
            TAGINFBODY1      := XDB.DBMS_XSLPROCESSOR.selectSingleNode(
                                                                        XDB.DBMS_XMLDOM.makenode(
                                                                                                  M_DOM_OUT )
                                                                       ,'UZ-XDOC/BODY'
                                                                       ,STR_ERR );
            TAGR7            := XDB.DBMS_XMLDOM.createElement( M_DOM_OUT
                                                              ,'R7_BASE' );

            DBMS_OUTPUT.put_line( 'R7_BASE' );
            XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                         ,'Nommar_id'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                         ,'NOMMAR'
                                         ,NOM
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                         ,'robota'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                         ,'nomrow'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                         ,'kodst'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                         ,'namest'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                         ,'prpryb'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                         ,'prvidpr'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                         ,'prmanevr'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                         ,'prprost'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                         ,'prnomtr'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                         ,'prkindwr'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                         ,'weightnet'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                         ,'weightbryt'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                         ,'kilkosey'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                         ,'nagon'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                         ,'kilvag'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR7
                                         ,'ktydinner'
                                         ,''
                                         ,STR_ERR );
            TAGBODY          := XDB.DBMS_XMLDOM.AppendChild(
                                                             TAGINFBODY
                                                            ,XDB.DBMS_XMLDOM.makenode(
                                                                                       TAGR7 ) );
        END IF;

        SELECT COUNT( * )
          INTO KOL
          FROM S_TAKSUV_R7
         WHERE NOMMAR_ID = A_IDF_MM;

        IF ( KOL > 0 )
        THEN
            FOR J IN ( SELECT *
                         FROM S_TAKSUV_R7
                        WHERE NOMMAR_ID = A_IDF_MM order by NOMROW asc)
            LOOP
                TAGINFBODY1        := XDB.DBMS_XSLPROCESSOR.selectSingleNode(
                                                                              XDB.DBMS_XMLDOM.makenode(
                                                                                                        M_DOM_OUT )
                                                                             ,'UZ-XDOC/BODY'
                                                                             ,STR_ERR );
                TAGRTAKSUV_R7      := XDB.DBMS_XMLDOM.createElement(
                                                                     M_DOM_OUT
                                                                    ,'TAKSUV_R7' );

                DBMS_OUTPUT.put_line( 'TAKSUV_R7' );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                             ,'Nommar_id'
                                             ,''
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                             ,'NOMMAR'
                                             ,J.NOMMAR
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                             ,'nomrow'
                                             ,J.NOMROW
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                             ,'timeout'
                                             ,J.timeout
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                             ,'timein'
                                             ,J.TIMEIN
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                             ,'koddor'
                                             ,J.KODDOR
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                             ,'kodst'
                                             ,J.KODST
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                             ,'nomtrain'
                                             ,J.NOMTRAIN
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                             ,'kodwork'
                                             ,J.KODWORK
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                             ,'kodpd'
                                             ,J.KODPD
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                             ,'lindist_r7'
                                             ,J.LINDIST_R7
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                             ,'wnetto'
                                             ,J.WNETTO
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                             ,'wbrutto'
                                             ,J.WBRUTTO
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                             ,'facttime_r7'
                                             ,J.FACTTIME_R7
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                             ,'przminabrgst_r7'
                                             ,J.PRZMINABRGST_R7
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                             ,'kolvantvag'
                                             ,J.KOLVANTVAG
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                             ,'kolporvag'
                                             ,J.KOLPORVAG
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                             ,'prst_r7'
                                             ,J.PRST_R7
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                             ,'manst_r7'
                                             ,J.MANST_R7
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                             ,'nagin'
                                             ,J.NAGIN
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                             ,'workman'
                                             ,J.WORKMAN
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                             ,'kilkosey'
                                             ,J.KILKOSEY
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                             ,'kilvag'
                                             ,J.KILVAG
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                             ,'kodserlok'
                                             ,J.KODSERLOK
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                             ,'nomlok'
                                             ,J.NOMLOK
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                             ,'robota'
                                             ,J.ROBOTA
                                             ,STR_ERR );
                TAGBODY            := XDB.DBMS_XMLDOM.AppendChild(
                                                                   TAGINFBODY
                                                                  ,XDB.DBMS_XMLDOM.makenode(
                                                                                             TAGRTAKSUV_R7 ) );
            END LOOP;
        ELSE
            TAGINFBODY1        := XDB.DBMS_XSLPROCESSOR.selectSingleNode(
                                                                          XDB.DBMS_XMLDOM.makenode(
                                                                                                    M_DOM_OUT )
                                                                         ,'UZ-XDOC/BODY'
                                                                         ,STR_ERR );
            TAGRTAKSUV_R7      := XDB.DBMS_XMLDOM.createElement(
                                                                 M_DOM_OUT
                                                                ,'TAKSUV_R7' );

            DBMS_OUTPUT.put_line( 'TAKSUV_R7' );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                         ,'Nommar_id'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                         ,'NOMMAR'
                                         ,NOM
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                         ,'nomrow'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                         ,'timeout'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                         ,'timein'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                         ,'koddor'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                         ,'kodst'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                         ,'nomtrain'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                         ,'kodwork'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                         ,'kodpd'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                         ,'lindist_r7'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                         ,'wnetto'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                         ,'wbrutto'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                         ,'facttime_r7'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                         ,'przminabrgst_r7'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                         ,'kolvantvag'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                         ,'kolporvag'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                         ,'prst_r7'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                         ,'manst_r7'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                         ,'nagin'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                         ,'workman'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                         ,'kilkosey'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                         ,'kilvag'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                         ,'kodserlok'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                         ,'nomlok'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV_R7
                                         ,'robota'
                                         ,''
                                         ,STR_ERR );
            TAGBODY            := XDB.DBMS_XMLDOM.AppendChild(
                                                               TAGINFBODY
                                                              ,XDB.DBMS_XMLDOM.makenode(
                                                                                         TAGRTAKSUV_R7 ) );
        END IF;

        SELECT COUNT( * )
          INTO KOL
          FROM S_R8_BASE
         WHERE NOMMAR_ID = A_IDF_MM;

        IF ( KOL > 0 )
        THEN
            FOR J IN ( SELECT *
                         FROM S_R8_BASE
                        WHERE NOMMAR_ID = A_IDF_MM )
            LOOP
                TAGINFBODY1      := XDB.DBMS_XSLPROCESSOR.selectSingleNode(
                                                                            XDB.DBMS_XMLDOM.makenode(
                                                                                                      M_DOM_OUT )
                                                                           ,'UZ-XDOC/BODY'
                                                                           ,STR_ERR );
                TAGR8            := XDB.DBMS_XMLDOM.createElement(
                                                                   M_DOM_OUT
                                                                  ,'R8_BASE' );

                DBMS_OUTPUT.put_line( 'R8_BASE' );
                XDB.DBMS_XMLDOM.setAttribute( TAGR8
                                             ,'Nommar_id'
                                             ,''
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR8
                                             ,'NOMMAR'
                                             ,J.NOMMAR
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR8
                                             ,'stname'
                                             ,J.STNAME
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR8
                                             ,'stkod'
                                             ,J.STKOD
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR8
                                             ,'manbeg'
                                             ,J.MANBEG
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR8
                                             ,'manend'
                                             ,J.MANEND
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR8
                                             ,'prvykl'
                                             ,J.PRVYKL
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR8
                                             ,'ktydinner'
                                             ,J.KTYDINNER
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR8
                                             ,'kodpark'
                                             ,J.KODPARK
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGR8
                                             ,'nomrow'
                                             ,J.NOMROW
                                             ,STR_ERR );
                                             XDB.DBMS_XMLDOM.setAttribute( TAGR8
                                             ,'kodwork'
                                             ,J.KODWORK
                                             ,STR_ERR );
                                             XDB.DBMS_XMLDOM.setAttribute( TAGR8
                                             ,'prwait'
                                             ,J.PRWAIT
                                             ,STR_ERR );
                TAGBODY          := XDB.DBMS_XMLDOM.AppendChild(
                                                                 TAGINFBODY
                                                                ,XDB.DBMS_XMLDOM.makenode(
                                                                                           TAGR8 ) );
            END LOOP;
        ELSE
            TAGINFBODY1      := XDB.DBMS_XSLPROCESSOR.selectSingleNode(
                                                                        XDB.DBMS_XMLDOM.makenode(
                                                                                                  M_DOM_OUT )
                                                                       ,'UZ-XDOC/BODY'
                                                                       ,STR_ERR );
            TAGR8            := XDB.DBMS_XMLDOM.createElement( M_DOM_OUT
                                                              ,'R8_BASE' );

            DBMS_OUTPUT.put_line( 'R8_BASE' );
            XDB.DBMS_XMLDOM.setAttribute( TAGR8
                                         ,'Nommar_id'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR8
                                         ,'NOMMAR'
                                         ,NOM
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR8
                                         ,'stname'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR8
                                         ,'stkod'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR8
                                         ,'manbeg'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR8
                                         ,'manend'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR8
                                         ,'prvykl'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR8
                                         ,'ktydinner'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR8
                                         ,'kodpark'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGR8
                                         ,'nomrow'
                                         ,''
                                         ,STR_ERR );
                                         XDB.DBMS_XMLDOM.setAttribute( TAGR8
                                         ,'kodwork'
                                         ,''
                                         ,STR_ERR );
                                         XDB.DBMS_XMLDOM.setAttribute( TAGR8
                                             ,'prwait'
                                             ,''
                                             ,STR_ERR );
            TAGBODY          := XDB.DBMS_XMLDOM.AppendChild(
                                                             TAGINFBODY
                                                            ,XDB.DBMS_XMLDOM.makenode(
                                                                                       TAGR8 ) );
        END IF;

        SELECT COUNT( * )
          INTO KOL
          FROM S_TAKSUV
         WHERE NOMMAR_ID = A_IDF_MM;

        IF ( KOL > 0 )
        THEN
            FOR J IN ( SELECT *
                         FROM S_TAKSUV
                        WHERE NOMMAR_ID = A_IDF_MM )
            LOOP
                TAGINFBODY1      := XDB.DBMS_XSLPROCESSOR.selectSingleNode(
                                                                            XDB.DBMS_XMLDOM.makenode(
                                                                                                      M_DOM_OUT )
                                                                           ,'UZ-XDOC/BODY'
                                                                           ,STR_ERR );
                TAGRTAKSUV       := XDB.DBMS_XMLDOM.createElement( M_DOM_OUT
                                                                  ,'taksuv' );

                DBMS_OUTPUT.put_line( 'taksuv' );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV
                                             ,'Nommar_id'
                                             ,''
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV
                                             ,'NOMMAR'
                                             ,J.NOMMAR
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV
                                             ,'lindist'
                                             ,J.LINDIST
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV
                                             ,'facttime'
                                             ,J.FACTTIME
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV
                                             ,'prst'
                                             ,J.PRST
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV
                                             ,'manst'
                                             ,J.MANST
                                             ,STR_ERR );
                                             XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV
                                             ,'datemod'
                                             ,TO_CHAR( J.DATEMOD
                                                      ,'dd.mm.yyyy' )
                                             ,STR_ERR );

                TAGBODY          := XDB.DBMS_XMLDOM.AppendChild(
                                                                 TAGINFBODY
                                                                ,XDB.DBMS_XMLDOM.makenode(
                                                                                           TAGRTAKSUV ) );
            END LOOP;
        ELSE
            TAGINFBODY1      := XDB.DBMS_XSLPROCESSOR.selectSingleNode(
                                                                        XDB.DBMS_XMLDOM.makenode(
                                                                                                  M_DOM_OUT )
                                                                       ,'UZ-XDOC/BODY'
                                                                       ,STR_ERR );
            TAGRTAKSUV       := XDB.DBMS_XMLDOM.createElement( M_DOM_OUT
                                                              ,'taksuv' );

            DBMS_OUTPUT.put_line( 'taksuv' );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV
                                         ,'Nommar_id'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV
                                         ,'NOMMAR'
                                         ,NOM
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV
                                         ,'lindist'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV
                                         ,'facttime'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV
                                         ,'prst'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV
                                         ,'manst'
                                         ,''
                                         ,STR_ERR );
                                         XDB.DBMS_XMLDOM.setAttribute( TAGRTAKSUV
                                         ,'datemod'
                                         ,''
                                         ,STR_ERR );

            TAGBODY          := XDB.DBMS_XMLDOM.AppendChild(
                                                             TAGINFBODY
                                                            ,XDB.DBMS_XMLDOM.makenode(
                                                                                       TAGRTAKSUV ) );
        END IF;

        DBMS_OUTPUT.put_line( 'Finish  Msg_Lm012.Form_Lm012' );
        S_LOG_WORK.ADD_RECORD( S_CHANGEDOM_PROC.GETVALUE( MSG, 'IDF_EVENT' )
                              ,'Finish  Form_Lm024' || SYSDATE );
    EXCEPTION
        WHEN OTHERS
        THEN
            MSG.EXITCODE   := 2;
            DBMS_OUTPUT.put_line(
                                  SUBSTR( 'Form_Lm024 - ' || SQLERRM
                                         ,1
                                         ,255 ) );
            S_LOG_WORK.ADD_RECORD(
                                   S_CHANGEDOM_PROC.GETVALUE( MSG
                                                             ,'IDF_EVENT' )
                                  ,   'Form_Lm024 - '
                                   || SUBSTR( SQLERRM, 1, 255 ) );
    END;
/* PROCEDURE Form_LM012_cancel( Msg IN OUT s_t_uzxdoc_message )
 IS
     m_DOM_Out       xdb.DBMS_XMLDOM.domdocument;
     tagBody         xdb.DBMS_XMLDOM.domnode;
     taginfBody      xdb.DBMS_XMLDOM.domnode;
     taginfBody1     xdb.DBMS_XMLDOM.domnode;
     taginfBody2     xdb.DBMS_XMLDOM.domnode;
     taginfBodyLok   xdb.DBMS_XMLDOM.domnode;
     taginfBodySec   xdb.DBMS_XMLDOM.domnode;

     tagNumberm      xdb.DBMS_XMLDOM.domelement;
     tagR1           xdb.DBMS_XMLDOM.domelement;
     tagR2           xdb.DBMS_XMLDOM.domelement;
     tagAttr2        xdb.DBMS_XMLDOM.domelement;
     tagR3           xdb.DBMS_XMLDOM.domelement;
     tagAttrSec      xdb.DBMS_XMLDOM.domelement;
     str_err         VARCHAR2( 255 );

     p_subtype       VARCHAR2( 25 );
     p_kod_mess      VARCHAR2( 25 );
     p_status_260    NUMBER;
     -----------------------------------------
     tbl_main        s_itf_main_mm%ROWTYPE;
     a_idf_mm        s_itf_main_mm.IDF_MM%TYPE;
 BEGIN
     Msg.ExitCode    := 0;

     DBMS_OUTPUT.put_line( 'Start Msg_Lm012.Form_Lm012_cancel' );
     s_log_work.add_record( s_changedom_proc.getVALUE( msg, 'IDF_EVENT' )
                           ,'Start Regl_Form_Lm024: ' || SYSDATE );

     SELECT kod_mess, subtype
       INTO p_kod_mess, p_subtype
       FROM S_Itf_Key_Msg;

     DBMS_OUTPUT.put_line( 'subtype=' || p_subtype );
     DBMS_OUTPUT.put_line( 'p_kod_mess=' || p_kod_mess );

     SELECT IDF_MM
       INTO a_idf_mm
       FROM S_ITF_MAIN_MM
      WHERE data_source = 1;

     m_DOM_Out       := xdb.DBMS_XMLDOM.newdomdocument;
     m_DOM_Out.ID    := msg.OutgoingDOM.ID;


     tagBody         := xdb.DBMS_XSLPROCESSOR.selectSingleNode(
                                                                xdb.DBMS_XMLDOM.makenode(
                                                                                          m_DOM_Out )
                                                               ,'UZ-XDOC'
                                                               ,str_err );
     xdb.DBMS_XMLDOM.setAttribute( XDB.DBMS_XMLDOM.MAKEELEMENT( tagBody )
                                  ,'subtype'
                                  ,p_subtype
                                  ,str_err );

     tagBody         := xdb.DBMS_XSLPROCESSOR.selectSingleNode(
                                                                xdb.DBMS_XMLDOM.makenode(
                                                                                          m_DOM_Out )
                                                               ,'UZ-XDOC/@doc_type'
                                                               ,str_err );
     xdb.DBMS_XMLDOM.setNodeValue( tagBody, 'data' );

     tagBody         := xdb.DBMS_XSLPROCESSOR.selectSingleNode(
                                                                xdb.DBMS_XMLDOM.makenode(
                                                                                          m_DOM_Out )
                                                               ,'UZ-XDOC/HEAD/@messcode'
                                                               ,str_err );
     xdb.DBMS_XMLDOM.setNodeValue( tagBody, 'LM024' );
     tagBody         := xdb.DBMS_XSLPROCESSOR.selectSingleNode(
                                                                xdb.DBMS_XMLDOM.makenode(
                                                                                          m_DOM_Out )
                                                               ,'UZ-XDOC/BODY'
                                                               ,str_err );
     tagNumberm      := xdb.DBMS_XMLDOM.createElement( m_DOM_Out
                                                      ,'NUMBERM' );


     FOR j IN ( SELECT *
                  FROM s_numberm_
                 WHERE NOMMAR_ID = a_idf_mm )
     LOOP
         xdb.DBMS_XMLDOM.setAttribute( tagNumberm
                                      ,'Nommar_id'
                                      ,''
                                      ,str_err );
         xdb.DBMS_XMLDOM.setAttribute( tagNumberm
                                      ,'NOMMAR'
                                      ,j.NOMMAR
                                      ,str_err );
         xdb.DBMS_XMLDOM.setAttribute( tagNumberm
                                      ,'DATEMOD'
                                      ,TO_CHAR( j.DATEMOD, 'dd.mm.yyyy' )
                                      ,str_err );
         xdb.DBMS_XMLDOM.setAttribute( tagNumberm
                                      ,'CLEANPASS'
                                      ,j.CLEANPASS
                                      ,str_err );
         xdb.DBMS_XMLDOM.setAttribute( tagNumberm
                                      ,'LNKNEXT'
                                      ,j.LNKNEXT
                                      ,str_err );
         xdb.DBMS_XMLDOM.setAttribute( tagNumberm
                                      ,'Sform'
                                      ,j.Sform
                                      ,str_err );
         xdb.DBMS_XMLDOM.setAttribute( tagNumberm
                                      ,'TAKSUV'
                                      ,j.TAKSUV
                                      ,str_err );
         xdb.DBMS_XMLDOM.setAttribute( tagNumberm
                                      ,'BEDMAK'
                                      ,j.BEDMAK
                                      ,str_err );
         xdb.DBMS_XMLDOM.setAttribute( tagNumberm
                                      ,'PRUJN'
                                      ,j.PRUJN
                                      ,str_err );
         xdb.DBMS_XMLDOM.setAttribute( tagNumberm
                                      ,'PERED'
                                      ,j.PERED
                                      ,str_err );
     END LOOP;



     tagBody         := xdb.DBMS_XMLDOM.AppendChild(
                                                     tagBody
                                                    ,xdb.DBMS_XMLDOM.makenode(
                                                                               tagNumberm ) );



     DBMS_OUTPUT.put_line( 'Finish  Msg_Lm012.Form_Lm012' );
     s_log_work.add_record( s_changedom_proc.getVALUE( msg, 'IDF_EVENT' )
                           ,'Finish  Form_Lm024' || SYSDATE );
 EXCEPTION
     WHEN OTHERS
     THEN
         Msg.ExitCode   := 2;
         DBMS_OUTPUT.put_line(
                               SUBSTR( 'Form_Lm024 - ' || SQLERRM
                                      ,1
                                      ,255 ) );
         s_log_work.add_record(
                                s_changedom_proc.getVALUE( msg
                                                          ,'IDF_EVENT' )
                               ,   'Form_Lm024 - '
                                || SUBSTR( SQLERRM, 1, 255 ) );
 END;*/
END MSG_LM012;
/