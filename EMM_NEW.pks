CREATE OR REPLACE PACKAGE APPL_DBW.EMM_NEW AS
--%�.099409.1.01.00.1 001.001.040%�����%�������� �.�.%���������� ���    

--29.02.16  ������������ �����������: d_beg_lunch, d_end_lunch 
--12.04.16  ���������� ����������
--12.04.16  �������� ���, ����������� ���
--31.05.16   4,7 ������
--10.06.16   9 ������
--29.06.16   ����������� ���
--30.06.16   ����������� ���
--�������� ������ � 4 ������
--�������� �������� ���
--31.10.16   ������� ���
--22.08.2017 ������� �� NSI.LM_KOD_SLED_OKDL � ��������� � PR_actual
--24.11.2017 ��� - ��� �����, ��� - ��� �������! �������� ������� 
--18.12.2017 ������ ���!!!!! ������ �� �������!UPDATE, CORRECTION,CLOSE 
--27,02,2018 ������� ��������� ���� ���! ������� � ��������,��������� �������� ������������!
--01,04,2018 RPS and LOK


  --������� ���������
   PROCEDURE MAIN (MSG IN OUT S_T_UZXDOC_MESSAGE); 
   --������������ �������� 1,3
   PROCEDURE PART_1_3(MSG IN OUT S_T_UZXDOC_MESSAGE) ;
   --���������� �������� 1,3
   PROCEDURE PART_MM_READ (MSG IN OUT S_T_UZXDOC_MESSAGE);  
   --���������� ������ ��� 31 �������� (�����)
   PROCEDURE UPDATE_MM(MSG IN OUT S_T_UZXDOC_MESSAGE);
   --���������� ������ � ����������
   PROCEDURE LOK_MM;
   --³������ ��� ���, ����, ����� ����� �� ������� ��������� ������ �� ��������
   PROCEDURE PART7_MM;
   --���������� ��� ����������, �� �������� � ����� 璺������� 
   PROCEDURE PART4_MM;  
   --���������� ��� ������
   PROCEDURE FUEL_MM; 
   --���������� ������ � ������� ����������
   PROCEDURE PASS;  
   --�������� ��� (��� ��������� LM002)
   PROCEDURE CLOSE02 (MSG IN OUT S_T_UZXDOC_MESSAGE);
   --����������� ���
   PROCEDURE CORRECTION (MSG IN OUT S_T_UZXDOC_MESSAGE);
  --��������� ��� ������������ ������� ��� (��� --���������� �������� 1,3)
   PROCEDURE PART_FULL_MM_MAIN (MSG IN OUT S_T_UZXDOC_MESSAGE);
 

END EMM_NEW;
/