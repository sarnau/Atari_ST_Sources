
(*
 *      Modul-Skelett zur Verwaltung von System-Ressourcen
 *      --------------------------------------------------
 *                 mit Hilfe von 'ResHandler'
 *                 --------------------------
 *
 * Das folgende Modul 'SysLibSkeleton' ist eine beispielhafte Implementation
 * f�r das Verwalten von Zugriffen, die er�ffnet und wieder geschlossen
 * werden k�nnen. Die Module 'Files', 'Excepts' oder 'TextWindows' sind
 * diesbez�glich �hnlich aufgebaut.
 *
 * Problemstellung:
 *   Beim Dateizugriff oder beim Verwenden mehrerer Fenster wird im
 * Allgemeinen ein Zugriff mit einer 'Open'-Funktion erlangt und am
 * Ende mit der entsprechenden 'Close'-Funktion wieder beendet.
 * F�r dieses Verfahren gibt viele weitere Anwendungen, z.B. f�r
 * Module, die Stapel (Stacks), Schlangen (Queues) oder Verwenden
 * von Systemvektoren, wie Timer, VBL-Queue, usw., vorsehen.
 *
 *   Im Allgemeinen ist es dabei w�nschenswert, dem Anwenderprogramm
 * die Arbeit abzunehmen, beim Programmende alle er�ffneten Zugriffe
 * wieder zu schlie�en. In der Regel sollte dies zwar am Ende des
 * Programms geschehen aber bei einem Laufzeitfehler oder einfach
 * schlampiger Programmierung sollte das betreffende Modul dies zur
 * Not selbst erledigen k�nnen.
 *
 *   Man kann sich nun aber, vor Allem beim Megamax-System, Anwendungen
 * vorstellen, bei denen bei Programmende die Zugriffe erhalten bleiben
 * sollen, so z.B., wenn der Zugriff vom darunter liegenden Proze�
 * weitergef�hrt werden soll oder wenn das Programm resident bleiben
 * will und weiterhin die Zugriffe ben�tigt.
 *
 *   In den betroffenen MOS-Modulen sind deshalb, wie auch im Handbuch
 * in Kapitel 5.1, unter 'Allg. Hinweise zu den Modulen' vermerkt,
 * 'Sys'-Funktionen vorgesehen. Diese Funktionen dienen dazu, den Zugriff
 * so zu er�ffnen, da� er nicht mehr automatisch geschlossen wird.
 * In dem Fall ist dann das Anwenderprogramm wieder ganz und gar selbst
 * f�r das Schlie�en verantwortlich.
 *
 *   Die folgende Modulimplementation sieht nun alle Funktionen vor, um
 * sowohl das normale, automatische Schlie�en als auch die Sys-Funktion
 * korrekt durchzuf�hren. Das Definitionsmodul mu� dazu immer zwei
 * 'Open'-Funktionen (wovon die eine mit 'Sys' beginnt) und eine Close-
 * Funktion enthalten. Weiterhin sind eigene Funktionen zum Zugriff auf
 * die 'Resourcen' implementierbar. Die Namensgebung ist selbstver-
 * st�ndlich beliebig, nur sollte die Sys-Funktion auf jeden Fall mit
 * diesem Prefix ("Sys") beginnen.
 *
 *   Au�erdem ist schon alles vorgesehen, wiederholte, verschiedene
 * Zugriffe zu verwalten, indem f�r jeden Zugriff ein Record angelegt
 * wird, in dem die spezifischen Daten stehen und alle solche Records
 * in einer Liste verkettet werden. Es ist unumg�nglich, die Zugriffe
 * untereinander zu verketten, aber sie k�nnen nat�rlich auch anders
 * als mit einer Liste realisiert werden.
 *
 *   Die Verwaltung ge�ffneter Zugriffe in Listen und das automatische
 * Schlie�en wird mit Hilfe des Moduls 'ResHandler' realisiert.
 *
 *   Das Beispielmodul zeigt eine einfache Anwendung, bei der beim
 * �ffnen eines Zugriffs eine Zahl bestimmt werden kann. Mit der
 * Zugriffsfunktion 'DoIt' kann dann eine Textzeile ausgegeben werden,
 * die um soviel Zeichen einger�ckt ist, wie vorher beim �ffnen bestimmt
 * wurde. F�r dies einfache Beispiel findet sich ganz am Ende ein Modul,
 * das die Verwendung dieses Systemmoduls demonstiert. Diese gesamte
 * Textdatei kann auf einmal vom Compiler �bersetzt werden und dann das
 * enthaltene Testmodul mit Ctrl-A von der Shell aus gestartet werden.
 *
 *   Um eigene Systemmodule zu erstellen, sind die Namen im Definitions-
 * text und ggf. die Parameter bei den Open-Funktionen zu �ndern und
 * eigene Zugriffsroutinen zu deklarieren. Im Implementationsteil m�ssen
 * die Zugriffsroutinen neu programmiert werden (anhand der Beispielrou-
 * tine 'DoIt') und in den Funktionen 'myOpen' und 'myClose' m�ssen ggf.
 * die externen Zugriffe initialisiert bzw. r�ckgesetzt werden. Au�erdem
 * mu� das Zugriffs-Record 'MyType' mit den ben�tigten Datenfeldern
 * versehen werden.
 *
 *   Alle weiteren �nderungsstellen sind im Text mit drei Punkten im
 * Kommentar versehen. Die Kontrollausgaben sollten nat�rlich auch
 * entfernt werden.
 *)


