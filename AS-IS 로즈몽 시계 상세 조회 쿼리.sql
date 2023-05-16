--psj_HQProductView2_10 '시계',1,186,''
--drop proc psj_HQProductView2_11_20190719
--GRANT exec on psj_HQProductView2_20190719 to execdb   with grant option
--CREATE                  proc  [dbo].[psj_HQProductView2_220104]


declare

  @item varchar(10)		= '시계',
  @category tinyint		= 1,
  @brand tinyint		= 129,
  @modelno varchar(30)	= '',
  @reguser varchar(20)	= 'system'
  

--exec psj_HQProductView2_10 @item='시계',@category=5,@brand=0,@modelno=''
/*
declare  @item varchar(10)
declare  @category tinyint
declare  @brand tinyint
declare  @modelno varchar(30)
declare  @reguser varchar(20)

set @item = '주얼리'
set @category = 4
set @brand = 89
set @modelno = ''
set @reguser='loise'

*/

 declare @rights tinyint
 if exists (  select * from hquserdetail 
            where (부서 in (  select username  From  ViewRights where  procName ='WatchProductView')
             or  userid  in (  select username  From  ViewRights where  procName ='WatchProductView'))
             and userid =@reguser )
       set @rights = 1
else 
        set @rights = 0
        
declare @premium int
select @premium = case when (type2 = '오롤로지움' or type = '오롤로지움') then 1 else 0 end
from brandname where seq = @brand
--select @premium
/*
-- 브랜드가 선택되지 않은 경우 조회할 필요 없음
if @brand = 0
select 1
*/

if   @category = 2 --as part
	select p.seq,
			  b.item "품목",
			  co.name "구분",
			  brandName "브랜드명",
			  ModelNo "모델명",
			  isnull(c.name,'')  "부품구분",
			  Gubun "분류",
			  series "시리즈명",
		   --   code "분류코드",
			  price  "소비자가",
			  fobprice  "fob가",
			  cost  "현지가"
	 from product p inner join brandname b on p.brandseq = b.seq
						   left  join (select name, value from codebook where code='aspartwatchtype' and @item = '시계'
											   union
											 select name, value from codebook where code='aspartjewtype' and @item = '주얼리'
											 ) c on  p.parttype = c.value
						  inner join (select name, value from codebook where code='category') co on  p.category = co.value

	WHERE  p.brandseq  = @brand and  p.category = @category   and b.item = @item
	order by modelno
	--select * from brandname where seq  in (7,6,14)]
else if (@brand = 186 )  --archimedes 제조원가 추가 2019-07-18
  exec psj_HQProductView2_Archimedes_20190718  @item , @category, @brand , @modelno
  
else if  @item = '시계' and ( @modelno = '' and @category = 1  and @brand not in (7,6,14,126) )  -- and @brand <> 15) )
	--select 1
	-- psj_HQProductView2_6 '시계',1,56,''
	-- psj_HQProductView2_5 '시계',1,56,''

	if (@premium = 0)
	 --200518 기본 citizen 과 조회 분기, 이커머스팀과 BM팀 싫다고 함(장태영대리, 장여정부장)	
	 --그래서 합침
	 --if(@brand != 124)
 
		 begin
		select distinct p.seq,
				  b.item "품목",
				  c.name "종류",
				  case when a.p_idx is not null or aa.modelno is not null then '등록' else '' end "홈페이지",
				  --''  "홈페이지",
				  isnull(brandName, '')  "브랜드명",
				  p.ModelNo "모델명",
				  isnull(p2.modelno2,'') "모델명2",
		--          case when p.isevent = 1 then '가능' else '불가' end "행사",
				  case when p.isevent = 1 then '가능' when p.isevent = 2  then '온라인' when p.isevent = 3  then '가능/불' when p.isevent = 4 then '기획' when p.isevent = 5 then 'DM' when p.isevent = 6 then '면세' when p.isevent = 7 then '악성' when p.isevent = 8 then '악성17' when 
