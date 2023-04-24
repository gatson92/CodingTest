<Query Kind="Statements" />

int a = 3;
int b = 2;
int n = 10;
int rs = 0; // 16
int tmp = 0;

while (n >= a) {
    
	tmp = (n/a)*b;
	n = tmp + n%a;
	
	rs += tmp;
	tmp.Dump();
} 
	


rs.ToString().Dump();