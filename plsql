Benefits
1. Performance benefits
      whenever u execute the block, for the complete block a  single request is send to db and for single req all stmt will be executed
   If u have 3 r 4 sql stmt then it will be executed with single request 

2. Modularization
  For diff set of task we can create diff blocks, but each block perform separate task 

3. Portable
   if we running plsql in one mc we can take and run on another mc

conn sys as sysdba
grant execute on utl_file to system;
grant create any directory to system;
conn system
sho user
create or replace directory user_dir as 'C:\Angular\'; 
grant read,write on directory user_dir to system;
conn system
select * from dba_directories;

Before we work with utl_file package we need to create a dir object. Directory object is an object in oracle database that points to OS directory, so instead of accessing OS directory in pl/sql programs directly, we create one directory object and that directory object points to OS directory, so if u want to refer OS directory in pl/sql program using directory object
    Directory object is created by DBA, consider we have C:\Angular folder, inside that we create a file 

SQL>create or replace directory user_dir as 'C:\Angular\'; 

So we created directory object called user_dir and this object points to c:\Angular folder. So in PL/SQL program if u want to refer C:/Angular instead of using C:/Angular we can use user_dir 

But directory object is created by DBA, but system user want to create the file, so grant permission object to system 

UTL_FILE Package
    Suppose we have table and we want to store table data into OS files on server side and also read data from OS files and store inside oracle database
    If we want to read data from file and write data to file, oracle provide predefined package called UTL_FILE package, it was introduced from oracle 7.3 version onwards
    This package is used to load data into OS files and also read data from OS files, But SQLLoader also used to retrieve data from flat file into Oracle db, but SQLLoader it works pn both client and server side but utl_file handles only server side files. Using SQLLoader loading data into flat file is impossible but through UTL_File package we can loading data into file and also read data from file 

1. Before writing or reading data from OS file, first we have to create alias directory. Actually PL/SQL program does not directly interact with OS files, if we want to interact with OS files then we must create logical directory, that logica; dir name whenever we specifying in PL/SQL program then automatically through that path OS reference that file only 

Syntax: Create or replace directory directoryname as 'path';

Suppose we want to store employee data into c: or d: where oracle resides where we specify 'path'

1. To create alias dir by scott user is not possible because scott user dosent have priviledge, so first we connect as admin user and give priviledge  to scott user using "create any directory" system priviledge 

Syntax: grant create any directory to 'username';

We try to store data in c:/ 

1. First we connect as admin user
sql>conn sys as sysdba
password: sys

sql>grant create any directory to scott;

2. Now connected as scott
sql>conn scott
password: tiger

Now we created alias directory called XYZ 
sql>create or replace directory XYZ as 'C:\';

3. When we perform read, write operation using utl_file package, so we must give read,write object priviledge to alias directory 

Syntax: grant read,write on directory 'dirname' to 'username';

sql>conn sys as sysdba
password: sys

sql> grant read,write on directory XYZ to scott;

sql>conn scott
password: tiger

4. Now we write data to OS file using putf(),put_line() procedure of utl_file package 

Step 1: Declare file pointer variable through which we are opening the file, loading data and closing the file using predefined record type called 'file_type' 

Syntax: varname utl_file.file_type;

Step 2: Before loading data into file first we should open the file using predefined fopen() function in executable section of pl/sql
   fopen() takes 3 parameter called alias directory,filename,mode(r,w,a)

Syntax: varname:=utl_file.fopen(alias directory,filename,mode);

Step 3: If we want to write data into file we use putf() or put_line() 

Syntax: utl_file.putf(varname,'content');

