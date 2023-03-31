<Query Kind="Statements" />


string input = "37 4";
var tmp = input.Split(' ');

int len = Convert.ToInt32(tmp[0]);
int k = Convert.ToInt32(tmp[1]);


int n = len-(k);
int cnt = n/(k-1) + 1;

if(n%(k-1) > 0)
 cnt +=1;

cnt.Dump();