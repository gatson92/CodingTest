<Query Kind="Statements" />

//2
string t  = "";
string p  = "";
int result = 0;

t  = "3141592";
p  = "271";
// 8
 t = "500220839878";
 p = "7";

// 3
 t = "10203";
 p = "15";

int pLen = p.Length;

while (true) 
{

	if (t.Length >= pLen) 
	{
		string tmp = t.Substring(0,pLen);
		
		//t.Dump(tmp + " : " + p);
		
		if(Convert.ToInt64(tmp) <= Convert.ToInt64(p))
			result++;
		
		t = t.Substring(1,t.Length-1);
		
		//t.Dump();
		//continue;
		
	}
	else break;
}

result.Dump();