DEFINITION MODULE SysLibSkeleton;

TYPE  Handle;

PROCEDURE OpenIt (VAR hdl: Handle; param: CARDINAL; VAR ok: BOOLEAN);
  (*
   * �ffnet einen Zugriff (Ressource).
   * 'param' bestimmt dabei die Einr�ckungsweite (s. 'DoIt').
   * Bei Proze�ende wird der Zugriff automatisch geschlossen
   *)

PROCEDURE SysOpenIt (VAR hdl: Handle; param: CARDINAL; VAR ok: BOOLEAN);
  (*
   * Wie 'OpenIt', jedoch als 'Sys'-Funktion (siehe Handbuch, Kap. 5.1)
   * Bei Proze�ende wird der Zugriff NICHT automatisch geschlossen, sondern
   * mu� manuell vom anwendenden Programm geschlossen werden!
   *)

PROCEDURE DoIt (hdl: Handle; data: ARRAY OF CHAR; VAR ok: BOOLEAN);
  (*
   * Gibt Textzeile aus, einger�ckt um den Wert, der beim �ffnen des
   * Zugriffs f. 'hdl' angegeben wurde.
   *)

PROCEDURE CloseIt (VAR hdl: Handle);
  (*
   * Beendet Zugriff auf 'hdl'
   *)

END SysLibSkeleton.

(* ----------------------------------------------------------------------- *)

IMPLEMENTATION MODULE SysLibSkeleton;

(*$Y+  Kennzeichnung f�r Systemmodule mit "shared data" (s. Handbuch) *)

FROM SYSTEM IMPORT ADDRESS, ADR;
FROM Storage IMPORT SysAlloc, DEALLOCATE;
FROM ErrBase IMPORT RtnCond, ErrResp, RaiseError;
FROM MOSGlobals IMPORT OutOfMemory;
FROM ResHandler IMPORT Resource, CreateResource,
                       InsertHandle, InsertSysHandle,
                       RemoveHandle, HandleInList;

(* ... werden ggf. nicht ben�tigt: *)
  IMPORT TOSIO, InOut, Strings;


TYPE MyType = RECORD
                (* ... hier folgen die eigenen Datenfelder: *)
                  col: CARDINAL;
              END;

TYPE Handle = POINTER TO MyType;      (* Der Opaque Typ wird redeklariert *)

VAR HandleList: Resource;             (* Liste zum Verketten der Zugriffe *)


PROCEDURE myClose (hdlAddr: ADDRESS; user: BOOLEAN);
  (*
   * Diese Prozedur �bernimmt das Schlie�en eines Zugriffs und wird
   * bei '(Sys)InsertHandle' als Parameter f�r die Freigabeprozedur
   * �bergeben.
   *)
  VAR hdl: Handle;
  BEGIN
    hdl:= hdlAddr; (* Initialisierung (Typkonvertierung) *)
    WITH hdl^ DO
      (* ... hier m�ssen ggf. R�cksetzungen erfolgen, wie *)
      (*     z.B. ver�nderte Vektoren wiederherzustellen. *)
      IF user THEN
        InOut.WriteString( 'Der Benutzer ');
      ELSE
        InOut.WriteString( 'Das System ');
      END;
      InOut.WriteString ('schlie�t den Zugriff auf Spalte ');
      InOut.WriteCard (col, 0);
      InOut.WriteLn;
    END;
    DEALLOCATE (hdl, 0)     (* Speicher f. Record freigeben *)
  END myClose;

