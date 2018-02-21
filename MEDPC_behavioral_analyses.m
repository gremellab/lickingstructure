%% MEDPC data for timing of events
% INTRODUCTORY TEXT
%The goal of this program is to take raw MEDPC data and produce usable
%information on the timing of each event type (licks, lever presses, head
%entries, reinforcements) and the intervals between events. This includes a
%number of analyses of the microstructure of licking behavior (see
%below). There is optional code that is commented out for more variables or
%figures. This was last updated 1/9/18 by Emily Baltz. (Gremel Lab, UCSD
%Dept of Psychology. Support: Please contact cgremel at ucsd.edu)

% FEATURES: 
% ?	Graph of cumulative licks/time
% ?	Graph of cumulative lever presses/time
% ?	Array of inter-lick intervals for each data set 
% ?	Array of coefficient of variance of each inter-event interval
% ?	Graph of all events over time
% ?	Binned response rates of each subject?s data 
% ?	Potential for other graphs (head entries, other lever presses) and other arrays when needed (currently commented out)

%%
%VARIABLES OF INTEREST: 
%c= event type, time matrix ordered by time
%numxls= original input from a sheet
%lp= lever presses, time
%li= licks, time
%rein= reinforcements, time
%he= head entries, time
%rlp= right lever presses, time
%ILI=interlick interval
%cvli= coefficient of variance for interlick interval (std/mean*100) 
%rate= each subjects' lever presses/minute during 5 minute bins of a 15
%minute test. you can change the time of bins and length of session 
%interburstinterval: Looking at the intervals between bursts of licking. A burst
%is defined as licks where there's less than 1 second between licks. 

%MEDPC NUMBERS: (MAKE SURE THESE MATCH UP WITH YOUR PROGRAM)
%.10=primary leverpress (lever 1)(LLP for incentive learning) 
%.11=lick
%.12=head entry.
%.13=secondary leverpress (lever 2) (RLP for incentive learning)
%.20=reinforcement

%% SECTION 1: GET THE DATA FROM A SINGLE NUMBER (in the form xxx.xxxx) INTO A FORM WHERE ONE COLUMN REPRESENTS ELAPSED TIME(as opposed to time from last event) AND THE OTHER  REPRESENTS THE EVENT TYPE

clear;
tic

%the following set up empty arrays to add to as you run through
%the sheets in your excel file
LPtotal=[];
RLPtotal=[];
CARRAY = {};            %array of all event timestamps
IHEIARRAY = {};         %inter-head entry intervals of each subject  
LPARRAY = {};           %lever press timestamps of each subject
CVLPARRAY= [];          %coefficient of variance of LPs of each subject
REINARRAY= {};          %rein timestamps of each subject
HEARRAY= {};            %head entry timestamps of each subject
LLPrate= [];            %rate of left lever pressing
%% 
Lickbins = [];          %rate of licking per 10ms
herate=[];
RLPARRAY={};            %right lever presses of each subject

%lick related variables/arrays and their descriptions
numlickARRAY= [];           %number of licks of each subject
numberofburstsARRAY =[];
ILIARRAY = {};              %interlick intervals of each subject
meanILI=[];                 %average interlick interval of each subject
CVILIARRAY = [];            %coefficient of variance of interlick interval
liARRAY= {};                %array of all licking timestamps
lickingrate= [];            %binned licking rates 
LickLatencyARRAY= {};       %latency of first lick after reinforcer
avgLickLatencyARRAY = [];   %avg latency of first lick after rein

nonburstlicks = [];         %number of licks that don't occur in a burst
burstlicks = [];            %number of licks that occur in burst
bursts = [];                %number of bursts
 % numberofburstsARRAY =[]; %figure what's going on with this (see below)
