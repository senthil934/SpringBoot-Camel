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
create or replace directory user_dir as 'C:\Angular\'; 
conn sys as sysdba
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

1. Before writing or reading data from OS file, first we have to create alias directory. Actually PL/SQL program does not directly interact with OS files, if we want to interact with OS files then we must create logical directory, that logical dir name whenever we specifying in PL/SQL program then automatically through that path OS reference that file only 

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
        fid:=utl_file.fopen('XYZ','test.txt','w');
        utl_file.put_line(fid,'hello');
        utl_file.put(fid,'world');
        utl_file.putf(fid,'welcome to plsql');
        utl_file.fclose(fid);
end;
/
-- It will create a file test.txt

sql>begin
       utl_file.fremove('XYZ','test.txt');
    end;
/
-- It will remove the file

11. Rename and move a file with Frename

sql> declare
        fid utl_file.file_type;
     begin
        fid:=utl_file.fopen('XYZ','test.txt','w');
        utl_file.put_line(fid,'hello');
        utl_file.put(fid,'world');
        utl_file.putf(fid,'welcome to plsql');
        utl_file.fclose(fid);
end;
/
-- It will create test.txt in C:/Training folder

--copy to file with different name
sql>begin
       utl_file.frename(src_location=>'XYZ',src_filename=>'test.txt',dest_location=>'ABC',dest_filename=>'test_copy.txt',overwrite=>true);
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
       fid:=utl_file.fopen('XYZ','a.txt','w',max_linesize=>32767);
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
       fid:=utl_file.fopen('XYZ','a.txt','r',max_linesize=>32767);
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

sql> insert into emp_bfile values(1, Bfilename('XYZ','abc.txt'));
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
     l_bfile BFILE:=BFILENAME('XYZ','a.txt');
     begin
       DBMS_OUTPUT.PUT_LINE('Exists' || DBMS_LOB.fileexists(l_bfile));
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
         - Will be automatically created by oracle server everytime when DML stmt is executed
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
             dbms_output.put_line(v_name);
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
         cursor c1 is select fname,lname from emp where empid>200;
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

sql> declare
  2        TYPE rv_dept IS RECORD(fname varchar2(20),dname dept.dname%TYPE);
  3        var1  rv_dept;
  4      begin
  5         select e.fname,d.dname into var1.fname,var1.dname from emp e join dept d on e.deptid=d.deptid and e.empid=100;
  6         dbms_output.put_line(var1.fname||' '||var1.dname);
  7     end;
  8  /


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
     [SAVE EXCEPTION] DML stmt;

SAVE EXCEPTION keeps FORALL stmt running even when DML stmt causes an exception 
DML stmt - need to refernce atleast one collection in its values or where clause. With FORALL stmt we can use only one DML at a time
bound_clause - controls the value of index as well as decides  the number of iteration of a FORALL stmt - 3types
    1. lower and upper bound - specify starting and ending of consecutive index number of referenced collection, make sure the collection whose index numbers you are referencing here should not be parse
    2. INDICES OF - If ur referencing collection is sparse and dont have consecutive index numbers to specify, using INDICES OF we can specify subscript number of ur sparse collection such as nestedtable or associative array 
    3. VALUES OF - If we want to use FORALL stmt with very specific individual elements of a particular collection. Using VALUES OF bound clause you can specify group of indices which dont need to be either unique or consecutive that a FORALL stmt can loop through 



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
    - Unlike Nested table and varray, associative array hold elemts of similar datatype in key value pairs, they cannot be reused 
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

RAISE_APPLICATION_ERROR
     - Another way of declaring user defined exception 
and it is inbuilt procedure comes with oracle
     - Using this procedure you can associate an error number with custom error message. Combining both error number and error message you can compose an error string which looks similar to those default error strings which are displayed by oracle engine when error occurs 

>ACCEPT var_age NUMBER PROMPT 'What is ur age?';
 DECLARE
    age number := &var_age;
 begin
    if age<18 THEN
       RAISE_APPLICATION_ERROR(-20008,'Your age shoud greater than 18');
    end if;
    dbms_output.put_line('Your age is greater');
 exception
    when others then
        dbms_output.put_line(SQLERRM);
end;
/

