%{
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include "propertylist.h"
#define YYERROR_VERBOSE

extern int yylineno;
    
int k;
char identifier[20], ex[100], *temp[20];
int i, j, count, length[20];
char a[15];
char t;
Element *ele;  //符号表指针
Element *ele1;
SymbalList *temp1;
SymbalList table;
int ptrStack = 0;
SymbalList *s_stack[1024];  //多个符号表组成的栈结构

int check(char * s);
Element * find(char * s);
void yyerror(const char *s);
%}
%locations

%union
{
    //非终结符
    struct  a{
        char *ccode;  //规约后代码
        int len;      //长度
    } NT_info;

    //标识符
    struct  b{
        char ccode[20]; //规约后代码
        int len;//长度
    } Symbol;

    //数组
    struct array_type
    {
        int isarray; //是否是数组
        int low;     //下界
        int high;    //上界
        int length;  //长度
        My_Type Type; //类型
        char *ccode;//规约后代码
        int len;   //长度
    } array_type;

    //数字
    struct digit {
        int num;  //值
        char ccode[20]; //规约后代码
        int len;    //长度
    } digit_attr;

    //变量列表
    struct id_list {
        int total;  //总数
        char id_name[20][10]; //每个变量名称

        char *ccode;  //规约后代码
        int len;    //长度
    } id_list;

    //列表
    struct list {
        int total;  //总数
        My_Type para_type[20]; //类型
        char *ccode;  //规约后代码
        int len;    //长度
    } list;

    //表达式
    struct exp {
        int isfunction; //是否为函数
        My_Type Type; //类型
        int num;        //值
        char *ccode;  //规约后代码
        int len;    //长度
    } exp;
}

%token <Symbol> ARRAY BEGAN BOOLEAN DO ELSE END FALSE FUNCTION IF INTEGER NOT OF PROCEDURE PROGRAM READ REAL RECORD THEN TRUE VAR WHILE WRITE  ID NUM RELOP ADDOP MULOP ASSIGNOP
%token <digit_attr> DIGITS

 /*以下符号类型为非终结符类型*/
%type <NT_info> program   program_head  program_body      declarations    declaration subprogram_declarations  subprogram_declaration  subprogram_head   compound_statement optional_statements    statement_list      statement           procedure_statement
%type <array_type> type standard_type  //数组类型
%type <id_list> identifier_list   //变量列表
%type <list> parameter_list expression_list arguments  //列表
%type <exp> variable expression simple_expression term factor  //表达式

%%
program : program_head program_body '.' //规约成program,直接将代码格式化打印出来
       {
          $$.ccode = (char *)malloc($1.len + $2.len + 2);      //分配空间，大小为$1.len + $2.len + 1,1为‘\n’
          $$.len = sprintf($$.ccode,"%s\n%s",$1.ccode,$2.ccode);     //sprintf函数：把格式化的数据写入某个字符串缓冲区，返回值为长度
                                                                  //此处将$1.ccode,\n,$2.ccode三部分格式化并写入$$.ccode，返回最终字符串长度
          fprintf(stdout,  "%s", $$.ccode); //输出
       }
       | program_head program_body error //若不完整，缺少'.',则继续规约，并打印错误信息。
       {
          $$.ccode = (char *)malloc($1.len + $2.len + 2);
          $$.len = sprintf($$.ccode,"%s\n%s",$1.ccode,$2.ccode);
          fprintf(stdout,  "%s", $$.ccode);
          yyerror("程序末尾缺少 '.'"); //错误报告函数
          yyerrok; //错误恢复宏定义
       }
       ;

program_head : PROGRAM ID '(' identifier_list ')' ';'   //规约出程序头，将所需头文件之类的翻译出来，并建立主表入栈
       {
          ele = (Element*)malloc(sizeof(Element)); //符号表指针分配一个表项
          strcpy(ele->name, $2.ccode);  //写入变量名称
          ele->type = PROGRAM_T; //赋给类型
          //ele->location=$2.location;
          SymPush(&table, ele);//将主程序名称写入符号表

            s_stack[ptrStack++] = &table;//主表入栈，第一层，嵌套检查

            $$.ccode = (char *)malloc(42);
            $$.len = sprintf($$.ccode,"#include <iostream>\nusing namespace std;\n"); //写入c++程序头
         }
       ;

program_body : declarations subprogram_declarations compound_statement  //程序主体部分，分别为全局变量，子函数体，然后是主函数main()
         {
          $$.ccode = (char *)malloc($1.len + $2.len + $3.len + 80);
          $$.len = sprintf($$.ccode,"%s\n%s\nint main()\n{\n\t%s\n\treturn(0);\n}",$1.ccode,$2.ccode,$3.ccode);  //翻译相应语句main等
          //fprintf(stderr, "body ok\n");
         }
         ;

