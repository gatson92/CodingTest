
-- MIS_DAILY_SALES_PRODUCT_LIST_SELECT

DECLARE
 @P_START_DATE			 VARCHAR(20) = '2020-01-01',	-- 시작일  
 @P_END_DATE			 VARCHAR(20) = '2022-07-01',	-- 종료일  
 @P_STORE_SEQ			 VARCHAR(10) = '',	-- 매장명  
 @P_BRAND_SEQ			 VARCHAR(10) = '',	-- 브랜드명  
 @P_GUBUN			     VARCHAR(20) = '',	-- 시계 = 1 ,주얼리 = 2 ,쇼파드 = 3
 @P_ModelNo				 VARCHAR(50) = '', -- 모델명
 @P_ITEM				NVARCHAR(20) = ''  -- 품목 : 시계 = 1 , 주얼리 = 2 , 잡화 = 3 , 화장품 = 4


BEGIN  

	DECLARE @StrDate	SMALLDATETIME,
			@EndDate	SMALLDATETIME,
			@TMP1		NCHAR(6),
			@TMP2		NCHAR(6),
			@OPENQUERY	NVARCHAR(MAX), 
			@TSQL		NVARCHAR(MAX), 
			@Linked		NVARCHAR(MAX)



	SELECT	@StrDate	= CONVERT(smalldatetime,@P_START_DATE)
		,	@EndDate	= CONVERT(smalldatetime,@P_END_DATE)
		,	@TMP1 = LEFT(REPLACE(@P_START_DATE,'-',''),6)
		,	@TMP2 = LEFT(REPLACE(@P_END_DATE,'-',''),6)
		,	@Linked		= 'ERP_LINK'
		,	@OPENQUERY	= 'SELECT COST_YM, CD_ITEM, UM FROM OPENQUERY('+ @Linked + ','''
		,	@TSQL		= 'SELECT A.YM_STANDARD AS COST_YM , A.CD_ITEM, A.UM_INV AS UM FROM NEOE.NEOE.V_MM_Z_WRFMG_AMINVL A WITH(NOLOCK) WHERE A.YM_STANDARD != ''''202100'''' AND A.YM_STANDARD BETWEEN ''''+@TMP1+'''' AND ''''+@TMP2+'''' '')'


	DECLARE @MM_AMINVL TABLE(
		COST_YM VARCHAR(7),
		CD_ITEM NVARCHAR(40),
		UM		INT
	)				
	
	INSERT @MM_AMINVL EXEC (@OPENQUERY+@TSQL)



SELECT		SALES_DATE	-- 일자	
		,	STORE_NM	-- 매장명
		,	MEM_NAME	-- 고객명
		,	BRAND_NAME	-- 브랜드명
		,	MODEL_NO2	-- 모델명
--		,   ISNULL(J.UM, 0) AS COST	-- 원가
		,	conAmt		-- 소비자가
		,	selQty		-- 정상판매 수량
		,	selAmt		-- 정상판매 금액 		
		,	evtQty		-- 행사 수량
		,	evtAmt		-- 행사 금액
		,	onlQty		-- 온라인 수량
		,	onlAmt		-- 온라인 금액     (  CST_TYPE -> O:온라인 M:맴버 N:비회원 )
		,	salAmt		-- 할인금액
		,	refQty		-- 반품 수량
		,	refAmt		-- 반품 금액
		,	resQty		-- 예약 수량
		,	resAmt		-- 예약 금액(완납 기준)
		,	recQty		-- 예약취소 수량
		,	recAmt		-- 예약취소 금액
		,	SALES_TYPE	-- 매출 유형(1:구매 2:예약 3:환불 4:취소)
		,	EVENT_YN	-- 행사여부
		,	ITEM		-- 품목


