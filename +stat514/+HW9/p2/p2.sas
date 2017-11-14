ods html close;
ods html;

data scope;
    infile 'D:\Grad\+stat514\+HW9\p2\measure.dat';
	input operator parts measurement;
proc print;

proc mixed method=type1;
	class operator parts;
	model measurement=operator;
	random parts(operator);
run;
