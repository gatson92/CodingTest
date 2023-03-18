<Query Kind="Statements" />

string s = "(())()";
bool answer = false;
int sum = 0;


for(int i =0; i < s.Length;i++)
{
	if (s[i] == '(')
		++sum;		
	else
		--sum;
	if (sum < 0) 
		break;

}

if (sum == 0)
	answer = true;

answer.Dump();