p.isevent = 9 then '악성19' when p.isevent = 10 then '반품진행' else '불가' end "행사",
				  Convert(char(10), cp1.usedate, 120) "아울렛최초등록일",
				  100 - cp.rate "아울렛할인률",
				  refercode "대분류", --추가
				  case when b.item='시계' then origin.name else '' end  "원산지",
				  CASE when len(series) < 1 then '' else  series end  "시리즈명",
				  p.partsname "출고증",
				  co.name  "구분",
				 case when b.item='시계' then skill.name   else
								cast(isnull(minsize,'')  as varchar(3))  +'~' +   cast(isnull(maxsize,'')  as varchar(3))   end  "기능",
				  Gubun "분류",
				  sex "성별",
				  --case when b.item='시계' then band.name else '' end  "밴드",
				  --230210 ERP
				  case when b.item='시계' then band.NAME  else '' end  "밴드",
				  case when b.item='시계' then form.name else '' end  "형태",
				  case when b.item='시계' then wcase.name else '' end   "케이스",
				  p.casesize "케이스사이즈",
				  case when b.item='시계' then case when couple = 'y' then '커플' else '' end  else '' end  "커플",
				  case when b.item='시계' then dial.name   else '' end  "문자판",
				   p.water "방수(M)" ,
				--  p.code "분류코드",
				  p.price  "소비자가",
				  fobprice  "fob가",
				  cost  "현지가",
				   case when @rights = 1 then  isnull(p.cost0,0) else 0 end "초기원가",
				  --p.etcnote "기타",
				 convert(char(10), p.regdate, 120) "등록일"
		--select top 10 * from product
		 from product p left  join brandname b on p.brandseq = b.seq
								inner join (select name, value from codebook where code='category') c on  p.category = c.value
							   --left join (select * from codebook
										--	 where code='watchband') band on p.material = band.value
								left join  (select * from codebook
											  where  code = case when @item = '시계' then  'watchcategory'
																				else    'jewelrycategory' end ) co on p.class = co.value
								 left join  (select * from codebook   where code='watchcase') wcase on p.color  = wcase.value
		--select top 10 * from product
								left join (select * from codebook
											where code='watchform') form on p.form = form.value
							   left join (select * from codebook  where code='watchdial') dial on p.dial = dial.value
							   left join (select * from codebook  where code='origin') origin on p.origin= origin.value
							   left join (select * From codebook where code='watchskill') skill on p.skill = skill.value
							   --left join       OPENQUERY(goc2, 'SELECT * FROM woorim.view_product') a on a.p_code = p.modelno
							   --left join       OPENQUERY(homepage, 'SELECT * FROM dbo.VIEW_ERP_PRODUCT') a on a.p_code = p.modelno
							   --200522 DB서버 교체후 재수정   
							   left join       OPENQUERY(homepage2, 'SELECT * FROM dbo.VIEW_ERP_PRODUCT') a on a.p_code = p.modelno
							   --left join  OPENQUERY(goc, 'SELECT * FROM dbo.VIEW_W_PRODUCT') aa on aa.modelno = p.modelno  
							   --200522 DB서버 교체후 재수정   
							   left join OPENQUERY(homepage2, 'SELECT * FROM dbo.VIEW_ERP_W_PRODUCT') aa on aa.modelno = p.modelno  
							   --left join OPENQUERY(homepage, 'SELECT * FROM dbo.VIEW_ERP_W_PRODUCT') aa on aa.modelno = p.modelno  
							   left join chelsyproduct cp on p.seq = cp.proseq and convert(char(10), getdate(), 120) between cp.usedate and isnull(cp.outdate,'2050-12-31') 
							   left join (select proseq, min(usedate) usedate from  chelsyproduct  where outdate is null group by proseq ) cp1 on p.seq = cp1.proseq
		--          left join  OPENQUERY(galleryoclock, 'SELECT * FROM new_product_main')  a on a.mod_no = p.modelno

								left outer join productmodelno2 p2 on p.seq = p2.proseq 

								--230213 시계 밴드 ERP 데이터 직접 보이도록
								left outer join
								(
								SELECT ERP_CD_ITEM , EC.NAME  		
									FROM product p
									inner join (
												select CD_SYSDEF CODE, NM_SYSDEF NAME 
												from ERP_CODE_DTL
												WHERE CD_COMPANY= '1000' AND CD_FIELD = 'MA_B000122' AND CD_FLAG2 = '1' AND ISNULL(USE_YN,'N') = 'Y'  
									) EC
									on p.Material = EC.CODE and p.Category =1					
								) band on p.ERP_CD_ITEM = band.ERP_CD_ITEM

		WHERE ( p.brandseq  = @brand and p.category = @category  and b.item = @item and   p.active='a'
		  aND ( p.seq in (select  distinct proseq  from productorderdetail where orderseq in (select seq from productorder where category = '상품') )  or
				p.seq in (select distinct d.proseq from invoice i inner join invoicedetail d on i.seq = d.inseq where i.orderseq in (select seq from productorder where category = '상품'))
			   or (@brand = 186 and p.seq in (select seq from product where brandseq = @brand and active='a')))
				  and  p.seq not  in (select distinct productidx  from productpart
																				 where productidx in (select proseq  From productorderdetail
																												 where orderseq in (select seq From productorder where category = 'a/s부품') )
																					  and productidx not in (select proseq  From productorderdetail
																   where orderseq in (select seq From productorder where category = '상품') ))
			  ) or ( p.brandseq  = @brand and p.category = @category  and b.item = @item and   p.active='a' and p.regdate > dateadd(d,-30,getdate()))
		  and isnull(series,'') <> 'A/S 자재용'
  

		--          aND ( p.seq in (select  distinct proseq  from productorderdetail where orderseq in (select seq from productorder where category = '상품') )

		--            and( ( @brand in (14,15)  and
		--               (  p.seq in (select distinct productseq from productprice where active='a')
		--                and ( p.seq in (select  distinct proseq  from productorderdetail where orderseq in (select seq from productorder where category = '상품'))
		--                   or p.seq in (select distinct proseq from storeinventorydetail)      or p.seq in (select distinct proseq from hqinventorydetail) ) ) )
		--                 or @brand  not in (14.15)   and  p.brandseq  = @brand )
		order by p.modelno
		end

	else
	select distinct  p.seq,
			  b.item "품목",
			  c.name "종류",
			  case when a.p_idx is not null then '등록' else '' end "홈페이지",
			  --''  "홈페이지",
			  isnull(brandName, '')  "브랜드명",
			-- 'test' "브랜드명",
			  ModelNo "모델명",
			  isnull(p2.modelno2,'') "모델명2",
	--          case when p.isevent = 1 then '가능' else '불가' end "행사",
			  case when p.isevent = 1 then '가능' when p.isevent = 2  then '온라인' when p.isevent = 3  then '가능/불' when p.isevent = 4 then '기획'   when p.isevent = 5 then 'DM' when p.isevent = 6 then '면세' when p.isevent = 7 then '악성' when p.isevent = 8 then '악성17' when
 p.isevent = 9 then '악성19' when p.isevent = 10 then '반품진행' else '불가' end "행사",
			  Convert(char(10), cp1.usedate, 120) "아울렛최초등록일",
			  100 - cp.rate "아울렛할인률",
			  refercode "대분류", --추가
			  case when b.item='시계' then origin.name else '' end  "원산지",
			  series "시리즈명",
			  co.name  "구분",
			 case when b.item='시계' then skill.name   else
							cast(isnull(minsize,'')  as varchar(3))  +'~' +   cast(isnull(maxsize,'')  as varchar(3))   end  "기능",
			  Gubun "분류",
			  sex "성별",
			  --case when b.item='시계' then band.name else '' end  "밴드",
			  --230210 ERP
			  case when b.item='시계' then band.NAME  else '' end  "밴드",
			  case when b.item='시계' then form.name else '' end  "형태",
			  case when b.item='시계' then wcase.name else '' end   "케이스",
	p.casesize "케이스사이즈",
			  case when b.item='시계' then case when couple = 'y' then '커플' else '' end  else '' end  "커플",
			  case when b.item='시계' then dial.name   else '' end  "문자판",
			   p.water "방수(M)" ,
			--  p.code "분류코드",
			  p.price  "소비자가",
			  fobprice  "fob가",
			  cost  "현지가",
			  --p.etcnote "기타",
			  case when @rights = 1 then  isnull(p.cost0,0) else 0 end "초기원가",
			 convert(char(10), p.regdate, 120) "등록일"
	--select top 10 * from product
	 from product p left  join brandname b on p.brandseq = b.seq
							inner join (select name, value from codebook where code='category') c on  p.category = c.value
						   --left join (select * from codebook
									--	 where code='watchband') band on p.material = band.value
							left join  (select * from codebook
										 where  code = case when @item = '시계' then  'watchcategory'

																			else    'jewelrycategory' end ) co on p.class = co.value
							 left join (select * from codebook  where code='origin') origin on p.origin= origin.value

							 left join  (select * from codebook   where code='watchcase') wcase on p.color  = wcase.value
	--select top 10 * from product
							left join (select * from codebook
										where code='watchform') form on p.form = form.value
						   left join (select * from codebook  where code='watchdial') dial on p.dial = dial.value
						   left join (select * From codebook where code='watchskill') skill on p.skill = skill.value
						 --left join       OPENQUERY(homepage, 'SELECT * FROM dbo.VIEW_ERP_PRODUCT') a on a.p_code = p.modelno
						 --200522 DB서버 교체후 재수정 
						 left join       OPENQUERY(homepage2, 'SELECT * FROM dbo.VIEW_ERP_PRODUCT') a on a.p_code = p.modelno
						 left join chelsyproduct cp on p.seq = cp.proseq and convert(char(10), getdate(), 120) between cp.usedate and isnull(cp.outdate,'2050-12-31')
						 left join (select proseq, min(usedate) usedate from  chelsyproduct group by proseq ) cp1 on p.seq = cp1.proseq
	--          left join  OPENQUERY(galleryoclock, 'SELECT * FROM new_product_main')  a on a.mod_no = p.modelno
	--select * from brandname where brandname like 'arch%'

						--210322
						left outer join productmodelno2 p2 on p.seq = p2.proseq 

						--230213 시계 밴드 ERP 데이터 직접 보이도록
						left outer join
						(
						SELECT ERP_CD_ITEM , EC.NAME  		
							FROM product p
							inner join (
										select CD_SYSDEF CODE, NM_SYSDEF NAME 
										from ERP_CODE_DTL
										WHERE CD_COMPANY= '1000' AND CD_FIELD = 'MA_B000122' AND CD_FLAG2 = '1' AND ISNULL(USE_YN,'N') = 'Y'  
							) EC
							on p.Material = EC.CODE and p.Category =1					
						) band on p.ERP_CD_ITEM = band.ERP_CD_ITEM

	WHERE  p.brandseq  = @brand and p.category = @category  and b.item = @item and   p.active='a'
	  aND ( p.seq in (select  distinct proseq  from productorderdetail where orderseq in (select seq from productorder where category = '상품') and p.seq <> 186 )  or
   			 p.seq in (select distinct d.proseq from invoice i inner join invoicedetail d on i.seq = d.inseq where i.orderseq in (select seq from productorder where category = '상품'))
			or  (@brand = 186 and p.seq in (select seq from product where brandseq =186)))
			  and  p.seq not  in (select distinct productidx  from productpart
																			 where productidx in (select proseq  From productorderdetail
																											 where orderseq in (select seq From productorder where category = 'a/s부품') )
																				  and productidx not in (select proseq  From productorderdetail
															   where orderseq in (select seq From productorder where category = '상품') ))
	--          aND ( p.seq in (select  distinct proseq  from productorderdetail where orderseq in (select seq from productorder where category = '상품') )

	--            and( ( @brand in (14,15)  and
	--               (  p.seq in (select distinct productseq from productprice where active='a')
	--                and ( p.seq in (select  distinct proseq  from productorderdetail where orderseq in (select seq from productorder where category = '상품'))
	--                   or p.seq in (select distinct proseq from storeinventorydetail)      or p.seq in (select distinct proseq from hqinventorydetail) ) ) )
	--                 or @brand  not in (14.15)   and  p.brandseq  = @brand )
	order by modelno


--select * from  OPENQUERY(goc, 'SELECT * FROM woorim.view_product') a

else if  @item = '시계' and ( @modelno = '' and @category = 1  and @brand=126 )  -- and @brand <> 15) )

	-- psj_HQProductView2_6 '시계',1,56,''
	-- psj_HQProductView2_5 '시계',1,56,''


	select distinct p.seq,
			  b.item "품목",
			  c.name "종류",
			  case when a.p_idx is not null then '등록' else '' end "홈페이지",
			  --''  "홈페이지",
			  isnull(brandName, '')  "브랜드명",
			  ModelNo "모델명",
			  isnull(p2.modelno2,'') "모델명2",
	--          case when p.isevent = 1 then '가능' else '불가' end "행사",
			  case when p.isevent = 1 then '가능' when p.isevent = 2  then '온라인' when p.isevent = 3  then '가능/불' when p.isevent = 4 then '기획'  when p.isevent = 5 then 'DM' when p.isevent = 6 then '면세' when p.isevent = 7 then '악성' when p.isevent = 8 then '악성17' when 
