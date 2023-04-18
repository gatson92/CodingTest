using System;
using System.Linq;
using System.Collections.Generic;

	public class gsumist
	{
		public int pl { get; set; }
		public int seq { get; set; }
		public int rnk { get; set; }
		public string ge { get; set; }
	}
	public class gsum
	{
		public string ge { get; set; }
		public int sum { get; set; }
	}

public class Solution {
    public int[] solution(string[] g, int[] p) {
		// 장르 목록
		List<gsumist> m = new List<gsumist>();
		// 장르별 합계 목록
		List<gsum> su = new List<gsum>();

		int glen = g.Length;

		// 1. list에 초기화
		for (int i = 0; i < glen; i++)
		{
			// 1-1. m에 장르를 담는다.
			m.Add(new gsumist { ge = g[i], pl = p[i], seq = i });

			// 1-2. su에 첫번째 값만 넣는다. 
			if(i == 0)
				su.Add(new gsum {ge = g[i],sum = p[i]});
		}

		// 2. sum에 장르별 재생합계 넣는다. 
		for (int i = 1; i < glen; i++)
		{
			bool isnull = true;

			for (int j = 0; j < su.Count; j++)
			{
				if (su[j].ge == m[i].ge)
				{
					su[j].sum += m[i].pl;
					isnull = false;
					break;
				}

			}
			// 일치하는 장르가 없으면 만들고 금액을 넣어준다. 
			if (isnull)
				su.Add(new gsum { ge = m[i].ge, sum = m[i].pl });
		}

		int sCnt = su.Count;

		// 재생목록별 역순으로 정렬 
		su = su.OrderByDescending(x => x.sum).ToList();

		// rank값 부여 (  sum배열과 같은 장르명을 찾아서 rank입력 )
		for (int i = 0; i < sCnt; i++)
		{
			for (int j = 0; j < glen; j++)
			{
				if (su[i].ge == m[j].ge)
				{
					m[j].rnk = i;
				}

			}
		}


		m = m.OrderByDescending(y => y.pl).OrderBy(x => x.rnk).ToList();
		
		List<int> tmp = new List<int>();


		// top 2개 남기고 지우기 
		for (int i = 0; i < sCnt; i++)
		{
			int grnk = 0;
			// 이전 재생 횟수
			int prepc = -1;

			for (int j = 0; j < glen; j++)
			{
				// 0,1보다 크면 
				if(grnk > 1)
					break;
                
				if (su[i].ge == m[j].ge)
				{
					if (grnk > 1)
						break;
					else
					{
						prepc = m[j].pl;
						tmp.Add(m[j].seq);
						++grnk;
					}
				}
			}
		}
		int[] answer = new int[tmp.Count];

		int tc = tmp.Count;
		for (int i = 0; i < tc; i++) 
			answer[i] = tmp[i];

		return answer;
    }
}