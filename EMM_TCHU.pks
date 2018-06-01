CREATE OR REPLACE PACKAGE APPL_DBW.EMM_TCHU AS

PROCEDURE msg_normal (Msg IN OUT s_T_UZXDOC_Message);
PROCEDURE msg_cancel (Msg IN OUT s_T_UZXDOC_Message);
PROCEDURE msg_close (Msg IN OUT s_T_UZXDOC_Message);


END EMM_TCHU;
/