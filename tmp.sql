SELECT C4_NAME AS "区域"
      ,OFFICE_NAME AS "支局"
      ,DEPT_NAME AS "部门"
      ,COALESCE(YY_LEIB,'其他渠道') AS "渠道"
      ,ASSET_ROW_ID
      ,ACC_NBR AS "号码"
      ,PROM_NAME
      ,COALESCE(CPL_DT,SERV_START_DT) AS "资产竣工日期"
      ,DATE_CD AS "智能机新增日期"
      ,REGISTER_DT AS "终端注册时间(注册平台)"
      ,DAYS_DIFF AS "资产注册竣工间隔天数"
      ,ESN_ID AS "串号"  
			,TER_MODEL AS "终端"
      ,MKT_EMPLOYEE_ID AS "揽装工号"
      ,MKT_EMPLOYEE_NAME AS "揽装人"
      ,MKT_DEPT_NAME AS "揽装人部门"
      ,SALES_EMPLOYEE_NAME AS "受理人"
      ,SALES_DEPT_NAME AS "受理部门"
      ,VOL_3G_FIRST_DAY AS "当天使用流量"
      ,VOL_3G_30MI_AFTER AS "入网半小时后的流量"
      ,VOL_3G_10MI AS "入网10分钟内使用流量"
      ,VOL_3G_20MI AS "入网20分钟内使用流量"
      ,VOL_3G_30MI AS "入网30分钟内使用流量"
      ,VOL_3G_40MI AS "入网40分钟内使用流量"
      ,VOL_3G_50MI AS "入网50钟内使用流量"
      ,VOL_3G_60MI AS "入网1小时内使用流量"
      ,VOL_3G_120MI AS "入网2小时内使用流量"
      ,VOL_3G_180MI AS "入网3小时内使用流量"
FROM (
  SELECT P1.*,T.C4_NAME,T.OFFICE_NAME,T.ACC_NBR,T.PROM_NAME,T.SERV_START_DT,T.DEPT_NAME
        ,P2.MKT_DEPT_NAME,P2.MKT_EMPLOYEE_ID,P2.MKT_EMPLOYEE_NAME
        ,P2.SALES_EMPLOYEE_NAME,P2.SALES_DEPT_NAME
        ,T.YY_LEIB
				,P4.TER_MODEL
  FROM APP_K.LIST_3G_20M P1
  LEFT JOIN APP_K.OFR_MAIN_ASSET_CUR_K T ON P1.ASSET_ROW_ID = T.ASSET_ROW_ID
  LEFT JOIN BICVIEW_K.EVT_NEW_ASSET_K P2 ON P1.ASSET_ROW_ID = P2.ASSET_ROW_ID AND P2.LAST_STAT_NAME='竣工'
	LEFT JOIN PRTDATA.PRT772_LIST_K P4 ON P1.ESN_ID = P4.ESN_ID AND P4.FLG = 'MSU_NEW_Users' AND DATE(P4.REGISTER_DT) BETWEEN DATE('$date.beginDate$') AND DATE('$date.endDate$')
  WHERE DATE(P1.REGISTER_DT) BETWEEN DATE('$date.beginDate$') AND DATE('$date.endDate$')
  ORDER BY P1.REGISTER_DT,T.C4_NAME,T.OFFICE_NAME)

WITH UR 


