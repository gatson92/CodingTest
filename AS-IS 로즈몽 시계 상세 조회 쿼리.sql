--psj_HQProductView2_10 '�ð�',1,186,''
--drop proc psj_HQProductView2_11_20190719
--GRANT exec on psj_HQProductView2_20190719 to execdb   with grant option
--CREATE                  proc  [dbo].[psj_HQProductView2_220104]


declare

  @item varchar(10)		= '�ð�',
  @category tinyint		= 1,
  @brand tinyint		= 129,
  @modelno varchar(30)	= '',
  @reguser varchar(20)	= 'system'
  

--exec psj_HQProductView2_10 @item='�ð�',@category=5,@brand=0,@modelno=''
/*
declare  @item varchar(10)
declare  @category tinyint
declare  @brand tinyint
declare  @modelno varchar(30)
declare  @reguser varchar(20)

set @item = '�־�'
set @category = 4
set @brand = 89
set @modelno = ''
set @reguser='loise'

*/

 declare @rights tinyint
 if exists (  select * from hquserdetail 
            where (�μ� in (  select username  From  ViewRights where  procName ='WatchProductView')
             or  userid  in (  select username  From  ViewRights where  procName ='WatchProductView'))
             and userid =@reguser )
       set @rights = 1
else 
        set @rights = 0
        
declare @premium int
select @premium = case when (type2 = '���ѷ�����' or type = '���ѷ�����') then 1 else 0 end
from brandname where seq = @brand
--select @premium
/*
-- �귣�尡 ���õ��� ���� ��� ��ȸ�� �ʿ� ����
if @brand = 0
select 1
*/

if   @category = 2 --as part
	select p.seq,
			  b.item "ǰ��",
			  co.name "����",
			  brandName "�귣���",
			  ModelNo "�𵨸�",
			  isnull(c.name,'')  "��ǰ����",
			  Gubun "�з�",
			  series "�ø����",
		   --   code "�з��ڵ�",
			  price  "�Һ��ڰ�",
			  fobprice  "fob��",
			  cost  "������"
	 from product p inner join brandname b on p.brandseq = b.seq
						   left  join (select name, value from codebook where code='aspartwatchtype' and @item = '�ð�'
											   union
											 select name, value from codebook where code='aspartjewtype' and @item = '�־�'
											 ) c on  p.parttype = c.value
						  inner join (select name, value from codebook where code='category') co on  p.category = co.value

	WHERE  p.brandseq  = @brand and  p.category = @category   and b.item = @item
	order by modelno
	--select * from brandname where seq  in (7,6,14)]
else if (@brand = 186 )  --archimedes �������� �߰� 2019-07-18
  exec psj_HQProductView2_Archimedes_20190718  @item , @category, @brand , @modelno
  
else if  @item = '�ð�' and ( @modelno = '' and @category = 1  and @brand not in (7,6,14,126) )  -- and @brand <> 15) )
	--select 1
	-- psj_HQProductView2_6 '�ð�',1,56,''
	-- psj_HQProductView2_5 '�ð�',1,56,''

	if (@premium = 0)
	 --200518 �⺻ citizen �� ��ȸ �б�, ��Ŀ�ӽ����� BM�� �ȴٰ� ��(���¿��븮, �忩������)	
	 --�׷��� ��ħ
	 --if(@brand != 124)
 
		 begin
		select distinct p.seq,
				  b.item "ǰ��",
				  c.name "����",
				  case when a.p_idx is not null or aa.modelno is not null then '���' else '' end "Ȩ������",
				  --''  "Ȩ������",
				  isnull(brandName, '')  "�귣���",
				  p.ModelNo "�𵨸�",
				  isnull(p2.modelno2,'') "�𵨸�2",
		--          case when p.isevent = 1 then '����' else '�Ұ�' end "���",
				  case when p.isevent = 1 then '����' when p.isevent = 2  then '�¶���' when p.isevent = 3  then '����/��' when p.isevent = 4 then '��ȹ' when p.isevent = 5 then 'DM' when p.isevent = 6 then '�鼼' when p.isevent = 7 then '�Ǽ�' when p.isevent = 8 then '�Ǽ�17' when 
