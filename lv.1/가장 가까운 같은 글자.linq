<Query Kind="Statements" />

//[-1, -1, -1, 2, 2, 2]
string s = "banana";
int[] answer = new int[s.Length];

//[-1, -1, 1, -1, -1, -1]
s = "foobar";

for (int i = 0; i < s.Length; i++) {

	int cnt = -1;
	
	if (i == 0) 
	{		
		answer[i] = cnt;
		continue;
	}
		

	for (int j = i-1; j > -1; j--) {

		if (s[j].ToString() == s[i].ToString()) 
		{
			answer[i] = i-j;
			break;
		}
			
		else
			answer[i] = cnt;
	}
}

answer.Dump();
