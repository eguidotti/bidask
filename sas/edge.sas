%let in = %sysget(in);
%let out = %sysget(out);

%let by_csv = %sysget(by);
%let by_lst = %sysfunc(tranwrd(%quote(&by_csv), %str(,), %str( )));
%let by_grp = %scan(%quote(&by_csv), -1, %str(,));

%let open = %sysget(open);
%let high = %sysget(high);
%let low = %sysget(low);
%let close = %sysget(close);
%let sign = %sysget(sign);


data prices;

    set "&in";
    by &by_lst;

    o = log(OPEN);
    h = log(HIGH);
    l = log(LOW);
    c = log(CLOSE);
    m = (h + l) / 2;

    h1 = lag1(h);
    l1 = lag1(l);    
    m1 = lag1(m);
    c1 = lag1(c);
    c2 = lag2(c);

    r1 = m-o;
    r2 = o-m1;
    r3 = m-c1;
    r4 = c1-m1;
    r5 = o-c1;

    tau = h ne l | l ne c1;
    phi1 = o ne h & tau;
    phi2 = o ne l & tau;
    phi3 = c1 ne h1 & tau;
    phi4 = c1 ne l1 & tau;
    
    if first.&by_grp = 0;

run;


proc sql;

    CREATE TABLE avg AS
    
    SELECT 
        &by_csv,
        AVG(r1*r2)        AS m1,
        AVG(r3*r4)        AS m2,
        AVG(r1*r5)        AS m3,
        AVG(r5*r4)        AS m4,
        AVG(tau)          AS m5,
        AVG(r1)           AS m6,
        AVG(tau*r2)       AS m7,
        AVG(r3)           AS m8,
        AVG(tau*r4)       AS m9,
        AVG(r5)           AS m10,
        AVG(r1**2*r2**2)  AS m11,
        AVG(r3**2*r4**2)  AS m12,
        AVG(r1**2*r5**2)  AS m13,
        AVG(r4**2*r5**2)  AS m14,
        AVG(r1*r2*r3*r4)  AS m15,
        AVG(r1*r4*r5**2)  AS m16,
        AVG(tau*r2**2)    AS m17,
        AVG(tau*r4**2)    AS m18,
        AVG(tau*r5**2)    AS m19,
        AVG(tau*r1*r2**2) AS m20,
        AVG(tau*r3*r4**2) AS m21,
        AVG(tau*r1*r5**2) AS m22,
        AVG(tau*r5*r4**2) AS m23,
        AVG(tau*r1*r2*r4) AS m24,
        AVG(tau*r2*r3*r4) AS m25,
        AVG(tau*r2*r4)    AS m26,
        AVG(tau*r1*r4*r5) AS m27,
        AVG(tau*r4*r5**2) AS m28,
        AVG(tau*r4*r5)    AS m29,
        AVG(tau*r5)       AS m30,
        AVG(phi1)         AS m31,
        AVG(phi2)         AS m32,
        AVG(phi3)         AS m33,
        AVG(phi4)         AS m34
    
    FROM
        prices
        
    GROUP BY
        &by_csv;   

quit;


data edge;

    set avg;

    po = -8 / (m31 + m32);
    pc = -8 / (m33 + m34);
    
    e1 = po/2 * (m1 - m6*m7/m5) + 
        pc/2 * (m2 - m8*m9/m5);
    
    e2 = po/2 * (m3 - m6*m30/m5) + 
        pc/2 * (m4 - m10*m9/m5);
    
    v1 = po**2/4 * (m11 + m6**2*m17/m5**2 - 2*m20*m6/m5) +
        pc**2/4 * (m12 + m8**2*m18/m5**2 - 2*m21*m8/m5) +
        po*pc/2 * (m15 - m24*m8/m5 - m6*m25/m5 + m6*m8*m26/m5**2) - 
        e1**2;
    
    v2 = po**2/4 * (m13 + m6**2*m19/m5**2 - 2*m22*m6/m5) +
        pc**2/4 * (m14 + m10**2*m18/m5**2 - 2*m23*m10/m5) +
        po*pc/2 * (m16 - m27*m10/m5 - m6*m28/m5 + m6*m10*m29/m5**2) -
        e2**2;
    
    s2 = (v2*e1 + v1*e2) / (v1 + v2);

    s = SQRT(ABS(s2));
    if &sign & (s2 < 0) then 
        do;
            s = -s;
        end;

    keep &by_lst s;
    rename s=EDGE;

run;


proc export data=edge 
    outfile="&out" 
    replace; 
run;