FROM
(

	SELECT CONVERT(CHAR(10), A.SALES_DATE, 23)  AS SALES_DATE,	-- 일자	
		   ISNULL(B.STORE_NM,'')				AS STORE_NM,	-- 매장명
		   ISNULL(C.MEM_NAME,'')				AS MEM_NAME,	-- 고객명
		   ISNULL(E.BRAND_NAME,'')				AS BRAND_NAME,	-- 브랜드명
		   ISNULL(D.MODEL_NO2,'')				AS MODEL_NO2,	-- 모델명
		   ISNULL(A.NOR_PRICE, 0)				AS conAmt,		-- 소비자가
		   (CASE WHEN ((A.SALES_TYPE = '1') AND (ISNULL(A.EVENT_STORE_SEQ,0) = 0) AND (A.CST_TYPE <> 'O'))	THEN A.QTY 
				 ELSE '0' END)	AS selQty,		-- 1. 정상판매 수량
		   (CASE WHEN ((A.SALES_TYPE = '1') AND (ISNULL(A.EVENT_STORE_SEQ,0) = 0) AND (A.CST_TYPE <> 'O'))	THEN A.SELL_PRICE 
				 ELSE '0' END)	AS selAmt,		-- 2. 정상판매 금액 		
		   (CASE WHEN ((A.SALES_TYPE = '1') AND (ISNULL(A.EVENT_STORE_SEQ,0) <> 0) AND (A.CST_TYPE <> 'O'))	THEN  A.QTY 
				 ELSE '0' END)	AS evtQty,		-- 3. 행사 수량
		   (CASE WHEN ((A.SALES_TYPE = '1') AND (ISNULL(A.EVENT_STORE_SEQ,0) <> 0) AND (A.CST_TYPE <> 'O'))	THEN  A.SELL_PRICE 
				 ELSE '0' END)	AS evtAmt,		-- 4. 행사 금액
		   (CASE WHEN ((A.SALES_TYPE = '1') AND(A.CST_TYPE = 'O')) THEN  A.QTY 
				 ELSE '0' END)	AS onlQty,		-- 5. 온라인 수량
		   (CASE WHEN ((A.SALES_TYPE = '1') AND(A.CST_TYPE = 'O')) THEN  A.SELL_PRICE 
				 ELSE '0' END)	AS onlAmt,		-- 6. 온라인 금액     (  CST_TYPE -> O:온라인 M:맴버 N:비회원 )
		   ISNULL(A.LOSS_PRICE,'0')											AS salAmt,	-- 7. 할인금액
		   CASE WHEN A.SALES_TYPE = '3' THEN A.QTY ELSE '0' END				AS refQty,	-- 반품 수량
		   CASE WHEN A.SALES_TYPE = '3' THEN A.REFUND_PRICE ELSE '0' END	AS refAmt,	-- 반품 금액
		   CASE WHEN A.SALES_TYPE = '2' THEN A.QTY ELSE '0' END				AS resQty,	-- 예약 수량
		   CASE WHEN A.SALES_TYPE = '2' THEN A.SELL_PRICE ELSE '0' END		AS resAmt,	-- 예약 금액(완납 기준)
		   CASE WHEN A.SALES_TYPE = '4' THEN A.QTY ELSE '0' END				AS recQty,	-- 예약취소 수량
		   CASE WHEN A.SALES_TYPE = '4' THEN A.REFUND_PRICE ELSE '0' END	AS recAmt,	-- 예약취소 금액
		   A.SALES_TYPE														AS SALES_TYPE,	-- 매출 유형(1:구매 2:예약 3:환불 4:취소)
		   CONVERT(CHAR(7),G.IN_DATE,120)+' '+H.EVENT_NAME					AS EVENT_YN,	-- 행사여부
		   ISNULL(D.ITEM,'')												AS ITEM,		-- 품목
		   D.SEQ								AS D_SEQ,
		   CONVERT(CHAR(7), A.SALES_DATE, 23)	AS SALES_MONTH,
		   I.CD_ITEM							AS I_CD_ITEM
	  FROM TB_SALES_DTL					 A WITH(NOLOCK)
	  LEFT OUTER JOIN TB_STORE			 B WITH(NOLOCK) ON B.STORE_ID = A.STORE_ID
	  LEFT OUTER JOIN TB_MEMBER			 C WITH(NOLOCK) ON C.CST_NO = A.CST_NO
	  LEFT OUTER JOIN TB_PRODUCT		 D WITH(NOLOCK) ON D.SEQ = A.PRO_SEQ
	  LEFT OUTER JOIN TB_BRAND			 E WITH(NOLOCK) ON E.SEQ = D.BRAND_SEQ
	  LEFT OUTER JOIN TB_STORE_MARGIN	 F WITH(NOLOCK) ON F.SEQ = A.MARGIN
	  LEFT OUTER JOIN TB_EVENT_STORE	 G WITH(NOLOCK) ON G.SEQ = A.EVENT_STORE_SEQ
	  LEFT OUTER JOIN TB_EVENT			 H WITH(NOLOCK) ON H.SEQ = G.EVENT_SEQ
	  LEFT JOIN TB_PRODUCT_MAPPING		 I WITH(NOLOCK) ON D.SEQ = I.SEQ
	 WHERE A.SALES_DATE BETWEEN @StrDate AND @EndDate
	   AND ((@P_BRAND_SEQ = '') OR (@P_BRAND_SEQ <> '' AND E.SEQ = @P_BRAND_SEQ))
	   AND ((@P_STORE_SEQ = '') OR (@P_STORE_SEQ <> '' AND B.SEQ = @P_STORE_SEQ))
	   AND (((@P_GUBUN = ''))							-- 전체	      
			OR ((E.ITEM = '1') AND (@P_GUBUN = '1'))	-- 시계
			OR ((E.ITEM = '2') AND (@P_GUBUN = '2'))	-- 쥬얼리
			OR ((E.SEQ IN (126,127,131,170,220)) AND (@P_GUBUN = '3'))) -- 쇼파드
	   AND ((@P_ModelNo = '') OR (@P_ModelNo <> '' AND D.MODEL_NO = @P_ModelNo)) -- 모델명 조회
	   AND (((@P_ITEM = ''))				 -- 전체	      
			OR ((D.ITEM = '1') AND (@P_ITEM = '1'))		-- 시계
			OR ((D.ITEM = '2') AND (@P_ITEM = '2'))		-- 쥬얼리
			OR ((D.ITEM = '3') AND (@P_ITEM = '3'))		-- 잡화
			OR ((D.ITEM = '4') AND (@P_ITEM = '4')))	-- 화장품
) A
	--LEFT JOIN @MM_AMINVL J	-- ERP 원가 정보
	--	ON A.I_CD_ITEM = J.CD_ITEM AND A.SALES_MONTH = J.COST_YM

END  