/**********************************************************************************
1、三零用户锁定统计
**************************************************************************************/
DECLARE GLOBAL TEMPORARY TABLE SESSION.NEW_DEVELOP_CUST
AS 
(
SELECT P1.ASSET_ROW_ID
      ,P1.LATN_ID
      ,P1.STAT_NAME
      ,P1.SERV_START_DT
      ,P1.USER_GRADE
      ,P1.corp_user_name
      ,P2.XIAOYUAN_FLG
      ,P1.Last_Display_Area_Id AREA_ID
      ,P1.Last_Display_Area_NAME AREA_NAME
      ,P3.STD_AREA_LVL4_NAME AREA_LEVEL2_NAME
      ,P3.STD_AREA_LVL5_NAME AREA_LEVEL3_NAME
      ,P3.STD_AREA_LVL6_NAME AREA_LEVEL4_NAME
      ,CASE WHEN P1.SERV_START_DT between DATE('${TX_DATE}') -7 DAY and DATE('${TX_DATE}') -1 DAY  then '本周入网'           
            WHEN P1.SERV_START_DT between DATE(SUBSTRING(CAST(DATE('${TX_DATE}')-8 DAY AS CHAR(10)),1,7,CODEUNITS16)||'-01') 
                               and DATE('${TX_DATE}')-8 DAY   
                               then SUBSTRING(CAST(DATE('${TX_DATE}')-8 DAY AS CHAR(10)),1,7,CODEUNITS16)||'(除本周)'          
            WHEN P1.SERV_START_DT between DATE(SUBSTRING(CAST(DATE('${TX_DATE}')-8 DAY AS CHAR(10)),1,7,CODEUNITS16)||'-01') -1 MONTH
                               and DATE(SUBSTRING(CAST(DATE('${TX_DATE}')-8 DAY AS CHAR(10)),1,7,CODEUNITS16)||'-01') -1 DAY 
                                then CAST(DATE(SUBSTRING(CAST(DATE('${TX_DATE}')-8 DAY AS CHAR(10)),1,7,CODEUNITS16)||'-01') -1 MONTH AS CHAR(7))||'月'        
            WHEN P1.SERV_START_DT between DATE(SUBSTRING(CAST(DATE('${TX_DATE}')-8 DAY AS CHAR(10)),1,7,CODEUNITS16)||'-01') -2 MONTH
                               and DATE(SUBSTRING(CAST(DATE('${TX_DATE}')-8 DAY AS CHAR(10)),1,7,CODEUNITS16)||'-01') -1 MONTH -1 DAY
                               then CAST(DATE(SUBSTRING(CAST(DATE('${TX_DATE}')-8 DAY AS CHAR(10)),1,7,CODEUNITS16)||'-01') -2 MONTH AS CHAR(7))||'月'         
            WHEN P1.SERV_START_DT between DATE(SUBSTRING(CAST(DATE('${TX_DATE}')-8 DAY AS CHAR(10)),1,7,CODEUNITS16)||'-01') -3 MONTH
                               and DATE(SUBSTRING(CAST(DATE('${TX_DATE}')-8 DAY AS CHAR(10)),1,7,CODEUNITS16)||'-01') -2 MONTH -1 DAY
                               then CAST(DATE(SUBSTRING(CAST(DATE('${TX_DATE}')-8 DAY AS CHAR(10)),1,7,CODEUNITS16)||'-01') -3 MONTH AS CHAR(7))||'月'      
            else '其他' end Innet_Month
      ,CASE WHEN P4.Band_User_type	IN (2,4) THEN 1 else 0 END Wireless_Flg_CD
FROM BICVIEW_Z.OFR_MAIN_ASSET_CUR_${LocalCode} p1
LEFT join BICVIEW_Z.OFR_ASSET_MAIN_CDSC_CUR_${LocalCode} p2
ON P1.ASSET_ROW_ID=P2.ASSET_ROW_ID
LEFT JOIN DMNVIEW.DMN_COM_STD_AREA_LVL6 P3
ON P1.Last_Display_Area_Id=p3.STD_AREA_LVL6_ID
LEFT join BICVIEW_Z.OFR_INTERNET_DAY_${LocalCode} P4
ON P1.ASSET_ROW_ID=P4.ASSET_ROW_ID
and p4.DATE_CD= DATE('${TX_DATE}') -1 DAY
WHERE COALESCE(P1.Pre_Active_Status,'正常开户') = '正常开户'
AND    P1.STAT_NAME   IN ('现行','已暂停')                 
AND    P1.ON_SERV_FLG =1
and   P1.SERV_START_DT> DATE(SUBSTRING(CAST(DATE('${TX_DATE}')-8 DAY AS CHAR(10)),1,7,CODEUNITS16)||'-01') -3 MONTH -1 DAY
AND   P1.SERV_START_DT< DATE('${TX_DATE}') 
and  (P1.Std_Prd_Lvl4_Id IN (11010501,11010502) OR P1.CPrd_Name = '移动电话')
)DEFINITION ONLY 
PARTITIONING KEY (ASSET_ROW_ID) 
ON COMMIT PRESERVE ROWS 
NOT LOGGED;


INSERT INTO SESSION.NEW_DEVELOP_CUST
SELECT P1.ASSET_ROW_ID
      ,P1.LATN_ID
      ,P1.STAT_NAME
      ,P1.SERV_START_DT
      ,P1.USER_GRADE
      ,P1.corp_user_name
      ,P2.XIAOYUAN_FLG
      ,P1.Last_Display_Area_Id AREA_ID
      ,P1.Last_Display_Area_NAME AREA_NAME
      ,P3.STD_AREA_LVL4_NAME AREA_LEVEL2_NAME
      ,P3.STD_AREA_LVL5_NAME AREA_LEVEL3_NAME
      ,P3.STD_AREA_LVL6_NAME AREA_LEVEL4_NAME
      ,CASE WHEN P1.SERV_START_DT between DATE('${TX_DATE}') -7 DAY and DATE('${TX_DATE}') -1 DAY  then '本周入网'           
            WHEN P1.SERV_START_DT between DATE(SUBSTRING(CAST(DATE('${TX_DATE}')-8 DAY AS CHAR(10)),1,7,CODEUNITS16)||'-01') 
                               and DATE('${TX_DATE}')-8 DAY   
                               then SUBSTRING(CAST(DATE('${TX_DATE}')-8 DAY AS CHAR(10)),1,7,CODEUNITS16)||'(除本周)'          
            WHEN P1.SERV_START_DT between DATE(SUBSTRING(CAST(DATE('${TX_DATE}')-8 DAY AS CHAR(10)),1,7,CODEUNITS16)||'-01') -1 MONTH
                               and DATE(SUBSTRING(CAST(DATE('${TX_DATE}')-8 DAY AS CHAR(10)),1,7,CODEUNITS16)||'-01') -1 DAY 
                                then CAST(DATE(SUBSTRING(CAST(DATE('${TX_DATE}')-8 DAY AS CHAR(10)),1,7,CODEUNITS16)||'-01') -1 MONTH AS CHAR(7))||'月'        
            WHEN P1.SERV_START_DT between DATE(SUBSTRING(CAST(DATE('${TX_DATE}')-8 DAY AS CHAR(10)),1,7,CODEUNITS16)||'-01') -2 MONTH
                               and DATE(SUBSTRING(CAST(DATE('${TX_DATE}')-8 DAY AS CHAR(10)),1,7,CODEUNITS16)||'-01') -1 MONTH -1 DAY
                               then CAST(DATE(SUBSTRING(CAST(DATE('${TX_DATE}')-8 DAY AS CHAR(10)),1,7,CODEUNITS16)||'-01') -2 MONTH AS CHAR(7))||'月'         
            WHEN P1.SERV_START_DT between DATE(SUBSTRING(CAST(DATE('${TX_DATE}')-8 DAY AS CHAR(10)),1,7,CODEUNITS16)||'-01') -3 MONTH
                               and DATE(SUBSTRING(CAST(DATE('${TX_DATE}')-8 DAY AS CHAR(10)),1,7,CODEUNITS16)||'-01') -2 MONTH -1 DAY
                               then CAST(DATE(SUBSTRING(CAST(DATE('${TX_DATE}')-8 DAY AS CHAR(10)),1,7,CODEUNITS16)||'-01') -3 MONTH AS CHAR(7))||'月'      
            else '其他' end Innet_Month
      ,CASE WHEN P4.Band_User_type	IN (2,4) THEN 1 else 0 END Wireless_Flg_CD