Step 4: After that we have to close the file using fclose(0 procedure
   
Syntax: utl_file.fclose(varname);

sql> declare
     fp utl_file.file_type;
     begin
       fp:=utl_file.fopen('XYZ','file1.txt','w');
       utl_file.putf(fp,'Hello world');
       utl_file.fclose(fp);
     end;
/

Now file1.txt is created in C:/ with the data 

5. Suppose we want to transfer employee table data into file 

>set line 100
>set pagesize 50;
>select * from emp;

Now we want to get multiple data from table to file, we are using cursor concepts 

sql> declare
     fp utl_file.file_type;
     cursor c1 is select ename from emp;
     begin
       fp:=utl_file.fopen('XYZ','file2.txt','w');
       for i in c1
       loop
       utl_file.putf(fp,i.ename);
       end loop;
       utl_file.fclose(fp);
     end;
/
Now file2.txt is created in C:/ with the data in horizontal format

But in this case since we use putf() it stores table data in horizontal format (ie) single line, so instead of putf we can use put_line so it will print one by one
    But samething can be achicve in putf() by using second parameter as format specifier  

 utl_file.putf(fp,'My employee name is: %s\n',i.ename);

6. Using put_line() procedure

Syntax: utl_file.put_line(filepointername,format);

sql> declare
     fp utl_file.file_type;
     cursor c1 is select * from emp;
     begin
       fp:=utl_file.fopen('XYZ','file3.txt','w');
       for i in c1
       loop
       utl_file.put_line(fp,i.ename||' '||i.sal);
       end loop;
       utl_file.fclose(fp);
     end;
/

Now file3.txt is created in C:/ with the data in vertical format 

7. Read data from OS file using get_line() procedure and store into the table or display in sql env

Syntax: utl_file.get_line(filepointername,buffervarname);

sql> declare
     fp utl_file.file_type;
     x varchar2(200);
     begin
       fp:=utl_file.fopen('XYZ','file1.txt','r');
       utl_file.get_line(fp,x);
       dbms_output.put_line(x);
       utl_file.fclose(fp);
     end;
/

Now data will read from file1.txt and printed in sql env

8. If we have multiple data items in file and if we want to read and display in sql env 

sql> declare
     fp utl_file.file_type;
     x varchar2(200);
     begin
       fp:=utl_file.fopen('XYZ','file2.txt','r');
       loop
       utl_file.get_line(fp,x);
       dbms_output.put_line(x);
       end loop;
       exception no_data_found then 
       utl_file.fclose(fp);
     end;
/

It will print all data one by one and whenever control reach end of file it will show error "no data found", so we can handle using exception part, so if no data found means we close the file pointer

9. Copy the file with fcopy
   - Copy all lines in the file or a specify range  of lines by start and end line numbers
   - You dont open/close the file

sql> declare
       fid utl_file.file_type;
     begin
       fid:=utl_file.fopen('ABC','a.txt','w',max_linesize=>32767);
       for indx in 1..100
       loop
          utl_file.put_line(fid,'Line ' || indx || 'contains GUID ' || SYS_GUID());
       end loop;
       utl_file.fclose(fid);
   end;
/

sql> begin
       -- copy entire file
       utl_file.fcopy(src_location=>'ABC',src_filename=>'a.txt',dest_location=>'ABC',dest_filename=>'a_copy.txt');
       --display_file('temp','a_copy.txt');

       --copy part of file
       utl_file.fcopy(src_location=>'ABC',src_filename=>'a.txt',dest_location=>'ABC',dest_filename=>'a_copy1.txt',start_line=>22,end_line=>43);
      --display_file('temp','a_copy1.txt');
end;
/


10. Delete a file with fremove
sql> declare
        fid utl_file.file_type;
     begin
        fid:=utl_file.fopen('ABC','test.txt','w');
        utl_file.put_line(fid,'hello');
        utl_file.put(fid,'world');
        utl_file.putf(fid,'welcome to plsql');
        utl_file.fclose(fid);
end;
/
-- It will create a file test.txt

sql>begin
       utl_file.fremove('ABC','test.txt');
    end;
/
-- It will remove the file

11. Rename and move a file with Frename

sql> declare
        fid utl_file.file_type;
     begin
        fid:=utl_file.fopen('ABC','test.txt','w');
        utl_file.put_line(fid,'hello');
        utl_file.put(fid,'world');
        utl_file.putf(fid,'welcome to plsql');
        utl_file.fclose(fid);
end;
/
-- It will create test.txt in C:/Training folder

--copy to file with different name
sql>begin
       utl_file.frename(src_location=>'ABC',src_filename=>'test.txt',dest_location=>'XYZ',dest_filename=>'test_copy.txt',overwrite=>true);
end;
/
--Now it will move to XYZ (ie)c:Angular as test_copy.txt

-- Move to a different directory
sql>begin
       utl_file.frename(src_location=>'ABC',src_filename=>'test.txt',dest_location=>'XYZ',dest_filename=>'test.txt',overwrite=>true);
end;
/
-- It will move the file to different location

--What if file exists and I do not override
sql>begin
       utl_file.frename(src_location=>'ABC',src_filename=>'test.txt',dest_location=>'XYZ',dest_filename=>'test.txt',overwrite=>false);
end;
/
-- If we didnt override it will show error, as same file is already created


12. Find current position in file with fgetpos
sql> declare
       fid utl_file.file_type;
     begin
       fid:=utl_file.fopen('ABC','a.txt','w',max_linesize=>32767);
       for indx in 1..10
       loop
          utl_file.put_line(fid,'Line ' || indx || 'contains GUID ' || SYS_GUID());
          DBMS_OUTPUT.PUT_LINE(utl_file.fgetpos(fid));
       end loop;
       utl_file.fclose(fid);
   end;
/
--fgetpos while writing is always 0

sql> declare
       fid utl_file.file_type;
       l_line varchar2(32767);
     begin
       fid:=utl_file.fopen('ABC','a.txt','r',max_linesize=>32767);
       for indx in 1..10
       loop
          utl_file.get_line(fid,l_line);
          DBMS_OUTPUT.PUT_LINE(utl_file.fgetpos(fid));
       end loop;
       utl_file.fclose(fid);
   end;
/


Retrieve characteristics of file with fgetattr
    - used to get how big is a file, what is its block size, does the file exist

BFile datatype
    - Binary file LOB is a data type added in oracle 8i version 
    - used for storing files, the data will be stored only in the form of files into BFile datatype, we cannot store anyother data, it can be txt file, csv file, excel file, doc file, pdf file or zip file, audio file, video file, animation, movie, exe files 
    - no maximum size limit for bfile datatype because data will never be stored inside the database in case of bfile data type, the data will always be stored outside the database that is in OS, so in order to work with bfile datatype we need to have read and write privileges on that particular folder which is alias directory 
    - we need to have alias directory with that path, we need to have read,write privilege to interact with the files which are stored through bfile datatype, all files will be stored in OS, all files will be stored outside the database due to this reason there is no guarantee for the security or consistency or protection 
    - one table can any number of bfile datatype, since data is stored outside so there is no restriction for the number of bfile data type in tables
    - no file size for bfile datatype because database is not going to hold the data 

sql> conn sys as sysdba
sql> sho user
sql> desc dba_directories;
sql> select * from dba_directories;

- Create alias directory
sql> create or replace directory dir1 as 'C:\Dir1';
sql> grant read,write on directory dir1 to scott;

sql> conn scott/tiger

sql> create table emp_bfile(c1 number, c2 bfile);
sql> desc emp_bfile;

-Inserting data into bfile table using bfilename() which is a function used to insert data into bfile data type with 2 args (ie) name of dir and name of file 

sql> insert into emp_bfile values(1, Bfilename('dir1','abc.txt'));
//here we are storing abc.txt file in dir1 directory, so db will internally find the path which is associated with this directory from DBA_DIRECTORIES and store the file specified into that particular dir
//we have manually move file into that dir 

sql> insert into emp_bfile values(2, Bfilename('dir1','abc.jpg'));
sql> insert into emp_bfile values(NULL, NULL);
sql> insert into emp_bfile values(NULL,'');
sql> insert into emp_bfile values(1, Bfilename('',''));
sql> insert into emp_bfile values(1, Bfilename(NULL,NULL));

sql> select c2 from emp_bfile;
    - We cannot display bfile content in sqlplus because they are files so we should  have UI or front end appl to view these 

>bfile column cannot be updated, but we can delete the record 
> we cannot enter number, char or any type of data except files 

DBMS_LOB and BFiles
    - Oracle allows you to manipulate bfiles through DBMS_LOB package 
    - Bfile is a pointer to an OS file 

DBMS_LOB BFILE functionality
    - Open and close BFILEs
    - Compare two bfiles with compare
    - Get info abt bfile like name,location,exists and length
    - Read contents of bfile - they are read only structured
    - perform instr and substr operations on bfile

1. Open and close Bfiles
sql> declare
     l_bfile BFILE:=BFILENAME('DIR1','abc.txt');
     begin
       DBMS_OUTPUT.PUT_LINE('Exists' \\ DBMS_LOB.fileexists(l_bfile));
       DBMS_OUTPUT.PUT_LINE('Open before open'|| DBMS_LOB.fileisopen(l_bfile));
       DBMS_LOB.fileopen(l_bfile);
       DBMS_OUTPUT.PUT_LINE('Open after open'|| DBMS_LOB.fileisopen(l_bfile));
       DBMS_LOB.fileclose(l_bfile);
       DBMS_OUTPUT.PUT_LINE('Open after close'|| DBMS_LOB.fileisopen(l_bfile));
     End;
/
       
2. Compare two Bfiles are same or not, 0=same, 1=different 
      - Specify amount of file you want to compare and the offset locations in each

- Create file1.txt with first 5 lines we give Line 1 and then the word 'same' and next 5 lines with Line number and going to generate guid which is string with unique value so each line should have a different value

sql> declare
        fid utl_file.file_type;
     begin
        fid := utl_file.fopen('dir1','file1.txt','w',max_linesize => 32767);
        for i in 1 .. 5
        loop
           utl_file.put_line(fid, 'Line ' || i || ' same');
        end loop;
        for i in 1 .. 5
        loop
           utl_file.put_line(fid, 'Line ' || i || SYS_GUID);
        end loop; 
        utl_file.fclose(fid);
     End;
/

-Create file2.txt

sql> declare
        fid utl_file.file_type;
     begin
        fid := utl_file.fopen('dir1','file2.txt','w',max_linesize => 32767);
        for i in 1 .. 5
        loop
           utl_file.put_line(fid, 'Line ' || i || ' same');
        end loop;
        for i in 1 .. 5
        loop
           utl_file.put_line(fid, 'Line ' || i || SYS_GUID);
        end loop; 
        utl_file.fclose(fid);
     End;
/

- So we created 2 file with some of the same content and some different content 

sql> declare
        l_bfile1 BFILE:=BFILENAME('dir1','file1.txt');      
        l_bfile2 BFILE:=BFILENAME('dir1','file2.txt');      
     begin
        DBMS_LOB.fileopen(l_bfile1);
        DBMS_LOB.fileopen(l_bfile2);

//compare portions of file that are same
        DBMS_OUTPUT.PUT_LINE(DBMS_LOB.compare(file_1 => l_bfile1, file_2 => l_bfile2,amount => 33,offset_1=>1,offset_2=>1));  //0

//compare portions of file that are different
        DBMS_OUTPUT.PUT_LINE(DBMS_LOB.compare(file_1 => l_bfile1, file_2 => l_bfile2,amount => 33,offset_1=>55,offset_2=>25));  //1

//compare the entire file
        DBMS_OUTPUT.PUT_LINE(DBMS_LOB.compare(file_1 => l_bfile1, file_2 => l_bfile2,amount => 18446744073709551615)); //here amt refers lob maxsize  //1
        DBMS_LOB.fileclose(l_bfile1);
        DBMS_LOB.fileclose(l_bfile2);
End;
/

3. Get information about BFILE
      - Get name of the file: FILEGETNAME
      - Get length of file: GETLENGTH
      - Does the file exists: FILEEXISTS
      - Is the file open: FILEISOPEN

sql> declare
        l_bfile BFILE := BFILENAME('DIR1','file1.txt');
        l_dir varchar2(1000);
        l_name varchar2(1000);
     begin
        DBMS_OUTPUT.PUT_LINE(DBMS_LOB.fileexists(l_bfile));//1
        DBMS_LOB.fileopen(l_bfile);
        DBMS_OUTPUT.PUT_LINE(DBMS_LOB.fileisopen(l_bfile));//1
        DBMS_OUTPUT.PUT_LINE(DBMS_LOB.getlength(l_bfile));
        DBMS_LOB.filegetname(l_bfile,l_dir,l_name);
        DBMS_OUTPUT.PUT_LINE(l_dir||' '||l_name);
        DBMS_LOB.fileclose(l_bfile);
     ENd;
/

4. Read contents of Bfile
        - Use DBMS_LOB.READ to read into raw or varchar2 variable for clob, but for bfiles only raw
        - Here open the file and using read() procedure we specify the amount we want to get using l_amount and starting location and the buffer that will receive it using l_contents 

sql> declare
        l_bfile BFILE:=BFILENAME('dir1','file1.txt');
        l_contents raw(32767);
        l_amount pls_integer := 100;
     begin
        dbms_lob.fileopen(l_bfile);
        dbms_lob.read(l_bfile,l_amount,1,l_contents);
        dbms_output.put_line(l_contents);
        dbms_lob.fileclose(l_bfile);
     end;
/

It will print the raw data 

5. Other Bfile operation
       - Read a bfile into blob or clob
       - Perform instr operation on the contents of bfile (ie) to check this string exists in my bfile
       - Perform substr operation on the contents of bfile (ie) we can pull out chunks of my bfile using substring

sql> declare
       l_bfile bfile:=BFILENAME('dir1','file1.txt');
       l_clob clob;
       l_dest_offset pls_integer := 1;
       l_src_offset pls_integer := 1;
       l_context pls_integer := 0;
       l_warning pls_integer;
     begin
//we need to create temporary clob otherwise it will not be able to use l_clob as clob
       dbms_lob.createtemporary(l_clob,false);

//open file for read only access 
       dbms_lob.open(l_bfile,dbms_lob.file_readonly);

//convert bfile to clob
//use lobmaxsize to specify entire bfile
       dbms_lob.loadclobfromfile(dest_lob=>l_clob,src_bfile=>l_bfile,amount=>dbms_lob.lobmaxsize,est_offset=>l_dest_offset,src_offset=>l_src_offset,bfile_csid=>0,lang_context=>l_context,warning=>l_warning);

DBMS_OUTPUT.PUT_LINE('Clob length'||DBMS_LOB.getlength(l_clob));
 
If dbms_lob.instr(file_loc=>l_bfile,pattern=>'123',offset=>1,nth=>1)>0
then
   DBMS_OUTPUT.PUT_LINE('Found 123');
END IF;

DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(file_loc=>l_bfile,amount=>5,offset=>1));
END;
/

