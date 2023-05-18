
-- 이커머스 외주생산 요청 연동
--CREATE PROC [dbo].[MIS_ECOM_MALL_ORDER_CSTM_ORDER_SYNC_UPDATE] 
DECLARE
	@P_XML_DATA		NVARCHAR(MAX),	-- 외주생산 요청 건 XML DATA
	@P_LOGIN_ID		NVARCHAR(50)    -- 등록자 

             
BEGIN TRY
	
	SET NOCOUNT ON; 
	
	SELECT @P_XML_DATA = '<DocumentElement>\r\n  <XML_TABLE>\r\n    <SEQ>1142024</SEQ>\r\n    <STORE_SEQ>2064</STORE_SEQ>\r\n    <STORE_NM>11번가S</STORE_NM>\r\n    <MALL_RECEIVER_NM>정미정</MALL_RECEIVER_NM>\r\n    <ORDER_DATE>2022-07-15</ORDER_DATE>\r\n    <HOPE_DATE>2022-07-29</HOPE_DATE>\r\n    <PRODCUT_SEQ>136807</PRODCUT_SEQ>\r\n    <MODEL_NO>SC1456A-BBR21</MODEL_NO>\r\n    <CLS_L_NM>Bracelet</CLS_L_NM>\r\n    <MTRL />\r\n    <SIZE />\r\n    <QTY>1</QTY>\r\n  </XML_TABLE>\r\n</DocumentElement>'
		,  @P_LOGIN_ID = '1'


	DECLARE @ERROR_NUMBER INT = 1
	      , @SEQ		  INT 


	
	-- 임시 테이블 생성 
	DECLARE @TMP_TBL TABLE (  
		SEQ					NVARCHAR(1000),
		STORE_SEQ			NVARCHAR(1000),
		STORE_NM			NVARCHAR(1000),
		MALL_RECEIVER_NM	NVARCHAR(1000),
		ORDER_DATE			NVARCHAR(1000),
		HOPE_DATE			NVARCHAR(1000),
		MODEL_NO			NVARCHAR(1000),
		CLS_L_NM			NVARCHAR(1000),
		MTRL				NVARCHAR(1000),
		SIZE				NVARCHAR(1000),
		QTY					NVARCHAR(1000),
		NOTE				NVARCHAR(1000)
	); 

	-- XML DATA 변환
	DECLARE @XML_DATA XML 
	SELECT @XML_DATA = CAST(@P_XML_DATA AS XML) 
			 
	-- 업로드 데이터 정보 세팅 
	INSERT INTO @TMP_TBL
	SELECT TB_XML.ROW_XML.value('SEQ[1]',				'VARCHAR(1000)')		AS SEQ,
		   TB_XML.ROW_XML.value('STORE_SEQ[1]',			'VARCHAR(1000)')		AS STORE_SEQ,
		   TB_XML.ROW_XML.value('STORE_NM[1]',			'VARCHAR(1000)')		AS STORE_NM,
		   TB_XML.ROW_XML.value('MALL_RECEIVER_NM[1]',	'VARCHAR(1000)')		AS MALL_RECEIVER_NM,
		   TB_XML.ROW_XML.value('ORDER_DATE[1]',		'VARCHAR(1000)')		AS ORDER_DATE,
		   TB_XML.ROW_XML.value('HOPE_DATE[1]',			'VARCHAR(1000)')		AS HOPE_DATE,
		   TB_XML.ROW_XML.value('MODEL_NO[1]',			'VARCHAR(1000)')		AS MODEL_NO,
		   TB_XML.ROW_XML.value('CLS_L_NM[1]',			'VARCHAR(1000)')		AS CLS_L_NM,
		   TB_XML.ROW_XML.value('MTRL[1]',				'VARCHAR(1000)')		AS MTRL,
		   TB_XML.ROW_XML.value('SIZE[1]',				'VARCHAR(1000)')		AS SIZE,
		   TB_XML.ROW_XML.value('QTY[1]',				'VARCHAR(1000)')		AS QTY,
		   TB_XML.ROW_XML.value('NOTE[1]',				'VARCHAR(1000)')		AS NOTE
	FROM @XML_DATA.nodes('/DocumentElement/XML_TABLE') AS TB_XML(ROW_XML) 

	BEGIN TRAN 

		SELECT @SEQ = MAX(SEQ)+1 FROM TB_STONEHENGE_ORDER WITH(NOLOCK) 

		IF EXISTS (SELECT * 
				   FROM TB_ECOM_MALL_ORDER A
					    INNER JOIN @TMP_TBL B ON A.SEQ = B.SEQ
				   WHERE ECOM_ORDER_STATUS != 'A01')
			BEGIN 
				;THROW 50001, '주문등록 상태에서만 고객주문 할 수 있습니다.', 64; 
			END 
		-- 스톤헨지 발주 데이터 연계 
		INSERT INTO TB_STONEHENGE_ORDER (	[SEQ], [CSTM_ORDER_TYPE], [STORE_SEQ], [STORE_ID], [RECEIVE_STORE_SEQ], [CSTM_NAME], [MOBILE_NO], [PRODUCT_SEQ], [MODEL_NO], 
											[METAL], [SIZE], [STONE_TYPE], [STONE_SIZE], [STONE_CD], [QTY], [ORDER_DATE], [HOPE_DATE], 
											[CASH], [CASH_MARGIN], [CARD], [CARD_MARGIN], [VOUCHER], [VOUCHER_MARGIN],
											[MEMO], [HQ_MEMO], [ORDER_SEQ], 
											[EMP_SEQ], [HQ_USER], [REG_DATE], [MOD_USER], [MOD_DATE], [CONFIRM_USER], [CONFIRM_DATE], [ERP_TRANSFER_USER], [ERP_TRANSFER_DATE], 
											[ERP_YN], [OLD_MODEL_NO], [JEWELRY_TYPE])
		SELECT @SEQ														    AS SEQ,
			   'ECM'														AS [CSTM_ORDER_TYPE],	
			   B.STORE_SEQ													AS [STORE_SEQ], 
			   S.STORE_ID													AS [STORE_ID], 
			   B.STORE_SEQ													AS [RECEIVE_STORE_SEQ], 
			   ISNULL(B.MALL_RECEIVER_NM, A.MALL_BUYER_MOBILE_NUM)			AS [CSTM_NAME], 
			   ISNULL(A.MALL_RECEIVER_MOBILE_NUM, A.MALL_BUYER_MOBILE_NUM)	AS [MOBILE_NO], 
			   A.PRODUCT_SEQ												AS [PRODUCT_SEQ], 
			   B.MODEL_NO													AS [MODEL_NO], 
			   B.MTRL														AS [METAL], 
			   B.SIZE														AS [SIZE], 
			   NULL															AS [STONE_TYPE], 
			   NULL															AS [STONE_SIZE], 
			   NULL															AS [STONE_CD], 
			   B.QTY														AS [QTY], 
			   B.ORDER_DATE													AS [ORDER_DATE], 
			   B.HOPE_DATE													AS [HOPE_DATE], 
			   NULL															AS [CASH], 
			   NULL															AS [CASH_MARGIN], 
			   NULL															AS [CARD], 
			   NULL															AS [CARD_MARGIN], 
			   NULL															AS [VOUCHER], 
			   NULL															AS [VOUCHER_MARGIN],
			   B.NOTE														AS [MEMO], 
			   NULL															AS [HQ_MEMO], 
			   NULL															AS [ORDER_SEQ], 
			   NULL															AS [EMP_SEQ], 
			   @P_LOGIN_ID													AS [HQ_USER], 
			   GETDATE()													AS [REG_DATE], 
			   NULL															AS [MOD_USER], 
			   NULL															AS [MOD_DATE], 
			   NULL															AS [CONFIRM_USER], 
			   NULL															AS [CONFIRM_DATE], 
			   NULL															AS [ERP_TRANSFER_USER], 
			   NULL															AS [ERP_TRANSFER_DATE], 
			   'N'															AS [ERP_YN], 
			   B.MODEL_NO													AS [OLD_MODEL_NO], 
			   NULL															AS [JEWELRY_TYPE] 
		FROM TB_ECOM_MALL_ORDER A
			 INNER JOIN @TMP_TBL B	ON A.SEQ = B.SEQ 
			 INNER JOIN TB_STORE S	ON B.STORE_SEQ = S.SEQ 

		-- 이커머스 발주 상태값 변경 
		UPDATE A 
		SET  A.ECOM_ORDER_STATUS = 'B01' -- 주문제작요청 
		FROM TB_ECOM_MALL_ORDER A 
			 INNER JOIN @TMP_TBL B	ON A.SEQ = B.SEQ 

	ROLLBACK TRAN



END TRY 
BEGIN CATCH 
		
	PRINT ERROR_PROCEDURE() + CHAR(13) + CHAR(10)   
        + 'LINE : '   
        + CONVERT(VARCHAR(3), ERROR_LINE())   
   
    -- 트랜잭션 상태 확인 
	--  1 : 트랜잭션 활성 (커밋 가능)
	--  0 : 트랜잭션 비활성 
	-- -1 : 트랜잭션 활성 (커밋 불가능)
    IF XACT_STATE() <> 0 ROLLBACK TRAN;     

     
    SET @ERROR_NUMBER = IIF(ISNULL(ERROR_NUMBER(), 0) = 0, -1, ERROR_NUMBER())

    PRINT ERROR_NUMBER(); 
    PRINT ERROR_MESSAGE();   


END CATCH 


--RETURN 1; 
--RETURN @ERROR_NUMBER;