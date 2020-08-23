/*
	STA 402 Final Project
	Author: Tyler Sagendorf
	Purpose: Create a macro that generates a hurricane 
	season summary map for a given year, and colors the points
	by the type of storm.
	
	The map should look something like the following:
	https://en.wikipedia.org/wiki/2017_Atlantic_hurricane_season#/media/File:2017_Atlantic_hurricane_season_summary_map.png

*/


/* 
	To read in the data, I used these resources:
	
	FILENAME Statement, URL Access Method:
		http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000223242.htm
	Missover: 
		http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000146932.htm
	Data Format File:
		https://www.aoml.noaa.gov/hrd/hurdat/newhurdat-format.pdf
*/


/* Get the file from the internet */
filename weather url "https://www.aoml.noaa.gov/hrd/hurdat/hurdat2.html";

/* Creating a dataset with just the values, not the header */
data weather1;
	infile weather dsd dlm="," missover firstobs=4;
	input @1 a $8. @11 b $4. @17 record $1. @20 status $2. @24 lat 4. 
		  @28 c $1. @31 long 5. @36 d $1. @39 wind 3. @44 pressure 4.
		  @50 ne34 4. @56 se34 4. @62 sw34 4. @68 nw34 4. @74 ne50 4. 
		  @80 se50 4. @86 sw50 4. @92 nw50 4. @98 ne64 4. @104 se64 4. 
		  @110 sw64 4. @116 nw64 4.;
	/* Get observations */
	if substr(a,1,1)="A" then delete;
	year1 = substr(a,1,4);
	/* For the Atlantic Basin, latitude is positive and longitude is negative */
	long=-long;
	/* Make year numeric */
   	year = input(year1, 8.);
	keep year status lat long;
run;

/* Creating a dataset with just the header information */
data weather2 (drop=i);
	infile weather dsd dlm="," missover;
	input @1 x $8. @19 name $10. @34 rows 3.;
	/* Get header rows */
	if substr(x,1,1) NE "A" then delete;
	do i = 1 to rows; /* Repeat header 'row' times */
		output;
	end;
	drop x rows;
run;

/* Combine datasets */
data weather3;
	merge weather1 weather2;
	if name = "" then delete; /* Get rid of blank rows */
run;


/* MACRO */
%macro hurricaneMap(year=2017); /* Set 2017 as the default year */

/* Weather data for desired year */
data anno1;
	set weather3;
	where year=&year.;
	/* Convert to radians */
	x=long*constant('pi')/180;
   	y=lat*constant('pi')/180;
	keep name x y status segment;
run;

/* Map data */
data my_map;
	set mapsgfk.world;
	name = id; /* Needed for the set statement in my_map2 */
	/* Restrict map area */
	where (-10<=lat<=70) and (-125<=long<=15);
	/* Convert to radians */
	x=long*constant('pi')/180;
   	y=lat*constant('pi')/180;
	keep name x y segment;
run;

/* 
	I used a combination of the following resources for 
	the rest of this project:
	
	PROC GMAP: 
		http://support.sas.com/documentation/cdl/en/graphref/63022/HTML/default/viewer.htm#a000729027.htm
	Make the Map You Want with PROC GMAP and the Annotate Facility: 
		https://www.lexjansen.com/nesug/nesug08/np/np05.pdf
	Annotating on Maps:
		http://robslink.com/SAS/book2/Chapter_07_Annotating_on_Maps.pdf
	
*/

/* Creating a data set for the storm points */
data anno2;
	set anno1;
	length function style color text $ 8 ; 
	/* Make a solid pie graph of size 0.15 and rotate it 360 degrees to get a solid circle */
	retain xsys ysys '2' function 'pie' style 'psolid' size .15 rotate 360 when 'A' text 'L';
	/* Color points by type of storm */
		if status = "TD" then color="#E8E70D";
		if status = "TS" then color="orange";
		if status = "HU" then color="red";
		if status = "EX" then color="purple";
		if status = "SD" then color="steel";
		if status = "SS" then color="blue";
		if status = "LO" then color="cyan";
		if status = "WV" then color="lime";
		if status = "DB" then color="green";
	output;
run;

/* Legend part of the annotate data set */
data legend;
	length function style color text$ 8;
	retain xsys '5' ysys '5' when 'A';
	
	/* Brute-force legend construction */

	function='move'; x=15; y=2; output; /* Annotation location */
	function='pie'; style='psolid'; /* Annotation type */
	size=0.3;position='5';color='#E8E70D';text='L'; rotate=360; output; /* Size and color */
	function='move'; x=18; y=3; output; /* Text location */
	function='label'; style='swissb'; size=1.5; position='5'; color='black'; /* Text formatting */
	text='TD'; output; /* Text */

	function='move'; x=23;y=2;output;
	function='pie';style='psolid';
	size=0.3;position='5';color='orange';text='L'; rotate=360; output;
	function='move'; x=26;y=3;output;
	function='label';style='swissb';size=1.5;position='5';color='black';
	text='TS';output;

	function='move'; x=31;y=2; output;
	function='pie';style='psolid';
	size=0.3;position='5';color='red';text='L'; rotate=360; output;
	function='move'; x=34;y=3; output;
	function='label';style='swissb';size=1.5;position='5';color='black';
	text='HU';output;

	function='move'; x=39;y=2; output;
	function='pie';style='psolid';
	size=0.3;position='5';color='purple';text='L'; rotate=360; output;
	function='move'; x=42;y=3; output;
	function='label';style='swissb';size=1.5;position='5';color='black';
	text='EX';output;

	function='move'; x=47;y=2; output;
	function='pie';style='psolid';
	size=0.3; position='5'; color='steel'; text='L'; rotate=360; output;
	function='move'; x=50;y=3; output;
	function='label';style='swissb';size=1.5;position='5';color='black';
	text='SD';output;

	function='move'; x=55;y=2; output;
	function='pie';style='psolid';
	size=0.3;position='5';color='blue';text='L'; rotate=360; output;
	function='move'; x=58;y=3; output;
	function='label';style='swissb';size=1.5;position='5';color='black';
	text='SS';output;

	function='move'; x=63;y=2; output;
	function='pie';style='psolid';
	size=0.3; position='5';color='cyan';text='L'; rotate=360; output;
	function='move'; x=66;y=3; output;
	function='label';style='swissb';size=1.5;position='5';color='black';
	text='LO';output;

	function='move'; x=71;y=2; output;
	function='pie';style='psolid';
	size=0.3;position='5';color='lime';text='L'; rotate=360; output;
	function='move'; x=74;y=3; output;
	function='label';style='swissb';size=1.5;position='5';color='black';
	text='WV';output;

	function='move'; x=79;y=2; output;
	function='pie'; style='psolid';
	size=0.3; position='5'; color='green'; text='L'; rotate=360; output;
	function='move'; x=82; y=3; output;
	function='label';style='swissb';size=1.5;position='5';color='black';
	text='DB';output;
run;

/* Combine legend and annotate data set to get final annotate data set */
data anno3;
	set anno2 legend;
run;

/* Color the map grey */
pattern1 color="#ccced1" value=solid;

/* Make the map and annotate with points and legend */
proc gmap data=my_map map=my_map;
  id name;
  title3 h=3 "&year. Storm Tracking Map";
  choro segment / levels=1 anno=anno3 nolegend coutline=white;
run;
quit;

%mend;

%hurricaneMap() /* 2017 Map */
%hurricaneMap(year=1998)
%hurricaneMap(year=1900)
