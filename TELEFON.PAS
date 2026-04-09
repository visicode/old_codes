program telefonkonyv;

{ Ez a program egy telefonkonyvet probal megvalositani.                       }
{ A program a kovetkezo adatokat tarolja : NEV,CIM,IRANYITOSZAM,TELEFONSZAM.  }
{ Az adatokat a program egy altalunk megnevezett file-ban tarolja, ha kivanjuk}
{ Az adatokat egyebkent a memoriaban tarolja egy egyiranyban lancolt listaban.}
{ A kovetkezo menupontok valaszthatok:BEOLVASAS(FILE),KIIRAS(FILE),RENDEZES,  }
{ UJ ADAT FELVETELE,JAVITAS,TORLES,LISTAZAS,KERESES.                          }

uses crt,dos;

type
   tagrec=record                {Ebben a tipusu rekordba  }
         nev:string;            {tarolja egy ember adatat.}
         irsz:integer;
         cim:string;
         tszam:string;
         end;
  ptag=^tag;                    {A mutato a lancolashoz}
  tag=record
      id:tagrec;
      kov:ptag;
      end;

const visi : string ='visi.dat';    {A rendezeshez az ideiglenes }
                                    {munkafile neve}
var lg,lkm:file of tagrec;
    v,x,z,fx,elso,utolso,stag,elozo,q:ptag;
    b,rend,gomb,c,ker:char;
    p:pointer;
    tsz,fnev,nm,cm:string;
    seged,adat:tagrec;
    talalt,tal:boolean;

procedure kep;         {Az altalanos menu kepe}

  begin
  clrscr;
  writeln('ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»');
  writeln('º                                                            º');
  writeln('º              1. Beolvas s file-b¢l                         º');
  writeln('º                                                            º');
  writeln('º              2. Ment‚s file-ba                             º');
  writeln('º                                                            º');
  writeln('º              3. Rendez‚s                                   º');
  writeln('º                                                            º');
  writeln('º              4. Adat bevitel                               º');
  writeln('º                                                            º');
  writeln('º              5. Jav¡t s                                    º');
  writeln('º                                                            º');
  writeln('º              6. T”rl‚s                                     º');
  writeln('º                                                            º');
  writeln('º              7. Kiiras                                     º');
  writeln('º                                                            º');
  writeln('º              8. Kereses                                    º');
  writeln('º                                                            º');
  writeln('º              9. Kilepes                                    º');
  writeln('º                                                            º');
  writeln('ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼');
  writeln;
  write('Az ”n v laszt sa:');
  repeat
  gomb:=readkey;
  until gomb in ['1','2','3','4','5','6','7','8','9'];
  clrscr;
  end;

procedure rendezes(miszer:char);      {A 'miszer' szerint rendezve beolvassa}
                                      {az 'lg' nevo valtozohoz hozzarendelt }
                                      {filebol az adatokat,mikozben vizsgal-}
                                      {ja,hogy van-e ilyen rekord a memoriban}
  begin
  if elso=nil then
             begin
             read(lg,seged);
             new(stag);
             utolso:=stag;
             elso:=stag;
             stag^.id.nev:=seged.nev;
             stag^.id.irsz:=seged.irsz;
             stag^.id.cim:=seged.cim;
             stag^.id.tszam:=seged.tszam;
             stag^.kov:=nil;
             end;
      tal:=false;
      while not(eof(lg)) do
      begin
      read(lg,seged);
      fx:=elso;
      repeat
      if  (fx^.id.nev=seged.nev) and
         (fx^.id.irsz=seged.irsz) and
        (fx^.id.tszam=seged.tszam) and
         (fx^.id.cim=seged.cim) then tal:=true;
      fx:=fx^.kov;
      until fx=nil;
      if tal=false then
        begin
        z:=nil;
        x:=elso;
        talalt:=false;
        repeat
        elozo:=z;
        z:=x;
        case miszer of
          '1': if x^.id.nev>=seged.nev then talalt:=true
                                  else x:=x^.kov;
          '2': if x^.id.tszam>=seged.tszam then talalt:=true
                                  else x:=x^.kov;
          '3': if x^.id.cim>=seged.cim then talalt:=true
                                  else x:=x^.kov;
          end;
        until talalt or (x=nil);
        if (x<>nil) and talalt then
          begin
          new(stag);
          stag^.id.nev:=seged.nev;
          stag^.id.irsz:=seged.irsz;
          stag^.id.cim:=seged.cim;
          stag^.id.tszam:=seged.tszam;
          stag^.kov:=x;
          elozo^.kov:=stag;
          end;
        if x=elso then
          begin
          new(stag);
          stag^.id.nev:=seged.nev;
          stag^.id.irsz:=seged.irsz;
          stag^.id.cim:=seged.cim;
          stag^.id.tszam:=seged.tszam;
          stag^.kov:=x;
          elso:=stag;
          end;
        if x=nil then
          begin
          new(stag);
          stag^.id.nev:=seged.nev;
          stag^.id.irsz:=seged.irsz;
          stag^.id.cim:=seged.cim;
          stag^.id.tszam:=seged.tszam;
          stag^.kov:=nil;
          z^.kov:=stag;
          end;


          if stag^.kov=nil then utolso:=stag;
        end;
      end;
  end;