FROM BICVIEW_Z.OFR_MAIN_ASSET_CUR_${LocalCode} p1
LEFT join BICVIEW_Z.OFR_ASSET_MAIN_CDSC_CUR_${LocalCode} p2
ON P1.ASSET_ROW_ID=P2.ASSET_ROW_ID
LEFT JOIN DMNVIEW.DMN_COM_STD_AREA_LVL6 P3
ON P1.Last_Display_Area_Id=p3.STD_AREA_LVL6_ID
LEFT join BICVIEW_Z.OFR_INTERNET_DAY_${LocalCode} P4
ON P1.ASSET_ROW_ID=P4.ASSET_ROW_ID
and p4.DATE_CD= DATE('${TX_DATE}') -1 DAY
WHERE COALESCE(P1.Pre_Active_Status,'正常开户') = '正常开户'
AND    P1.STAT_NAME   IN ('现行','已暂停')                 
AND    P1.ON_SERV_FLG =1
and   P1.SERV_START_DT> DATE(SUBSTRING(CAST(DATE('${TX_DATE}')-8 DAY AS CHAR(10)),1,7,CODEUNITS16)||'-01') -3 MONTH -1 DAY
AND   P1.SERV_START_DT< DATE('${TX_DATE}') 
and  (P1.Std_Prd_Lvl4_Id IN (11010501,11010502) OR P1.CPrd_Name = '移动电话')
;



/**********************************************************************************
2、三零用户最近非零通话日期
**************************************************************************************/
DECLARE GLOBAL TEMPORARY TABLE SESSION.RECENT_ZERO_DATE
AS
(
SELECT P1.ASSET_ROW_ID
      ,P1.LATN_ID
      ,P1.STAT_NAME
      ,P1.SERV_START_DT
      ,P1.Innet_Month
      ,MAX(P2.Date_Cd) AS RECENT_ZERO_DATE
FROM SESSION.NEW_DEVELOP_CUST P1
INNER JOIN BICVIEW_Z.OFR_ASSET_CDMA_ACT_DAY_${LocalCode} P2
ON P1.ASSET_ROW_ID=P2.ASSET_ROW_ID
AND (P2.Vs_Act_Flg_Cd=1 OR P2.Sms_Act_Flg_Cd=1 OR P2.Ds_Act_Flg_Cd=1)
AND P2.Date_Cd>=DATE('${TX_DATE}') -33 DAY
and P2.Date_Cd<=DATE('${TX_DATE}') -1 DAY
GROUP BY P1.ASSET_ROW_ID
      ,P1.LATN_ID
      ,P1.STAT_NAME
      ,P1.SERV_START_DT
      ,P1.Innet_Month
)DEFINITION ONLY 
PARTITIONING KEY (ASSET_ROW_ID) 
ON COMMIT PRESERVE ROWS 
NOT LOGGED;

INSERT INTO SESSION.RECENT_ZERO_DATE
SELECT P1.ASSET_ROW_ID
      ,P1.LATN_ID
      ,P1.STAT_NAME
      ,P1.SERV_START_DT
      ,P1.Innet_Month
      ,MAX(P2.Date_Cd) AS RECENT_ZERO_DATE
FROM SESSION.NEW_DEVELOP_CUST P1
INNER JOIN BICVIEW_Z.OFR_ASSET_CDMA_ACT_DAY_${LocalCode} P2
ON P1.ASSET_ROW_ID=P2.ASSET_ROW_ID
AND (P2.Vs_Act_Flg_Cd=1 OR P2.Sms_Act_Flg_Cd=1 OR P2.Ds_Act_Flg_Cd=1)
AND P2.Date_Cd>=DATE('${TX_DATE}') -33 day
and P2.Date_Cd<=DATE('${TX_DATE}') -1 day
GROUP BY P1.ASSET_ROW_ID
      ,P1.LATN_ID
      ,P1.STAT_NAME
      ,P1.SERV_START_DT
      ,P1.Innet_Month
