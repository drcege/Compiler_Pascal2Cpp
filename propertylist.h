#ifndef  __SYMBALLIST__
#define  __SYMBALLIST__

struct SymbalList;

typedef enum
{
    VOID,INT_T,REAL_T,BOOL_T,ARRAY_T,RECORD_T,PROGRAM_T,PROCEDURE_T,FUNCTION_T
}My_Type;

typedef struct
{
  int first;
  int last;
  My_Type arr_type;
}array;

typedef struct 
{
    int para_num;//参数个数
    My_Type return_type;
    My_Type para_type[10];
    struct SymbalList* sub_list;
}function;

typedef union
{
  array arr;
  function fun;
} array_function;

typedef struct
{
  char name[9]; //最多有8个
  int location;//声明行
  My_Type type;
  array_function arr_fun;
}Element;

typedef struct SymbalList
{
  unsigned m_size;  //1024
  unsigned m_num_of_pro;  //0
  Element* m_name_list[1024];
} SymbalList;


unsigned SymHash(SymbalList *sym, Element *s);
int SymIsExist(SymbalList *sym, Element *key);
int SymPush(SymbalList *sym, Element *key);
int SymPop(SymbalList *sym, Element *key);
int SymPopAt(SymbalList *sym, int pos);
int SymIsElementEqualed(SymbalList *sym, Element *key, int pos);

#endif
