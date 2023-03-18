<Query Kind="Statements" />

// 행렬 곱셈 최솟값 구하기 
int[] A = {1,4,2};
int[] B = {5,4,4};
int answer = 0;

List<int> a = A.OrderBy(x=>x).ToList();
List<int> b = B.OrderByDescending(x=>x).ToList();

for (int i = 0; i < a.Count(); i++) 
	answer += a[i]*b[i];

//a.Dump();
//b.Dump();
answer.Dump();