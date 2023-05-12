USE WOORIM_230215
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE dbo.MIS_ECOM_SALES_CRM_IF
AS
/******************************************************************************
** File:
** Name: MIS_ECOM_SALES_CRM_IF
**
** Desc: �ڻ�� �������� CRM ����
**
** EXEC dbo.MIS_ECOM_SALES_CRM_IF '','','',''
** This template can be customized: MIS_SALES_MST_CRM_IF
**
** Return values:
**
** Called by: 
**
** Parameters:
** Input Output
** ---------- -----------
**
** Auth: �̻���
** Date: 2022.11.04
*******************************************************************************
** Change History
*******************************************************************************
** Date:		Author:	Description:
** ---------	------	-------------------------------------------
** 2022.11.10	�̻���	CRM ���� Ʈ����� ó�� 
** 2023.04.06	�̻���	����� �ŷ�ó 2��, CRM IF������ RWB�� ���ؼ��� 
						��������� ������ �ǰ��־ 2419�� ��� 2418�� ����ǰ� �ӽ÷� �ϵ��ڵ� 
						INDEX : LSH20230406
*******************************************************************************/
BEGIN TRY
	SET NOCOUNT ON 
	SET XACT_ABORT ON

	BEGIN
		-- �Ϸù�ȣ ����
		DECLARE @IF_SEQ_NO_MIS NUMERIC;				-- CRM I/F �Ϸù�ȣ(MST)
		DECLARE @IF_SEQ_NO_MIS_DTL NUMERIC;			-- CRM I/F �Ϸù�ȣ(DTL)
		DECLARE @IF_TYPE_CD    VARCHAR(10) = 'I';	-- I:INSERT
		DECLARE @SALES_DETAIL_NO_CNT INT;			-- ���� ���� Ȯ��

		-- ���� �߻� �� ERROR ó��
		DECLARE @ERROR_CD  VARCHAR(4),
				@ERROR_MSG VARCHAR(200),
				@ERROR_LOC CHAR(1);


		-- �ֹ� Ŀ���� ����� ���� ����
		DECLARE @P_SALES_NO		  NVARCHAR(100); -- �ֹ���ȣ

			
		-- ��������� 1.MIS ���� ���� (ECOM) CURSOR ���� - �ֹ����� ���������

		BEGIN 
			DECLARE OWNMALL_ORDER_CUR CURSOR STATIC FOR 

			SELECT SALES_NO 
			FROM TB_OWNMALL_ORDER
			WHERE CRM_IF_YN = 'N'
			ORDER BY SEQ ASC
		
			OPEN OWNMALL_ORDER_CUR
			FETCH NEXT FROM OWNMALL_ORDER_CUR INTO @P_SALES_NO
				WHILE 1=1
					BEGIN
						BEGIN TRY
							IF (@@FETCH_STATUS <>0) BREAK;
							
							-- ���� ��ġ SET 
							SET @ERROR_LOC = '1'

							BEGIN DISTRIBUTED TRAN

								-- MIS I/F �Ϸù�ȣ I/F ���� (MST)
								SELECT @IF_SEQ_NO_MIS = (ISNULL(MAX(IF_SEQ_NO), 0) + 1)
								FROM   MISSEC_LINK.MIS_SEC.DBO.IF_MIS_TO_CRM_SALES_MST
								--FROM   MISSEC_LINK.MIS_SEC.DBO.IF_MIS_TO_CRM_SALES_MST_TEST
					
								-- 1-1. MIS IF ���̺� �Է�(�ڻ�� �ֹ� MST)
								INSERT INTO MISSEC_LINK.MIS_SEC.DBO.IF_MIS_TO_CRM_SALES_MST
								--INSERT INTO MISSEC_LINK.MIS_SEC.DBO.IF_MIS_TO_CRM_SALES_MST_TEST
											(IF_SEQ_NO,
												IF_TYPE_CD,
												IF_REG_DT,
												IF_STATUS_CD,
												IF_CMPL_DT,
												IF_ERR_MSG,
												SALES_NO,
												CST_TYPE,
												CST_NO,
												SAVE_POINT,
												USE_POINT,
												AGREE_YN,
												CST_GRD_CD,
												GRD_SALE_AMT,
												BIZ_SALE_AMT,
												COUPON_SALE_AMT,
												DIF_ADJ_AMT,
												DIF_ADJ_REASON,
												NOR_PRICE,
												SELL_PRICE,
												ACT_SELL_PRICE,
												LOSS_PRICE,
												SALES_TYPE,
												DISCOUNT_RATE,
												STORE_ID,
												SALES_DATE,
												REG_DATE,
												TOT_QTY
											)
								SELECT  @IF_SEQ_NO_MIS IF_SEQ_NO,
										@IF_TYPE_CD    IF_TYPE_CD,
										GETDATE()      IF_REG_DT,
										'W'            IF_STATUS_CD,
										NULL           IF_CMPL_DT,
										NULL           IF_ERR_MSG,
										A.SALES_NO,
										A.CST_TYPE,
										A.CST_NO,
										A.SAVE_POINT,
										A.USE_POINT,
										A.AGREE_YN,
										A.CST_GRD_CD,
										A.GRD_SALE_AMT,
										A.BIZ_SALE_AMT,
										A.COUPON_SALE_AMT,
										A.DIF_ADJ_AMT,
										A.DIF_ADJ_REASON,
										A.PRICE  NOR_PRICE, -- �Һ��ڰ�
										A.SELL_PRICE, -- �ǸŰ�
										A.PAY_AMT ACT_SELL_PRICE, -- �����ݾ�
										A.LOSS_PRICE,
										'1' SALES_TYPE, -- �ֹ�����
										A.DISCOUNT_RATE,
										B.STOREID,
										A.PAY_DATE   SALES_DATE, -- ������(�Ǹ�����)
										A.REG_DATE,
										TOT_QTY
								FROM   TB_OWNMALL_ORDER A
											INNER JOIN STORE B ON B.SEQ = CASE WHEN A.STORE_SEQ IN ('2418','2419') THEN '2418' 
																			   ELSE A.STORE_SEQ 
																		   END -- MIS_V_CRM_SHOP_INFO_IF ���̺� 2418�� ��������� ��ϵǾ� �־� �ӽ÷� �ϵ��ڵ� ó��.. ���� �����ڵ� �Ǵ� �ŷ�ó���� �ʿ� .. (LSH20230406)
								WHERE  SALES_NO = @P_SALES_NO
					
								-- INSERT COUNT�� ���� MIS-IF-TABLE �Է� ���� Ȯ��
								IF(@@ROWCOUNT = 0)
									BEGIN 
										SET @ERROR_MSG = '��û�� �������� �����Ͱ� �����ϴ�. (NOCOUNT INSERT IF_MIS_TO_CRM_SALES_MST)' + CHAR(13) + CHAR(10);
										THROW 55555, '@@ROWCOUNT = 0 ERROR', 0; -- CATCH �������� �̵� (THROW ������ �����ڵ�� ū �ǹ̴� ����.)
									END

								-- 1-2. �ڻ�� CRM I/F ���� UPDATE
								UPDATE TB_OWNMALL_ORDER
								SET CRM_IF_YN = 'Y',
									CRM_IF_DATE = GETDATE()
								WHERE  SALES_NO = @P_SALES_NO

								-- UPDATE COUNT�� ���� MIS-IF-TABLE �Է� ���� Ȯ��
								IF(@@ROWCOUNT = 0)
									BEGIN 
										SET @ERROR_MSG = '��û�� �������� �����Ͱ� �����ϴ�.';
										THROW 55555, '@@ROWCOUNT = 0 ERROR', 0; -- CATCH �������� �̵� (THROW ������ �����ڵ�� ū �ǹ̴� ����.)
									END

								-- MIS I/F �Ϸù�ȣ I/F ���� (DTL)
								SELECT @IF_SEQ_NO_MIS_DTL = (ISNULL(MAX(IF_SEQ_NO), 0))
								FROM   MISSEC_LINK.MIS_SEC.DBO.IF_MIS_TO_CRM_SALES_DTL
								--FROM   MISSEC_LINK.MIS_SEC.DBO.IF_MIS_TO_CRM_SALES_DTL_TEST

								-- 1-3. MIS IF ���̺� �Է�(�ڻ�� �ֹ� ��)
								INSERT INTO MISSEC_LINK.MIS_SEC.DBO.IF_MIS_TO_CRM_SALES_DTL
								--INSERT INTO MISSEC_LINK.MIS_SEC.DBO.IF_MIS_TO_CRM_SALES_DTL_TEST
											(IF_SEQ_NO,
												IF_TYPE_CD,
												IF_REG_DT,
												IF_STATUS_CD,
												IF_CMPL_DT,
												IF_ERR_MSG,
												SALES_NO,
												SALES_DETAIL_NO,
												CST_TYPE,
												CST_NO,
												SAVE_POINT,
												USE_POINT,
												AGREE_YN,
												CST_GRD_CD,
												GRD_SALE_AMT,
												BIZ_SALE_AMT,
												COUPON_SALE_AMT,
												DIF_ADJ_AMT,
												DIF_ADJ_REASON,
												NOR_PRICE,
												SELL_PRICE,
												ACT_SELL_PRICE,
												LOSS_PRICE,
												DISCOUNT_RATE,
												SALES_TYPE,
												STORE_ID,
												SALES_DATE,
												PRO_SEQ,
												QTY,
												PAY_TYPE,
												CER_NO,
												EVENT_STORE_SEQ
												)
								SELECT  @IF_SEQ_NO_MIS_DTL + ROW_NUMBER() OVER(ORDER BY A.SEQ) IF_SEQ_NO,
										@IF_TYPE_CD    IF_TYPE_CD,
										GETDATE()      IF_REG_DT,
										'W'            IF_STATUS_CD,
										NULL           IF_CMPL_DT,
										NULL           IF_ERR_MSG,
										A.SALES_NO,
										A.SALES_DETAIL_NO,
										A.CST_TYPE,
										A.CST_NO,
										A.SAVE_POINT,
										A.USE_POINT,
										A.AGREE_YN,
										A.CST_GRD_CD,
										A.GRD_SALE_AMT,
										A.BIZ_SALE_AMT,
										A.COUPON_SALE_AMT,
										A.DIF_ADJ_AMT,
										A.DIF_ADJ_REASON,
										A.PRICE NOR_PRICE, -- �Һ��ڰ�
										A.SELL_PRICE, -- �ǸŰ�
										A.PAY_AMT     AS ACT_SELL_PRICE, -- �����ݾ�
										A.LOSS_PRICE, -- �սǰ�
										A.DISCOUNT_RATE, -- ������
										'1'         AS SALES_TYPE, -- �ֹ�����
										B.STOREID,
										A.PAY_DATE    AS SALES_DATE, -- ������
										A.PRODUCT_SEQ AS PRO_SEQ,-- ��ǰ ����
										A.QTY,
										A.PAY_TYPE,
										NULL CER_NO, -- �ø����ȣ
										A.EVENT_STORE_SEQ
								FROM   TB_OWNMALL_ORDER_DETAIL A 
										INNER JOIN STORE B ON B.SEQ = CASE WHEN A.STORE_SEQ IN ('2418','2419') THEN '2418' 
																		   ELSE A.STORE_SEQ 
																	   END -- MIS_V_CRM_SHOP_INFO_IF ���̺� 2418�� ��������� ��ϵǾ� �־� �ӽ÷� �ϵ��ڵ� ó��.. ���� �����ڵ� �Ǵ� �ŷ�ó���� �ʿ� ..(LSH20230406)
								WHERE  SALES_NO = @P_SALES_NO

								-- INSERT COUNT�� ���� MIS-IF-TABLE �Է� ���� Ȯ��
								IF(@@ROWCOUNT = 0)
									BEGIN 
										SET @ERROR_MSG = '��û�� �������� �����Ͱ� �����ϴ�. (NOCOUNT INSERT IF_MIS_TO_CRM_SALES_DTL)' + CHAR(13) + CHAR(10);
										THROW 55555, '@@ROWCOUNT = 0 ERROR', 0; -- CATCH �������� �̵� (THROW ������ �����ڵ�� ū �ǹ̴� ����.)
									END
					
						COMMIT TRAN
						END TRY	
						BEGIN CATCH

							ROLLBACK TRAN

							PRINT CONVERT(VARCHAR(30),@P_SALES_NO)+' : ���� (LINE : ' + CONVERT(VARCHAR(3), ERROR_LINE()) + ') ' + ERROR_MESSAGE()   
						
							-- CRM ������ ���� �� INSERT�� ����ϰ� CRM_IF_YN�� X�� ǥ�� �Ѵ�. 
							-- ���� �����ǿ� ���� ������ Ȯ�� �� �� ���� ���μ��� �ʿ� 
							UPDATE A
							   SET A.CRM_IF_YN = 'X',
								   A.CRM_IF_DATE = GETDATE(),
								   A.CRM_IF_ERROR_MSG = CASE WHEN ISNULL(@ERROR_MSG,'') <> '' THEN @ERROR_MSG 
															 ELSE ERROR_MESSAGE() 
														 END
							 FROM TB_OWNMALL_ORDER A
							 WHERE A.SALES_NO = @P_SALES_NO

							-- Ŀ���� ���������� �ݱ� 
							IF CURSOR_STATUS('global','OWNMALL_ORDER_CUR') = -1
								DEALLOCATE OWNMALL_ORDER_CUR;
                    
							IF CURSOR_STATUS('global','OWNMALL_ORDER_CUR') = 0
							BEGIN
								CLOSE OWNMALL_ORDER_CUR;
								DEALLOCATE OWNMALL_ORDER_CUR; 
							END                    
						END CATCH

						FETCH NEXT FROM OWNMALL_ORDER_CUR INTO @P_SALES_NO
					END

				CLOSE OWNMALL_ORDER_CUR 
				DEALLOCATE OWNMALL_ORDER_CUR 
				
		END

		-- ��������� 2.MIS ���� ���� (ECOM) CURSOR ���� - ��ǰ���� ���������
		
		BEGIN 
			DECLARE OWNMALL_REFUND_CUR CURSOR STATIC FOR 
			SELECT SALES_NO 
			FROM TB_OWNMALL_ORDER
			WHERE CRM_REFUND_IF_YN = 'N'
			ORDER BY SEQ ASC

			OPEN OWNMALL_REFUND_CUR 
			FETCH NEXT FROM OWNMALL_REFUND_CUR INTO @P_SALES_NO
				WHILE 1=1
					BEGIN
						BEGIN TRY						
							IF (@@FETCH_STATUS <>0) BREAK;
							
							-- ���� ��ġ SET 
							SET @ERROR_LOC = '2'
							
							BEGIN DISTRIBUTED TRAN

								-- MIS I/F �Ϸù�ȣ I/F ���� (MST)
								SELECT @IF_SEQ_NO_MIS = (ISNULL(MAX(IF_SEQ_NO), 0) + 1)
								FROM   MISSEC_LINK.MIS_SEC.DBO.IF_MIS_TO_CRM_SALES_MST
					
								-- 1-1. MIS IF ���̺� �Է�(�ڻ�� �ֹ� MST)
								INSERT INTO MISSEC_LINK.MIS_SEC.DBO.IF_MIS_TO_CRM_SALES_MST
								--INSERT INTO MISSEC_LINK.MIS_SEC.DBO.IF_MIS_TO_CRM_SALES_MST_TEST
											(IF_SEQ_NO,
												IF_TYPE_CD,
												IF_REG_DT,
												IF_STATUS_CD,
												IF_CMPL_DT,
												IF_ERR_MSG,
												SALES_NO,
												CST_TYPE,
												CST_NO,
												SAVE_POINT,
												USE_POINT,
												AGREE_YN,
												CST_GRD_CD,
												GRD_SALE_AMT,
												BIZ_SALE_AMT,
												COUPON_SALE_AMT,
												DIF_ADJ_AMT,
												DIF_ADJ_REASON,
												NOR_PRICE,
												SELL_PRICE,
												ACT_SELL_PRICE,
												LOSS_PRICE,
												SALES_TYPE,
												DISCOUNT_RATE,
												STORE_ID,
												SALES_DATE,
												REG_DATE,
												REFUND_DATE,
												REFUND_REASON,
												REFUND_PRICE,
												REFUND_LOST_PRICE,
												PRICE_CHANGE_REASON,
												ORG_SALES_NO,
												TOT_QTY,
												REFUND_STORE_ID
											)
								SELECT  @IF_SEQ_NO_MIS IF_SEQ_NO,
										@IF_TYPE_CD    IF_TYPE_CD,
										GETDATE()      IF_REG_DT,
										'W'            IF_STATUS_CD,
										NULL           IF_CMPL_DT,
										NULL           IF_ERR_MSG,
										A.REFUND_SALES_NO AS SALES_NO,
										A.CST_TYPE,
										A.CST_NO,
										A.SAVE_POINT,
										A.USE_POINT,
										A.AGREE_YN,
										A.CST_GRD_CD,
										A.GRD_SALE_AMT,
										A.BIZ_SALE_AMT,
										A.COUPON_SALE_AMT,
										A.DIF_ADJ_AMT,
										A.DIF_ADJ_REASON,
										A.PRICE  NOR_PRICE, -- �Һ��ڰ�
										A.SELL_PRICE, -- �ǸŰ�
										A.PAY_AMT ACT_SELL_PRICE, -- �����ݾ�
										A.LOSS_PRICE,
										'3' SALES_TYPE, -- �ֹ�����
										A.DISCOUNT_RATE,
										B.STOREID,
										A.PAY_DATE   SALES_DATE, -- ������(�Ǹ�����)
										A.REG_DATE,
										A.REFUND_DATE,
										A.REFUND_REASON,
										A.REFUND_PRICE,
										A.REFUND_LOST_PRICE,
										A.PRICE_CHANGE_REASON,
										A.SALES_NO AS ORG_SALES_NO,-- ���ֹ���ȣ
										A.TOT_QTY,
										B.STOREID AS REFUND_STORE_ID
								FROM   TB_OWNMALL_ORDER A
											INNER JOIN STORE B ON B.SEQ = CASE WHEN A.STORE_SEQ IN ('2418','2419') THEN '2418' 
																			   ELSE A.STORE_SEQ 
																		   END -- MIS_V_CRM_SHOP_INFO_IF ���̺� 2418�� ��������� ��ϵǾ� �־� �ӽ÷� �ϵ��ڵ� ó��.. ���� �����ڵ� �Ǵ� �ŷ�ó���� �ʿ� ..(LSH20230406)
								WHERE  SALES_NO = @P_SALES_NO

								-- INSERT COUNT�� ���� MIS-IF-TABLE �Է� ���� Ȯ��
								IF(@@ROWCOUNT = 0)
									BEGIN 
										SET @ERROR_MSG = '��û�� �������� �����Ͱ� �����ϴ�. (NOCOUNT INSERT IF_MIS_TO_CRM_SALES_MST)' + CHAR(13) + CHAR(10);
										THROW 55555, '@@ROWCOUNT = 0 ERROR', 0; -- CATCH �������� �̵� (THROW ������ �����ڵ�� ū �ǹ̴� ����.)
									END

								-- 1-2. �ڻ�� CRM I/F ���� UPDATE
								UPDATE TB_OWNMALL_ORDER
								SET CRM_REFUND_IF_YN = 'Y',
									CRM_REFUND_IF_DATE = GETDATE(),
									CRM_REFUND_UPDATE_IF_YN = 'N'
								WHERE  SALES_NO = @P_SALES_NO

								-- UPDATE COUNT�� ���� MIS-IF-TABLE �Է� ���� Ȯ��
								IF(@@ROWCOUNT = 0)
									BEGIN 
										SET @ERROR_MSG = '��û�� �������� �����Ͱ� �����ϴ�. (NOCOUNT UPDATE TB_OWNMALL_ORDER)' + CHAR(13) + CHAR(10);
										THROW 55555, '@@ROWCOUNT = 0 ERROR', 0; -- CATCH �������� �̵� (THROW ������ �����ڵ�� ū �ǹ̴� ����.)
									END
							
								-- MIS I/F �Ϸù�ȣ I/F ���� (DTL)
								SELECT @IF_SEQ_NO_MIS_DTL = (ISNULL(MAX(IF_SEQ_NO), 0))
								FROM   MISSEC_LINK.MIS_SEC.DBO.IF_MIS_TO_CRM_SALES_DTL
						
								-- 1-3. MIS IF ���̺� �Է�(�ڻ�� �ֹ� ��)
								INSERT INTO MISSEC_LINK.MIS_SEC.DBO.IF_MIS_TO_CRM_SALES_DTL
								--INSERT INTO MISSEC_LINK.MIS_SEC.DBO.IF_MIS_TO_CRM_SALES_DTL_TEST
											(IF_SEQ_NO,
												IF_TYPE_CD,
												IF_REG_DT,
												IF_STATUS_CD,
												IF_CMPL_DT,
												IF_ERR_MSG,
												SALES_NO,
												SALES_DETAIL_NO,
												CST_TYPE,
												CST_NO,
												SAVE_POINT,
												USE_POINT,
												AGREE_YN,
												CST_GRD_CD,
												GRD_SALE_AMT,
												BIZ_SALE_AMT,
												COUPON_SALE_AMT,
												DIF_ADJ_AMT,
												DIF_ADJ_REASON,
												NOR_PRICE,
												SELL_PRICE,
												ACT_SELL_PRICE,
												LOSS_PRICE,
												DISCOUNT_RATE,
												SALES_TYPE,
												STORE_ID,
												SALES_DATE,
												PRO_SEQ,
												QTY,
												PAY_TYPE,
												CER_NO,
												EVENT_STORE_SEQ,
												REFUND_DATE,
												REFUND_REASON,
												REFUND_PRICE,
												REFUND_LOST_PRICE,
												REFUND_STORE_ID,
												PRICE_CHANGE_REASON,
												ORG_SALES_NO,
												ORG_SALES_DETAIL_NO
												)
								SELECT  @IF_SEQ_NO_MIS_DTL + ROW_NUMBER() OVER(ORDER BY A.SEQ) IF_SEQ_NO,
										@IF_TYPE_CD    IF_TYPE_CD,
										GETDATE()      IF_REG_DT,
										'W'            IF_STATUS_CD,
										NULL           IF_CMPL_DT,
										NULL           IF_ERR_MSG,
										A.REFUND_SALES_NO AS SALES_NO,
										A.REFUND_SALES_DETAIL_NO AS SALES_DETAIL_NO,
										A.CST_TYPE,
										A.CST_NO,
										A.SAVE_POINT,
										A.USE_POINT,
										A.AGREE_YN,
										A.CST_GRD_CD,
										A.GRD_SALE_AMT,
										A.BIZ_SALE_AMT,
										A.COUPON_SALE_AMT,
										A.DIF_ADJ_AMT,
										A.DIF_ADJ_REASON,
										A.PRICE NOR_PRICE, -- �Һ��ڰ�
										A.SELL_PRICE, -- �ǸŰ�
										A.PAY_AMT     AS ACT_SELL_PRICE, -- �����ݾ�
										A.LOSS_PRICE, -- �սǰ�
										A.DISCOUNT_RATE, -- ������
										'3'           AS SALES_TYPE, -- �ֹ�����
										B.STOREID,
										A.PAY_DATE    AS SALES_DATE, -- ������
										A.PRODUCT_SEQ AS PRO_SEQ,-- ��ǰ ����
										A.QTY,
										A.PAY_TYPE,
										NULL CER_NO, -- �ø����ȣ
										A.EVENT_STORE_SEQ,
										A.REFUND_DATE,
										A.REFUND_REASON,
										A.REFUND_PRICE,
										A.REFUND_LOST_PRICE,
										B.STOREID        AS REFUND_STORE_ID,
										A.PRICE_CHANGE_REASON,
										A.SALES_NO        AS ORG_SALES_NO,
										A.SALES_DETAIL_NO AS ORG_SALES_DETAIL_NO
								FROM   TB_OWNMALL_ORDER_DETAIL A 
										INNER JOIN STORE B ON B.SEQ = CASE WHEN A.STORE_SEQ IN ('2418','2419') THEN '2418' 
																		   ELSE A.STORE_SEQ 
																	   END -- MIS_V_CRM_SHOP_INFO_IF ���̺� 2418�� ��������� ��ϵǾ� �־� �ӽ÷� �ϵ��ڵ� ó��.. ���� �����ڵ� �Ǵ� �ŷ�ó���� �ʿ� ..(LSH20230406)
								WHERE  SALES_NO = @P_SALES_NO
						
								-- UPDATE COUNT�� ���� MIS-IF-TABLE �Է� ���� Ȯ��
								IF(@@ROWCOUNT = 0)
									BEGIN 
										SET @ERROR_MSG = '��û�� �������� �����Ͱ� �����ϴ�. (NOCOUNT INSERT IF_MIS_TO_CRM_SALES_DTL)' + CHAR(13) + CHAR(10);
										THROW 55555, '@@ROWCOUNT = 0 ERROR', 0; -- CATCH �������� �̵� (THROW ������ �����ڵ�� ū �ǹ̴� ����.)
									END

						COMMIT TRAN

						END TRY	
						BEGIN CATCH
			  
							ROLLBACK TRAN

							PRINT CONVERT(VARCHAR(30),@P_SALES_NO)+' : ���� (LINE : ' + CONVERT(VARCHAR(3), ERROR_LINE()) + ') ' + ERROR_MESSAGE()   
						
							-- CRM ������ ���� �� INSERT�� ����ϰ� CRM_IF_YN�� X�� ǥ�� �Ѵ�. 
							-- ���� �����ǿ� ���� ������ Ȯ�� �� �� ���� ���μ��� �ʿ� 
							UPDATE A
							   SET A.CRM_REFUND_IF_YN = 'X',
								   A.CRM_REFUND_IF_DATE = GETDATE(),
								   A.CRM_IF_ERROR_MSG = CASE WHEN ISNULL(@ERROR_MSG,'') <> '' THEN @ERROR_MSG 
															 ELSE ERROR_MESSAGE() 
														 END
							  FROM TB_OWNMALL_ORDER A
							 WHERE A.SALES_NO = @P_SALES_NO

							-- Ŀ���� ���������� �ݱ� 
							IF CURSOR_STATUS('global','OWNMALL_REFUND_CUR') = -1
								DEALLOCATE OWNMALL_REFUND_CUR;
                    
							IF CURSOR_STATUS('global','OWNMALL_REFUND_CUR') > 0
							BEGIN
								CLOSE OWNMALL_REFUND_CUR;
								DEALLOCATE OWNMALL_REFUND_CUR; 
							END                    

						END CATCH

						FETCH NEXT FROM OWNMALL_REFUND_CUR INTO @P_SALES_NO
					END 

			CLOSE OWNMALL_REFUND_CUR 
			DEALLOCATE OWNMALL_REFUND_CUR 
		END

		-- ��������� 3.MIS ���� ���� (ECOM) CURSOR ���� - ȯ������ ���������
		
		BEGIN 
			DECLARE OWNMALL_REFUND_UPDATE_CUR CURSOR STATIC FOR 
			SELECT SALES_NO 
			FROM TB_OWNMALL_ORDER A 
			WHERE CRM_REFUND_IF_YN = 'Y'
				AND CRM_REFUND_UPDATE_IF_YN = 'N'
				-- ��ǰ���� ���� �� UPDATE_IF_YN 'NULL'�̸� �Ʒ� ���� �ʿ� ������..
				AND ISNULL(REFUND_DATE,'') <> '' 
			ORDER BY SEQ ASC
			
			OPEN OWNMALL_REFUND_UPDATE_CUR 
			FETCH NEXT FROM OWNMALL_REFUND_UPDATE_CUR INTO @P_SALES_NO
				WHILE 1=1
					BEGIN
						BEGIN TRY
							IF (@@FETCH_STATUS <>0) BREAK;

							-- ���� ��ġ SET 
							SET @ERROR_LOC = '3'

							BEGIN DISTRIBUTED TRAN
						
								-- �� 1-1. MIS IF ���̺� UPDATE (�ڻ�� �ֹ� MST)
								UPDATE A 
								   SET A.IF_STATUS_CD = 'U',
					   				   A.REFUND_DATE  = B.REFUND_DATE,
					   				   A.REFUND_REASON = B.REFUND_REASON,
					   				   A.REFUND_PRICE = B.REFUND_PRICE,
					   				   A.REFUND_LOST_PRICE = B.REFUND_LOST_PRICE
								  FROM MISSEC_LINK.MIS_SEC.DBO.IF_MIS_TO_CRM_SALES_MST A
								  INNER JOIN TB_OWNMALL_ORDER B ON A.SALES_NO = B.SALES_NO
								  WHERE A.SALES_NO = @P_SALES_NO

								-- UPDATE COUNT�� ���� MIS-IF-TABLE �Է� ���� Ȯ��
								IF(@@ROWCOUNT = 0)
									BEGIN 
										SET @ERROR_MSG = '��û�� �������� �����Ͱ� �����ϴ�. (NOCOUNT INSERT IF_MIS_TO_CRM_SALES_MST)' + CHAR(13) + CHAR(10);
										THROW 55555, '@@ROWCOUNT = 0 ERROR', 0; -- CATCH �������� �̵� (THROW ������ �����ڵ�� ū �ǹ̴� ����.)
									END

								-- �� 1-2. �ڻ�� CRM I/F ���� UPDATE
								UPDATE TB_OWNMALL_ORDER
									SET CRM_REFUND_UPDATE_IF_YN = 'Y',
										CRM_REFUND_UPDATE_IF_DATE = GETDATE()
									WHERE SALES_NO = @P_SALES_NO

								-- UPDATE COUNT�� ���� MIS-IF-TABLE �Է� ���� Ȯ��
								IF(@@ROWCOUNT = 0)
									BEGIN 
										SET @ERROR_MSG = '��û�� �������� �����Ͱ� �����ϴ�. (NOCOUNT UPDATE TB_OWNMALL_ORDER)' + CHAR(13) + CHAR(10);
										THROW 55555, '@@ROWCOUNT = 0 ERROR', 0; -- CATCH �������� �̵� (THROW ������ �����ڵ�� ū �ǹ̴� ����.)
									END 
							
								-- �� 1-3. MIS IF ���̺� UPDATE (�ڻ�� �ֹ� ��)
								UPDATE A 
									SET A.IF_STATUS_CD = 'U',
										A.REFUND_DATE  = B.REFUND_DATE,
										A.REFUND_REASON = B.REFUND_REASON,
										A.REFUND_PRICE = B.REFUND_PRICE,
										A.REFUND_LOST_PRICE = B.REFUND_LOST_PRICE
									FROM MISSEC_LINK.MIS_SEC.DBO.IF_MIS_TO_CRM_SALES_DTL A
									INNER JOIN TB_OWNMALL_ORDER_DETAIL B ON A.SALES_DETAIL_NO = B.SALES_DETAIL_NO
								WHERE A.SALES_NO = @P_SALES_NO

								-- UPDATE COUNT�� ���� MIS-IF-TABLE �Է� ���� Ȯ��
								IF(@@ROWCOUNT = 0)
									BEGIN 
										SET @ERROR_MSG = '��û�� �������� �����Ͱ� �����ϴ�. (NOCOUNT UPDATE IF_MIS_TO_CRM_SALES_DTL)' + CHAR(13) + CHAR(10) ;
										THROW 55555, '@@ROWCOUNT = 0 ERROR', 0; -- CATCH �������� �̵� (THROW ������ �����ڵ�� ū �ǹ̴� ����.)
									END 

						COMMIT TRAN

						END TRY	
						BEGIN CATCH
			  
							ROLLBACK TRAN

							PRINT CONVERT(VARCHAR(30),@P_SALES_NO)+' : ���� (LINE : ' + CONVERT(VARCHAR(3), ERROR_LINE()) + ') ' + ERROR_MESSAGE()   
						
							-- CRM ������ ���� �� INSERT�� ����ϰ� CRM_IF_YN�� X�� ǥ�� �Ѵ�. 
							-- ���� �����ǿ� ���� ������ Ȯ�� �� �� ���� ���μ��� �ʿ� 
							UPDATE A
							   SET A.CRM_REFUND_UPDATE_IF_YN = 'X',
								   A.CRM_REFUND_UPDATE_IF_DATE = GETDATE(),
								   A.CRM_IF_ERROR_MSG = CASE WHEN ISNULL(@ERROR_MSG,'') <> '' THEN @ERROR_MSG 
															 ELSE ERROR_MESSAGE() 
														 END
							  FROM TB_OWNMALL_ORDER A
							 WHERE A.SALES_NO = @P_SALES_NO
                    
							-- Ŀ���� ���������� �ݱ� 
							IF CURSOR_STATUS('global','OWNMALL_REFUND_UPDATE_CUR') = -1
								DEALLOCATE OWNMALL_REFUND_UPDATE_CUR;
                    
							IF CURSOR_STATUS('global','OWNMALL_REFUND_UPDATE_CUR') > 0
							BEGIN
								CLOSE OWNMALL_REFUND_UPDATE_CUR;
								DEALLOCATE OWNMALL_REFUND_UPDATE_CUR; 
							END                    

						END CATCH

						FETCH NEXT FROM OWNMALL_REFUND_UPDATE_CUR INTO @P_SALES_NO
					END 

			CLOSE OWNMALL_REFUND_UPDATE_CUR 
			DEALLOCATE OWNMALL_REFUND_UPDATE_CUR 
		END
	
	
	END

	
	SET XACT_ABORT OFF