Bind/Host variables in PL/SQL
      - Unlike user variables which can only be declared inside the declaration section of PL/SQL block, u can declare bind variable anywhere in host env and that is the reason we refer bind variable as host variables
      - Bind variables in oracle database can be defined as the variables that we created in SQL*PLUS and then reference in PL/SQL 

Declare in bind variables
     - using "variable" command declares the bind variable and do not need to write any PL/SQL block or section 

sql>variable v varchar2(10);

Initialize bind variable using :
1. using execute command
sql> exec :v := 'Ram';

2. Using execution section of pl/sql part
sql>begin
      :v := 'Sam';
    end;
/

3. Display bind variable - 3 ways
1. Using DBMS_OUTPUT 
sql>begin
      :v := 'Sam';
      dbms_output.put_line(:v);
    end;
/

2. Using print command in host env rather in plsql  block 
sql> print :v;

3. using autoprint on we can display the current value stored in any bind variable without use of print or dbms_output
sql> set autoprint on
sql> variable v1 varchar2(10)
sql> exec :v1 := 'Raj';
It will automatically print the value after line 3

Cursor
   - It is a pointer to a memory area called context area. This context area is a memory region inside Program Global area or PGA, assigned to hold the information about the processing of SELECT stmt or DML statement 

Context Area
   - It is a memory region inside PGA which helps oracle server in processing an SQL stmt by holding the important info about that statement like
     1. Rows returned by a query
     2. Number of rows processed by a query
     3. A pointer to the parsed query in shared pool

