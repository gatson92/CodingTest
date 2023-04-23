<Query Kind="Statements" />

string str = "abcdefghijklmnopqrstuvwxyz";
string s = "AaZz";
string answer = "";
int n = 25;
bool LowerChk = false;

for (int i = 0; i < s.Length; i++) {

	if (s[i] == ' ') 
	{
		answer += " ";
		continue;
	}
	
	
	char x = s[i];
	LowerChk = System.Char.IsLower(x);
	
	if(!LowerChk)
		x = Char.ToLower(x);
		
	//LowerChk.ToString().Dump();
	//x.ToString().Dump();
	
	//str.IndexOf(x).ToString().Dump();
	
	int loc = str.IndexOf(x);
	
	loc = loc+n > 25 ? (loc+n-1) % 25 : loc+n;
	//((loc+n) % 25).ToString().Dump(i.ToString());
		
	x = str[loc];
	
	//i.ToString().Dump(x.ToString());
	answer += LowerChk ? x.ToString() : Char.ToUpper(x).ToString();
}

answer.Dump();