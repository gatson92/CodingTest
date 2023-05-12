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
** Desc: 자사몰 주문발생시 재고 선점 
**
** This template can be customized : sp_helptext psj_HQLogDeliveryStoreNew1108_order
**
** Auth: 이상현
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

    DECLARE @HQ_QTY		SMALLINT, -- 본사 재고
			@ORDER_QTY	SMALLINT  -- 주문 재고

	DECLARE @TMP_OWN_INV TABLE
	(	NUM			SMALLINT,		-- 1.  STORE별 순번
		IF_SEQ		INT,			-- 2.  [LEADER_ORDER_IF] SEQ
		PRO_SEQ		INT,			-- 3.  [PRODUCT] SEQ
		STORE_SEQ	INT,			-- 4.  [STORE] SEQ
		BRAND_SEQ	INT,			-- 5.  [BRAND] SEQ
		MODEL_NO	VARCHAR(200),	-- 6.  제품코드
		DEL_NO		CHAR(9),		-- 7.  배송번호
		RI_QTY		SMALLINT,		-- 8.  실제 재고
		ORD_QTY		SMALLINT,		-- 9.  주문 수량
		REMAIN_QTY	SMALLINT,		-- 10. 재고여분 (실재고 - 주문수량)
		PAY_AMT		INT,			-- 11. 결제금액
		NOTE		VARCHAR(1000)	-- 12. 수신자 + ' ' + 배송메시지
		
	)

	SET @TODAY = CONVERT(VARCHAR(8),GETDATE(),112)

	--### 1. @TMP_OWN_INV에 신규 주문들에 대한 정보 INSERT
	INSERT INTO @TMP_OWN_INV (IF_SEQ, PRO_SEQ, STORE_SEQ, BRAND_SEQ, MODEL_NO, DEL_NO, RI_QTY, ORD_QTY, REMAIN_QTY, PAY_AMT, NOTE)
	SELECT A.SEQ				AS IF_SEQ
		 , C.SEQ				AS PRO_SEQ
		 , A.STORE_SEQ			AS STORE_SEQ
		 , A.BRAND_SEQ			AS BRAND_SEQ
		 , B.MODELNO			AS MODEL_NO
		 , CONVERT(VARCHAR(8), @TODAY, 112) + 
		   RIGHT('000' + CAST(ROW_NUMBER() OVER (ORDER BY A.STORE_SEQ) - 1 AS VARCHAR(3)), 3) AS DEL_NO	-- DEL번호 생성
		 , B.RI_QTY				AS RI_QTY
		 , SUM(A.QTY)			AS ORD_QTY
		 , B.RI_QTY-SUM(A.QTY)	AS REMAIN_QTY
		 , A.PAY_AMT			AS PAY_AMT
		 , RECEIVER_NM + ' ' + DELIVER_MSG	AS NOTE
	  FROM LEADER_ORDER_IF A -- 실제 적용 시 INSERTED로 대체 필요
	 INNER JOIN LEADER_V_INV	B WITH(NOLOCK) ON A.MODEL_NO = B.MODELNO 
	 INNER JOIN PRODUCT			C WITH(NOLOCK) ON A.MODEL_NO = C.ERP_CD_ITEM
	 WHERE B.RI_QTY > 0
	 GROUP BY A.SEQ, C.SEQ, A.STORE_SEQ, A.BRAND_SEQ, B.MODELNO, B.RI_QTY, A.QTY, A.PAY_AMT, A.RECEIVER_NM, A.DELIVER_MSG
	 
	--### 2. STORE별 NUM 생성하여 UPDATE 
	UPDATE T1
	   SET T1.NUM = T2.NEW_NUM
	  FROM @TMP_OWN_INV T1
	 INNER JOIN ( SELECT IF_SEQ
					   , ROW_NUMBER() OVER (PARTITION BY STORE_SEQ ORDER BY NUM) AS NEW_NUM 
					FROM @TMP_OWN_INV 
				) T2 ON T1.IF_SEQ = T2.IF_SEQ

	--### 3. 자사몰 재고 선점 및 본사재고 차감

	IF EXISTS (SELECT 1 FROM @TMP_OWN_INV)
		BEGIN
			--## 3-1. 실재고 > 주문재고 


			--# 1. 자사몰 재고 선점
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
			
			--# 2. 배송 상세정보 입력(배송SEQ, 상품SEQ, 수량, 총금액, 배송정보, 거래처별순번, SHMALL_SEQ )
			INSERT INTO DELIVERYDETAIL (DELSEQ, PROSEQ, QTY,TOTAL, NOTE, NUM, SERIAL)   
			SELECT D.SEQ							-- 1. DELIVERY SEQ
				 , A.PRO_SEQ						-- 2. PRODUCT SEQ
				 , A.ORD_QTY						-- 3. 자사몰 주문재고 
				 , A.PAY_AMT						-- 4. 결제금액
				 , A.NOTE							-- 5. 비고( 수신자명 + ' ' + 배송메시지 )
				 , A.NUM							-- 6. STORE별 순번
				 , ISNULL(O.ECOM_ORDER_SEQ,'')		-- 7. SHMALL SEQ
			  FROM @TMP_OWN_INV			A
		     INNER JOIN DELIVERY		D WITH(NOLOCK) ON D.DELNO = A.DEL_NO AND D.STORESEQ = A.STORE_SEQ
			  LEFT JOIN OWNMALL_ORDER	O WITH(NOLOCK) ON A.IF_SEQ = O.ORDER_IF_SEQ
			 WHERE A.REMAIN_QTY > 0

			--# 3. 본사재고 차감
			UPDATE HQINVENTORY
			   SET QTY = A.QTY - B.ORD_QTY
			  FROM HQINVENTORY A 
			 INNER JOIN @TMP_OWN_INV  B  ON A.PROSEQ = B.PRO_SEQ
			 WHERE B.REMAIN_QTY > 0


			--## 3-2. 실재고 < 주문재고 


			--# 1. 자사몰 재고 선점
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

			--# 2. 배송 상세정보 입력(배송SEQ, 상품SEQ, 수량, 총금액, 배송정보, 거래처별순번, SHMALL_SEQ )
			INSERT INTO DELIVERYDETAIL (DELSEQ, PROSEQ, QTY,TOTAL, NOTE, NUM, SERIAL)   
			SELECT D.SEQ						-- 1. DELIVERY SEQ
				 , A.PRO_SEQ					-- 2. PRODUCT SEQ
				 , A.RI_QTY						-- 3. 본사창고의 실재고 
				 , A.PAY_AMT					-- 4. 결제금액
				 , A.NOTE						-- 5. 비고( 수신자명 + ' ' + 배송메시지 )
				 , A.NUM						-- 6. STORE별 순번
				 , ISNULL(O.ECOM_ORDER_SEQ,'')	-- 7. SHMALL SEQ
			  FROM @TMP_OWN_INV			A
			  LEFT JOIN OWNMALL_ORDER	O WITH(NOLOCK) ON A.IF_SEQ = O.ORDER_IF_SEQ
		     INNER JOIN DELIVERY		D WITH(NOLOCK) ON D.DELNO = A.DEL_NO AND D.STORESEQ = A.STORE_SEQ
			 WHERE A.REMAIN_QTY < 1

			--# 3. 본사재고 0으로 차감 
			UPDATE HQINVENTORY
			   SET QTY = 0
			  FROM HQINVENTORY A 
			 INNER JOIN @TMP_OWN_INV  B  ON A.PROSEQ = B.PRO_SEQ
			 WHERE B.REMAIN_QTY < 1
			   AND A.QTY > 0


		END

END;