identifier_list : identifier_list ',' ID  //规约成变量列表，total记录变量个数，并将ID串起来，用‘，’隔开
          {
              $$.total=$1.total+1; //总数+1
              for(k=0;k<$1.total;k++)
                strcpy($$.id_name[k],$1.id_name[k]);//把$1变量名赋给($$
                strcpy($$.id_name[k],$3.ccode);   //增加一个变量，即ID
              $$.ccode = (char *)malloc($1.len + $3.len + 2); //分配内存 +1为‘，’
              $$.len = sprintf($$.ccode,"%s,%s",$1.ccode,$3.ccode); //格式化代码写入$$，包含','
          //      fprintf(stderr, "ID=%s\n", $3.ccode);
            //    fprintf(stderr, "list=%s\n", $$.ccode);
                
          }
        | ID
          {
            $$.total=1;//个数为1
            strcpy($$.id_name[0],$1.ccode);//将ID赋值给$$

              $$.ccode = (char *)malloc($1.len + 1);//分配空间
              $$.len = sprintf($$.ccode,"%s",$1.ccode); //格式化代码写入$$
              //  fprintf(stderr, "ID=%s\n", $1.ccode);
            }
//           | DIGITS ID error ' '//若标示符声明有误
//           {
//          $$.ccode = (char *)malloc($1.len + 1);
//            $$.len = sprintf($$.ccode,"%s",$1.ccode); //提取ID赋给$$，即identifier_list
//            yyerror("标示符声明不合法");//写入错误报告函数
//            yyerrok();//错误恢复宏定义
//           }
        ;

declarations : VAR declaration ';' //规约成所有声明的统一
         {
                  $$.ccode = (char *)malloc($2.len + 2); //分配空间,1为‘;’
            $$.len = sprintf($$.ccode,"%s;",$2.ccode);  //格式化代码写入$$
         }
       |
         {
          $$.ccode = (char *)malloc(2);
           $$.len = sprintf($$.ccode," ");
         }
       ;

declaration : declaration ';' identifier_list ':' type  //声明较多，将声明合并规约
        {
            for(k=0; k<$3.total; k++)       //对identifier_list进行重复检测，无重复则压入符号表
            {
              if(find($3.id_name[k]) == NULL)     //因为此时头部已规约出来，主表已存在用find函数 为NULL，说明未定义
              {
                ele=(Element*)malloc(sizeof(Element));  //符号表指针分配一个表项
                strcpy(ele->name,$3.id_name[k]); //赋名称
                //ele->location=$1.location;
                if($5.isarray == 0) //若不是数组
                {
                  ele->type=$5.Type;//赋类型
                }
                else
                {
                  ele->type=ARRAY_T; //若是数组，类型标示数组
                  ele->arr_fun.arr.arr_type=$5.Type; //数组内元素类型
                  (ele->arr_fun).arr.first=$5.low;//赋下界
                  (ele->arr_fun).arr.last=$5.high;//赋上界

                }
                SymPush(s_stack[ptrStack-1], ele);//压栈
              }
              else
              {
                yyerror("变量重复定义！声明处");
                yyerrok;
              }
            }

            if($5.isarray == 0)       //根据类型，若不是数组，将该声明和前面规约出来的声明串合并。
            {
              $$.ccode = (char *)malloc($1.len + $3.len + $5.len + 7); //分配
                $$.len = sprintf($$.ccode,"%s;\n%s %s",$1.ccode,$5.ccode,$3.ccode);//  //格式化代码写入$$
            }
            else             //根据类型，若是数组，将该声明和前面规约出来的声明串合并。
            {
                //$$.len = sprintf($$.ccode,"%d",$5.length);  cout<<$5.length;
                      $$.ccode = (char *)malloc($1.len + $3.len + $5.len + $$.len + 20);
                $$.len = sprintf($$.ccode,"%s;\n%s %s[%d]",$1.ccode,$5.ccode,$3.ccode,$5.length);   //增加声明数组大小[%d]
            }
        }
      | identifier_list ':' type       //单一声明
        {
            for(k=0;k<$1.total;k++)   //对identifier_list进行重复检测，无重复则压入符号表
            {
              if(find($1.id_name[k])==NULL) //为NULL，说明未定义
              {
                ele=(Element*)malloc(sizeof(Element));//符号表指针分配一个表项
                strcpy(ele->name,$1.id_name[k]);//赋名称
                //ele->location=$1.location;
                if($3.isarray==0) //若不是数组
                {
                  ele->type=$3.Type;//赋类型
                }
                else  //若是数组，类型标示数组
                {
                  ele->type=ARRAY_T;   //若是数组，类型标示数组
                  (ele->arr_fun).arr.arr_type=$3.Type; // 数组内元素类型
                  (ele->arr_fun).arr.first=$3.low;//赋下界
                  (ele->arr_fun).arr.last=$3.high;//赋上界

                }
                SymPush(s_stack[ptrStack-1], ele);//压栈

              }
              else
              {
                yyerror("变量重复定义！单种声明处");
                yyerrok;
              }
            }

            if($3.isarray == 0)  //根据类型，若不是数组，将该声明和前面规约出来的声明串合并。
          {
            $$.ccode = (char *)malloc($1.len + $3.len + 5);
            $$.len = sprintf($$.ccode," %s %s",$3.ccode,$1.ccode);
          }
          else //根据类型，若是数组，将该声明和前面规约出来的声明串合并，增加数组大小的声明
          {
            $$.ccode = (char *)malloc($1.len + $3.len  + 10);
            $$.len = sprintf($$.ccode,"%s %s[%d]",$3.ccode,$1.ccode,$3.length);  //增加声明数组大小[%d]
          }
        }
      ;