avgburstlickARRAY= [];          %average number of licks per burst
interburstintervalARRAY = {};   %inter burst interval
avginterburstinterval =[];      %average interburst interval
ILIduringburstARRAY = {};       %interlick interval during bursts
avgILIduringburstARRAY = [];    %average interlick interval during bursts
ILIoutsideburstARRAY = {};      %interlick interval outside of bursts
avgILIoutsideburstARRAY =[];    %average interlick interval outside of bursts
avgburstdurationARRAY = [];     %average duration of bursts   
burstingrate= [];           %binned bursting rates
quicklicksARRAY = {};       %array of timestamps of licks that happened in bursts
slowlicksARRAY = {};        %array of timestamps of licks that happened out of bursts
quicklicksrate = [];        %binned rate of licks within bursts
burstratio = [];            %number of licks within bursts/ total licks
firstburstlil= [];          %timestamps of licks that happened during first burst of licking after reinforcer delivery
firstburstduration= [];     %duration of the first burst after rein delivery
firstburstdurations= {};    %firstburstduration for all animals
avgfirstburstduration={};   %mean duration of the first burst after rein delivery for each animal
numlicksfirstburst = [];    %number of licks in the first bursts
numlickfirstbursts= {};     %numlicksfirstburst for all animals
avgnumlicksfirstburst = []; %average for each animal of numlicksfirstbursts
prereinlickARRAY ={};       %array of licks that occur before the 1st reinforcer for each mouse
% Set up your bins:
%change this 
%based on how small or large of bins you want. This is currently set for a 60 minute test
numbersvector= [0,10,20,30,40,50,60]; %one minute bins;
edges = numbersvector *600 ;  %divides into 1 minute bins for a 60 minute test
edges3= [0:36000]; %divides in a second for a 60 minute test

% Set up your excel file and parameters
% [status,sheets] = xlsfinfo(inputfile); %[sheets] = names of your sheets in excel
% numOfSheets = numel(sheets);  %finds the number of sheets in your Excel file
colorsheets = [ 'm','m','m','m', 'm','m', 'm', 'm','m','m', 'm', 'm','m',  'g', 'g', 'g', 'g', 'g', 'g', 'g','g','g', 'g', 'g','g', 'g','r','r','r','r','r', 'r', 'r', 'r','r', 'r', 'r','r','r','r','r', 'r', 'r', 'r','r','k', 'k', 'k', 'k', 'k', 'k', 'k','k', 'k', 'k', 'k', 'k', 'k', 'k', 'k', 'k', 'k', 'k','k', 'k', 'k', 'k' ];
%colorsheets lets you set up the colors you want to use for graphing each subject
set(groot, 'defaultAxesFontSize', 24)
set(groot, 'defaultTextFontSize', 20)

%% SECTION 2: Get your MEDPC data into Matlab from the folder
    %go to the folder that has all of the data files you want to impor
MEDPCFiles = dir('EBEXP*'); %this takes all the data files that start with "EBEXP"- 
% *****change this ^^^ depending on what your files start with*****

numfiles = length(MEDPCFiles); %gets the number of files you have
subjectlist = cell(1, numfiles); %set up a cell array of your subjects

for k = 1:numfiles 
  subjectlist{k} = importfile_MEDPC((MEDPCFiles(k).name), 37, 500000); %uses importfile_MEDPC to import the text file starting where the array starts
end

%% SECTION 3:GET THE DATA FROM A SINGLE NUMBER (in the form xxx.xxxx) INTO A FORM WHERE ONE COLUMN REPRESENTS ELAPSED TIME(as opposed to time from last event) AND THE OTHER  REPRESENTS THE EVENT TYPE
for i = 1:numfiles %run following code through each subject
    currentsubjectdata= subjectlist{i}; %get the current subject data to manipulate
    format long %make sure matlab doesn't truncate your numbers or use scientific notation
    %numxls(:,1)= []; %get rid of the first column (event counter) to leave only data points on your excel file
    time = floor(currentsubjectdata); %get the integer part of the number (ie: timestamp from previous event)
    event = (currentsubjectdata-time); %get the decimal part of the number (ie: the type of event)
    time = time'; %get the order that you need for time
    time = reshape(time,[],1); %reshape time to be in a vector so you can sum it easily
    time = cumsum(time); %get the cumulative sum of the integers in order to get accurate timestamps
    event = event'; %get the order that you need for event (decimal coding for the event type)
    event = reshape(event,[],1); %get a vector of events
    event= (event*100); %multiply by 100 to avoid sci notation issues
    c=cat(2,event,time); %concatenate time and events


