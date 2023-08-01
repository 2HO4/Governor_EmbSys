/*Instructions to Run
On Your Computer:
	arm-linux-androideabi-clang++ -static-libstdc++ Governor.cpp -o Governor
	adb push Governor /data/local/Working_dir
On the Board:
	chmod +x Governor.sh
	./Governor graph_alexnet_all_pipe_sync #TotalParts #TargetFPS #TargetLatency
*/


#include <stdio.h>      /* printf */
#include <stdlib.h>     /* system, NULL, EXIT_FAILURE */
#include <iostream>
#include <algorithm>
#include <fstream>
#include <sstream>
#include <cmath>
#include <ctime>



using namespace std;


int LittleFrequencyTable[]={500000, 667000, 1000000, 1200000, 1398000, 1512000, 1608000, 1704000, 1800000};
int BigFrequencyTable[]={500000, 667000, 1000000, 1200000, 1398000, 1512000, 1608000, 1704000, 1800000, 1908000, 2016000, 2100000, 2208000};

float LittleModel[]={2.25675619e-13,-1.68652700e-07,2.04314929e+00};
float BigModel[]={9.91799875e-13,-1.09918631e-06,2.53383187e+00};
float gpuModel[]={3.05,0,0};

int LittleFrequencyCounter=4;
int BigFrequencyCounter=6;

int MaxLittleFrequencyCounter=8;
int MaxBigFrequencyCounter=12;

float Latency = 0;
float FPS = 0;

float StageOneInferenceTime=0;
float StageTwoInferenceTime=0;
float StageThreeInferenceTime=0;

int TotalParts=0;
int Target_FPS=0;
int Target_Latency=0;

int bestLittle = 8;
int bestBig = 12;
int gpu = 1;

string Graph;
int N_Frames = 5;

typedef enum mode: int
{

	none = 0,low = 3,mid = 8,high = 12,
}mode;

typedef struct modes
{
	mode big;
	mode little;
	int gpu;
} modes;


void changeFrequencies()
{
	string Command;
	Command="echo " + to_string(LittleFrequencyTable[LittleFrequencyCounter]) + " > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq";
	system(Command.c_str());
	Command="echo " + to_string(BigFrequencyTable[BigFrequencyCounter]) + " > /sys/devices/system/cpu/cpufreq/policy2/scaling_max_freq";
	system(Command.c_str());
}

float Model(int x, float model[])
{
	float sum = 0;
	float pow = 1;
	for(int i =0; i < 3; i++)
	{
		sum += model[0] * pow;
		pow *= x;
	}
	return sum;

}

int modes_num(modes mod)
{
	int core = 0;
	if (mod.big == 0)
	{
		core += 1;
	}
	if (mod.little == 0)
	{
		core+= 1;
	}
	if (mod.gpu == 0)
	{
		core += 1;
	}
	return core;
}

string modes_to_freq(modes mod,int &PartitionPoint1, int &PartitionPoint2)
{
	int core = modes_num(mod);
	string s = "B-G-L";
	// if it core 2s.
	if (core == 1)
	{
		if (mod.big == 0)
		{
			s = "G-L-B";
			PartitionPoint1 = (TotalParts/3) * 2;
		}
		else if (mod.gpu == 0)
		{
			s ="B-L-G";
			PartitionPoint1 = (TotalParts/3) * 2;
		}
		else if (mod.little == 0)
		{
			PartitionPoint1 = TotalParts /2;
		}
		PartitionPoint2 = TotalParts;

	}

	if  (core == 2)
	{
		if (mod.gpu != 0)
		{
			s = "G-L-B";
		}
		else if (mod.little != 0)
		{
			s = "L-B-G";
		}
		PartitionPoint1 = TotalParts;
		PartitionPoint2 = TotalParts;
	}

	if (mod.big != 0)
	{
		BigFrequencyCounter = mod.big;
	}
	if (mod.little != 0)
	{
		LittleFrequencyCounter = mod.little;
	}
	changeFrequencies();

	return s;
}