type    : standard_type   //规约成类型
        {
            $$.isarray=$1.isarray;
            $$.Type=$1.Type;
            $$.ccode = (char *)malloc($1.len+1);
            $$.len = sprintf($$.ccode,"%s",$1.ccode);
        }
      | ARRAY '['DIGITS '.''.' DIGITS']' OF standard_type
        {
            
            $$.isarray=1;
            $$.low=$3.num;
            $$.high=$6.num;
            
            if ($$.low > $$.high)  // to correct
            {
                int temp = $$.low;
                $$.low = $$.high;
                $$.high = temp;
            } 
            $$.length=$$.high-$$.low+1;

            $$.Type=$9.Type;

            $$.ccode = (char *)malloc($9.len + 1);
            $$.len = sprintf($$.ccode,"%s",$9.ccode);
            if ($3.num>$6.num) yyerror(" the index error.");
        }
      | RECORD declaration END
        {
            $$.isarray=0;
            $$.Type=RECORD_T;
            $$.ccode = (char *)malloc($2.len + 9);
            $$.len = sprintf($$.ccode,"struct{%s}",$2.ccode);
        }
      ;

standard_type : INTEGER       //三种类型规约成标准类型
        {
            $$.isarray=0;
            $$.Type=INT_T;

            $$.ccode = (char *)malloc(4);
              $$.len = sprintf($$.ccode,"int");
          }
        | REAL
          {
              $$.isarray=0;
              $$.Type=REAL_T;

              $$.ccode = (char *)malloc(6);
              $$.len = sprintf($$.ccode,"float");
          }
        | BOOLEAN
          {
              $$.isarray=0;
              $$.Type=BOOL_T;

              $$.ccode = (char *)malloc(5);
              $$.len = sprintf($$.ccode,"bool");
          }
        ;

subprogram_declarations : subprogram_declarations subprogram_declaration ';'//所有的子程序规约出来
              {
                $$.ccode = (char *)malloc($1.len + $2.len + 2);
                $$.len = sprintf($$.ccode,"%s\n%s",$1.ccode,$2.ccode);
              }
            |
              {
                $$.ccode = (char *)malloc(2);
                $$.len = sprintf($$.ccode," ");
              }
            ;

subprogram_declaration : subprogram_head declarations compound_statement //子程序头和子程序体声明和子程序体规约起来，
             {                                               //即完成一个子程序，所有应该退出子程序，将子表删除，即重定位操作
                //in_function=0;
                $$.ccode = (char *)malloc($1.len + $2.len + $3.len + 17);
                $$.len = sprintf($$.ccode,"%s\n{\n%s\n%s\n}\n",$1.ccode,$2.ccode,$3.ccode);
                temp1 = s_stack[ptrStack-1];
                 --ptrStack;
                 free(temp1);
             }
             ;

subprogram_head : FUNCTION ID arguments ':' standard_type ';'//规约成子函数或过程的头部,即判断出进入子程序体，新建哈希子表，并将指针入栈
          {
            ele=(Element*)malloc(sizeof(Element));
            (ele->arr_fun).fun.sub_list=temp1;
            s_stack[ptrStack++] = ele->arr_fun.fun.sub_list;

            strcpy(ele->name,$2.ccode);
            ele->type=FUNCTION_T;
            (ele->arr_fun).fun.para_num=$3.total;
            (ele->arr_fun).fun.return_type=$5.Type;
            for(k=0;k<$3.total;k++)       //对形参类型进行存储
            {
              ele->arr_fun.fun.para_type[k]=$3.para_type[k];
            }

            SymPush(s_stack[ptrStack-2], ele);//将表项放入对应子表

              $$.ccode = (char *)malloc($2.len + $3.len + $5.len + 2);
                $$.len = sprintf($$.ccode,"%s %s%s",$5.ccode,$2.ccode,$3.ccode);
            }
        | FUNCTION ID arguments error
          {
            $$.ccode = (char *)malloc($2.len + $3.len  + 2);
                $$.len = sprintf($$.ccode,"%s%s",$2.ccode,$3.ccode);
              yyerror("函数无返回值类型");

          }
        | PROCEDURE ID arguments ';'//过程头部规约
          {
            ele=(Element*)malloc(sizeof(Element));
            (ele->arr_fun).fun.sub_list=temp1;
            s_stack[ptrStack++] = ele->arr_fun.fun.sub_list;

              strcpy(ele->name,$2.ccode);
            ele->type=PROCEDURE_T;
            (ele->arr_fun).fun.para_num=$3.total;

            for(k=0;k<$3.total;k++)       //对形参类型进行存储
            {
              ele->arr_fun.fun.para_type[k]=$3.para_type[k];
            }

            SymPush(s_stack[ptrStack-2], ele);


              $$.ccode = (char *)malloc($2.len + $3.len + 6);
                $$.len = sprintf($$.ccode,"void %s%s",$2.ccode,$3.ccode);
            }
        ;

arguments : '('parameter_list')'//参数列表
      {
          $$.total=$2.total;
          for(k=0;k<$2.total;k++)
              $$.para_type[k]=$2.para_type[k];

            $$.ccode = (char *)malloc($2.len + 3);
            $$.len = sprintf($$.ccode,"(%s)",$2.ccode); //加了个（）
      }
      |
        {
            $$.ccode = (char *)malloc(3);
            $$.len = sprintf($$.ccode,"()");  //没有参数直接翻译成（）
      }
      ;

