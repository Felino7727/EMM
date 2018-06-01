CREATE OR REPLACE PACKAGE APPL_PKG.MSG_LM012_CANCEL AS

procedure Main(Msg in out s_t_uzxdoc_message);
procedure Form_LM012_cancel(Msg in out s_t_uzxdoc_message) ;

END MSG_LM012_CANCEL;
/