<Query Kind="Statements" />

//long l = 37; // 494209
//int l = 10; // 3025 
long l = 8764891; // 831853577
long sum = 0;


sum = (((l+1)*l)/2)%1000000007;
sum = sum*sum;
(sum % 1000000007).ToString().Dump();