PRAGMA EXCEPTION_INIT
    - Also defines user defined exception but here we cannot name the exception 
    - In PL/SQL we handle all the exceptions which has no name in "others" exception handler and that causes confusion especially when working on a project which is huge and habing multiple user defined exception, we can easily overcome this problem by using PRAGMA EXCEPTION INIT
    - Using Pragma Exception_Init we can associate an exception name with an oracle error number 

sql>declare
       ex_age EXCEPTION;
       age number := 17;
       PRAGMA EXCEPTION_INIT(ex_age,-20008);
    begin
       IF age<18 THEN
          RAISE_APPLICATION_ERROR(-20008,'Your age shoud greater than 18');
    end if;
    dbms_output.put_line('Your age is greater');
 exception
    when ex_age then
        dbms_output.put_line(SQLERRM);
end;
/
          

Performance Tuning
    First understand how to start with PLSQL tuning because many times the requirements comes like the given procedure is taking more time and you need to start tuning, so the biggest problem of performance tuning that too specifically in plsql is that u cannot start with manual inspection of code because the procedure may call another procedure which in turn may call another one and it can go for n number of PLSQL call and so literally it is not possible for you to go through each and every line of code, to check whether that particular line is taking more time or not 
    So we discuss where to start with plsql tuning and how to identify the potential bottleneck in plsql code because once u know the place where it is taking time then you can start tuning that particular line. To ease the process of PLSQL performance tuning oracle has provided an inbuilt tool called DBMS_PROFILER 

How to start with PLSQL Performance tuning ?
     1. Start with the manual inspection of code to check whether a particular line might take more time or not, this will work as far as the number of lines in the plsql code is very less.
     Suppose if you are tuning one procedure and it is not calling any other plsql unit and if the number of lines in plsql code is very less then this may work, however this may not work if there is too many plsql calls internally 
   2. Another way is we can put enough log statements to capture the timing of each and every stmt so that by analyzing the log stmt, you can easily identify where exactly the time is going or which particular stmt is taking more time 
   This also will work if number of lines in plsql code is very less but this is not most efficient way because you need to keep modifying plsql code to check whether a particular line is taking more or not
   3. Instead of doing all these thing we can use inbuilt tool called DBMS_PROFILER

What is DBMS_PROFILER?
    - It is a package provided by Oracle to capture the info about the PLSQL code and runtime info like how much time each line is taking and how many number of time a particular stmt is being executed, so these info are captured in separate set of table, so after execution we can analyse this information to find which particular line is taking more time

How to use DBMS_PROFILER?
    - We need to follow 4 steps exactly in same order
1. Environment setup
      - You need to prepare ur env to use DBMS_PROFILER, this is nothing but you need to create few predefined tables prescribed by Oracle to capture the profiler informations

2. Profiler Execution
     - First step is just one-time setup only, once env setup is done u need to execute the profiler, so the profiler execution is as per our requirement (ie) we can execute any number of times, for example we can execute a profiler execution on a setup with plsql code to capture its information

3. Analyze Profiler data
     After analyzing the informations you can tune ur particular code, again you can execute the profiler to check whether it has actually improved or not
    So for every profiler execution it collects some info in plsql tables then you need to analyze the data collector to identify where exactly the time is going 
    So 2nd and 3rd step is iterative process, you just need to keep running profiler execution and data analysis for each and every subsequent execution of your profiler

4. Optimize the PLSQL
      The optimization may be an SQL optimization or it may be PLSQL optimization 

1. Environment setup
      - We need to check whether ur user has the privilege to execute DBMS_PROFILER package or not, by default most of time when we create the user it will have default privilege to access DBMS_PROFILER package, in case if we not able to access this package then login as sys and grant privilege 

sql>conn sys as sysdba
password: sys

sql>grant dbms_profiler to scott;

    - Create profiler table in the schema where you are going to run the execution, for that we need to run a particular file called oracle/product/10/dbhome_1/rdbms/admin/proftab.sql which is present in oracle installation directory which creates 3 tables called plsql_profiler_data,plsql_profiler_units and plsql_profiler_runs
   This 3 tables hold the profiler info during ur profiler execution 

SQL> @C:\oraclexe\app\oracle\product\10.2.0\server\RDBMS\ADMIN\proftab.sql - run the sql script to create the tables

SQL> select table_name from user_tables where table_name like '%PROF%';  -- check 3 tables are created