p.isevent = 9 then '악성19' when p.isevent = 10 then '반품진행' else '불가' end "행사",
			  Convert(char(10), cp1.usedate, 120) "아울렛최초등록일",
			  100 - cp.rate "아울렛할인률",
			  refercode "대분류", --추가
			  case when b.item='시계' then origin.name else '' end  "원산지",
			  series "시리즈명",
			  co.name  "구분",
			 case when b.item='시계' then skill.name   else
							cast(isnull(minsize,'')  as varchar(3))  +'~' +   cast(isnull(maxsize,'')  as varchar(3))   end  "기능",
			  Gubun "분류",
			  sex "성별",
			  case when b.item='시계' then band.name else '' end  "밴드",
			  case when b.item='시계' then form.name else '' end  "형태",
			  case when b.item='시계' then wcase.name else '' end   "케이스",
			  case when b.item='시계' then case when couple = 'y' then '커플' else '' end  else '' end  "커플",
			  case when b.item='시계' then dial.name   else '' end  "문자판",
			   p.water "방수(M)" ,
			   p.movetype "무브먼트호환",
			  p.casesize "케이스사이즈",
			  p.depth "두께",
			--  p.code "분류코드",
			  p.price  "소비자가",
			  fobprice  "fob가",
			  cost  "현지가",
			  --p.etcnote "기타",
			   case when @rights = 1 then  isnull(p.cost0,0) else 0 end "초기원가",
			 convert(char(10), p.regdate, 120) "등록일"
	--select top 10 * from product
	 from product p left  join brandname b on p.brandseq = b.seq
							inner join (select name, value from codebook where code='category') c on  p.category = c.value
						   left join (select * from codebook
										 where code='watchband') band on p.material = band.value
							left join  (select * from codebook
										  where  code = case when @item = '시계' then  'watchcategory'

																			else    'jewelrycategory' end ) co on p.class = co.value
							 left join  (select * from codebook   where code='watchcase') wcase on p.color  = wcase.value
	--select top 10 * from product
						  left join (select * from codebook  where code='origin') origin on p.origin= origin.value
							left join (select * from codebook
										where code='watchform') form on p.form = form.value
						   left join (select * from codebook  where code='watchdial') dial on p.dial = dial.value
						   left join (select * From codebook where code='watchskill') skill on p.skill = skill.value
					 --    left join      OPENQUERY(homepage, 'SELECT * FROM dbo.VIEW_ERP_PRODUCT') a on a.p_code = p.modelno
						   left join      OPENQUERY(homepage2, 'SELECT * FROM dbo.VIEW_ERP_PRODUCT') a on a.p_code = p.modelno
						   left join chelsyproduct cp on p.seq = cp.proseq and convert(char(10), getdate(), 120) between cp.usedate and isnull(cp.outdate,'2050-12-31')
						   left join (select proseq, min(usedate) usedate from  chelsyproduct group by proseq ) cp1 on p.seq = cp1.proseq

						   left outer join productmodelno2 p2 on p.seq = p2.proseq 

	WHERE  p.brandseq  = @brand and p.category = @category  and b.item = @item and   p.active='a'
	  aND ( p.seq in (select  distinct proseq  from productorderdetail where orderseq in (select seq from productorder where category = '상품') )  or
		p.seq in (select distinct d.proseq from invoice i inner join invoicedetail d on i.seq = d.inseq where i.orderseq in (select seq from productorder where category = '상품')))
			  and  p.seq not  in (select distinct productidx  from productpart
																			 where productidx in (select proseq  From productorderdetail
																											 where orderseq in (select seq From productorder where category = 'a/s부품') )
																				  and productidx not in (select proseq  From productorderdetail
															   where orderseq in (select seq From productorder where category = '상품') ))



	-- aND ( p.seq in (select  distinct proseq  from productorderdetail where orderseq in (select seq from productorder where category = '상품') )

	-- and( ( @brand in (14,15)  and
	--( p.seq in (select distinct productseq from productprice where active='a')
	-- and ( p.seq in (select  distinct proseq  from productorderdetail where orderseq in (select seq from productorder where category = '상품'))
	-- or p.seq in (select distinct proseq from storeinventorydetail)      or p.seq in (select distinct proseq from hqinventorydetail) ) ) )
	-- or @brand  not in (14.15)   and  p.brandseq  = @brand )
	order by modelno
                                                                                                                                                       
	--select * From brandname where seq in (7,6,14)

else if ( @item = '시계' and  @modelno = '' and @category = 1 and @brand in (7,6,14))

	select distinct  p.seq,
			  b.item "품목",
			  c.name "종류",
			case when a.p_idx is not null then '등록' else '' end "홈페이지",
			--''  "홈페이지",
			  isnull(brandName, '')  "브랜드명",
			  ModelNo "모델명",
			  isnull(p2.modelno2,'') "모델명2",
	--          case when p.isevent = 1 then '가능' else '불가' end "행사",
			  case when p.isevent = 1 then '가능' when p.isevent = 2  then '온라인' when p.isevent = 3  then '가능/불' when p.isevent = 4 then '기획'  when p.isevent = 5 then 'DM' when p.isevent = 6 then '면세' when p.isevent = 7 then '악성' when p.isevent = 8 then '악성17' when 
p.isevent = 9 then '악성19' when p.isevent = 10 then '반품진행' else '불가' end "행사",
			  Convert(char(10), cp1.usedate, 120) "아울렛최초등록일",
			  100 - cp.rate "아울렛할인률",
			  series "시리즈명",

			  co.name  "구분",
			 case when b.item='시계' then skill.name   else
							cast(isnull(minsize,'')  as varchar(3))  +'~' +   cast(isnull(maxsize,'')  as varchar(3))   end  "기능",
			  Gubun "분류",
			  sex "성별",
			  case when b.item='시계' then band.name else '' end  "밴드",
			  case when b.item='시계' then form.name else '' end  "형태",
			  case when b.item='시계' then wcase.name else '' end   "케이스",
			  case when b.item='시계' then dial.name   else '' end  "문자판",
			   p.water "방수(M)" ,
			  case when b.item='시계' then case when couple = 'y' then '커플' else '' end  else '' end  "커플",
			--  p.code "분류코드",
			  p.price  "소비자가",
			  fobprice  "fob가",
			  cost  "현지가"  ,
			 p.etcnote "기타",
			 convert(char(10), p.regdate, 120) "등록일"
	 from product p left  join brandname b on p.brandseq = b.seq
							inner join (select name, value from codebook where code='category') c on  p.category = c.value
						   left join (select * from codebook
										 where code='watchband') band on p.material = band.value
							left join  (select * from codebook
										  where  code = case when @item = '시계' then  'watchcategory'
																			else    'jewelrycategory' end ) co on p.class = co.value
						   left join  (select * from codebook   where code='watchcase') wcase on p.color  = wcase.value
						   left join (select * from codebook  where code='origin') origin on p.origin= origin.value
							left join (select * from codebook
										where code='watchform') form on p.form = form.value
						   left join (select * from codebook  where code='watchdial') dial on p.dial = dial.value
						   left join (select * From codebook where code='watchskill') skill on p.skill = skill.value
					 --       left join       OPENQUERY(homepage, 'SELECT * FROM dbo.VIEW_ERP_PRODUCT') a on a.p_code = p.modelno
							left join       OPENQUERY(homepage2, 'SELECT * FROM dbo.VIEW_ERP_PRODUCT') a on a.p_code = p.modelno
						   left join chelsyproduct cp on p.seq = cp.proseq and convert(char(10), getdate(), 120) between cp.usedate and isnull(cp.outdate,'2050-12-31')
						   left join (select proseq, min(usedate) usedate from  chelsyproduct group by proseq ) cp1 on p.seq = cp1.proseq

						   left outer join productmodelno2 p2 on p.seq = p2.proseq 

	WHERE  p.brandseq  = @brand and p.category = @category  and b.item = @item and   p.active='a'
	  aND ( p.seq in (select  distinct proseq  from productorderdetail where orderseq in (select seq from productorder where category = '상품') )  or
		p.seq in (select distinct d.proseq from invoice i inner join invoicedetail d on i.seq = d.inseq where i.orderseq in (select seq from productorder where category = '상품')))
			  and  p.seq not  in (select distinct productidx  from productpart
																			 where productidx in (select proseq  From productorderdetail
																											 where orderseq in (select seq From productorder where category = 'a/s부품') )
																				  and productidx not in (select proseq  From productorderdetail
															   where orderseq in (select seq From productorder where category = '상품') ))


	--            and( ( @brand in (14,15)  and
	--               (  p.seq in (select distinct productseq from productprice where active='a')
	--                and ( p.seq in (select  distinct proseq  from productorderdetail where orderseq in (select seq from productorder where category = '상품'))
	--                   or p.seq in (select distinct proseq from storeinventorydetail)      or p.seq in (select distinct proseq from hqinventorydetail) ) ) )
	--                 or @brand  not in (14.15)   and  p.brandseq  = @brand )
	order by modelno

	--select * from product where modelno ='1032'

	--select * from productprice  where productseq =16821

else if    @item = '시계' and ( @modelno <>  '' and (( @category = 1 ) ))
select distinct p.seq,
          b.item "품목",
          c.name "종류",
       case when a.p_idx is not null or aa.modelno is not null then '등록' else '' end "홈페이지",
       --''  "홈페이지",
          isnull(brandName, '')  "브랜드명",
          p.ModelNo "모델명",
		  isnull(p2.modelno2,'') "모델명2",
--          case when p.isevent = 1 then '가능' else '불가' end "행사",
          case when p.isevent = 1 then '가능' when p.isevent = 2  then '온라인' when p.isevent = 3  then '가능/불' when p.isevent = 4 then '기획'  when p.isevent = 5 then 'DM' when p.isevent = 6 then '면세' when p.isevent = 7 then '악성' when p.isevent = 8 then '악성17' 
when p.isevent = 9 then '악성19' when p.isevent = 10 then '반품진행' else '불가' end "행사",
          Convert(char(10), cp1.usedate, 120) "아울렛최초등록일",
          100 - cp.rate "아울렛할인률",
		  refercode "대분류", --추가
		 case when b.item='시계' then origin.name else '' end  "원산지",
          series "시리즈명",
          co.name  "구분",
          case when b.item='시계' then skill.name   else '' end  "기능",
          Gubun "분류",
          sex "성별",
          --case when b.item='시계' then band.name else '' end  "밴드",
		  --230210
		  case when b.item='시계' then wb.NAME  else '' end  "밴드",
          case when b.item='시계' then form.name else '' end  "형태",
          case when b.item='시계' then wcase.name else '' end   "케이스",
p.casesize "케이스사이즈",
          case when b.item='시계' then dial.name   else '' end  "문자판",
           p.water "방수(M)" ,
       --   case when b.item='시계' then case when couple = 'y' then '커플' else '' end  else '' end  "커플",
          case when b.item='시계' then dial.name   else '' end  "다이알",
        --  p.code "분류코드",
          p.price  "소비자가",
          fobprice  "fob가",
          cost  "현지가"  ,
         --p.etcnote "기타",
          case when @rights = 1 then  isnull(p.cost0,0) else 0 end "초기원가",
         convert(char(10), p.regdate, 120) "등록일"
 from product p left  join brandname b on p.brandseq = b.seq
                        inner join (select name, value from codebook where code='category') c on  p.category = c.value
                       left join (select * from codebook

                                     where code='watchband') band on p.material = band.value
                        left join  (select * from codebook
                                      where  code = case when @item = '시계' then  'watchcategory'
                                                                        else    'jewelrycategory' end ) co on p.class = co.value
                    left join  (select * from codebook   where code='watchcase') wcase on p.color  = wcase.value
                    left join (select * from codebook  where code='origin') origin on p.origin= origin.value
                        left join (select * from codebook
                                    where code='watchform') form on p.form = form.value
                       left join (select * from codebook  where code='watchdial') dial on p.dial = dial.value
                       left join (select * From codebook where code='watchskill') skill on p.skill = skill.value
             --       left join       OPENQUERY(homepage, 'SELECT * FROM dbo.VIEW_ERP_PRODUCT') a on a.p_code = p.modelno
		--		   left join  OPENQUERY(homepage, 'SELECT * FROM dbo.VIEW_ERP_W_PRODUCT')  aa on aa.modelno = p.modelno  
                    left join       OPENQUERY(homepage2, 'SELECT * FROM dbo.VIEW_ERP_PRODUCT') a on a.p_code = p.modelno
		      	    left join  OPENQUERY(homepage2, 'SELECT * FROM dbo.VIEW_ERP_W_PRODUCT')  aa on aa.modelno = p.modelno   		  
		            left join chelsyproduct cp on p.seq = cp.proseq and convert(char(10), getdate(), 120) between cp.usedate and isnull(cp.outdate,'2050-12-31')
                    left join (select proseq, min(usedate) usedate from  chelsyproduct group by proseq ) cp1 on p.seq = cp1.proseq

					--210322
					left outer join productmodelno2 p2 on p.seq = p2.proseq  

					--230210
					left outer join
					(
					SELECT CD_ITEM, EC.NAME  
						FROM ERP_LINK.NEOE.NEOE.MA_PITEM EM
						inner join (
									select CD_SYSDEF CODE, NM_SYSDEF NAME 
									from ERP_LINK.NEOE.NEOE.MA_CODEDTL
									WHERE CD_COMPANY= '1000' AND CD_FIELD = 'MA_B000122' AND CD_FLAG2 = '1' AND ISNULL(USE_YN,'N') = 'Y'  
						) EC
						on EM.CD_USERDEF13 = EC.CODE
						WHERE CD_COMPANY = '1000'          
							AND CLS_ITEM IN ('003', '005')
					) wb on p.ERP_CD_ITEM = wb.cd_item

WHERE  p.brandseq  = @brand and p.category = @category  and b.item = @item
            and   p.modelno   Like '%' + @modelno + '%'
          -- and p.seq in (select distinct productseq from productprice where active='a')
            and  p.seq not in (select distinct productidx  from productpart
                                                                         where productidx in (select proseq  From productorderdetail
                                                                                                         where orderseq in (select seq From productorder where category = 'a/s부품') )
                                                                              and productidx not in (select proseq  From productorderdetail
                                                           where orderseq in (select seq From productorder where category = '상품') ))
order by p.modelno
--select * from brandname where  brandname like 'cho%'

--select * From brandname where seq in (89,117,127,150)

-- 스톤헨지시계
else if  @item = '주얼리' and ( @modelno = '' and ( @category = 1   and @brand = 150 ) )
  exec psj_HQProductView2_Stonehengewatch_20190711  @item ,@category ,@brand , @modelno 
  -- 스톤헨지시계
--select * from productprice  where productseq =16821


--스톤헨지
else if  @item = '주얼리' and ( @modelno = '' and (( @category = 1  ) and ( @brand <> 89 and @brand <> 117 and @brand <> 127 and @brand <> 150 )   ) )  -- and @brand <> 15) )
 exec psj_HQProductView2_Stonehenge_220104 @item ,@category ,@brand , @modelno ,@reguser 
 
