<Query Kind="Statements" />

//[1, 3, 4, 6] "1223330333221"
//[1, 7, 1, 2]    "111303111"
int[] food = new int[] { 1, 3, 4, 6};
//1223330333221
//1223330333221

food = new int[] { 1, 7, 1, 2};
string answer = "";
string str = "";

for (int i = 1; i<food.Count(); i++) 
{
	int tmp = food[i];
	while (true)
	{
		if (tmp > 1) 
		{
			answer += i;
			tmp = tmp-2;
			i.ToString().Dump("tmp : " + tmp.ToString());
		}
		else
			break;		
	}
}

answer += "0";

for (int i = answer.Length-2; i > -1; i--) 
{
	str += answer[i].ToString();
}
(answer+str).Dump();