2. Profiler Execution
      It is 3 step process like
    - Start the profiler so that from that particular point of time Oracle captures all line by line execution information into profiler table
      We need to invoke a procedure called "exec dbms_profiler.start_profiler()"
    - After starting the profiler, u need to execute all PLSQL code where u want to collect performance related informations 
    - After executing all your plsql block, u need to stop the profiler 
      We need to invoke a procedure called "exec dbms_profiler.stop_profiler()"

1. We create 3 procedures, when we invoke proc_a it will call proc_b and proc_b will internally call proc_c. So invoking proc_a is taking more time then we need to identify which particular stmt in these 3 procedures are taking more time then you need to stop executing

sql> create or replace procedure proc_c AS
        lv_avg_sal number;
     begin
        for i in 1..50 loop
           select avg(salary) into lv_avg_sal from employee;
        end loop;
     end;
/

sql>create or replace procedure proc_b as
        lv_date date;
    begin
        for i in 1..50 loop
            proc_c;
            select sysdate into lv_date from dual;
        end loop;
    end;
/

sql>create or replace procedure proc_a as 
       lv_count number;
    begin
       select count(*) into lv_count from user_tables,all_objects;
       for i in 1..50 loop
           proc_b;
       end loop;
end;
/

2. Now execute start_profiler and will start collecting the profiler informations of the plsql code 

SQL> exec dbms_profiler.start_profiler('MY_TEST_PERFORMANCE_RUN');

Now executing procedure proc_a, since there are like multiple loops we have included in each procedure it take some time 
SQL> exec proc_a;

Now execute stop_profiler procedure
SQL> exec dbms_profiler.stop_profiler();

3. Analyze profiler data 
        When a profiler get executed this captures the informations in 3 different tables called plsql_profiler_runs,plsql_profiler_data,plsql_profiler_units
    - plsql_profiler_runs will contain information about one row for each execution 
    - plsql_profiler_units captures the info abt what all the apis or what all the plsql units involved as part of the profiler units like procedures and functions etc
    - plsql_profiler_data will have the info about line by line details like how much time a particular line is taken in that particular unit and how many times the particular line is being is invoked 
    All 3 tables have common linkages like runid and unit_number, so using runid for every run there will be one runid generated using that we can join plsql_profiler_runs and plsql_profiler_units tables, same way we can join plsql_profiler_runs and plsql_profiler_data tables, using unit_number we can join plsql_profiler_data and plsql_profiler_units tables. So by joining these 3 tables we can get info about how much time a particular line is taken in particular program unit

SQL> select * from plsql_profiler_runs; -- will have info abt how much time taken for overall execution

SQL> select * from plsql_profiler_data; -- will have info abt what all the units involved like procedures, functions etc 

SQL> select * from plsql_profiler_units; -- will have how many number of times a particular line is being executed and how much total time the particular line has taken 

Now we join the table

sql>select plsql_profiler_runs.run_date,plsql_profiler_runs.run_comment,plsql_profiler_units.unit_type,plsql_profiler_units.unit_name,plsql_profiler_data.LINE#,plsql_profiler_data.total_occur,plsql_profiler_data.total_time,plsql_profiler_data.min_time,plsql_profiler_data.max_time,round(plsql_profiler_data.total_time/1000000000) total_time_in_sec,
trunc(((plsql_profiler_data.total_time)/(sum(plsql_profiler_data.total_time) over()))*100,2) pct_of_time_taken from
 plsql_profiler_data,plsql_profiler_runs,plsql_profiler_units
where plsql_profiler_data.total_time > 0
and plsql_profiler_data.runid=plsql_profiler_runs.runid
and plsql_profiler_units.unit_number=plsql_profiler_data.unit_number
and plsql_profiler_units.runid=plsql_profiler_runs.runid
order by
   plsql_profiler_data.total_time DESC;

    Here we can see line no 5 of proc_c takes 125000 times to execute, in this way we can identify which particular line is taking more time, so instead of browsing through the entire lines of code or instead of tuning all plsql code in ur procedure now u can just concentrate on only one line. Again u should concentrate on a line just because it is taking more time, the another thing we need to check is total occurences because sometimes total occurences will be very less whereas the time taken will be very high so those are all the potential lines to start with tuning
  If we want to delete info from profiler table then we need to follow in this order
>truncate  table plsql_profiler_data;
>delete from plsql_profiler_units;
>delete from plsql_profiler_runs;

