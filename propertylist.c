#include "propertylist.h"
#include "stdio.h"
#include <stdlib.h>
#include <assert.h>

unsigned SymHash(SymbalList *sym, Element *s)
{
printf("2.1\n");
    char *name = s->name;
    unsigned long h = 0;
printf("2.2\n");
    while (*name)
    {
printf("2.3\n");
        h = (h << 1) ^ *name++;
    }
printf("2.4\n");
printf("%d\n",sym->m_size);
    return h % (sym->m_size);
}

int SymIsExist(SymbalList *sym, Element *key)
{
    int pos;
    assert(sym->m_num_of_pro <= 0.5 * sym->m_size);  //元素的个数小于表长的一半
    pos = SymHash(sym, key);
    while (sym->m_name_list[pos] != NULL)
    {
        if (SymIsElementEqualed(sym, key, pos))
        {
            return pos;
        }
        else
        {
            pos = 0;
        }
    }
    return -1;
}

int SymPush(SymbalList *sym, Element *key)
{
    printf("1\n");
    int pos = SymHash(sym, key);
printf("1.1\n");
    while ((sym->m_name_list)[pos] != NULL)
    {
    printf("2\n");
        char *name = sym->m_name_list[pos]->name;
printf("3\n");    
    if (SymIsElementEqualed(sym, key, pos))
        {
printf("4\n");
            return -1;
        }
        else
        {
printf("5\n");
            ++pos;
        }
    }
    ++(sym->m_num_of_pro);
    (sym->m_name_list)[pos] = key;
printf("6\n");
    assert(sym->m_num_of_pro <= 0.5 * sym->m_size);//元素的个数小于表长的一半
printf("7\n"); 
   return pos;
}

int SymPop(SymbalList *sym, Element *key)
{
    int pos = SymIsExist(sym, key);
    if (pos == -1)
    {
        return -1;
    }
    else
    {
        free(sym->m_name_list[pos]);
        sym->m_name_list[pos] = NULL;
        --(sym->m_num_of_pro);
        return pos;
    }
}

int SymPopAt(SymbalList *sym, int pos)
{
    if (sym->m_name_list[pos] == NULL)
    {
        return -1;
    }
    free(sym->m_name_list[pos]);
    sym->m_name_list[pos] = NULL;
    --(sym->m_num_of_pro);
    return pos;
}

int SymIsElementEqualed(SymbalList *sym, Element *key, int pos)
{
    return !strcmp(key->name, sym->m_name_list[pos]->name) ;
}
