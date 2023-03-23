<Query Kind="Statements" />

int n = 3;
string[] words = {"tank", "kick", "know", "wheel", "land", "dream", "mother", "robot", "tank"};

int person = 2;
int playCnt = 1;

bool IsWrong = false;
bool IsOverlap = false;
bool correctDivided = words.Length % n == 0 ? true : false;

int[] answer = {0,0};

for (int i = 1; i < words.Length; i++) 
{	
	if (words[i-1].Last() == words[i].First())
	{
		// overlap check
		for (int j = 0; j < i; j++) 
			if(words[i] == words[j])
				IsOverlap = true;
		if (IsOverlap) // overlap 
			break;
	}
	else // wrong word 
	{
		IsWrong = true;
		break;
	}

	//(words.Length-1).Dump(i.ToString());
	if (i == words.Length-2)
	{
		person = person+1 > n ? 1 : ++person;
		
		// overlap check
		for (int j = 0; j < i; j++)
			if (words[i+1] == words[j])
				IsOverlap = true;

		// last -> first check
		if ( !correctDivided && words[i + 1].Last() != words[0].First())
			IsWrong = true;
		
		if(IsOverlap || IsWrong)
			break;

	}
	else
	{
		if(person+1 > n)
		{
			person = 1;
			playCnt++;
		}
		else ++person;		
	}
		
}



if (IsOverlap || IsWrong)
{
	answer[0] = person;
	answer[1] = playCnt;
}


answer.Dump();