else if  ( @item = '잡화' and @category = 1 )

select p.seq,
          b.item "품목",
          c.name "종류",
          isnull(brandName, '')  "브랜드명",
          ModelNo "모델명",
          series "COLLECTION",
          p.price  "소비자가",
          fobprice  "fob가",
          cost  "IRP"
 from product p left  join brandname b on p.brandseq = b.seq
                        left join (select name, value from codebook where code='goods') c on  p.class= c.value

WHERE  p.brandseq  = @brand and p.category = @category  and b.item = @item
           -- and   p.modelno   Like '%' + @modelno + '%'
      --   and p.seq in (select distinct productseq from productprice where active='a')
order by modelno


--select * from product where modelno ='f725110'

--select * from productprice  where productseq =16821
else if  ( @category = 4 )
select p.seq,
          b.item "품목",
          c.name "종류",
         case when a.imagename is not null then '등록' else '' end "이미지",
          isnull(brandName, '')  "브랜드명",
          ModelNo "모델명",
          case when p.isevent = 1 then '가능' when p.isevent = 2  then '온라인' when p.isevent = 3  then '가능/불' when p.isevent = 4 then '기획'  when p.isevent = 5 then 'DM' when p.isevent = 6 then '면세' when p.isevent = 7 then '악성' when p.isevent = 8 then '악성17'
 when p.isevent = 9 then '악성19' when p.isevent = 10 then '반품진행' else '불가' end "행사",
		  series "시리즈명",
          co.name  "구분",
          case when b.item='시계' then skill.name   else '' end  "기능",
          Gubun "분류",
          sex "성별",
          case when b.item='시계' then band.name else '' end  "밴드",
          case when b.item='시계' then form.name else '' end  "형태",
          case when b.item='시계' then case when couple = 'y' then '커플' else '' end  else '' end  "커플",
          case when b.item='시계' then dial.name   else '' end  "다이알",
        --  p.code "분류코드",
          p.price  "소비자가",
          fobprice  "fob가",
          cost  "현지가"
 from product p left  join brandname b on p.brandseq = b.seq
                        inner join (select name, value from codebook where code='category') c on  p.category = c.value
                        left join (select * from codebook
                                     where code='watchband') band on p.material = band.value
                        left join  (select * from codebook
                                      where  code = case when @item = '시계' then  'watchcategory'
                                                                        else    'jewelrycategory' end ) co on p.class = co.value

                        left join (select * from codebook
                                    where code='watchform') form on p.form = form.value
                       left join (select * from codebook  where code='watchdial') dial on p.dial = dial.value
                       left join (select * From codebook where code='watchskill') skill on p.skill = skill.value
	         left join dpdesc a on a.proseq = p.seq
                    -- left join  OPENQUERY(galleryoclock, 'SELECT * FROM new_product_main')  a on a.mod_no = p.modelno