;
/**********************************************************************************
3、整合
**************************************************************************************/
DECLARE GLOBAL TEMPORARY TABLE SESSION.ZERO_ACTIVE_CUST_PRE
AS
(
SELECT P1.ASSET_ROW_ID
      ,P1.LATN_ID
      ,P1.STAT_NAME
      ,P1.SERV_START_DT
      ,P1.corp_user_name
      ,P1.USER_GRADE
      ,P1.XIAOYUAN_FLG
      ,P1.AREA_ID
      ,P1.AREA_NAME
      ,P1.AREA_LEVEL2_NAME
      ,P1.AREA_LEVEL3_NAME
      ,P1.AREA_LEVEL4_NAME
      ,P1.Innet_Month
      ,P2.RECENT_ZERO_DATE
      ,CASE WHEN P2.RECENT_ZERO_DATE <P1.SERV_START_DT or P2.RECENT_ZERO_DATE IS NULL THEN P1.SERV_START_DT-1 day 
            else P2.RECENT_ZERO_DATE END RECENT_ZERO_DATE_NEW
      ,days(DATE('${TX_DATE}') -1 day)-(CASE WHEN P2.RECENT_ZERO_DATE <P1.SERV_START_DT or P2.RECENT_ZERO_DATE IS NULL THEN days(P1.SERV_START_DT-1 day )
            else days(P2.RECENT_ZERO_DATE) END) AS RECENT_ZERO_DAYS
      ,CASE WHEN days(DATE('${TX_DATE}') -1 day)-(CASE WHEN P2.RECENT_ZERO_DATE <P1.SERV_START_DT or P2.RECENT_ZERO_DATE IS NULL THEN days(P1.SERV_START_DT-1 day )
            else days(P2.RECENT_ZERO_DATE) END)<= 3 THEN '3天以下'
            WHEN days(DATE('${TX_DATE}') -1 day)-(CASE WHEN P2.RECENT_ZERO_DATE <P1.SERV_START_DT or P2.RECENT_ZERO_DATE IS NULL THEN days(P1.SERV_START_DT-1 day )
            else days(P2.RECENT_ZERO_DATE) END)= 4 THEN '4天'
            WHEN days(DATE('${TX_DATE}') -1 day)-(CASE WHEN P2.RECENT_ZERO_DATE <P1.SERV_START_DT or P2.RECENT_ZERO_DATE IS NULL THEN days(P1.SERV_START_DT-1 day )
            else days(P2.RECENT_ZERO_DATE) END)= 5 THEN '5天'
            WHEN days(DATE('${TX_DATE}') -1 day)-(CASE WHEN P2.RECENT_ZERO_DATE <P1.SERV_START_DT or P2.RECENT_ZERO_DATE IS NULL THEN days(P1.SERV_START_DT-1 day )
            else days(P2.RECENT_ZERO_DATE) END)= 6 THEN '6天'
            WHEN days(DATE('${TX_DATE}') -1 day)-(CASE WHEN P2.RECENT_ZERO_DATE <P1.SERV_START_DT or P2.RECENT_ZERO_DATE IS NULL THEN days(P1.SERV_START_DT-1 day )
            else days(P2.RECENT_ZERO_DATE) END)= 7 THEN '7天'
            WHEN days(DATE('${TX_DATE}') -1 day)-(CASE WHEN P2.RECENT_ZERO_DATE <P1.SERV_START_DT or P2.RECENT_ZERO_DATE IS NULL THEN days(P1.SERV_START_DT-1 day )
            else days(P2.RECENT_ZERO_DATE) END) BETWEEN 8 AND 14 THEN '8-14天'
            WHEN days(DATE('${TX_DATE}') -1 day)-(CASE WHEN P2.RECENT_ZERO_DATE <P1.SERV_START_DT or P2.RECENT_ZERO_DATE IS NULL THEN days(P1.SERV_START_DT-1 day )
            else days(P2.RECENT_ZERO_DATE) END) BETWEEN 15 AND 31 THEN '15-31天'
            WHEN days(DATE('${TX_DATE}') -1 day)-(CASE WHEN P2.RECENT_ZERO_DATE <P1.SERV_START_DT or P2.RECENT_ZERO_DATE IS NULL THEN days(P1.SERV_START_DT-1 day )
            else days(P2.RECENT_ZERO_DATE) END) >= 32 OR days(DATE('${TX_DATE}') -1 day)-(CASE WHEN P2.RECENT_ZERO_DATE <P1.SERV_START_DT or P2.RECENT_ZERO_DATE IS NULL THEN days(P1.SERV_START_DT-1 day )
            else days(P2.RECENT_ZERO_DATE) END) IS NULL THEN '一个月以上'   
          END  RECENT_ZERO_DAYS_TAG 
     ,Wireless_Flg_CD   
     ,P3.Brand_Type_Name
     ,P3.Prom_Row_Id
     ,P3.Prom_Name
FROM SESSION.NEW_DEVELOP_CUST P1
LEFT JOIN SESSION.RECENT_ZERO_DATE P2
ON P1.ASSET_ROW_ID=P2.ASSET_ROW_ID
LEFT JOIN BICVIEW_Z.OFR_ASSET_MAIN_CDSC_CUR_${LocalCode} P3
ON P1.ASSET_ROW_ID=P2.ASSET_ROW_ID
)DEFINITION ONLY 
PARTITIONING KEY (ASSET_ROW_ID) 
ON COMMIT PRESERVE ROWS 
NOT LOGGED;

