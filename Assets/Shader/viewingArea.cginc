float CalcViewingArea1to6per25(float d)
{
	if(d < 0.5) return 1.0;
	else if(d < 1.5) return 1.0 - 1.0 / 4.0 * (d - 0.5) * (d - 0.5);
	else if(d < 2.5) return 3.0 / 4.0 - 1.0 / 2.0 * (d - 1.5);
	else if(d < 3.5) return 1.0 / 4.0 * (d - 3.5) * (d - 3.5);
	else return 0;	
}

float CalcViewingArea1to6per50(float d)
{
	if(d < 2.5) return 1.0;
	else if(d < 3.5) return 1.0 - 1.0 / 4.0 * (d - 2.5) * (d - 2.5);
	else if(d < 4.5) return 3.0 / 4.0 - 1.0 / 2.0 * (d - 3.5);
	else if(d < 5.5) return 1.0 / 4.0 * (d - 5.5) * (d - 5.5);
	else return 0;	
}

float CalcViewingArea3to23(float d)
{
	if(d < 43.0 / 6.0) return 1.0;
	else if(d < 49.0 / 6.0) return 1.0 - 3.0 / 46.0 * (d - 43.0 / 6.0) * (d - 43.0 / 6.0);
	else if(d < 89.0 / 6.0) return 43.0 / 46.0 - 3.0 / 23.0 * (d - 49.0 / 6);
	else if(d < 95.0 / 6.0) return 3.0 / 46.0 * (d - 95.0 / 6.0) * (d - 95.0 / 6.0);
	else return 0;
}