PROCEDURE myOpen ( VAR hdl     : Handle;
                       param   : CARDINAL;
                   VAR ok      : BOOLEAN;
                       sysLevel: BOOLEAN);
  (*
   * Ist sysLevel 'TRUE', dann wird der Zugriff bei Prozessende nicht
   * automatisch geschlossen.
   *)
  VAR strOk, found, error: BOOLEAN;
  BEGIN
    ok:= FALSE;
    (* Nur neu �ffnen, wenn Zugriff noch nicht ge�ffnet ist: *)
    IF NOT HandleInList (HandleList, hdl) THEN
      (*
       * Nun Speicher f�r Record anfordern. Dazu wird eine 'Sys'-Funktion
       * benutzt (wichtig!!), damit dieser auch 'InsertSysHandle' �berlebt.
       * Auch, wenn andere Ressourcen (GEM, Vektoren, Prozesse, usw.) hier
       * angelegt werden, sollten m�glichst immer 'Sys'-Funktion dazu ver-
       * wendet werden. Ist dies nicht m�glich, darf hier auch keine Sys-
       * Funktion angeboten werden, damit's nicht schiefgeht!
       * Nat�rlich kann dieses Modul auch Dinge tun, wozu �berhaupt keine
       * externen Ressourcen (wie der Speicher f�r das Record) ge�ffnet werden
       * m�ssen, z.B. wenn hier nur damit ein Daten-Stack aufgebaut wird.
       * Dann kann hier nat�rlich problemlos eine Sys-Funktion angeboten
       * werden.
       *)
      SysAlloc (hdl, SIZE (hdl^));
      IF hdl # NIL THEN
        (* Record in der Resource-Liste HandleList verketten *)
        IF sysLevel THEN
          (* System-Zugriff; nur verwenden, wenn der Rest (Speicher, usw.)
           * auch mit Sys-Funktionen angelegt wurde! *)
          InsertSysHandle (HandleList, hdl, myClose, error);
        ELSE
          (* normaler Zugriff *)
          InsertHandle (HandleList, hdl, myClose, error);
        END;
        IF error THEN
          DEALLOCATE (hdl, 0)
        ELSE
          WITH hdl^ DO
            (* ... hier folgen eigene Initialisierungen *)
            (* ... und Zuweisungen der Record-Felder:   *)
              col:= param;
          END;
          ok:= TRUE
        END
      END
    END
  END myOpen;

PROCEDURE OpenIt (VAR hdl: Handle; param: CARDINAL; VAR ok: BOOLEAN);
  (*
   * Normales Er�ffnen eines Zugriffs (einer Ressource).
   *)
  BEGIN
    myOpen (hdl, param, ok, FALSE)
  END OpenIt;

PROCEDURE SysOpenIt (VAR hdl: Handle; param: CARDINAL; VAR ok: BOOLEAN);
  (*
   * Dauerhaftes Er�ffnen eines Zugriffs (einer Ressource).
   *)
  BEGIN
    myOpen (hdl, param, ok, TRUE)
  END SysOpenIt;


PROCEDURE DoIt (hdl: Handle; data: ARRAY OF CHAR; VAR ok: BOOLEAN);
  (*
   * Operation auf dem Zugriff (auf der Ressource)
   *)
  BEGIN
    (* Existiert Zugriff �berhaupt ? *)
    IF HandleInList (HandleList, hdl) THEN
      WITH hdl^ DO                   (* ja, dann ist der 'handle' g�ltig. *)
        (* ...hier wird ein Zugriff durchgef�hrt: *)
        InOut.WriteString (Strings.Space (col));  (* 'col' aus Record *)
        InOut.WriteString (data);
        InOut.WriteLn;
      END
    END
  END DoIt;