INSERT INTO SESSION.ZERO_ACTIVE_CUST_PRE
SELECT P1.ASSET_ROW_ID
      ,P1.LATN_ID
      ,P1.STAT_NAME
      ,P1.SERV_START_DT
      ,P1.corp_user_name
      ,P1.USER_GRADE
      ,P1.XIAOYUAN_FLG
      ,P1.AREA_ID
      ,P1.AREA_NAME
      ,P1.AREA_LEVEL2_NAME
      ,P1.AREA_LEVEL3_NAME
      ,P1.AREA_LEVEL4_NAME
      ,P1.Innet_Month
      ,P2.RECENT_ZERO_DATE
      ,CASE WHEN P2.RECENT_ZERO_DATE <P1.SERV_START_DT or P2.RECENT_ZERO_DATE IS NULL THEN P1.SERV_START_DT-1 day 
            else P2.RECENT_ZERO_DATE END RECENT_ZERO_DATE_NEW
      ,days(DATE('${TX_DATE}') -1 day)-(CASE WHEN P2.RECENT_ZERO_DATE <P1.SERV_START_DT or P2.RECENT_ZERO_DATE IS NULL THEN days(P1.SERV_START_DT-1 day )
            else days(P2.RECENT_ZERO_DATE) END) AS RECENT_ZERO_DAYS
      ,CASE WHEN days(DATE('${TX_DATE}') -1 day)-(CASE WHEN P2.RECENT_ZERO_DATE <P1.SERV_START_DT or P2.RECENT_ZERO_DATE IS NULL THEN days(P1.SERV_START_DT-1 day )
            else days(P2.RECENT_ZERO_DATE) END)<= 3 THEN '3天以下'
            WHEN days(DATE('${TX_DATE}') -1 day)-(CASE WHEN P2.RECENT_ZERO_DATE <P1.SERV_START_DT or P2.RECENT_ZERO_DATE IS NULL THEN days(P1.SERV_START_DT-1 day )
            else days(P2.RECENT_ZERO_DATE) END)= 4 THEN '4天'
            WHEN days(DATE('${TX_DATE}') -1 day)-(CASE WHEN P2.RECENT_ZERO_DATE <P1.SERV_START_DT or P2.RECENT_ZERO_DATE IS NULL THEN days(P1.SERV_START_DT-1 day )
            else days(P2.RECENT_ZERO_DATE) END)= 5 THEN '5天'
            WHEN days(DATE('${TX_DATE}') -1 day)-(CASE WHEN P2.RECENT_ZERO_DATE <P1.SERV_START_DT or P2.RECENT_ZERO_DATE IS NULL THEN days(P1.SERV_START_DT-1 day )
            else days(P2.RECENT_ZERO_DATE) END)= 6 THEN '6天'
            WHEN days(DATE('${TX_DATE}') -1 day)-(CASE WHEN P2.RECENT_ZERO_DATE <P1.SERV_START_DT or P2.RECENT_ZERO_DATE IS NULL THEN days(P1.SERV_START_DT-1 day )
            else days(P2.RECENT_ZERO_DATE) END)= 7 THEN '7天'
            WHEN days(DATE('${TX_DATE}') -1 day)-(CASE WHEN P2.RECENT_ZERO_DATE <P1.SERV_START_DT or P2.RECENT_ZERO_DATE IS NULL THEN days(P1.SERV_START_DT-1 day )
            else days(P2.RECENT_ZERO_DATE) END) BETWEEN 8 AND 14 THEN '8-14天'
            WHEN days(DATE('${TX_DATE}') -1 day)-(CASE WHEN P2.RECENT_ZERO_DATE <P1.SERV_START_DT or P2.RECENT_ZERO_DATE IS NULL THEN days(P1.SERV_START_DT-1 day )
            else days(P2.RECENT_ZERO_DATE) END) BETWEEN 15 AND 31 THEN '15-31天'
            WHEN days(DATE('${TX_DATE}') -1 day)-(CASE WHEN P2.RECENT_ZERO_DATE <P1.SERV_START_DT or P2.RECENT_ZERO_DATE IS NULL THEN days(P1.SERV_START_DT-1 day )
            else days(P2.RECENT_ZERO_DATE) END) >= 32 OR days(DATE('${TX_DATE}') -1 day)-(CASE WHEN P2.RECENT_ZERO_DATE <P1.SERV_START_DT or P2.RECENT_ZERO_DATE IS NULL THEN days(P1.SERV_START_DT-1 day )
            else days(P2.RECENT_ZERO_DATE) END) IS NULL THEN '一个月以上'   
          END  RECENT_ZERO_DAYS_TAG 
     ,Wireless_Flg_CD   
     ,P3.Brand_Type_Name
     ,P3.Prom_Row_Id
     ,P3.Prom_Name
FROM SESSION.NEW_DEVELOP_CUST P1
LEFT JOIN SESSION.RECENT_ZERO_DATE P2
ON P1.ASSET_ROW_ID=P2.ASSET_ROW_ID
LEFT JOIN BICVIEW_Z.OFR_ASSET_MAIN_CDSC_CUR_${LocalCode} P3
ON P1.ASSET_ROW_ID=P3.ASSET_ROW_ID
;
--插入统计清单
DELETE FROM HEMSS.HEMS_A_ZERO_ACTIVE_WEEK_LIST_Z
WHERE DATE_CD= DATE('${TX_DATE}')
AND   LATN_ID= ${Latn_Id}
;
INSERT INTO HEMSS.HEMS_A_ZERO_ACTIVE_WEEK_LIST_Z
(      ASSET_ROW_ID
      ,DATE_CD
      ,DATE_START_END
      ,LATN_ID
      ,STAT_NAME
      ,SERV_START_DT
      ,corp_user_name
      ,USER_GRADE
      ,XIAOYUAN_FLG
      ,AREA_ID
      ,AREA_NAME
      ,AREA_LEVEL2_NAME
      ,AREA_LEVEL3_NAME
      ,AREA_LEVEL4_NAME
      ,Innet_Month
      ,RECENT_UNZERO_DATE
      ,RECENT_ZERO_DAYS
      ,RECENT_ZERO_DAYS_TAG
      ,Wireless_Flg_CD
      ,Brand_Type_Name
      ,Prom_Row_Id
      ,Prom_Name
)
SELECT 
       ASSET_ROW_ID
      ,DATE('${TX_DATE}')
      ,CAST(DATE('${TX_DATE}')-7 DAY AS CHAR(10)) ||'至'||CAST(DATE('${TX_DATE}')-1 DAY AS CHAR(10) )
      ,LATN_ID
      ,STAT_NAME
      ,SERV_START_DT
      ,corp_user_name
      ,USER_GRADE
      ,XIAOYUAN_FLG
      ,AREA_ID
      ,AREA_NAME
      ,AREA_LEVEL2_NAME
      ,AREA_LEVEL3_NAME
      ,AREA_LEVEL4_NAME
      ,Innet_Month
  ,RECENT_ZERO_DATE_NEW
      ,RECENT_ZERO_DAYS
      ,RECENT_ZERO_DAYS_TAG
      ,Wireless_Flg_CD
       ,Brand_Type_Name
      ,Prom_Row_Id
      ,Prom_Name