%% SECTION 2:SEPARATE THE DIFFERENT EVENT TYPES INTO DISTINCT MATRICES 
%GRAPH THEM IF YOU WANT (uncomment the graphs)  

    %generate matrix for lever presses (10)
    lp= c(c(:,1)>9.5 & c(:,1)<10.5, : );
    lp= fliplr (lp); %flips the columns so time is on the left
    lp(:,2)=[]; %removes number coding event
    LPtotal= [LPtotal numel(lp)]; %array of all the lever presses of the subjects
    LPARRAY= [LPARRAY lp];

%     figure(2) %graphs cumulative left lever presses/time
%     hold on
%     title('')
%     xlabel('time in deciseconds');
%     ylabel('cumulative left lever presses');
%     plot(lp, find(lp), colorsheets(i), 'LineWidth', 1);
%    legend([sheets], 'Location', 'Best'); %makes the legend sheet names & puts it in best location
    
    %generate matrix for licks (11)
    li= c(c(:,1)<11.5 & c(:,1)>10.5, : );
    li= fliplr (li); %flips the columns so time is on the left
    li(:,2)=[]; %removes number coding event (removes "11"s)
    liARRAY= [liARRAY li];
    
    %collect the total number of licks:
    numlicks= numel(li); %gets the number of licks
    numlickARRAY= [numlickARRAY numlicks]; %adds number of licks to the array
    
    %get the timestamps of licks that are in bursts ("quicklicks") and licks that are out
    %of bursts ("slowlicks")
    quicklicks= []; %timestamps of licks that are within bursts
    slowlicks= [];  %timestamps of licks that are out of bursts
    
    for j = 1:numlicks-1
        difference = li(j+1)- li(j);
        if difference <= 10
            quicklicks=[quicklicks; li(j)];
        else
            slowlicks = [slowlicks; li(j)];
        end
      
    end
    difference = li(numlicks) - li(numlicks-1); %this is code for the last data point because it can't be run in the previous section
        if difference <= 10
            quicklicks=[quicklicks; li(numlicks)];
        else
            slowlicks = [slowlicks; li(numlicks)];
        end

    quicklicksARRAY= [quicklicksARRAY quicklicks];
    slowlicksARRAY= [slowlicksARRAY slowlicks];
    burstratio= [burstratio (numel(quicklicks)/numel(li))];
    
    %generate matrix for head entries (12)
    he= c(c(:,1)<12.5 & c(:,1)>11.5, : );
    he= fliplr (he); %flips the columns so time is on the left
    he(:,2)=[]; %removes number coding event (removes "12"s)
    HEARRAY = [HEARRAY he];
    
%     figure(3) %graph headentries/time
%     hold on
%     title('')
%     xlabel('time in deciseconds');
%     ylabel('cumulative head entries');
%     plot(he, find(he), colorsheets(i), 'LineWidth', 1);
%     legend([sheets], 'Location', 'Best');
    
    %generate matrix for secondary lever presses (13)
    rlp= c(c(:,1)<13.5 & c(:,1)>12.5, : );
    rlp= fliplr (rlp); %flips the columns so time is on the left
    rlp(:,2)=[]; %removes number coding event (removes "13"s)
    RLPtotal= [RLPtotal numel(rlp)];
    
    %generate matrix for reinforcements earned (20) 
    rein= c(c(:,1)>19.5 & c(:,1)<20.5, : );
    rein= fliplr (rein); %flips the columns so time is on the left
    rein(:,2)=[]; %removes number coding event (removes "20"s)
    REINARRAY= [REINARRAY rein];
% 
%     figure(4)  %graph cumulative licks/time
%     hold on
%     title('')
%     xlabel('time in deciseconds'); %x axis label
%     ylabel('cumulative licks'); %y axis label 
%     lilength= (find(li)); %todo: need to figure out a way to include zeroes, otherwise get an error
%     plot(li, lilength, colorsheets(i), 'LineWidth', .5); %plot when the licks happen, and what number lick they are 

