-- 스타일북 상세조회 : exec psj_vueStoneHengeStyleBook_one2 '107406'

/*
SELECT TOP 10 stone,stonesmallgroup,smallgroup,* FROM STYLEBOOK
SELECT TOP 99  * FROM PRODUCT
*/
SELECT	
		AA.PRODUCT_SEQ,			-- 상품SEQ
		AA.OWNMALL_MODEL_NO,	-- 자사몰 모델명(이커머스전용 모델명)
		AA.BRAND_NAME,			-- 브랜드명 
		CASE WHEN AA.CATEGORY = 'N' THEN '목걸이'
			 WHEN AA.CATEGORY = 'A' THEN '발찌'
			 WHEN AA.CATEGORY = 'B' THEN '팔찌'
			 WHEN AA.CATEGORY = 'C' THEN '커플링'
			 WHEN AA.CATEGORY = 'E' THEN '귀걸이'
			 WHEN AA.CATEGORY = 'H' THEN '머리장식'
			 WHEN AA.CATEGORY = 'J' THEN '주얼리ACC'
			 WHEN AA.CATEGORY = 'L' THEN '연장체인'
			 WHEN AA.CATEGORY = 'M' THEN '모바일ACC'
			 WHEN AA.CATEGORY = 'O' THEN '브로찌'
			 WHEN AA.CATEGORY = 'P' THEN '팬던트'
			 WHEN AA.CATEGORY = 'R' THEN '반지'
			 ELSE AA.CATEGORY
		 END AS CATEGORY,		-- 품목
		AA.METALTYPE,			-- 금속
		AA.STONESMALLGROUP,		-- 스톤소재
		AA.STONE,				-- 스톤
		AA.[WEIGHT],			-- 택중량(G)
		AA.SIZE					-- 사이즈
								
								
  FROM 							
	(
		SELECT S.METALTYPE,
				S.STONESMALLGROUP,S.STONE, 
				CASE WHEN B.SEQ = 167 
					 THEN P.JUNGAE 
					 ELSE ISNULL(PJD.TAGMETALWEIGHT, S.METALWEIGHT)
				END [WEIGHT],
				S.SIZE,
			
			    DD.Name					AS MATERIAL
			  ,	S.PROSEQ				AS PRODUCT_SEQ			-- 상품SEQ
			  , A.MODELNO				AS OWNMALL_MODEL_NO		-- 자사몰 모델명(이커머스전용 모델명)
			  , B.BRANDNAME				AS BRAND_NAME			-- 브랜드명 
			  , P.MODELNO				AS MODELNO				-- 모델번호 (MIS FULL MODELNO)
			  , P.ERP_CD_ITEM			AS MODELNO2				-- 모델번호2(NEW MODELNO)
			  , CASE WHEN LEN(P.ERP_CD_ITEM) = 18 AND CHARINDEX('-', P.ERP_CD_ITEM) > 0 
					 THEN LEFT(RIGHT(P.ERP_CD_ITEM, CHARINDEX('-', REVERSE(P.ERP_CD_ITEM))-1),1) 
				 END					AS CATEGORY			-- 카테고리 
			  , ISNULL(S.OPTIONYN,'N')	AS OPTIONYN			-- 옵션여부
			  -- ■ 사이즈 
			  , CEILING(S.MINSIZE)		AS MINSIZE			-- 최소 사이즈
			  , FLOOR (S.MAXSIZE)		AS MAXSIZE			-- 최대 사이즈
			  , S.UNIT										-- 단위
			  , ISNULL(S.UNITPRICE,0)	AS UNITPRICE		-- 옵션 가격
			  , S.READYMADESIZE								-- 기성 사이즈(반지사이즈, 길이)
			  -- ■ 각인
			  , ISNULL(S.ENGRAVE,'N')	AS ENGRAVE			-- 안각인 사용 여부(Y/N)
			  , S.ENGRAVEOUT								-- 겉각인 여부(Y/N)
			  --, S.ENGRAVEPRICE							-- 안각인 비용(10,000으로 동일하여 공통코드에서 가져오기로 함)
			  --, S.ENGRAVEOUTPRICE							-- 겉각인 비용(10,000으로 동일하여 공통코드에서 가져오기로 함)
			  -- ■ 색상
			  , CASE WHEN SUBSTRING(P.ERP_CD_ITEM,14,1) = 'R' THEN 'RG'
					 WHEN SUBSTRING(P.ERP_CD_ITEM,14,1) = 'Y' THEN 'YG'
					 WHEN SUBSTRING(P.ERP_CD_ITEM,14,1) = 'W' THEN 'WG'
					 WHEN SUBSTRING(P.ERP_CD_ITEM,14,1) = 'X' THEN 'WGX'
					 WHEN SUBSTRING(P.ERP_CD_ITEM,14,1) = 'C' THEN 'CB' 
				END						AS READYMADECOLOR	-- 기성색상
			  , S.YG										-- 옐로우 골드
			  , S.RG										-- 로즈 골드 
			  , S.WG										-- 화이트 골드
			  , S.WGX										-- 화이트 무광 골드
			  , S.CB										-- MIX 색상
			  , CC.COM_NM				AS READYMADESTONE	-- 기성 스톤

		FROM (	   
				SELECT MODELNO, FULLMODELNO, 1 AS QTY, SEQ, 'P' AS GUBUN
				FROM ECOMMERCEPRODUCT
				WHERE OWN_YN = 'Y'
				UNION ALL
				SELECT MODELNO, FULLMODELNO, SQTY AS QTY, SEQ, 'S' AS GUBUN
				FROM ECOMMERCESETPRODUCT
				WHERE OWN_YN = 'Y'
			) A  
		  INNER JOIN PRODUCT	P ON A.FULLMODELNO = P.MODELNO
		  INNER JOIN BRANDNAME	B ON P.BRANDSEQ = B.SEQ
		  INNER JOIN TB_OWNMALL_BRAND_STORE_MAPPING BSM ON BSM.BRAND_SEQ = B.SEQ  
		   LEFT JOIN STYLEBOOK S ON S.PROSEQ = P.SEQ
		   LEFT JOIN PRODUCT_JEWELRY_DTL PJD ON P.SEQ = PJD.PROSEQ
		   LEFT JOIN TB_COM_CODE CC ON CC.GRP_CD = 'OWN_OPT_STONE' AND CC.COM_CD = S.READYMADESTONE
		   LEFT OUTER JOIN CODEBOOK DD ON P.MATERIAL = DD.VALUE  AND DD.CODE = 'JEWELRYSOJAE'

		 WHERE 1=1
		   AND P.ACTIVE = 'A'
		   AND B.ACTIVE = '1'
		   AND ISNULL(S.OPTIONYN,'N') = 'Y'

	) AA