4. Optimize the PLSQL
     - Implement the logic in SQL(instead of PLSQL) as far as possible
     - Use the inbuilt/analytical functions as mush as possible
     - Bulk collections - whenever we are working on a collections and if you are using traditional looping to load the data or insert the data instead we use bulk collection which will improve the performance
     - Wherever u want to store a huge amount of temporary info use global temporary tables instead of putting internal into a variable so that this might improve performance
     - Instead of writing multiple statements, merge all these stmts into a single stmt wherever is possible
     - use insert append hint to improve performance 
     - use lob variables only if needed  

PRAGMA AUTONOMOUS_TRANSACTION
   - By default Oracle dosent create a separate transaction for procedure, procedure will always part of main program transaction so what happens is commit or rollback command in procedure affects the transaction started in main prg
    For example we create a procedure which is updating the data and the update is rolledback, usually we wont rollback directly may be using some condition we will rollback (ie) if some condition is true then it commit or else it will rollback 
    After creating the procedure, the procedure is invoked from plsql block, so in calling prg we have update command and after update we are calling the procedure and then commit is executed
   So when u submit update or dml command from any plsql block, then oracle starts a separate transaction. So when u submit update command oracle starts a new transaction and after that we are calling procedure, now the control goes to procedure, in procedure also we call update command, but oracle dosent starts separate transaction for procedure because by default procedure is executed as a part of main prg transaction, so update command also have same transaction started in main prg.
     So when rollback command is executed it cancels the transaction started in main prg, so main prg and procedure updates both are cancelled, so rollback cmd in procedure affects the transaction started in main prg
    So my requirement is we want separate transaction for procedure so commit or rollback in procedure should affect only transaction started in procedure but should not affect transaction started in main prg, then we create procedure with pragma autonomous then separate transaction is created for procedure 

>create or replace procedure updateSal(e number)
is
 begin
    update employee set salary=salary+1000 where eid=e;
    rollback;
end;
/

>begin
   update employee set salary=salary+1000 where eid=2;
   updateSal(1);
   commit;
 end;
/

When we run plsql block it will cancel both transaction so it wont update both salary 
     
>create or replace procedure updateSal(e number)
is
PRAGMA AUTONOMOUS_TRANSACTION;
 begin
    update employee set salary=salary+1000 where eid=e;
    rollback;
end;
/

Now when we run it will update salary only in plsql block not in procedure since it creates a separate transaction


Triggers
    - Named PL/SQL blocks which are stored in the database, it is specialized stored programs which execute implicitly when a triggering event occurs which means we cannot call and execute them directly instead they only get triggered by events in the database 
    - This events can be anything like
        1. DML statement 
        2. DDL statement
These triggers are generally used by DBA for auditing purposes
        3. System event - you can create a trigger on a system event (ie) startup and shutdown of ur database 
        4. User events such as logoff or log on into ur database 

Types of triggers
1. DML triggers - these are the triggers which depend on DML stmt such as update,insert,delete and they get fired either before or after them 
2. DDL triggers - these are the triggers which are created over DDL stmt such as create or alter. We can monitor the behavior and force rules on ur DDL stmts.
   - Using DDL triggers you can track changes to the db (ie) when a schema object such as table, trigger,index or anything is created or altered or dropped

sql>show user;

1. Create a table which this trigger will store all info 
>create table schema_audit(ddl_date date,ddl_user varchar2(15),object_created varchar2(20),object_name varchar2(20),ddl_operation varchar2(20));

2. Create trigger
>create or replace trigger hr_audit_td
after DDL on schema
begin
  insert into schema_audit values(sysdate,sys_context('userenv','current_user'),ora_dict_obj_type,ora_dict_obj_name,ora_sysevent);
end;
/

sys_context('userenv','current_user') will return current user name. Next 3 attributes are oracle system event attributes which return some info regarding the events that fired the triggers
ora_dict_obj_type - return type of object on which DDL operation occured (ie) table
ora_dict_obj_name - return table name of object given by user
ora_sysevent - which ddl event or ddl stmt was executed such create or alter or truncate 

This trigger will fire after every DDL stmt executed on the system schema. If u want trigger to fire for only create and alter then we can create like
>create or replace trigger hr_audit_td
after create or alter on schema

3. Create dummy table to check whether it records this event into schema_audit table
>create table dummy(r number);

4. Check schema_audit table for audit entry
>select * from schema_audit 

5. Now we insert some values in dummy table and then truncate and check schema_audit table
>insert into dummy values(1);
>truncate table dummy;
>select * from schema_audit;


