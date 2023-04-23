<Query Kind="Statements" />

int[] number = new int[]{-2, 3, 0, 2, -5};
number = new int[]{-3, -2, -1, 0, 1, 2, 3};
int answer = 0;
// , 두 번째, 네 번째, 다섯 번째 학생의 정수
// 1/3/4
for (int i = 0; i < number.Length-2; i++) 
{
	for (int j = i+1; j < number.Length - 1 ; j++) {
		
		for(int k = j+1; k < number.Length; k++){

			if (number[i] + number[j] + number[k] == 0) {
				answer++;
				

			}
				(number[i].ToString() + " " +
				number[j].ToString() + " " +
				number[k].ToString()).Dump("i:" + i.ToString() + " j:"
				+ j.ToString() + " k:"
				+ k.ToString() + " ");


		}
	}
	
}

answer.ToString().Dump();