PROCEDURE CloseIt (VAR hdl: Handle);
  BEGIN
    (*
     * Falls der angegebene Zugriff noch existiert, wird der
     * belegte Speicher freigegeben und der Zugriff aus der Liste
     * 'HandleList' gel�scht.
     *)
    RemoveHandle (HandleList, hdl)
  END CloseIt;


VAR error: BOOLEAN;

BEGIN
  CreateResource (HandleList, error);
  IF error THEN
    RaiseError (OutOfMemory, '', selfCaused, mustAbort)
  END;
END SysLibSkeleton.

(* ----------------------------------------------------------------------- *)

MODULE SysLibDemo;

(*
 * Dies Modul demonstiert die Anwendung des obigen Beispielmoduls.
 *
 * Es �ffnet erst zwei Zugriffe, dann wendet es die Zugriffsfunktionen an,
 * dann startet es einen Tochterproze�, welcher ebenfalls zwei Zugriffe
 * er�ffnet. Einer der Zugriffe wird mit der Sys-Funktion ge�ffnet. Der
 * Proze� gibt auch mit 'DoIt' Text aus und endet dann, ohne die Zugriffe
 * zu schlie�en. Der eine Zugriff wird sodann vom Systemmodul geschlossen,
 * w�hrend der Sys-Zugriff erhalten bleibt. Dann werden im ersten Proze�
 * wieder Ausgaben mit 'DoIt' gemacht, wobei auch der noch vorhandene
 * Sys-Zugriff benutzt wird. Am Ende wird dann einer der beiden ersten
 * Zugriffe ordnungsgem�� geschlossen, soda� das Systemmodul den anderen
 * wiederum automatisch schlie�t.
 *
 * Der Sys-Zugriff mu� (immer) explizit geschlossen werden, was in der
 * 'Termination'-Funktion geschieht, die zuvor mit 'CatchProcessTerm'
 * einen Aufruf bei Proze�ende angefordert hat. Dies ist besser, als am
 * Ende des Programmtextes diesen Aufruf durchzuf�hren, weil bei einem
 * Laufzeitfehler diese Programmstelle nicht mehr erreicht werden w�rde
 * und der Zugriff f�r immer (bis zum Reset des Rechners) als "Leiche"
 * im Speicher verleiben w�rde.
 *
 * Die Fehlerabfragen ('ok') wurden absichtlich weggelassen, da hier sowieso
 * alles funktionieren sollte (Speicher sollte ausreichen).
 *)

IMPORT GEMDOSIO; (*$E MOS ..machen wir ein TOS-Programm draus. *)

FROM SYSTEM IMPORT ADR;
FROM SysLibSkeleton IMPORT Handle, OpenIt, SysOpenIt, DoIt, CloseIt;
FROM MOSGlobals IMPORT MemArea;
FROM ModCtrl IMPORT CallProcess;
FROM ResCtrl IMPORT CatchRemoval, RemovalCarrier;
FROM PrgCtrl IMPORT CatchProcessTerm, TermCarrier;
IMPORT InOut;

MODULE local;

  (*
   * Dies lokale Modul enth�lt eine Prozedur, die als neuer Proze� unter
   * dem Hauptprogramm gestartet wird.
   * Ebenso k�nnte zur Demonstration mit 'Loader.CallModule' ein anderes
   * Modul als Tochterproze� gestartet werden, das dann 'SysLibSkeleton'
   * importiert und die im Folgenden gezeigten Funktionen aufruft.
   *)

  IMPORT Handle, OpenIt, SysOpenIt, DoIt, CloseIt;
  IMPORT InOut;

  EXPORT otherProgram, sysHdl;

  VAR sysHdl: Handle;

  PROCEDURE otherProgram;
    VAR ok: BOOLEAN;
        hdl: Handle;
    BEGIN
      (* Normalen Zugriff zu diesem Proze� �ffnen *)
      OpenIt (hdl, 12, ok);
        InOut.WriteString ('�ffne Zugriff auf Spalte 12');
        InOut.WriteLn;

      (* Dauerhaften Zugriff �ffnen *)
      SysOpenIt (sysHdl, 14, ok);
        InOut.WriteString ('�ffne Sys-Zugriff 2 auf Spalte 14');
        InOut.WriteLn;

      DoIt (hdl,    'Dies ist 2. Proze�, normaler Zugriff', ok);
      DoIt (sysHdl, 'Dies ist 2. Proze�, Sys-Zugriff', ok)

      (* Der Sys-Zugriff soll nicht geschlossen werden, da im *)
      (* Vaterproze� noch darauf zugegriffen werden wird..    *)
      (* Der andere Proze� wird einfach vergessen - er wird   *)
      (* vom Systemmodul geschlossen werden.                  *)
    END otherProgram;

  END local;