WHERE  --p.brandseq  = @brand
			p.brandSeq = case when @brand = 0 then p.brandSeq else @brand end
and p.category = @category
and b.item = @item
 and p.active='a'
  --          and   p.modelno   Like '%' + @modelno + '%'
    --   and p.seq in (select distinct productseq from productprice where active='a')
order by b.brandname,modelno


else  if (@item = '주얼리' and @category <> 3)

select p.seq,
          case when @category = 3 then p.gubun else b.item end  "품목",
          c.name "구분",
          isnull(brandName, '')  "브랜드명",
          ModelNo "모델명",

		  isnull(p2.modelno2,'') "모델명2",

         --case when p.isevent = 1 then '가능' when p.isevent = 2  then '온라인' when p.isevent = 3  then '가능/불' when p.isevent = 4 then '기획' when p.isevent = 5 then 'DM' when p.isevent = 6 then '면세' when p.isevent = 7 then '악성' when p.isevent = 8 then '악성17' when p.isevent = 9 then '악성19' when p.isevent = 10 then '반품진행' else '불가' end "행사",
          --case when  se.oprattr = 1 then '가능'  else '불가'  end "행사",
		  --201022 수정
		  case when p.modelno is null then '' else stevent.evntname end "행사", 
		  sex "성별",
          case when b.item ='주얼리' then class.name when @category = 3 then isnull(class1.name,'') else ''  end "품목",
          series "시리즈명",
           case when b.item ='주얼리' then sojae.name else '' end "소재",
          price  "소비자가",
          fobprice  "fob가",
          cost  "현지가"
 from product p left  join brandname b on p.brandseq = b.seq
		                inner join (select name, value from codebook where code='category') c on  p.category = c.value
                        left join ( select * from codebook where  code='jewelrycategory') class on p.class = class.value
                        left join  ( select * from codebook where  code='jewelrysojae') sojae  on  p.material = sojae.value
                        left join ( select * from codebook where  code='freeGiftCategory') class1 on p.class = class1.value
						--LEFT JOIN  (select usedate,proseq,prdattr,oprattr from StonehengeEvent where oprattr =1  ) AS se on  se.proseq=p.seq
					    --LEFT join (select value, name from codebook where code='prdattrgubun_j') prdattrgubun on se.prdattr=prdattrgubun.Value
					    --LEFT join (select value, name from codebook where code='oprattrgubun_j') oprattrgubun on se.oprattr=oprattrgubun.Value
						--201022 수정
						left join (  select proseq, prdattrgubun.name + '/' + oprattrgubun.name evntname 
						 from 
						 (
						 select  proseq,prdattr,oprattr , usedate, isnull(outdate,'2050-12-31') outdate 
						 from StonehengeEvent 
						 where GETDATE()  between usedate and isnull(outdate,'2050-12-31') 
						 union all

						 select proseq,prdattr,oprattr, usedate,outdate
						 from  productEventHistory2
						 where GETDATE()  between usedate and isnull(outdate,'2050-12-31') 
						 ) a 
						   LEFT join (select value, name from codebook where code='prdattrgubun_j') prdattrgubun on a.prdattr = prdattrgubun.Value
						   LEFT join (select value, name from codebook where code='oprattrgubun_j') oprattrgubun on a.oprattr = oprattrgubun.Value
						) stevent on p.seq =   stevent.proseq		
					
						left outer join productmodelno2 p2 on p.seq = p2.proseq 