p.isevent = 9 then '�Ǽ�19' when p.isevent = 10 then '��ǰ����' else '�Ұ�' end "���",
				  Convert(char(10), cp1.usedate, 120) "�ƿ﷿���ʵ����",
				  100 - cp.rate "�ƿ﷿���η�",
				  refercode "��з�", --�߰�
				  case when b.item='�ð�' then origin.name else '' end  "������",
				  CASE when len(series) < 1 then '' else  series end  "�ø����",
				  p.partsname "�����",
				  co.name  "����",
				 case when b.item='�ð�' then skill.name   else
								cast(isnull(minsize,'')  as varchar(3))  +'~' +   cast(isnull(maxsize,'')  as varchar(3))   end  "���",
				  Gubun "�з�",
				  sex "����",
				  --case when b.item='�ð�' then band.name else '' end  "���",
				  --230210 ERP
				  case when b.item='�ð�' then band.NAME  else '' end  "���",
				  case when b.item='�ð�' then form.name else '' end  "����",
				  case when b.item='�ð�' then wcase.name else '' end   "���̽�",
				  p.casesize "���̽�������",
				  case when b.item='�ð�' then case when couple = 'y' then 'Ŀ��' else '' end  else '' end  "Ŀ��",
				  case when b.item='�ð�' then dial.name   else '' end  "������",
				   p.water "���(M)" ,
				--  p.code "�з��ڵ�",
				  p.price  "�Һ��ڰ�",
				  fobprice  "fob��",
				  cost  "������",
				   case when @rights = 1 then  isnull(p.cost0,0) else 0 end "�ʱ����",
				  --p.etcnote "��Ÿ",
				 convert(char(10), p.regdate, 120) "�����"
		--select top 10 * from product
		 from product p left  join brandname b on p.brandseq = b.seq
								inner join (select name, value from codebook where code='category') c on  p.category = c.value
							   --left join (select * from codebook
										--	 where code='watchband') band on p.material = band.value
								left join  (select * from codebook
											  where  code = case when @item = '�ð�' then  'watchcategory'
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
							   --200522 DB���� ��ü�� �����   
							   left join       OPENQUERY(homepage2, 'SELECT * FROM dbo.VIEW_ERP_PRODUCT') a on a.p_code = p.modelno
							   --left join  OPENQUERY(goc, 'SELECT * FROM dbo.VIEW_W_PRODUCT') aa on aa.modelno = p.modelno  
							   --200522 DB���� ��ü�� �����   
							   left join OPENQUERY(homepage2, 'SELECT * FROM dbo.VIEW_ERP_W_PRODUCT') aa on aa.modelno = p.modelno  
							   --left join OPENQUERY(homepage, 'SELECT * FROM dbo.VIEW_ERP_W_PRODUCT') aa on aa.modelno = p.modelno  
							   left join chelsyproduct cp on p.seq = cp.proseq and convert(char(10), getdate(), 120) between cp.usedate and isnull(cp.outdate,'2050-12-31') 
							   left join (select proseq, min(usedate) usedate from  chelsyproduct  where outdate is null group by proseq ) cp1 on p.seq = cp1.proseq
		--          left join  OPENQUERY(galleryoclock, 'SELECT * FROM new_product_main')  a on a.mod_no = p.modelno

								left outer join productmodelno2 p2 on p.seq = p2.proseq 

								--230213 �ð� ��� ERP ������ ���� ���̵���
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
		  aND ( p.seq in (select  distinct proseq  from productorderdetail where orderseq in (select seq from productorder where category = '��ǰ') )  or
				p.seq in (select distinct d.proseq from invoice i inner join invoicedetail d on i.seq = d.inseq where i.orderseq in (select seq from productorder where category = '��ǰ'))
			   or (@brand = 186 and p.seq in (select seq from product where brandseq = @brand and active='a')))
				  and  p.seq not  in (select distinct productidx  from productpart
																				 where productidx in (select proseq  From productorderdetail
																												 where orderseq in (select seq From productorder where category = 'a/s��ǰ') )
																					  and productidx not in (select proseq  From productorderdetail
																   where orderseq in (select seq From productorder where category = '��ǰ') ))
			  ) or ( p.brandseq  = @brand and p.category = @category  and b.item = @item and   p.active='a' and p.regdate > dateadd(d,-30,getdate()))
		  and isnull(series,'') <> 'A/S �����'
  

		--          aND ( p.seq in (select  distinct proseq  from productorderdetail where orderseq in (select seq from productorder where category = '��ǰ') )

		--            and( ( @brand in (14,15)  and
		--               (  p.seq in (select distinct productseq from productprice where active='a')
		--                and ( p.seq in (select  distinct proseq  from productorderdetail where orderseq in (select seq from productorder where category = '��ǰ'))
		--                   or p.seq in (select distinct proseq from storeinventorydetail)      or p.seq in (select distinct proseq from hqinventorydetail) ) ) )
		--                 or @brand  not in (14.15)   and  p.brandseq  = @brand )
		order by p.modelno
		end

	else
	select distinct  p.seq,
			  b.item "ǰ��",
			  c.name "����",
			  case when a.p_idx is not null then '���' else '' end "Ȩ������",
			  --''  "Ȩ������",
			  isnull(brandName, '')  "�귣���",
			-- 'test' "�귣���",
			  ModelNo "�𵨸�",
			  isnull(p2.modelno2,'') "�𵨸�2",
	--          case when p.isevent = 1 then '����' else '�Ұ�' end "���",
			  case when p.isevent = 1 then '����' when p.isevent = 2  then '�¶���' when p.isevent = 3  then '����/��' when p.isevent = 4 then '��ȹ'   when p.isevent = 5 then 'DM' when p.isevent = 6 then '�鼼' when p.isevent = 7 then '�Ǽ�' when p.isevent = 8 then '�Ǽ�17' when
 p.isevent = 9 then '�Ǽ�19' when p.isevent = 10 then '��ǰ����' else '�Ұ�' end "���",
			  Convert(char(10), cp1.usedate, 120) "�ƿ﷿���ʵ����",
			  100 - cp.rate "�ƿ﷿���η�",
			  refercode "��з�", --�߰�
			  case when b.item='�ð�' then origin.name else '' end  "������",
			  series "�ø����",
			  co.name  "����",
			 case when b.item='�ð�' then skill.name   else
							cast(isnull(minsize,'')  as varchar(3))  +'~' +   cast(isnull(maxsize,'')  as varchar(3))   end  "���",
			  Gubun "�з�",
			  sex "����",
			  --case when b.item='�ð�' then band.name else '' end  "���",
			  --230210 ERP
			  case when b.item='�ð�' then band.NAME  else '' end  "���",
			  case when b.item='�ð�' then form.name else '' end  "����",
			  case when b.item='�ð�' then wcase.name else '' end   "���̽�",
	p.casesize "���̽�������",
			  case when b.item='�ð�' then case when couple = 'y' then 'Ŀ��' else '' end  else '' end  "Ŀ��",
			  case when b.item='�ð�' then dial.name   else '' end  "������",
			   p.water "���(M)" ,
			--  p.code "�з��ڵ�",
			  p.price  "�Һ��ڰ�",
			  fobprice  "fob��",
			  cost  "������",
			  --p.etcnote "��Ÿ",
			  case when @rights = 1 then  isnull(p.cost0,0) else 0 end "�ʱ����",
			 convert(char(10), p.regdate, 120) "�����"
	--select top 10 * from product
	 from product p left  join brandname b on p.brandseq = b.seq
							inner join (select name, value from codebook where code='category') c on  p.category = c.value
						   --left join (select * from codebook
									--	 where code='watchband') band on p.material = band.value
							left join  (select * from codebook
										 where  code = case when @item = '�ð�' then  'watchcategory'

																			else    'jewelrycategory' end ) co on p.class = co.value
							 left join (select * from codebook  where code='origin') origin on p.origin= origin.value

							 left join  (select * from codebook   where code='watchcase') wcase on p.color  = wcase.value
	--select top 10 * from product
							left join (select * from codebook
										where code='watchform') form on p.form = form.value
						   left join (select * from codebook  where code='watchdial') dial on p.dial = dial.value
						   left join (select * From codebook where code='watchskill') skill on p.skill = skill.value
						 --left join       OPENQUERY(homepage, 'SELECT * FROM dbo.VIEW_ERP_PRODUCT') a on a.p_code = p.modelno
						 --200522 DB���� ��ü�� ����� 
						 left join       OPENQUERY(homepage2, 'SELECT * FROM dbo.VIEW_ERP_PRODUCT') a on a.p_code = p.modelno
						 left join chelsyproduct cp on p.seq = cp.proseq and convert(char(10), getdate(), 120) between cp.usedate and isnull(cp.outdate,'2050-12-31')
						 left join (select proseq, min(usedate) usedate from  chelsyproduct group by proseq ) cp1 on p.seq = cp1.proseq
	--          left join  OPENQUERY(galleryoclock, 'SELECT * FROM new_product_main')  a on a.mod_no = p.modelno
	--select * from brandname where brandname like 'arch%'

						--210322
						left outer join productmodelno2 p2 on p.seq = p2.proseq 

						--230213 �ð� ��� ERP ������ ���� ���̵���
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
	  aND ( p.seq in (select  distinct proseq  from productorderdetail where orderseq in (select seq from productorder where category = '��ǰ') and p.seq <> 186 )  or
   			 p.seq in (select distinct d.proseq from invoice i inner join invoicedetail d on i.seq = d.inseq where i.orderseq in (select seq from productorder where category = '��ǰ'))
			or  (@brand = 186 and p.seq in (select seq from product where brandseq =186)))
			  and  p.seq not  in (select distinct productidx  from productpart
																			 where productidx in (select proseq  From productorderdetail
																											 where orderseq in (select seq From productorder where category = 'a/s��ǰ') )
																				  and productidx not in (select proseq  From productorderdetail
															   where orderseq in (select seq From productorder where category = '��ǰ') ))
	--          aND ( p.seq in (select  distinct proseq  from productorderdetail where orderseq in (select seq from productorder where category = '��ǰ') )

	--            and( ( @brand in (14,15)  and
	--               (  p.seq in (select distinct productseq from productprice where active='a')
	--                and ( p.seq in (select  distinct proseq  from productorderdetail where orderseq in (select seq from productorder where category = '��ǰ'))
	--                   or p.seq in (select distinct proseq from storeinventorydetail)      or p.seq in (select distinct proseq from hqinventorydetail) ) ) )
	--                 or @brand  not in (14.15)   and  p.brandseq  = @brand )
	order by modelno


--select * from  OPENQUERY(goc, 'SELECT * FROM woorim.view_product') a

else if  @item = '�ð�' and ( @modelno = '' and @category = 1  and @brand=126 )  -- and @brand <> 15) )

	-- psj_HQProductView2_6 '�ð�',1,56,''
	-- psj_HQProductView2_5 '�ð�',1,56,''


	select distinct p.seq,
			  b.item "ǰ��",
			  c.name "����",
			  case when a.p_idx is not null then '���' else '' end "Ȩ������",
			  --''  "Ȩ������",
			  isnull(brandName, '')  "�귣���",
			  ModelNo "�𵨸�",
			  isnull(p2.modelno2,'') "�𵨸�2",
	--          case when p.isevent = 1 then '����' else '�Ұ�' end "���",
			  case when p.isevent = 1 then '����' when p.isevent = 2  then '�¶���' when p.isevent = 3  then '����/��' when p.isevent = 4 then '��ȹ'  when p.isevent = 5 then 'DM' when p.isevent = 6 then '�鼼' when p.isevent = 7 then '�Ǽ�' when p.isevent = 8 then '�Ǽ�17' when 