Types of Cursors
   1. Implicit cursors
         - Will be automatically created by oracle server everythime when DML stmt is executed
         - User cannot control the behavior of these cursors 
         - Oracle server creates an implicit cursor for any PLSQL block which executes an SQL stmt,as long as an explicit cursor does not exists for that SQL stmt

   2. Explicit cursors
          - It is user defined cursors which means user has to create these cursors for any stmt which returns more than one row of data 
          - User have full control on explicit cursor 

Cursor parameters 
     - We can pass as many parameters to cursor but always make sure that when u open the cursor, u need to include corresponding arg value in parameter list for each parameter

sql> declare
        v_name varchar2(30);
        cursor c1(v varchar2) is select fname from emp where empid < v;
      begin
          open c1(100);
          loop
             fetch c1 into v_name;
             exit when c1%NOTFOUND;
             dbma_coutput.put_line(v_name);
             end loop;
            close c1;
end;
/

Create Cursor parameter with default value
   Every cursor parameter has some restrictions, for example we have to specify the argument for each parameter when we open the cursor otherwise we get PLS:00306 error
   To overcome this restriction we have option called default value, which is assign to parameter of ur cursor during the declaration of cursor    
   Default value comes into action only when user does not specify the arg for the parameter while opening the cursor. If we have default value and also specify an argument for the parameter in ur OPEN CURSOR stmt then the result will be based on value we provide in OPEN CURSOR stmt and not on default value 

sql> declare
        v_name varchar2(30);
        v_id number(10);
        cursor c1(vid number:=100) is select fname,empid from emp where empid > vid;
      begin
          open c1;
          loop
             fetch c1 into v_name,v_id;
             exit when c1%NOTFOUND;
             dbma_coutput.put_line(v_name||' '||v_id);
             end loop;
            close c1;
end;
/

Cursor FOR loop
    - It is type of for loop provided by oracle pl/sql to make work with explicit cursor easier
    - In order to work with explicit cursor we have to follow a chain of process like declare,open,fetch and close cursor
    - Cursor for loop reduces the burden of opening,fetching and closing the cursor

Syntax: 
    for loop_index IN cursorname
       loop
         --statement
       end loop;

sql> declare
         cursor c1 is select fname,lname from emp where eid>200;
     begin
         for i in c1
           loop
             dbms_output.put_line(i.fname||' '||i.lname);
           end loop;
      end;
/

Cursor for loop with parameters
sql> declare
         cursor c1 (v number) is select fname,lname from emp where eid>v;
     begin
         for i in c1(200)
           loop
             dbms_output.put_line(i.fname||' '||i.lname);
           end loop;
      end;
/

Ref cursors
     - It is an acronym of Reference to a Cursor
     - It is a PL/SQL datatype using which you can declare a special type of variable called cursor variable
     - A single cursor variable can be associated with  multiple SELECT statements in a single PL/SQL block
     - A static cursor can only access single select statement at a time
     - 2 types
1. Strong Ref cursor - Any ref cursor which has fixed return type
Syntax:  Declare
           type ref_cursor_name is ref cursor return (return type);