/* Get feedback by parsing the results */
void ParseResults() {
	ifstream myfile("output.txt");
	cout<<endl;
	/* Read Output.txt File and Extract Data */
	for( std::string line; getline( myfile, line ); )
	{
		string temp;
		/* Extract Frame Rate */
		if ( line.find("Frame rate is:")==0 ){
			//cout<<"line is: "<<line<<std::endl;
			std::istringstream ss(line);
			while (!ss.eof()) {
				/* extracting word by word from stream */
				ss >> temp;
				/* Checking the given word is float or not */
				if (stringstream(temp) >> FPS){
					printf("Throughput is: %f FPS\n", FPS);
					break;
				}
				temp = "";
			}
		}
		/* Extract Frame Latency */
		if ( line.find("Frame latency is:")==0 ){
			//cout<<"line is: "<<line<<std::endl;
			std::istringstream ss(line);
			while (!ss.eof()) {
				/* extracting word by word from stream */
				ss >> temp;
				/* Checking the given word is float or not */
				if (stringstream(temp) >> Latency){
					printf("Latency is: %f ms\n", Latency);
					break;
				}
				temp = "";
			}
		}
		/* Extract Stage One Inference Time */
		if ( line.find("stage1_inference_time:")==0 ){
			//cout<<"line is: "<<line<<std::endl;
			std::istringstream ss(line);
			while (!ss.eof()) {
				/* extracting word by word from stream */
				ss >> temp;
				/* Checking the given word is float or not */
				if (stringstream(temp) >> StageOneInferenceTime){
					//printf("StageOneInferenceTime is: %f ms\n", StageOneInferenceTime);
					break;
				}
				temp = "";
			}
		}
		/* Extract Stage Two Inference Time */
		if ( line.find("stage2_inference_time:")==0 ){
			//cout<<"line is: "<<line<<std::endl;
			std::istringstream ss(line);
			while (!ss.eof()) {
				/* extracting word by word from stream */
				ss >> temp;
				/* Checking the given word is float or not */
				if (stringstream(temp) >> StageTwoInferenceTime){
					//printf("StageTwoInferenceTime is: %f ms\n", StageTwoInferenceTime);
					break;
				}
				temp = "";
			}
		}
		/* Extract Stage Three Inference Time */
		if ( line.find("stage3_inference_time:")==0 ){
			//cout<<"line is: "<<line<<std::endl;
			std::istringstream ss(line);
			while (!ss.eof()) {
				/* extracting word by word from stream */
				ss >> temp;
				/* Checking the given word is float or not */
				if (stringstream(temp) >> StageThreeInferenceTime){
					//printf("StageThreeInferenceTime is: %f ms\n", StageThreeInferenceTime);
					break;
				}
				temp = "";
			}
		}
	}
}



void UpdateResults(int PartitionPoint1, int PartitionPoint2, string Order) {
    char Run_Command[150];
    sprintf(Run_Command,"./%s --threads=4 --threads2=2 --target=NEON --n=%d --partition_point=%d "
                     "--partition_point2=%d --order=%s > output.txt", Graph.c_str(), N_Frames, PartitionPoint1,
                     PartitionPoint2, Order.c_str());
    system(Run_Command);
    ParseResults();
}


/* Update 2 partition points to equate the 3 inference times after each call
 * (frequencies & cores' order are kept constant)
 * */