WHERE  p.category = @category and (@modelno = '' or p.modelno like '%' + @modelno + '%')
AND p.brandSeq =  CASE WHEN @brand= 0 THEN p.brandSeq ELSE @brand END   -- hot diamond에 stonehenge 제품 들어가는 거 수정 170130 by chkim
order by modelno

--220415
else  if (@item = '화장품' and @category <> 3)

select p.seq,
          case when @category = 3 then p.gubun else b.item end  "품목",
          c.name "구분",
          isnull(brandName, '')  "브랜드명",
          ModelNo "모델명",
		  isnull(p2.nm_item,'') "모델명2",
         case when p.isevent = 1 then '가능' when p.isevent = 2  then '온라인' when p.isevent = 3  then '가능/불' when p.isevent = 4 then '기획' when p.isevent = 5 then 'DM' when p.isevent = 6 then '면세' when p.isevent = 7 then '악성' when p.isevent = 8 then '악성17' when p.isevent = 9 then '악성19' when p.isevent = 10 then '반품진행' else '불가' end "행사",
          sex "성별",
          case when b.item ='주얼리' then class.name when @category = 3 then isnull(class1.name,'') else ''  end "품목",
          series "시리즈명",
           case when b.item ='주얼리' then sojae.name else '' end "소재",
          price  "소비자가",
          fobprice  "fob가",
          cost  "현지가"
 from product p left  join brandname b on p.brandseq = b.seq
		                inner join (select name, value from codebook where code='category') c on  p.category = c.value
                        left join ( select * from codebook where  code='jewelrycategory') class on p.class = class.value
                        left join  ( select * from codebook where  code='jewelrysojae') sojae  on  p.material = sojae.value
                        left join ( select * from codebook where  code='freeGiftCategory') class1 on p.class = class1.value

						left outer join ERP_LINK.NEOE.NEOE.MA_PITEM p2 on p.modelno = p2.cd_item and p2.cd_company = '1000' AND p2.CD_PLANT = '1000'

