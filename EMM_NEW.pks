CREATE OR REPLACE PACKAGE APPL_DBW.EMM_NEW AS
--%Є.099409.1.01.00.1 001.001.040%Придн%Антонцев М.В.%Формування ЕММ    

--29.02.16  доповнюється інформацією: d_beg_lunch, d_end_lunch 
--12.04.16  следование пассажиром
--12.04.16  Закриття ЕММ, коригування ЕММ
--31.05.16   4,7 раздел
--10.06.16   9 раздел
--29.06.16   коригування ЕММ
--30.06.16   коригування ЕММ
--Дописали секции в 4 раздел
--Дописали закриття ЕММ
--31.10.16   Закритя ЕММ
--22.08.2017 сменили на NSI.LM_KOD_SLED_OKDL с привязкой к PR_actual
--24.11.2017 Кое - что убрал, кое - что добавил! Смотреть задание 
--18.12.2017 Полный ППЦ!!!!! Правки по заданию!UPDATE, CORRECTION,CLOSE 
--27,02,2018 Изменил полностью весь код! Задание в блакноте,пожелания Виктории Владимировны!
--01,04,2018 RPS and LOK


  --Главная процедура
   PROCEDURE MAIN (MSG IN OUT S_T_UZXDOC_MESSAGE); 
   --Формирование разделов 1,3
   PROCEDURE PART_1_3(MSG IN OUT S_T_UZXDOC_MESSAGE) ;
   --Считывание разделов 1,3
   PROCEDURE PART_MM_READ (MSG IN OUT S_T_UZXDOC_MESSAGE);  
   --Добавление данных при 31 операции (Отдых)
   PROCEDURE UPDATE_MM(MSG IN OUT S_T_UZXDOC_MESSAGE);
   --Добавление данных о локомотиве
   PROCEDURE LOK_MM;
   --Відомість про хід, вагу, склад поїзда та виділену маневрову роботу на станціях
   PROCEDURE PART7_MM;
   --інформація про локомотиви, які працюють у різних з’єднаннях 
   PROCEDURE PART4_MM;  
   --інформація про паливо
   PROCEDURE FUEL_MM; 
   --Добавление данных о поездки пассажиром
   PROCEDURE PASS;  
   --Закриття ЕММ (для сообщения LM002)
   PROCEDURE CLOSE02 (MSG IN OUT S_T_UZXDOC_MESSAGE);
   --коригування ЕММ
   PROCEDURE CORRECTION (MSG IN OUT S_T_UZXDOC_MESSAGE);
  --Процедура для формирования полного ЕММ (без --Считывание разделов 1,3)
   PROCEDURE PART_FULL_MM_MAIN (MSG IN OUT S_T_UZXDOC_MESSAGE);
 

END EMM_NEW;
/