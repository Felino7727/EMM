CREATE OR REPLACE PACKAGE BODY APPL_PKG.MSG_LM012_CANCEL
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


        MSG_LM012_cancel.FORM_LM012_CANCEL( MSG );

        M_TEXT   := 'формируем  регламент (LM024)';
        S_LOG_WORK.ADD_RECORD( S_E_SERVICE.IDF_EVENT, M_TEXT ); --event.service
        -- END IF;

        /* для потока */

        --   s_changedom_proc.SetValue('OUT_DOCTYPE', 'LM024');
        --   s_changedom_proc.SetValue('REGL_DOCTYPE','LM024');
        --   s_changedom_proc.SetValue('RETFMT','XML');
        --   s_changedom_proc.SetValue('SEND_ONE','1');



        ---dbms_output.put_line('Finish  Reg_Mess_End');
        /* s_Uvp_Queue.PutMes( '(11 3305 5)02'
                            ,'(11 7777 7)51'
                            ,msg.outgoingxml
                            ,SYSDATE
                            ,0
                            ,0
                            ,0 );*/
        --просмотреть результат сформированного запроса
        --s_Uvp_Queue.PutMes('(11 3305 5)02','(11 7777 7)51',msg.outgoingxml,SYSDATE,12,0,0);  --тправить запрос явно
        DBMS_OUTPUT.put_line( 'Finish Msg_Lm024' );
    END;

    PROCEDURE FORM_LM012_CANCEL( MSG IN OUT S_T_UZXDOC_MESSAGE )
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
        TAGATTRSEC      XDB.DBMS_XMLDOM.domelement;
        STR_ERR         VARCHAR2( 255 );

        P_SUBTYPE       VARCHAR2( 25 );

        P_KOD_MESS      VARCHAR2( 25 );
        P_STATUS_260    NUMBER;
        -----------------------------------------
        TBL_MAIN        S_ITF_MAIN_MM%ROWTYPE;
        A_IDF_MM        S_ITF_MAIN_MM.IDF_MM%TYPE;
        KOL             NUMBER;
    BEGIN
        MSG.EXITCODE    := 0;

        DBMS_OUTPUT.put_line( 'Start Msg_Lm012.Form_Lm012_cancel' );
        S_LOG_WORK.ADD_RECORD( S_CHANGEDOM_PROC.GETVALUE( MSG, 'IDF_EVENT' )
                              ,'Start Regl_Form_Lm024: ' || SYSDATE );

        SELECT KOD_MESS, subtype
          INTO P_KOD_MESS, P_SUBTYPE
          FROM S_ITF_KEY_MSG;

        DBMS_OUTPUT.put_line( 'subtype=' || P_SUBTYPE );
        DBMS_OUTPUT.put_line( 'p_kod_mess=' || P_KOD_MESS );

       /* SELECT IDF_MM
          INTO a_idf_mm
          FROM S_ITF_MAIN_MM                                               --;
         WHERE data_source = 0;*/                         -- 0 или 1 узнать Лена

        M_DOM_OUT       := XDB.DBMS_XMLDOM.newdomdocument;
        M_DOM_OUT.ID    := MSG.OUTGOINGDOM.ID;


        TAGBODY         := XDB.DBMS_XSLPROCESSOR.selectSingleNode(
                                                                   XDB.DBMS_XMLDOM.makenode(
                                                                                             M_DOM_OUT )
                                                                  ,'UZ-XDOC'
                                                                  ,STR_ERR );
        XDB.DBMS_XMLDOM.setAttribute( XDB.DBMS_XMLDOM.MAKEELEMENT( TAGBODY )
                                     ,'subtype'
                                     ,'cancel'
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
          
        
              select count (*) into KOL from(  SELECT distinct a.IDF_MM
                    ,a.IDF_MOD
                    ,decode(a.KPZ,B.ID_DEPO,B.ID_DEPO_IOMM,a.KPZ)
                    ,a.NOM_MRM
                    ,a.DATE_OP
                    ,DECODE( a.OZN_MM,  1, 0,  2, DBMS_RANDOM.VALUE( 1, 9 ) ) CLEANPASS
                    ,1
                    ,decode(a.IDF_TAKS,null,0,1) TAKSUV
                    ,DECODE( a.STATUS,  0, 0,  1, 1 ) BEDMAK
                    ,1
                    ,1
                    ,null
                FROM S_ITF_MAIN_MM a, APPL_DBW.PEREKODIROVKA_DEPO B 
               WHERE DATA_SOURCE = 0);
        
        /*SELECT COUNT( * )
          INTO kol
          FROM s_numberm_
         WHERE NOMMAR_ID = a_idf_mm;*/

        IF ( KOL > 0 )
        THEN
            FOR J IN (SELECT distinct
                     a.JAVKA JAVKA
                    ,a.NOM_MRM NOM_MRM
                    ,a.DATE_OP DATE_OP
                    ,DECODE( a.OZN_MM,  1, 0,  2, DBMS_RANDOM.VALUE( 1, 9 ) ) CLEANPASS
                    ,decode(a.IDF_TAKS,null,0,1) TAKSUV
                    ,DECODE( a.STATUS,  0, 0,  1, 1 ) BEDMAK                    
                FROM S_ITF_MAIN_MM a, APPL_DBW.PEREKODIROVKA_DEPO B 
               WHERE DATA_SOURCE = 0/*SELECT *
                         FROM s_numberm_
                        WHERE NOMMAR_ID = a_idf_mm*/ )
            LOOP
                DBMS_OUTPUT.put_line( 's_numberm_' );
                XDB.DBMS_XMLDOM.setAttribute( TAGNUMBERM
                                             ,'Nommar_id'
                                             ,''
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGNUMBERM
                                             ,'NOMMAR'
                                             ,J.NOM_MRM
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute(
                                              TAGNUMBERM
                                             ,'DATEMOD'
                                             ,TO_CHAR( J.DATE_OP
                                                      ,'dd.mm.yyyy' )
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGNUMBERM
                                             ,'CLEANPASS'
                                             ,J.CLEANPASS
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGNUMBERM
                                             ,'LNKNEXT'
                                             ,''
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGNUMBERM
                                             ,'Sform'
                                             ,'1'
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
                                             ,'1'
                                             ,STR_ERR );
                XDB.DBMS_XMLDOM.setAttribute( TAGNUMBERM
                                             ,'PERED'
                                             ,'1'
                                             ,STR_ERR );
                                             XDB.DBMS_XMLDOM.setAttribute(
                                              TAGNUMBERM
                                             ,'DATE_DOCUM'
                                             ,TO_CHAR( J.JAVKA
                                                      ,'dd.mm.yyyy' )
                                             ,STR_ERR );
            END LOOP;
        ELSE
            DBMS_OUTPUT.put_line( 's_numberm_' );
            XDB.DBMS_XMLDOM.setAttribute( TAGNUMBERM
                                         ,'Nommar_id'
                                         ,''
                                         ,STR_ERR );
            XDB.DBMS_XMLDOM.setAttribute( TAGNUMBERM
                                         ,'NOMMAR'
                                         ,''
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
END MSG_LM012_CANCEL;
/