parameter_list : parameter_list ';' identifier_list ':' type  //形成参数列表(参数列表;id列表:类型)->(参数列表,类型 id)
         {
            $$.total=$1.total+$3.total;//统计参数个数

          for(k=0;k<$1.total;k++)
                $$.para_type[k]=$1.para_type[k];

            for(k=0;k<$3.total;k++)
            {
                if(check($3.id_name[k])==0)//查看参数是否在对应的子表中重复定义，但此时子程序的函数头还为规约出来，所以
                {             //必须建立一个临时子表，来存放对应参数符号，等函数头规约出来，再压入栈中

                  $$.para_type[k+$1.total]=$5.Type;
                  ele=(Element*)malloc(sizeof(Element));
                  strcpy(ele->name,$3.id_name[k]);

                  if($5.isarray==0)
                  {
                    ele->type=$5.Type;
                  }
                  else
                  {
                    ele->type=ARRAY_T;
                    (ele->arr_fun).arr.first=$5.low;
                    (ele->arr_fun).arr.last=$5.high;
                    (ele->arr_fun).arr.arr_type=$5.Type;
                  }
                  SymPush(temp1, ele);
                }
                else
                {
                  yyerror("变量重复定义！形参声明处");
                  yyerrok;
                }
            }

            if($5.isarray == 0)  //对于数组翻译方法略不同
          {
                      $$.ccode = (char *)malloc($1.len + $3.len + $5.len + 3);
                $$.len = sprintf($$.ccode,"%s,%s %s",$1.ccode,$5.ccode,$3.ccode);
              }
              else
              {
                $$.len = sprintf($$.ccode,"%d",$5.length);
                      $$.ccode = (char *)malloc($1.len + $3.len + $5.len + $$.len + 5);
                $$.len = sprintf($$.ccode,"%s,%s %s[%d]",$1.ccode,$5.ccode,$3.ccode,$5.length);
              }

         }

               | identifier_list ':' type          //最后一个参数
                 {
                  temp1 =(SymbalList*)malloc(sizeof(SymbalList));
                  temp1->m_size = 1024;
                  temp1->m_num_of_pro =0;
                  $$.total=$1.total;
                  for(k=0;k<$1.total;k++)
            {
              $$.para_type[k]=$3.Type;
              if(check($1.id_name[k])==0)
              {
                ele=(Element*)malloc(sizeof(Element));
                strcpy(ele->name,$1.id_name[k]);

                if($3.isarray==0)
                {
                  ele->type=$3.Type;
                }
                else
                {
                  ele->type=ARRAY_T;
                  (ele->arr_fun).arr.first=$3.low;
                  (ele->arr_fun).arr.last=$3.high;
                  (ele->arr_fun).arr.arr_type=$3.Type;
                }
                SymPush(temp1, ele);

              }
              else
              {
                yyerror("变量重复定义！单种类型形参处");
                yyerrok;
              }
            }


            if($3.isarray == 0)
            {
                $$.ccode = (char *)malloc($1.len + $3.len + 40);
            	$$.len = sprintf($$.ccode,"%s ",$3.ccode);
            	int i = 0;
            	for(;i<$1.len;i++){
            		if($1.ccode[i]!=','){
            			strncat($$.ccode,&$1.ccode[i],1);
            			$$.len++;
            		}
            		else{
            			strcat($$.ccode,",");
            			strcat($$.ccode,$3.ccode);
            			strcat($$.ccode," ");
            			$$.len+=($3.len+2);
            		}
            	}
            }
            else
            {
                $$.len = sprintf($$.ccode,"%d",$3.length);
                      $$.ccode = (char *)malloc($1.len + $3.len + $$.len + 4);
                $$.len = sprintf($$.ccode,"%s %s[%d]",$3.ccode,$1.ccode,$3.length);
            }
         }
               ;

compound_statement : BEGAN optional_statements END  //复合语句，表明程序主体，中间为可选的表达语句
           {
            $$.ccode = (char *)malloc($2.len+10);
            $$.len = sprintf($$.ccode,"\n%s\n",$2.ccode);
           }
           ;

optional_statements : statement_list  //可由一堆表达语句构成
                      {
                         $$.ccode = (char *)malloc($1.len + 1);
                   $$.len = sprintf($$.ccode,"%s",$1.ccode);
                }
          |
            {
                         $$.ccode = (char *)malloc(2);
                   $$.len = sprintf($$.ccode," ");
                }
          ;

statement_list : statement_list ';' statement  //表达语句以‘；’为间隔
         {
                    $$.ccode = (char *)malloc($1.len + $3.len + 5);
              $$.len = sprintf($$.ccode,"%s\n\t%s",$1.ccode,$3.ccode);
           }
         | statement
           {
                    $$.ccode = (char *)malloc($1.len+4);
              $$.len = sprintf($$.ccode,"\t%s",$1.ccode);
           }
         ;