%  
%% SECTION 3: DETERMINE THE LATENCY OF THE FIRST LICK
%AFTER A REINFORCER IS DELIVERED. THIS SECTION ALSO COLLECTS THE NUMBER OF
%LICKS IN THE FIRST BURST AFTER THE REINFORCER IS DELIVERED AND THE
%TEMPORAL DURATION OF SAID BURST. 

    Clatency = zeros(size(rein));
    for q = 1:numel(rein) %for each number of reinforcer the animal got
        T = min(li(li>rein(q))); %T is equal to the minimum timestamp of a lick that's greater than the timestamp of the reinforcer
        if ~isempty(T)    %if there exists a T 
            r= find(li==T); %get the index of T
            Clatency(q) = T-rein(q);  %set the latency to the difference between T and the reinforcer timestamp
            firstburstlil= T; %set the first index of firstburstlil to the first lick time
            for s= r:numel(li)-1 %for the index of licks from T to the end
                if (li(s+1))-(li(s)) <= 10 %if the difference between the next lick and the current lick is less than or equal to 10
                    firstburstlil = [firstburstlil; li(s+1)]; %add the next lick to the array
                else (li(s+1))-(li(s)) >= 10; %if the difference is greater than or equal to 10
                    U= (li(s))-T; %take the difference between the ending lick of the first burst and the first lick of the first burst
                    break; %this stops the code from going further into the index after the end of the first burst
                end
            end
            numlicksfirstburst(q)= numel(firstburstlil); %get the number of licks in the first burst after the rein delivery
            firstburstduration(q)= U; %get the duration of the first burst after reinforcer
        else %if there isn't a lick after the reinforcer at all
            Clatency(q) = NaN; %set the latency variable to Not a number
        end

    %make some cell arrays so each animal's data is available
    end
    
    numlickfirstbursts= [numlickfirstbursts numlicksfirstburst]; %make array of the quantity of licks in the first burst following reinforcer delivery
    avgnumlicksfirstburst= [avgnumlicksfirstburst; mean(numlicksfirstburst)]; %make an array of the mean quantity of licks in the first burst following a reinforcer of a given animal
    firstburstdurations= [firstburstdurations firstburstduration]; %make an array of the durations of each burst following reinforcer delivery
    avgfirstburstduration= [avgfirstburstduration; mean(firstburstduration)]; %get the average duration of each first burst after a reinforcer for each animal
    Clatency(isnan(Clatency))= []; %remove non-numbers from Clatency
    LickLatencyARRAY = [LickLatencyARRAY Clatency]; %make an array of all the lick latencies
    avgLickLatencyARRAY = [avgLickLatencyARRAY mean(Clatency)]; %make an array of the mean lick latencies of each mouse


%% SECTION 5 :DETERMINE THE INTER-EVENT INTERVAL 
%(e.g. interlick interval)

    %interlick interval 
    ILI= diff(li);
    ILI= ILI';
    ILIARRAY = [ILIARRAY ILI];
    
    %burst interval (excludes interlick intervals under 1 second) 
    burst= ILI;
    burst(burst<10)=NaN;
    burst(isnan(burst))= [];
    interburstintervalARRAY = [interburstintervalARRAY burst];
    %average interburst interval
    avginterburstinterval= [avginterburstinterval mean(burst)];
    
    %number of bursts
    bursts=[bursts, numel(burst)];
    
    %average duration of a burst
    TTILI= sum(ILI); %total time of licking
    TTburst=sum(burst); %total time of <1 second intervals in licking
    avgbursttime=(TTILI-TTburst)/numel(burst); %average time of a burst based 
    %on the difference between the total intervals and long intervals divided by the total number of bursts
    avgburstdurationARRAY=[avgburstdurationARRAY avgbursttime]; %array of each subjects average length of bursts
    
    %interlick interval during bursting
    ILIduringburst=ILI;
    ILIduringburst(ILIduringburst>10)=NaN;
    ILIduringburst(isnan(ILIduringburst))= [];
    ILIduringburstARRAY= [ILIduringburstARRAY ILIduringburst];
    avgILIduringburst= mean(ILIduringburst);
    avgILIduringburstARRAY= [avgILIduringburstARRAY avgILIduringburst];
    
    %interlick interval outside of bursts
    ILIoutsideburst=ILI;
    ILIoutsideburst(ILIoutsideburst<10)= NaN;
    ILIoutsideburst(isnan(ILIoutsideburst))= [];
    ILIoutsideburstARRAY= [ILIoutsideburstARRAY ILIoutsideburst];
    avgILIoutsideburst= mean(ILIoutsideburst);
    avgILIoutsideburstARRAY= [avgILIoutsideburstARRAY avgILIoutsideburst];
    
    %number of licks that occur in bursts
    burstlicks= [burstlicks (numel(ILIduringburst)+1)]; 

    %average number of licks in each burst
    avgburstlick= burstlicks/bursts; %total number of licks in bursts divided by the number of bursts
    avgburstlickARRAY= [avgburstlickARRAY avgburstlick];
    
    %interlever-press interval
    ILPI= diff(lp); 
    
    %inter 2ndary lp interval
    IRLPI= diff(rlp); 
    
    %inter-head-entries interval
    IHEI= diff(he); 
    IHEI=IHEI';
    IHEIARRAY= [IHEIARRAY IHEI];
    
    %inter-reinforcement interval
    IREINI= diff(rein); 