END TRY
BEGIN CATCH 

	PRINT     ERROR_PROCEDURE() + CHAR(13) + CHAR(10) 
			+ 'LINE : ' 
			+ CONVERT(VARCHAR(3), ERROR_LINE()) 

	PRINT ERROR_MESSAGE() + CHAR(13) + CHAR(10) + ISNULL(' - ' + @ERROR_MSG + '(' + @ERROR_MSG + ')', '')        

	-- ���� ��ġ�� ���� ���� 'X'ó�� 
	UPDATE A
	   SET A.CRM_IF_YN					= CASE WHEN @ERROR_LOC = '1' THEN 'X' ELSE A.CRM_IF_YN END,
		   A.CRM_IF_DATE				= CASE WHEN @ERROR_LOC = '1' THEN GETDATE() ELSE A.CRM_IF_DATE END,
		   A.CRM_REFUND_IF_YN			= CASE WHEN @ERROR_LOC = '2' THEN 'X' ELSE A.CRM_REFUND_IF_YN END,
		   A.CRM_REFUND_IF_DATE			= CASE WHEN @ERROR_LOC = '2' THEN GETDATE() ELSE A.CRM_REFUND_IF_DATE END,
		   A.CRM_REFUND_UPDATE_IF_YN	= CASE WHEN @ERROR_LOC = '3' THEN 'X' ELSE A.CRM_REFUND_UPDATE_IF_YN END,
		   A.CRM_REFUND_UPDATE_IF_DATE	= CASE WHEN @ERROR_LOC = '3' THEN GETDATE() ELSE A.CRM_REFUND_UPDATE_IF_DATE END,
  		   A.CRM_IF_ERROR_MSG			= CASE WHEN ISNULL(@ERROR_MSG,'') <> '' THEN @ERROR_MSG ELSE ERROR_MESSAGE() END
 	  FROM TB_OWNMALL_ORDER A
	 WHERE A.SALES_NO = @P_SALES_NO			
	
	BEGIN -- Ŀ���� ���������� �ݱ�   
		IF CURSOR_STATUS('global','OWNMALL_ORDER_CUR') > 0
		BEGIN
			CLOSE OWNMALL_ORDER_CUR;
			DEALLOCATE OWNMALL_ORDER_CUR; 
		END 

		IF CURSOR_STATUS('global','OWNMALL_REFUND_CUR') > 0
		BEGIN
			CLOSE OWNMALL_REFUND_CUR;
			DEALLOCATE OWNMALL_REFUND_CUR; 
		END 
			
		IF CURSOR_STATUS('global','OWNMALL_REFUND_UPDATE_CUR') > 0
		BEGIN
			CLOSE OWNMALL_REFUND_UPDATE_CUR;
			DEALLOCATE OWNMALL_REFUND_UPDATE_CUR; 
		END
	END

	-- I/F �Է� ���� �߻���
	RETURN ERROR_MESSAGE() 
END CATCH 

