<Query Kind="Statements" />

string s = "01110";

int cnt = 0; 		// 이진 변환 횟수
int zeroCnt = 0;	// 제거된 0의 개수
while (s != "1")
{
	// 0 제거
	int beforeLen = s.Length;
	s = s.Replace("0", "");
	int afterLen = s.Length;
	zeroCnt += beforeLen - afterLen;

	// 이진 변환
	s = Convert.ToString(s.Length, 2);
	cnt++;
}

int[] answer = new int[] { cnt, zeroCnt };
answer.Dump();