%% SECTION 6: DETERMINE THE AVERAGE INTER-EVENT INTERVAL AND THE STANDARD DEVIATION 
    
    %interlick interval
        %average 
        mli= mean(ILI);
        meanILI= [meanILI mli];
        %standard deviation 
        stdli= std(ILI);
    %inter-lever press interval
        %average 
        mlp= mean(ILPI);
        %standard deviation 
        stdlp= std(ILPI);
    %inter- 2ndary lever press interval
        %average 
        mrlp= mean(IRLPI);
        %standard deviation 
        stdrlp= std(IRLPI);
    %interhead-entry interval
        %average 
        mhe= mean(IHEI); 
        %standard deviation 
        stdhe= std(IHEI); 
    %inter-reinforcement interval
        %average 
        mrein= mean(IREINI); 
        %standard deviation 
        stdrein= std(IREINI);
        
%% SECTION 7: FIND THE COEFFICIENT OF VARIANCE OF THE INTEREVENT INTERVALS
%- (HOW WIDESPREAD THE VARIANCE IS) 
    %coefficient of variance of interlick interval
        cvli= 100*(stdli/mli);
        CVILIARRAY = [CVILIARRAY, cvli];
    %coefficient of variance of inter-lever press interval
        cvlp= 100*(stdlp/mlp);
        %CVLPARRAY = [CVLPARRAY, cvlp];
    %coefficient of variance of secondary inter-lever press interval
        cvrlp= 100*(stdrlp/mrlp);
        %CVRLPARRAY = [CVRLPARRAY, cvrlp];
    %coefficient of variance of interhead-entry interval
        cvhe= 100*(stdhe/mhe);
        %CVHEARRAY = [CVHEARRAY, cvhe];
    %coefficient of variance of inter-reinforcement interval   
        cvrein= 100*(stdrein/mrein);
        %CVREINARRAY = [CVREINARRAY, cvrein]; 
        
%% Section 8: BIN THE RATES OF EVENTS

    %left lever pressing rate
        [N,edges] = histcounts(lp, edges, 'Normalization', 'countdensity');
        N = N*600; %converts the rate to lever presses/minute
        N = N'; %changes each vector to vertical so it's easily scalable
        LLPrate = [LLPrate N]; %get the rates of lever-pressing over time for the whole thing
        avgLLPrate = mean(LLPrate,2);%get an average rate across mice
        semllprate = std(LLPrate,0,2)/sqrt(length(LLPrate));
    %head entry rate
        [V, edges] = histcounts(he, edges, 'Normalization', 'countdensity');
        V= V*100;
        V= V';
        herate= [herate V];
    %licking rate 
       [Q,edges]= histcounts(li, edges, 'Normalization', 'countdensity');
       Q = Q*600;
       Q = Q';
       lickingrate = [lickingrate Q];
    %bursting rate   
       [M, edges]= histcounts(slowlicks, edges, 'Normalization', 'countdensity');
       M= M*600;
       M= M';
       burstingrate= [burstingrate M];
     %quicklicks rate   
       [L, edges]= histcounts(quicklicks, edges, 'Normalization', 'countdensity');
       L= L*600;
       L= L';
       quicklicksrate= [quicklicksrate L];
     %licks per second
       [R,edges3] = histcounts(li, edges3, 'Normalization', 'countdensity');
        R = R'; %changes each vector to vertical so it's easily scalable
        Lickbins = [Lickbins R];
        

      
end
toc