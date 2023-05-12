USE WOORIM_230215
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[OWNMALL_INV_BOOKING]
  @storename  varchar(40),
  @storeseq int,
  @item varchar(10),
  @category tinyint,
  @delDate smalldatetime, 
  @type varchar(10),
  @reguser varchar(20),
  @ListPrd varchar(8000)


/******************************************************************************
** File:
** Name: OWNMALL_INV_BOOKING
**
** Desc: 자사몰 실재고 주문시 재고 선점 
**
** This template can be customized : psj_HQLogDeliveryStoreNew1108_order
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
** Date: 2022.04.12
*******************************************************************************
** Change History
*******************************************************************************
** Date:		Author:	Description:
** ---------	------	-----------------
*******************************************************************************/
AS

--SET XACT_ABORT ON 
DECLARE @seq int
DECLARE	@detailStartIndex smallint
DECLARE	@detailLastIndex smallint
DECLARE	@ArrayLen smallint  -- 세부항목의 바이트수 (prdID, qty)
DECLARE	@prdid int
DECLARE	@Qty int
DECLARE @total int
DECLARE @note varchar(30)
DECLARE @DelNo char(9)
DECLARE @num smallint

DECLARE @aseq int -- agencyorder-seq

declare   @store smallint
set @store = @storeseq

--재고 마감이전 출고 확인
IF EXISTS (select 1 from hqinventoryclose
	where item=@item and category = @category and closeDate >= @delDate)

RETURN 1 

declare @storeid varchar(3)
select @storeid = storeid from store
where seq = @store

select Convert(Char(10),getdate(),20)
--210518 수정
IF not exists (select 1 from delivery where delDate =  Convert(Char(10),@deldate,20) and left(delno,1)<>'F')
 select  @delNo =    replicate('0',2-len(right(year(@deldate),2)))+cast(right(year(@deldate),2) as varchar(2))  +''+
          replicate('0',2-len(month(@deldate)))+cast(month(@deldate) as varchar(2))  +''+
          replicate('0',2-len(day(@deldate)))+cast(day(@deldate) as varchar(2))  +''+ '001'
	
ELSE IF  (select count(*) from delivery where delDate =  Convert(Char(10),@deldate,20)) > 999

select
         @delno =  replicate('0',2-len(right(year(@deldate),2)))+cast(right(year(@deldate),2) as varchar(2))  +''+
          replicate('0',1-len(month(@deldate)))+cast(month(@deldate) as varchar(2))  +''+
          replicate('0',2-len(day(@deldate)))+cast(day(@deldate) as varchar(2))  +''+ 
          replicate('0',4- len(max(cast(right(isnull(delno,0),4) as int)) +1)) + cast(max(cast(right(isnull(delno,0),4) as int)) +1 as varchar(4)) 
 --         replicate('0',3-len(cast(right(isnull(delno,0),3) as smallint) +1))+cast(cast(right(isnull(delno,0),3) as smallint) +1 as varchar(3)) 
--          replicate('0',3-len(count(seq ) +1))+cast(count(seq ) +1 as varchar(3))   
from delivery
where delDate =  Convert(Char(10),@deldate,20)

ELSE
select  @delNo =    replicate('0',2-len(right(year(@deldate),2)))+cast(right(year(@deldate),2) as varchar(2))  +''+
          replicate('0',2-len(month(@deldate)))+cast(month(@deldate) as varchar(2))  +''+
          replicate('0',2-len(day(@deldate)))+cast(day(@deldate) as varchar(2))  +''+ 
          replicate('0',3- len(max(cast(right(isnull(delno,0),3) as int)) +1)) + cast(max(cast(right(isnull(delno,0),3) as int)) +1 as varchar(3)) 
from delivery
where delDate =  Convert(Char(10),@deldate,20)
--210518
and left(delno,1)<>'F'

BEGIN TRY
    SET XACT_ABORT ON;
    BEGIN TRANSACTION
    -- logic processing
    -- optional : other procedure call

	INSERT INTO  Delivery (storeseq, item, category, brandseq, delDate,delNo, type, reguser)
	VALUES(@storeseq, @item, @category, 0, Convert(Char(10),@deldate,20),@delNo, @type, @reguser)
	
	SET @seq = @@identity
	SET @ArrayLen = Len(@ListPrd)
	SET @detailStartIndex = 1
	SET @num = 1 

	WHILE (@DetailStartIndex < @ArrayLen )
	BEGIN
		SET @detailLastIndex = CharIndex('$', @ListPrd, @DetailStartIndex)
		SET @prdID = Cast (SubString(@ListPrd,@DetailStartIndex, @DetailLastIndex - @DetailStartIndex) as int)
		
		SET @detailStartIndex=CharIndex('$', @ListPrd, @DetailLastIndex+1)
		SET @Qty = Cast(SubString(@ListPrd, @DetailLastIndex+1, @DetailStartIndex- @DetailLastIndex -1) as smallint)
		
		SET @detailLastIndex=CharIndex('$', @ListPrd, @DetailStartIndex+1)
		SET @total = Cast(SubString(@ListPrd, @DetailStartIndex+1,  @DetailLastIndex- @DetailStartIndex-1 ) as int)

		SET @detailStartIndex=CharIndex('$', @ListPrd, @DetailLastIndex+1)
		--SET @note = Cast(SubString(@ListPrd,  @DetailLastIndex+1, @DetailStartIndex- @DetailLastIndex-1 ) as varchar(30))
		SET @aseq = Cast(SubString(@ListPrd,  @DetailLastIndex+1, @DetailStartIndex- @DetailLastIndex-1 ) as int)
		
        IF @store = 367
        set @total = 0

		--2. 출고상세데이블  입력			
		INSERT INTO DeliveryDetail (delseq, proseq, Qty,total, note, num) 
		VALUES (@seq, @prdID, @Qty, @total, '', @num)

                              --매장 재고 테이블에 넣기.
                            IF NOT EXISTS(select 1  from storeinventory where storeid =  @storeid and proseq = @prdid and (@type='직영점' or @type = '로드샵') ) and (@type = '직영점' or @type = '로드샵')
                              INSERT INTO storeinventory(storeid, proseq, qty) 
                              VALUES(ISNULL(@storeid,''), @prdid, 0)

		IF @type = '기타'
		BEGIN
		IF NOT EXISTS(select 1  from etcinventory where storeseq =  @store and proseq = @prdid and @type='기타' )
		INSERT INTO etcinventory
		VALUES(@store, @prdid, @qty)
		ELSE
		UPDATE etcinventory
		set qty = qty + @qty
		where storeseq = @store and proseq = @prdid and @type = '기타'
		END 
		
		IF NOT EXISTS(select 1  from hqinventory where  proseq = @prdid )
		INSERT INTO hqinventory
		VALUES( @prdid, -@qty)
		ELSE
		UPDATE HqInventory
		SET qty = qty - @qty
		WHERE proseq = @prdid
			
			
		if exists (select 1 from  AgencyOrderOk where seq =@aseq)
			update  AgencyOrderOk
			set type = 'o', reguser = @reguser, regdate = getdate(), qty=@qty
			where seq =@aseq
		else 
			INSERT INTO  AgencyOrderOk (seq, reguser, type,qty)
			 values(@aseq, @reguser,'o',@qty )

		update  AgencyOrder
		set deldate = getdate(),delseq=@seq, deluser=@reguser
		where seq =@aseq 
		
		SET @num = @num + 1
		SET @DetailStartIndex = @DetailStartIndex + 1
   END
   
    COMMIT TRANSACTION
	RETURN @seq  --(@seq가 1이면 곤란....)
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION
END CATCH

