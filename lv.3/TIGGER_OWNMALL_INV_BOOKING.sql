USE WOORIM_230215
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[TRIGGER_OWNMALL_INV_BOOKING]
--CREATE TRIGGER [dbo].[TRIGGER_OWNMALL_INV_BOOKING]
--    ON [dbo].[LEADER_ORDER_IF]
-- AFTER INSERT --, UPDATE, DELETE
/******************************************************************************
** File:
** Name: TIGGER_OWNMALL_INV_BOOKING
**
** Desc: �ڻ�� �ֹ��߻��� ��� ���� 
**
** This template can be customized : sp_helptext psj_HQLogDeliveryStoreNew1108_order
**
** Auth: �̻���
** Date: 2022.04.18
*******************************************************************************
** Change History
*******************************************************************************
** Date:		Author:	Description:
** ---------	------	-----------------
*******************************************************************************/
AS

SET NOCOUNT ON;

BEGIN
	DECLARE @TODAY		VARCHAR (8)

    DECLARE @HQ_QTY		SMALLINT, -- ���� ���
			@ORDER_QTY	SMALLINT  -- �ֹ� ���

	DECLARE @TMP_OWN_INV TABLE
	(	NUM			SMALLINT,		-- 1.  STORE�� ����
		IF_SEQ		INT,			-- 2.  [LEADER_ORDER_IF] SEQ
		PRO_SEQ		INT,			-- 3.  [PRODUCT] SEQ
		STORE_SEQ	INT,			-- 4.  [STORE] SEQ
		BRAND_SEQ	INT,			-- 5.  [BRAND] SEQ
		MODEL_NO	VARCHAR(200),	-- 6.  ��ǰ�ڵ�
		DEL_NO		CHAR(9),		-- 7.  ��۹�ȣ
		RI_QTY		SMALLINT,		-- 8.  ���� ���
		ORD_QTY		SMALLINT,		-- 9.  �ֹ� ����
		REMAIN_QTY	SMALLINT,		-- 10. ����� (����� - �ֹ�����)
		PAY_AMT		INT,			-- 11. �����ݾ�
		NOTE		VARCHAR(1000)	-- 12. ������ + ' ' + ��۸޽���
		
	)

	SET @TODAY = CONVERT(VARCHAR(8),GETDATE(),112)

	--### 1. @TMP_OWN_INV�� �ű� �ֹ��鿡 ���� ���� INSERT
	INSERT INTO @TMP_OWN_INV (IF_SEQ, PRO_SEQ, STORE_SEQ, BRAND_SEQ, MODEL_NO, DEL_NO, RI_QTY, ORD_QTY, REMAIN_QTY, PAY_AMT, NOTE)
	SELECT A.SEQ				AS IF_SEQ
		 , C.SEQ				AS PRO_SEQ
		 , A.STORE_SEQ			AS STORE_SEQ
		 , A.BRAND_SEQ			AS BRAND_SEQ
		 , B.MODELNO			AS MODEL_NO
		 , CONVERT(VARCHAR(8), @TODAY, 112) + 
		   RIGHT('000' + CAST(ROW_NUMBER() OVER (ORDER BY A.STORE_SEQ) - 1 AS VARCHAR(3)), 3) AS DEL_NO	-- DEL��ȣ ����
		 , B.RI_QTY				AS RI_QTY
		 , SUM(A.QTY)			AS ORD_QTY
		 , B.RI_QTY-SUM(A.QTY)	AS REMAIN_QTY
		 , A.PAY_AMT			AS PAY_AMT
		 , RECEIVER_NM + ' ' + DELIVER_MSG	AS NOTE
	  FROM LEADER_ORDER_IF A -- ���� ���� �� INSERTED�� ��ü �ʿ�
	 INNER JOIN LEADER_V_INV	B WITH(NOLOCK) ON A.MODEL_NO = B.MODELNO 
	 INNER JOIN PRODUCT			C WITH(NOLOCK) ON A.MODEL_NO = C.ERP_CD_ITEM
	 WHERE B.RI_QTY > 0
	 GROUP BY A.SEQ, C.SEQ, A.STORE_SEQ, A.BRAND_SEQ, B.MODELNO, B.RI_QTY, A.QTY, A.PAY_AMT, A.RECEIVER_NM, A.DELIVER_MSG
	 
	--### 2. STORE�� NUM �����Ͽ� UPDATE 
	UPDATE T1
	   SET T1.NUM = T2.NEW_NUM
	  FROM @TMP_OWN_INV T1
	 INNER JOIN ( SELECT IF_SEQ
					   , ROW_NUMBER() OVER (PARTITION BY STORE_SEQ ORDER BY NUM) AS NEW_NUM 
					FROM @TMP_OWN_INV 
				) T2 ON T1.IF_SEQ = T2.IF_SEQ

	--### 3. �ڻ�� ��� ���� �� ������� ����

	IF EXISTS (SELECT 1 FROM @TMP_OWN_INV)
		BEGIN
			--## 3-1. ����� > �ֹ���� 


			--# 1. �ڻ�� ��� ����
			INSERT INTO  DELIVERY (STORESEQ, ITEM, CATEGORY, BRANDSEQ, DELDATE,DELNO, TYPE, REGUSER)  
			SELECT A.STORE_SEQ, 
				   C.[NAME] AS ITEM,
				   1,						-- SELECT * FROM CODEBOOK WHERE CODE = 'CATEGORY'
				   A.BRAND_SEQ,						
				   CONVERT(CHAR(10),GETDATE(),120),
				   A.DEL_NO,
				   S.TYPE,
				   'SYSTEM'  
			  FROM @TMP_OWN_INV		A
			 INNER JOIN PRODUCT		P WITH(NOLOCK) ON A.MODEL_NO = P.ERP_CD_ITEM
			 INNER JOIN STORE		S WITH(NOLOCK) ON A.STORE_SEQ = S.SEQ
			  LEFT JOIN CODEBOOK 	C WITH(NOLOCK) ON P.ERP_CLS_L = C.VALUE 
			 WHERE S.ACTIVE = 'A'  
			   AND REMAIN_QTY > 0
			   AND C.CODE = 'ERP_GRP_MFG'
			
			--# 2. ��� ������ �Է�(���SEQ, ��ǰSEQ, ����, �ѱݾ�, �������, �ŷ�ó������, SHMALL_SEQ )
			INSERT INTO DELIVERYDETAIL (DELSEQ, PROSEQ, QTY,TOTAL, NOTE, NUM, SERIAL)   
			SELECT D.SEQ							-- 1. DELIVERY SEQ
				 , A.PRO_SEQ						-- 2. PRODUCT SEQ
				 , A.ORD_QTY						-- 3. �ڻ�� �ֹ���� 
				 , A.PAY_AMT						-- 4. �����ݾ�
				 , A.NOTE							-- 5. ���( �����ڸ� + ' ' + ��۸޽��� )
				 , A.NUM							-- 6. STORE�� ����
				 , ISNULL(O.ECOM_ORDER_SEQ,'')		-- 7. SHMALL SEQ
			  FROM @TMP_OWN_INV			A
		     INNER JOIN DELIVERY		D WITH(NOLOCK) ON D.DELNO = A.DEL_NO AND D.STORESEQ = A.STORE_SEQ
			  LEFT JOIN OWNMALL_ORDER	O WITH(NOLOCK) ON A.IF_SEQ = O.ORDER_IF_SEQ
			 WHERE A.REMAIN_QTY > 0

			--# 3. ������� ����
			UPDATE HQINVENTORY
			   SET QTY = A.QTY - B.ORD_QTY
			  FROM HQINVENTORY A 
			 INNER JOIN @TMP_OWN_INV  B  ON A.PROSEQ = B.PRO_SEQ
			 WHERE B.REMAIN_QTY > 0


			--## 3-2. ����� < �ֹ���� 


			--# 1. �ڻ�� ��� ����
			INSERT INTO  DELIVERY (STORESEQ, ITEM, CATEGORY, BRANDSEQ, DELDATE,DELNO, TYPE, REGUSER)  
			SELECT A.STORE_SEQ, 
				   C.[NAME] AS ITEM,
				   1,				-- SELECT * FROM CODEBOOK WHERE CODE = 'CATEGORY'
				   A.BRAND_SEQ,
				   CONVERT(CHAR(10),GETDATE(),120),
				   A.DEL_NO,
				   S.TYPE,
				   'SYSTEM'  
			  FROM @TMP_OWN_INV A
			 INNER JOIN PRODUCT		P WITH(NOLOCK) ON A.MODEL_NO = P.ERP_CD_ITEM
			 INNER JOIN STORE		S WITH(NOLOCK) ON A.STORE_SEQ = S.SEQ  
			  LEFT JOIN CODEBOOK	C WITH(NOLOCK) ON P.ERP_CLS_L = C.VALUE 
			 WHERE S.ACTIVE = 'A'  
			   AND A.REMAIN_QTY < 1
			   AND C.CODE = 'ERP_GRP_MFG'

			--# 2. ��� ������ �Է�(���SEQ, ��ǰSEQ, ����, �ѱݾ�, �������, �ŷ�ó������, SHMALL_SEQ )
			INSERT INTO DELIVERYDETAIL (DELSEQ, PROSEQ, QTY,TOTAL, NOTE, NUM, SERIAL)   
			SELECT D.SEQ						-- 1. DELIVERY SEQ
				 , A.PRO_SEQ					-- 2. PRODUCT SEQ
				 , A.RI_QTY						-- 3. ����â���� ����� 
				 , A.PAY_AMT					-- 4. �����ݾ�
				 , A.NOTE						-- 5. ���( �����ڸ� + ' ' + ��۸޽��� )
				 , A.NUM						-- 6. STORE�� ����
				 , ISNULL(O.ECOM_ORDER_SEQ,'')	-- 7. SHMALL SEQ
			  FROM @TMP_OWN_INV			A
			  LEFT JOIN OWNMALL_ORDER	O WITH(NOLOCK) ON A.IF_SEQ = O.ORDER_IF_SEQ
		     INNER JOIN DELIVERY		D WITH(NOLOCK) ON D.DELNO = A.DEL_NO AND D.STORESEQ = A.STORE_SEQ
			 WHERE A.REMAIN_QTY < 1

			--# 3. ������� 0���� ���� 
			UPDATE HQINVENTORY
			   SET QTY = 0
			  FROM HQINVENTORY A 
			 INNER JOIN @TMP_OWN_INV  B  ON A.PROSEQ = B.PRO_SEQ
			 WHERE B.REMAIN_QTY < 1
			   AND A.QTY > 0


		END

END;