void balanceLoad(int &PartitionPoint1, int &PartitionPoint2, string Order, int timeDifferenceLimit=3) {
    static int point_min = 0;
    static int point_max = TotalParts;

    if ((point_min == PartitionPoint1) || (point_max == PartitionPoint2 - 1) ||
            (abs(StageOneInferenceTime - StageTwoInferenceTime) < timeDifferenceLimit &&
            abs(StageOneInferenceTime - StageThreeInferenceTime) < timeDifferenceLimit &&
            abs(StageThreeInferenceTime - StageTwoInferenceTime) < timeDifferenceLimit) || // achieved both
            // 'optimal' points
            (PartitionPoint1 == TotalParts))  // 1 processor
        return;

    if (PartitionPoint2 == TotalParts) {  // 2 processors
        if (StageOneInferenceTime < StageTwoInferenceTime && point_min != PartitionPoint1) {
            point_min = PartitionPoint1;
            PartitionPoint1 = floor((PartitionPoint1 + point_max)/2);
//            if (StageTwoInferenceTime - StageOneInferenceTime > timeDifferenceLimit)
//                PartitionPoint1 +=2;
//            else
//                PartitionPoint1++;
            return;
        }
        else if (StageOneInferenceTime > StageTwoInferenceTime && point_max > PartitionPoint1 + 1) {
            point_max = PartitionPoint1;
            PartitionPoint1 = floor((PartitionPoint1 + point_min)/2);
//            if (StageOneInferenceTime - StageTwoInferenceTime > timeDifferenceLimit)
//                PartitionPoint1 -= 2;
//            else
//                PartitionPoint1--;
            return;
        }
        else {
            return;
        }
    }

    /* 3 processors */

    float time_min = min({StageOneInferenceTime, StageTwoInferenceTime, StageThreeInferenceTime});

    if (time_min == StageOneInferenceTime) {  /* StageOneInferenceTime is smallest     -> increase p1 */
        if (PartitionPoint1 != PartitionPoint2 - 1) {
            point_min = PartitionPoint1;
            PartitionPoint1 = floor((PartitionPoint1 + PartitionPoint2) / 2);
//            if (StageTwoInferenceTime - StageOneInferenceTime > timeDifferenceLimit)
//                PartitionPoint1 += 2;
//            else
//                PartitionPoint1++;
            return;
        } else {
            return;
        }
    }

    else if (time_min == StageTwoInferenceTime) {  /* StageTwoInferenceTime is smallest */
//        float timeDifference1 = StageOneInferenceTime - StageTwoInferenceTime;
//        float timeDifference2 = StageThreeInferenceTime - StageTwoInferenceTime;
        PartitionPoint1 = floor((PartitionPoint1 + point_min) / 2);
        PartitionPoint2 = floor((PartitionPoint2 + point_max) / 2);
//        if (timeDifference1 > timeDifferenceLimit)
//            PartitionPoint1 -= 2;
//        else
//            PartitionPoint1--;
//        if (timeDifference2 > timeDifferenceLimit)
//            PartitionPoint2 += 2;
//        else
//            PartitionPoint2++;
        return;
    }
    else if (time_min == StageThreeInferenceTime) {  /* StageThreeInferenceTime is smallest    -> decrease p2 */
        if (PartitionPoint1 != PartitionPoint2 + 1) {
            point_max = PartitionPoint2;
            PartitionPoint2 = floor((PartitionPoint1 + PartitionPoint2) / 2);
//            if (StageTwoInferenceTime - StageThreeInferenceTime > timeDifferenceLimit)
//                PartitionPoint2 +=2;
//            else
//                PartitionPoint2--;
            return;
        } else {
            return;
        }
    }

return;
}