FROM  SESSION.ZERO_ACTIVE_CUST_PRE
;
DELETE FROM HEMSS.HEMS_A_ZERO_ACTIVE_WEEK_STAT_Z
WHERE DATE_CD= DATE('${TX_DATE}')
AND   LATN_ID= ${Latn_Id}
;
INSERT INTO  HEMSS.HEMS_A_ZERO_ACTIVE_WEEK_STAT_Z
      (RECENT_ZERO_DAYS_TAG
      ,Innet_Month
      ,LATN_ID
      ,DATE_CD
      ,DATE_START_END
      ,CNT
      )
      SELECT 
      RECENT_ZERO_DAYS_TAG
      ,Innet_Month
      ,LATN_ID
      ,DATE_CD
      ,DATE_START_END
      ,COUNT(*)
      FROM  HEMSS.HEMS_A_ZERO_ACTIVE_WEEK_LIST_Z
      WHERE DATE_CD= DATE('${TX_DATE}')
      and   LATN_ID= ${Latn_Id}
      GROUP BY RECENT_ZERO_DAYS_TAG
      ,Innet_Month
      ,LATN_ID
      ,DATE_CD
       ,DATE_START_END
;

DROP SPECIFIC FUNCTION "APP_K"."SQL130722085214900";

SET SCHEMA = "APP_K";

SET CURRENT PATH = "SYSIBM","SYSFUN","SYSPROC","SYSIBMADM","LKETL01";

CREATE FUNCTION "APP_K"."FN_SMS_C_SUMMARY" (
    "F_DATE_CD"	DATE,
    "F_CPRD_NAME"	VARCHAR(20) )
  RETURNS VARCHAR(1000)
  SPECIFIC "SQL130722085214900"
  LANGUAGE SQL
  NOT DETERMINISTIC
  EXTERNAL ACTION
  READS SQL DATA
  CALLED ON NULL INPUT
  INHERIT SPECIAL REGISTERS
BEGIN ATOMIC
 
	DECLARE SMS_HEAD VARCHAR(1000) DEFAULT '';
	DECLARE SMS_CONTENT VARCHAR(1000) DEFAULT ''; 
	
	DECLARE ALL_NEW_CNT,QB_NEW_CNT,QN_NEW_CNT,LY_NEW_CNT,JS_NEW_CNT,CS_NEW_CNT,KH_NEW_CNT INTEGER DEFAULT 0; 
	DECLARE ALL_LEAVE_CNT,QB_LEAVE_CNT,QN_LEAVE_CNT,LY_LEAVE_CNT,JS_LEAVE_CNT,CS_LEAVE_CNT,KH_LEAVE_CNT INTEGER DEFAULT 0;
 
	DECLARE V_INDEPEDENT_CNT,V_INDEPEDENT_CNT2 INT;
	
	LOOP: WHILE (1 = 1) DO
					SET V_INDEPEDENT_CNT = (SELECT COUNT(*)
																	 FROM APPVIEW.SMS_ZHU_NEW_LIST_K P1
																	 JOIN APP_K.OFR_MAIN_ASSET_CUR_K T
																	   ON T.ASSET_ROW_ID = P1.ASSET_ROW_ID
																		AND T.DATE_CD >= P1.DATE_CD
																	WHERE P1.DATE_CD = F_DATE_CD) ;	
					SET V_INDEPEDENT_CNT2 = (SELECT COUNT(*)
																	  FROM APPVIEW.SMS_ZHU_LEAVE_LIST_K P1
																	  JOIN APP_K.OFR_MAIN_ASSET_CUR_K T
																	    ON T.ASSET_ROW_ID = P1.ASSET_ROW_ID
																		 AND T.DATE_CD >= P1.DATE_CD
																	WHERE P1.DATE_CD = F_DATE_CD) ;																		
						IF (V_INDEPEDENT_CNT <> 0 AND V_INDEPEDENT_CNT2 <> 0) THEN
							LEAVE LOOP;
						END IF;
					END WHILE;
					
	SET SMS_HEAD = RIGHT(TRIM(CHAR(INTEGER(F_DATE_CD))),2)||'日'||F_CPRD_NAME||'装/离:';
	
	FOR V_CUR_NEW AS (SELECT T.C4_NAME
                          ,COUNT(DISTINCT P1.ASSET_ROW_ID) AS NEW_NEW_CNT
										FROM APPVIEW.SMS_ZHU_NEW_LIST_K P1
										LEFT JOIN APP_K.OFR_MAIN_ASSET_CUR_K T
													 ON T.ASSET_ROW_ID = P1.ASSET_ROW_ID
										WHERE P1.DATE_CD = F_DATE_CD
											AND P1.CPRD_NAME = F_CPRD_NAME
										GROUP BY T.C4_NAME
			
	)
	DO
		IF V_CUR_NEW.C4_NAME LIKE '%衢北%' THEN
			SET QB_NEW_CNT = V_CUR_NEW.NEW_NEW_CNT;
		ELSEIF  V_CUR_NEW.C4_NAME LIKE '%衢南%' THEN
			SET QN_NEW_CNT = V_CUR_NEW.NEW_NEW_CNT;
		ELSEIF  V_CUR_NEW.C4_NAME LIKE '%龙游%' THEN
			SET LY_NEW_CNT = V_CUR_NEW.NEW_NEW_CNT;
		ELSEIF  V_CUR_NEW.C4_NAME LIKE '%江山%' THEN
			SET JS_NEW_CNT = V_CUR_NEW.NEW_NEW_CNT;
		ELSEIF  V_CUR_NEW.C4_NAME LIKE '%常山%' THEN
			SET CS_NEW_CNT = V_CUR_NEW.NEW_NEW_CNT;
		ELSEIF  V_CUR_NEW.C4_NAME LIKE '%开化%' THEN
			SET KH_NEW_CNT = V_CUR_NEW.NEW_NEW_CNT;
		END IF;					
		SET ALL_NEW_CNT = ALL_NEW_CNT + V_CUR_NEW.NEW_NEW_CNT;
	END FOR;
	
	FOR V_CUR_LEAVE AS (SELECT T.C4_NAME
	                          ,COUNT(DISTINCT P1.ASSET_ROW_ID) AS LEAVE_NEW_CNT
											FROM APPVIEW.SMS_ZHU_LEAVE_LIST_K P1
											LEFT JOIN APP_K.OFR_MAIN_ASSET_CUR_K T 
											       ON T.ASSET_ROW_ID = P1.ASSET_ROW_ID
										  WHERE P1.DATE_CD = F_DATE_CD
											  AND P1.CPRD_NAME = F_CPRD_NAME 
										  GROUP BY T.C4_NAME
	)
	DO
		IF V_CUR_LEAVE.C4_NAME LIKE '%衢北%' THEN
			SET QB_LEAVE_CNT = V_CUR_LEAVE.LEAVE_NEW_CNT;
		ELSEIF  V_CUR_LEAVE.C4_NAME LIKE '%衢南%' THEN
			SET QN_LEAVE_CNT = V_CUR_LEAVE.LEAVE_NEW_CNT;
		ELSEIF  V_CUR_LEAVE.C4_NAME LIKE '%龙游%' THEN
			SET LY_LEAVE_CNT = V_CUR_LEAVE.LEAVE_NEW_CNT;
		ELSEIF  V_CUR_LEAVE.C4_NAME LIKE '%江山%' THEN
			SET JS_LEAVE_CNT = V_CUR_LEAVE.LEAVE_NEW_CNT;
		ELSEIF  V_CUR_LEAVE.C4_NAME LIKE '%常山%' THEN
			SET CS_LEAVE_CNT = V_CUR_LEAVE.LEAVE_NEW_CNT;
		ELSEIF  V_CUR_LEAVE.C4_NAME LIKE '%开化%' THEN
			SET KH_LEAVE_CNT = V_CUR_LEAVE.LEAVE_NEW_CNT;
		END IF;					
		SET ALL_LEAVE_CNT = ALL_LEAVE_CNT + V_CUR_LEAVE.LEAVE_NEW_CNT;
	END FOR;
	
	
	SET SMS_CONTENT =  '全市:'||TRIM(CHAR(ALL_NEW_CNT))||'/'||TRIM(CHAR(ALL_LEAVE_CNT))
									||';衢北:'||TRIM(CHAR(QB_NEW_CNT))||'/'||TRIM(CHAR(QB_LEAVE_CNT))
									||';衢南:'||TRIM(CHAR(QN_NEW_CNT))||'/'||TRIM(CHAR(QN_LEAVE_CNT))
									||';龙游:'||TRIM(CHAR(LY_NEW_CNT))||'/'||TRIM(CHAR(LY_LEAVE_CNT))
									||';江山:'||TRIM(CHAR(JS_NEW_CNT))||'/'||TRIM(CHAR(JS_LEAVE_CNT))
									||';常山:'||TRIM(CHAR(CS_NEW_CNT))||'/'||TRIM(CHAR(CS_LEAVE_CNT))
									||';开化:'||TRIM(CHAR(KH_NEW_CNT))||'/'||TRIM(CHAR(KH_LEAVE_CNT))
									||'。-'
									;
	RETURN SMS_HEAD||SMS_CONTENT;
   END;