The return type of cursor must always be record type only. It can be either table based record or user defined record 

Example 1: 
   - Here the retrun value of my_RefCur is a table based record, where we used employees table
   Type my_RefCur IS REF CURSOR RETURN employee%ROWTYPE;
   - Next we create cursor variable which is used to refer cursor type 
        cur_var my_RefCur;
   - Next we create another variable for holding the data which we will be fetching from our ref cursor 
     rec_var employee%ROWTYPE;
Here we have another table based record datatype for holding the data from our ref cursor 
    - OPEN FOR stmt is opening our ref cursor for SELECT stmt in which we are selecting data from all the columns of Employee table 
    - Using FETCH stmt we are fetching the data from our stron ref cursor into the variable rec_var 

sql> declare
        Type my_RefCur IS REF CURSOR RETURN employee%ROWTYPE;
        cur_var my_RefCur;
        rec_var employee%ROWTYPE;
      begin
        OPEN cur_var FOR select * from employee where empid=100;
        FETCH cur_var INTO rec_var;
        CLOSE cur_var;
      dbms_output.put_line(rec_var.fname||'has salary'||rec_var.salary);
   end;
/

Example 2:
    Previously we fetch all columns from employee table, but if we want data from some specific column of employee table by using strong ref cursor with user defined record datatype
   - We define userdefined record datatype my_rec with one field emp_sal
   TYPE my_rec IS RECORD(emp_sal employee.salary%TYPE);
  - Create strong ref cursor refCur which returns a result of my_rec datatype which is the record based datatype
    TYPE ref_cur IS REF CURSOR RETURN my_ref
  - We create cursir variable cur_var whcih used to refer to our strong ref cursor
     cur_var ref_cur;
  - we create another variable at_var used to hold the data returned by our strong ref cursor
     at_var employee%salary%TYPE;

sql> declare
        TYPE my_rec IS RECORD(emp_sal employee.salary%TYPE);
        TYPE ref_cur IS REF CURSOR RETURN my_ref
        cur_var ref_cur;
        at_var employee%salary%TYPE;
      begin
        OPEN cur_var FOR select salary from employee where empid=100;
        FETCH cur_var INTO at_var;
        CLOSE cur_var;
      dbms_output.put_line('Salary of employee is '||at_var.salary);
   end;
/

2. Weak ref cursors are those which do not have any return type
  - Because weak ref cursors dont have fixed return type thus they are open to all types of select stmt
Syntax: Type ref_cursor is ref cursor;

sql>declare
     TYPE wk_refcur IS REF CURSOR;   -- create weak ref cursor
     cur_var wk_refcur;   -- create cursor variable
     f_name employee.fname%TYPE;
     emp_sal employee.salary%TYPE;  --used to hold data which will be fetched into weak ref cursor
 begin
        OPEN cur_var FOR select fname,salary from employee where empid=100;
        FETCH cur_var INTO f_name,emp_sal;
        CLOSE cur_var;
      dbms_output.put_line(f_name||'has salary'||emp_sal);
   end;
/

sys_refcursor
    - It is a predefined weak ref cursor which comes built-in with oracle database 
    - We create weak ref cursor as 2 step process but it will be reduced using sys_refcursor
    When using sys_refcursor we just create cursor variable and nothing else.

sql>declare
     cur_var sys_refcursor;   -- create cursor variable
     f_name employee.fname%TYPE;
     emp_sal employee.salary%TYPE;  
 begin
        OPEN cur_var FOR select fname,salary from employee where empid=100;
        FETCH cur_var INTO f_name,emp_sal;
        CLOSE cur_var;
      dbms_output.put_line(f_name||'has salary'||emp_sal);
   end;
/


Special datatype
1. Anchored datatype
2. Record datatype

Records
   - It is composite data structures made up of different components called fields, these fields can have different data types 
   - Record is an group of related data items stored in fields, each with its own name and datatype

Types of Record
    1. Table based record
    2. Cursor based record
    3. User defined record

Declaration of record datatype
    - Similar to %TYPE to declare anchored datatype we have %ROWTYPE to declare variable with record datatype

Syntax:
    variable_name tablename%ROWTYPE;
    variable_name cursorname%ROWTYPE;

Table based record datatype
      In case of select into stmt, we will declaring the variables to store the values fetched from database, it is suitable when we know the structure of the table 
      But we dont know the structure of table or one day someone decide to change the datatype or data width of salary column of table, so all plsql prg based on this table is useless. The solution to this problem is record datatype variables 
   - First we create record variable v_emp with %ROWTYPE (ie) if we have a record variable created using Employee table then that variable will have all fields corresponding to that table 

Example 1: Initialize record variable by fetching data from all the columns of table using select into stmt

sql>declare
       v_emp employee%ROWTYPE;
    begin
       select * into v_emp from employee where emp_id=200;
       dbms_output.put_line(v_emp.fname||' '||v_emp.salary);
    end;
/

Example 2: If we want to fetch the data from selected columns of table 

sql>declare
       v_emp employee%ROWTYPE;
    begin
       select fname,salary into v_emp.fname,v_emp.salary from employee where emp_id=200;
       dbms_output.put_line(v_emp.fname||' '||v_emp.salary);
    end;
/

2. Cursor based records
         Cursor based records are those variables whose structure is derived from SELECT list of an already created cursor

1. Declaration of cursor based records
2. Initialization of cursor based records
3. Accessing data stored into the cursor based record variable 

Example 1: cursor returning values from only one row from table 

sql> declare
        cursor c1 IS select fname,salary from employee where empid=100;
        var_emp c1%ROWTYPE;  --cursor based record
     begin
         open c1;
         fetch c1 into var_emp;
         dbms_output.put_line(var_emp.fname||''||var_emp.salary);
   end;
/

Example 2: Cursor returning records of multiple employees

