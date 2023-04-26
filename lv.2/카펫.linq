<Query Kind="Statements">
  <Namespace>System</Namespace>
  <Namespace>System.Collections.Generic</Namespace>
  <Namespace>System.Linq</Namespace>
</Query>

// [4,3]
int brown = 10;
int yellow = 2;
int width = 0;
int height = 0;

// [3,3]
// brown = 8;
// yellow = 1;

// [8,6]
//brown = 24;
//yellow = 24;

// [6,5]
//brown = 18;
//yellow = 12;

//[8, 3]
brown = 18;
yellow = 6;

int Area = brown + yellow;

int length = 0;

// 약수 구하기 
while (true)
{
	int val = (int)System.Math.Sqrt(Area);

	// 제곱근인경우 
	if (val * val == Area)
	{
		width = (int)val;
		length = (int)val;
		break;
	}
	else
	{
		List<int> lst = new List<int>();

		for (int i = 2; i < Area; i++)
			if (Area % i == 0)
				lst.Add(i);

		while (lst.Count() > 0)
		{
			int middle = lst.Count / 2;
			
			length = lst[middle - 1];
			width = lst[middle];

			if ((length - 2) * (width - 2) == yellow)
			{
				new int[] { width, length }.Dump();
				break;
			}
			else
			{
				lst.RemoveAt(middle - 1);
				lst.RemoveAt(middle - 1);
			}
		}

		break;
	}
}

//int[] answer = new int[] { width, length };


//answer.Dump();
