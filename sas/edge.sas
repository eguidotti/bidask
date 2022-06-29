%let in = %sysget(in);
%let out = %sysget(out);

%let by_csv = %sysget(by);
%let by_lst = %sysfunc(tranwrd(%quote(&by_csv), %str(,), %str( )));
%let by_grp = %scan(%quote(&by_csv), -1, %str(,));

%let open = %sysget(open);
%let high = %sysget(high);
%let low = %sysget(low);
%let close = %sysget(close);


data prices;

    set "&in";
    by &by_lst;

    o = log(&open);
    h = log(&high);
    l = log(&low);
    c = log(&close);
    m = (h + l) / 2;

    h1 = lag(h);
    l1 = lag(l);    
    c1 = lag(c);
    m1 = lag(m);

    x1 = (m-o)*(o-m1) + (m-c1)*(c1-m1);
    x2 = (m-o)*(o-c1) + (o-c1)*(c1-m1);

    n1 = o=h;
    n2 = o=l;
    n3 = c1=h1;
    n4 = c1=l1;
    n5 = h=l & l=c1;

    if first.&by_grp = 0;

run;


proc sql;

    CREATE TABLE agg AS
    
    SELECT 
        &by_csv,
        AVG(x1) AS e1,
        AVG(x2) AS e2,
        AVG(x1 * x1) AS e11,
        AVG(x2 * x2) AS e22,
        AVG(n1) AS n1,
        AVG(n2) AS n2,
        AVG(n3) AS n3,
        AVG(n4) AS n4,
        AVG(n5) AS n5
    
    FROM
        prices
    
    WHERE
        x1 IS NOT NULL AND
        x2 IS NOT NULL
    
    GROUP BY
        &by_csv;   

quit;


data edge;

    set agg;

    v1 = e11 - e1*e1;
    v2 = e22 - e2*e2;
    if v1 and v2;
    
    w1 = v2 / (v1 + v2);
    w2 = v1 / (v1 + v2);
    k = 4 * w1 * w2;
    
    s2 = -4 * (w1 * e1 + w2 * e2) / ((1 - k * (n1 + n2) / 2) + (1 - n5) * (1 - k * (n3 + n4) / 2));
    EDGE = SQRT(MAX(0, s2));
    
    keep &by_lst EDGE;

run;


proc export data=edge 
    outfile="&out" 
    replace; 
run;