SET SCHEMA = APP_K;

SET CURRENT PATH = "SYSIBM","SYSFUN","SYSPROC","SYSIBMADM","LKETL01";



SELECT DATE_CD                 AS DATE_CD
      ,T1.C4_NAME              AS "区域"
			,T1.OFFICE_NAME              AS "支局"
			,INTELLIGENT_ARRIVE_SUM  AS "智能机到达量"
      ,NEW_INTELLIGENT_SUM     AS "新增智能机"
      ,VOL_3G_NO_ZERO_SUM      AS "当天有流量"
      ,VOL_3G_FIRST_DAY_SUM    AS "当天超20M" 
			,VOL_3G_30MI_AFTER_NO_ZERO_SUM  AS "入网半小时后有流量"
			,VOL_3G_30MI_AFTER_SUM   AS "当天超20M且入网半小时后有流量"
			,DECODE(NEW_INTELLIGENT_SUM,0,0,VOL_3G_30MI_AFTER_SUM * 100.0/NEW_INTELLIGENT_SUM)  AS "当天超20M且入网半小时后有流量占比"
      ,VOL_3G_10MI_SUM         AS "入网10分钟超内20M"
			,VOL_3G_20MI_SUM         AS "入网20分钟超内20M"
      ,VOL_3G_30MI_SUM         AS "入网30分钟超内20M"
      ,VOL_3G_40MI_SUM         AS "入网40分钟超内20M"
      ,VOL_3G_50MI_SUM         AS "入网50分钟超内20M"
      ,VOL_3G_60MI_SUM         AS "入网1小时超20M"
      ,VOL_3G_120MI_SUM        AS "入网2小时内20M"
      ,VOL_3G_180MI_SUM        AS "入网3小时内20M"
      ,DECODE(NEW_INTELLIGENT_SUM,0,0,VOL_3G_FIRST_DAY_SUM * 100.0/NEW_INTELLIGENT_SUM) AS "当天超20M占比"
      ,DECODE(NEW_INTELLIGENT_SUM,0,0,VOL_3G_10MI_SUM * 100.0/NEW_INTELLIGENT_SUM)      AS "其中：入网10分钟内超20M占比"
      ,DECODE(NEW_INTELLIGENT_SUM,0,0,VOL_3G_20MI_SUM * 100.0/NEW_INTELLIGENT_SUM)      AS "其中：入网20分钟内超20M占比"
      ,DECODE(NEW_INTELLIGENT_SUM,0,0,VOL_3G_30MI_SUM * 100.0/NEW_INTELLIGENT_SUM)      AS "其中：入网30分钟内超20M占比"
      ,DECODE(NEW_INTELLIGENT_SUM,0,0,VOL_3G_40MI_SUM * 100.0/NEW_INTELLIGENT_SUM)      AS "其中：入网40分钟内超20M占比"
      ,DECODE(NEW_INTELLIGENT_SUM,0,0,VOL_3G_50MI_SUM * 100.0/NEW_INTELLIGENT_SUM)      AS "其中：入网50分钟内超20M占比"
      ,DECODE(NEW_INTELLIGENT_SUM,0,0,VOL_3G_60MI_SUM * 100.0/NEW_INTELLIGENT_SUM)      AS "其中：入网1小时内超20M占比"
      ,DECODE(NEW_INTELLIGENT_SUM,0,0,VOL_3G_120MI_SUM * 100.0/NEW_INTELLIGENT_SUM)     AS "其中：入网2小时内超20M占比"
      ,DECODE(NEW_INTELLIGENT_SUM,0,0,VOL_3G_180MI_SUM * 100.0/NEW_INTELLIGENT_SUM)     AS "其中：入网3小时内超20M占比"