PROCEDURE Removal;
  VAR wait: CHAR;
  BEGIN
    InOut.WriteLn;
    InOut.WriteString ('Taste...');
    InOut.Read (wait);
  END Removal;

PROCEDURE Termination;
  VAR wait: CHAR;
  BEGIN
    (* Der Sys-Zugriff mu� sp�testens hier geschlossen werden, sonst bleibt
     * er f�r immer ge�ffnet (und belegt damit unn�tig Speicher). *)
    InOut.WriteString ('Schlie�e manuell Sys-Zugriff auf Spalte 14:');
    InOut.WriteLn;
    CloseIt (sysHdl);
    InOut.WriteLn;
    (* ... hier k�nnten eigene Ressourcen geschlossen werden. *)
  END Termination;

VAR ok: BOOLEAN;
    exitCode: INTEGER;                  (* Exit-Code von 2. Proze� *)
    stack: ARRAY [1..4096] OF CARDINAL; (* Stack f�r 2. Proze�: 8 KB *)
    wsp: MemArea;
    rCarrier: RemovalCarrier;
    tCarrier: TermCarrier;

    hdl: ARRAY [1..2] OF Handle;        (* 'Handles' f�r zwei Zugriffe *)

BEGIN
  (* Bei Programmende soll 'Removal' aufgerufen werden, um auf einen
   * Tastendruck zu warten: *)
  wsp.bottom:= NIL; (* Damit wird der Stack des Hauptprozesses benutzt *)
  CatchRemoval (rCarrier, Removal, wsp);

  (* Bei Proze�ende soll 'Termination' aufgerufen werden *)
  wsp.bottom:= NIL;  (* Damit wird der Stack des Hauptprozesses benutzt *)
  CatchProcessTerm ( tCarrier, Termination, wsp );
    (* Hier h�tte auch 'CatchRemoval' verwendet werden  *)
    (* k�nnen, da dies beim Hauptmodul, sofern es nicht *)
    (* resident ist, keinen Unterschied macht.          *)

  (* Ersten Zugriff �ffnen *)
  OpenIt (hdl [1], 2, ok);
    InOut.WriteString ('�ffne Zugriff 1 auf Spalte 2');
    InOut.WriteLn;
  (* Zweiten Zugriff �ffnen *)
  OpenIt (hdl [2], 4, ok);
    InOut.WriteString ('�ffne Zugriff 2 auf Spalte 4');
    InOut.WriteLn;

  (* Funktionen auf die beiden Zugriffe durchf�hren *)
  DoIt (hdl [1], 'Dies ist 1. Proze�, Zugriff 1', ok);
  DoIt (hdl [2], 'Dies ist 1. Proze�, Zugriff 2', ok);

  (* Tochterproze� starten *)
  InOut.WriteLn;
  wsp.bottom:= ADR (stack);
  wsp.length:= SIZE (stack);
  CallProcess (otherProgram, wsp, ok, exitCode);
  InOut.WriteLn;

  (* Funktionen auf die beiden Zugriffe dieses Prozesses und des    *)
  (* residenten, vom Tochterproze� ge�ffneten, Zugriffs durchf�hren *)
  DoIt (hdl [2], 'Dies ist wieder 1. Proze�, Zugriff 2', ok);
  DoIt (hdl [1], 'Dies ist wieder 1. Proze�, Zugriff 1', ok);
  DoIt (sysHdl,  'Dies ist der Sys-Zugriff', ok);

  (* Einen der hier ge�ffneten Zugriffe selber schlie�en,  *)
  (* der andere wird testweise vom Systemmodul geschlossen *)
  InOut.WriteLn;
  InOut.WriteString ('Schlie�e manuell Zugriff 2 auf Spalte 4:');
  InOut.WriteLn;
  CloseIt (hdl [2]);

  InOut.WriteLn

END SysLibDemo.
