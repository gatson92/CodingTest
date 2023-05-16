-- ��Ÿ�Ϻ� ����ȸ : exec psj_vueStoneHengeStyleBook_one2 '107406'

/*
SELECT TOP 10 stone,stonesmallgroup,smallgroup,* FROM STYLEBOOK
SELECT TOP 99  * FROM PRODUCT
*/
SELECT	
		AA.PRODUCT_SEQ,			-- ��ǰSEQ
		AA.OWNMALL_MODEL_NO,	-- �ڻ�� �𵨸�(��Ŀ�ӽ����� �𵨸�)
		AA.BRAND_NAME,			-- �귣��� 
		CASE WHEN AA.CATEGORY = 'N' THEN '�����'
			 WHEN AA.CATEGORY = 'A' THEN '����'
			 WHEN AA.CATEGORY = 'B' THEN '����'
			 WHEN AA.CATEGORY = 'C' THEN 'Ŀ�ø�'
			 WHEN AA.CATEGORY = 'E' THEN '�Ͱ���'
			 WHEN AA.CATEGORY = 'H' THEN '�Ӹ����'
			 WHEN AA.CATEGORY = 'J' THEN '�־�ACC'
			 WHEN AA.CATEGORY = 'L' THEN '����ü��'
			 WHEN AA.CATEGORY = 'M' THEN '�����ACC'
			 WHEN AA.CATEGORY = 'O' THEN '�����'
			 WHEN AA.CATEGORY = 'P' THEN '�Ҵ�Ʈ'
			 WHEN AA.CATEGORY = 'R' THEN '����'
			 ELSE AA.CATEGORY
		 END AS CATEGORY,		-- ǰ��
		AA.METALTYPE,			-- �ݼ�
		AA.STONESMALLGROUP,		-- �������
		AA.STONE,				-- ����
		AA.[WEIGHT],			-- ���߷�(G)
		AA.SIZE					-- ������
								
								
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
			  ,	S.PROSEQ				AS PRODUCT_SEQ			-- ��ǰSEQ
			  , A.MODELNO				AS OWNMALL_MODEL_NO		-- �ڻ�� �𵨸�(��Ŀ�ӽ����� �𵨸�)
			  , B.BRANDNAME				AS BRAND_NAME			-- �귣��� 
			  , P.MODELNO				AS MODELNO				-- �𵨹�ȣ (MIS FULL MODELNO)
			  , P.ERP_CD_ITEM			AS MODELNO2				-- �𵨹�ȣ2(NEW MODELNO)
			  , CASE WHEN LEN(P.ERP_CD_ITEM) = 18 AND CHARINDEX('-', P.ERP_CD_ITEM) > 0 
					 THEN LEFT(RIGHT(P.ERP_CD_ITEM, CHARINDEX('-', REVERSE(P.ERP_CD_ITEM))-1),1) 
				 END					AS CATEGORY			-- ī�װ� 
			  , ISNULL(S.OPTIONYN,'N')	AS OPTIONYN			-- �ɼǿ���
			  -- �� ������ 
			  , CEILING(S.MINSIZE)		AS MINSIZE			-- �ּ� ������
			  , FLOOR (S.MAXSIZE)		AS MAXSIZE			-- �ִ� ������
			  , S.UNIT										-- ����
			  , ISNULL(S.UNITPRICE,0)	AS UNITPRICE		-- �ɼ� ����
			  , S.READYMADESIZE								-- �⼺ ������(����������, ����)
			  -- �� ����
			  , ISNULL(S.ENGRAVE,'N')	AS ENGRAVE			-- �Ȱ��� ��� ����(Y/N)
			  , S.ENGRAVEOUT								-- �Ѱ��� ����(Y/N)
			  --, S.ENGRAVEPRICE							-- �Ȱ��� ���(10,000���� �����Ͽ� �����ڵ忡�� ��������� ��)
			  --, S.ENGRAVEOUTPRICE							-- �Ѱ��� ���(10,000���� �����Ͽ� �����ڵ忡�� ��������� ��)
			  -- �� ����
			  , CASE WHEN SUBSTRING(P.ERP_CD_ITEM,14,1) = 'R' THEN 'RG'
					 WHEN SUBSTRING(P.ERP_CD_ITEM,14,1) = 'Y' THEN 'YG'
					 WHEN SUBSTRING(P.ERP_CD_ITEM,14,1) = 'W' THEN 'WG'
					 WHEN SUBSTRING(P.ERP_CD_ITEM,14,1) = 'X' THEN 'WGX'
					 WHEN SUBSTRING(P.ERP_CD_ITEM,14,1) = 'C' THEN 'CB' 
				END						AS READYMADECOLOR	-- �⼺����
			  , S.YG										-- ���ο� ���
			  , S.RG										-- ���� ��� 
			  , S.WG										-- ȭ��Ʈ ���
			  , S.WGX										-- ȭ��Ʈ ���� ���
			  , S.CB										-- MIX ����
			  , CC.COM_NM				AS READYMADESTONE	-- �⼺ ����

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