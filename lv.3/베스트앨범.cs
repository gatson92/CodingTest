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
		// �帣 ���
		List<gsumist> m = new List<gsumist>();
		// �帣�� �հ� ���
		List<gsum> su = new List<gsum>();

		int glen = g.Length;

		// 1. list�� �ʱ�ȭ
		for (int i = 0; i < glen; i++)
		{
			// 1-1. m�� �帣�� ��´�.
			m.Add(new gsumist { ge = g[i], pl = p[i], seq = i });

			// 1-2. su�� ù��° ���� �ִ´�. 
			if(i == 0)
				su.Add(new gsum {ge = g[i],sum = p[i]});
		}

		// 2. sum�� �帣�� ����հ� �ִ´�. 
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
			// ��ġ�ϴ� �帣�� ������ ����� �ݾ��� �־��ش�. 
			if (isnull)
				su.Add(new gsum { ge = m[i].ge, sum = m[i].pl });
		}

		int sCnt = su.Count;

		// �����Ϻ� �������� ���� 
		su = su.OrderByDescending(x => x.sum).ToList();

		// rank�� �ο� (  sum�迭�� ���� �帣���� ã�Ƽ� rank�Է� )
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


		// top 2�� ����� ����� 
		for (int i = 0; i < sCnt; i++)
		{
			int grnk = 0;
			// ���� ��� Ƚ��
			int prepc = -1;

			for (int j = 0; j < glen; j++)
			{
				// 0,1���� ũ�� 
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