p.isevent = 9 then '�Ǽ�19' when p.isevent = 10 then '��ǰ����' else '�Ұ�' end "���",
			  Convert(char(10), cp1.usedate, 120) "�ƿ﷿���ʵ����",
			  100 - cp.rate "�ƿ﷿���η�",
			  refercode "��з�", --�߰�
			  case when b.item='�ð�' then origin.name else '' end  "������",
			  series "�ø����",
			  co.name  "����",
			 case when b.item='�ð�' then skill.name   else
							cast(isnull(minsize,'')  as varchar(3))  +'~' +   cast(isnull(maxsize,'')  as varchar(3))   end  "���",
			  Gubun "�з�",
			  sex "����",
			  case when b.item='�ð�' then band.name else '' end  "���",
			  case when b.item='�ð�' then form.name else '' end  "����",
			  case when b.item='�ð�' then wcase.name else '' end   "���̽�",
			  case when b.item='�ð�' then case when couple = 'y' then 'Ŀ��' else '' end  else '' end  "Ŀ��",
			  case when b.item='�ð�' then dial.name   else '' end  "������",
			   p.water "���(M)" ,
			   p.movetype "�����Ʈȣȯ",
			  p.casesize "���̽�������",
			  p.depth "�β�",
			--  p.code "�з��ڵ�",
			  p.price  "�Һ��ڰ�",
			  fobprice  "fob��",
			  cost  "������",
			  --p.etcnote "��Ÿ",
			   case when @rights = 1 then  isnull(p.cost0,0) else 0 end "�ʱ����",
			 convert(char(10), p.regdate, 120) "�����"
	--select top 10 * from product
	 from product p left  join brandname b on p.brandseq = b.seq
							inner join (select name, value from codebook where code='category') c on  p.category = c.value
						   left join (select * from codebook
										 where code='watchband') band on p.material = band.value
							left join  (select * from codebook
										  where  code = case when @item = '�ð�' then  'watchcategory'

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
	  aND ( p.seq in (select  distinct proseq  from productorderdetail where orderseq in (select seq from productorder where category = '��ǰ') )  or
		p.seq in (select distinct d.proseq from invoice i inner join invoicedetail d on i.seq = d.inseq where i.orderseq in (select seq from productorder where category = '��ǰ')))
			  and  p.seq not  in (select distinct productidx  from productpart
																			 where productidx in (select proseq  From productorderdetail
																											 where orderseq in (select seq From productorder where category = 'a/s��ǰ') )
																				  and productidx not in (select proseq  From productorderdetail
															   where orderseq in (select seq From productorder where category = '��ǰ') ))



	-- aND ( p.seq in (select  distinct proseq  from productorderdetail where orderseq in (select seq from productorder where category = '��ǰ') )

	-- and( ( @brand in (14,15)  and
	--( p.seq in (select distinct productseq from productprice where active='a')
	-- and ( p.seq in (select  distinct proseq  from productorderdetail where orderseq in (select seq from productorder where category = '��ǰ'))
	-- or p.seq in (select distinct proseq from storeinventorydetail)      or p.seq in (select distinct proseq from hqinventorydetail) ) ) )
	-- or @brand  not in (14.15)   and  p.brandseq  = @brand )
	order by modelno
                                                                                                                                                       
	--select * From brandname where seq in (7,6,14)

else if ( @item = '�ð�' and  @modelno = '' and @category = 1 and @brand in (7,6,14))

	select distinct  p.seq,
			  b.item "ǰ��",
			  c.name "����",
			case when a.p_idx is not null then '���' else '' end "Ȩ������",
			--''  "Ȩ������",
			  isnull(brandName, '')  "�귣���",
			  ModelNo "�𵨸�",
			  isnull(p2.modelno2,'') "�𵨸�2",
	--          case when p.isevent = 1 then '����' else '�Ұ�' end "���",
			  case when p.isevent = 1 then '����' when p.isevent = 2  then '�¶���' when p.isevent = 3  then '����/��' when p.isevent = 4 then '��ȹ'  when p.isevent = 5 then 'DM' when p.isevent = 6 then '�鼼' when p.isevent = 7 then '�Ǽ�' when p.isevent = 8 then '�Ǽ�17' when 
p.isevent = 9 then '�Ǽ�19' when p.isevent = 10 then '��ǰ����' else '�Ұ�' end "���",
			  Convert(char(10), cp1.usedate, 120) "�ƿ﷿���ʵ����",
			  100 - cp.rate "�ƿ﷿���η�",
			  series "�ø����",

			  co.name  "����",
			 case when b.item='�ð�' then skill.name   else
							cast(isnull(minsize,'')  as varchar(3))  +'~' +   cast(isnull(maxsize,'')  as varchar(3))   end  "���",
			  Gubun "�з�",
			  sex "����",
			  case when b.item='�ð�' then band.name else '' end  "���",
			  case when b.item='�ð�' then form.name else '' end  "����",
			  case when b.item='�ð�' then wcase.name else '' end   "���̽�",
			  case when b.item='�ð�' then dial.name   else '' end  "������",
			   p.water "���(M)" ,
			  case when b.item='�ð�' then case when couple = 'y' then 'Ŀ��' else '' end  else '' end  "Ŀ��",
			--  p.code "�з��ڵ�",
			  p.price  "�Һ��ڰ�",
			  fobprice  "fob��",
			  cost  "������"  ,
			 p.etcnote "��Ÿ",
			 convert(char(10), p.regdate, 120) "�����"
	 from product p left  join brandname b on p.brandseq = b.seq
							inner join (select name, value from codebook where code='category') c on  p.category = c.value
						   left join (select * from codebook
										 where code='watchband') band on p.material = band.value
							left join  (select * from codebook
										  where  code = case when @item = '�ð�' then  'watchcategory'
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
	  aND ( p.seq in (select  distinct proseq  from productorderdetail where orderseq in (select seq from productorder where category = '��ǰ') )  or
		p.seq in (select distinct d.proseq from invoice i inner join invoicedetail d on i.seq = d.inseq where i.orderseq in (select seq from productorder where category = '��ǰ')))
			  and  p.seq not  in (select distinct productidx  from productpart
																			 where productidx in (select proseq  From productorderdetail
																											 where orderseq in (select seq From productorder where category = 'a/s��ǰ') )
																				  and productidx not in (select proseq  From productorderdetail
															   where orderseq in (select seq From productorder where category = '��ǰ') ))


	--            and( ( @brand in (14,15)  and
	--               (  p.seq in (select distinct productseq from productprice where active='a')
	--                and ( p.seq in (select  distinct proseq  from productorderdetail where orderseq in (select seq from productorder where category = '��ǰ'))
	--                   or p.seq in (select distinct proseq from storeinventorydetail)      or p.seq in (select distinct proseq from hqinventorydetail) ) ) )
	--                 or @brand  not in (14.15)   and  p.brandseq  = @brand )
	order by modelno

	--select * from product where modelno ='1032'

	--select * from productprice  where productseq =16821

else if    @item = '�ð�' and ( @modelno <>  '' and (( @category = 1 ) ))
select distinct p.seq,
          b.item "ǰ��",
          c.name "����",
       case when a.p_idx is not null or aa.modelno is not null then '���' else '' end "Ȩ������",
       --''  "Ȩ������",
          isnull(brandName, '')  "�귣���",
          p.ModelNo "�𵨸�",
		  isnull(p2.modelno2,'') "�𵨸�2",
--          case when p.isevent = 1 then '����' else '�Ұ�' end "���",
          case when p.isevent = 1 then '����' when p.isevent = 2  then '�¶���' when p.isevent = 3  then '����/��' when p.isevent = 4 then '��ȹ'  when p.isevent = 5 then 'DM' when p.isevent = 6 then '�鼼' when p.isevent = 7 then '�Ǽ�' when p.isevent = 8 then '�Ǽ�17' 
when p.isevent = 9 then '�Ǽ�19' when p.isevent = 10 then '��ǰ����' else '�Ұ�' end "���",
          Convert(char(10), cp1.usedate, 120) "�ƿ﷿���ʵ����",
          100 - cp.rate "�ƿ﷿���η�",
		  refercode "��з�", --�߰�
		 case when b.item='�ð�' then origin.name else '' end  "������",
          series "�ø����",
          co.name  "����",
          case when b.item='�ð�' then skill.name   else '' end  "���",
          Gubun "�з�",
          sex "����",
          --case when b.item='�ð�' then band.name else '' end  "���",
		  --230210
		  case when b.item='�ð�' then wb.NAME  else '' end  "���",
          case when b.item='�ð�' then form.name else '' end  "����",
          case when b.item='�ð�' then wcase.name else '' end   "���̽�",
p.casesize "���̽�������",
          case when b.item='�ð�' then dial.name   else '' end  "������",
           p.water "���(M)" ,
       --   case when b.item='�ð�' then case when couple = 'y' then 'Ŀ��' else '' end  else '' end  "Ŀ��",
          case when b.item='�ð�' then dial.name   else '' end  "���̾�",
        --  p.code "�з��ڵ�",
          p.price  "�Һ��ڰ�",
          fobprice  "fob��",
          cost  "������"  ,
         --p.etcnote "��Ÿ",
          case when @rights = 1 then  isnull(p.cost0,0) else 0 end "�ʱ����",
         convert(char(10), p.regdate, 120) "�����"
 from product p left  join brandname b on p.brandseq = b.seq
                        inner join (select name, value from codebook where code='category') c on  p.category = c.value
                       left join (select * from codebook

                                     where code='watchband') band on p.material = band.value
                        left join  (select * from codebook
                                      where  code = case when @item = '�ð�' then  'watchcategory'
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
                                                                                                         where orderseq in (select seq From productorder where category = 'a/s��ǰ') )
                                                                              and productidx not in (select proseq  From productorderdetail
                                                           where orderseq in (select seq From productorder where category = '��ǰ') ))
order by p.modelno
--select * from brandname where  brandname like 'cho%'

--select * From brandname where seq in (89,117,127,150)

-- ���������ð�
else if  @item = '�־�' and ( @modelno = '' and ( @category = 1   and @brand = 150 ) )
  exec psj_HQProductView2_Stonehengewatch_20190711  @item ,@category ,@brand , @modelno 
  -- ���������ð�
--select * from productprice  where productseq =16821


--��������
else if  @item = '�־�' and ( @modelno = '' and (( @category = 1  ) and ( @brand <> 89 and @brand <> 117 and @brand <> 127 and @brand <> 150 )   ) )  -- and @brand <> 15) )
 exec psj_HQProductView2_Stonehenge_220104 @item ,@category ,@brand , @modelno ,@reguser 
 