3. System/Database event triggers - used when some system event occurs such as db log on or log off or shutdown or startup
    - Used to monitor system event activities of either a specific user or whole database 
    - To create a trigger on db u must need "Administrative database trigger" system privileges

>create table hr_evnt_audit(event_type varchar2(20),logon_date date,logon_time varchar2(15),logof_date date,logof_time varchar2(15));

>create or replace trigger hr_logon_audit
after logon on schema
begin
   insert into hr_evnt_audit values(ora_sysevent,sysdate,to_char(sysdate,'hh24:mi:ss'),null,null);
commit;
end;
/

>disconnect from db, once agin connect with db

>select * from hr_event_audit;

4. Instead of trigger
      - Using Instead-of trigger you can control the default behavior of insert,update,delete and merge operation on views but not on tables 

Syntax: create [or replace] trigger trigger_name
        instead of operation
        on view_name
        for each row
        begin
           --stmt
        end;
/

>create table trainer(full_name varchar2(20));
>insert into trainer values('Ram');
>create table subject(subject_name varchar2(20));
>insert into subject values('oracle');

-Create a view to join both tables
  >create view v1 as select full_name,subject_name from trainer,subject;
   - This view is not updatable,
>insert into v1 values('Raj','Java'); --show error

- But using instead of trigger we can make non updatable view to updatable 

>create or replace trigger tr_io_insert
instead of insert on v1
for each row
begin
  insert into trainer(tname) values(:new.tname);
  insert into subject(sname) values(:new.sname);
end;
/

>insert into v1 values('Raj','Java'); -- now it will insert new values through views 

INSTEAD OF - UPDATE TRIGGER
>desc v1;

>update v1 set tname='Raj' where sname='Java'; -- show error as view contains multiple table

>create or replace trigger io_update
instead of UPDATE on v1
for each row
begin
  update trainer set tname=:new.tname where tname=:old.tname;
  update subject set sname=:new.sname where sname=:old.sname;
end;
/

>update v1 set full_name='Raj' where subject_name='Java'; - now it will update the data


5. Compound triggers - multi tasking triggers act as both statement as well as row level triggers when data is inserted, updated or deleted from table. 

CURRENT OF Clause
    - used in cursor
    - Suppose we are taking emp table with ename, salary column 
ename  sal
A      5000
B      4000
A      6000
B      5000
C      4000





Day 1
1. Create a type dept_type whose structure is given below: 
 Column name data type 
 Deptno number(2) 
 Dname varchar2(14) 
 Loc varchar2(13) 

2. Create a table emp which will hold a reference to the above created table and also have a structure as given below: 
 Column name data type 
 Empno number(4) 
 Job varchar2(10) 
 Mgr number(4) 
 Hiredate date 
 Sal number(7,2) 
 Comm number(7,2) 
 Dept ref dept_type 
 
3. Write PL/SQL block to insert department details into Department table until the user wishes to  stop.

4. Write PL/SQL block to increase the salary by 10% if the salary is > 2500 and > 3000. 

5. Write PL/SQL block to display the names of those employees getting salary > 3000. 

6. Write a PL/SQL code to retrieve the employee name, join_date, and
designation from employee database of an employee whose number is
input by the user. 

SQL> select * from employee; 
EMP_NO EMPLOYEE_NAME STREET CITY 
1 rajesh first cross gulbarga 
2 paramesh second cross bidar 
3 pushpa ghandhi road banglore 
4 vijaya shivaji nagar manglore 
5 keerthi anand sagar street bijapur 

7. Write a PL/SQL procedure to find the number of students ranging from 10070%, 
69-60%, 59-50% & below 49% in each course from the student_course
table given by the procedure as parameter. 

SQL> select * from student_enrollment; 
ROLL_NO COURSE COURSE_COD SEM TOTAL_MARKS PERCENTAGE 
111 cs 1001 1 300 50 
112 cs 1001 1 400 66 
113 is 1002 1 465 77 
114 is 1002 1 585 97 

Day 2 - Function and Package
1. Create a store function that accepts 2 numbers and returns the addition
of passed values. Also write the code to call your function. 

2. Write a PL/SQL function that accepts department number and returns the
total salary of the department. Also write a function to call the
function. 