int main (int argc, char *argv[])
{
	if ( argc < 5 ){
		std::cout<<"Wrong number of input arguments.\n";
		return -1;
	}
	time_t start = time(NULL);
	Graph=argv[1];
	TotalParts=atoi(argv[2]);
	Target_FPS=atoi(argv[3]);
	Target_Latency=atoi(argv[4]);
	string Command="";
    string Order;

	/* Checking if processor is available */
	if (system(NULL)) puts ("Ok");
	else exit (EXIT_FAILURE);


	/* Export OpenCL library path */
	system("export LD_LIBRARY_PATH=/data/local/Working_dir");
	setenv("LD_LIBRARY_PATH","/data/local/Working_dir",1);

	/* Setup Performance Governor (CPU) */
	system("echo performance > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor");
	system("echo performance > /sys/devices/system/cpu/cpufreq/policy2/scaling_governor");


	/* Start with running half network on Little CPU and half network on Big CPU with GPU empty in the middle */
	int PartitionPoint1=(TotalParts/2);
	int PartitionPoint2=TotalParts - floor(TotalParts/3);
						// # 11      # 5          #17          #2         #8            #14				#2
	modes bintree[23] = {{high,low,0},{low,mid,0},{mid,none,1},{low,none,0}, {mid,none,0}, {mid,mid,0}, {high,low,1},
	 				{none,mid,0},{low,low,0},{none,mid,1},{low,none,1},{low,low,1},{low,mid,1},{mid,low,1},{high,mid,1},
				    {none,low,0},{none,none,1},{none,low,1},{high,none,0},{high,low,0},{high,mid,0},{high,none,1},{mid,mid,1}};
	int index = 0;
	int best = 22;
	while(true){
		char Run_Command[150];
		Order = modes_to_freq(bintree[index],PartitionPoint1,PartitionPoint2);
		UpdateResults(PartitionPoint1, PartitionPoint2, Order);
        balanceLoad(PartitionPoint1, PartitionPoint2, Order);
        if ( FPS * 1.1 >= Target_FPS && Latency * 0.9 <= Target_Latency  ){//Both Latency and Throughput Requirements are Met.
			printf("Solution Was Found.\n TargetBigFrequency:%d \t TargetLittleFrequency:%d \t PartitionPoint1:%d \t PartitionPoint2:%d \t Order:%s\n",
			BigFrequencyTable[BigFrequencyCounter], LittleFrequencyTable[LittleFrequencyCounter], PartitionPoint1,
            PartitionPoint2, Order.c_str());
			best = index;
			if (index > 12)
			{
				break;
			}
			 else if (index > 6)

			{
				index += 8;
			}
			else
			{
				index = index * 2 + 1;
			}
		}
		else
		{
			printf("Target Perfromance Not Satisfied\n\n");
			if (index > 6)
			{
				break;
			}
			else
			{
				index = index * 2 + 2;
			}

		}


	}
	Order = modes_to_freq(bintree[best],PartitionPoint1,PartitionPoint2);
	printf("Big: %d en Little : %d , order = %s\n", BigFrequencyTable[BigFrequencyCounter],LittleFrequencyTable[LittleFrequencyCounter],Order.c_str());
	int bestBig = BigFrequencyCounter;
	int bestLittle = LittleFrequencyCounter;
	int BestPart1 = PartitionPoint1;
	int BestPart2 = PartitionPoint2;
	while (start + 540 >= time(NULL))
	{
		char Run_Command[150];
		UpdateResults(PartitionPoint1, PartitionPoint2, Order);

		if ( FPS >= Target_FPS && Latency <= Target_Latency  )
		{

			printf("Solution Was Found.\n TargetBigFrequency:%d \t TargetLittleFrequency:%d \t PartitionPoint1:%d \t PartitionPoint2:%d \t Order:%s\n",
			BigFrequencyTable[BigFrequencyCounter], LittleFrequencyTable[LittleFrequencyCounter], PartitionPoint1,
			PartitionPoint2, Order.c_str());
			float MinSpeed = min({StageOneInferenceTime, StageTwoInferenceTime, StageThreeInferenceTime});
			for(int i = 0; i < 7; i += 2)
			{
				if (Order[i] != 'G' && MinSpeed == StageOneInferenceTime)
				{
					if (Order[i] == 'B')
					{
						BigFrequencyCounter -= 1;
					}
					else
					{
						LittleFrequencyCounter -=1;
					}
				}
			}

		}
		else
		{
			balanceLoad(PartitionPoint1,PartitionPoint2,Order);
		}
	}

	printf("end Solution Was Found.\n TargetBigFrequency:%d \t TargetLittleFrequency:%d \t PartitionPoint1:%d \t PartitionPoint2:%d \t Order:%s\n",
	BigFrequencyTable[bestBig],LittleFrequencyTable[bestLittle], PartitionPoint1, PartitionPoint2, Order.c_str());

  return 0;
}