else if  ( @item = '��ȭ' and @category = 1 )

select p.seq,
          b.item "ǰ��",
          c.name "����",
          isnull(brandName, '')  "�귣���",
          ModelNo "�𵨸�",
          series "COLLECTION",
          p.price  "�Һ��ڰ�",
          fobprice  "fob��",
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
          b.item "ǰ��",
          c.name "����",
         case when a.imagename is not null then '���' else '' end "�̹���",
          isnull(brandName, '')  "�귣���",
          ModelNo "�𵨸�",
          case when p.isevent = 1 then '����' when p.isevent = 2  then '�¶���' when p.isevent = 3  then '����/��' when p.isevent = 4 then '��ȹ'  when p.isevent = 5 then 'DM' when p.isevent = 6 then '�鼼' when p.isevent = 7 then '�Ǽ�' when p.isevent = 8 then '�Ǽ�17'
 when p.isevent = 9 then '�Ǽ�19' when p.isevent = 10 then '��ǰ����' else '�Ұ�' end "���",
		  series "�ø����",
          co.name  "����",
          case when b.item='�ð�' then skill.name   else '' end  "���",
          Gubun "�з�",
          sex "����",
          case when b.item='�ð�' then band.name else '' end  "���",
          case when b.item='�ð�' then form.name else '' end  "����",
          case when b.item='�ð�' then case when couple = 'y' then 'Ŀ��' else '' end  else '' end  "Ŀ��",
          case when b.item='�ð�' then dial.name   else '' end  "���̾�",
        --  p.code "�з��ڵ�",
          p.price  "�Һ��ڰ�",
          fobprice  "fob��",
          cost  "������"
 from product p left  join brandname b on p.brandseq = b.seq
                        inner join (select name, value from codebook where code='category') c on  p.category = c.value
                        left join (select * from codebook
                                     where code='watchband') band on p.material = band.value
                        left join  (select * from codebook
                                      where  code = case when @item = '�ð�' then  'watchcategory'
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


else  if (@item = '�־�' and @category <> 3)

select p.seq,
          case when @category = 3 then p.gubun else b.item end  "ǰ��",
          c.name "����",
          isnull(brandName, '')  "�귣���",
          ModelNo "�𵨸�",

		  isnull(p2.modelno2,'') "�𵨸�2",

         --case when p.isevent = 1 then '����' when p.isevent = 2  then '�¶���' when p.isevent = 3  then '����/��' when p.isevent = 4 then '��ȹ' when p.isevent = 5 then 'DM' when p.isevent = 6 then '�鼼' when p.isevent = 7 then '�Ǽ�' when p.isevent = 8 then '�Ǽ�17' when p.isevent = 9 then '�Ǽ�19' when p.isevent = 10 then '��ǰ����' else '�Ұ�' end "���",
          --case when  se.oprattr = 1 then '����'  else '�Ұ�'  end "���",
		  --201022 ����
		  case when p.modelno is null then '' else stevent.evntname end "���", 
		  sex "����",
          case when b.item ='�־�' then class.name when @category = 3 then isnull(class1.name,'') else ''  end "ǰ��",
          series "�ø����",
           case when b.item ='�־�' then sojae.name else '' end "����",
          price  "�Һ��ڰ�",
          fobprice  "fob��",
          cost  "������"
 from product p left  join brandname b on p.brandseq = b.seq
		                inner join (select name, value from codebook where code='category') c on  p.category = c.value
                        left join ( select * from codebook where  code='jewelrycategory') class on p.class = class.value
                        left join  ( select * from codebook where  code='jewelrysojae') sojae  on  p.material = sojae.value
                        left join ( select * from codebook where  code='freeGiftCategory') class1 on p.class = class1.value
						--LEFT JOIN  (select usedate,proseq,prdattr,oprattr from StonehengeEvent where oprattr =1  ) AS se on  se.proseq=p.seq
					    --LEFT join (select value, name from codebook where code='prdattrgubun_j') prdattrgubun on se.prdattr=prdattrgubun.Value
					    --LEFT join (select value, name from codebook where code='oprattrgubun_j') oprattrgubun on se.oprattr=oprattrgubun.Value
						--201022 ����
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
AND p.brandSeq =  CASE WHEN @brand= 0 THEN p.brandSeq ELSE @brand END   -- hot diamond�� stonehenge ��ǰ ���� �� ���� 170130 by chkim
order by modelno

--220415
else  if (@item = 'ȭ��ǰ' and @category <> 3)

select p.seq,
          case when @category = 3 then p.gubun else b.item end  "ǰ��",
          c.name "����",
          isnull(brandName, '')  "�귣���",
          ModelNo "�𵨸�",
		  isnull(p2.nm_item,'') "�𵨸�2",
         case when p.isevent = 1 then '����' when p.isevent = 2  then '�¶���' when p.isevent = 3  then '����/��' when p.isevent = 4 then '��ȹ' when p.isevent = 5 then 'DM' when p.isevent = 6 then '�鼼' when p.isevent = 7 then '�Ǽ�' when p.isevent = 8 then '�Ǽ�17' when p.isevent = 9 then '�Ǽ�19' when p.isevent = 10 then '��ǰ����' else '�Ұ�' end "���",
          sex "����",
          case when b.item ='�־�' then class.name when @category = 3 then isnull(class1.name,'') else ''  end "ǰ��",
          series "�ø����",
           case when b.item ='�־�' then sojae.name else '' end "����",
          price  "�Һ��ڰ�",
          fobprice  "fob��",
          cost  "������"
 from product p left  join brandname b on p.brandseq = b.seq
		                inner join (select name, value from codebook where code='category') c on  p.category = c.value
                        left join ( select * from codebook where  code='jewelrycategory') class on p.class = class.value
                        left join  ( select * from codebook where  code='jewelrysojae') sojae  on  p.material = sojae.value
                        left join ( select * from codebook where  code='freeGiftCategory') class1 on p.class = class1.value

						left outer join ERP_LINK.NEOE.NEOE.MA_PITEM p2 on p.modelno = p2.cd_item and p2.cd_company = '1000' AND p2.CD_PLANT = '1000'

WHERE  p.category = @category and (@modelno = '' or p.modelno like '%' + @modelno + '%')
AND p.brandSeq =  CASE WHEN @brand= 0 THEN p.brandSeq ELSE @brand END   -- hot diamond�� stonehenge ��ǰ ���� �� ���� 170130 by chkim
and b.item = @item
order by modelno

else  if (@item <> '�־�' and @category <> 3)

select p.seq,
          case when @category = 3 then p.gubun else b.item end  "ǰ��",
          c.name "����",
          isnull(brandName, '')  "�귣���",
          ModelNo "�𵨸�",
		  isnull(p2.modelno2,'') "�𵨸�2",
         case when p.isevent = 1 then '����' when p.isevent = 2  then '�¶���' when p.isevent = 3  then '����/��' when p.isevent = 4 then '��ȹ' when p.isevent = 5 then 'DM' when p.isevent = 6 then '�鼼' when p.isevent = 7 then '�Ǽ�' when p.isevent = 8 then '�Ǽ�17' when p.isevent = 9 then '�Ǽ�19' when p.isevent = 10 then '��ǰ����' else '�Ұ�' end "���",
          sex "����",
          case when b.item ='�־�' then class.name when @category = 3 then isnull(class1.name,'') else ''  end "ǰ��",
          series "�ø����",
           case when b.item ='�־�' then sojae.name else '' end "����",
          price  "�Һ��ڰ�",
          fobprice  "fob��",
          cost  "������"
 from product p left  join brandname b on p.brandseq = b.seq
		                inner join (select name, value from codebook where code='category') c on  p.category = c.value
                        left join ( select * from codebook where  code='jewelrycategory') class on p.class = class.value
                        left join  ( select * from codebook where  code='jewelrysojae') sojae  on  p.material = sojae.value
                        left join ( select * from codebook where  code='freeGiftCategory') class1 on p.class = class1.value

						left outer join productmodelno2 p2 on p.seq = p2.proseq 

WHERE  p.category = @category and (@modelno = '' or p.modelno like '%' + @modelno + '%')
AND p.brandSeq =  CASE WHEN @brand= 0 THEN p.brandSeq ELSE @brand END   -- hot diamond�� stonehenge ��ǰ ���� �� ���� 170130 by chkim
order by modelno

--����ǰ
else

select p.seq,
          case when @category = 3 then p.gubun else b.item end  "ǰ��",
          c.name "����",
          isnull(brandName, '')  "�귣���",
          ModelNo "�𵨸�",		 
          case when p.isevent = 1 then '����' else '�Ұ�' end "���",
          --case when p.isevent = 1 then '����' when p.isevent = 2  then '�¶���' when p.isevent = 3  then '����/��' when p.isevent = 4 then '��ȹ' when p.isevent = 5 then 'DM' when p.isevent = 6 then '�鼼' when p.isevent = 7 then '�Ǽ�' when p.isevent = 8 then '�Ǽ�17' when p.isevent = 9 then '�Ǽ�19' when p.isevent = 10 then '��ǰ����' else '�Ұ�' end "���",
		  sex "����",
          case when b.item ='�־�' then class.name when @category = 3 and p.gubun='�ð�'  then isnull(class1.name,'') else ''  end "ǰ��",
          series "�ø����",
           case when b.item ='�־�' then sojae.name else '' end "����",
          price  "�Һ��ڰ�",
          fobprice  "fob��",
          cost  "������"
          ,p.regdate "�����"
 from product p left  join brandname b on isnull(p.code,0)  = b.seq
						inner join (select name, value from codebook where code='category') c on  p.category = c.value
                        left join ( select * from codebook where  code='jewelrycategory') class on p.class = class.value
                        left join  ( select * from codebook where  code='jewelrysojae') sojae  on  p.material = sojae.value
                        left join ( select * from codebook where  code='freeGiftCategory') class1 on p.class = class1.value						
WHERE  p.category = @category and (@modelno = '' or p.modelno like '%' + @modelno + '%')
order by  case when p.gubun = '�ð�' then 1 when p.gubun='�־�' then 2 else  3 end , modelno --brandname, modelno

