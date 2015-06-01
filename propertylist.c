#include "propertylist.h"
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

unsigned SymHash(SymbalList *sym, Element *s)
{
    char *name = s->name;
    unsigned long h = 0;
    while (*name)
    {
        h = (h << 1) ^ *name++;
    }
    return h % (sym->m_size);
}

int SymIsExist(SymbalList *sym, Element *key)
{
    int pos;
    if(sym == NULL)
        return -1;
    
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
    int pos = SymHash(sym, key);
    while ((sym->m_name_list)[pos] != NULL)
    {
        char *name = sym->m_name_list[pos]->name;
        if (SymIsElementEqualed(sym, key, pos))
        {
            return -1;
        }
        else
        {
            ++pos;
        }
    }
    ++(sym->m_num_of_pro);
    (sym->m_name_list)[pos] = key;
    assert(sym->m_num_of_pro <= 0.5 * sym->m_size);//元素的个数小于表长的一半
    
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
