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
** Desc: 자사몰 매출정보 CRM 연동
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
** Auth: 이상현
** Date: 2022.11.04
*******************************************************************************
** Change History
*******************************************************************************
** Date:		Author:	Description:
** ---------	------	-------------------------------------------
** 2022.11.10	이상현	CRM 연동 트랜잭션 처리 
** 2023.04.06	이상현	로즈몽 거래처 2개, CRM IF에서는 RWB에 대해서만 
						로즈몽으로 구분이 되고있어서 2419인 경우 2418로 변경되게 임시로 하드코딩 
						INDEX : LSH20230406
*******************************************************************************/
BEGIN TRY
	SET NOCOUNT ON 
	SET XACT_ABORT ON

	BEGIN
		-- 일련번호 변수
		DECLARE @IF_SEQ_NO_MIS NUMERIC;				-- CRM I/F 일련번호(MST)
		DECLARE @IF_SEQ_NO_MIS_DTL NUMERIC;			-- CRM I/F 일련번호(DTL)
		DECLARE @IF_TYPE_CD    VARCHAR(10) = 'I';	-- I:INSERT
		DECLARE @SALES_DETAIL_NO_CNT INT;			-- 매출 정보 확인

		-- 오류 발생 시 ERROR 처리
		DECLARE @ERROR_CD  VARCHAR(4),
				@ERROR_MSG VARCHAR(200),
				@ERROR_LOC CHAR(1);


		-- 주문 커서에 사용할 변수 선언
		DECLARE @P_SALES_NO		  NVARCHAR(100); -- 주문번호

			
		-- ■□■□■□■□ 1.MIS 매출 정보 (ECOM) CURSOR 정의 - 주문정보 ■□■□■□■□

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
							
							-- 오류 위치 SET 
							SET @ERROR_LOC = '1'

							BEGIN DISTRIBUTED TRAN

								-- MIS I/F 일련번호 I/F 세팅 (MST)
								SELECT @IF_SEQ_NO_MIS = (ISNULL(MAX(IF_SEQ_NO), 0) + 1)
								FROM   MISSEC_LINK.MIS_SEC.DBO.IF_MIS_TO_CRM_SALES_MST
								--FROM   MISSEC_LINK.MIS_SEC.DBO.IF_MIS_TO_CRM_SALES_MST_TEST
					
								-- 1-1. MIS IF 테이블 입력(자사몰 주문 MST)
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
										A.PRICE  NOR_PRICE, -- 소비자가
										A.SELL_PRICE, -- 판매가
										A.PAY_AMT ACT_SELL_PRICE, -- 결제금액
										A.LOSS_PRICE,
										'1' SALES_TYPE, -- 주문정보
										A.DISCOUNT_RATE,
										B.STOREID,
										A.PAY_DATE   SALES_DATE, -- 결제일(판매일자)
										A.REG_DATE,
										TOT_QTY
								FROM   TB_OWNMALL_ORDER A
											INNER JOIN STORE B ON B.SEQ = CASE WHEN A.STORE_SEQ IN ('2418','2419') THEN '2418' 
																			   ELSE A.STORE_SEQ 
																		   END -- MIS_V_CRM_SHOP_INFO_IF 테이블에 2418만 로즈몽으로 등록되어 있어 임시로 하드코딩 처리.. 추후 공통코드 또는 거래처통일 필요 .. (LSH20230406)
								WHERE  SALES_NO = @P_SALES_NO
					
								-- INSERT COUNT를 통해 MIS-IF-TABLE 입력 여부 확인
								IF(@@ROWCOUNT = 0)
									BEGIN 
										SET @ERROR_MSG = '요청한 정보수정 데이터가 없습니다. (NOCOUNT INSERT IF_MIS_TO_CRM_SALES_MST)' + CHAR(13) + CHAR(10);
										THROW 55555, '@@ROWCOUNT = 0 ERROR', 0; -- CATCH 구문으로 이동 (THROW 구문의 오류코드는 큰 의미는 없다.)
									END

								-- 1-2. 자사몰 CRM I/F 여부 UPDATE
								UPDATE TB_OWNMALL_ORDER
								SET CRM_IF_YN = 'Y',
									CRM_IF_DATE = GETDATE()
								WHERE  SALES_NO = @P_SALES_NO

								-- UPDATE COUNT를 통해 MIS-IF-TABLE 입력 여부 확인
								IF(@@ROWCOUNT = 0)
									BEGIN 
										SET @ERROR_MSG = '요청한 정보수정 데이터가 없습니다.';
										THROW 55555, '@@ROWCOUNT = 0 ERROR', 0; -- CATCH 구문으로 이동 (THROW 구문의 오류코드는 큰 의미는 없다.)
									END

								-- MIS I/F 일련번호 I/F 세팅 (DTL)
								SELECT @IF_SEQ_NO_MIS_DTL = (ISNULL(MAX(IF_SEQ_NO), 0))
								FROM   MISSEC_LINK.MIS_SEC.DBO.IF_MIS_TO_CRM_SALES_DTL
								--FROM   MISSEC_LINK.MIS_SEC.DBO.IF_MIS_TO_CRM_SALES_DTL_TEST

								-- 1-3. MIS IF 테이블 입력(자사몰 주문 상세)
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
										A.PRICE NOR_PRICE, -- 소비자가
										A.SELL_PRICE, -- 판매가
										A.PAY_AMT     AS ACT_SELL_PRICE, -- 결제금액
										A.LOSS_PRICE, -- 손실가
										A.DISCOUNT_RATE, -- 할인율
										'1'         AS SALES_TYPE, -- 주문정보
										B.STOREID,
										A.PAY_DATE    AS SALES_DATE, -- 결제일
										A.PRODUCT_SEQ AS PRO_SEQ,-- 상품 순번
										A.QTY,
										A.PAY_TYPE,
										NULL CER_NO, -- 시리얼번호
										A.EVENT_STORE_SEQ
								FROM   TB_OWNMALL_ORDER_DETAIL A 
										INNER JOIN STORE B ON B.SEQ = CASE WHEN A.STORE_SEQ IN ('2418','2419') THEN '2418' 
																		   ELSE A.STORE_SEQ 
																	   END -- MIS_V_CRM_SHOP_INFO_IF 테이블에 2418만 로즈몽으로 등록되어 있어 임시로 하드코딩 처리.. 추후 공통코드 또는 거래처통일 필요 ..(LSH20230406)
								WHERE  SALES_NO = @P_SALES_NO

								-- INSERT COUNT를 통해 MIS-IF-TABLE 입력 여부 확인
								IF(@@ROWCOUNT = 0)
									BEGIN 
										SET @ERROR_MSG = '요청한 정보수정 데이터가 없습니다. (NOCOUNT INSERT IF_MIS_TO_CRM_SALES_DTL)' + CHAR(13) + CHAR(10);
										THROW 55555, '@@ROWCOUNT = 0 ERROR', 0; -- CATCH 구문으로 이동 (THROW 구문의 오류코드는 큰 의미는 없다.)
									END
					
						COMMIT TRAN
						END TRY	
						BEGIN CATCH

							ROLLBACK TRAN

							PRINT CONVERT(VARCHAR(30),@P_SALES_NO)+' : 실패 (LINE : ' + CONVERT(VARCHAR(3), ERROR_LINE()) + ') ' + ERROR_MESSAGE()   
						
							-- CRM 연동중 오류 시 INSERT를 취소하고 CRM_IF_YN을 X로 표시 한다. 
							-- 추후 오류건에 대해 관리자 확인 후 재 연동 프로세스 필요 
							UPDATE A
							   SET A.CRM_IF_YN = 'X',
								   A.CRM_IF_DATE = GETDATE(),
								   A.CRM_IF_ERROR_MSG = CASE WHEN ISNULL(@ERROR_MSG,'') <> '' THEN @ERROR_MSG 
															 ELSE ERROR_MESSAGE() 
														 END
							 FROM TB_OWNMALL_ORDER A
							 WHERE A.SALES_NO = @P_SALES_NO

							-- 커서가 열려있으면 닫기 
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

		-- ■□■□■□■□ 2.MIS 매출 정보 (ECOM) CURSOR 정의 - 반품정보 ■□■□■□■□
		
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
							
							-- 오류 위치 SET 
							SET @ERROR_LOC = '2'
							
							BEGIN DISTRIBUTED TRAN

								-- MIS I/F 일련번호 I/F 세팅 (MST)
								SELECT @IF_SEQ_NO_MIS = (ISNULL(MAX(IF_SEQ_NO), 0) + 1)
								FROM   MISSEC_LINK.MIS_SEC.DBO.IF_MIS_TO_CRM_SALES_MST
					
								-- 1-1. MIS IF 테이블 입력(자사몰 주문 MST)
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
										A.PRICE  NOR_PRICE, -- 소비자가
										A.SELL_PRICE, -- 판매가
										A.PAY_AMT ACT_SELL_PRICE, -- 결제금액
										A.LOSS_PRICE,
										'3' SALES_TYPE, -- 주문정보
										A.DISCOUNT_RATE,
										B.STOREID,
										A.PAY_DATE   SALES_DATE, -- 결제일(판매일자)
										A.REG_DATE,
										A.REFUND_DATE,
										A.REFUND_REASON,
										A.REFUND_PRICE,
										A.REFUND_LOST_PRICE,
										A.PRICE_CHANGE_REASON,
										A.SALES_NO AS ORG_SALES_NO,-- 원주문번호
										A.TOT_QTY,
										B.STOREID AS REFUND_STORE_ID
								FROM   TB_OWNMALL_ORDER A
											INNER JOIN STORE B ON B.SEQ = CASE WHEN A.STORE_SEQ IN ('2418','2419') THEN '2418' 
																			   ELSE A.STORE_SEQ 
																		   END -- MIS_V_CRM_SHOP_INFO_IF 테이블에 2418만 로즈몽으로 등록되어 있어 임시로 하드코딩 처리.. 추후 공통코드 또는 거래처통일 필요 ..(LSH20230406)
								WHERE  SALES_NO = @P_SALES_NO

								-- INSERT COUNT를 통해 MIS-IF-TABLE 입력 여부 확인
								IF(@@ROWCOUNT = 0)
									BEGIN 
										SET @ERROR_MSG = '요청한 정보수정 데이터가 없습니다. (NOCOUNT INSERT IF_MIS_TO_CRM_SALES_MST)' + CHAR(13) + CHAR(10);
										THROW 55555, '@@ROWCOUNT = 0 ERROR', 0; -- CATCH 구문으로 이동 (THROW 구문의 오류코드는 큰 의미는 없다.)
									END

								-- 1-2. 자사몰 CRM I/F 여부 UPDATE
								UPDATE TB_OWNMALL_ORDER
								SET CRM_REFUND_IF_YN = 'Y',
									CRM_REFUND_IF_DATE = GETDATE(),
									CRM_REFUND_UPDATE_IF_YN = 'N'
								WHERE  SALES_NO = @P_SALES_NO

								-- UPDATE COUNT를 통해 MIS-IF-TABLE 입력 여부 확인
								IF(@@ROWCOUNT = 0)
									BEGIN 
										SET @ERROR_MSG = '요청한 정보수정 데이터가 없습니다. (NOCOUNT UPDATE TB_OWNMALL_ORDER)' + CHAR(13) + CHAR(10);
										THROW 55555, '@@ROWCOUNT = 0 ERROR', 0; -- CATCH 구문으로 이동 (THROW 구문의 오류코드는 큰 의미는 없다.)
									END
							
								-- MIS I/F 일련번호 I/F 세팅 (DTL)
								SELECT @IF_SEQ_NO_MIS_DTL = (ISNULL(MAX(IF_SEQ_NO), 0))
								FROM   MISSEC_LINK.MIS_SEC.DBO.IF_MIS_TO_CRM_SALES_DTL
						
								-- 1-3. MIS IF 테이블 입력(자사몰 주문 상세)
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
										A.PRICE NOR_PRICE, -- 소비자가
										A.SELL_PRICE, -- 판매가
										A.PAY_AMT     AS ACT_SELL_PRICE, -- 결제금액
										A.LOSS_PRICE, -- 손실가
										A.DISCOUNT_RATE, -- 할인율
										'3'           AS SALES_TYPE, -- 주문정보
										B.STOREID,
										A.PAY_DATE    AS SALES_DATE, -- 결제일
										A.PRODUCT_SEQ AS PRO_SEQ,-- 상품 순번
										A.QTY,
										A.PAY_TYPE,
										NULL CER_NO, -- 시리얼번호
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
																	   END -- MIS_V_CRM_SHOP_INFO_IF 테이블에 2418만 로즈몽으로 등록되어 있어 임시로 하드코딩 처리.. 추후 공통코드 또는 거래처통일 필요 ..(LSH20230406)
								WHERE  SALES_NO = @P_SALES_NO
						
								-- UPDATE COUNT를 통해 MIS-IF-TABLE 입력 여부 확인
								IF(@@ROWCOUNT = 0)
									BEGIN 
										SET @ERROR_MSG = '요청한 정보수정 데이터가 없습니다. (NOCOUNT INSERT IF_MIS_TO_CRM_SALES_DTL)' + CHAR(13) + CHAR(10);
										THROW 55555, '@@ROWCOUNT = 0 ERROR', 0; -- CATCH 구문으로 이동 (THROW 구문의 오류코드는 큰 의미는 없다.)
									END

						COMMIT TRAN

						END TRY	
						BEGIN CATCH
			  
							ROLLBACK TRAN

							PRINT CONVERT(VARCHAR(30),@P_SALES_NO)+' : 실패 (LINE : ' + CONVERT(VARCHAR(3), ERROR_LINE()) + ') ' + ERROR_MESSAGE()   
						
							-- CRM 연동중 오류 시 INSERT를 취소하고 CRM_IF_YN을 X로 표시 한다. 
							-- 추후 오류건에 대해 관리자 확인 후 재 연동 프로세스 필요 
							UPDATE A
							   SET A.CRM_REFUND_IF_YN = 'X',
								   A.CRM_REFUND_IF_DATE = GETDATE(),
								   A.CRM_IF_ERROR_MSG = CASE WHEN ISNULL(@ERROR_MSG,'') <> '' THEN @ERROR_MSG 
															 ELSE ERROR_MESSAGE() 
														 END
							  FROM TB_OWNMALL_ORDER A
							 WHERE A.SALES_NO = @P_SALES_NO

							-- 커서가 열려있으면 닫기 
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

		-- ■□■□■□■□ 3.MIS 매출 정보 (ECOM) CURSOR 정의 - 환불정보 ■□■□■□■□
		
		BEGIN 
			DECLARE OWNMALL_REFUND_UPDATE_CUR CURSOR STATIC FOR 
			SELECT SALES_NO 
			FROM TB_OWNMALL_ORDER A 
			WHERE CRM_REFUND_IF_YN = 'Y'
				AND CRM_REFUND_UPDATE_IF_YN = 'N'
				-- 반품정보 들어올 때 UPDATE_IF_YN 'NULL'이면 아래 조건 필요 없을듯..
				AND ISNULL(REFUND_DATE,'') <> '' 
			ORDER BY SEQ ASC
			
			OPEN OWNMALL_REFUND_UPDATE_CUR 
			FETCH NEXT FROM OWNMALL_REFUND_UPDATE_CUR INTO @P_SALES_NO
				WHILE 1=1
					BEGIN
						BEGIN TRY
							IF (@@FETCH_STATUS <>0) BREAK;

							-- 오류 위치 SET 
							SET @ERROR_LOC = '3'

							BEGIN DISTRIBUTED TRAN
						
								-- ■ 1-1. MIS IF 테이블 UPDATE (자사몰 주문 MST)
								UPDATE A 
								   SET A.IF_STATUS_CD = 'U',
					   				   A.REFUND_DATE  = B.REFUND_DATE,
					   				   A.REFUND_REASON = B.REFUND_REASON,
					   				   A.REFUND_PRICE = B.REFUND_PRICE,
					   				   A.REFUND_LOST_PRICE = B.REFUND_LOST_PRICE
								  FROM MISSEC_LINK.MIS_SEC.DBO.IF_MIS_TO_CRM_SALES_MST A
								  INNER JOIN TB_OWNMALL_ORDER B ON A.SALES_NO = B.SALES_NO
								  WHERE A.SALES_NO = @P_SALES_NO

								-- UPDATE COUNT를 통해 MIS-IF-TABLE 입력 여부 확인
								IF(@@ROWCOUNT = 0)
									BEGIN 
										SET @ERROR_MSG = '요청한 정보수정 데이터가 없습니다. (NOCOUNT INSERT IF_MIS_TO_CRM_SALES_MST)' + CHAR(13) + CHAR(10);
										THROW 55555, '@@ROWCOUNT = 0 ERROR', 0; -- CATCH 구문으로 이동 (THROW 구문의 오류코드는 큰 의미는 없다.)
									END

								-- ■ 1-2. 자사몰 CRM I/F 여부 UPDATE
								UPDATE TB_OWNMALL_ORDER
									SET CRM_REFUND_UPDATE_IF_YN = 'Y',
										CRM_REFUND_UPDATE_IF_DATE = GETDATE()
									WHERE SALES_NO = @P_SALES_NO

								-- UPDATE COUNT를 통해 MIS-IF-TABLE 입력 여부 확인
								IF(@@ROWCOUNT = 0)
									BEGIN 
										SET @ERROR_MSG = '요청한 정보수정 데이터가 없습니다. (NOCOUNT UPDATE TB_OWNMALL_ORDER)' + CHAR(13) + CHAR(10);
										THROW 55555, '@@ROWCOUNT = 0 ERROR', 0; -- CATCH 구문으로 이동 (THROW 구문의 오류코드는 큰 의미는 없다.)
									END 
							
								-- ■ 1-3. MIS IF 테이블 UPDATE (자사몰 주문 상세)
								UPDATE A 
									SET A.IF_STATUS_CD = 'U',
										A.REFUND_DATE  = B.REFUND_DATE,
										A.REFUND_REASON = B.REFUND_REASON,
										A.REFUND_PRICE = B.REFUND_PRICE,
										A.REFUND_LOST_PRICE = B.REFUND_LOST_PRICE
									FROM MISSEC_LINK.MIS_SEC.DBO.IF_MIS_TO_CRM_SALES_DTL A
									INNER JOIN TB_OWNMALL_ORDER_DETAIL B ON A.SALES_DETAIL_NO = B.SALES_DETAIL_NO
								WHERE A.SALES_NO = @P_SALES_NO

								-- UPDATE COUNT를 통해 MIS-IF-TABLE 입력 여부 확인
								IF(@@ROWCOUNT = 0)
									BEGIN 
										SET @ERROR_MSG = '요청한 정보수정 데이터가 없습니다. (NOCOUNT UPDATE IF_MIS_TO_CRM_SALES_DTL)' + CHAR(13) + CHAR(10) ;
										THROW 55555, '@@ROWCOUNT = 0 ERROR', 0; -- CATCH 구문으로 이동 (THROW 구문의 오류코드는 큰 의미는 없다.)
									END 

						COMMIT TRAN

						END TRY	
						BEGIN CATCH
			  
							ROLLBACK TRAN

							PRINT CONVERT(VARCHAR(30),@P_SALES_NO)+' : 실패 (LINE : ' + CONVERT(VARCHAR(3), ERROR_LINE()) + ') ' + ERROR_MESSAGE()   
						
							-- CRM 연동중 오류 시 INSERT를 취소하고 CRM_IF_YN을 X로 표시 한다. 
							-- 추후 오류건에 대해 관리자 확인 후 재 연동 프로세스 필요 
							UPDATE A
							   SET A.CRM_REFUND_UPDATE_IF_YN = 'X',
								   A.CRM_REFUND_UPDATE_IF_DATE = GETDATE(),
								   A.CRM_IF_ERROR_MSG = CASE WHEN ISNULL(@ERROR_MSG,'') <> '' THEN @ERROR_MSG 
															 ELSE ERROR_MESSAGE() 
														 END
							  FROM TB_OWNMALL_ORDER A
							 WHERE A.SALES_NO = @P_SALES_NO
                    
							-- 커서가 열려있으면 닫기 
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

	-- 오류 위치에 따른 연동 'X'처리 
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
	
	BEGIN -- 커서가 열려있으면 닫기   
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

	-- I/F 입력 오류 발생시
	RETURN ERROR_MESSAGE() 
END CATCH 

