/*
   Modul: M_ALERTS (Headerdatei)

   geschrieben von Thomas K�nneth
   Friedrich-Neuper-Str. 2b
   90552 R�thenbach

   Diese Datei ist Bestandteil der C-Version von Magic 4.0 von
   Peter Hellinger und Thomas K�nneth und darf nur gem�� den
   Nutzungsbedingungen von Magic f�r C verwendet werden

   Alle Rechte beim Autor
*/

#ifndef _MPALERTS_
#define _MPALERTS_

#ifndef _MAGICTYP_
#include <magic\m_types.h>
#endif

typedef struct {
   int   message,
         objc;
} Alertpara;

typedef Alertpara* PtrAlertpara;

typedef  void  (*AlertHandler)(PtrAlertpara);

int Alert(int x,int y,int def,char *str);
void WindowAlert(int x,int y,int def,char *str,AlertHandler handler);
void SetIconColor(int fcolor,int bcolor);
CICONBLK *Iconslot(int slotnum);
void SetIconslot(int slotnum,CICONBLK *icon);

#endif