FROM( 
		SELECT P1.DATE_CD
		      ,T.C4_NAME
					,T.OFFICE_NAME
					,COUNT(P1.ASSET_ROW_ID) AS NEW_ASSET_ALL
					,COUNT(P1.ASSET_ROW_ID)    AS NEW_INTELLIGENT_SUM  --智能机
					,COUNT(CASE WHEN P1.VOL_3G_30MI_AFTER > 0 THEN P1.ASSET_ROW_ID END)  AS VOL_3G_30MI_AFTER_NO_ZERO_SUM --半小时后有流量
					,COUNT(CASE WHEN P1.VOL_3G_FIRST_DAY > 0 THEN P1.ASSET_ROW_ID END)   AS VOL_3G_NO_ZERO_SUM   --当天有流量
					,COUNT(CASE WHEN P1.VOL_3G_10MI >= 20 THEN P1.ASSET_ROW_ID END)      AS VOL_3G_BEGIN_SUM     --(头十分钟)头次使用超20M
					,COUNT(CASE WHEN P1.VOL_3G_FIRST_DAY >= 20 THEN P1.ASSET_ROW_ID END) AS VOL_3G_FIRST_DAY_SUM --当天超20M
          ,COUNT(CASE WHEN P1.VOL_3G_30MI_AFTER > 0  
                       AND P1.VOL_3G_FIRST_DAY >= 20 THEN P1.ASSET_ROW_ID END)AS VOL_3G_30MI_AFTER_SUM	--半小时后有流量且当天超20M				
					,COUNT(CASE WHEN P1.VOL_3G_10MI >= 20 THEN P1.ASSET_ROW_ID END)      AS VOL_3G_10MI_SUM      --入网10分钟内超20M
					,COUNT(CASE WHEN P1.VOL_3G_20MI >= 20 THEN P1.ASSET_ROW_ID END)      AS VOL_3G_20MI_SUM      --入网20分钟内超20M
					,COUNT(CASE WHEN P1.VOL_3G_30MI >= 20 THEN P1.ASSET_ROW_ID END)      AS VOL_3G_30MI_SUM      --入网30分钟内超20M
					,COUNT(CASE WHEN P1.VOL_3G_40MI >= 20 THEN P1.ASSET_ROW_ID END)      AS VOL_3G_40MI_SUM      --入网40分钟内超20M
					,COUNT(CASE WHEN P1.VOL_3G_50MI >= 20 THEN P1.ASSET_ROW_ID END)      AS VOL_3G_50MI_SUM      --入网50分钟内超20M
					,COUNT(CASE WHEN P1.VOL_3G_60MI >= 20 THEN P1.ASSET_ROW_ID END)      AS VOL_3G_60MI_SUM      --入网1小时内超20M
					,COUNT(CASE WHEN P1.VOL_3G_120MI >= 20 THEN P1.ASSET_ROW_ID END)     AS VOL_3G_120MI_SUM     --入网2小时内超20M
					,COUNT(CASE WHEN P1.VOL_3G_180MI >= 20 THEN P1.ASSET_ROW_ID END)     AS VOL_3G_180MI_SUM     --入网3小时内超20M
		FROM APP_K.LIST_TERM_DATA	P1 
		LEFT JOIN APP_K.OFR_MAIN_ASSET_CUR_K T ON T.ASSET_ROW_ID = P1.ASSET_ROW_ID
		WHERE P1.DATE_CD = CURRENT_DATE -2 DAYS
		GROUP BY P1.DATE_CD
		        ,T.C4_NAME
						,T.OFFICE_NAME
)T1	
		LEFT JOIN (SELECT T.C4_NAME,T.OFFICE_NAME
											,COUNT(*) AS INTELLIGENT_ARRIVE_SUM
								FROM PRTDATA.PRT772_LIST_K  P1
								LEFT JOIN APP_K.OFR_MAIN_ASSET_CUR_K  T
											ON T.ASSET_ROW_ID=P1.ASSET_ROW_ID
								WHERE P1.FLG='MSU_Arrive_Cnts'  
								  AND P1.DATE_CD = CURRENT_DATE -2 DAYS
								GROUP BY P1.DATE_CD
								        ,T.C4_NAME
												,T.OFFICE_NAME
							) T2 --计算每日智能机到达量
							ON T1.C4_NAME = T2.C4_NAME
						 AND T1.OFFICE_NAME = T2.OFFICE_NAME
ORDER BY T1.C4_NAME