statement : variable ASSIGNOP expression  //赋值语句
      {
        if($1.Type==$3.Type)//若类型相等
        {
             if($1.isfunction == 0)  //非函数或过程体，可成功赋值
             {
             $$.ccode = (char *)malloc($1.len + $3.len + 5);
             $$.len = sprintf($$.ccode,"%s = %s;",$1.ccode,$3.ccode);
             }
             else if($1.isfunction == 1)  //是过程体的话，expression为返回值
             {
             $$.ccode = (char *)malloc($3.len + 9);
             $$.len = sprintf($$.ccode,"return %s;",$3.ccode);
               }
          }
          else if($1.Type==REAL_T||$3.Type==REAL_T)//若类型不一致，由于规约到factor时，限制只能三种类型或函数，若是无法赋值的数组是规约不上来的
          {                   //所以进行强制类型转换，转换成最大的REAL
            $1.Type=REAL_T;
            $3.Type=REAL_T;
            if($1.isfunction == 0)
             {
             $$.ccode = (char *)malloc($1.len + $3.len + 5);
             $$.len = sprintf($$.ccode,"%s = %s;",$1.ccode,$3.ccode);
             }
             else if($1.isfunction == 1)
             {
             $$.ccode = (char *)malloc($3.len + 9);
             $$.len = sprintf($$.ccode,"return %s;",$3.ccode);
               }
          }
          else
          {
            $$.ccode = (char *)malloc($1.len + $3.len + 5);
            $$.len = sprintf($$.ccode,"%s = %s;",$1.ccode,$3.ccode);
            yyerror("赋值号两边类型不符合，而且该类型不能进行强制转化");
            yyerrok;
        }
      }
      | procedure_statement
        {
               $$.ccode = (char *)malloc($1.len + 2);
         $$.len = sprintf($$.ccode,"%s;",$1.ccode);
      }
      | compound_statement
        {
               $$.ccode = (char *)malloc($1.len + 1);
         $$.len = sprintf($$.ccode,"%s",$1.ccode);
      }
      | IF expression THEN statement ELSE statement//IF里面的判断类型只能是布尔型或整型
        {
          if($2.Type==BOOL_T || $2.Type==INT_T)
          {
                  $$.ccode = (char *)malloc($2.len + $4.len + $6.len +40);
            $$.len = sprintf($$.ccode,"if(%s)\n\t{\n\t\t%s\n\t}\n\telse\n\t{\n\t\t%s\n\t}\n",$2.ccode,$4.ccode,$6.ccode);
        }
          else
          {
          $$.ccode = (char *)malloc($2.len + $4.len + $6.len +40);
            $$.len = sprintf($$.ccode,"if(%s)\n\t{\n\t\t%s\n\t}\n\telse\n\t{\n\t\t%s\n\t}\n",$2.ccode,$4.ccode,$6.ccode);
            yyerror("判别式类型不符");
            yyerrok;
          }
        }
      | WHILE expression DO statement//WHILE里面的判断类型只能是布尔型或整型
        {
          if($2.Type==BOOL_T || $2.Type==INT_T)
          {
                  $$.ccode = (char *)malloc($2.len + $4.len +19);
            $$.len = sprintf($$.ccode,"while(%s)\n\t{\t\t%s\n\t}",$2.ccode,$4.ccode);
        }
          else
          {
          $$.ccode = (char *)malloc($2.len + $4.len +19);
            $$.len = sprintf($$.ccode,"while(%s)\n\t{\t\t%s\n\t}",$2.ccode,$4.ccode);
            yyerror("判别式类型不符");
            yyerrok;
          }
        }

      | READ '('identifier_list')'
        {
        int tt=$3.len;
        char n[20];

           count=0;
           j=0;

          strcpy(n,$3.ccode);
        //  fprintf(stderr, "n=%s\n", n);
           while(count<$3.len)
           {
          for(i=0;(count<$3.len) && ($3.ccode[count]!=',');i++,count++)
            identifier[i]=*($3.ccode+count);
          identifier[i]='\0';
      //    fprintf(stderr, "identifier=%s\n", identifier);
          count++;
          temp[j]=(char *)malloc(i+15);
          length[j]=sprintf(temp[j],"cin>>%s;",identifier);
  //        fprintf(stderr, "length=%d\n", length[j]);
          j++;
        }


        $$.ccode = (char *)malloc(5000);
        $$.len = sprintf($$.ccode,"%.*s",length[0],temp[0]);
    //    fprintf(stderr, "temp[0]=%s\n", temp[0]);
        for(i=1;i<j;i++) {
           //fprintf(stderr, "$$.ccode=%s\ntemp[%d]=%s\n", $$.ccode, i, temp[i]); 
           $$.len = sprintf($$.ccode,"%.*s\n%.*s",$$.len,$$.ccode,length[i],temp[i]);
           }
//           fprintf(stderr, "$$.ccode=%s\n", $$.ccode);
        }

      | WRITE '('expression_list')'
        {
           count=0;
           j=0;
           while(count<$3.len)
           {
          for(i=0;(count<$3.len) && ($3.ccode[count]!=')');i++,count++)
            ex[i]=$3.ccode[count];
          count++;
          for(k=0;ex[k]!='(' && k<i;k++)
             a[k]=ex[k];
          if(k<i)
          {
              ex[i]=')';
            i++;
          }

          ex[i]='\0';
          k=0;

          temp[j]=(char *)malloc(i+16);
          length[j]=sprintf(temp[j],"cout<<%s<<endl;",ex);
          j++;
        }

        $$.ccode = (char *)malloc(5000);
        $$.len = sprintf($$.ccode,"%.*s",length[0],temp[0]);
        for(;i<j;i++)
           $$.len = sprintf($$.ccode,"%.*s\n%.*s",$$.len,$$.ccode,length[i],temp[i]);
        }
      ;