sql> declare
        cursor c1 IS select fname,salary from employee where empid>100;
        var_emp c1%ROWTYPE;  --cursor based record
     begin
         open c1;
         loop
         fetch c1 into var_emp;
         exit when c1%NOTFOUND;
         dbms_output.put_line(var_emp.fname||''||var_emp.salary);
       end loop;
       close c1;
   end;
/

3. User defined record
      User define records are the record variables whose structure is defined by the user, which is unlike the table based or cursor based records whose structures are derived from their respective tables or cursor 

Syntax:   TYPE type_name IS RECORD(
               field_name1 datatype1, field_name2 datatype2,...);
          recordname type_name;

sql>declare
      TYPE rv_dept IS RECORD(fname varchar2(20),dname dept.dname%TYPE);
      var1  rv_dept;
    begin
       select fname,dname into var1.fname,var1.dname from employee join dept using deptid where emp_id=100;
       dbms_output.put_line(var1.fname||' '||var1.dname);
   end;
/


Bulk Collect
    - It is about reducing context switching and improving query performance

What is Context Switching?
    - Whenever you write a PL/SQL block and execute it, the PL/SQL runtime engine starts processing it line by line. This engine processes all the PL/SQL stmts by itself, but it passes all the SQL stmts which u coded into PL/SQL block to SQL runtime engine. Those SQL stmts will then get processed separately by the SQL engine, once it is done processing them , sql engine then returns the result back to PL/SQL engine,so that combined result can be produced by latter. This to and fro hopping of control is called context switching
    So higher the hopping of controls the greater will be the overhead which in turn will degrade the performance 

   - Bulk collect clause reduces multiple control hopping by collecting all SQL stmt calls from PL/SQL program and sending them to SQL engine in just one go and vice versa
     It is like instead of taking multiple trips for transferring palyers from their hotel to stadium using cycle just put them all into a bus and take them to the stadium in one single trip

Defination
    - Bulk collect clause reduces/compresses multiple switches into a single context switch and increase the efficiency and performance of a PL/SQL program. 
      The process of fetching batches of data from PL/SQL runtime engine to SQL runtime engine and vice versa is called bulk data processing 
    - Bulk collect clause can be used with SELECT-INTO,FETCH-INTO,RETURNING-INTO 

Bulk Collect with SELECT-INTO
     Consider we have PL/SQL program 
sql> declare
         TYPE nt_fname IS TABLE OF varchar2(20);
         fname nt_fname;
     begin
         SELECT first_name into fname FROM employee;
     end;
/

The execution section of this prg consists of SQL operation and that SQL operation is SELECT stmt, this stmt retrieving all data from first_name column of employee table and storing it in collection which we created in declaration section 
    Consider employee table contains 100 rows, then the control will jump 100 times from PL/SQL to SQL engine and 100 times from SQL to PL/SQL engine, so there will be total 200 jumps between PL/SQL and SQL runtime engines, so it will reduce performance, so we should have an option to reduce the control jumps between engines using bulk collect clause

sql> declare
         TYPE nt_fname IS TABLE OF varchar2(20);
         fname nt_fname;
     begin
         SELECT first_name BULK COLLECT INTO fname FROM employee;
         FOR idx IN i..fname.count
         LOOP  
           dbms_output.put_line(idx||'-'||fname(idx));
         end loop;
     end;
/

On the execution of this program when PL/SQL engine comes across SQL operation, it will club all 100 context switches together into one single context switch and send it to SQL engine in single go, instead of transferring individually to SQL engine. So here instead of 200 context switches we have only have 2 context switches (ie) one from PL/SQL to SQL and one from SQL to PL/SQL

Bulk Collect clause with FETCH-INTO statement
       But SELECT-INTO is not flexible like other standard SQL queries. For example with SELECT-INTO stmt we cannot decide when to fetch the records or how many records we want to retrieve at once. In order to overcome this problem we use explicit cursor which includes FETCH-INTO as 3rd step in cursor declaration process

sql>declare
       cursor exp_cur IS select first_name from employee;
       TYPE nt_fname IS TABLE OF varchar2(20);
       fname nt_fname;
     begin
        open exp_cur;
        loop
            fetch exp_cur BULK COLLECT INTO fname;
            EXIT when fname.count=0;
            FOR idx IN fname.FIRST..fname.LAST 
              loop
                dbms_output.put_line(idx||' '||fname(idx));
              end loop;
          end loop;
       close exp_cur;
end;
/
 
Limit clause with BULK COLLECT
      Previously we have learnt abt query performance, but still there is memory overhead caused by bulk collect 

Memory Overhead
      Whenever we retrieve or fetch large number of records using bulk collect clause, our program starts consuming lot of memory in order to be fast and efficient, that degrades the performance of the database which means that our query must be performing well but at same time our database may not
    This problem of memory exhaustion can easily be overcome if we can control the amount of data fetched using bulk collect clause, we can do that using bulk collect with limit clause and it can be used only with FETCH-INTO and it cant used with SELECT-INTO  

sql>declare
       cursor exp_cur IS select first_name from employee;
       TYPE nt_fname IS TABLE OF varchar2(20);
       fname nt_fname;
     begin
        open exp_cur;
        fetch exp_cur BULK COLLECT INTO fname LIMIT 10;
        close exp_cur;
        FOR idx IN 1..fname.COUNT 
              loop
                dbms_output.put_line(idx||' '||fname(idx));
              end loop;
end;
/

So instead of fetching all the records and exhausting an expensive resource like memory, we are retrieving only necessary rows and that too without any resource wastage 

Bulk data processing using FORALL statement
     - FORALL statement reduces context switches which occur during the execution of DML statement in a loop, in other words FORALL is a bulk loop constrcut which executes one DML stmt multiple times at once
     - FORALL stmt reduces context switches by sending execution call of DML from PL/SQL to SQL in batches instead of one at a time 