WHERE  p.category = @category and (@modelno = '' or p.modelno like '%' + @modelno + '%')
AND p.brandSeq =  CASE WHEN @brand= 0 THEN p.brandSeq ELSE @brand END   -- hot diamond에 stonehenge 제품 들어가는 거 수정 170130 by chkim
and b.item = @item
order by modelno

else  if (@item <> '주얼리' and @category <> 3)

select p.seq,
          case when @category = 3 then p.gubun else b.item end  "품목",
          c.name "구분",
          isnull(brandName, '')  "브랜드명",
          ModelNo "모델명",
		  isnull(p2.modelno2,'') "모델명2",
         case when p.isevent = 1 then '가능' when p.isevent = 2  then '온라인' when p.isevent = 3  then '가능/불' when p.isevent = 4 then '기획' when p.isevent = 5 then 'DM' when p.isevent = 6 then '면세' when p.isevent = 7 then '악성' when p.isevent = 8 then '악성17' when p.isevent = 9 then '악성19' when p.isevent = 10 then '반품진행' else '불가' end "행사",
          sex "성별",
          case when b.item ='주얼리' then class.name when @category = 3 then isnull(class1.name,'') else ''  end "품목",
          series "시리즈명",
           case when b.item ='주얼리' then sojae.name else '' end "소재",
          price  "소비자가",
          fobprice  "fob가",
          cost  "현지가"
 from product p left  join brandname b on p.brandseq = b.seq
		                inner join (select name, value from codebook where code='category') c on  p.category = c.value
                        left join ( select * from codebook where  code='jewelrycategory') class on p.class = class.value
                        left join  ( select * from codebook where  code='jewelrysojae') sojae  on  p.material = sojae.value
                        left join ( select * from codebook where  code='freeGiftCategory') class1 on p.class = class1.value

						left outer join productmodelno2 p2 on p.seq = p2.proseq 