variable : ID   //规约成变量,根据变量类型，将其属性存入variable
       {
        ele1=find($1.ccode);
        if(ele1!=NULL)
        {
          if(ele1->type==INT_T||ele1->type==REAL_T||ele1->type==BOOL_T)
          {
            $$.Type=ele1->type;
            $$.isfunction=0;
            $$.ccode=(char *)malloc($1.len + 1);
              $$.len = sprintf($$.ccode,"%s",$1.ccode);
          }
          else if(ele1->type==FUNCTION_T && ele1->arr_fun.fun.return_type!=VOID)
          {
              $$.Type=ele1->arr_fun.fun.return_type;
                $$.isfunction=1;

                $$.ccode = (char *)malloc($1.len + 1);
                $$.len = sprintf($$.ccode,"%s",$1.ccode);
          }
          else
          {
              $$.ccode = (char *)malloc($1.len + 1);
                $$.len = sprintf($$.ccode,"%s",$1.ccode);
                yyerror("左值类型不符");
                yyerrok;
            }
        }
        else
        {
            $$.ccode = (char *)malloc($1.len + 1);
              $$.len = sprintf($$.ccode,"%s",$1.ccode);
              yyerror("变量未定义");
              yyerrok;
          }
      }
     | ID '['expression']'
       {
      ele1=find($1.ccode);
      if(ele1!=NULL) //若该数组存在，则不用检查expression,直接将expression翻译过去。因为在运行前，是无法判断expression的值的，除非是个常数，这里没进行处理
      {
        if(ele1->type==ARRAY_T&&$3.Type==INT_T)
        {
          int mylow = ele1->arr_fun.arr.first;
          $$.Type=ele1->arr_fun.arr.arr_type;
          $$.isfunction=0;
          $$.ccode = (char *)malloc($1.len + $3.len + 20);
          $$.len = sprintf($$.ccode,"%s[%s-%d]",$1.ccode,$3.ccode,mylow);
        }
      }

        else
        {
          $$.ccode = (char *)malloc($1.len + $3.len + 10);
          $$.len = sprintf($$.ccode,"%s[%s]",$1.ccode,$3.ccode);
          yyerror("变量未定义");
         yyerrok;
        }
       }
     ;

procedure_statement : ID             //过程声明，不含参数的过程
           {
            if((ele1=find($1.ccode))!=NULL)
            {
                  if(ele1->type==PROCEDURE_T && ele1->arr_fun.fun.para_num==0)
                  {
                  $$.ccode = (char *)malloc($1.len + 1);
                  $$.len = sprintf($$.ccode,"%s",$1.ccode);
                  }
                  else if(ele1->arr_fun.fun.para_num!=0)
                  {
                    $$.ccode = (char *)malloc($1.len + 1);
                  $$.len = sprintf($$.ccode,"%s",$1.ccode);
                    yyerror("过程调用参数个数不匹配");
                    yyerrok;
                  }
                  else
                  {
                    $$.ccode = (char *)malloc($1.len + 1);
                  $$.len = sprintf($$.ccode,"%s",$1.ccode);
                    yyerror("过程调用不合法");
                    yyerrok;
                  }
            }

              else
              {
                $$.ccode = (char *)malloc($1.len + 1);
              $$.len = sprintf($$.ccode,"%s",$1.ccode);
                yyerror("变量未定义");
                yyerrok;
              }
          }

           | ID '(' expression_list ')'  //过程声明，含参数的过程
           {
            ele1=find($1.ccode);
            if(ele1!=NULL)
            {
                if(ele1->type==PROCEDURE_T &&ele1->arr_fun.fun.para_num==$3.total)
                {
                  for(k=0;k<$3.total && (ele1->arr_fun.fun.para_type[k]==$3.para_type[k]); k++);//参数类型检查
                  if(k==$3.total)
                  {
                    $$.ccode = (char *)malloc($1.len + $3.len + 12);
                    $$.len = sprintf($$.ccode,"%s(%s)",$1.ccode,$3.ccode);
                      }
                  else
                  {
                    $$.ccode = (char *)malloc($1.len + $3.len + 12);
                    $$.len = sprintf($$.ccode,"%s(%s)",$1.ccode,$3.ccode);
                    yyerror("参数列表与定义时的不匹配");
                    yyerrok;
                  }
                }
                else
                {
                  $$.ccode = (char *)malloc($1.len + $3.len + 12);
                  $$.len = sprintf($$.ccode,"%s(%s)",$1.ccode,$3.ccode);
                  yyerror("参数列表与定义时的不匹配");
                  yyerrok;
                }
            }
            else
            {
              $$.ccode = (char *)malloc($1.len + $3.len + 12);
              $$.len = sprintf($$.ccode,"%s(%s)",$1.ccode,$3.ccode);
                yyerror("变量未定义");
                yyerrok;
              }
           }
          ;