Syntax:
     FORALL index in bound_clause
     [SAVE EXCEPTION]
     DML stmt;

SAVE EXCEPTION keeps FORALL stmt running even when DML stmt causes an exception 
DML stmt - need to refernce atleast one collection in its values or where clause. With FORALL stmt we can use only one DML at a time
bound_clause - controls the value of index as well as decides  the number of iteration of a FORALL stmt - 3types
    1. lower and upper bound - specify starting and ending of consecutive index number of referenced collection, make sure the collection whose index numbers you are referencing here should not be parse
    2. INDICES OF - If ur referencing collection is sparse and dont have consecutive index numbers to specify, using INDICES OF we can specify subscript number of ur sparse collection such as nestedtable or associative array 
    3. VALUES OF - If we want to use FORALL stmt with very specific individual elements of a particular collection. Using VALUES OF bound clause you can specify group of indices which dont need to be either uniqur or consecutive that a FORALL stmt can loop through 

FORALL stmt with lower and upper bound clause
       FORALL stmt does same work as bulk collect but in inverse manner (ie) in bulk collect we are fetching data from tables and storing it in collection but in FORALL we fetch data from collection and store it in table

sql>create table tut77(mul_tab number(5));

sql>declare
        TYPE my_array IS TABLE OF NUMBER INDEX BY PLS_INTEGER;  -- created associative array called my_array 
        col_var my_array; 
        tot_rec number;   -- used to check how many  records are fetched from collection and stored in table
      begin
          -- Populate the collection
          FOR i IN 1..10 LOOP
              col_var(i) := 9*i;
          END LOOP;
           
          --Insert data from collection to table
          FORALL  idx IN 1..10
             insert into tut77(mul_tab) values (col_var(idx));

     select count(*) into tot_rec from tut77;
     dbms_output.put_line('Total records are ' || tot_rec);
     end;
/

Two rules while writing FORALL stmt
     1. FORALL stmt can have only one DML stmt at a time
     2. DML stmt in its either values or where clause must reference the collection whose indexes we used in our bound clause

In above example we have only 1 insert stmt and that stmt referencing the collection my_array through the collection variable col_var in its values clause
    
FORALL stmt with INDICES OF bound clause
       
sql>create table tut78(mul_tab number(5));

Here we created nestedtable called my_nested_table and initialized with 10 elements using var_nt, so this nested table is dense collection because the indexes of this collection are populated consecutively. But now using delete() we deleted data from 3 to 6 index, so index of collection is not populated sequentially, so the collection becomes sparse

sql>declare
       TYPE my_nested_table IS TABLE OF number;
       var_nt my_nested_table := my_tested_table(9,18,27,36,45,54,63,72,81,90);
     begin
        var_nt.DELETE(3,6);
        FORALL idx IN 1..10
          INSERT INTO tut78(mul_tab) values (var_nt(idx));
     end;
/

Here we are taking data from collection and storing it into the table, and we use lower and upper bound as 1 to 10 which means this stmt will traverse from index number 1 to 10 and we get an error 
    So problem with lower and upper bound is that we cannot use it with sparse collection, so we use indices of 

sql>declare
       TYPE my_nested_table IS TABLE OF number;
       var_nt my_nested_table := my_tested_table(9,18,27,36,45,54,63,72,81,90);
       tot_rec number;
     begin
        var_nt.DELETE(3,6);
        FORALL idx IN INDICES OF var_nt
          INSERT INTO tut78(mul_tab) values (var_nt(idx));
        
     select count(*) into tot_rec from tut78;
     dbms_output.put_line('Total records are ' || tot_rec);
     end;
/

Here we initialize 10 elts, then we deleted 4 elts and we left with 6 elts, so output is 6

FORALL stmt with VALUES OF bound clause 
      FORALL stmt is all about binding the collection elements with a single DML stmt in an optimized manner 
      Using 'values-of' bound clause of FORALL stmt we can bind the selected elements of the collection with DML stmt
     - VALUES OF clause requires two collection, 
   1. The first collection will be the source collection - we will be doing DML operations on data of this collection using FORALL stmt
   2. The second collection will be indexing collection which will specify the index number of selected elements from first collection 
      These selected elements will be those elements over which you want to perform DML operations
      This indexing collection must be a nested table or an associative array. If it is an associative array then it must be indexed by PLS_INTEGER or BINARY_INTEGER 

sql> create table tut79(selected_data number(4));

Here we create nested table my_nestedtable which holds number datatype and initialize with 10 indexes of our index table. This will act as source collection for our FORALL stmt. Here we want to index only 3rd,7th,8th and 10th element of this collection into the table tut79 which we created
     Next we create indexing collection, using this we will limit our FORALL stmt to execute only for 3rd,7th,8th and 10th elt 

sql>declare
      --Source collection
      TYPE my_nestedtable IS TABLE OF NUMBER;
      source_col my_nestedtable := my_nestedtable(9,18,27,36,45,54,63,72,81,90);

      --Indexing collection, datatype of elt which it hold is pls_integer which is also datatype of indexing element
      TYPE my_array IS TABLE OF PLS_INTEGER  INDEX BY PLS_INTEGER;
      index_col my_array;

    begin
       -- initialize indexing collection with those index number of source collection whose data we want to fetch and store into table, indexing collection is sparse collection we have  not initialized it in a consecutive manner. We stored 1st record at index 1, 2nd record at index 5 etc
    Even we can store these records in a sequential manner too, its completely ur choice because number of index where u store the data in ur indexing collection does not matter like 1,5,12,28, the data storing into ur indexing collection matters like 3,7,8,10
       
      index_col(1) := 3;
      index_col(5) := 7;
      index_col(12) := 8;
      index_col(28) := 10;

--Now we use this collection in our FORALL stmt using VALUES OF bound clause

   FORALL idx IN VALUES OF index_col
      insert into tut79 values(source_col(idx));
 end;
