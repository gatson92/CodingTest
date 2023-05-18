
-- MIS_DAILY_SALES_PRODUCT_LIST_SELECT

DECLARE
 @P_START_DATE			NVARCHAR(20) = '2020-06-20',	-- ������  
 @P_END_DATE			NVARCHAR(20) = '2022-06-21',	-- ������  
 @P_STORE_SEQ			NVARCHAR(10) = '',	-- �����  
 @P_BRAND_SEQ			NVARCHAR(10) = '',	-- �귣���  
 @P_GUBUN			    NVARCHAR(20) = '',	-- �ð� = 1 ,�־� = 2 ,���ĵ� = 3
 @P_ModelNo				NVARCHAR(50) = '', -- �𵨸�
 @P_ITEM				NVARCHAR(20) = ''  -- ǰ�� : �ð� = 1 , �־� = 2 , ��ȭ = 3 , ȭ��ǰ = 4


BEGIN  

	DECLARE @StrDate	SMALLDATETIME,
			@EndDate	SMALLDATETIME

	DECLARE @Query	NVARCHAR(MAX)


	SELECT	@StrDate	= CONVERT(smalldatetime,@P_START_DATE)
		,	@EndDate	= CONVERT(smalldatetime,@P_END_DATE)

	SET @Query = '
--		DECLARE @p_StrDate		SMALLDATETIME
--			,	@p_EndDate		SMALLDATETIME
--			,	@p_BRAND_SEQ	NVARCHAR(10)
--			,	@p_STORE_SEQ	NVARCHAR(10)
--			,	@p_ModelNo		NVARCHAR(50)

		SELECT TOP 10 CONVERT(CHAR(10), A.SALES_DATE, 23)  AS SALES_DATE,	-- ����	
			   ISNULL(B.STORE_NM,'''')				AS STORE_NM,	-- �����
			   ISNULL(C.MEM_NAME,'''')				AS MEM_NAME,	-- ����
			   ISNULL(E.BRAND_NAME,'''')				AS BRAND_NAME,	-- �귣���
			   ISNULL(D.MODEL_NO2,'''')				AS MODEL_NO2,	-- �𵨸�
			   ISNULL(J.UM, 0)						AS COST,		-- ����
			   ISNULL(A.NOR_PRICE, 0)				AS conAmt,		-- �Һ��ڰ�
			   (CASE WHEN ((A.SALES_TYPE = ''1'') AND (ISNULL(A.EVENT_STORE_SEQ,0) = 0) AND (A.CST_TYPE <> ''O''))	THEN A.QTY 
					 ELSE ''0'' END)	AS selQty,		-- 1. �����Ǹ� ����
			   (CASE WHEN ((A.SALES_TYPE = ''1'') AND (ISNULL(A.EVENT_STORE_SEQ,0) = 0) AND (A.CST_TYPE <> ''O''))	THEN A.SELL_PRICE 
					 ELSE ''0'' END)	AS selAmt,		-- 2. �����Ǹ� �ݾ� 		
			   (CASE WHEN ((A.SALES_TYPE = ''1'') AND (ISNULL(A.EVENT_STORE_SEQ,0) <> 0) AND (A.CST_TYPE <> ''O''))	THEN  A.QTY 
					 ELSE ''0'' END)	AS evtQty,		-- 3. ��� ����
			   (CASE WHEN ((A.SALES_TYPE = ''1'') AND (ISNULL(A.EVENT_STORE_SEQ,0) <> 0) AND (A.CST_TYPE <> ''O''))	THEN  A.SELL_PRICE 
					 ELSE ''0'' END)	AS evtAmt,		-- 4. ��� �ݾ�
			   (CASE WHEN ((A.SALES_TYPE = ''1'') AND(A.CST_TYPE = ''O'')) THEN  A.QTY 
					 ELSE ''0'' END)	AS onlQty,		-- 5. �¶��� ����
			   (CASE WHEN ((A.SALES_TYPE = ''1'') AND(A.CST_TYPE = ''O'')) THEN  A.SELL_PRICE 
					 ELSE ''0'' END)	AS onlAmt,		-- 6. �¶��� �ݾ�     (  CST_TYPE -> O:�¶��� M:�ɹ� N:��ȸ�� )
			   ISNULL(A.LOSS_PRICE,''0'')											AS salAmt,	-- 7. ���αݾ�
			   CASE WHEN A.SALES_TYPE = ''3'' THEN A.QTY ELSE ''0'' END				AS refQty,	-- ��ǰ ����
			   CASE WHEN A.SALES_TYPE = ''3'' THEN A.REFUND_PRICE ELSE ''0'' END	AS refAmt,	-- ��ǰ �ݾ�
			   CASE WHEN A.SALES_TYPE = ''2'' THEN A.QTY ELSE ''0'' END				AS resQty,	-- ���� ����
			   CASE WHEN A.SALES_TYPE = ''2'' THEN A.SELL_PRICE ELSE ''0'' END		AS resAmt,	-- ���� �ݾ�(�ϳ� ����)
			   CASE WHEN A.SALES_TYPE = ''4'' THEN A.QTY ELSE ''0'' END				AS recQty,	-- ������� ����
			   CASE WHEN A.SALES_TYPE = ''4'' THEN A.REFUND_PRICE ELSE ''0'' END	AS recAmt,	-- ������� �ݾ�
			   A.SALES_TYPE														AS SALES_TYPE,	-- ���� ����(1:���� 2:���� 3:ȯ�� 4:���)
			   CONVERT(CHAR(7),G.IN_DATE,120)+'' ''+H.EVENT_NAME					AS EVENT_YN,	-- ��翩��
			   ISNULL(D.ITEM,'''')												AS ITEM			-- ǰ��
		  FROM TB_SALES_DTL					 A WITH(NOLOCK)
		  LEFT OUTER JOIN TB_STORE			 B WITH(NOLOCK) ON B.STORE_ID = A.STORE_ID
		  LEFT OUTER JOIN TB_MEMBER			 C WITH(NOLOCK) ON C.CST_NO = A.CST_NO
		  LEFT OUTER JOIN TB_PRODUCT		 D WITH(NOLOCK) ON D.SEQ = A.PRO_SEQ
		  LEFT OUTER JOIN TB_BRAND			 E WITH(NOLOCK) ON E.SEQ = D.BRAND_SEQ
		  LEFT OUTER JOIN TB_STORE_MARGIN	 F WITH(NOLOCK) ON F.SEQ = A.MARGIN
		  LEFT OUTER JOIN TB_EVENT_STORE	 G WITH(NOLOCK) ON G.SEQ = A.EVENT_STORE_SEQ
		  LEFT OUTER JOIN TB_EVENT			 H WITH(NOLOCK) ON H.SEQ = G.EVENT_SEQ
		  LEFT OUTER JOIN MIS_PRODUCT_COST_V J WITH(NOLOCK)	ON D.SEQ = J.PRODUCT_SEQ AND CONVERT(CHAR(7), A.SALES_DATE, 23) = J.COST_YM
		 --WHERE A.SALES_DATE BETWEEN @p_StrDate AND @p_EndDate'

	--IF(@P_GUBUN = '1')	-- �ð� 
	--	SET @Query = 'AND E.ITEM = ''1'''

	--IF(@P_GUBUN = '2')	-- ��� 
	--	SET @Query = 'AND E.ITEM = ''2'''

	--IF(@P_GUBUN = '3')	-- ���ĵ�  
	--	SET @Query = 'E.SEQ IN (126,127,131,170,220)'

	--IF(@P_STORE_SEQ <> '')
	--	SET @Query = 'AND B.SEQ = @p_STORE_SEQ'

	--IF(@P_BRAND_SEQ <> '')
	--	SET @Query = 'AND E.SEQ = @p_BRAND_SEQ'

	--IF(@P_ModelNo <> '')
	--	SET @Query = 'D.MODEL_NO = @p_ModelNo'


	--IF(@P_ITEM = '1')	-- �ð�
	--	SET @Query = 'D.ITEM = ''1'''
	--IF(@P_ITEM = '2')	-- ���
	--	SET @Query = 'D.ITEM = ''2'''
	--IF(@P_ITEM = '3')	-- ��ȭ
	--	SET @Query = 'D.ITEM = ''3'''
	--IF(@P_ITEM = '4')	-- ȭ��ǰ
	--	SET @Query = 'D.ITEM = ''4'''


	EXEC SP_EXECUTESQL @Query--, @p_StrDate = @StrDate, @p_EndDate = @EndDate--, @p_STORE_SEQ = @P_STORE_SEQ, @p_BRAND_SEQ = @P_BRAND_SEQ, @p_ModelNo = @P_ModelNo

END  