expression_list : expression_list ',' expression//参数列表,将参数类型存放到expression_list里
          {
              $$.total=$1.total+1;
              for(k=0;k<$1.total;k++)
                $$.para_type[k]=$1.para_type[k];
              $$.para_type[k]=$3.Type;

              $$.ccode = (char *)malloc($1.len + $3.len + 2);
            $$.len = sprintf($$.ccode,"%s,%s",$1.ccode,$3.ccode);
          }
          | expression
            {
                $$.total=1;
                $$.para_type[0]=$1.Type;

                $$.ccode = (char *)malloc($1.len + 1);
            $$.len = sprintf($$.ccode,"%s",$1.ccode);
          }
          ;

expression : simple_expression  RELOP simple_expression  //比较表达式，返回的是布尔型
      {
        if($1.Type==$3.Type)//左右类型一样时才能比较
        {
          $$.Type=BOOL_T;

          if(strcmp($2.ccode,"=") == 0)//只有=和<>的表达法不一样
            {
            $$.ccode = (char *)malloc($1.len + $3.len + 3);
            $$.len = sprintf($$.ccode,"%s==%s",$1.ccode,$3.ccode);
            }
            else if(strcmp($2.ccode,"<>") == 0)
            {
            $$.ccode = (char *)malloc($1.len + $3.len + 3);
            $$.len = sprintf($$.ccode,"%s!=%s",$1.ccode,$3.ccode);
            }
            else
            {
            $$.ccode = (char *)malloc($1.len + $2.len + $3.len + 1);
            $$.len = sprintf($$.ccode,"%s%s%s",$1.ccode,$2.ccode,$3.ccode);
            }
        }
        else
        {
          $$.ccode = (char *)malloc($1.len + $2.len + $3.len + 1);
          $$.len = sprintf($$.ccode,"%s%s%s",$1.ccode,$2.ccode,$3.ccode);
          yyerror("类型不匹配");
          yyerrok;
        }
      }
       | simple_expression
        {
          $$.Type=$1.Type;
          $$.num=$1.num;
          $$.ccode = (char *)malloc($1.len + 1);
          $$.len = sprintf($$.ccode,"%s",$1.ccode);
        }
       ;

simple_expression : term // 简单表达式
          {
            $$.Type=$1.Type;
            $$.ccode = (char *)malloc($1.len + 1);
            $$.len = sprintf($$.ccode,"%s",$1.ccode);
            $$.num = $1.num;
          }

          | simple_expression ADDOP term  //加减法运算或者or ,加减法表达方法一样，所以直接复制
            {
              if($1.Type==$3.Type)
              {
                $$.Type=$1.Type;

                if(strcmp($2.ccode,"or") == 0)
              {
                $$.ccode = (char *)malloc($1.len + $3.len + 5);
                $$.len = sprintf($$.ccode,"%s || %s",$1.ccode,$3.ccode);
              }
              else
              {
                $$.ccode = (char *)malloc($1.len + $2.len + $3.len + 3);
                $$.len = sprintf($$.ccode,"%s %s %s",$1.ccode,$2.ccode,$3.ccode);
              }
              }
              else
              {
                $$.ccode = (char *)malloc($1.len + $2.len + $3.len + 3);
              $$.len = sprintf($$.ccode,"%s %s %s",$1.ccode,$2.ccode,$3.ccode);
                yyerror("类型不匹配.");
                yyerrok;
              }
            }
          ;

term : term MULOP factor
     {

      if($1.Type==$3.Type)//类型匹配，分离出不同的操作各自翻译
      {
        $$.Type=$1.Type;
        if(strcmp($2.ccode,"and") == 0)
        {
          $$.ccode = (char *)malloc($1.len + $3.len + 5);
          $$.len = sprintf($$.ccode,"%s && %s",$1.ccode,$3.ccode);
        }
        else if(strcmp($2.ccode,"mod") == 0)
        {
          $$.ccode = (char *)malloc($1.len + $3.len + 4);
          $$.len = sprintf($$.ccode,"%s %% %s",$1.ccode,$3.ccode);
        }
        else
        {
          $$.ccode = (char *)malloc($1.len + $2.len + $3.len + 3);
          $$.len = sprintf($$.ccode,"%s %s %s",$1.ccode,$2.ccode,$3.ccode);
        }
      }
      else
      {
        $$.ccode = (char *)malloc($1.len + $2.len + $3.len + 3);
        $$.len = sprintf($$.ccode,"%s %s %s",$1.ccode,$2.ccode,$3.ccode);
        yyerror("类型不匹配.");
        yyerrok;
      }
     }
   | factor
     {
        $$.Type=$1.Type;
        $$.num=$1.num;
        $$.ccode = (char *)malloc($1.len + 1);
      $$.len = sprintf($$.ccode,"%s",$1.ccode);
     }
   ;