/

After writing the reserved phrase VALUES OF we have specified the collection variable of our indexing collection called index_col, then we have our insert DML using which we are inserting records from our source collection which is referenced through its collection variable source_col into the table tut79
    We use source collection into our DML stmt while we use indexing collection with VALUES OF bound clause. On execution this FORALL stmt will fetch the data from index 3,7,8,10 from the source collection and store it in tut79
       
Associative Array
    - Unlike Nested table and varray, associative array hold elemts of similar datatype in key value pairs 
    - It is non persistent, which  means neither the array nor the data can be stored in the database 
    - It is also an unbounded collection which means there is no upper bound 

sql>declare
     --created an associative array called books which can hold elements of number and using index by clause we specify datatype of associative array subscript. The value stored against index as varchar2 will act as key and value is stored as number 
     TYPE books IS TABLE OF NUMBER INDEX BY VARCHAR(20);

--create associative array variable and associative array does not require initialization and have no constructor syntax      
      isbn books;
      flag varchar2(20);
begin
   isbn('Oracle') := 1234;
   isbn('MySQL') := 987;
   isbn('MySQL') := 1010;
   flag := isbn.FIRST;
   while flag IS NOT NULL
   LOOP
     dbms_output.put_line('key => '||flag||'Value => '||isbn(flag));
     flag := isbn.NEXT(flag);
    END LOOP;
END;
/

PL/SQL Conditional statement
1. if...then statement can be used when there is only a single condition to be tested. 

sql>DECLARE
	x int:=10;
	y int:=80;
BEGIN
	if(y>x) then
		dbms_output.put_line('Result: ' ||y|| ' is greater than ' ||x);
	end if;
END;

2.if...then...else statement

sql>DECLARE
	x int;
BEGIN
	x := &x;
	if mod(x,2) = 0 then
		dbms_output.put_line('Even Number');
	else
		dbms_output.put_line('Odd Number');
	end if;
END;

3. if...then...elsif...else statement
sql>DECLARE
	a int;
	b int;
BEGIN
	a := &a;
	b := &b;
	if(a>b) then
		dbms_output.put_line(‘a is greater than b’);
	elsif(b>a) then
		dbms_output.put_line(‘b is greater than a’);
	else
		dbms_output.put_line(‘Both a and b are equal’);
	end if;
END;

4. CASE stmt

Syntax: CASE selector
	when value1 then Statement1;
	when value2 then Statement2;
	...
	...
	else statement;
end CASE;

sql>set serveroutput on;
DECLARE
	a int;
	b int;
BEGIN
	a := &a;
	b := mod(a,2);
	CASE b
		when 0 then dbms_output.put_line('Even Number');
		when 1 then dbms_output.put_line('Odd Number');
 		else dbms_output.put_line('User has not given any input value to check');
	END CASE;
END;

5. Searched Case Statement
In this type of case statement, no selector is used but a test condition is checked by using the WHEN clause itself. 

Syntax: CASE
	when <test_condition1> then statement1;
	when <test_condition2> then statement2;
    ...
    ...
	else defaultstatement;
end case;

sql>set serveroutput on;

DECLARE
	dt Date;
	str varchar2(10);
BEGIN
	dt := '&date';
	str := to_char(dt,'DY');
	CASE
		when str in ('SAT','SUN') then dbms_output.put_line('Its the Weekend');
 		else dbms_output.put_line('Not a Weekend');
	END CASE;
END;


2. PL/SQL Looping statement

1. PL/SQL Basic Loop
     we use the basic loop the code block will be executed at least once.

sql>DECLARE
	i int;
BEGIN
	i := 0;
	LOOP
		i := i+2
		dbms_output.put_line(i);
		exit WHEN x > 10
	END LOOP;
END;

2. While loop
sql> DECLARE
	num int:=1;
BEGIN
	while(num <= 10) LOOP
		dbms_output.put_line(''|| no);
		num := num+2;
	END LOOP;
END;

3. FOR Loop
sql>DECLARE
	i number(2);
BEGIN
	FOR i IN 1..10 LOOP
		dbms_output.put_line(i);
	END LOOP;
END;

sql>DECLARE
	i number(2);
BEGIN
	FOR i IN REVERSE 1..10 LOOP
		dbms_output.put_line(i);
	END LOOP;
END;

3. Unconditional branching stmt using GOTO stmt

sql> 
     


PRAGMA SERIALLY_REUSABLE
    - Enforces different behaviour to packaged variable 

1. Now we create 2 packages, one without serially reusable and another with serially reusable 
sql> create or replace package pk_non_sr as
        lv_num number;
     end;
/
sql> create or replace package pk_sr as 
        pragma SERIALLY_REUSABLE;
        lv_num number;
     end;
/

2. Now we initialize the value to variable and execute it 

sql>begin
      pk_non_sr.lv_num := 10;
      dbms_output.put_line(pk_non_sr.lv_num); --10
    end;
/

sql>begin
      pk_sr.lv_num := 10;
      dbms_output.put_line(pk_sr.lv_num); --10
    end;
/

In both cases it will print 10, packaged variable are used as global variable (ie) the value assigned to variable will be available till you disconnect from session (ie) the memory allocated to variable will be available till you disconnect from the session 

3. After sometime if we try to print the value, it will still print as 10 (ie) variable is global variable which holds the value till end of session 

sql>begin
      dbms_output.put_line(pk_non_sr.lv_num); --10
    end;
/

But if we try to print the value of serially_reusable, in this case it will not print the value as 10 instead it print as null, this is because pragma serially_reusable enforces the value to be hold only for the block in which it is declared and will not available till end of session 

sql>begin
      dbms_output.put_line(pk_sr.lv_num); --null
    end;
/

So when u specify pragma serially_reusable keyword, the variables declared to value only for the block it will be executing not till end of session 