WHERE  p.category = @category and (@modelno = '' or p.modelno like '%' + @modelno + '%')
AND p.brandSeq =  CASE WHEN @brand= 0 THEN p.brandSeq ELSE @brand END   -- hot diamond에 stonehenge 제품 들어가는 거 수정 170130 by chkim
order by modelno

--사은품
else

select p.seq,
          case when @category = 3 then p.gubun else b.item end  "품목",
          c.name "구분",
          isnull(brandName, '')  "브랜드명",
          ModelNo "모델명",		 
          case when p.isevent = 1 then '가능' else '불가' end "행사",
          --case when p.isevent = 1 then '가능' when p.isevent = 2  then '온라인' when p.isevent = 3  then '가능/불' when p.isevent = 4 then '기획' when p.isevent = 5 then 'DM' when p.isevent = 6 then '면세' when p.isevent = 7 then '악성' when p.isevent = 8 then '악성17' when p.isevent = 9 then '악성19' when p.isevent = 10 then '반품진행' else '불가' end "행사",
		  sex "성별",
          case when b.item ='주얼리' then class.name when @category = 3 and p.gubun='시계'  then isnull(class1.name,'') else ''  end "품목",
          series "시리즈명",
           case when b.item ='주얼리' then sojae.name else '' end "소재",
          price  "소비자가",
          fobprice  "fob가",
          cost  "현지가"
          ,p.regdate "등록일"
 from product p left  join brandname b on isnull(p.code,0)  = b.seq
						inner join (select name, value from codebook where code='category') c on  p.category = c.value
                        left join ( select * from codebook where  code='jewelrycategory') class on p.class = class.value
                        left join  ( select * from codebook where  code='jewelrysojae') sojae  on  p.material = sojae.value
                        left join ( select * from codebook where  code='freeGiftCategory') class1 on p.class = class1.value						
WHERE  p.category = @category and (@modelno = '' or p.modelno like '%' + @modelno + '%')
order by  case when p.gubun = '시계' then 1 when p.gubun='주얼리' then 2 else  3 end , modelno --brandname, modelno