factor : ID // 当id是一个factor时，规约上去是一个表达式，所以数组之类的结构是不合规范的。
     {
      if((ele1=find($1.ccode))!=NULL)
      {
          if(ele1->type==INT_T || ele1->type==REAL_T || ele1->type==BOOL_T)
            {
              $$.Type=ele1->type;
              $$.ccode = (char *)malloc($1.len + 1);
            $$.len = sprintf($$.ccode,"%s",$1.ccode);
          }
          else if(ele1->type==FUNCTION_T && ele1->arr_fun.fun.para_num==0)
          {
            $$.Type=ele1->arr_fun.fun.return_type;
            $$.ccode = (char *)malloc($1.len + 1);
            $$.len = sprintf($$.ccode,"%s",$1.ccode);
          }
          else
          {

            $$.ccode = (char *)malloc($1.len + 1);
            $$.len = sprintf($$.ccode,"%s",$1.ccode);
            yyerror("函数或数组调用语句不符合规范");
            yyerrok;
          }
      }
      else
        {
          $$.ccode = (char *)malloc($1.len + 1);
          $$.len = sprintf($$.ccode,"%s",$1.ccode);
            yyerror("变量未定义");
            yyerrok;
        }

     }

    | ID '(' expression_list ')' //函数规约成factor就是他的返回值
     {
      if((ele1=find($1.ccode))!=NULL)
      {
          if(ele1->type==FUNCTION_T && ele1->arr_fun.fun.para_num==$3.total)
          {
            for(k=0;k<$3.total && (ele1->arr_fun.fun.para_type[k]==$3.para_type[k]); k++);
            if(k==$3.total)
            {
              $$.ccode = (char *)malloc($1.len + $3.len + 12);
              $$.len = sprintf($$.ccode,"%s(%s)",$1.ccode,$3.ccode);

              $$.Type=ele1->arr_fun.fun.return_type;
            }
            else
            {
              $$.ccode = (char *)malloc($1.len + $3.len + 12);
              $$.len = sprintf($$.ccode,"%s(%s)",$1.ccode,$3.ccode);
              yyerror("参数列表与定义时的不匹配");
              yyerrok;
            }
          }
          else
          {
            $$.ccode = (char *)malloc($1.len + $3.len + 12);
            $$.len = sprintf($$.ccode,"%s(%s)",$1.ccode,$3.ccode);
            yyerror("参数个数不匹配");
            yyerrok;
          }
      }
      else
        {
        $$.ccode = (char *)malloc($1.len + $3.len + 12);
        $$.len = sprintf($$.ccode,"%s(%s)",$1.ccode,$3.ccode);
          yyerror("变量未定义");
          yyerrok;
        }
    }

     | ID '['expression']'
       {
      if((ele1=find($1.ccode))!=NULL)
      {
          if(ele1->type==ARRAY_T && $3.Type==INT_T)
            {
                int mylow = ele1->arr_fun.arr.first;
                $$.Type=ele1->arr_fun.arr.arr_type;
                $$.isfunction=0;

                $$.ccode = (char *)malloc($1.len + $3.len + 20);
                $$.len = sprintf($$.ccode,"%s[%s-%d]",$1.ccode,$3.ccode,mylow);
            }
            else
            {
              $$.ccode = (char *)malloc($1.len + $3.len + 10);
              $$.len = sprintf($$.ccode,"%s[%s]",$1.ccode,$3.ccode);
              yyerror("ID不是数组名或下标不合法");
              yyerrok;
            }
        }
        else
        {
          $$.ccode = (char *)malloc($1.len + $3.len + 10);
          $$.len = sprintf($$.ccode,"%s[%s]",$1.ccode,$3.ccode);
          yyerror("变量未定义");
          yyerrok;
        }
       }

     | NUM
       {
          $$.Type=REAL_T;
          $$.ccode = (char *)malloc($1.len + 1);
          $$.len = sprintf($$.ccode,"%s",$1.ccode);
     }
     | DIGITS
       {
          $$.Type=INT_T;
          $$.num = $1.num;
          $$.ccode = (char *)malloc($1.len + 1);
        $$.len = sprintf($$.ccode,"%s",$1.ccode);
     }
     | '(' expression ')'
       {
          $$.Type=$2.Type;
          $$.ccode = (char *)malloc($2.len + 3);
        $$.len = sprintf($$.ccode,"(%s)",$2.ccode);
     }
     | NOT factor
       {
          $$.Type=BOOL_T;
          $$.ccode = (char *)malloc($2.len + 2);
        $$.len = sprintf($$.ccode,"!%s",$2.ccode);
     }
     | TRUE
       {
          $$.Type=BOOL_T;
          $$.ccode = (char *)malloc(2);
        $$.len = sprintf($$.ccode,"1");
     }
     | FALSE
       {
          $$.Type=BOOL_T;
          $$.ccode = (char *)malloc(2);
        $$.len = sprintf($$.ccode,"0");
     }
     ;
%%

int main(void)
{
    table.m_size = 1024;
    table.m_num_of_pro =0;

    yyparse();

    return 0;
}

void yyerror(const char* s)
{
    fprintf(stderr, "-_-！错误出现在源文件%d行：%s\n", yylineno, s);   
}

//判断子表中，即该函数或过程中的作用域，该元素是否已经定义，未定义返回0，已定义返回-1
int check(char *s)
{
    Element *e = (Element*)malloc(sizeof(Element));
    strcpy(e->name, s);
    if (SymIsExist(temp1, e) != -1) //已定义该元素
    {
        free(e);
        return -1;
    }
    free(e);
    return 0;
}

//查找操作，从当前子表开始查找，作用域不断往外层扩张，直到查到主程序部分，都不存在，可确定未定义
Element *find(char *s)
{
    int i, j;
    Element *e = (Element*)malloc(sizeof(Element));
    strcpy(e->name, s);
    for (j = ptrStack-1; j >= 0; j--)
    {
        i = SymIsExist(s_stack[j], e);
        if (i != -1)
        {
            free(e);
            return s_stack[j]->m_name_list[i];
        }
    }
    free(e);
    return NULL;
}