SQL> select * from works; 
EMP_NO COMPANY_NAME JOINING_D DESIGNATION SALARY DEPTNO 
1 abc 23-NOV-00 project lead 40000 1 
2 abc 25-DEC-10 software engg 20000 2 
3 abc 15-JAN-11 software engg 1900 1 
4 abc 19-JAN-11 software engg 19000 2 
5 abc 06-FEB-11 software engg 18000 1 


3. Accept year as parameter and write a Function to return the total net salary spent for a given year.

SQL> select * from works; 
EMP_NO COMPANY_NAME JOINING_D DESIGNATION SALARY DEPTNO 
1 abc 23-NOV-00 project lead 40000 1 
2 abc 25-DEC-10 software engg 20000 2 
3 abc 15-JAN-11 software engg 1900 1 
4 abc 19-JAN-11 software engg 19000 2 
5 abc 06-FEB-11 software engg 18000 1 

4. Create a package that contains overloaded functions for
a. Adding five integers
b. Subtracting two integers
c. Multiplying three integers


Cursors
1. Write a PL/SQL code to calculate the total salary of first n records of
emp table. The value of n is passed to cursor as parameter. 


SQL> select * from employee_salary; 
EMP_NO BASIC HRA DA TOTAL_DEDUCTION NET_SALARY GROSS_SALARY 
2 15000 4000 1000 5000 15000 20000 
1 31000 8000 1000 5000 35000 40000 
3 14000 4000 1000 5000 15000 19000 
4 14000 4000 1000 5000 15000 19000 
5 13000 4000 1000 5000 15000 18000 
6 12000 3000 800 4000 11800 15800 


2. Create a PL/SQL block that determines the top n salaries of the
employees.
a. Execute the script given below to create a new table, top_salaries, for storing the salaries of the employees.
CREATE TABLE top_salaries(salary NUMBER(8,2));
b. Accept a number n from the user where n represents the number of top n earners from the employees table. For example, to view the top five salaries, enter 5.
Pass the value to the PL/SQL block as an input from user
c. In the declarative section, declare two variables: num of type NUMBER to accept
the substitution variable p_num, sal of type employees.salary. Declare a cursor, emp_cursor, that retrieves the salaries of employees in descending order. Remember that the salaries should not be duplicated.
d. In the executable section, open the loop and fetch top n salaries and insert them into top_salaries table. You can use a simple loop to operate on the data. Also, try and use %ROWCOUNT and %FOUND attributes for the exit condition.
e. After inserting into the top_salaries table, display the rows with a SELECT statement.

3. Write a program in PL/SQL to display a cursor based detail information of employees from employees table

4. Write PL/SQL block to increase the salary by 15 % for all employees in employee table.

Exception
1. Write an anonyms block which count total customers into a variable who has bought more than 10,000 Rs. of goods so far. If the count is more than 100 it should display ‘This is a message from body” else it should go to exception and from there is should display ‘This is a message from Exception block.”

2. Write PL/SQL block to handle the exception dup_val_on_index by inserting a duplicate row in the works table.

3. Write PL/SQL block with a user defined exception and raise the exception, and handle the exception. 


Trigger
1. Create a row level trigger for the customers table that would fire for INSERT or UPDATE or DELETE operations performed on the CUSTOMERS table. This trigger will display the salary difference between the old values and new values:
 CUSTOMERS table:
ID NAME AGE ADDRESS SALARY
1 Alive 24 Khammam 2000
2 Bob 27 Kadappa 3000
3 Catri 25 Guntur 4000
4 Dena 28 Hyderabad 5000
5 Eeshwar 27 Kurnool 6000
6 Farooq 28 Nellur 7000

2.2. Creation of insert trigger, delete trigger, update trigger practice triggers using the passenger database.
Passenger( Passport_ id INTEGER PRIMARY KEY, Name VARCHAR (50) Not NULL,
Age Integer Not NULL, Sex Char, Address VARCHAR (50) Not NULL);
a. Write a Insert Trigger to check the Passport_id is exactly six digits or not.
b. Write a trigger on passenger to display messages „1 Record is inserted‟, „1 record is deleted‟, „1
record is updated‟ when insertion, deletion and updation are done on passenger respectively.

3. Convert employee name into uppercase whenever an employee record is inserted or updated. Trigger
to fire before the insert or update.
4. Trigger before deleting a record from emp table. Trigger will insert the row to be deleted into table
called delete _emp and also record user who has deleted the record and date and time of delete




















