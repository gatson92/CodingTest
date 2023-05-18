
-- MIS_DAILY_SALES_PRODUCT_LIST_SELECT

DECLARE
 @P_START_DATE			 VARCHAR(20) = '2022-06-20',	-- ������  
 @P_END_DATE			 VARCHAR(20) = '2022-06-21',	-- ������  
 @P_STORE_SEQ			 VARCHAR(10) = '',	-- �����  
 @P_BRAND_SEQ			 VARCHAR(10) = '',	-- �귣���  
 @P_GUBUN			     VARCHAR(20) = '',	-- �ð� = 1 ,�־� = 2 ,���ĵ� = 3
 @P_ModelNo				 VARCHAR(50) = '', -- �𵨸�
 @P_ITEM				NVARCHAR(20) = ''  -- ǰ�� : �ð� = 1 , �־� = 2 , ��ȭ = 3 , ȭ��ǰ = 4


BEGIN  

	DECLARE @StrDate	SMALLDATETIME,
			@EndDate	SMALLDATETIME

	SELECT	@StrDate	= CONVERT(smalldatetime,@P_START_DATE)
		,	@EndDate	= CONVERT(smalldatetime,@P_END_DATE)

	DECLARE @TMP TABLE(
						SALES_DATE	CHAR(10),
						STORE_NM	VARCHAR(50),	
						MEM_NAME	VARCHAR(100),	
						BRAND_NAME	VARCHAR(30),	
						MODEL_NO2	VARCHAR(50),	
						conAmt		NUMERIC,		
						selQty		INT,
						selAmt		INT,
						evtQty		INT,
						evtAmt		INT,
						onlQty		INT,
						onlAmt		INT,
						salAmt		INT,
						refQty		INT,
						refAmt		INT,
						resQty		INT,
						resAmt		INT,
						recQty		INT,
						recAmt		INT,
						SALES_TYPE	INT,
						EVENT_YN	VARCHAR(57),
						ITEM		NVARCHAR(20),
						D_MODEL_NO	VARCHAR(50),
						B_SEQ		INT,
						E_SEQ		INT,
						D_SEQ		INT,
						SALES_MONTH VARCHAR(7)

	)

	INSERT INTO @TMP
	SELECT CONVERT(CHAR(10), A.SALES_DATE, 23)  AS SALES_DATE,	-- ����	
		   ISNULL(B.STORE_NM,'')				AS STORE_NM,	-- �����
		   ISNULL(C.MEM_NAME,'')				AS MEM_NAME,	-- ����
		   ISNULL(E.BRAND_NAME,'')				AS BRAND_NAME,	-- �귣���
		   ISNULL(D.MODEL_NO2,'')				AS MODEL_NO2,	-- �𵨸�
		   ISNULL(A.NOR_PRICE, 0)				AS conAmt,		-- �Һ��ڰ�
		   (CASE WHEN ((A.SALES_TYPE = '1') AND (ISNULL(A.EVENT_STORE_SEQ,0) = 0) AND (A.CST_TYPE <> 'O'))	THEN A.QTY ELSE 0 END)			AS selQty,	-- 1. �����Ǹ� ����
		   (CASE WHEN ((A.SALES_TYPE = '1') AND (ISNULL(A.EVENT_STORE_SEQ,0) = 0) AND (A.CST_TYPE <> 'O'))	THEN A.SELL_PRICE ELSE 0 END)	AS selAmt,	-- 2. �����Ǹ� �ݾ� 		
		   (CASE WHEN ((A.SALES_TYPE = '1') AND (ISNULL(A.EVENT_STORE_SEQ,0) <> 0) AND (A.CST_TYPE <> 'O'))	THEN  A.QTY ELSE 0 END)			AS evtQty,	-- 3. ��� ����
		   (CASE WHEN ((A.SALES_TYPE = '1') AND (ISNULL(A.EVENT_STORE_SEQ,0) <> 0) AND (A.CST_TYPE <> 'O'))	THEN  A.SELL_PRICE ELSE 0 END)	AS evtAmt,	-- 4. ��� �ݾ�
		   (CASE WHEN ((A.SALES_TYPE = '1') AND(A.CST_TYPE = 'O')) THEN  A.QTY ELSE 0 END)			AS onlQty,											-- 5. �¶��� ����
		   (CASE WHEN ((A.SALES_TYPE = '1') AND(A.CST_TYPE = 'O')) THEN  A.SELL_PRICE ELSE 0 END)	AS onlAmt,											-- 6. �¶��� �ݾ�     (  CST_TYPE -> O:�¶��� M:�ɹ� N:��ȸ�� )
		   ISNULL(A.LOSS_PRICE,0)											AS salAmt,		-- 7. ���αݾ�
		   CASE WHEN A.SALES_TYPE = '3' THEN A.QTY ELSE 0 END				AS refQty,		-- ��ǰ ����
		   CASE WHEN A.SALES_TYPE = '3' THEN A.REFUND_PRICE ELSE 0 END		AS refAmt,		-- ��ǰ �ݾ�
		   CASE WHEN A.SALES_TYPE = '2' THEN A.QTY ELSE 0 END				AS resQty,		-- ���� ����
		   CASE WHEN A.SALES_TYPE = '2' THEN A.SELL_PRICE ELSE 0 END		AS resAmt,		-- ���� �ݾ�(�ϳ� ����)
		   CASE WHEN A.SALES_TYPE = '4' THEN A.QTY ELSE 0 END				AS recQty,		-- ������� ����
		   CASE WHEN A.SALES_TYPE = '4' THEN A.REFUND_PRICE ELSE 0 END		AS recAmt,		-- ������� �ݾ�
		   A.SALES_TYPE														AS SALES_TYPE,	-- ���� ����(1:���� 2:���� 3:ȯ�� 4:���)
		   CONVERT(CHAR(7),G.IN_DATE,120)+' '+H.EVENT_NAME					AS EVENT_YN,	-- ��翩��
		   ISNULL(D.ITEM,'')												AS ITEM			-- ǰ��
		  ,D.MODEL_NO
		  ,B.SEQ
		  ,E.SEQ
		  ,D.SEQ
		  ,CONVERT(CHAR(7), A.SALES_DATE, 23) AS SALES_MONTH
	  FROM TB_SALES_DTL					 A WITH(NOLOCK) 
	  LEFT OUTER JOIN TB_STORE			 B WITH(NOLOCK) ON B.STORE_ID = A.STORE_ID
	  LEFT OUTER JOIN TB_MEMBER			 C WITH(NOLOCK) ON C.CST_NO = A.CST_NO
	  LEFT OUTER JOIN TB_PRODUCT		 D WITH(NOLOCK) ON D.SEQ = A.PRO_SEQ
	  LEFT OUTER JOIN TB_BRAND			 E WITH(NOLOCK) ON E.SEQ = D.BRAND_SEQ
	  LEFT OUTER JOIN TB_STORE_MARGIN	 F WITH(NOLOCK) ON F.SEQ = A.MARGIN
	  LEFT OUTER JOIN TB_EVENT_STORE	 G WITH(NOLOCK) ON G.SEQ = A.EVENT_STORE_SEQ
	  LEFT OUTER JOIN TB_EVENT			 H WITH(NOLOCK) ON H.SEQ = G.EVENT_SEQ
	 WHERE A.SALES_DATE BETWEEN @StrDate AND @EndDate--(A.SALES_DATE >= @StrDate AND A.SALES_DATE <= @EndDate)


	SELECT 	SALES_DATE	-- ����	
		,	STORE_NM	-- �����
		,	MEM_NAME	-- ����
		,	BRAND_NAME	-- �귣���
		,	MODEL_NO2	-- �𵨸�
		,   ISNULL(B.UM, 0) AS COST	-- ����
		,	conAmt		-- �Һ��ڰ�
		,	selQty		-- �����Ǹ� ����
		,	selAmt		-- �����Ǹ� �ݾ� 		
		,	evtQty		-- ��� ����
		,	evtAmt		-- ��� �ݾ�
		,	onlQty		-- �¶��� ����
		,	onlAmt		-- �¶��� �ݾ�     (  CST_TYPE -> O:�¶��� M:�ɹ� N:��ȸ�� )
		,	salAmt		-- ���αݾ�
		,	refQty		-- ��ǰ ����
		,	refAmt		-- ��ǰ �ݾ�
		,	resQty		-- ���� ����
		,	resAmt		-- ���� �ݾ�(�ϳ� ����)
		,	recQty		-- ������� ����
		,	recAmt		-- ������� �ݾ�
		,	SALES_TYPE	-- ���� ����(1:���� 2:���� 3:ȯ�� 4:���)
		,	EVENT_YN	-- ��翩��
		,	ITEM		-- ǰ��
	FROM @TMP A 
    LEFT JOIN MIS_PRODUCT_COST_V B WITH(NOLOCK) ON A.D_SEQ = B.PRODUCT_SEQ AND A.SALES_MONTH = B.COST_YM
   WHERE (((@P_GUBUN = ''))							-- ��ü	      
     	OR ((ITEM = '1') AND (@P_GUBUN = '1'))	-- �ð�
     	OR ((ITEM = '2') AND (@P_GUBUN = '2'))	-- ���
     	OR ((E_SEQ IN (126,127,131,170,220)) AND (@P_GUBUN = '3'))) -- ���ĵ�
     AND ((@P_STORE_SEQ = '') OR (@P_STORE_SEQ <> '' AND B_SEQ = @P_STORE_SEQ))
	 AND ((@P_BRAND_SEQ = '') OR (@P_BRAND_SEQ <> '' AND E_SEQ = @P_BRAND_SEQ))
     AND ((@P_ModelNo = '') OR (@P_ModelNo <> '' AND D_MODEL_NO = @P_ModelNo)) -- �𵨸� ��ȸ
     AND (((@P_ITEM = ''))				 -- ��ü	      
     	OR ((ITEM = '1') AND (@P_ITEM = '1'))		-- �ð�
     	OR ((ITEM = '2') AND (@P_ITEM = '2'))		-- ���
     	OR ((ITEM = '3') AND (@P_ITEM = '3'))		-- ��ȭ
     	OR ((ITEM = '4') AND (@P_ITEM = '4')))	-- ȭ��ǰ


END  