procedure fname;       {beolvas a bilentyuzetrol}
                       {egy altalunk hasznalni  }
                       {kivant file nevet       }

  begin
  clrscr;
  writeln;
  writeln('Adja meg az £j file nev‚t: ');
  readln(fnev);
  end;



procedure kiiras(var lm:string);   {Az 'lm' nevu file-ba kiirja   }
                                   {az adatokat a lemezre, de     }
                                   {a memoriaban ezzel egyidejuleg}
                                   {megszunteti oket.             }
  begin
  assign(lkm,lm);
  rewrite(lkm);
  z:=elso;
  repeat
  x:=z;
  seged:=x^.id;
  write(lkm,seged);
  z:=x^.kov;
  dispose(x);
  until z=nil;
  elso:=nil;
  utolso:=nil;
  close(lkm);
  end;

procedure lemez;         {Az 'fnev'-u filet megvizsgalja hogy letezik-e  }
                         {, ha igen, akkor megkerdezi, hogy az abban levo}
                         {adatokat felulirja-e vagy ne, ha igen, akkor   }
                         {felulirja egyebkent beker egy uj file nevet, es}
                         {meghivja onmagat.  (fname,lemez,kiiras elj.    }

  begin
  if fsearch(fnev,'')='' then
                         begin
                         if elso<>nil then kiiras(fnev)
                                      else
                                      begin
                                      writeln('Nincs adat!');
                                      end;
                         end
                         else
                         begin
                         clrscr;
                         writeln('Mar van ilyen file!');
                         writeln('Felulirjam(i/n)?');
                           repeat
                           b:=readkey;
                           until (b='i') or (b='I') or (b='n') or (b='N');
                           if (b='i') or (b='I') then kiiras(fnev)
                                                 else begin
                                                      fname;
                                                      lemez;
                                                      end;
                         end;
  end;

procedure mentes;         {Lementi az adtokat a lemezre.Ha volt mar     }
                          {beolvasas, akkor megkerdi azt a file-t       }
                          {hasznalja-e irasra amelyikbol olvasot, ha    }
                          {nem, vagy nem volt beolvasas, akkor          }
                          {megkerdezi mibe mentsen ki (fname,lemez elj.)}

  begin
  if fnev<>'' then
                    begin
                    clrscr;
                    writeln;
                    writeln('A ',fnev,' file-ba mentsem(i/n)');
                    repeat
                    b:=readkey;
                    until (b='i') or (b='I') or (b='n') or (b='N');
                    if (b='i') or (b='I') then lemez
                                          else begin
                                               fname;
                                               lemez;
                                               end;
                    end
              else
              begin
              fname;
              lemez;
              end;
  end;

procedure beolvas(flnev:string);    {Megnyitja az 'flnev'-u file-t , ha}
                                    {letezik es beolvassa belole az    }
                                    {adatokat a bekert rendezes szerint}
                                    {(rendezes elj.)                   }

  begin
  {$I-}
  clrscr;
  assign(lg,flnev);
  reset(lg);
  {$i+}
    if ioresult=0 then
      begin
      if elso=nil then
        begin
        writeln('K‚rem a rendez‚si param‚tert!');
        writeln('  1: N‚v szerint              ');
        writeln('  2: Telefonsz m szerint      ');
        writeln('  3: Cim szerint              ');
        repeat
        rend:=readkey;
        until rend in ['1','2','3'];
        end;
      if ioresult<>0 then writeln('Hiba az olvasasban!');
      rendezes(rend);
      close(lg);
      end
      else
      begin
      writeln('error  Nincs ilyen file');
      c:=readkey;
      end;
  end;

procedure rendez;         {Kiirja az adatokat egy munkafile-ba         }
                          {, majd beolvassa belole az adatokat         }
                          {mar helyesen rendezve (kiiras,rendezes elj.)}

     begin
     kiiras(visi);
     clrscr;
     writeln('K‚rem a rendez‚si param‚tert!');
     writeln('  1: N‚v szerint              ');
     writeln('  2: Telefonsz m szerint      ');
     writeln('  3: Cim szerint              ');
     repeat
     rend:=readkey;
     until rend in ['1','2','3'];
     assign(lg,visi);
     reset(lg);
     rendezes(rend);
     close(lg);
     end;

procedure kiir(v:ptag);      {A kepernyore kiirja a 'v' altal}
                             {mutatot rekord tartalmat       }

  begin
  clrscr;
  writeln('                  Az ember neve: ',v^.id.nev);
  writeln(' Az ember cimenek iranyitoszama: ',v^.id.irsz);
  writeln('                  Az ember cime: ',v^.id.cim);
  writeln('          Az ember telefonszama: ',v^.id.tszam);
  end;

procedure kereses;       {Beker egy keresesi parametert es megprobalja }
                         {az alapjan megkeresni a memoriaban, amennyibe}
                         {talal ilyet kiirja a kepernyore (kiir elj.)  }

  begin
  clrscr;
  if elso<>nil then begin
    writeln('K‚rem a keresesi param‚tert!');
    writeln('  1: N‚v szerint              ');
    writeln('  2: Telefonsz m szerint      ');
    writeln('  3: Cim szerint              ');
    repeat
    ker:=readkey;
    until ker in ['1','2','3'];
    case ker of
    '1': begin
         writeln('Mi a szem‚ly neve?');
         readln(nm);
         z:=nil;
         x:=elso;
         talalt:=false;
           repeat
           q:=z;
           z:=x;
           if x^.id.nev=nm then
                           begin
                           kiir(x);
                           writeln('press SPACE =ha ezt kerested,press not(space),ha tovabb keresel');
                           c:=readkey;
                           if c=' ' then talalt:=true
                                    else
                                    begin
                                    x:=x^.kov;
                                    talalt:=false;
                                    end;
                           end
                           else x:=x^.kov;
           until (talalt) or (x=nil);
         if x=nil then begin
                       writeln;
                       writeln('Nem talaltam ilyen nevet!');
                       c:=readkey;
                       end;
           end;
    '2': begin
         writeln('Mi a telefonszam?');
         readln(tsz);
         z:=nil;
         x:=elso;
         talalt:=false;
           repeat
           q:=z;
           z:=x;
           if x^.id.tszam=tsz then
                                            begin
                                            kiir(x);
                                            writeln('press SPACE =ha ezt kerested,press not(space),ha tovabb keresel');
                                            c:=readkey;
                                            if c=' ' then talalt:=true
                                                      else
                                                      begin
                                                      x:=x^.kov;
                                                      talalt:=false;
                                                      end;
                                            end
                                            else x:=x^.kov;
           until talalt or (x=nil);
         if x=nil then begin
                       writeln;
                       writeln('Nem talaltam ilyen szamot');
                       c:=readkey;
                       end;
           end;
    '3': begin
         writeln('Mi a szem‚ly cime?');
         readln(cm);
         z:=nil;
         x:=elso;
         talalt:=false;
           repeat
           q:=z;
           z:=x;
           if x^.id.cim=cm then
                           begin
                           kiir(x);
                           writeln('press SPACE =ha ezt kerested,press not(space),ha tovabb keresel');
                           c:=readkey;
                           if c=' ' then talalt:=true
                                     else
                                     begin
                                     talalt:=false;
                                     x:=x^.kov;
                                     end;
                           end
                           else x:=x^.kov;
           until talalt or (x=nil);
         if x=nil then begin
                       writeln;
                       writeln('Nem talaltam ilyen cimet!');
                       c:=readkey;
                       end;
           end;
  end;
  end;
  end;

procedure berendez(re:tagrec);   {A 're' rekordot berendezi a memoriaba  }
                                 {a tobbi adat soraba az utolso ('rend') }
                                 {rendezesi parameter szerint, ha meg    }
                                 {nem volt rendezes vagy beolvasas, akkor}
                                 {nevsorba rendez                        }

  begin
  if elso=nil then
                begin
                new(stag);
                utolso:=stag;
                elso:=stag;
                stag^.id.nev:=re.nev;
                stag^.id.irsz:=re.irsz;
                stag^.id.cim:=re.cim;
                stag^.id.tszam:=re.tszam;
                stag^.kov:=nil;
                end
              else
                begin
                x:=elso;
                talalt:=false;
                z:=nil;
                  repeat
                  elozo:=z;
                  z:=x;
                    case rend of
                      '1': if x^.id.nev>=re.nev then talalt:=true
                                                else x:=x^.kov;
                      '2': if x^.id.tszam>=re.tszam then talalt:=true
                                                    else x:=x^.kov;
                      '3': if x^.id.cim>=re.cim then talalt:=true
                                                else x:=x^.kov;
                    end;
                  until talalt or (x=nil);
                new(stag);
                stag^.id.nev:=re.nev;
                stag^.id.irsz:=re.irsz;
                stag^.id.cim:=re.cim;
                stag^.id.tszam:=re.tszam;
                stag^.kov:=x;
                  if x=nil then z^.kov:=stag;
                  if (elozo=nil) and (x<>nil) then begin
                                                   elso:=stag;
                                                   stag^.kov:=x;
                                                   end;
                  if (elozo<>nil) and (x<>nil) then elozo^.kov:=stag;
                  if stag^.kov=nil then utolso:=stag;
                end;

  end;

procedure felv;      {Beolvas a billentyuzetrol egy ujjab}
                     {adatot az 'adat' nevu rekordba     }

  begin
  writeln('Mi a szem‚ly neve?');
  readln(adat.nev);
  writeln('Mi a szem‚ly lakasanak iranyitoszama?');
  readln(adat.irsz);
  writeln('Mi a szem‚ly lakasanak cime?');
  readln(adat.cim);
  writeln('Mi a szem‚ly telefonszama?');
  readln(adat.tszam);
  berendez(adat);
  end;

procedure torol(w,m:ptag);  {Kitorli az 'm' mutato altal}
                            {mutatottat a listabol, majd}
                            {felszabaditja a helyet a   }
                            {memoriaba.                 }
                            {Az 'w' az 'm' elotti       }
                            {rekordra mutat.            }

  begin
  if w=nil then
             begin
             elso:=m^.kov;
             dispose(m);
             end
           else
             begin
             w^.kov:=m^.kov;
             dispose(m);
             end;
  end;







begin

  q:=nil;
  x:=nil;
  rend:='1';
  fnev:='';
  new(elso);
  mark(p);
  elso:=nil;
  utolso:=elso;
  repeat
  kep;
  case gomb of
           '1': begin                        {mindenfelekeppen beolvas}
                                             {(beolvas elj.)          }
                clrscr;
                   writeln('K‚rem irja be a file nev‚t!');
                   readln(fnev);
                   beolvas(fnev);
                end;
            '2': mentes;  {kimenti az adatokat lemezre (mentes elj.)}
            '3': rendez;  {berendezi az adatokat (rendez elj.)}
            '4': begin    {uj adatot vesz fel (felv elj.)}
                 clrscr;
                 felv;
                 end;
            '5': begin    {kijavitja a megkereset rekordot        }
                          {torli az elozot,majd uj adatot vesz fel}
                          {(kereses,torol,felv elj.               }
                 kereses;
                 if x<>nil then begin
                                writeln('Tuti ,hogy javitani akarod(i/n)?');
                                  repeat
                                  b:=readkey;
                                  until (b='i') or (b='I') or (b='n') or (b='N');
                                   if (b='i') or (b='I') then  begin
                                                               torol(q,x);
                                                               felv;
                                                               end;
                                end;
                 end;
            '6': begin     {torli a megkereset rekordot}
                           {(kereses,torol elj.)       }
                 kereses;
                 c:=readkey;
                 if x<>nil then begin
                                writeln('Tuti ,hogy torolni akarod(i/n)?');
                                  repeat
                                  b:=readkey;
                                  until (b='i') or (b='I') or (b='n') or (b='N');
                                   if (b='i') or (b='I') then  begin
                                                               torol(q,x);
                                                               end;

                                end;
                 end;
            '7': begin      {sorrendbe kiirja az adatokat}
                            {egymas utan a kepernyore    }
                            {(kiir elj.)                 }
                 if elso<>nil then begin
                                   v:=elso;
                                   kiir(v);
                                   c:=readkey;
                                   while v^.kov<>nil do begin
                                                        v:=v^.kov;
                                                        kiir(v);
                                                        c:=readkey;
                                                        end;
                                   end
                                   else
                                   begin
                                   clrscr;
                                   writeln('Nincs adat a memoriaban!');
                                   c:=readkey;
                                   end;
                 end;
            '8': kereses;   {megkeres egy rekordot}
                            {(kereses elj.)       }
            '9': begin      {kilep a programbol         }
                            {ha kell lementi az adatokat}
                            {(mentes elj.)              }
                 clrscr;
                 if elso<>nil then
                 begin
                 writeln('Mentes (i/n)?');
                   repeat
                   b:=readkey;
                   until (b='i') or (b='I') or (b='n') or (b='N');
                    if (b='i') or (b='I') then  mentes
                                          else
                                          begin
                                          release(p);
                                          utolso:=nil;
                                          end;
                 end;
                 halt(0);
                 end;
            end;
  until false;    {Vissza a fomenube}
end.
